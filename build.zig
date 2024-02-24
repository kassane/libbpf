//! Requires zig version: 0.12.0 or higher (w/ pkg-manager)
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .whitelist = permissive_targets,
    });
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "bpf",
        .target = target,
        .optimize = optimize,
    });
    if (optimize == .Debug or optimize == .ReleaseSafe)
        lib.bundle_compiler_rt = true
    else
        lib.root_module.strip = true;
    lib.addIncludePath(.{ .path = "src" });
    lib.addIncludePath(.{ .path = "include" });
    lib.addIncludePath(.{ .path = "include/uapi" });
    lib.addCSourceFiles(.{ .files = src, .flags = &.{
        "-Wall",
        "-Wextra",
        "-Wpedantic",
    } });
    lib.defineCMacro("_LARGEFILE64_SOURCE", null);
    lib.defineCMacro("_FILE_OFFSET_BITS", "64");
    lib.linkSystemLibrary("elf");
    lib.linkSystemLibrary("z");
    lib.linkLibC();
    // copy all headers to zig-out/include
    lib.installHeadersDirectory("include", "");
    lib.installHeadersDirectoryOptions(.{
        .source_dir = .{ .path = "src" },
        .install_dir = .header,
        .install_subdir = "",
        .exclude_extensions = &.{
            "c",
            "Makefile",
            "map",
            "template",
        },
    });
    b.installArtifact(lib);
}

const src = &.{
    "src/btf.c",
    "src/btf_dump.c",
    "src/usdt.c",
    "src/libbpf_errno.c",
    "src/linker.c",
    "src/relo_core.c",
    "src/str_error.c",
    "src/libbpf.c",
    "src/bpf_prog_linfo.c",
    "src/hashmap.c",
    "src/libbpf_probes.c",
    "src/bpf.c",
    "src/zip.c",
    "src/netlink.c",
    "src/gen_loader.c",
    "src/ringbuf.c",
    "src/strset.c",
    "src/nlattr.c",
};

const permissive_targets: []const std.Target.Query = &.{
    .{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
        .abi = .gnu,
    },
    .{
        .cpu_arch = .x86,
        .os_tag = .linux,
        .abi = .gnu,
    },
    .{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
        .abi = .musl,
    },
    .{
        .cpu_arch = .x86,
        .os_tag = .linux,
        .abi = .musl,
    },
    .{
        .cpu_arch = .aarch64,
        .os_tag = .linux,
        .abi = .gnu,
    },
    .{
        .cpu_arch = .aarch64,
        .os_tag = .linux,
        .abi = .musl,
    },
    .{
        .cpu_arch = .riscv64,
        .os_tag = .linux,
        .abi = .gnu,
        // issue: https://github.com/ziglang/zig/issues/3340
    },
    .{
        .cpu_arch = .riscv64,
        .os_tag = .linux,
        .abi = .musl,
    },
    .{
        .cpu_arch = .powerpc64,
        .os_tag = .linux,
        .abi = .gnu,
    },
    .{
        .cpu_arch = .powerpc64,
        .os_tag = .linux,
        .abi = .musl,
    },
};
// see all targets list:
// run: zig targets | jq .libc (json format)
