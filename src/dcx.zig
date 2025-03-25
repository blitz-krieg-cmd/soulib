const std = @import("std");
const assert = std.debug.assert;
const eql = std.mem.eql;

const ParseError = @import("root.zig").ParseError;

const DCX = @This();

const Header = struct {
    magic: [4]u8,
    uncompressedSize: i32,
    compressedSize: i32,
    format: [4]u8,
};

header: Header,
data: []u8,

pub fn read(
    bytes: []u8,
) ParseError!DCX {
    const allocator = std.heap.c_allocator;
    var fbs = std.io.fixedBufferStream(bytes);
    const reader = fbs.reader();

    const endian: std.builtin.Endian = .big;

    const magic: [4]u8 = reader.readBytesNoEof(4) catch return error.UnexpectedEof;
    assert(eql(u8, &magic, "DCX\x00") or eql(u8, &magic, "DCP\x00"));

    var format: [4]u8 = undefined;

    if (eql(u8, &magic, "DCX\x00")) {
        format = bytes[0x28 .. 0x28 + 4].*;

        if (eql(u8, &format, "DFLT")) {
            assert(eql(u8, &magic, "DCX\x00"));
            const unk04 = reader.readInt(i32, endian) catch return error.UnexpectedEof;
            assert(unk04 == 0x10000 or unk04 == 0x11000);
            assert((reader.readInt(i32, endian) catch return error.UnexpectedEof) == 0x18);
            assert((reader.readInt(i32, endian) catch return error.UnexpectedEof) == 0x24);
            const unk10 = reader.readInt(i32, endian) catch return error.UnexpectedEof;
            assert(unk10 == 0x24 or unk10 == 0x44);
            const unk14Check: i32 = if (unk10 == 0x24) 0x2c else 0x4c;
            assert((reader.readInt(i32, endian) catch return error.UnexpectedEof) == unk14Check);
            assert(eql(u8, &(reader.readBytesNoEof(4) catch return error.UnexpectedEof), "DCS\x00"));
            const uncompressedSize = reader.readInt(i32, endian) catch return error.UnexpectedEof;
            const compressedSize = reader.readInt(i32, endian) catch return error.UnexpectedEof;
            assert(uncompressedSize != compressedSize);
            assert(eql(u8, &(reader.readBytesNoEof(4) catch return error.UnexpectedEof), "DCP\x00"));
            assert(eql(u8, &(reader.readBytesNoEof(4) catch return error.UnexpectedEof), "DFLT"));
            assert((reader.readInt(i32, endian) catch return error.UnexpectedEof) == 0x20);
            const level = reader.readInt(u8, endian) catch return error.UnexpectedEof;
            assert(level == 8 or level == 9);
            assert((reader.readInt(u8, endian) catch return error.UnexpectedEof) == 0);
            assert((reader.readInt(u8, endian) catch return error.UnexpectedEof) == 0);
            assert((reader.readInt(u8, endian) catch return error.UnexpectedEof) == 0);
            assert((reader.readInt(i32, endian) catch return error.UnexpectedEof) == 0x0);
            const unk38 = reader.readInt(u8, endian) catch return error.UnexpectedEof;
            assert(unk38 == 0 or unk38 == 15);
            assert((reader.readInt(u8, endian) catch return error.UnexpectedEof) == 0);
            assert((reader.readInt(u8, endian) catch return error.UnexpectedEof) == 0);
            assert((reader.readInt(u8, endian) catch return error.UnexpectedEof) == 0);
            assert((reader.readInt(i32, endian) catch return error.UnexpectedEof) == 0x0);
            assert((reader.readInt(i32, endian) catch return error.UnexpectedEof) == 0x00010100);
            assert(eql(u8, &(reader.readBytesNoEof(4) catch return error.UnexpectedEof), "DCA\x00"));
            _ = reader.readInt(i32, endian) catch return error.UnexpectedEof; // dcaSize

            const comp = reader.readAllAlloc(allocator, @intCast(compressedSize)) catch return error.UnexpectedEof;
            var stream = std.io.fixedBufferStream(comp);
            var inflate = std.compress.zlib.decompressor(stream.reader());
            const out = inflate.reader().readAllAlloc(allocator, @intCast(uncompressedSize)) catch return error.UnexpectedEof;

            return DCX{
                .header = Header{
                    .magic = magic,
                    .uncompressedSize = uncompressedSize,
                    .compressedSize = compressedSize,
                    .format = format,
                },
                .data = out,
            };
        } else if (eql(u8, &format, "EDGE")) {
            return error.UnsupportedCompression;
        } else if (eql(u8, &format, "KRAK")) {
            return error.UnsupportedCompression;
        } else if (eql(u8, &format, "ZSTD")) {
            return error.UnsupportedCompression;
        } else {
            return error.UnknownCompression;
        }
    } else if (eql(u8, &magic, "DCP\x00")) {
        format = bytes[4..8].*;

        if (eql(u8, &format, "EDGE")) {
            // Redundant but nice to have
            assert(eql(u8, &magic, "DCP\x00"));
            assert(eql(u8, &(reader.readBytesNoEof(4) catch return error.UnexpectedEof), "EDGE"));

            assert((reader.readInt(i32, endian) catch return error.UnexpectedEof) == 0x20);
            assert((reader.readInt(u8, endian) catch return error.UnexpectedEof) == 9);
            assert((reader.readInt(u8, endian) catch return error.UnexpectedEof) == 0);
            assert((reader.readInt(u8, endian) catch return error.UnexpectedEof) == 0);
            assert((reader.readInt(u8, endian) catch return error.UnexpectedEof) == 0);
            assert((reader.readInt(i32, endian) catch return error.UnexpectedEof) == 0x10000);
            assert((reader.readInt(i32, endian) catch return error.UnexpectedEof) == 0x0);
            assert((reader.readInt(i32, endian) catch return error.UnexpectedEof) == 0x0);
            assert((reader.readInt(i32, endian) catch return error.UnexpectedEof) == 0x00100100);

            assert(eql(u8, &(reader.readBytesNoEof(4) catch return error.UnexpectedEof), "DCS\x00"));
            const uncompressedSize = reader.readInt(i32, endian) catch return error.UnexpectedEof;
            const compressedSize = reader.readInt(i32, endian) catch return error.UnexpectedEof;
            assert(uncompressedSize != compressedSize);
            assert((reader.readInt(i32, endian) catch return error.UnexpectedEof) == 0);

            const dataStart = reader.context.pos;
            reader.skipBytes(@intCast(compressedSize), .{}) catch return error.UnexpectedEof;

            assert(eql(u8, &(reader.readBytesNoEof(4) catch return error.UnexpectedEof), "DCA\x00"));
            _ = reader.readInt(i32, endian) catch return error.UnexpectedEof; // dcaSize
            assert(eql(u8, &(reader.readBytesNoEof(4) catch return error.UnexpectedEof), "EgdT"));
            assert((reader.readInt(i32, endian) catch return error.UnexpectedEof) == 0x00010000);
            assert((reader.readInt(i32, endian) catch return error.UnexpectedEof) == 0x20);
            assert((reader.readInt(i32, endian) catch return error.UnexpectedEof) == 0x10);
            assert((reader.readInt(i32, endian) catch return error.UnexpectedEof) == 0x10000);
            const egdtSize = reader.readInt(i32, endian) catch return error.UnexpectedEof;
            const chunkCount = reader.readInt(i32, endian) catch return error.UnexpectedEof;
            assert((reader.readInt(i32, endian) catch return error.UnexpectedEof) == 0x100000);

            if (egdtSize != 0x20 + chunkCount * 0x10) {
                return error.DecompressionFailed;
            }

            var decompressed = std.ArrayList(u8).initCapacity(allocator, @intCast(uncompressedSize)) catch return error.OutOfMemory;

            for (0..@intCast(chunkCount)) |_| {
                assert((reader.readInt(i32, endian) catch return error.UnexpectedEof) == 0);
                const offset = reader.readInt(i32, endian) catch return error.UnexpectedEof;
                const size = reader.readInt(i32, endian) catch return error.UnexpectedEof;

                const comp = reader.readInt(i32, endian) catch return error.UnexpectedEof;
                assert(comp == 0 or comp == 1);
                const compressed = comp == 1;

                const chunk: []u8 = bytes[dataStart + @as(usize, @intCast(offset)) .. dataStart + @as(usize, @intCast(offset + size))];

                if (compressed) {
                    var stream = std.io.fixedBufferStream(chunk);
                    var inflate = std.compress.zlib.decompressor(stream.reader());
                    const out = inflate.reader().readAllAlloc(allocator, @intCast(uncompressedSize)) catch return error.UnexpectedEof;

                    decompressed.appendSlice(out) catch return error.OutOfMemory;
                } else {
                    decompressed.appendSlice(chunk) catch return error.OutOfMemory;
                }
            }

            return DCX{
                .header = Header{
                    .magic = magic,
                    .uncompressedSize = uncompressedSize,
                    .compressedSize = compressedSize,
                    .format = format,
                },
                .data = decompressed.toOwnedSlice() catch unreachable,
            };
        } else {
            return error.UnsupportedCompression;
        }
    } else {
        return error.UnknownCompression;
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

    const dcx = try DCX.read(fileBytes);

    try std.testing.expect(std.mem.eql(u8, &dcx.header.magic, "DCX\x00") or std.mem.eql(u8, &dcx.header.magic, "DCS\x00"));
    try std.testing.expect(std.mem.eql(u8, &dcx.header.format, "DFLT") or std.mem.eql(u8, &dcx.header.format, "NONE"));
    try std.testing.expect(dcx.data.len == dcx.header.uncompressedSize);
}
