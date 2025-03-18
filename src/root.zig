pub const DCX = @import("dcx.zig");
pub const TPF = @import("tpf.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
