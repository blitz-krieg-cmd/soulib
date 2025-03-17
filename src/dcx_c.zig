const std = @import("std");
const DCX = @import("dcx.zig");

const DCX_C = extern struct {
    dcx: [4]u8,
    dcsOffset: i32,
    dcpOffset: i32,
    dcs: [4]u8,
    uncompressedSize: u32,
    compressedSize: u32,
    dcp: [4]u8,
    format: [4]u8,
    dca: [4]u8,
    dcaSize: i32,

    data: []u8,
};

pub export fn parseDCX(path: [*:0]const u8) DCX_C {
    const allocator = std.heap.c_allocator;

    var file = std.fs.openFileAbsoluteZ(
        path,
        .{ .mode = .read_only },
    ) catch |e| switch (e) {
        error.FileNotFound => {
            std.log.err("File '{s}' does not exist\n", .{path});
            return "";
        },
        else => {
            std.log.err("{?}\n", .{e});
            return "";
        },
    };
    defer file.close();

    const bytes = file.readToEndAlloc(allocator, try file.getEndPos()) catch unreachable;

    DCX.read(allocator, bytes);
}
