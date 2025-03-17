const std = @import("std");
const DCX = @import("dcx.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
