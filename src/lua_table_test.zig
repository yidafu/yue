const std = @import("std");
const testing = std.testing;
const lua_table = @import("lua_table.zig");
const lua_value = @import("lua_value.zig");
const LuaTable = lua_table.LuaTable;
const LuaValue = lua_value.LuaValue;

// 测试表初始化
test "LuaTable init" {
    const allocator = testing.allocator;
    var table = try LuaTable.init(allocator, 0);
    defer table.arr.deinit();
    defer table.map.deinit();

    try testing.expectEqual(table.arr.items.len, 0);
    try testing.expectEqual(table.map.count(), 0);
}

// 测试数组部分的基本操作
test "LuaTable array operations" {
    const allocator = testing.allocator;
    var table = try LuaTable.init(allocator, 5);
    defer table.arr.deinit();
    defer table.map.deinit();

    // 添加元素到数组
    table.put(lua_value.lua_integer(1), lua_value.lua_string("one"));
    table.put(lua_value.lua_integer(2), lua_value.lua_string("two"));
    table.put(lua_value.lua_integer(3), lua_value.lua_string("three"));

    // 检查数组长度
    try testing.expectEqual(table.len(), 3);

    // 检查获取元素
    const val1 = table.get(lua_value.lua_integer(1));
    try testing.expect(val1.is_string());
    try testing.expectEqualStrings(val1.to_string(), "one");

    const val2 = table.get(lua_value.lua_integer(2));
    try testing.expect(val2.is_string());
    try testing.expectEqualStrings(val2.to_string(), "two");

    // 测试数组收缩
    table.put(lua_value.lua_integer(3), lua_value.lua_nil());
    try testing.expectEqual(table.len(), 2);

    // 测试数组扩展
    table.put(lua_value.lua_integer(3), lua_value.lua_string("three"));
    try testing.expectEqual(table.len(), 3);
}

// 测试映射部分的基本操作
test "LuaTable map operations" {
    const allocator = testing.allocator;
    var table = try LuaTable.init(allocator, 0);
    defer table.arr.deinit();
    defer table.map.deinit();

    // 添加元素到映射
    table.put(lua_value.lua_string("name"), lua_value.lua_string("Lua"));
    table.put(lua_value.lua_string("version"), lua_value.lua_number(5.4));

    // 检查映射大小
    try testing.expectEqual(table.map.count(), 2);

    // 检查获取元素
    const name_val = table.get(lua_value.lua_string("name"));
    try testing.expect(name_val.is_string());
    try testing.expectEqualStrings(name_val.to_string(), "Lua");

    const ver_val = table.get(lua_value.lua_string("version"));
    try testing.expect(ver_val.is_number());
    try testing.expectEqual(ver_val.to_number(), 5.4);

    // 测试删除元素
    table.put(lua_value.lua_string("version"), lua_value.lua_nil());
    try testing.expectEqual(table.map.count(), 1);
}

// 测试混合操作
test "LuaTable mixed operations" {
    const allocator = testing.allocator;
    var table = try LuaTable.init(allocator, 2);
    defer table.arr.deinit();
    defer table.map.deinit();

    // 混合数组和映射操作
    table.put(lua_value.lua_integer(1), lua_value.lua_string("first"));
    table.put(lua_value.lua_integer(2), lua_value.lua_string("second"));
    table.put(lua_value.lua_string("key"), lua_value.lua_integer(42));

    // 检查长度和计数
    try testing.expectEqual(table.len(), 2);
    try testing.expectEqual(table.map.count(), 1);

    // 检查获取不同类型的元素
    const arr_val = table.get(lua_value.lua_integer(1));
    try testing.expect(arr_val.is_string());
    try testing.expectEqualStrings(arr_val.to_string(), "first");

    const map_val = table.get(lua_value.lua_string("key"));
    try testing.expect(map_val.is_integer());
    try testing.expectEqual(map_val.to_integer(), 42);
}

// 测试expand_array功能
test "LuaTable expand array" {
    const allocator = testing.allocator;
    var table = try LuaTable.init(allocator, 1);
    defer table.arr.deinit();
    defer table.map.deinit();

    // 先放入非连续索引
    table.put(lua_value.lua_integer(1), lua_value.lua_string("one"));
    table.put(lua_value.lua_integer(3), lua_value.lua_string("three"));

    // 此时数组长度应为1，3在映射中
    try testing.expectEqual(table.len(), 1);
    try testing.expectEqual(table.map.count(), 1);

    // 放入索引2，触发数组扩展
    table.put(lua_value.lua_integer(2), lua_value.lua_string("two"));

    // 现在数组长度应为3，映射为空
    try testing.expectEqual(table.len(), 3);
    try testing.expectEqual(table.map.count(), 0);

    // 验证所有值都在数组中
    const val1 = table.get(lua_value.lua_integer(1));
    try testing.expectEqualStrings(val1.to_string(), "one");

    const val2 = table.get(lua_value.lua_integer(2));
    try testing.expectEqualStrings(val2.to_string(), "two");

    const val3 = table.get(lua_value.lua_integer(3));
    try testing.expectEqualStrings(val3.to_string(), "three");
}
