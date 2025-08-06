const std = @import("std");
const binary_chunk = @import("binary_chunk.zig");
const lua_value = @import("lua_value.zig");
const lua_arith = @import("lua_arith.zig");

const LuaValueType = lua_value.LuaValueType;
const LuaValue = lua_value.LuaValue;
pub const ArithOp = lua_arith.ArithOp;

pub const CompareOp = lua_arith.CompareOp;

/// Lua值列表类型，用于表示Lua栈
pub const ListLuaValue = struct {
    values: std.ArrayList(LuaValue),
    allocator: std.mem.Allocator,
    /// 初始化指定容量的列表
    pub fn initCapacity(allocator: std.mem.Allocator, capacity: usize) !ListLuaValue {
        return .{
            .values = try std.ArrayList(LuaValue).initCapacity(allocator, capacity),
            .allocator = allocator,
        };
    }

    /// 释放列表资源
    pub fn deinit(self: *ListLuaValue) void {
        self.values.deinit();
    }

    /// 添加元素到列表末尾
    pub fn append(self: *ListLuaValue, value: LuaValue) void {
        self.values.append(value) catch unreachable;
    }

    /// 移除并返回列表末尾的元素
    pub fn pop(self: *ListLuaValue) LuaValue {
        return self.values.pop() orelse unreachable;
    }

    /// 检查索引是否有效（Lua索引从1开始）
    pub fn is_valid(self: *ListLuaValue, index: i32) bool {
        const abs_idx = self.abs_index(index);
        return abs_idx > 0 and abs_idx <= @as(i32, @intCast(self.values.items.len));
    }

    /// 计算绝对索引（处理负索引）
    pub fn abs_index(self: *ListLuaValue, index: i32) i32 {
        if (index >= 0) {
            return index;
        }
        return index + @as(i32, @intCast(self.values.items.len)) + 1;
    }

    /// 私有方法：获取指定索引的Lua值
    fn get_value(self: *ListLuaValue, index: i32) LuaValue {
        const abs_idx = self.abs_index(index);
        if (abs_idx > 0 and abs_idx <= @as(i32, @intCast(self.values.items.len))) {
            return self.values.items[@as(usize, @intCast(abs_idx - 1))];
        }
        return lua_value.lua_nil();
    }

    /// 私有方法：设置指定索引的Lua值
    fn set_value(self: *ListLuaValue, index: i32, value: LuaValue) void {
        const abs_idx = self.abs_index(index);
        if (abs_idx > 0 and abs_idx <= @as(i32, @intCast(self.values.items.len))) {
            self.values.items[@as(usize, @intCast(abs_idx - 1))] = value;
            return;
        }
        @panic("invalid index!");
    }

    /// 私有方法：反转指定区间的元素
    fn reverse_values(self: *ListLuaValue, from: usize, to: usize) void {
        var f = from;
        var t = to;
        while (f < t) {
            std.mem.swap(LuaValue, &self.values.items[f], &self.values.items[t]);
            f += 1;
            t -= 1;
        }
    }
};

pub const LuaState = struct {
    stack: ListLuaValue,
    proto: binary_chunk.Prototype,
    pc: i32,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, size: usize, proto: binary_chunk.Prototype) LuaState {
        return .{
            .stack = ListLuaValue.initCapacity(allocator, size) catch unreachable,
            .proto = proto,
            .pc = 0,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *LuaState, allocator: std.mem.Allocator) void {
        self.stack.deinit();
        self.proto.deinit(allocator);
    }

    /// 获取栈顶索引（Lua风格，从1开始计数）
    pub fn get_top(self: *LuaState) i32 {
        return @as(i32, @intCast(self.stack.values.items.len)) + 1;
    }

    /// 计算绝对索引（调用栈的absIndex方法）
    pub fn abs_index(self: *LuaState, index: i32) i32 {
        return self.stack.abs_index(index);
    }

    /// 检查栈空间（C3动态列表始终返回true）
    pub fn check_stack(_: *LuaState, _: i32) bool {
        return true;
    }

    /// 弹出n个元素
    pub fn pop(self: *LuaState, n: i32) void {
        var i: i32 = 0;
        while (i < n) : (i += 1) {
            _ = self.stack.values.pop();
            // if (value) |*v| {
            //     v.deinit(self.allocator);
            // }
        }
    }

    /// 弹出一个元素并返回其值
    pub fn pop_value(self: *LuaState) LuaValue {
        return self.stack.values.pop() orelse lua_value.lua_nil();
    }

    /// 复制元素（从from_index到to_index）
    pub fn copy(self: *LuaState, from_index: i32, to_index: i32) void {
        const from_value = self.stack.get_value(from_index);
        self.stack.set_value(to_index, from_value);
    }

    /// 替换指定索引的元素（弹出栈顶值并设置）
    pub fn replace(self: *LuaState, index: i32) void {
        const value = self.pop_value();
        self.stack.set_value(index, value);
    }

    /// 在指定索引插入元素（通过旋转实现）
    pub fn insert(self: *LuaState, index: i32) void {
        self.rotate(index, 1);
    }

    /// 移除指定索引的元素（通过旋转后弹出）
    pub fn remove(self: *LuaState, index: i32) void {
        self.rotate(index, -1);
        _ = self.pop(1);
    }

    /// 旋转栈元素（实现区间反转）
    pub fn rotate(self: *LuaState, index: i32, n: i32) void {
        const top = @as(i32, @intCast(self.stack.values.items.len)) - 1;
        const p = self.abs_index(index) - 1;
        const middle = if (n > 0) top - n else p - n - 1;

        self.stack.reverse_values(@as(usize, @intCast(p)), @as(usize, @intCast(middle)));
        self.stack.reverse_values(@as(usize, @intCast(middle + 1)), @as(usize, @intCast(top)));
        self.stack.reverse_values(@as(usize, @intCast(p)), @as(usize, @intCast(top)));
    }

    /// 设置栈顶位置（调整栈长度）
    pub fn set_top(self: *LuaState, index: i32) void {
        const new_top = self.abs_index(index);
        if (new_top < 0) {
            @panic("stack underflow!");
        }
        const current_len = @as(i32, @intCast(self.stack.values.items.len));
        const n = current_len - new_top;
        // std.debug.print("set top {d} -> {d}", .{ n, new_top });
        if (n > 0) {
            var i: i32 = 0;
            while (i < n) : (i += 1) {
                _ = self.stack.values.pop();
            }
        } else if (n < 0) {
            var i: i32 = 0;
            while (i > n) : (i -= 1) {
                self.stack.values.append(lua_value.lua_nil()) catch @panic("out of memory");
            }
        }
    }

    /// 获取Lua值类型的名称
    pub fn type_name(_: *LuaState, lua_type: LuaValueType) []const u8 {
        return switch (lua_type) {
            .LUA_TNONE => "none",
            .LUA_TNIL => "nil",
            .LUA_TBOOLEAN => "boolean",
            .LUA_TNUMBER => "number",
            .LUA_TSTRING => "string",
            .LUA_TTABLE => "table",
            else => "userdata",
        };
    }

    /// 获取指定索引处的值类型
    pub fn type_of(self: *LuaState, index: i32) LuaValueType {
        const abs_idx = self.stack.abs_index(index);
        if (self.stack.is_valid(abs_idx)) {
            const value = self.stack.get_value(abs_idx);
            return lua_value.type_of(value);
        }
        return .LUA_TNONE;
    }

    /// 检查是否为NONE类型
    pub fn is_none(self: *LuaState, index: i32) bool {
        return self.type_of(index) == .LUA_TNONE;
    }

    /// 检查是否为NIL类型
    pub fn is_nil(self: *LuaState, index: i32) bool {
        return self.type_of(index) == .LUA_TNIL;
    }

    /// 检查是否为NONE或NIL类型
    pub fn is_none_or_nil(self: *LuaState, index: i32) bool {
        const t = self.type_of(index);
        return t == .LUA_TNIL or t == .LUA_TNONE;
    }

    /// 检查是否为布尔类型
    pub fn is_bool(self: *LuaState, index: i32) bool {
        return self.type_of(index) == .LUA_TBOOLEAN;
    }

    /// 检查是否为整数类型
    pub fn is_integer(self: *LuaState, index: i32) bool {
        return self.type_of(index) == .LUA_TNUMBER;
    }

    /// 检查是否为数值类型（整数或浮点数）
    pub fn is_number(self: *LuaState, index: i32) bool {
        const t = self.type_of(index);
        return t == .LUA_TNUMBER or t == .LUA_TINTEGER;
    }

    /// 检查是否为字符串类型（包括数值类型可转换为字符串的情况）
    pub fn is_string(self: *LuaState, index: i32) bool {
        const t = self.type_of(index);
        return t == .LUA_TSTRING or t == .LUA_TNUMBER or t == .LUA_TINTEGER;
    }

    /// 将指定索引处的值转换为布尔值
    pub fn to_bool(self: *LuaState, index: i32) bool {
        const value = self.stack.get_value(index);
        return switch (value) {
            .LUA_TBOOLEAN => |b| b,
            .LUA_TNIL => false,
            else => true,
        };
    }

    /// 将指定索引处的值转换为整数（失败返回0）
    pub fn to_integer(self: *LuaState, index: i32) i64 {
        return self.to_integer_x(index) orelse 0;
    }

    /// 将指定索引处的值转换为整数（可选返回）
    pub fn to_integer_x(self: *LuaState, index: i32) ?i64 {
        const value = self.stack.get_value(index);
        return switch (value) {
            .LUA_TINTEGER => |i| i,
            .LUA_TNUMBER => |n| @as(i64, @intFromFloat(n)),
            else => null,
        };
    }

    /// 将指定索引处的值转换为浮点数（失败返回0.0）
    pub fn to_number(self: *LuaState, index: i32) f64 {
        return self.to_number_x(index) orelse 0.0;
    }

    /// 将指定索引处的值转换为浮点数（可选返回）
    pub fn to_number_x(self: *LuaState, index: i32) ?f64 {
        const value = self.stack.get_value(index);
        return switch (value) {
            .LUA_TINTEGER => |i| @as(f64, @floatFromInt(i)),
            .LUA_TNUMBER => |n| n,
            else => null,
        };
    }

    /// 将指定索引处的值转换为字符串（失败返回空字符串）
    pub fn to_string(self: *LuaState, index: i32) []const u8 {
        return self.to_string_x(index) orelse "";
    }

    /// 将指定索引处的值转换为字符串（可选返回）
    pub fn to_string_x(self: *LuaState, index: i32) ?[]const u8 {
        const value = self.stack.get_value(index);
        return switch (value) {
            .LUA_TSTRING => |s| s,
            .LUA_TINTEGER => |i| {
                const str = std.fmt.allocPrint(self.stack.values.allocator, "{d}", .{i}) catch return null;
                self.stack.set_value(index, lua_value.lua_string(str));
                return str;
            },
            .LUA_TNUMBER => |n| {
                const str = std.fmt.allocPrint(self.stack.values.allocator, "{d}", .{n}) catch return null;
                self.stack.set_value(index, lua_value.lua_string(str));
                return str;
            },
            else => null,
        };
    }

    pub fn push_value(self: *LuaState, index: i32) void {
        const value = self.stack.get_value(index);
        self.append(value);
    }

    pub fn push_nil(self: *LuaState) void {
        self.append(lua_value.lua_nil());
    }

    pub fn push_bool(self: *LuaState, value: bool) void {
        self.append(lua_value.lua_bool(value));
    }

    pub fn push_integer(self: *LuaState, value: i64) void {
        self.append(lua_value.lua_integer(value));
    }

    pub fn push_number(self: *LuaState, value: f64) void {
        // std.debug.print("push_number {d}\n", .{value});
        self.append(lua_value.lua_number(value));
    }

    pub fn append(self: *LuaState, value: LuaValue) void {
        self.stack.append(value);
    }

    pub fn push_string(self: *LuaState, value: []const u8) void {
        self.append(lua_value.lua_string(value));
    }

    /// 执行算术操作
    pub fn arith(self: *LuaState, operator: ArithOp) void {
        const b = self.pop_value();
        const a = (if (operator != .LUA_OPPOW and operator != .LUA_OPBNOT)
            self.pop_value()
        else
            b);
        const op = lua_arith.operator_map.get(operator) orelse @panic("invalid operator");
        const result = lua_arith.arith_fn(a, b, op) catch |err| {
            std.debug.print("Arithmetic error: {s}\n", .{@errorName(err)});
            @panic("arithmetic error");
        };
        self.stack.values.append(result) catch @panic("out of memory");
    }

    /// 比较两个值
    pub fn compare(self: *LuaState, idx1: i32, idx2: i32, op: CompareOp) bool {
        const a = self.stack.get_value(idx1);
        const b = self.stack.get_value(idx2);
        return switch (op) {
            .LUA_OPEQ => a.equal(b),
            .LUA_OPLT => a.less_than(b),
            .LUA_OPLE => a.less_equal(b),
        };
    }

    /// 获取值的长度
    pub fn len(self: *LuaState, idx: i32) void {
        const a = self.stack.get_value(idx);
        switch (a) {
            .LUA_TSTRING => |s| self.push_integer(@as(i64, @intCast(s.len))),
            .LUA_TTABLE => |t| self.push_integer(@as(i64, @intCast(t.len()))),
            else => @panic("length error"),
        }
    }

    /// 字符串拼接
    pub fn concat(self: *LuaState, n: i32) void {
        if (n == 0) {
            self.push_string("");
        } else if (n >= 2) {
            var i: i32 = 1;
            while (i < n) : (i += 1) {
                if (self.is_string(-1) and self.is_string(-2)) {
                    const s1 = self.to_string(-1);
                    const s2 = self.to_string(-2);
                    // std.debug.print("{s} + {s}\n", .{ s1, s2 });
                    _ = self.pop(2);

                    const new_str: []u8 = std.mem.concat(self.allocator, u8, &.{ s1, s2 }) catch @panic("Out of memory");
                    // std.debug.print("new string => {s}\n", .{new_str});
                    self.push_string(new_str);
                    // self.stack.values.append() catch @panic("out of memory");
                } else {
                    @panic("concatenation error");
                }
            }
        }
    }

    pub fn new_table(self: *LuaState) !void {
        try self.create_table(0, 0);
    }

    pub fn create_table(self: *LuaState, n_array: usize, n_record: usize) !void {
        const table = try lua_value.lua_table(self.allocator, n_array, n_record);
        self.append(table);
    }

    pub fn get_table(self: *LuaState, idx: i32) LuaValueType {
        const table = self.stack.get_value(idx);
        const key = self.pop_value();
        return self.get_table_internal(table, key);
    }

    fn get_table_internal(self: *LuaState, table: LuaValue, key: LuaValue) LuaValueType {
        switch (table) {
            .LUA_TTABLE => |t| {
                const value = t.get(key);
                self.append(value);
                return lua_value.type_of(value);
            },
            else => @panic("not a table"),
        }
    }

    pub fn get_field(self: *LuaState, idx: i32, key: []const u8) LuaValueType {
        self.push_string(key);
        return self.get_table(idx);
    }

    pub fn get_index(self: *LuaState, idx: i32, i: i64) LuaValueType {
        const table = self.stack.get_value(idx);
        return self.get_table_internal(table, lua_value.lua_integer(i));
    }

    pub fn set_table(self: *LuaState, idx: i32) void {
        const table = self.stack.get_value(idx);
        const value = self.pop_value();
        const key = self.pop_value();
        self.set_table_internal(table, key, value);
    }

    fn set_table_internal(_: *LuaState, table: LuaValue, key: LuaValue, value: LuaValue) void {
        switch (table) {
            .LUA_TTABLE => |t| {
                t.put(key, value);
            },
            else => @panic("not a table"),
        }
    }

    pub fn set_field(self: *LuaState, idx: i32, key: []const u8) void {
        const table = self.stack.get_value(idx);
        const value = self.pop_value();
        self.set_table_internal(table, lua_value.lua_string(key), value);
    }

    pub fn set_index(self: *LuaState, idx: i32) void {
        const table = self.stack.get_value(idx);
        const value = self.pop_value();
        self.set_table_internal(table, lua_value.lua_integer(@as(i64, idx)), value);
    }

    /// 打印Lua栈内容
    pub fn print_stack(self: *LuaState) void {
        const top = self.get_top();
        var i: i32 = 1;
        while (i < top) : (i += 1) {
            const value_type = self.type_of(i);
            switch (value_type) {
                .LUA_TBOOLEAN => {
                    const b = self.to_bool(i);
                    std.debug.print("[{s}]", .{if (b) "true" else "false"});
                },
                .LUA_TINTEGER, .LUA_TNUMBER => {
                    const n = self.to_number(i);
                    std.debug.print("[{d}]", .{n});
                },
                .LUA_TSTRING => {
                    const s = self.to_string(i);
                    std.debug.print("[{s}]", .{s});
                },
                else => {
                    const local_type_name = self.type_name(value_type);
                    std.debug.print("[{s}]", .{local_type_name});
                },
            }
        }
        std.debug.print("\n", .{});
    }
};
