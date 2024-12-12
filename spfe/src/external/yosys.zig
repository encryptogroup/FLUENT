const std = @import("std");

const run = @import("run.zig").run;

fn runYosysScript(
    allocator: std.mem.Allocator,
    working_dir: std.fs.Dir,
    verbose: bool,
    yosys_script: []const u8,
) !void {
    const script_file_name = "tmp_spfe_yosys_script";
    try working_dir.writeFile(script_file_name, yosys_script);

    try run(allocator, working_dir, verbose, &.{ "yosys", "-s", script_file_name });

    try working_dir.deleteFile(script_file_name);
}

fn runAbcScript(
    allocator: std.mem.Allocator,
    working_dir: std.fs.Dir,
    verbose: bool,
    abc_script: []const u8,
) !void {
    const script_file_name = "tmp_spfe_abc_script";
    try working_dir.writeFile(script_file_name, abc_script);

    try run(allocator, working_dir, verbose, &.{ "yosys-abc", "-f", script_file_name });

    try working_dir.deleteFile(script_file_name);
}

pub fn verilogToJsonNoSynth(
    allocator: std.mem.Allocator,
    working_dir: std.fs.Dir,
    verbose: bool,
    verilog_file_path: []const u8,
    json_file_path: []const u8,
) !void {
    var arena_instance = std.heap.ArenaAllocator.init(allocator);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    const yosys_script = try std.fmt.allocPrint(
        arena,
        \\read_verilog {s}
        \\proc
        \\write_json {s}
    ,
        .{ verilog_file_path, json_file_path },
    );

    try runYosysScript(arena, working_dir, verbose, yosys_script);
}

pub const SynthesisScript = enum {
    synth,
    manual,
    blackbox,
};

pub fn verilogToJson(
    allocator: std.mem.Allocator,
    working_dir: std.fs.Dir,
    verbose: bool,
    verilog_file_path: []const u8,
    json_file_path: []const u8,
    torder_file_path: []const u8,
    top_level_module: []const u8,
    synthesize_modules: []const []const u8,
    blackbox_modules: []const []const u8,
    script: SynthesisScript,
    pub_lut_size: ?u8,
) !void {
    var arena_instance = std.heap.ArenaAllocator.init(allocator);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    if (pub_lut_size) |lut_size| {
        try verilogToJsonLut(
            arena,
            working_dir,
            verbose,
            verilog_file_path,
            json_file_path,
            torder_file_path,
            top_level_module,
            blackbox_modules,
            lut_size,
        );
    } else {
        switch (script) {
            .synth => try verilogToJsonSynth(
                arena,
                working_dir,
                verbose,
                verilog_file_path,
                json_file_path,
                torder_file_path,
                synthesize_modules,
            ),
            .manual => try verilogToJsonManual(
                arena,
                working_dir,
                verbose,
                verilog_file_path,
                json_file_path,
                torder_file_path,
            ),
            .blackbox => try verilogToJsonBlackbox(
                arena,
                working_dir,
                verbose,
                verilog_file_path,
                json_file_path,
                torder_file_path,
                top_level_module,
                blackbox_modules,
            ),
        }
    }
}

pub fn verilogToJsonSynth(
    arena: std.mem.Allocator,
    working_dir: std.fs.Dir,
    verbose: bool,
    verilog_file_path: []const u8,
    json_file_path: []const u8,
    torder_file_path: []const u8,
    synthesize_modules: []const []const u8,
) !void {
    const yosys_script = try std.fmt.allocPrint(
        arena,
        \\read_verilog {s}
        \\synth
        \\select {s}
        \\abc -g AND,XOR
        \\select *
        \\tee -o {s} torder
        \\write_json {s}
    ,
        .{
            verilog_file_path,
            try std.mem.join(arena, " ", synthesize_modules),
            torder_file_path,
            json_file_path,
        },
    );

    try runYosysScript(arena, working_dir, verbose, yosys_script);
}

pub fn verilogToJsonManual(
    arena: std.mem.Allocator,
    working_dir: std.fs.Dir,
    verbose: bool,
    verilog_file_path: []const u8,
    json_file_path: []const u8,
    torder_file_path: []const u8,
) !void {
    const liberty_file_name = "tmp_spfe_lib";
    const liberty =
        \\library(demo) {
        \\	cell(SPFE_NOT) {
        \\		area: 1;
        \\		pin(A) { direction: input; }
        \\		pin(Z) { direction: output; function: "A'"; }
        \\	}
        \\	cell(SPFE_XOR) {
        \\		area: 0;
        \\		pin(A) { direction: input; }
        \\		pin(B) { direction: input; }
        \\		pin(Z) { direction: output; function: "(A^B)"; }
        \\	}
        \\	cell(SPFE_AND) {
        \\		area: 500;
        \\		pin(A) { direction: input; }
        \\		pin(B) { direction: input; }
        \\		pin(Z) { direction: output; function: "(A&B)"; }
        \\	}
        \\}
        \\
    ;
    try working_dir.writeFile(liberty_file_name, liberty);

    const abc_script_file_name = "tmp_spfe_abc_script";
    const abc_script =
        \\map;
        \\
    ;
    try working_dir.writeFile(abc_script_file_name, abc_script);

    const yosys_script = try std.fmt.allocPrint(
        arena,
        \\read_verilog {s}
        \\hierarchy -check
        \\proc; fsm; opt;
        \\techmap; opt;
        \\dfflibmap -liberty {s}
        \\abc -liberty {s} -script {s}
        \\opt; clean;
        \\opt_clean -purge
        \\tee -o {s} torder
        \\write_json {s}
    ,
        .{
            verilog_file_path,
            liberty_file_name,
            liberty_file_name,
            abc_script_file_name,
            torder_file_path,
            json_file_path,
        },
    );

    try runYosysScript(arena, working_dir, verbose, yosys_script);

    try working_dir.deleteFile(liberty_file_name);
    try working_dir.deleteFile(abc_script_file_name);
}

pub fn verilogToJsonBlackbox(
    arena: std.mem.Allocator,
    working_dir: std.fs.Dir,
    verbose: bool,
    verilog_file_path: []const u8,
    json_file_path: []const u8,
    torder_file_path: []const u8,
    top_level_module: []const u8,
    blackbox_modules: []const []const u8,
) !void {
    const yosys_script = try std.fmt.allocPrint(
        arena,
        \\read_verilog {s}
        \\{s}
        \\synth -top {s} -flatten
        \\abc -g AND,XOR
        \\tee -o {s} torder
        \\write_json {s}
    ,
        .{
            verilog_file_path,
            if (blackbox_modules.len > 0) blackbox_pass: {
                const concatenated_modules = try std.mem.join(arena, " ", blackbox_modules);
                break :blackbox_pass try std.fmt.allocPrint(arena, "blackbox {s}", .{concatenated_modules});
            } else "",
            top_level_module,
            torder_file_path,
            json_file_path,
        },
    );

    try runYosysScript(arena, working_dir, verbose, yosys_script);
}

pub fn verilogToJsonLut(
    arena: std.mem.Allocator,
    working_dir: std.fs.Dir,
    verbose: bool,
    verilog_file_path: []const u8,
    json_file_path: []const u8,
    torder_file_path: []const u8,
    top_level_module: []const u8,
    blackbox_modules: []const []const u8,
    lut_size: u8,
) !void {
    const yosys_script = try std.fmt.allocPrint(
        arena,
        \\read_verilog {s}
        \\{s}
        \\synth -top {s} -flatten -lut {}
        \\tee -o {s} torder
        \\write_json {s}
    ,
        .{
            verilog_file_path,
            if (blackbox_modules.len > 0) blackbox_pass: {
                const concatenated_modules = try std.mem.join(arena, " ", blackbox_modules);
                break :blackbox_pass try std.fmt.allocPrint(arena, "blackbox {s}", .{concatenated_modules});
            } else "",
            top_level_module,
            lut_size,
            torder_file_path,
            json_file_path,
        },
    );

    try runYosysScript(arena, working_dir, verbose, yosys_script);
}

pub fn verilogModuleToBench(
    allocator: std.mem.Allocator,
    working_dir: std.fs.Dir,
    verbose: bool,
    verilog_file_path: []const u8,
    blif_file_path: []const u8,
    bench_file_path: []const u8,
    module_name: []const u8,
    lut_size: u8,
    optimize_area: bool,
) !void {
    var arena_instance = std.heap.ArenaAllocator.init(allocator);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    const yosys_script = try std.fmt.allocPrint(
        arena,
        \\read_verilog {s}
        \\hierarchy -check -top {s}
        \\flatten; opt; proc; opt; memory; opt; fsm; opt; techmap; opt;
        \\write_blif {s}
    ,
        .{ verilog_file_path, module_name, blif_file_path },
    );
    try runYosysScript(arena, working_dir, verbose, yosys_script);

    const extra_if_args: []const u8 = if (optimize_area) " -F 200 -a" else "";

    const abc_script = try std.fmt.allocPrint(
        arena,
        \\read_blif {s}
        \\strash; dc2; fraig; retime; strash; dch -f; if -K {}{s}; mfs;
        \\topo
        \\cec
        \\write_bench {s}
    ,
        .{ blif_file_path, lut_size, extra_if_args, bench_file_path },
    );
    try runAbcScript(arena, working_dir, verbose, abc_script);
}
