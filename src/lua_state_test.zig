const std = @import("std");
const testing = std.testing;
const LuaState = @import("../src/lua_state.zig").LuaState;
const binary_chunk = @import("../src/binary_chunk.zig");
const lua_arith = @import("../src/lua_arith.zig");

const Prototype = binary_chunk.Prototype;
const ArithOp = lua_arith.ArithOp;
const CompareOp = lua_arith.CompareOp;

fn new_state(allocator: std.mem.Allocator, size: usize, proto: Prototype) LuaState {
    // 实际函数实现，与src中的定义匹配
    return LuaState.init(allocator, size, proto);
}
fn empty_proto() Prototype {
    return Prototype{ .source = "", .line_defined = 0, .last_line_defined = 0, .num_params = 0, .is_vararg = 0, .max_stack_size = 0, .codes = &.{}, .constants = &.{}, .upvalues = &.{}, .protos = &.{}, .line_info = &.{}, .loc_vars = &.{}, .upvalue_names = &.{} };
}
test "lua_state_test" {
    const allocator = std.testing.allocator;
    var proto = empty_proto();
    var state = new_state(allocator, 32, proto);
    defer state.free();

    state.push_bool(true);
    state.print_stack();

    state.push_integer(10);
    state.print_stack();

    state.push_nil();
    state.print_stack();

    state.push_string("hello");
    state.print_stack();

    state.push_value(-4);
    state.print_stack();

    state.replace(3);
    state.print_stack();

    state.set_top(6);
    state.print_stack();

    state.remove(-3);
    state.print_stack();

    state.set_top(-5);
    state.print_stack();
}

test "lua_state_arith_test" {
    const allocator = std.testing.allocator;
    var proto = empty_proto();
    var state = new_state(allocator, 32, proto);
    defer state.free();

    state.push_integer(1);
    state.push_string("2.0");
    state.push_string("3.0");
    state.push_number(4.0);
    state.print_stack();

    state.arith(ArithOp.LUA_OPADD);
    state.print_stack();

    state.arith(ArithOp.LUA_OPBNOT);
    state.print_stack();

    state.len(2);
    state.print_stack();

    state.concat(3);
    state.print_stack();

    state.push_bool(state.compare(1, 2, CompareOp.LUA_OPEQ));
    state.print_stack();

    try testing.expectEqual(false, state.to_bool(-1));
    try testing.expectEqualStrings("3-82.0", state.to_string(-2));
    try testing.expectEqual(true, state.to_bool(1));
}
