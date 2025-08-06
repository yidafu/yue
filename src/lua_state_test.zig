const std = @import("std");
const testing = std.testing;
const LuaState = @import("../src/lua_state.zig").LuaState;
const binary_chunk = @import("../src/binary_chunk.zig");
const lua_arith = @import("../src/lua_arith.zig");
const lua_value = @import("../src/lua_value.zig");

const Prototype = binary_chunk.Prototype;
const ArithOp = lua_arith.ArithOp;
const CompareOp = lua_arith.CompareOp;
const LuaValueType = lua_value.LuaValueType;

fn new_state(allocator: std.mem.Allocator, size: usize, proto: Prototype) LuaState {
    // 实际函数实现，与src中的定义匹配
    return LuaState.init(allocator, size, proto);
}
fn empty_proto() Prototype {
    return Prototype{ .source = "", .line_defined = 0, .last_line_defined = 0, .num_params = 0, .is_vararg = 0, .max_stack_size = 0, .codes = &.{}, .constants = &.{}, .upvalues = &.{}, .protos = &.{}, .line_info = &.{}, .loc_vars = &.{}, .upvalue_names = &.{} };
}
test "lua_state_test" {
    const allocator = std.testing.allocator;
    const proto = empty_proto();
    var state = new_state(allocator, 32, proto);
    defer state.deinit(allocator);

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
    const proto = empty_proto();
    var state = new_state(allocator, 32, proto);
    defer state.deinit(allocator);

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

// 测试表操作
test "lua_state_table_operations" {
    const allocator = std.testing.allocator;
    const proto = empty_proto();
    var state = new_state(allocator, 32, proto);
    defer state.deinit(allocator);

    // 测试创建表
    try state.new_table();
    try testing.expectEqual(.LUA_TTABLE, state.type_of(-1));

    // 测试设置和获取字段
    state.push_string("name");
    state.push_string("Lua");
    state.set_table(-3);
    state.print_stack();

    state.push_string("name");
    _ = state.get_table(@as(i32, -2));
    try testing.expectEqual(.LUA_TSTRING, state.type_of(-1));
    try testing.expectEqualStrings("Lua", state.to_string(-1));
    state.pop(1);

    // 测试 get_field 和 set_field
    state.push_number(5.4);
    state.set_field(@as(i32, -2), "version");
    state.print_stack();

    _ = state.get_field(@as(i32, -2), "version");
    try testing.expectEqual(.LUA_TNUMBER, state.type_of(-1));
    try testing.expectEqual(5.4, state.to_number(-1));
    state.pop(1);

    // 测试数组操作
    state.push_integer(1);
    state.push_string("one");
    state.set_table(-3);
    state.print_stack();

    _ = state.get_index(@as(i32, -1), 1);
    try testing.expectEqual(.LUA_TSTRING, state.type_of(-1));
    try testing.expectEqualStrings("one", state.to_string(-1));
    state.pop(1);

    // 测试设置索引值
    state.push_string("two");
    state.set_index(-2);
    state.print_stack();

    _ = state.get_index(@as(i32, -1), 2);
    try testing.expectEqual(.LUA_TSTRING, state.type_of(-1));
    try testing.expectEqualStrings("two", state.to_string(-1));
}

// 测试表长度
test "lua_state_table_len" {
    const allocator = std.testing.allocator;
    const proto = empty_proto();
    var state = new_state(allocator, 32, proto);
    defer state.deinit(allocator);

    // 创建表并添加元素
    try state.create_table(5, 0);
    var i: i64 = 1;
    while (i <= 3) : (i += 1) {
        state.push_integer(i);
        state.push_string("value");
        state.set_table(-3);
    }

    // 测试表长度
    state.len(-1);
    try testing.expectEqual(3, state.to_integer(-1));
}

// 测试嵌套表
test "lua_state_nested_tables" {
    const allocator = std.testing.allocator;
    const proto = empty_proto();
    var state = new_state(allocator, 32, proto);
    defer state.deinit(allocator);

    // 创建外层表
    try state.new_table();
    state.print_stack(); // 打印栈状态: [table]

    // 创建内层表
    try state.new_table();
    state.print_stack(); // 打印栈状态: [table, table]
    state.push_string("inner_key");
    state.print_stack(); // 打印栈状态: [table, table, string]
    state.push_string("inner_value");
    state.print_stack(); // 打印栈状态: [table, table, string, string]
    state.set_table(-3);
    state.print_stack(); // 打印栈状态: [table, table]

    // 将内层表放入外层表
    state.push_string("nested");
    state.print_stack(); // 打印栈状态: [table, table, string]
    state.set_table(-3);
    state.print_stack(); // 打印栈状态: [table]

    // 获取嵌套表的值
    try testing.expectEqual(.LUA_TTABLE, state.type_of(-1)); // 确保栈顶是一个表
    _ = state.get_field(@as(i32, -1), "nested");
    _ = state.get_field(@as(i32, -1), "inner_key");
    try testing.expectEqualStrings("inner_value", state.to_string(-1));
}
