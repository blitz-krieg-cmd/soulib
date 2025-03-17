const std = @import("std");
const builtin = @import("builtin");

// Define error set for parsing operations
const ParseError = error{
    InvalidMagic,
    UnsupportedCompression,
    DecompressionFailed,
    OutOfMemory,
    UnexpectedEof,
};

const Error = ParseError || anyerror;

// Define the DCX header struct
const DcxHeader = struct {
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

    fn parse(reader: std.io.AnyReader) Error!DcxHeader {
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

        return DcxHeader{
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

// Define the full DCX file struct
const DcxFile = struct {
    header: DcxHeader,
    data: []u8, // Decompressed data

    fn parse(allocator: std.mem.Allocator, reader: std.io.AnyReader) Error!DcxFile {
        const header = try DcxHeader.parse(reader);
        const data = try decompress(allocator, reader, header);

        return DcxFile{
            .header = header,
            .data = data,
        };
    }

    fn decompress(allocator: std.mem.Allocator, reader: std.io.AnyReader, header: DcxHeader) ![]u8 {
        // Allocate buffer for compressed data
        const compressed_data = try allocator.alloc(u8, header.compressedSize);
        errdefer allocator.free(compressed_data);
        // Read the compressed data
        try reader.readNoEof(compressed_data);

        // Handle decompression based on compression type
        if (std.mem.eql(u8, &header.format, "NONE")) {
            // No compression
            if (header.compressedSize != header.uncompressedSize) {
                allocator.free(compressed_data);
                return error.DecompressionFailed;
            }
            return compressed_data;
        } else if (std.mem.eql(u8, &header.format, "DFLT")) {
            // DFLT
            const decompressed = try decompressDFLT(allocator, compressed_data, header);
            allocator.free(compressed_data);
            return decompressed;
        } else {
            allocator.free(compressed_data);
            return error.UnsupportedCompression;
        }
    }

    fn decompressDFLT(allocator: std.mem.Allocator, compressed_data: []u8, header: DcxHeader) ![]u8 {
        var stream = std.io.fixedBufferStream(compressed_data);
        var decompressor = std.compress.zlib.decompressor(stream.reader());

        // Allocate buffer for decompressed data
        const decompressed = try allocator.alloc(u8, header.uncompressedSize);
        errdefer allocator.free(decompressed);

        // Read exactly decompressed_size bytes
        try decompressor.reader().readNoEof(decompressed);

        return decompressed;
    }
};

pub const DCX = struct {
    header: DcxHeader,
    data: []u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, path: []const u8) !DCX {
        // Open a DCX file
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        // Create a reader for the file
        const reader = file.reader().any();

        const dcx = try DcxFile.parse(allocator, reader);
        return DCX{
            .allocator = allocator,
            .header = dcx.header,
            .data = dcx.data,
        };
    }

    pub fn deinit(self: *DCX) void {
        self.allocator.free(self.data);
    }
};

//
// Testing
//

test "read dcx header" {
    // Open a DCX file
    const file = try std.fs.cwd().openFile("game_bins/msg/ENGLISH/item.msgbnd.dcx", .{});
    defer file.close();

    // Create a reader for the file
    const reader = file.reader().any();

    // Parse the DCX header
    const header = try DcxHeader.parse(reader);

    // Use the parsed data (e.g., print sizes)
    std.debug.print("HEADER:\n    Magic: {c}\n    Compression Type: {c}\n    Compressed size: {d}\n    Decompressed size: {d}\n", .{
        header.dcx,
        header.format,
        header.compressedSize,
        header.uncompressedSize,
    });
}

test "read dcx" {
    const allocator = std.testing.allocator;

    const path: []const u8 = "game_bins/msg/ENGLISH/item.msgbnd.dcx";

    // Parse the DCX
    var dcx = try DCX.init(allocator, path);
    defer dcx.deinit();

    std.debug.print("HEADER:\n    Magic: {c}\n    Compression Type: {c}\n    Compressed size: {d}\n    Decompressed size: {d}\n", .{
        dcx.header.dcx,
        dcx.header.format,
        dcx.header.compressedSize,
        dcx.header.uncompressedSize,
    });

    // Use the parsed data (e.g., print sizes)
    std.debug.print("BODY:    Length: {d}\n    Summary: {x}..{x}\n", .{
        dcx.data.len,
        dcx.data[0..32],
        dcx.data[dcx.data.len - 32 .. dcx.data.len],
    });
}
