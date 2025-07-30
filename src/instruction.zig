const std = @import("std");
const OpCode = @import("op_code.zig").OpCode;

pub const Instruction = u32;

pub const MAX_ARG_BX = (1 << 18) - 1; // 262143
pub const MAX_ARG_SBX = MAX_ARG_BX >> 1; // 131071

pub fn op_code(self: Instruction) OpCode {
    const code_int = @as(u8, @truncate(self & 0x3f));
    return @as(OpCode, @enumFromInt(code_int));
}

pub fn op_name(self: Instruction) []const u8 {
    return op_code(self).info().desc;
}

pub fn a_b_c(self: Instruction) struct { i32, i32, i32 } {
    const a = @as(i32, @as(u8, @truncate((self >> 6) & 0xff)));
    const c = @as(i32, @as(u9, @truncate((self >> 14) & 0x1ff)));
    const b = @as(i32, @as(u9, @truncate((self >> 23) & 0x1ff)));
    return .{ a, b, c };
}

pub fn a_bx(self: Instruction) struct { i32, i32 } {
    const a = @as(i32, @as(u8, @truncate((self >> 6) & 0xff)));
    const bx = @as(i32, @as(u18, @truncate(self >> 14)));
    // std.debug.print("a_bx ==> a: {d}, bx: {d}\n", .{ a, bx });
    return .{ a, bx };
}

pub fn a_sbx(self: Instruction) struct { i32, i32 } {
    const a, const bx = a_bx(self);
    return .{ a, bx - MAX_ARG_SBX };
}

pub fn ax(self: Instruction) i32 {
    return @as(i32, @as(u26, @truncate(self >> 6)));
}

pub fn main() void {
    std.debug.print("hello world\n", .{});
}
