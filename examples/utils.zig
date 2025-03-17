const std = @import("std");

pub fn getPathArgs(allocator: std.mem.Allocator) []u8 {
    const argv = std.process.argsAlloc(allocator) catch |err| {
        std.log.err("Error: {?}", .{err});
        return "";
    };

    if (argv.len == 1) {
        std.log.info("Usage: {s} <filename> <options>\n", .{argv[0]});
        return "";
    }

    return argv[1];
}

pub fn readFileBytes(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    var file = std.fs.openFileAbsolute(
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

    return try file.readToEndAlloc(allocator, try file.getEndPos());
}
