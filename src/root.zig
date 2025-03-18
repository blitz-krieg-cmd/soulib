const std = @import("std");
pub const DCX = @import("dcx.zig");

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

    data: [*:0]u8,
};

export fn parseDCX(path: [*:0]const u8) DCX_C {
    const allocator = std.heap.c_allocator;

    var file = std.fs.openFileAbsoluteZ(
        path,
        .{ .mode = .read_only },
    ) catch unreachable;
    defer file.close();

    const bytes = file.readToEndAlloc(allocator, file.getEndPos() catch unreachable) catch unreachable;

    const dcx = DCX.read(allocator, bytes) catch unreachable;

    return DCX_C{
        .dcx = dcx.header.dcx,
        .dcsOffset = dcx.header.dcsOffset,
        .dcpOffset = dcx.header.dcpOffset,
        .dcs = dcx.header.dcs,
        .uncompressedSize = dcx.header.uncompressedSize,
        .compressedSize = dcx.header.compressedSize,
        .dcp = dcx.header.dcp,
        .format = dcx.header.format,
        .dca = dcx.header.dca,
        .dcaSize = dcx.header.dcaSize,
        .data = allocator.dupeZ(u8, dcx.data) catch unreachable,
    };
}

test {
    @import("std").testing.refAllDecls(@This());
}
