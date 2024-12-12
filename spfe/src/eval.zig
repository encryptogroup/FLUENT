const std = @import("std");

const Circuit = @import("Circuit.zig");
const BristolParser = @import("BristolParser.zig");
const Parser = @import("Parser.zig");
const EvalCircuit = @import("EvalCircuit.zig");

const log = std.log.scoped(.convert);

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    log.err(format, args);
    std.process.exit(1);
}

const usage =
    \\usage: {s} [circuit file] [input]
    \\
    \\Supported file types:
    \\        .bristol  Bristol circuit format
    \\        .spfe     SPFE circuit format
    \\
;

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
    if (args.len != 3) {
        std.debug.print(usage, .{args[0]});
        fatal("expected circuit file and input", .{});
    }

    const input_file_path = args[1];
    const raw_input = args[2];

    const inputs = try arena.alloc(u1, raw_input.len);
    for (raw_input) |x, i| {
        switch (x) {
            '0' => inputs[i] = 0,
            '1' => inputs[i] = 1,
            else => fatal("Invalid input bit {} at position {}", .{ x, i }),
        }
    }

    const input_file_dirname = std.fs.path.dirname(input_file_path) orelse ".";
    const input_file_basename = std.fs.path.basename(input_file_path);

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

    const stdout = std.io.getStdOut().writer();
    const outputs = try EvalCircuit.evaluateCircuit(arena, circuit, inputs);
    for (outputs) |bit| try stdout.print("{}", .{bit});
    try stdout.print("\n", .{});
}
