const std = @import("std");
const assert = std.debug.assert;
const eql = std.mem.eql;

const ParseError = @import("root.zig").ParseError;

const DCX = @This();

const Header = struct {
    magic: [4]u8,
    dcsOffset: i32,
    dcpOffset: i32,
    dcs: [4]u8,
    uncompressedSize: i32,
    compressedSize: i32,
    dcp: [4]u8,
    format: [4]u8,
    dca: [4]u8,
    dcaSize: i32,
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
            const unk04 = reader.readInt(i32, endian) catch return error.UnexpectedEof;
            assert(unk04 == 0x10000 or unk04 == 0x11000);
            const dcsOffset = reader.readInt(i32, endian) catch return error.UnexpectedEof;
            assert(dcsOffset == 0x18);
            const dcpOffset = reader.readInt(i32, endian) catch return error.UnexpectedEof;
            assert(dcpOffset == 0x24);
            const unk10 = reader.readInt(i32, endian) catch return error.UnexpectedEof;
            assert(unk10 == 0x24 or unk10 == 0x44);
            const unk14 = reader.readInt(i32, endian) catch return error.UnexpectedEof;
            const unk14Check: i32 = if (unk10 == 0x24) 0x2c else 0x4c;
            assert(unk14 == unk14Check);
            const dcs: [4]u8 = reader.readBytesNoEof(4) catch return error.UnexpectedEof;
            assert(eql(u8, &dcs, "DCS\x00"));
            const uncompressedSize = reader.readInt(i32, endian) catch return error.UnexpectedEof;
            const compressedSize = reader.readInt(i32, endian) catch return error.UnexpectedEof;
            assert(uncompressedSize != compressedSize);
            const dcp: [4]u8 = reader.readBytesNoEof(4) catch return error.UnexpectedEof;
            assert(eql(u8, &dcp, "DCP\x00"));
            _ = reader.readBytesNoEof(4) catch return error.UnexpectedEof; // format again
            const unk2C = reader.readInt(i32, endian) catch return error.UnexpectedEof;
            assert(unk2C == 0x20);
            const level = reader.readInt(u8, endian) catch return error.UnexpectedEof;
            assert(level == 8 or level == 9);
            const unk31 = reader.readInt(u8, endian) catch return error.UnexpectedEof;
            assert(unk31 == 0);
            const unk32 = reader.readInt(u8, endian) catch return error.UnexpectedEof;
            assert(unk32 == 0);
            const unk33 = reader.readInt(u8, endian) catch return error.UnexpectedEof;
            assert(unk33 == 0);
            const unk34 = reader.readInt(i32, endian) catch return error.UnexpectedEof;
            assert(unk34 == 0x0);
            const unk38 = reader.readInt(u8, endian) catch return error.UnexpectedEof;
            assert(unk38 == 0 or unk38 == 15);
            const unk39 = reader.readInt(u8, endian) catch return error.UnexpectedEof;
            assert(unk39 == 0);
            const unk3A = reader.readInt(u8, endian) catch return error.UnexpectedEof;
            assert(unk3A == 0);
            const unk3B = reader.readInt(u8, endian) catch return error.UnexpectedEof;
            assert(unk3B == 0);
            const unk3C = reader.readInt(i32, endian) catch return error.UnexpectedEof;
            assert(unk3C == 0x0);
            const unk40 = reader.readInt(i32, endian) catch return error.UnexpectedEof;
            assert(unk40 == 0x00010100);
            const dca: [4]u8 = reader.readBytesNoEof(4) catch return error.UnexpectedEof;
            assert(eql(u8, &dca, "DCA\x00"));

            const dcaSize = reader.readInt(i32, endian) catch return error.UnexpectedEof;

            const comp = reader.readAllAlloc(allocator, @intCast(compressedSize)) catch return error.UnexpectedEof;
            var stream = std.io.fixedBufferStream(comp);
            var inflate = std.compress.zlib.decompressor(stream.reader());
            const out = inflate.reader().readAllAlloc(allocator, @intCast(uncompressedSize)) catch return error.UnexpectedEof;

            return DCX{
                .header = Header{
                    .magic = magic,
                    .dcsOffset = dcsOffset,
                    .dcpOffset = dcpOffset,
                    .dcs = dcs,
                    .uncompressedSize = uncompressedSize,
                    .compressedSize = compressedSize,
                    .dcp = dcp,
                    .format = format,
                    .dca = dca,
                    .dcaSize = dcaSize,
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

        return error.UnsupportedCompression;
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

        fileBytes,
    );

    try std.testing.expect(std.mem.eql(u8, &dcx.header.magic, "DCX\x00") or std.mem.eql(u8, &dcx.header.magic, "DCS\x00"));
    try std.testing.expect(std.mem.eql(u8, &dcx.header.format, "DFLT") or std.mem.eql(u8, &dcx.header.format, "NONE"));
    try std.testing.expect(dcx.data.len == dcx.header.uncompressedSize);
}
