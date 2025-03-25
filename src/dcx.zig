const std = @import("std");
const assert = std.debug.assert;
const eql = std.mem.eql;

const ParseError = @import("root.zig").ParseError;

const DCX = @This();

// Define the DCX header struct

const DCX_DFLT_Header = extern struct {
    unk04: i32,
    dcsOffset: i32,
    dcpOffset: i32,
    unk10: i32,
    unk14: i32,
    dcs: [4]u8,
    uncompressedSize: i32,
    compressedSize: i32,
    dcp: [4]u8,
    format: [4]u8,
    unk2C: i32,
    level: u8,
    unk31: u8,
    unk32: u8,
    unk33: u8,
    unk34: i32,
    unk38: u8,
    unk39: u8,
    unk3A: u8,
    unk3B: u8,
    unk3C: i32,
    unk40: i32,
    dca: [4]u8,
    dcaSize: i32,
};

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
            const header = reader.readStructEndian(DCX_DFLT_Header, endian) catch return error.UnexpectedEof;

            assert(header.unk04 == 0x10000 or header.unk04 == 0x11000);
            assert(header.dcsOffset == 0x18);
            assert(header.dcpOffset == 0x24);
            assert(header.unk10 == 0x24 or header.unk10 == 0x44);
            const unk14Check: i32 = if (header.unk10 == 0x24) 0x2c else 0x4c;
            assert(header.unk14 == unk14Check);
            assert(eql(u8, &header.dcs, "DCS\x00"));
            assert(header.uncompressedSize != header.compressedSize);
            assert(eql(u8, &header.dcp, "DCP\x00"));
            assert(header.unk2C == 0x20);
            assert(header.level == 8 or header.level == 9);
            assert(header.unk31 == 0);
            assert(header.unk32 == 0);
            assert(header.unk33 == 0);
            assert(header.unk34 == 0x0);
            assert(header.unk38 == 0 or header.unk38 == 15);
            assert(header.unk39 == 0);
            assert(header.unk3A == 0);
            assert(header.unk3B == 0);
            assert(header.unk3C == 0x0);
            assert(header.unk40 == 0x00010100);
            assert(eql(u8, &header.dca, "DCA\x00"));

            const comp = reader.readAllAlloc(allocator, @intCast(header.compressedSize)) catch return error.UnexpectedEof;
            var stream = std.io.fixedBufferStream(comp);
            var inflate = std.compress.zlib.decompressor(stream.reader());
            const out = inflate.reader().readAllAlloc(allocator, @intCast(header.uncompressedSize)) catch return error.UnexpectedEof;

            return DCX{
                .header = Header{
                    .magic = magic,
                    .dcsOffset = header.dcsOffset,
                    .dcpOffset = header.dcpOffset,
                    .dcs = header.dcs,
                    .uncompressedSize = header.uncompressedSize,
                    .compressedSize = header.compressedSize,
                    .dcp = header.dcp,
                    .format = header.format,
                    .dca = header.dca,
                    .dcaSize = header.dcaSize,
                },
                .data = out,
            };
        } else if (eql(u8, &format, "EDGE")) {
            return ParseError.UnsupportedCompression;
        } else if (eql(u8, &format, "KRAK")) {
            return ParseError.UnsupportedCompression;
        } else if (eql(u8, &format, "ZSTD")) {
            return ParseError.UnsupportedCompression;
        } else {
            return ParseError.UnknownCompression;
        }
    } else if (eql(u8, &magic, "DCP\x00")) {
        format = bytes[4..8].*;

        return ParseError.UnsupportedCompression;
    } else {
        return ParseError.UnknownCompression;
    }
}

// ===========Testing=========== //

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

    const dcx = try DCX.read(
        fileBytes,
    );

    try std.testing.expect(std.mem.eql(u8, &dcx.header.magic, "DCX\x00") or std.mem.eql(u8, &dcx.header.magic, "DCS\x00"));
    try std.testing.expect(std.mem.eql(u8, &dcx.header.format, "DFLT") or std.mem.eql(u8, &dcx.header.format, "NONE"));
    try std.testing.expect(dcx.data.len == dcx.header.uncompressedSize);
}
