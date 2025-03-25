const std = @import("std");
const assert = std.debug.assert;
const eql = std.mem.eql;

const root = @import("root.zig");
const ParseError = root.ParseError;

const DDS = @This();

// Flags
const DDSD = enum(u32) {
    CAPS = 0x1,
    HEIGHT = 0x2,
    WIDTH = 0x4,
    PITCH = 0x8,
    PIXELFORMAT = 0x1000,
    MIPMAPCOUNT = 0x20000,
    LINEARSIZE = 0x80000,
    DEPTH = 0x800000,
};

// Flags
const DDSCAPS = enum(u32) {
    COMPLEX = 0x8,
    TEXTURE = 0x1000,
    MIPMAP = 0x400000,
};

// Flags
const DDSCAPS2 = enum(u32) {
    CUBEMAP = 0x200,
    CUBEMAP_POSITIVEX = 0x400,
    CUBEMAP_NEGATIVEX = 0x800,
    CUBEMAP_POSITIVEY = 0x1000,
    CUBEMAP_NEGATIVEY = 0x2000,
    CUBEMAP_POSITIVEZ = 0x4000,
    CUBEMAP_NEGATIVEZ = 0x8000,
    VOLUME = 0x200000,
};

// Flags
const DDPF = enum(u32) {
    ALPHAPIXELS = 0x1,
    ALPHA = 0x2,
    FOURCC = 0x4,
    RGB = 0x40,
    YUV = 0x200,
    LUMINANCE = 0x20000,
};

const DIMENSION = enum(u32) {
    TEXTURE1D = 2,
    TEXTURE2D = 3,
    TEXTURE3D = 4,
};

// Flags
const RESOURCE_MISC = enum(u32) {
    TEXTURECUBE = 0x4,
};

const ALPHA_MODE = enum(u32) {
    UNKNOWN = 0,
    STRAIGHT,
    PREMULTIPLIED,
    OPAQUE,
    CUSTOM,
};

const DXGI_FORMAT = enum(u32) {
    UNKNOWN = 0,
    R32G32B32A32_TYPELESS,
    R32G32B32A32_FLOAT,
    R32G32B32A32_UINT,
    R32G32B32A32_SINT,
    R32G32B32_TYPELESS,
    R32G32B32_FLOAT,
    R32G32B32_UINT,
    R32G32B32_SINT,
    R16G16B16A16_TYPELESS,
    R16G16B16A16_FLOAT,
    R16G16B16A16_UNORM,
    R16G16B16A16_UINT,
    R16G16B16A16_SNORM,
    R16G16B16A16_SINT,
    R32G32_TYPELESS,
    R32G32_FLOAT,
    R32G32_UINT,
    R32G32_SINT,
    R32G8X24_TYPELESS,
    D32_FLOAT_S8X24_UINT,
    R32_FLOAT_X8X24_TYPELESS,
    X32_TYPELESS_G8X24_UINT,
    R10G10B10A2_TYPELESS,
    R10G10B10A2_UNORM,
    R10G10B10A2_UINT,
    R11G11B10_FLOAT,
    R8G8B8A8_TYPELESS,
    R8G8B8A8_UNORM,
    R8G8B8A8_UNORM_SRGB,
    R8G8B8A8_UINT,
    R8G8B8A8_SNORM,
    R8G8B8A8_SINT,
    R16G16_TYPELESS,
    R16G16_FLOAT,
    R16G16_UNORM,
    R16G16_UINT,
    R16G16_SNORM,
    R16G16_SINT,
    R32_TYPELESS,
    D32_FLOAT,
    R32_FLOAT,
    R32_UINT,
    R32_SINT,
    R24G8_TYPELESS,
    D24_UNORM_S8_UINT,
    R24_UNORM_X8_TYPELESS,
    X24_TYPELESS_G8_UINT,
    R8G8_TYPELESS,
    R8G8_UNORM,
    R8G8_UINT,
    R8G8_SNORM,
    R8G8_SINT,
    R16_TYPELESS,
    R16_FLOAT,
    D16_UNORM,
    R16_UNORM,
    R16_UINT,
    R16_SNORM,
    R16_SINT,
    R8_TYPELESS,
    R8_UNORM,
    R8_UINT,
    R8_SNORM,
    R8_SINT,
    A8_UNORM,
    R1_UNORM,
    R9G9B9E5_SHAREDEXP,
    R8G8_B8G8_UNORM,
    G8R8_G8B8_UNORM,
    BC1_TYPELESS,
    BC1_UNORM,
    BC1_UNORM_SRGB,
    BC2_TYPELESS,
    BC2_UNORM,
    BC2_UNORM_SRGB,
    BC3_TYPELESS,
    BC3_UNORM,
    BC3_UNORM_SRGB,
    BC4_TYPELESS,
    BC4_UNORM,
    BC4_SNORM,
    BC5_TYPELESS,
    BC5_UNORM,
    BC5_SNORM,
    B5G6R5_UNORM,
    B5G5R5A1_UNORM,
    B8G8R8A8_UNORM,
    B8G8R8X8_UNORM,
    R10G10B10_XR_BIAS_A2_UNORM,
    B8G8R8A8_TYPELESS,
    B8G8R8A8_UNORM_SRGB,
    B8G8R8X8_TYPELESS,
    B8G8R8X8_UNORM_SRGB,
    BC6H_TYPELESS,
    BC6H_UF16,
    BC6H_SF16,
    BC7_TYPELESS,
    BC7_UNORM,
    BC7_UNORM_SRGB,
    AYUV,
    Y410,
    Y416,
    NV12,
    P010,
    P016,
    OPAQUE_420, // DXGI_FORMAT_420_OPAQUE
    YUY2,
    Y210,
    Y216,
    NV11,
    AI44,
    IA44,
    P8,
    A8P8,
    B4G4R4A4_UNORM,
    P208,
    V208,
    V408,
    FORCE_UINT,
};

const PIXELFORMAT = struct {
    // dwFlags: DDPF,
    dwFourCC: [4]u8,
    dwRGBBitCount: i32,
    dwRBitMask: u32,
    dwGBitMask: u32,
    dwBBitMask: u32,
    dwABitMask: u32,
};

const HEADER_DXT10 = struct {
    dxgiFormat: DXGI_FORMAT,
    resourceDimension: DIMENSION,
    miscFlag: u32, // should be RESOURCE_MISC but we havent got bit flags yet
    arraySize: u32,
    miscFlags2: ALPHA_MODE,
};

const Header = struct {
    // dwFlags: DDSD,
    dwHeight: i32,
    dwWidth: i32,
    dwPitchOrLinearSize: i32,
    dwDepth: i32,
    dwMipMapCount: i32,
    dwReserved1: []i32,
    ddspf: PIXELFORMAT,
    // dwCaps: DDSCAPS,
    // dwCaps2: DDSCAPS2,
    dwCaps3: i32,
    dwCaps4: i32,
    dwReserved2: i32,
    header10: ?HEADER_DXT10,

    dataOffset: i32,
};

header: Header,

pub fn read(
    bytes: []u8,
) ParseError!DDS {
    const allocator = std.heap.c_allocator;
    var fbs = std.io.fixedBufferStream(bytes);
    const reader = fbs.reader();

    const endian: std.builtin.Endian = .little;

    const magic = reader.readBytesNoEof(4) catch return error.UnexpectedEof;
    assert(eql(u8, &magic, "DDS "));
    const dwSize = reader.readInt(i32, endian) catch return error.UnexpectedEof;
    assert(dwSize == 0x7C);

    // Bit flags
    // const dwFlags = reader.readInt(u32, endian) catch return error.UnexpectedEof;
    _ = reader.readInt(u32, endian) catch return error.UnexpectedEof;
    const dwHeight = reader.readInt(i32, endian) catch return error.UnexpectedEof;
    const dwWidth = reader.readInt(i32, endian) catch return error.UnexpectedEof;
    const dwPitchOrLinearSize = reader.readInt(i32, endian) catch return error.UnexpectedEof;
    const dwDepth = reader.readInt(i32, endian) catch return error.UnexpectedEof;
    const dwMipMapCount = reader.readInt(i32, endian) catch return error.UnexpectedEof;

    var dwReserved1 = allocator.alloc(i32, 11) catch return error.OutOfMemory;
    for (0..11) |i| {
        dwReserved1[i] = reader.readInt(i32, endian) catch return error.UnexpectedEof;
    }

    const dwSizePF: i32 = reader.readInt(i32, endian) catch return error.UnexpectedEof;
    assert(dwSizePF == 32);
    // Bit flags
    // const dwFlagsPF: u32 = reader.readInt(u32, endian) catch return error.UnexpectedEof;
    _ = reader.readInt(u32, endian) catch return error.UnexpectedEof;
    const dwFourCCPF: [4]u8 = reader.readBytesNoEof(4) catch return error.UnexpectedEof;
    const dwRGBBitCountPF: i32 = reader.readInt(i32, endian) catch return error.UnexpectedEof;
    const dwRBitMaskPF: u32 = reader.readInt(u32, endian) catch return error.UnexpectedEof;
    const dwGBitMaskPF: u32 = reader.readInt(u32, endian) catch return error.UnexpectedEof;
    const dwBBitMaskPF: u32 = reader.readInt(u32, endian) catch return error.UnexpectedEof;
    const dwABitMaskPF: u32 = reader.readInt(u32, endian) catch return error.UnexpectedEof;

    const ddspf: PIXELFORMAT = .{
        // .dwFlags = dwFlagsPF,
        .dwFourCC = dwFourCCPF,
        .dwRGBBitCount = dwRGBBitCountPF,
        .dwRBitMask = dwRBitMaskPF,
        .dwGBitMask = dwGBitMaskPF,
        .dwBBitMask = dwBBitMaskPF,
        .dwABitMask = dwABitMaskPF,
    };

    // Bit flags
    // const dwCaps = reader.readInt(u32, endian) catch return error.UnexpectedEof;
    // const dwCaps2 = reader.readInt(u32, endian) catch return error.UnexpectedEof;

    _ = reader.readInt(u32, endian) catch return error.UnexpectedEof;
    _ = reader.readInt(u32, endian) catch return error.UnexpectedEof;

    const dwCaps3 = reader.readInt(i32, endian) catch return error.UnexpectedEof;
    const dwCaps4 = reader.readInt(i32, endian) catch return error.UnexpectedEof;
    const dwReserved2 = reader.readInt(i32, endian) catch return error.UnexpectedEof;

    var header10: ?HEADER_DXT10 = null;
    if (eql(u8, &ddspf.dwFourCC, "DX10")) {
        header10 = HEADER_DXT10{
            .dxgiFormat = @enumFromInt(reader.readInt(u32, endian) catch return error.UnexpectedEof),
            .resourceDimension = @enumFromInt(reader.readInt(u32, endian) catch return error.UnexpectedEof),
            .miscFlag = reader.readInt(u32, endian) catch return error.UnexpectedEof,
            .arraySize = reader.readInt(u32, endian) catch return error.UnexpectedEof,
            .miscFlags2 = @enumFromInt(reader.readInt(u32, endian) catch return error.UnexpectedEof),
        };
    }

    const header = Header{
        // .dwFlags = dwFlags,
        .dwHeight = dwHeight,
        .dwWidth = dwWidth,
        .dwPitchOrLinearSize = dwPitchOrLinearSize,
        .dwDepth = dwDepth,
        .dwMipMapCount = dwMipMapCount,
        .dwReserved1 = dwReserved1,
        .ddspf = ddspf,
        // .dwCaps = dwCaps,
        // .dwCaps2 = dwCaps2,
        .dwCaps3 = dwCaps3,
        .dwCaps4 = dwCaps4,
        .dwReserved2 = dwReserved2,
        .header10 = header10,
        .dataOffset = if (eql(u8, &ddspf.dwFourCC, "DX10")) 0x94 else 0x80,
    };

    reader.skipBytes(@intCast(header.dataOffset), .{}) catch return error.UnexpectedEof;

    return DDS{
        .header = header,
    };
}

test {
    std.testing.refAllDecls(@This());
}

test "DSR TalkFont24.tpf.dcx" {
    const DCX = @import("dcx.zig");
    const TPF = @import("tpf.zig");

    const allocator = std.testing.allocator;

    const path = "dsr/font/english/TalkFont24.tpf.dcx";

    var file = try std.fs.cwd().openFile(
        path,
        .{ .mode = .read_only },
    );
    defer file.close();

    const fileBytes = try file.readToEndAlloc(allocator, try file.getEndPos());
    defer allocator.free(fileBytes);

    const dcx: DCX = try DCX.read(fileBytes);
    const tpf: TPF = try TPF.read(dcx.data);

    try std.testing.expect(eql(u8, tpf.textures[0].bytes[0..4], "DDS "));

    const dds: DDS = try read(tpf.textures[0].bytes);

    try std.testing.expect(dds.header.dwWidth == 1024);
    try std.testing.expect(dds.header.dwHeight == 1024);
}
