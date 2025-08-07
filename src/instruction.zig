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

const testing = std.testing;

// 测试 a_b_c 函数
test "instruction a_b_c" {
    //  ADD        0  0  4  0x1000d
    const instr: Instruction = 0x1000d;

    // 调用 a_b_c 函数
    const a, const b, const c = a_b_c(instr);
    try testing.expectEqual(op_code(instr), OpCode.OP_ADD);
    std.debug.print("a: {d}, b: {d}, c: {d}\n", .{ a, b, c });
    // 验证结果
    try testing.expectEqual(a, 0);
    try testing.expectEqual(b, 0);
    try testing.expectEqual(c, 4);
}

// 测试 a_bx 函数
test "instruction a_bx" {
    //  LOADK        1  -2    0x4041
    const instr: Instruction = 0x4041;

    try testing.expectEqual(op_code(instr), OpCode.OP_LOADK);

    // 调用 a_bx 函数
    const a, const bx = a_bx(instr);
    std.debug.print("a: {d}, bx: {d}\n", .{ a, bx });

    // 验证结果
    try testing.expectEqual(a, 1);
    try testing.expectEqual(bx, 1);
}

// 测试 a_sbx 函数
test "instruction a_sbx" {
    //  1  4     0x8000c068
    const instr: Instruction = 0x8000c068;
    try testing.expectEqual(op_code(instr), OpCode.OP_FORPREP);

    // 调用 a_sbx 函数
    const a, const sBx = a_sbx(instr);
    std.debug.print("a: {d}, sBx: {d}\n", .{ a, sBx });

    // 验证结果
    try testing.expectEqual(a, 1);
    try testing.expectEqual(sBx, 4);
}

// 测试 ax 函数
test "instruction ax" {
    // 创建一个指令，其中包含 ax=0x1234567
    const instr: Instruction = 0x300_0000 << 6;

    // 调用 ax 函数
    const _ax = ax(instr);
    std.debug.print("ax: {d}\n", .{_ax});
    // 验证结果
    try testing.expectEqual(_ax, 50331648);
}

// 测试 opCode 函数
test "instruction opCode" {
    const instr: Instruction = 1;
    // 调用 opCode 函数
    const result = op_code(instr);
    try testing.expectEqual(result, OpCode.OP_LOADK);

    try testing.expectEqual(op_code(0x800026), OpCode.OP_RETURN);
}

// 测试 opName 函数
test "instruction opName" {
    // 创建一个指令，其中包含 opcode=0x01（是 OP_LOADK）
    const instr: Instruction = 0x1;

    // 调用 opName 函数
    const result = op_name(instr);
    try testing.expectEqualStrings(result, "LOADK");
}
