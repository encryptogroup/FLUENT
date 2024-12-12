const std = @import("std");

const Circuit = @import("Circuit.zig");

const Parser = @This();

gpa: std.mem.Allocator,

circuit_buffered_reader: std.io.BufferedReader(4096, std.fs.File.Reader),
programming_buffered_reader: std.io.BufferedReader(4096, std.fs.File.Reader),

circuit_nodes: std.MultiArrayList(Circuit.Node) = .{},
circuit_luts: std.ArrayListUnmanaged(Circuit.Node.Index) = .{},
circuit_inputs: std.ArrayListUnmanaged(Circuit.Node.Index) = .{},
circuit_outputs: std.ArrayListUnmanaged(Circuit.Node.Index) = .{},
circuit_lut_tables: std.ArrayListUnmanaged(u1) = .{},
circuit_programming_bits: std.ArrayListUnmanaged(u1) = .{},
circuit_max_wire_number: Circuit.Node.Index = 0,

pub fn parseCircuit(
    gpa: std.mem.Allocator,
    working_dir: std.fs.Dir,
    circuit_file_path: []const u8,
    prog_file_path: []const u8,
) !Circuit {
    var circuit_file = try working_dir.openFile(circuit_file_path, .{});
    defer circuit_file.close();

    var prog_file = try working_dir.openFile(prog_file_path, .{});
    defer prog_file.close();

    var parser = Parser{
        .gpa = gpa,
        .circuit_buffered_reader = std.io.bufferedReader(circuit_file.reader()),
        .programming_buffered_reader = std.io.bufferedReader(prog_file.reader()),
    };
    try parser.parse();

    return Circuit{
        .nodes = parser.circuit_nodes.toOwnedSlice(),
        .luts = parser.circuit_luts.toOwnedSlice(gpa),
        .inputs = parser.circuit_inputs.toOwnedSlice(gpa),
        .outputs = parser.circuit_outputs.toOwnedSlice(gpa),
        .lut_tables = parser.circuit_lut_tables.toOwnedSlice(gpa),
        .programming_bits = parser.circuit_programming_bits.toOwnedSlice(gpa),
        .max_wire_number = parser.circuit_max_wire_number,
    };
}

fn addNode(parser: *Parser, node: Circuit.Node) !void {
    const gpa = parser.gpa;
    try parser.circuit_nodes.ensureUnusedCapacity(gpa, 1);
    parser.circuit_nodes.appendAssumeCapacity(node);
}

fn adjustMaxWireNumber(parser: *Parser, wire_numbers: []const Circuit.Node.Index) void {
    for (wire_numbers) |wire_number| {
        parser.circuit_max_wire_number = @max(parser.circuit_max_wire_number, wire_number);
    }
}

fn parse(
    parser: *Parser,
) !void {
    const circuit_reader = parser.circuit_buffered_reader.reader();
    const programming_reader = parser.programming_buffered_reader.reader();

    var buf: [4096]u8 = undefined;
    const max_line_len = 1024 * 1024;
    while (try circuit_reader.readUntilDelimiterOrEofAlloc(parser.gpa, '\n', max_line_len)) |line| {
        defer parser.gpa.free(line);

        var iter = std.mem.tokenize(u8, line, " ");
        const line_type = iter.next() orelse return error.ExpectedType;
        if (std.mem.eql(u8, "C", line_type)) {
            while (iter.next()) |wire_number_raw| {
                const wire_number = try std.fmt.parseInt(Circuit.Node.Index, wire_number_raw, 10);
                parser.adjustMaxWireNumber(&.{wire_number});
                try parser.circuit_inputs.append(parser.gpa, wire_number);
            }
        } else if (std.mem.eql(u8, "O", line_type)) {
            while (iter.next()) |wire_number_raw| {
                const wire_number = try std.fmt.parseInt(Circuit.Node.Index, wire_number_raw, 10);
                parser.adjustMaxWireNumber(&.{wire_number});
                try parser.circuit_outputs.append(parser.gpa, wire_number);
            }
        } else if (std.mem.eql(u8, "0", line_type)) {
            try parser.parseConstant(&iter, .zero);
        } else if (std.mem.eql(u8, "1", line_type)) {
            try parser.parseConstant(&iter, .one);
        } else if (std.mem.eql(u8, "I", line_type)) {
            try parser.parseOneInput(&iter, .inv);
        } else if (std.mem.eql(u8, "A", line_type)) {
            try parser.parseTwoInput(&iter, .@"and");
        } else if (std.mem.eql(u8, "E", line_type)) {
            try parser.parseTwoInput(&iter, .xor);
        } else if (std.mem.eql(u8, "Y", line_type)) {
            try parser.parseTwoInput(&iter, .y);

            const programming_bits_line = (try programming_reader.readUntilDelimiterOrEof(&buf, '\n')) orelse
                return error.ExpectedProgrammingBits;
            const programming_bit = try std.fmt.parseInt(u1, programming_bits_line, 10);
            try parser.circuit_programming_bits.append(parser.gpa, programming_bit);
        } else if (std.mem.eql(u8, "X", line_type)) {
            try parser.parseTwoInputTwoOutput(&iter, .x);

            const programming_bits_line = (try programming_reader.readUntilDelimiterOrEof(&buf, '\n')) orelse
                return error.ExpectedProgrammingBits;
            const programming_bit = try std.fmt.parseInt(u1, programming_bits_line, 10);
            try parser.circuit_programming_bits.append(parser.gpa, programming_bit);
        } else if (std.mem.eql(u8, "L", line_type)) {
            try parser.parseLut(&iter, .lut);
        } else if (std.mem.eql(u8, "U", line_type)) {
            try parser.parseUlut(&iter, .ulut);

            const programming_bits_line = (try programming_reader.readUntilDelimiterOrEof(&buf, '\n')) orelse
                return error.ExpectedProgrammingBits;
            var programming_bits_iter = std.mem.tokenize(u8, programming_bits_line, " ");
            while (programming_bits_iter.next()) |programming_bit_raw| {
                const programming_bit = try std.fmt.parseInt(u1, programming_bit_raw, 10);
                try parser.circuit_programming_bits.append(parser.gpa, programming_bit);
            }
        } else if (std.mem.eql(u8, "S", line_type)) {
            try parser.parseOneInput(&iter, .y2s);
        } else if (std.mem.eql(u8, "B", line_type)) {
            try parser.parseOneInput(&iter, .s2y);
        } else {
            return error.UnsupportedType;
        }
    }
}

fn parseConstant(
    parser: *Parser,
    iter: *std.mem.TokenIterator(u8),
    tag: Circuit.Node.Tag,
) !void {
    const output_raw = iter.next() orelse return error.ExpectedWireNumber;
    const output = try std.fmt.parseInt(Circuit.Node.Index, output_raw, 10);

    parser.adjustMaxWireNumber(&.{output});

    try parser.addNode(.{
        .tag = tag,
        .data = .{ .constant = .{ .output = output } },
    });
}

fn parseOneInput(
    parser: *Parser,
    iter: *std.mem.TokenIterator(u8),
    tag: Circuit.Node.Tag,
) !void {
    const input_raw = iter.next() orelse return error.ExpectedWireNumber;
    const input = try std.fmt.parseInt(Circuit.Node.Index, input_raw, 10);
    const output_raw = iter.next() orelse return error.ExpectedWireNumber;
    const output = try std.fmt.parseInt(Circuit.Node.Index, output_raw, 10);

    parser.adjustMaxWireNumber(&.{ input, output });

    try parser.addNode(.{
        .tag = tag,
        .data = .{ .one_input = .{
            .input = input,
            .output = output,
        } },
    });
}

fn parseTwoInput(
    parser: *Parser,
    iter: *std.mem.TokenIterator(u8),
    tag: Circuit.Node.Tag,
) !void {
    const input_a_raw = iter.next() orelse return error.ExpectedWireNumber;
    const input_a = try std.fmt.parseInt(Circuit.Node.Index, input_a_raw, 10);
    const input_b_raw = iter.next() orelse return error.ExpectedWireNumber;
    const input_b = try std.fmt.parseInt(Circuit.Node.Index, input_b_raw, 10);
    const output_raw = iter.next() orelse return error.ExpectedWireNumber;
    const output = try std.fmt.parseInt(Circuit.Node.Index, output_raw, 10);

    parser.adjustMaxWireNumber(&.{ input_a, input_b, output });

    try parser.addNode(.{
        .tag = tag,
        .data = .{ .two_input = .{
            .input_a = input_a,
            .input_b = input_b,
            .output = output,
        } },
    });
}

fn parseTwoInputTwoOutput(
    parser: *Parser,
    iter: *std.mem.TokenIterator(u8),
    tag: Circuit.Node.Tag,
) !void {
    const input_a_raw = iter.next() orelse return error.ExpectedWireNumber;
    const input_a = try std.fmt.parseInt(Circuit.Node.Index, input_a_raw, 10);
    const input_b_raw = iter.next() orelse return error.ExpectedWireNumber;
    const input_b = try std.fmt.parseInt(Circuit.Node.Index, input_b_raw, 10);
    const output_a_raw = iter.next() orelse return error.ExpectedWireNumber;
    const output_a = try std.fmt.parseInt(Circuit.Node.Index, output_a_raw, 10);
    const output_b_raw = iter.next() orelse return error.ExpectedWireNumber;
    const output_b = try std.fmt.parseInt(Circuit.Node.Index, output_b_raw, 10);

    parser.adjustMaxWireNumber(&.{ input_a, input_b, output_a, output_b });

    try parser.addNode(.{
        .tag = tag,
        .data = .{ .two_input_two_output = .{
            .input_a = input_a,
            .input_b = input_b,
            .output_a = output_a,
            .output_b = output_b,
        } },
    });
}

fn parseLut(
    parser: *Parser,
    iter: *std.mem.TokenIterator(u8),
    tag: Circuit.Node.Tag,
) !void {
    const offset = parser.circuit_luts.items.len;
    const table_offset = parser.circuit_lut_tables.items.len;

    var penultimate_wire_number_raw = iter.next() orelse return error.AtLeastOneLutEntryExpected;
    var last_wire_number_raw = iter.next() orelse return error.ExpectedOneOutput;

    while (iter.next()) |wire_number_raw| {
        const penultimate_wire_number = try std.fmt.parseInt(Circuit.Node.Index, penultimate_wire_number_raw, 10);
        try parser.circuit_luts.append(parser.gpa, penultimate_wire_number);

        penultimate_wire_number_raw = last_wire_number_raw;
        last_wire_number_raw = wire_number_raw;
    }
    const arity = @intCast(u8, parser.circuit_luts.items.len - offset);

    const output = try std.fmt.parseInt(Circuit.Node.Index, penultimate_wire_number_raw, 10);

    for (last_wire_number_raw) |table_bit_raw| {
        const table_bit = try std.fmt.parseInt(u1, &.{table_bit_raw}, 10);
        try parser.circuit_lut_tables.append(parser.gpa, table_bit);
    }

    parser.adjustMaxWireNumber(parser.circuit_luts.items[offset..][0..arity]);
    parser.adjustMaxWireNumber(&.{output});

    try parser.addNode(.{
        .tag = tag,
        .data = .{ .lut = .{
            .offset = offset,
            .table_offset = table_offset,
            .arity = arity,
            .output = output,
        } },
    });
}

fn parseUlut(
    parser: *Parser,
    iter: *std.mem.TokenIterator(u8),
    tag: Circuit.Node.Tag,
) !void {
    const offset = parser.circuit_luts.items.len;

    const first_wire_number_raw = iter.next() orelse return error.AtLeastOneLutEntryExpected;
    var last_wire_number = try std.fmt.parseInt(Circuit.Node.Index, first_wire_number_raw, 10);
    while (iter.next()) |wire_number_raw| {
        try parser.circuit_luts.append(parser.gpa, last_wire_number);

        const wire_number = try std.fmt.parseInt(Circuit.Node.Index, wire_number_raw, 10);
        last_wire_number = wire_number;
    }
    const arity = @intCast(u8, parser.circuit_luts.items.len - offset);

    const output = last_wire_number;

    parser.adjustMaxWireNumber(parser.circuit_luts.items[offset..][0..arity]);
    parser.adjustMaxWireNumber(&.{output});

    try parser.addNode(.{
        .tag = tag,
        .data = .{ .ulut = .{
            .offset = offset,
            .arity = arity,
            .output = output,
        } },
    });
}
