const std = @import("std");
const soulib = @import("soulib");

const utils = @import("utils.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const path = utils.getPathArgs(allocator);
    const fileBytes = try utils.readFileBytes(allocator, path);

    const dcx = try soulib.DCX.read(
        allocator,
        fileBytes,
    );

    std.debug.print("HEADER:\n    Magic: {c}\n    Compression Type: {c}\n    Compressed size: {d}\n    Decompressed size: {d}\n", .{
        dcx.header.dcx,
        dcx.header.format,
        dcx.header.compressedSize,
        dcx.header.uncompressedSize,
    });

    // Use the parsed data (e.g., print sizes)
    std.debug.print("BODY:\n    Length: {d}\n    Summary: {x}\n", .{
        dcx.data.len,
        dcx.data[0..32],
    });
}
