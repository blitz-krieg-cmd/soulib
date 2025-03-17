const std = @import("std");
const builtin = @import("builtin");

const DCX = @This();

// Define error set for parsing operations
const ParseError = error{
    InvalidMagic,
    UnsupportedCompression,
    DecompressionFailed,
    OutOfMemory,
    UnexpectedEof,
};

// Define the DCX header struct
const Header = struct {
    dcx: [4]u8, // Assert(dcx == "DCX\0");
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

    fn parse(reader: anytype) ParseError!Header {
        const dcx: [4]u8 = reader.readBytesNoEof(4) catch return error.UnexpectedEof;
        if (!std.mem.eql(u8, &dcx, "DCX\x00") and !std.mem.eql(u8, &dcx, "DCP\x00")) return error.InvalidMagic;

        const unk04: i32 = reader.readInt(i32, .big) catch return error.UnexpectedEof;

        const dcsOffset: i32 = reader.readInt(i32, .big) catch return error.UnexpectedEof;
        const dcpOffset: i32 = reader.readInt(i32, .big) catch return error.UnexpectedEof;

        const unk10: i32 = reader.readInt(i32, .big) catch return error.UnexpectedEof;
        const unk14: i32 = reader.readInt(i32, .big) catch return error.UnexpectedEof;

        const dcs: [4]u8 = reader.readBytesNoEof(4) catch return error.UnexpectedEof;
        if (!std.mem.eql(u8, &dcs, "DCS\x00")) return error.InvalidMagic;

        const uncompressedSize: u32 = reader.readInt(u32, .big) catch return error.UnexpectedEof;
        const compressedSize: u32 = reader.readInt(u32, .big) catch return error.UnexpectedEof;

        const dcp: [4]u8 = reader.readBytesNoEof(4) catch return error.UnexpectedEof;
        if (!std.mem.eql(u8, &dcp, "DCP\x00")) return error.InvalidMagic;

        const format: [4]u8 = reader.readBytesNoEof(4) catch return error.UnexpectedEof;
        if (!std.mem.eql(u8, &format, "DFLT") and !std.mem.eql(u8, &format, "EDGE") and !std.mem.eql(u8, &format, "KRAK")) return error.InvalidMagic;

        const unk2C: i32 = reader.readInt(i32, .big) catch return error.UnexpectedEof;
        const unk30: i8 = reader.readInt(i8, .big) catch return error.UnexpectedEof;
        const unk31: i8 = reader.readInt(i8, .big) catch return error.UnexpectedEof;
        const unk32: i8 = reader.readInt(i8, .big) catch return error.UnexpectedEof;
        const unk33: i8 = reader.readInt(i8, .big) catch return error.UnexpectedEof;
        const unk34: i32 = reader.readInt(i32, .big) catch return error.UnexpectedEof;
        const unk38: i8 = reader.readInt(i8, .big) catch return error.UnexpectedEof;
        const unk39: i8 = reader.readInt(i8, .big) catch return error.UnexpectedEof;
        const unk3A: i8 = reader.readInt(i8, .big) catch return error.UnexpectedEof;
        const unk3B: i8 = reader.readInt(i8, .big) catch return error.UnexpectedEof;
        const unk3C: i32 = reader.readInt(i32, .big) catch return error.UnexpectedEof;
        const unk40: i32 = reader.readInt(i32, .big) catch return error.UnexpectedEof;

        const dca: [4]u8 = reader.readBytesNoEof(4) catch return error.UnexpectedEof;
        if (!std.mem.eql(u8, &dca, "DCA\x00")) return error.InvalidMagic;

        const dcaSize: i32 = reader.readInt(i32, .big) catch return error.UnexpectedEof;

        return Header{
            .dcx = dcx,
            .unk04 = unk04,
            .dcsOffset = dcsOffset,
            .dcpOffset = dcpOffset,
            .unk10 = unk10,
            .unk14 = unk14,
            .dcs = dcs,
            .uncompressedSize = uncompressedSize,
            .compressedSize = compressedSize,
            .dcp = dcp,
            .format = format,
            .unk2C = unk2C,
            .unk30 = unk30,
            .unk31 = unk31,
            .unk32 = unk32,
            .unk33 = unk33,
            .unk34 = unk34,
            .unk38 = unk38,
            .unk39 = unk39,
            .unk3A = unk3A,
            .unk3B = unk3B,
            .unk3C = unk3C,
            .unk40 = unk40,
            .dca = dca,
            .dcaSize = dcaSize,
        };
    }
};

header: Header,
data: []u8,

pub fn read(
    allocator: std.mem.Allocator,
    bytes: []u8,
) ParseError!DCX {
    var fbs = std.io.fixedBufferStream(bytes);

    const reader = fbs.reader();

    const header = try Header.parse(reader);
    const compressed_data = try allocator.alloc(u8, header.compressedSize);
    defer allocator.free(compressed_data);

    reader.readNoEof(compressed_data) catch return error.UnexpectedEof;

    if (std.mem.eql(u8, &header.format, "NONE")) {
        if (header.compressedSize != header.uncompressedSize) {
            return ParseError.DecompressionFailed;
        }
        return DCX{
            .header = header,
            .data = compressed_data,
        };
    } else if (std.mem.eql(u8, &header.format, "DFLT")) {
        var stream = std.io.fixedBufferStream(compressed_data);
        var decompressor = std.compress.zlib.decompressor(stream.reader());

        // Allocate buffer for decompressed data
        const decompressed = try allocator.alloc(u8, header.uncompressedSize);
        errdefer allocator.free(decompressed);

        decompressor.reader().readNoEof(decompressed) catch return error.DecompressionFailed;

        return DCX{
            .header = header,
            .data = decompressed,
        };
    } else return ParseError.UnsupportedCompression;
}

// ===========C-API=========== //
pub const DCX_C = @import("dcx_c.zig");

// ===========Testing=========== //

test "DSR item.msgbnd.dcx" {
    const allocator = std.testing.allocator;

    const path = "dsr/msg/ENGLISH/item.msgbnd.dcx";

    var file = std.fs.cwd().openFile(
        path,
        .{ .mode = .read_only },
    ) catch unreachable;
    defer file.close();

    const fileBytes = try file.readToEndAlloc(allocator, try file.getEndPos());
    defer allocator.free(fileBytes);

    const dcx = try DCX.read(
        allocator,
        fileBytes,
    );
    defer allocator.free(dcx.data);

    try std.testing.expect(std.mem.eql(u8, &dcx.header.dcx, "DCX\x00"));
    try std.testing.expect(std.mem.eql(u8, &dcx.header.format, "DFLT"));
    try std.testing.expect(dcx.header.compressedSize == 346199);
    try std.testing.expect(dcx.header.uncompressedSize == 3113120);
    try std.testing.expect(dcx.data.len == 3113120);
}

test "DSR DSFont24.ccm.dcx" {
    const allocator = std.testing.allocator;

    const path = "dsr/font/english/DSFont24.ccm.dcx";

    var file = std.fs.cwd().openFile(
        path,
        .{ .mode = .read_only },
    ) catch unreachable;
    defer file.close();

    const fileBytes = try file.readToEndAlloc(allocator, try file.getEndPos());
    defer allocator.free(fileBytes);

    const dcx = try DCX.read(
        allocator,
        fileBytes,
    );
    defer allocator.free(dcx.data);

    try std.testing.expect(std.mem.eql(u8, &dcx.header.dcx, "DCX\x00"));
    try std.testing.expect(std.mem.eql(u8, &dcx.header.format, "DFLT"));
    try std.testing.expect(dcx.header.compressedSize == 10732);
    try std.testing.expect(dcx.header.uncompressedSize == 32468);
    try std.testing.expect(dcx.data.len == 32468);
}

test "DSR TalkFont24.tpf.dcx" {
    const allocator = std.testing.allocator;

    const path = "dsr/font/english/TalkFont24.tpf.dcx";

    var file = std.fs.cwd().openFile(
        path,
        .{ .mode = .read_only },
    ) catch unreachable;
    defer file.close();

    const fileBytes = try file.readToEndAlloc(allocator, try file.getEndPos());
    defer allocator.free(fileBytes);

    const dcx = try DCX.read(
        allocator,
        fileBytes,
    );
    defer allocator.free(dcx.data);

    try std.testing.expect(std.mem.eql(u8, &dcx.header.dcx, "DCX\x00"));
    try std.testing.expect(std.mem.eql(u8, &dcx.header.format, "DFLT"));
    try std.testing.expect(dcx.header.compressedSize == 856756);
    try std.testing.expect(dcx.header.uncompressedSize == 4194940);
    try std.testing.expect(dcx.data.len == 4194940);
}
