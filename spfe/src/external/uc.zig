const std = @import("std");

const run = @import("run.zig").run;

fn runUcCompiler(
    arena: std.mem.Allocator,
    working_dir: std.fs.Dir,
    verbose: bool,
    uc_compiler_path: []const u8,
    bench_file_path: []const u8,
    construction: Construction,
) !void {
    var args = std.ArrayList([]const u8).init(arena);
    try args.appendSlice(&.{ uc_compiler_path, "-f", bench_file_path, "-l" });
    switch (construction) {
        .luc => {},
        .vuc => try args.append("-i"),
    }

    try run(
        arena,
        working_dir,
        verbose,
        args.items,
    );
}

pub const CompiledUc = struct {
    circuit_file_path: []const u8,
    prog_file_path: []const u8,

    pub fn deinit(self: *CompiledUc, allocator: std.mem.Allocator) void {
        allocator.free(self.circuit_file_path);
        allocator.free(self.prog_file_path);
    }
};

pub const Construction = enum {
    luc,
    vuc,
};

pub fn compileUc(
    allocator: std.mem.Allocator,
    working_dir: std.fs.Dir,
    verbose: bool,
    bench_file_path: []const u8,
    module_name: []const u8,
    lut_size: u8,
    construction: Construction,
    keep_intermediate_files: bool,
) !CompiledUc {
    var arena_instance = std.heap.ArenaAllocator.init(allocator);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    try working_dir.makePath("outputs");
    try working_dir.makePath("circuits");

    const uc_compiler_path = try std.fs.path.join(arena, &.{ try std.fs.selfExeDirPathAlloc(arena), "UC" });
    const circuit_file_path = try std.fmt.allocPrint(allocator, "{s}_{s}_{}.circ", .{ bench_file_path, module_name, lut_size });
    const prog_file_path = try std.fmt.allocPrint(allocator, "{s}_{s}_{}.prog", .{ bench_file_path, module_name, lut_size });

    try runUcCompiler(arena, working_dir, verbose, uc_compiler_path, bench_file_path, construction);

    try working_dir.rename("outputs/circuit", circuit_file_path);
    try working_dir.rename("outputs/programming", prog_file_path);

    if (!keep_intermediate_files) {
        try working_dir.deleteTree("outputs");
        try working_dir.deleteTree("circuits");
        try working_dir.deleteFile("benchmarks.txt");
    }

    return CompiledUc{
        .circuit_file_path = circuit_file_path,
        .prog_file_path = prog_file_path,
    };
}
