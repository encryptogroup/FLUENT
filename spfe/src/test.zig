const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");
const use_aby = build_options.use_aby;

pub const Case = struct {
    name: []const u8,
    input_file_path: []const u8,
    pub_lut_size: ?u8 = null,
    priv_lut_size: u8 = 2,
    output_equality_check: ?OutputEquality = null,
    evaluate_check: ?[]const AbyInputOutput = null,
    extra_compiler_args: []const []const u8 = &.{},

    pub const OutputEquality = struct {
        expected_spfe_file: []const u8,
        expected_prog_file: []const u8,
    };

    /// ABY input and output strings (e.g. "0110")
    pub const AbyInputOutput = struct {
        input: []const u8,
        output: []const u8,
    };

    pub fn run(case: Case, gpa: std.mem.Allocator) !void {
        var arena_instance = std.heap.ArenaAllocator.init(gpa);
        defer arena_instance.deinit();
        const arena = arena_instance.allocator();

        var tmp_dir = std.testing.tmpDir(.{});
        defer tmp_dir.cleanup();

        // TODO find a way to make this independent of cwd
        var test_dir = try std.fs.cwd().openDir("test", .{});
        defer test_dir.close();

        const tmp_dir_path = try std.fs.path.join(
            arena,
            &.{ "zig-cache", "tmp", &tmp_dir.sub_path },
        );
        const compiler_exe_path = try std.fs.path.join(
            arena,
            &.{ "zig-out", "bin", "spfe" },
        );
        const eval_exe_path = try std.fs.path.join(
            arena,
            &.{ "zig-out", "bin", "eval" },
        );

        const tmp_input_file_path = try std.fs.path.join(
            arena,
            &.{ tmp_dir_path, "test.v" },
        );

        try test_dir.copyFile(case.input_file_path, tmp_dir.dir, "test.v", .{});

        var arg_list = std.ArrayList([]const u8).init(arena);
        try arg_list.appendSlice(&.{
            compiler_exe_path,
            "-l",
            try std.fmt.allocPrint(arena, "{}", .{case.priv_lut_size}),
            tmp_input_file_path,
        });
        if (case.pub_lut_size) |lut_size| {
            try arg_list.appendSlice(&.{
                "-L",
                try std.fmt.allocPrint(arena, "{}", .{lut_size}),
            });
        }
        try arg_list.appendSlice(case.extra_compiler_args);
        const args = arg_list.toOwnedSlice();

        const result = try std.ChildProcess.exec(.{
            .allocator = arena,
            .argv = args,
        });
        if (result.term != .Exited or result.term.Exited != 0) {
            std.debug.print("test case {s}: The following exited abnormally with {}:\n{s}\n", .{
                case.name,
                result.term,
                try std.mem.join(arena, " ", args),
            });
            if (result.stdout.len > 0) std.debug.print("compiler stdout: {s}", .{result.stdout});
            if (result.stderr.len > 0) std.debug.print("compiler stderr: {s}", .{result.stderr});
            return error.CompilerFailed;
        }

        if (case.output_equality_check) |data| {
            const spfe = try tmp_dir.dir.readFileAlloc(arena, "test.spfe", 40 * 1024 * 1024);
            const prog = try tmp_dir.dir.readFileAlloc(arena, "test.spfe.prog", 40 * 1024 * 1024);

            try std.testing.expectEqualStrings(data.expected_spfe_file, spfe);
            try std.testing.expectEqualStrings(data.expected_prog_file, prog);
        }

        if (case.evaluate_check) |data| {
            const spfe_path = try std.fs.path.join(arena, &.{ tmp_dir_path, "test.spfe" });
            const prog_path = try std.fs.path.join(arena, &.{ tmp_dir_path, "test.spfe.prog" });

            for (data) |input_output| {
                const eval_result = try std.ChildProcess.exec(.{
                    .allocator = arena,
                    .argv = &.{
                        eval_exe_path,
                        spfe_path,
                        input_output.input,
                    },
                });
                if (eval_result.term != .Exited or eval_result.term.Exited != 0) {
                    std.debug.print("test case {s}: {s} exited abnormally: {}\n", .{
                        case.name,
                        eval_exe_path,
                        eval_result.term,
                    });
                    if (eval_result.stdout.len > 0) std.debug.print("eval stdout: {s}", .{eval_result.stdout});
                    if (eval_result.stderr.len > 0) std.debug.print("eval stderr: {s}", .{eval_result.stderr});
                    return error.EvalFailed;
                }

                const cleaned_output = std.mem.trimRight(u8, eval_result.stdout, "\n");
                try std.testing.expectEqualStrings(input_output.output, cleaned_output);
            }

            if (use_aby) {
                if (builtin.single_threaded) @panic("Running ABY test requires threads");

                const aby_exe_path = "uc_circuit_test";
                probe(aby_exe_path) catch return error.AbyFailed;

                for (data) |aby_input_output| {
                    var threads: [2]std.Thread = undefined;

                    const job: AbyJob = .{
                        .aby_exe = aby_exe_path,
                        .spfe_path = spfe_path,
                        .prog_path = prog_path,
                        .input = aby_input_output.input,
                        .expected_output = aby_input_output.output,
                    };
                    threads[0] = try std.Thread.spawn(.{}, runAby, .{ 0, job });
                    threads[1] = try std.Thread.spawn(.{}, runAby, .{ 1, job });

                    for (threads) |t| t.join();
                }
            }
        }
    }
};

fn probe(exe_path: []const u8) !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const result = try std.ChildProcess.exec(.{
        .allocator = arena,
        .argv = &.{exe_path},
    });
    switch (result.term) {
        .Exited => return,
        else => return error.ProbeFailed,
    }
}

const AbyJob = struct {
    aby_exe: []const u8,
    spfe_path: []const u8,
    prog_path: []const u8,
    input: []const u8,
    expected_output: []const u8,
};

fn runAby(
    role: u1,
    job: AbyJob,
) anyerror!void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const result = try std.ChildProcess.exec(.{
        .allocator = arena,
        .argv = &.{
            job.aby_exe,
            "-r",
            try std.fmt.allocPrint(arena, "{}", .{role}),
            "-f",
            job.spfe_path,
            "-e",
            job.prog_path,
            "-d",
            job.input,
        },
    });
    if (result.term != .Exited or result.term.Exited != 0) {
        std.debug.print("{s} exited abnormally: {}\n", .{ job.aby_exe, result.term });
        if (result.stdout.len > 0) std.debug.print("aby stdout: {s}", .{result.stdout});
        if (result.stderr.len > 0) std.debug.print("aby stderr: {s}", .{result.stderr});
        return error.AbyFailed;
    }

    // Only make role 1 check the output, otherwise we print a
    // mismatch twice
    if (role == 1) {
        var lines = std.mem.split(u8, result.stdout, "\n");
        while (lines.next()) |line| {
            const prefix = "OUTPUTS: ";
            if (std.mem.startsWith(u8, line, prefix)) {
                try std.testing.expectEqualStrings(job.expected_output, line[prefix.len..]);
            }
        }
    }
}

test {
    const allocator = std.testing.allocator;
    var cases = std.ArrayList(Case).init(allocator);
    defer cases.deinit();

    var arena_instance = std.heap.ArenaAllocator.init(allocator);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    try @import("test_cases").addCases(arena, &cases);

    var progress = std.Progress{};
    const root_node = progress.start("", 0);
    defer root_node.end();

    var tests_node = root_node.start("testing", cases.items.len);
    tests_node.activate();
    for (cases.items) |case| {
        try case.run(allocator);
        tests_node.completeOne();
    }
    tests_node.end();
}
