const std = @import("std");
const lua_state = @import("./lua_state.zig");
// const chunk = @import("./chunk.zig");
const binary_chunk = @import("./binary_chunk.zig");
const lua_value = @import("./lua_value.zig");
const instruction = @import("./instruction.zig");
const lua_arith = @import("./lua_arith.zig");
const utils = @import("./utils.zig");

const LuaValueType = lua_value.LuaValueType;
const LuaState = lua_state.LuaState;
const Instruction = instruction.Instruction;
const a_b_c = instruction.a_b_c;
const a_bx = instruction.a_bx;
const a_sbx = instruction.a_sbx;

pub const ArithOp = lua_arith.ArithOp;
pub const CompareOp = lua_arith.CompareOp;

const LFIELDS_PER_FLUSH: i32 = 50;
pub const LuaVm = struct {
    state: LuaState,

    /// 初始化 LuaVm 实例
    pub fn init(allocator: std.mem.Allocator, size: usize, proto: binary_chunk.Prototype) LuaVm {
        return .{
            .state = LuaState.init(allocator, size, proto),
        };
    }

    /// 释放 LuaVm 资源
    pub fn deinit(self: *LuaVm, allocator: std.mem.Allocator) void {
        self.state.deinit(allocator);
    }
    pub inline fn get_pc(self: *LuaVm) i32 {
        return self.state.pc;
    }

    pub fn add_pc(self: *LuaVm, n: i32) void {
        self.state.pc += n;
    }

    pub fn patch(self: *LuaVm) Instruction {
        const i = self.state.proto.codes[@as(usize, @intCast(self.state.pc))];
        self.state.pc += 1;
        return i;
    }

    pub fn get_constant(self: *LuaVm, idx: i32) void {
        const c = self.state.proto.constants[@as(usize, @intCast(idx))];
        switch (c) {
            .NIL => self.push_nil(),
            .BOOL => |b| self.push_bool(b),
            .INTEGER => |v| self.push_integer(v),
            .NUMBER => |v| self.push_number(v),
            .SHORT_STR => |s| self.push_string(s),
            .LONG_STR => |s| self.push_string(s),
        }
    }

    pub fn get_rk(self: *LuaVm, rk: i32) void {
        if (rk > 0xff) {
            self.get_constant(rk & 0xff);
        } else {
            self.push_value(rk + 1);
        }
    }

    pub fn execute(self: *LuaVm, instr: Instruction) void {
        switch (instruction.op_code(instr)) {
            .OP_MOVE => self.op_move(instr),
            .OP_LOADK => self.op_load_k(instr),
            .OP_LOADKX => self.op_load_kx(instr),
            .OP_LOADBOOL => self.op_load_bool(instr),
            .OP_LOADNIL => self.op_load_nil(instr),
            .OP_GETUPVAL => unreachable,
            .OP_GETTABUP => unreachable,
            .OP_GETTABLE => self.op_get_table(instr),
            .OP_SETTABUP => unreachable,
            .OP_SETUPVAL => unreachable,
            .OP_SETTABLE => self.op_set_table(instr),
            .OP_NEWTABLE => self.op_new_table(instr),
            .OP_SELF => unreachable,
            .OP_ADD => self.op_addition(instr),
            .OP_SUB => self.op_subtract(instr),
            .OP_MUL => self.op_multiply(instr),
            .OP_MOD => self.op_modulo(instr),
            .OP_POW => self.op_power(instr),
            .OP_DIV => self.op_division(instr),
            .OP_IDIV => self.op_idivision(instr),
            .OP_BAND => self.op_binary_and(instr),
            .OP_BOR => self.op_binary_or(instr),
            .OP_BXOR => self.op_binary_xor(instr),
            .OP_SHL => self.op_shift_left(instr),
            .OP_SHR => self.op_shift_right(instr),
            .OP_UNM => self.op_unary_unm(instr),
            .OP_BNOT => self.op_unary_not(instr),
            .OP_NOT => self.op_not(instr),
            .OP_LEN => self.op_length(instr),
            .OP_CONCAT => self.op_iconcat(instr),
            .OP_JMP => self.op_jump(instr),
            .OP_EQ => self.op_equal(instr),
            .OP_LT => self.op_less_than(instr),
            .OP_LE => self.op_less_equal(instr),
            .OP_TEST => self.op_test(instr),
            .OP_TESTSET => self.op_test_set(instr),
            .OP_CALL => unreachable,
            .OP_TAILCALL => unreachable,
            .OP_RETURN => unreachable,
            .OP_FORLOOP => self.op_for_loop(instr),
            .OP_FORPREP => self.op_for_prep(instr),
            .OP_TFORCALL => unreachable,
            .OP_TFORLOOP => unreachable,
            .OP_SETLIST => self.op_set_list(instr),
            .OP_CLOSURE => unreachable,
            .OP_VARARG => unreachable,
            .OP_EXTRAARG => unreachable,
        }
    }

    pub inline fn op_move(self: *LuaVm, instr: Instruction) void {
        var a, var b, const c = instruction.a_b_c(instr);

        a += 1;
        b += 1;
        _ = c;
        // std.debug.print("op_move: {d} -> {d}\n", .{ b, a });

        self.copy(b, a);
    }

    pub inline fn op_jump(self: *LuaVm, instr: Instruction) void {
        const a, const sBx = instruction.a_sbx(instr);
        // std.debug.print("op_jump: {d} -> {d}\n", .{ a, sBx });
        self.add_pc(sBx);
        if (a != 0) {
            unreachable; // Todo!
        }
    }

    pub inline fn op_load_nil(self: *LuaVm, instr: Instruction) void {
        // const abc = instruction.a_b_c(instr);
        var a, const b, const c = instruction.a_b_c(instr);
        // std.debug.print("op_load_nil: {d} -> {d}\n", .{ a, b });
        a += 1;
        _ = c;
        self.push_nil();
        var j: i32 = a;
        while (j <= a + b) : (j += 1) {
            self.copy(-1, j);
        }
        self.pop(1);
    }

    pub inline fn op_load_bool(self: *LuaVm, instr: Instruction) void {
        var a, const b, const c = instruction.a_b_c(instr);

        a += 1;

        self.push_bool(b != 0);
        self.replace(a);
        if (c != 0) {
            self.add_pc(1);
        }
    }

    pub inline fn op_load_k(self: *LuaVm, instr: Instruction) void {
        var a, const bx = instruction.a_bx(instr);
        a += 1;
        self.get_constant(bx);
        self.replace(a);
    }

    pub inline fn op_load_kx(self: *LuaVm, instr: Instruction) void {
        var a, const bx = instruction.a_bx(instr);
        a += 1;
        _ = bx;
        // const bx = abx.bx;
        // const adjusted_a = a + 1;
        const ax = instruction.ax(self.patch());
        self.get_constant(ax);
        self.replace(a);
    }

    inline fn binary_arith(self: *LuaVm, instr: Instruction, op: ArithOp) void {
        var a, var b, const c = instruction.a_b_c(instr);
        a += 1;
        b += 1;
        self.get_rk(b);
        self.get_rk(c);
        self.arith(op);
        self.replace(a);
    }

    inline fn unary_arith(self: *LuaVm, instr: Instruction, op: ArithOp) void {
        var a, var b, const c = instruction.a_b_c(instr);
        a += 1;
        b += 1;
        _ = c;
        self.push_value(b);
        self.arith(op);
        self.replace(a);
    }

    inline fn op_compare(self: *LuaVm, instr: Instruction, op: CompareOp) void {
        const a, const b, const c = instruction.a_b_c(instr);
        _ = a;
        self.get_rk(b);
        self.get_rk(c);
        if (self.compare(-2, -1, op)) {
            self.add_pc(1);
        }
        self.pop(2);
    }

    pub inline fn op_addition(self: *LuaVm, instr: Instruction) void {
        self.binary_arith(instr, .LUA_OPADD);
    }

    pub inline fn op_subtract(self: *LuaVm, instr: Instruction) void {
        self.binary_arith(instr, .LUA_OPSUB);
    }

    pub inline fn op_multiply(self: *LuaVm, instr: Instruction) void {
        self.binary_arith(instr, .LUA_OPMUL);
    }

    pub inline fn op_modulo(self: *LuaVm, instr: Instruction) void {
        self.binary_arith(instr, .LUA_OPMOD);
    }

    pub inline fn op_power(self: *LuaVm, instr: Instruction) void {
        self.binary_arith(instr, .LUA_OPPOW);
    }

    pub inline fn op_division(self: *LuaVm, instr: Instruction) void {
        self.binary_arith(instr, .LUA_OPDIV);
    }

    pub inline fn op_idivision(self: *LuaVm, instr: Instruction) void {
        self.binary_arith(instr, .LUA_OPIDIV);
    }

    pub inline fn op_binary_and(self: *LuaVm, instr: Instruction) void {
        self.binary_arith(instr, .LUA_OPBAND);
    }

    pub inline fn op_binary_or(self: *LuaVm, instr: Instruction) void {
        self.binary_arith(instr, .LUA_OPBOR);
    }

    pub inline fn op_binary_xor(self: *LuaVm, instr: Instruction) void {
        self.binary_arith(instr, .LUA_OPBXOR);
    }

    pub inline fn op_shift_left(self: *LuaVm, instr: Instruction) void {
        self.binary_arith(instr, .LUA_OPSHL);
    }

    pub inline fn op_shift_right(self: *LuaVm, instr: Instruction) void {
        self.binary_arith(instr, .LUA_OPSHR);
    }

    pub inline fn op_unary_unm(self: *LuaVm, instr: Instruction) void {
        self.unary_arith(instr, .LUA_OPUNM);
    }

    pub inline fn op_unary_not(self: *LuaVm, instr: Instruction) void {
        self.unary_arith(instr, .LUA_OPBNOT);
    }

    pub inline fn op_length(self: *LuaVm, instr: Instruction) void {
        var a, var b, const c = instruction.a_b_c(instr);
        _ = c;
        a += 1;
        b += 1;
        self.len(b);
        self.replace(a);
    }

    pub inline fn op_iconcat(self: *LuaVm, instr: Instruction) void {
        var a, var b, var c = instruction.a_b_c(instr);
        a += 1;
        b += 1;
        c += 1;
        const n = c - b + 1;
        const d = self.check_stack(n);
        _ = d;
        var j = b;

        while (j <= c) : (j += 1) {
            self.push_value(j);
        }
        self.concat(n);
        self.replace(a);
    }

    pub inline fn op_equal(self: *LuaVm, instr: Instruction) void {
        self.op_compare(instr, .LUA_OPEQ);
    }

    pub inline fn op_less_than(self: *LuaVm, instr: Instruction) void {
        self.op_compare(instr, .LUA_OPLT);
    }

    pub inline fn op_less_equal(self: *LuaVm, instr: Instruction) void {
        self.op_compare(instr, .LUA_OPLE);
    }

    pub inline fn op_not(self: *LuaVm, instr: Instruction) void {
        var a, var b, const c = instruction.a_b_c(instr);
        a += 1;
        b += 1;
        _ = c;
        self.push_bool(!self.to_bool(b));
        self.replace(a);
    }

    pub inline fn op_test_set(self: *LuaVm, instr: Instruction) void {
        var a, var b, const c = instruction.a_b_c(instr);
        a += 1;
        b += 1;

        if (self.to_bool(b) == (c != 0)) {
            self.copy(b, a);
        } else {
            self.add_pc(1);
        }
    }

    pub inline fn op_test(self: *LuaVm, instr: Instruction) void {
        var a, const b, const c = instruction.a_b_c(instr);
        _ = b;
        a += 1;
        // b += 1;
        // c += 1;
        if (self.to_bool(a) == (c != 0)) {
            self.add_pc(1);
        }
    }

    pub inline fn op_for_prep(self: *LuaVm, instr: Instruction) void {
        var a, const sBx = instruction.a_sbx(instr);
        a += 1;
        self.push_value(a);
        self.push_value(a + 2);
        self.arith(.LUA_OPSUB);
        self.replace(a);
        self.add_pc(sBx);
    }

    pub inline fn op_for_loop(self: *LuaVm, instr: Instruction) void {
        var a, const sBx = instruction.a_sbx(instr);
        a += 1;
        self.push_value(a + 2);
        self.push_value(a);
        self.arith(.LUA_OPADD);
        self.replace(a);
        const is_positive_step = self.to_number(a + 2) >= 0;
        if ((is_positive_step and self.compare(a, a + 1, .LUA_OPLE)) or
            (!is_positive_step and self.compare(a + 1, a, .LUA_OPLE)))
        {
            self.add_pc(sBx);
            self.copy(a, a + 3);
        }
    }

    pub inline fn op_new_table(self: *LuaVm, instr: Instruction) void {
        var a, const b, const c = instr.a_b_c();
        a += 1;
        self.create_table(self, utils.float_byte_to_integer(b), utils.float_byte_to_integer(c));
    }

    pub inline fn op_get_table(self: *LuaVm, instr: Instruction) void {
        var a, var b, const c = instr.a_b_c();
        a += 1;
        b += 1;
        self.get_rk(c);
        self.get_table(b);
        self.replace(c);
    }

    pub inline fn op_set_list(self: *LuaVm, instr: Instruction) void {
        var a, const b, var c = instr.a_b_c();
        a += 1;
        if (c > 0) {
            c -= 1;
        } else {
            c = self.patch().ax();
        }
        var idx: i32 = c * LFIELDS_PER_FLUSH;
        var j = 1;
        while (j <= b) : (j += 1) {
            idx += 1;
            self.push_value(a + j);
            self.set_index(a, idx);
        }
    }
    pub inline fn op_set_table(self: *LuaVm, instr: Instruction) void {
        var a, const b, const c = instr.a_b_c();
        a += 1;
        self.get_rk(b);
        self.get_rk(c);
        self.set_table(a);
    }
    // ============== 代理方法实现 ==============
    pub fn get_top(self: *LuaVm) i32 {
        return self.state.get_top();
    }

    pub fn abs_index(self: *LuaVm, index: i32) i32 {
        return self.state.abs_index(index);
    }

    pub fn check_stack(self: *LuaVm, n: i32) bool {
        return self.state.check_stack(n);
    }

    pub fn pop(self: *LuaVm, n: i32) void {
        self.state.pop(n);
    }

    pub fn copy(self: *LuaVm, from: i32, to: i32) void {
        self.state.copy(from, to);
    }

    pub fn replace(self: *LuaVm, index: i32) void {
        self.state.replace(index);
    }

    pub fn insert(self: *LuaVm, index: i32) void {
        self.state.insert(index);
    }

    pub fn remove(self: *LuaVm, index: i32) void {
        self.state.remove(index);
    }

    pub fn rotate(self: *LuaVm, index: i32, n: i32) void {
        self.state.rotate(index, n);
    }

    pub fn set_top(self: *LuaVm, index: i32) void {
        self.state.set_top(index);
    }

    pub fn type_name(self: *LuaVm, lua_type: LuaValueType) []const u8 {
        return self.state.type_name(lua_type);
    }

    pub fn type_of(self: *LuaVm, index: i32) LuaValueType {
        return self.state.type_of(index);
    }

    pub fn is_none(self: *LuaVm, index: i32) bool {
        return self.state.is_none(index);
    }

    pub fn is_nil(self: *LuaVm, index: i32) bool {
        return self.state.is_nil(index);
    }

    pub fn is_none_or_nil(self: *LuaVm, index: i32) bool {
        return self.state.is_none_or_nil(index);
    }

    pub fn is_bool(self: *LuaVm, index: i32) bool {
        return self.state.is_bool(index);
    }

    pub fn is_integer(self: *LuaVm, index: i32) bool {
        return self.state.is_integer(index);
    }

    pub fn is_number(self: *LuaVm, index: i32) bool {
        return self.state.is_number(index);
    }

    pub fn is_string(self: *LuaVm, index: i32) bool {
        return self.state.is_string(index);
    }

    pub fn to_bool(self: *LuaVm, index: i32) bool {
        return self.state.to_bool(index);
    }

    pub fn to_integer(self: *LuaVm, index: i32) i64 {
        return self.state.to_integer(index);
    }

    pub fn to_integer_x(self: *LuaVm, index: i32) ?i64 {
        return self.state.to_integer_x(index);
    }

    pub fn to_number(self: *LuaVm, index: i32) f64 {
        return self.state.to_number(index);
    }

    pub fn to_number_x(self: *LuaVm, index: i32) ?f64 {
        return self.state.to_number_x(index);
    }

    pub fn to_string(self: *LuaVm, index: i32) []const u8 {
        return self.state.to_string(index);
    }

    pub fn to_string_x(self: *LuaVm, index: i32) ?[]const u8 {
        return self.state.to_string_x(index);
    }

    pub fn push_value(self: *LuaVm, index: i32) void {
        self.state.push_value(index);
    }

    pub fn push_nil(self: *LuaVm) void {
        self.state.push_nil();
    }

    pub fn push_bool(self: *LuaVm, value: bool) void {
        self.state.push_bool(value);
    }

    pub fn push_integer(self: *LuaVm, value: i64) void {
        self.state.push_integer(value);
    }

    pub fn push_number(self: *LuaVm, value: f64) void {
        self.state.push_number(value);
    }

    pub fn push_string(self: *LuaVm, value: []const u8) void {
        self.state.push_string(value);
    }

    pub fn arith(self: *LuaVm, operator: ArithOp) void {
        self.state.arith(operator);
    }

    pub fn len(self: *LuaVm, idx: i32) void {
        self.state.len(idx);
    }

    pub fn concat(self: *LuaVm, n: i32) void {
        self.state.concat(n);
    }

    pub fn compare(self: *LuaVm, idx1: i32, idx2: i32, operator: CompareOp) bool {
        return self.state.compare(idx1, idx2, operator);
    }

    pub fn print_stack(self: *LuaVm) void {
        self.state.print_stack();
    }

    // ============== Table 相关代理方法 ==============
    pub fn new_table(self: *LuaVm) !void {
        try self.state.new_table();
    }

    pub fn create_table(self: *LuaVm, n_array: usize, n_record: usize) !void {
        try self.state.create_table(n_array, n_record);
    }

    pub fn get_table(self: *LuaVm, idx: i32) LuaValueType {
        return self.state.get_table(idx);
    }

    pub fn get_field(self: *LuaVm, idx: i32, key: []const u8) LuaValueType {
        return self.state.get_field(idx, key);
    }

    pub fn get_index(self: *LuaVm, idx: i32, i: i64) LuaValueType {
        return self.state.get_index(idx, i);
    }

    pub fn set_table(self: *LuaVm, idx: i32) void {
        self.state.set_table(idx);
    }

    pub fn set_field(self: *LuaVm, idx: i32, key: []const u8) void {
        self.state.set_field(idx, key);
    }

    pub fn set_index(self: *LuaVm, idx: i32) void {
        self.state.set_index(idx);
    }
    // ============== 代理方法实现 ==============
};
