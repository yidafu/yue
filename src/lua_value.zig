const std = @import("std");
const utils = @import("utils.zig");

pub const LuaValueType = enum {
    LUA_TNONE,
    LUA_TNIL,
    LUA_TBOOLEAN,
    LUA_TLIGHTUSERDATA,
    LUA_TNUMBER,
    LUA_TSTRING,
    LUA_TTABLE,
    LUA_TFUNCTION,
    LUA_TUSERDATA,
    LUA_TTHREAD,
    LUA_TINTEGER,

    pub fn description(self: LuaValueType) []const u8 {
        return switch (self) {
            .LUA_TNONE => "no value",
            .LUA_TNIL => "nil",
            .LUA_TBOOLEAN => "boolean",
            .LUA_TLIGHTUSERDATA => "light userdata",
            .LUA_TNUMBER => "number",
            .LUA_TSTRING => "string",
            .LUA_TTABLE => "table",
            .LUA_TFUNCTION => "function",
            .LUA_TUSERDATA => "userdata",
            .LUA_TTHREAD => "thread",
            .LUA_TINTEGER => "number",
        };
    }
};

pub const LuaValue = union(LuaValueType) {
    LUA_TNONE: void,
    LUA_TNIL: void,
    LUA_TBOOLEAN: bool,
    LUA_TLIGHTUSERDATA: *anyopaque,
    LUA_TNUMBER: f64,
    LUA_TSTRING: []const u8,
    LUA_TTABLE: *LuaTable,
    LUA_TFUNCTION: *LuaFunction,
    LUA_TUSERDATA: *anyopaque,
    LUA_TTHREAD: *LuaThread,
    LUA_TINTEGER: i64,

    /// 比较两个Lua值是否相等
    pub inline fn equal(self: LuaValue, b: LuaValue) bool {
        return switch (self) {
            .LUA_TNIL => b == .LUA_TNIL,
            .LUA_TBOOLEAN => |a_bool| b.LUA_TBOOLEAN == a_bool,
            .LUA_TSTRING => |a_str| std.mem.eql(u8, a_str, b.LUA_TSTRING),
            .LUA_TINTEGER => |a_int| switch (b) {
                .LUA_TINTEGER => b.LUA_TINTEGER == a_int,
                .LUA_TNUMBER => @as(f64, @floatFromInt(a_int)) == b.LUA_TNUMBER,
                else => false,
            },
            .LUA_TNUMBER => |a_num| switch (b) {
                .LUA_TINTEGER => a_num == @as(f64, @floatFromInt(b.LUA_TINTEGER)),
                .LUA_TNUMBER => a_num == b.LUA_TNUMBER,
                else => false,
            },
            else => {
                // TODO: 实现其他类型的比较
                return false;
            },
        };
    }

    pub fn less_than(self: LuaValue, other: LuaValue) bool {
        return switch (self) {
            .LUA_TSTRING => switch (other) {
                .LUA_TSTRING => std.mem.lessThan(u8, self.LUA_TSTRING, other.LUA_TSTRING),
                else => unreachable,
            },
            .LUA_TINTEGER => switch (other) {
                .LUA_TINTEGER => self.LUA_TINTEGER < other.LUA_TINTEGER,
                .LUA_TNUMBER => @as(f64, @floatFromInt(self.LUA_TINTEGER)) < other.LUA_TNUMBER,
                else => unreachable,
            },
            .LUA_TNUMBER => switch (other) {
                .LUA_TINTEGER => self.LUA_TNUMBER < @as(f64, @floatFromInt(other.LUA_TINTEGER)),
                .LUA_TNUMBER => self.LUA_TNUMBER < other.LUA_TNUMBER,
                else => unreachable,
            },
            else => unreachable,
        };
    }

    pub fn less_equal(self: LuaValue, other: LuaValue) bool {
        return switch (self) {
            .LUA_TSTRING => switch (other) {
                .LUA_TSTRING => std.mem.lessThan(u8, self.LUA_TSTRING, other.LUA_TSTRING) or std.mem.eql(u8, self.LUA_TSTRING, other.LUA_TSTRING),
                else => unreachable,
            },
            .LUA_TINTEGER => switch (other) {
                .LUA_TINTEGER => self.LUA_TINTEGER <= other.LUA_TINTEGER,
                .LUA_TNUMBER => @as(f64, @floatFromInt(self.LUA_TINTEGER)) <= other.LUA_TNUMBER,
                else => unreachable,
            },
            .LUA_TNUMBER => switch (other) {
                .LUA_TINTEGER => self.LUA_TNUMBER <= @as(f64, @floatFromInt(other.LUA_TINTEGER)),
                .LUA_TNUMBER => self.LUA_TNUMBER <= other.LUA_TNUMBER,
                else => unreachable,
            },
            else => unreachable,
        };
    }

    pub fn to_bool(self: LuaValue) bool {
        return switch (self) {
            .LUA_TNIL => false,
            .LUA_TBOOLEAN => self.LUA_TBOOLEAN,
            else => true,
        };
    }

    pub fn convert_to_double(self: LuaValue) !f64 {
        return switch (self) {
            .LUA_TNUMBER => self.LUA_TNUMBER,
            .LUA_TINTEGER => @as(f64, @floatFromInt(self.LUA_TINTEGER)),
            .LUA_TSTRING => try std.fmt.parseFloat(f64, self.LUA_TSTRING),
            else => error.TypeMismatch,
        };
    }

    pub fn convert_to_long(self: LuaValue) !i64 {
        return switch (self) {
            .LUA_TNUMBER => @as(i64, @intFromFloat(self.LUA_TNUMBER)),
            .LUA_TINTEGER => self.LUA_TINTEGER,
            .LUA_TSTRING => try utils.string_to_long(self.LUA_TSTRING),
            .LUA_TNIL => 0,
            else => error.TypeMismatch,
        };
    }
};

pub fn lua_nil() LuaValue {
    return .LUA_TNIL;
}

pub inline fn lua_bool(value: bool) LuaValue {
    return .{ .LUA_TBOOLEAN = value };
}

pub inline fn lua_integer(value: i64) LuaValue {
    return .{ .LUA_TINTEGER = value };
}

pub inline fn lua_number(value: f64) LuaValue {
    return .{ .LUA_TNUMBER = value };
}

pub inline fn lua_string(value: []const u8) LuaValue {
    return .{ .LUA_TSTRING = value };
}

// 其他类型定义（如LuaTable、LuaFunction、LuaThread）需要根据实际项目补充
const LuaTable = struct {};
const LuaFunction = struct {};
const LuaThread = struct {};
