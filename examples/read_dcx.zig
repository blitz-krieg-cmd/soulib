const std = @import("std");
// Import the library.
const soulib = @import("soulib");
// Example Utils
const utils = @import("utils.zig");

pub fn main() !void {
    // Define the allocator to use.
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Define the file to parse over.
    const path = utils.getPathArgs(allocator);
    // Read the bytes from the file.
    const fileBytes = try utils.readFileBytes(allocator, path);

    // Parse the file.
    const dcx = try soulib.DCX.read(
        allocator,
        fileBytes,
    );

    // Use the parsed data.
    std.debug.print("HEADER:\n    Magic: {c}\n    Compression Type: {c}\n    Compressed size: {d}\n    Decompressed size: {d}\nBODY:\n    Length: {d}\n    Summary: {x}\n", .{
        dcx.header.dcx,
        dcx.header.format,
        dcx.header.compressedSize,
        dcx.header.uncompressedSize,
        dcx.data.len,
        dcx.data[0..32],
    });
}
