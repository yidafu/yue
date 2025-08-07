const std = @import("std");
const debug = std.debug;
const lua_value = @import("lua_value.zig");
const LuaValue = lua_value.LuaValue;

const LuaHashContext = struct {
    pub fn hash(_: @This(), key: LuaValue) u64 {
        var hasher = std.hash.Wyhash.init(0);
        switch (key) {
            .LUA_TNIL => hasher.update(&.{@as(u8, 0)}),
            .LUA_TBOOLEAN => |b| hasher.update(&.{@as(u8, @intFromBool(b))}),
            .LUA_TINTEGER => |i| hasher.update(std.mem.asBytes(&i)),
            .LUA_TNUMBER => |n| hasher.update(std.mem.asBytes(&@as(u64, @bitCast(n)))),
            .LUA_TSTRING => |s| hasher.update(s),
            .LUA_TTABLE => |t| hasher.update(std.mem.asBytes(&@as(*anyopaque, @ptrCast(t)))),
            .LUA_TLIGHTUSERDATA => |p| hasher.update(std.mem.asBytes(&p)),
            .LUA_TFUNCTION => |f| hasher.update(std.mem.asBytes(&@as(*anyopaque, @ptrCast(f)))),
            .LUA_TUSERDATA => |u| hasher.update(std.mem.asBytes(&u)),
            .LUA_TTHREAD => |th| hasher.update(std.mem.asBytes(&@as(*anyopaque, @ptrCast(th)))),
            .LUA_TNONE => hasher.update(&.{@as(u8, 1)}),
        }
        return hasher.final();
    }

    pub fn eql(self: @This(), a: LuaValue, b: LuaValue) bool {
        _ = self;
        return a.equal(b);
    }
};

pub fn LuaValueHashMap() type {
    return std.HashMap(LuaValue, LuaValue, LuaHashContext, 80);
}

pub const LuaTable = struct {
    arr: std.ArrayList(LuaValue),
    map: LuaValueHashMap(),

    pub fn init(allocator: std.mem.Allocator, nArr: usize) !LuaTable {
        return LuaTable{
            .arr = try std.ArrayList(LuaValue).initCapacity(allocator, nArr),
            .map = LuaValueHashMap().init(allocator),
        };
    }

    pub fn get(self: *const LuaTable, key: LuaValue) LuaValue {
        const optional_key_int = key.float_to_int();
        if (optional_key_int) |key_int| {
            if (key_int > 0 and key_int <= self.arr.items.len) {
                // Lua arrays are 1-indexed
                const idx = std.math.cast(usize, key_int - 1) orelse unreachable;
                return self.get_item(idx);
            }
        }
        return self.map.get(key) orelse unreachable;
    }

    pub fn put(self: *LuaTable, key: LuaValue, value: LuaValue) void {
        if (key.is_nil()) {
            @panic("table index is nil");
        }
        // TODO: number is NaN

        const optional_key_int = key.float_to_int();
        if (optional_key_int) |key_int| {
            const arr_len = self.arr.items.len;

            if (key_int > 0 and key_int <= arr_len) {
                // Lua arrays are 1-indexed
                const idx = std.math.cast(usize, key_int - 1) orelse unreachable;
                // std.debug.assert(idx >= 0);
                self.set_item(idx, value);
                if (key_int == arr_len and value.is_nil()) {
                    // shrink array
                    self.shrink_array();
                }
                return;
            }
            if (key_int == arr_len + 1) {
                _ = self.map.remove(key);
                if (!value.is_nil()) {
                    self.arr.append(value) catch {
                        return;
                    };
                    //  expand array
                    self.expand_array();
                }
                return;
            }
        }
        if (value.is_nil()) {
            _ = self.map.remove(key);
        } else {
            self.map.put(key, value) catch unreachable;
        }
    }

    fn shrink_array(self: *LuaTable) void {
        const arr_len = self.len();
        var i = arr_len - 1;
        while (i >= 0) : (i -= 1) {
            if (self.get_item(i).is_nil()) {
                _ = self.arr.pop();
            } else {
                break;
            }
        }
    }

    fn expand_array(self: *LuaTable) void {
        const arr_len = self.len();
        var idx = arr_len + 1;
        while (true) : (idx += 1) {
            const lua_idx_int = lua_value.lua_integer(std.math.cast(i64, idx) orelse unreachable);
            if (self.map.contains(lua_idx_int)) {
                if (self.map.get(lua_idx_int)) |value| {
                    self.arr.append(value) catch unreachable;
                    _ = self.map.remove(lua_idx_int); // 从映射中删除
                }
            } else {
                break;
            }
        }
    }

    inline fn get_item(self: LuaTable, idx: usize) LuaValue {
        return self.arr.items[idx];
    }
    inline fn set_item(self: LuaTable, idx: usize, value: LuaValue) void {
        self.arr.items[idx] = value;
    }
    pub fn len(self: LuaTable) usize {
        return self.arr.items.len;
    }

    pub fn to_string(self: LuaTable, allocator: std.mem.Allocator) []u8 {
        var builder = std.ArrayList(u8).init(allocator);

        for (self.arr.items) |item| {
            builder.appendSlice(item.fmt_string(allocator)) catch unreachable;
            builder.append(',') catch unreachable;
            builder.append(' ') catch unreachable;
        }

        var iterator = self.map.iterator();

        while (iterator.next()) |entry| {
            const key = entry.key_ptr.*;
            const value = entry.value_ptr.*;
            builder.appendSlice(key.fmt_string(allocator)) catch unreachable;
            builder.append(':') catch unreachable;
            builder.appendSlice(value.fmt_string(allocator)) catch unreachable;

            builder.append(',') catch unreachable;
            builder.append(' ') catch unreachable;
        }

        return std.fmt.allocPrint(allocator, "table{{{s}}}", .{builder.toOwnedSlice() catch unreachable}) catch unreachable;
    }
};
