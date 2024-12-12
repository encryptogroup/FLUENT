const std = @import("std");

const Case = @import("../src/test.zig").Case;

pub fn addCases(arena: std.mem.Allocator, cases: *std.ArrayList(Case)) !void {
    for ([_]?u8{ null, 2, 3, 4 }) |pub_lut_size| {
        try addCasesWithPubLutSize(arena, cases, pub_lut_size);
    }
}

pub fn addCasesWithPubLutSize(
    arena: std.mem.Allocator,
    cases: *std.ArrayList(Case),
    pub_lut_size: ?u8,
) !void {
    for ([_][]const u8{ "simple/simple.v", "simple/simple_depth_1.v", "simple/simple_depth_2.v" }) |path| {
        try cases.append(.{
            .name = path,
            .input_file_path = path,
            .pub_lut_size = pub_lut_size,
            // .output_equality_check = .{
            //     .expected_spfe_file = @embedFile("simple/simple.spfe"),
            //     .expected_prog_file = @embedFile("simple/simple.spfe.prog"),
            // },
        });
    }
    for ([_][]const u8{ "invert/invert.v", "invert/invert_depth_3.v" }) |path| {
        try cases.append(.{
            .name = path,
            .input_file_path = path,
            .pub_lut_size = pub_lut_size,
            // .output_equality_check = .{
            //     .expected_spfe_file = @embedFile("invert/invert.spfe"),
            //     .expected_prog_file = @embedFile("invert/invert.spfe.prog"),
            // },
        });
    }
    for ([_][]const u8{ "constant/constant.v", "constant/constant_depth_2.v" }) |path| {
        try cases.append(.{
            .name = path,
            .input_file_path = path,
            .pub_lut_size = pub_lut_size,
            // .output_equality_check = .{
            //     .expected_spfe_file = @embedFile("constant/constant.spfe"),
            //     .expected_prog_file = @embedFile("constant/constant.spfe.prog"),
            // },
        });
    }
    for ([_][]const u8{ "and2/and2.v", "and2/and2_depth_3.v" }) |path| {
        try cases.append(.{
            .name = path,
            .input_file_path = path,
            .pub_lut_size = pub_lut_size,
            // .output_equality_check = .{
            //     .expected_spfe_file = @embedFile("and2/and2.spfe"),
            //     .expected_prog_file = @embedFile("and2/and2.spfe.prog"),
            // },
        });
    }
    for ([_][]const u8{ "reused_output/reused_output.v", "reused_output/reused_output_depth_2.v" }) |path| {
        try cases.append(.{
            .name = path,
            .input_file_path = path,
            .pub_lut_size = pub_lut_size,
            // .output_equality_check = .{
            //     .expected_spfe_file = @embedFile("reused_output/reused_output.spfe"),
            //     .expected_prog_file = @embedFile("reused_output/reused_output.spfe.prog"),
            // },
            .evaluate_check = &.{
                .{
                    .input = "00",
                    .output = "00",
                },
                .{
                    .input = "11",
                    .output = "11",
                },
                .{
                    .input = "10",
                    .output = "00",
                },
            },
        });
    }
    for ([_]u8{ 2, 3, 4 }) |priv_lut_size| {
        try cases.append(.{
            .name = try std.fmt.allocPrint(arena, "and4/and4.v priv_lut_size={}", .{priv_lut_size}),
            .input_file_path = "and4/and4.v",
            .pub_lut_size = pub_lut_size,
            .priv_lut_size = priv_lut_size,
            .evaluate_check = &.{
                .{
                    .input = "0000",
                    .output = "0",
                },
                .{
                    .input = "1111",
                    .output = "1",
                },
                .{
                    .input = "1001",
                    .output = "0",
                },
            },
        });
        for ([_][]const u8{ "add32/add32priv.v", "add32/add32.v" }) |path| {
            try cases.append(.{
                .name = try std.fmt.allocPrint(arena, "{s} priv_lut_size={}", .{ path, priv_lut_size }),
                .input_file_path = path,
                .pub_lut_size = pub_lut_size,
                .priv_lut_size = priv_lut_size,
                .evaluate_check = &.{
                    .{
                        .input = "0000000000000000000000000000000000000000000000000000000000000000",
                        .output = "00000000000000000000000000000000",
                    },
                    .{
                        .input = "1000000000000000000000000000000000000000000000000000000000000000",
                        .output = "10000000000000000000000000000000",
                    },
                    .{
                        .input = "1000000000000000000000000000000010000000000000000000000000000000",
                        .output = "01000000000000000000000000000000",
                    },
                    .{
                        .input = "1010000000000000000000000000000010000000000000000000000000000000",
                        .output = "01100000000000000000000000000000",
                    },
                    .{
                        .input = "1000000000000000000000000000000000000000000000000000000000000001",
                        .output = "10000000000000000000000000000001",
                    },
                    .{
                        .input = "1111111111111111111111111111111100000000000000000000000000000000",
                        .output = "11111111111111111111111111111111",
                    },
                    .{
                        .input = "1111111111111111111111111111111110000000000000000000000000000000",
                        .output = "00000000000000000000000000000000",
                    },
                },
            });
        }
        for ([_][]const u8{ "cmp32/cmp32priv.v", "cmp32/cmp32.v" }) |path| {
            try cases.append(.{
                .name = try std.fmt.allocPrint(arena, "{s} priv_lut_size={}", .{ path, priv_lut_size }),
                .input_file_path = path,
                .pub_lut_size = pub_lut_size,
                .priv_lut_size = priv_lut_size,
                .extra_compiler_args = &.{"--dont-optimize-area"}, // FIXME this fix is necessary for newer Yosys+ABC versions
                .evaluate_check = &.{
                    .{
                        .input = "0000000000000000000000000000000000000000000000000000000000000000",
                        .output = "0",
                    },
                    .{
                        .input = "1000000000000000000000000000000000000000000000000000000000000000",
                        .output = "1",
                    },
                    .{
                        .input = "1000000000000000000000000000000010000000000000000000000000000000",
                        .output = "0",
                    },
                    .{
                        .input = "1010000000000000000000000000000010000000000000000000000000000000",
                        .output = "1",
                    },
                    .{
                        .input = "1000000000000000000000000000000000000000000000000000000000000001",
                        .output = "0",
                    },
                    .{
                        .input = "1111111111111111111111111111111100000000000000000000000000000000",
                        .output = "1",
                    },
                    .{
                        .input = "1111111111111111111111111111111110000000000000000000000000000000",
                        .output = "1",
                    },
                },
            });
        }
        try cases.append(.{
            .name = try std.fmt.allocPrint(arena, "cond_increment/cond_increment.v priv_lut_size={}", .{priv_lut_size}),
            .input_file_path = "cond_increment/cond_increment.v",
            .pub_lut_size = pub_lut_size,
            .priv_lut_size = priv_lut_size,
            .evaluate_check = &.{
                .{
                    .input = "00000000000000000000000000000000",
                    .output = "10000000000000000000000000000000",
                },
                .{
                    .input = "00000000000000000000000000000001",
                    .output = "00000000000000000000000000000001",
                },
                .{
                    .input = "00000000000000000000000000100000",
                    .output = "00000000000000000000000000100000",
                },
                .{
                    .input = "11100110000000000000000000000000",
                    .output = "00010110000000000000000000000000",
                },
                .{
                    .input = "11100110000000000100000000000000",
                    .output = "11100110000000000100000000000000",
                },
            },
        });
    }
}
