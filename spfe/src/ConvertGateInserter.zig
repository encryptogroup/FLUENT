const std = @import("std");
const assert = std.debug.assert;

const Circuit = @import("Circuit.zig");

const ConvertGateInserter = @This();

gpa: std.mem.Allocator,

circuit: Circuit,

circuit_nodes: std.MultiArrayList(Circuit.Node) = .{},
circuit_luts: std.ArrayListUnmanaged(Circuit.Node.Index) = .{},
circuit_inputs: std.ArrayListUnmanaged(Circuit.Node.Index) = .{},
circuit_outputs: std.ArrayListUnmanaged(Circuit.Node.Index) = .{},
circuit_lut_tables: std.ArrayListUnmanaged(u1) = .{},
circuit_programming_bits: std.ArrayListUnmanaged(u1) = .{},
circuit_max_wire_number: Circuit.Node.Index = 0,

/// Maps each original wire number to a Yao or SPLUT version of the
/// wire
wire_yao_wire: std.AutoHashMapUnmanaged(Circuit.Node.Index, Circuit.Node.Index) = .{},
wire_splut_wire: std.AutoHashMapUnmanaged(Circuit.Node.Index, Circuit.Node.Index) = .{},

next_free_wire_number: Circuit.Node.Index = 0,

err_msg: ?ErrorMsg = null,

const ErrorMsg = struct {
    msg: []const u8,
};

const InnerError = error{
    OutOfMemory,
    PassFail,
};

pub fn run(cgi: *ConvertGateInserter) InnerError!Circuit {
    // Programming bits can be added as-is
    try cgi.circuit_programming_bits.appendSlice(cgi.gpa, cgi.circuit.programming_bits);

    // LUT tables can be added as-is
    try cgi.circuit_lut_tables.appendSlice(cgi.gpa, cgi.circuit.lut_tables);

    // Make space for the LUT inputs
    try cgi.circuit_luts.resize(cgi.gpa, cgi.circuit.luts.len);

    try cgi.processInputs();

    try cgi.processGates();

    try cgi.processOutputs();

    return Circuit{
        .nodes = cgi.circuit_nodes.toOwnedSlice(),
        .luts = cgi.circuit_luts.toOwnedSlice(cgi.gpa),
        .inputs = cgi.circuit_inputs.toOwnedSlice(cgi.gpa),
        .outputs = cgi.circuit_outputs.toOwnedSlice(cgi.gpa),
        .lut_tables = cgi.circuit_lut_tables.toOwnedSlice(cgi.gpa),
        .programming_bits = cgi.circuit_programming_bits.toOwnedSlice(cgi.gpa),
        .max_wire_number = cgi.next_free_wire_number - 1,
    };
}

fn fail(cgi: *ConvertGateInserter, comptime format: []const u8, args: anytype) InnerError {
    @setCold(true);
    assert(cgi.err_msg == null);
    cgi.err_msg = ErrorMsg{ .msg = try std.fmt.allocPrint(cgi.gpa, format, args) };
    return error.PassFail;
}

fn addNode(cgi: *ConvertGateInserter, node: Circuit.Node) !void {
    try cgi.circuit_nodes.ensureUnusedCapacity(cgi.gpa, 1);
    cgi.circuit_nodes.appendAssumeCapacity(node);
}

const WireType = enum { yao, splut };

fn getWireOfType(
    cgi: *ConvertGateInserter,
    ty: WireType,
    original_wire_number: Circuit.Node.Index,
) !Circuit.Node.Index {
    switch (ty) {
        .yao => {
            const gop = try cgi.wire_yao_wire.getOrPut(cgi.gpa, original_wire_number);
            if (!gop.found_existing) {
                // There should always be at least either a Yao
                // version or a SPLUT version of this wire
                const splut_wire_number = cgi.wire_splut_wire.get(original_wire_number).?; // see note above
                const yao_wire_number = cgi.next_free_wire_number;
                cgi.next_free_wire_number += 1;

                try cgi.addNode(.{
                    .tag = .s2y,
                    .data = .{ .one_input = .{
                        .input = splut_wire_number,
                        .output = yao_wire_number,
                    } },
                });

                gop.value_ptr.* = yao_wire_number;
            }
            return gop.value_ptr.*;
        },
        .splut => {
            const gop = try cgi.wire_splut_wire.getOrPut(cgi.gpa, original_wire_number);
            if (!gop.found_existing) {
                // There should always be at least either a Yao
                // version or a SPLUT version of this wire
                const yao_wire_number = cgi.wire_yao_wire.get(original_wire_number).?; // see note above
                const splut_wire_number = cgi.next_free_wire_number;
                cgi.next_free_wire_number += 1;

                try cgi.addNode(.{
                    .tag = .y2s,
                    .data = .{ .one_input = .{
                        .input = yao_wire_number,
                        .output = splut_wire_number,
                    } },
                });

                gop.value_ptr.* = splut_wire_number;
            }
            return gop.value_ptr.*;
        },
    }
}

fn getNewWireOfType(
    cgi: *ConvertGateInserter,
    ty: WireType,
    original_wire_number: Circuit.Node.Index,
) !Circuit.Node.Index {
    const wire_number = cgi.next_free_wire_number;
    cgi.next_free_wire_number += 1;

    switch (ty) {
        .yao => try cgi.wire_yao_wire.put(cgi.gpa, original_wire_number, wire_number),
        .splut => try cgi.wire_splut_wire.put(cgi.gpa, original_wire_number, wire_number),
    }

    return wire_number;
}

fn processInputs(cgi: *ConvertGateInserter) !void {
    for (cgi.circuit.inputs) |original_wire_number| {
        const new_wire_number = cgi.next_free_wire_number;
        const inv = new_wire_number + 1;
        const invinv = new_wire_number + 2;
        const converted = new_wire_number + 3;
        cgi.next_free_wire_number += 4;

        try cgi.addNode(.{
            .tag = .inv,
            .data = .{ .one_input = .{
                .input = new_wire_number,
                .output = inv,
            } },
        });
        try cgi.addNode(.{
            .tag = .inv,
            .data = .{ .one_input = .{
                .input = inv,
                .output = invinv,
            } },
        });
        try cgi.addNode(.{
            .tag = .y2s,
            .data = .{ .one_input = .{
                .input = invinv,
                .output = converted,
            } },
        });

        try cgi.wire_yao_wire.put(cgi.gpa, original_wire_number, new_wire_number);
        try cgi.wire_splut_wire.put(cgi.gpa, original_wire_number, converted);
        try cgi.circuit_inputs.append(cgi.gpa, new_wire_number);
    }
}

fn processGates(cgi: *ConvertGateInserter) !void {
    try cgi.circuit_nodes.ensureUnusedCapacity(cgi.gpa, cgi.circuit.nodes.len);

    const tags = cgi.circuit.nodes.items(.tag);
    const datas = cgi.circuit.nodes.items(.data);
    for (tags) |tag, i| {
        const data: Circuit.Node.Data = switch (tag) {
            .zero, .one => blk: {
                const constant = datas[i].constant;
                break :blk .{ .constant = .{
                    .output = try cgi.getNewWireOfType(.yao, constant.output),
                } };
            },
            .inv => blk: {
                const one_input = datas[i].one_input;
                break :blk .{ .one_input = .{
                    .input = try cgi.getWireOfType(.yao, one_input.input),
                    .output = try cgi.getNewWireOfType(.yao, one_input.output),
                } };
            },
            .@"and", .xor, .y => blk: {
                const two_input = datas[i].two_input;
                break :blk .{ .two_input = .{
                    .input_a = try cgi.getWireOfType(.yao, two_input.input_a),
                    .input_b = try cgi.getWireOfType(.yao, two_input.input_b),
                    .output = try cgi.getNewWireOfType(.yao, two_input.output),
                } };
            },
            .x => blk: {
                const two_input_two_output = datas[i].two_input_two_output;
                break :blk .{ .two_input_two_output = .{
                    .input_a = try cgi.getWireOfType(.yao, two_input_two_output.input_a),
                    .input_b = try cgi.getWireOfType(.yao, two_input_two_output.input_b),
                    .output_a = try cgi.getNewWireOfType(.yao, two_input_two_output.output_a),
                    .output_b = try cgi.getNewWireOfType(.yao, two_input_two_output.output_b),
                } };
            },
            .lut => blk: {
                const lut = datas[i].lut;

                for (cgi.circuit.luts[lut.offset..][0..lut.arity]) |input, j| {
                    cgi.circuit_luts.items[lut.offset + j] = try cgi.getWireOfType(.splut, input);
                }

                break :blk .{ .lut = .{
                    .offset = lut.offset,
                    .table_offset = lut.table_offset,
                    .arity = lut.arity,
                    .output = try cgi.getNewWireOfType(.splut, lut.output),
                } };
            },
            .ulut => blk: {
                const ulut = datas[i].ulut;

                for (cgi.circuit.luts[ulut.offset..][0..ulut.arity]) |input, j| {
                    cgi.circuit_luts.items[ulut.offset + j] = try cgi.getWireOfType(.yao, input);
                }

                break :blk .{ .ulut = .{
                    .offset = ulut.offset,
                    .arity = ulut.arity,
                    .output = try cgi.getNewWireOfType(.yao, ulut.output),
                } };
            },
            .y2s, .s2y => return cgi.fail("ConverterGateInserter cannot handle Y2S/S2Y gates", .{}),
        };

        // TODO this should be appendAssumeCapacity
        try cgi.circuit_nodes.append(cgi.gpa, .{
            .tag = tag,
            .data = data,
        });
    }
}

fn processOutputs(cgi: *ConvertGateInserter) !void {
    try cgi.circuit_outputs.ensureUnusedCapacity(cgi.gpa, cgi.circuit.outputs.len);

    for (cgi.circuit.outputs) |original_wire_number| {
        const new_wire_number = blk: {
            if (cgi.wire_yao_wire.get(original_wire_number)) |w| {
                break :blk w;
            } else if (cgi.wire_splut_wire.get(original_wire_number)) |w| {
                const wire_number = cgi.next_free_wire_number;
                cgi.next_free_wire_number += 1;

                try cgi.circuit_nodes.append(cgi.gpa, .{
                    .tag = .s2y,
                    .data = .{ .one_input = .{
                        .input = w,
                        .output = wire_number,
                    } },
                });

                break :blk wire_number;
            } else {
                // There should always be at least either a Yao
                // version or a SPLUT version of this wire
                unreachable; // see note above
            }
        };

        cgi.circuit_outputs.appendAssumeCapacity(new_wire_number);
    }
}
