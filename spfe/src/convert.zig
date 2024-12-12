const std = @import("std");

const Circuit = @import("Circuit.zig");
const BristolParser = @import("BristolParser.zig");
const Parser = @import("Parser.zig");
const Emit = @import("Emit.zig");
const EmitVerilog = @import("EmitVerilog.zig");

const log = std.log.scoped(.convert);

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    log.err(format, args);
    std.process.exit(1);
}

const usage =
    \\usage: {s} [options] [input file]
    \\
    \\Supported file types:
    \\        .bristol  Bristol circuit format
    \\        .spfe     SPFE circuit format
    \\
    \\Options:
    \\ -f [format]      Output circuit format (possible options:
    \\                  spfe, verilog) (default=spfe)
    \\
;

const OutputFormat = enum {
    verilog,
    spfe,
};

const InputFormat = enum {
    bristol,
    spfe,
};

fn classifyFileExt(file_name: []const u8) ?InputFormat {
    if (std.mem.endsWith(u8, file_name, ".bristol")) {
        return .bristol;
    } else if (std.mem.endsWith(u8, file_name, ".spfe")) {
        return .spfe;
    } else {
        return null;
    }
}

pub fn main() !void {
    var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_instance.deinit();
    const gpa = gpa_instance.allocator();

    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    const args = try std.process.argsAlloc(arena);

    var input_file_path: ?[]const u8 = null;
    var output_format: OutputFormat = .spfe;

    {
        var i: usize = 1;
        while (i < args.len) : (i += 1) {
            const arg = args[i];
            if (std.mem.eql(u8, "-h", arg) or std.mem.eql(u8, "--help", arg)) {
                std.debug.print(usage, .{args[0]});
                std.process.exit(1);
            } else if (std.mem.eql(u8, "-f", arg)) {
                if (i + 1 >= args.len) fatal("expected parameter after '{s}'", .{arg});
                i += 1;
                output_format = std.meta.stringToEnum(OutputFormat, args[i]) orelse fatal("invalid output format '{s}'", .{args[i]});
            } else {
                if (input_file_path == null and !std.mem.startsWith(u8, arg, "-")) {
                    input_file_path = arg;
                } else {
                    fatal("unrecognized parameter: '{s}'", .{arg});
                }
            }
        }
    }

    if (input_file_path == null) fatal("no input file provided", .{});

    const input_file_dirname = std.fs.path.dirname(input_file_path.?) orelse ".";
    const input_file_basename = std.fs.path.basename(input_file_path.?);

    var working_dir = try std.fs.cwd().openDir(input_file_dirname, .{});
    defer working_dir.close();

    const input_file_type = classifyFileExt(input_file_basename) orelse {
        fatal("unrecognized input file type", .{});
    };

    const root_name = switch (input_file_type) {
        .bristol => input_file_basename[0 .. input_file_basename.len - ".bristol".len],
        .spfe => input_file_basename[0 .. input_file_basename.len - ".spfe".len],
    };

    const circuit: Circuit = switch (input_file_type) {
        .bristol => try BristolParser.parseBristol(
            arena,
            working_dir,
            input_file_basename,
        ),
        .spfe => blk: {
            const programming_file_path = try std.fmt.allocPrint(arena, "{s}.spfe.prog", .{root_name});
            break :blk try Parser.parseCircuit(
                arena,
                working_dir,
                input_file_basename,
                programming_file_path,
            );
        },
    };

    switch (output_format) {
        .spfe => {
            const spfe_file_path = try std.fmt.allocPrint(arena, "{s}.spfe", .{root_name});
            const programming_file_path = try std.fmt.allocPrint(arena, "{s}.spfe.prog", .{root_name});

            try Emit.writeCircuit(circuit, null, working_dir, spfe_file_path, programming_file_path);
        },
        .verilog => {
            const verilog_file_path = try std.fmt.allocPrint(arena, "{s}.v", .{root_name});

            try EmitVerilog.writeCircuit(circuit, working_dir, root_name, verilog_file_path);
        },
    }
}
