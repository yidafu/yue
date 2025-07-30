const std = @import("std");
const instruction = @import("instruction.zig");
const OpCode = @import("op_code.zig").OpCode;

const testing = std.testing;
const Instruction = instruction.Instruction;

// 测试 a_b_c 函数
test "instruction a_b_c" {
    //  ADD        0  0  4  0x1000d
    const instr: Instruction = 0x1000d;

    // 调用 a_b_c 函数
    const a, const b, const c = instruction.a_b_c(instr);
    try testing.expectEqual(instruction.op_code(instr), OpCode.OP_ADD);
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

    try testing.expectEqual(instruction.op_code(instr), OpCode.OP_LOADK);

    // 调用 a_bx 函数
    const a, const bx = instruction.a_bx(instr);
    std.debug.print("a: {d}, bx: {d}\n", .{ a, bx });

    // 验证结果
    try testing.expectEqual(a, 1);
    try testing.expectEqual(bx, 1);
}

// 测试 a_sbx 函数
test "instruction a_sbx" {
    //  1  4     0x8000c068
    const instr: Instruction = 0x8000c068;
    try testing.expectEqual(instruction.op_code(instr), OpCode.OP_FORPREP);

    // 调用 a_sbx 函数
    const a, const sBx = instruction.a_sbx(instr);
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
    const ax = instruction.ax(instr);
    std.debug.print("ax: {d}\n", .{ax});
    // 验证结果
    try testing.expectEqual(ax, 50331648);
}

// 测试 opCode 函数
test "instruction opCode" {
    const instr: Instruction = 1;
    // 调用 opCode 函数
    const result = instruction.op_code(instr);
    try testing.expectEqual(result, OpCode.OP_LOADK);

    try testing.expectEqual(instruction.op_code(0x800026), OpCode.OP_RETURN);
}

// 测试 opName 函数
test "instruction opName" {
    // 创建一个指令，其中包含 opcode=0x01（是 OP_LOADK）
    const instr: Instruction = 0x1;

    // 调用 opName 函数
    const result = instruction.op_name(instr);
    try testing.expectEqualStrings(result, "LOADK");
}
