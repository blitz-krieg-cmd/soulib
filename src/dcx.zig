const std = @import("std");
const assert = std.debug.assert;
const eql = std.mem.eql;

const ParseError = @import("root.zig").ParseError;

const DCX = @This();

// Define the DCX header struct
const Header = extern struct {
    magic: [4]u8, // Assert(dcx == "DCX\0");
    unk04: i32, // Assert(unk04 == 0x10000 || unk04 == 0x11000);
    dcsOffset: i32, // Assert(dcsOffset == 0x18);
    dcpOffset: i32, // Assert(dcpOffset == 0x24);
    unk10: i32, // Assert(unk10 == 0x24 || unk10 == 0x44);
    unk14: i32, // In EDGE, size from 0x20 to end of block headers
    dcs: [4]u8, // Assert(dcs == "DCS\0");
    uncompressedSize: u32,
    compressedSize: u32,
    dcp: [4]u8, // Assert(dcp == "DCP\0");
    format: [4]u8, // Assert(format == "DFLT" || format == "EDGE" || format == "KRAK");
    unk2C: i32, // Assert(unk2C == 0x20);
    unk30: i8, // Assert(unk30 == 6|| unk30 == 8 || unk30 == 9); // Compression param?
    unk31: i8, // Assert(unk31 == 0);
    unk32: i8, // Assert(unk32 == 0);
    unk33: i8, // Assert(unk33 == 0);
    unk34: i32, // Assert(unk34 == 0 || unk34 == 0x10000); // Block size for EDGE?
    unk38: i8, // Assert(unk38 == 0 || unk38 == 15);
    unk39: i8, // Assert(unk39 == 0);
    unk3A: i8, // Assert(unk3A == 0);
    unk3B: i8, // Assert(unk3B == 0);
    unk3C: i32, // Assert(unk3C == 0);
    unk40: i32,
    dca: [4]u8, // Assert(dca == "DCA\0");
    dcaSize: i32, // From before "DCA" to dca end
};

header: Header,
data: []u8,

pub fn read(
    bytes: []u8,
) ParseError!DCX {
    const allocator = std.heap.c_allocator;
    var fbs = std.io.fixedBufferStream(bytes);
    const reader = fbs.reader();

    const header = reader.readStructEndian(Header, .big) catch return error.UnexpectedEof;

    if (header.compressedSize == header.uncompressedSize and std.mem.eql(u8, &header.format, "NONE")) {
        return DCX{
            .header = header,
            .data = reader.readAllAlloc(allocator, header.compressedSize) catch return error.UnexpectedEof,
        };
    } else {
        const comp = reader.readAllAlloc(allocator, header.compressedSize) catch return error.UnexpectedEof;
        var stream = std.io.fixedBufferStream(comp);
        var inflate = std.compress.zlib.decompressor(stream.reader());
        const out = inflate.reader().readAllAlloc(allocator, header.uncompressedSize) catch return error.UnexpectedEof;

        return DCX{
            .header = header,
            .data = out,
        };
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
