const std = @import("std");
const OpCode = @import("op_code.zig").OpCode;

pub const Instruction = u32;

pub const MAX_ARG_BX = (1 << 18) - 1;
pub const MAX_ARG_SBX = MAX_ARG_BX >> 1;

pub fn opCode(self: Instruction) OpCode {
    const code_int = @as(u8, @truncate(self & 0x3f));
    return @as(OpCode, @enumFromInt(code_int));
}

pub fn opName(self: Instruction) []const u8 {
    return opCode(self).info().desc;
}

pub fn a_b_c(self: Instruction) [3]i32 {
    const a = @as(i32, @as(u8, @truncate((self >> 6) & 0xff)));
    const c = @as(i32, @as(u9, @truncate((self >> 14) & 0x1ff)));
    const b = @as(i32, @as(u9, @truncate((self >> 23) & 0x1ff)));
    return .{ a, b, c };
}

pub fn a_bx(self: Instruction) [2]i32 {
    const a = @as(i32, @as(u8, @truncate((self >> 6) & 0xff)));
    const bx = @as(i32, @as(u18, @truncate(self >> 14)));
    return .{ a, bx };
}

pub fn a_sbx(self: Instruction) [2]i32 {
    const abx = a_bx(self);
    return .{ abx[0], abx[1] - MAX_ARG_SBX };
}

pub fn ax(self: Instruction) i32 {
    return @as(i32, @as(u26, @truncate(self >> 6)));
}
