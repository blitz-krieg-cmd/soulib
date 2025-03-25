const std = @import("std");
const assert = std.debug.assert;
const eql = std.mem.eql;

const DCX = @import("dcx.zig");
const root = @import("root.zig");
const ParseError = root.ParseError;

const TPF = @This();

const Header = struct {
    magic: [4]u8,
    dataSize: i32,
    textureCount: i32,
    platform: u8,
    encoding: u8,
};

const TextureType = enum(u8) {
    Texture = 0,
    Cubemap,
    Volume,
};

const Texture = struct {
    name: []u8,
    format: u8,
    texType: TextureType,
    mipmaps: u8,
    flags1: u8,
    bytes: []u8,
};

header: Header,
textures: []Texture, // length of textureCount

pub fn is(
    bytes: []u8,
) ParseError!bool {
    var fbs = std.io.fixedBufferStream(bytes);
    const reader = fbs.reader();

    const magic: [4]u8 = reader.readBytesNoEof(4) catch return error.UnexpectedEof;

    return eql(u8, &magic, "TPF\x00");
}

pub fn read(
    bytes: []u8,
) ParseError!TPF {
    const allocator = std.heap.c_allocator;
    var fbs = std.io.fixedBufferStream(bytes);
    const reader = fbs.reader();

    var endian: std.builtin.Endian = .little;

    const magic = reader.readBytesNoEof(4) catch return error.UnexpectedEof;
    assert(eql(u8, &magic, "TPF\x00"));

    const dataSize = reader.readInt(i32, endian) catch return error.UnexpectedEof;
    const textureCount = reader.readInt(i32, endian) catch return error.UnexpectedEof;

    const platform = reader.readInt(u8, endian) catch return error.UnexpectedEof;
    assert(platform == 0 or platform == 1 or platform == 2 or platform == 4 or platform == 5);
    const flag2 = reader.readInt(i8, endian) catch return error.UnexpectedEof;
    assert(flag2 == 0 or flag2 == 1 or flag2 == 2 or flag2 == 3);
    const encoding = reader.readInt(u8, endian) catch return error.UnexpectedEof;
    assert(encoding == 0 or encoding == 1 or encoding == 2);
    const unk0F = reader.readInt(u8, endian) catch return error.UnexpectedEof;
    assert(unk0F == 0);

    endian = if (platform == 1 or platform == 2) .big else .little;

    const textures: []Texture = allocator.alloc(Texture, @intCast(textureCount)) catch return error.OutOfMemory;

    // Just pc atm
    switch (platform) {
        0 => {
            for (0..@intCast(textureCount)) |i| {
                const fileOffset = reader.readInt(u32, endian) catch return error.UnexpectedEof;
                const fileSize = reader.readInt(i32, endian) catch return error.UnexpectedEof;

                const format = reader.readInt(u8, endian) catch return error.UnexpectedEof;
                const texType: TextureType = @enumFromInt(reader.readInt(u8, endian) catch return error.UnexpectedEof);
                const mipmaps = reader.readInt(u8, endian) catch return error.UnexpectedEof;
                const flags1 = reader.readInt(u8, endian) catch return error.UnexpectedEof;
                assert(flags1 == 0 or flags1 == 1 or flags1 == 2 or flags1 == 3);

                const nameOffset = reader.readInt(u32, endian) catch return error.UnexpectedEof;
                _ = nameOffset; // TODO: Read name of tpf

                const hasFloatStruct = reader.readInt(i32, endian) catch return error.UnexpectedEof;
                assert(hasFloatStruct == 0 or hasFloatStruct == 1);

                if (hasFloatStruct == 1) {
                    // Read Float struct
                }

                const texBytes = allocator.dupe(u8, bytes[@intCast(fileOffset)..@intCast(@as(i32, @intCast(fileOffset)) + fileSize)]) catch return error.OutOfMemory;

                var dcxBytes: []u8 = undefined;
                if (flags1 == 2 or flags1 == 3) {
                    const dcx = DCX.read(texBytes) catch return error.DecompressionFailed;
                    if (!eql(u8, &dcx.header.magic, "DCP") or !eql(u8, &dcx.header.format, "EDGE")) {
                        return error.DecompressionFailed;
                    }
                    dcxBytes = dcx.data;
                }

                // TODO: Read name of tpf
                // var name = undefined;
                // if (header.encoding == 1) {
                //     name = readUTF16
                // } else if (header.encoding == 0 or header.encoding == 2) {
                //     name = readShiftJis
                // }

                textures[i] = Texture{
                    .name = "", // TODO: Read name of tpf
                    .format = format,
                    .texType = texType,
                    .mipmaps = mipmaps,
                    .flags1 = flags1,
                    .bytes = if (flags1 != 2 and flags1 != 3) texBytes else dcxBytes,
                };
            }

            return TPF{
                .header = Header{
                    .magic = magic,
                    .dataSize = dataSize,
                    .textureCount = textureCount,
                    .platform = platform,
                    .encoding = encoding,
                },
                .textures = textures,
            };
        },
        else => return ParseError.UnknownPlatform,
    }
}

test {
    std.testing.refAllDecls(@This());
}

test "DSR TalkFont24.tpf.dcx" {
    const allocator = std.testing.allocator;

    const path = "dsr/font/english/TalkFont24.tpf.dcx";

    var file = try std.fs.cwd().openFile(
        path,
        .{ .mode = .read_only },
    );
    defer file.close();

    const fileBytes = try file.readToEndAlloc(allocator, try file.getEndPos());
    defer allocator.free(fileBytes);

    try std.testing.expect(try DCX.is(fileBytes));
    const dcx: DCX = try DCX.read(fileBytes);

    try std.testing.expect(try TPF.is(dcx.data));
    const tpf: TPF = try read(dcx.data);

    try std.testing.expect(std.mem.eql(u8, &tpf.header.magic, "TPF\x00"));
    try std.testing.expect(tpf.header.dataSize == 4194768);
    try std.testing.expect(tpf.header.textureCount == 3);
    try std.testing.expect(tpf.header.platform == 0);
    try std.testing.expect(tpf.header.encoding == 2);
    try std.testing.expect(tpf.header.textureCount == tpf.textures.len);

    try std.testing.expect(tpf.textures.len == 3);
    try std.testing.expect(std.mem.eql(u8, tpf.textures[0].bytes[0..4], "DDS "));
    try std.testing.expect(tpf.textures[0].format == 5);
}
