const std = @import("std");

pub const DCX = @import("dcx.zig");
pub const TPF = @import("tpf.zig");

pub const ParseError = error{
    InvalidMagic,
    UnsupportedCompression,
    DecompressionFailed,
    OutOfMemory,
    UnexpectedEof,
    UnknownCompression,
    UnknownPlatform,
};

test {
    std.testing.refAllDecls(@This());
}
