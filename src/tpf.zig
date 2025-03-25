const std = @import("std");
const assert = std.debug.assert;
const eql = std.mem.eql;

const root = @import("root.zig");
const ParseError = root.ParseError;

const TPF = @This();

const Header = extern struct {
    magic: [4]u8, // Assert(magic == "TPF\0");
    dataSize: i32,
    textureCount: i32,
    platform: i8, // { PC = 0, X360 = 1, PS3 = 2, PS4 = 4, Xbone = 5 }
    unk0D: i8,
    encoding: i8,
    unk0F: i8, // Assert(unk0F == 0);
};

const TexturePC = extern struct {
    dataOffset: u32,
    dataSize: i32,
    format: u8,
    cubemap: u8,
    mipmaps: u8,
    unk0B: u8,
    nameOffset: u32,
    unk10: i32,
};

header: Header,
textures: []TexturePC, // length of textureCount

pub fn read(
    bytes: []u8,
) ParseError!TPF {
    const allocator = std.heap.c_allocator;
    var fbs = std.io.fixedBufferStream(bytes);
    const reader = fbs.reader();

    const header = reader.readStructEndian(Header, .little) catch return error.UnexpectedEof;
    var textures = allocator.alloc(TexturePC, @intCast(header.textureCount)) catch return error.OutOfMemory;

    for (0..textures.len) |i| {
        textures[i] = reader.readStructEndian(TexturePC, .little) catch return error.UnexpectedEof;
    }

    return TPF{
        .header = header,
        .textures = textures,
    };
}

test "DSR TalkFont24.tpf.dcx" {
    const DCX = @import("dcx.zig");

    const allocator = std.testing.allocator;

    const path = "dsr/font/english/TalkFont24.tpf.dcx";

    var file = try std.fs.cwd().openFile(
        path,
        .{ .mode = .read_only },
    );
    defer file.close();

    const fileBytes = try file.readToEndAlloc(allocator, try file.getEndPos());
    defer allocator.free(fileBytes);

    const dcx = try DCX.read(
        fileBytes,
    );

    const tpf = try read(dcx.data);

    try std.testing.expect(std.mem.eql(u8, &tpf.header.magic, "TPF\x00"));
    try std.testing.expect(tpf.header.dataSize == 4194768);
    try std.testing.expect(tpf.header.textureCount == 3);
    try std.testing.expect(tpf.header.platform == 0);
    try std.testing.expect(tpf.header.encoding == 2);
    try std.testing.expect(tpf.textures.len == 3);
}
