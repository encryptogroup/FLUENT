const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const use_aby = b.option(bool, "use-aby", "Run tests using ABY") orelse false;

    const uc_compiler = b.addExecutable("UC", null);
    uc_compiler.setTarget(target);
    uc_compiler.setBuildMode(mode);
    uc_compiler.install();
    uc_compiler.linkLibCpp();
    uc_compiler.addCSourceFiles(&.{
        "uc/UC.cpp",
        "uc/gamma/gamma.cpp",
        "uc/uc/2way/valiant.cpp",
        "uc/uc/2way/valiantBase.cpp",
        "uc/uc/2way/valiantMerged.cpp",
        "uc/uc/2way/liu.cpp",
        "uc/util/parseBench.cpp",
        "uc/util/utility.cpp",
    }, &.{
        "-Wall",
        "-std=c++17",
    });

    const compiler = b.addExecutable("spfe", "src/main.zig");
    compiler.setTarget(target);
    compiler.setBuildMode(mode);
    compiler.install();

    const convert = b.addExecutable("convert", "src/convert.zig");
    convert.setTarget(target);
    convert.setBuildMode(mode);
    convert.install();

    const eval = b.addExecutable("eval", "src/eval.zig");
    eval.setTarget(target);
    eval.setBuildMode(mode);
    eval.install();

    const tests = b.addTest("src/test.zig");
    tests.setTarget(target);
    tests.setBuildMode(mode);
    tests.addPackagePath("test_cases", "test/cases.zig");
    tests.step.dependOn(b.getInstallStep());

    const test_options = b.addOptions();
    tests.addOptions("build_options", test_options);
    test_options.addOption(bool, "use_aby", use_aby);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&tests.step);
}
