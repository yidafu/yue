const std = @import("std");

const OpCode = @import("op_code.zig").OpCode;
const OpMode = @import("op_code.zig").OpMode;
const OpArgMode = @import("op_code.zig").OpArgMode;
const instruction = @import("instruction.zig");

pub const TagValue = enum {
    NIL,
    BOOL,
    INTEGER,
    NUMBER,
    SHORT_STR,
    LONG_STR,
};

pub const BinaryChunk = struct {
    header: Header,
    size_upvalues: u8,
    main_func: Prototype,

    /// 释放二进制块占用的内存
    pub fn deinit(self: *BinaryChunk, allocator: std.mem.Allocator) void {
        self.main_func.deinit(allocator);
    }
};

pub const Header = struct {
    signature: []const u8,
    version: u8,
    format: u8,
    luac_date: []const u8,
    cint_size: u8,
    sizet_size: u8,
    instruction_size: u8,
    lua_integer_size: u8,
    lua_number_size: u8,
    luac_int: i32,
    luac_num: f64,
};

pub const Constant = union(TagValue) {
    NIL: void,
    BOOL: bool,
    INTEGER: i64,
    NUMBER: f64,
    SHORT_STR: []const u8,
    LONG_STR: []const u8,

    /// 释放常量占用的内存
    pub fn deinit(self: *Constant, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .SHORT_STR => |*s| allocator.free(s.*),
            .LONG_STR => |*s| allocator.free(s.*),
            else => {},
        }
    }
};

pub const Upvalue = struct {
    instack: u8,
    index: u8,
};

pub const LocVar = struct {
    var_name: []const u8,
    start_pc: u32,
    end_pc: u32,
};

pub const Prototype = struct {
    source: []const u8,
    line_defined: usize,
    last_line_defined: usize,
    num_params: u8,
    is_vararg: u8,
    max_stack_size: u8,
    codes: []u32,
    constants: []Constant,
    upvalues: []Upvalue,
    protos: []Prototype,
    line_info: []u32,
    loc_vars: []LocVar,
    upvalue_names: [][]const u8,

    /// 释放原型及其子原型占用的内存
    pub fn deinit(self: *Prototype, allocator: std.mem.Allocator) void {
        if (@sizeOf(Prototype) == 0) return;

        // 释放source: []const u8
        if (self.source.len > 0) {
            // std.debug.print("free source\n", .{});
            allocator.free(self.source);
        }

        // 释放codes: []u32
        if (self.codes.len > 0) {
            // std.debug.print("free codes\n", .{});
            allocator.free(self.codes);
        }

        // 释放constants: 先释放每个常量占用的内存，再释放数组
        if (self.constants.len > 0) {
            // std.debug.print("free constants\n", .{});
            // for (self.constants) |c| {
            //     allocator.free(c);
            // }
            // allocator.free(self.constants);
        }

        // 释放upvalues: []Upvalue
        if (self.upvalues.len > 0) {
            // std.debug.print("free upvalues\n", .{});
            allocator.free(self.upvalues);
        }

        // 递归释放protos
        if (self.protos.len > 0) {
            // std.debug.print("free protos {d}\n", .{self.protos.len});
            for (self.protos) |*p| {
                p.deinit(allocator);
            }
        }

        if (self.line_info.len > 0) {
            // std.debug.print("free line_info\n", .{});
            allocator.free(self.line_info);
        }

        // 释放loc_vars: 先释放每个变量名，再释放数组
        if (self.loc_vars.len > 0) {
            // std.debug.print("free loc_vars\n", .{});
            for (self.loc_vars) |*lv| {
                if (lv.var_name.len > 0) {
                    allocator.free(lv.var_name);
                }
            }
            // allocator.free(self.loc_vars);
        }

        // 释放upvalue_names: 先释放每个名称，再释放数组
        if (self.upvalue_names.len > 0) {
            // std.debug.print("free upvalue_names\n", .{});
            for (self.upvalue_names) |*name| {
                if (name.len > 0) {
                    allocator.free(name.*);
                }
            }
            // allocator.free(self.upvalue_names);
        }
    }

    /// 打印原型信息（包含嵌套函数）
    pub fn print(self: *const Prototype) void {
        self.print_header();
        self.print_code();
        self.print_detail();
        for (self.protos) |proto| {
            proto.print();
        }
    }

    /// 打印头部信息
    fn print_header(self: *const Prototype) void {
        const func_type = if (self.line_defined > 0) "function" else "main";
        const vararg_flag = if (self.is_vararg != 0) "+" else "";
        std.debug.print(
            "{s} <{s}:{d},{d}> ({d} instructions)\n",
            .{ func_type, self.source, self.line_defined, self.last_line_defined, self.codes.len },
        );
        std.debug.print(
            "{d}{s} params, {d} slots {d} upvalues\n",
            .{ self.num_params, vararg_flag, self.max_stack_size, self.upvalues.len },
        );
        std.debug.print(
            "{d} locals, {d} constants, {d} functions\n",
            .{ self.loc_vars.len, self.constants.len, self.protos.len },
        );
    }

    /// 打印字节码指令
    fn print_code(self: *const Prototype) void {
        for (self.codes, 0..) |code, index| {
            const line_info = if (self.line_info.len > 0) self.line_info[index] else 0;
            const op_code = @as(OpCode, @enumFromInt(@as(u8, @truncate(code))));
            std.debug.print("\t{d}\t[{d}]\t{s:8}\t", .{ index + 1, line_info, op_code.info().desc });
            switch (op_code.info().mode) {
                .IABC => {
                    const abc = instruction.a_b_c(code);
                    std.debug.print("{d}", .{abc[0]});
                    if (op_code.info().arg_b_mode != .OP_ARG_N) {
                        const b: i32 = if (@as(i32, abc[1]) > @as(i32, 0xff)) -(@as(i32, abc[1]) & @as(i32, 0xff)) else @as(i32, abc[1]);
                        std.debug.print("  {d}", .{b});
                    }
                    if (op_code.info().arg_c_mode != .OP_ARG_N) {
                        const c: i32 = if (@as(i32, abc[2]) > @as(i32, 0xff)) -(@as(i32, abc[2]) & @as(i32, 0xff)) else @as(i32, abc[2]);
                        std.debug.print("  {d}", .{c});
                    }
                },
                .IA_BX => {
                    const a_bx = instruction.a_bx(code);
                    std.debug.print("{d}", .{a_bx[0]});
                    if (op_code.info().arg_b_mode == .OP_ARG_K) {
                        std.debug.print("  {d}", .{-1 - a_bx[1]});
                    } else if (op_code.info().arg_b_mode == .OP_ARG_U) {
                        std.debug.print("  {d}", .{a_bx[1]});
                    }
                },
                .IA_SBX => {
                    const a_sbx = instruction.a_sbx(code);
                    std.debug.print("{d}  {d}", .{ a_sbx[0], a_sbx[1] });
                },
                .I_AX => {
                    const ax = instruction.ax(code);
                    std.debug.print("{d}", .{-1 - ax});
                },
            }
            std.debug.print("\t 0x{X}\n", .{code});
        }
    }

    /// 打印详细信息（常量、局部变量、upvalue）
    fn print_detail(self: *const Prototype) void {
        std.debug.print("constants ({d}):\n", .{self.constants.len});
        for (self.constants, 0..) |constant, index| {
            std.debug.print("\t{d}\t{s}\n", .{ index + 1, to_string(constant) });
        }
        std.debug.print("locals ({d}):\n", .{self.loc_vars.len});
        for (self.loc_vars, 0..) |loc, index| {
            std.debug.print("\t{d}\t{s}\t{d}\t{d}\n", .{ index, loc.var_name, loc.start_pc + 1, loc.end_pc + 1 });
        }
        std.debug.print("upvalues ({d}):\n", .{self.upvalues.len});
        for (self.upvalues, 0..) |upvalue, index| {
            const name = if (self.upvalue_names.len > 0) self.upvalue_names[index] else "-";
            std.debug.print("\t{d}\t{s}\t{d}\t{d}\n", .{ index, name, upvalue.instack, upvalue.index });
        }
    }
};

pub fn const_int(value: i64) Constant {
    return Constant{ .INTEGER = value };
}

pub fn const_str(value: []const u8) Constant {
    return Constant{ .SHORT_STR = value };
}

pub fn const_nil() Constant {
    return Constant{ .NIL = {} };
}

pub fn loc_var(name: []const u8, s: u32, e: u32) LocVar {
    return LocVar{ .var_name = name, .start_pc = s, .end_pc = e };
}

pub const LUA_SIGNATURE = "\x1bLua";
pub const LUAC_VERSION: u8 = 0x53;
pub const LUAC_FORMAT: u8 = 0x0;
pub const LUAC_DATA = "\x19\x93\x0d\x0a\x1a\x0a";
pub const CINT_SIZE: u8 = 4;
pub const CSIZET_SIZE: u8 = 8;
pub const INSTRUCTION_SIZE: u8 = 4;
pub const LUA_INTEGER_SIZE: u8 = 8;
pub const LUA_NUMBER_SIZE: u8 = 8;
pub const LUAC_INT: i64 = 22136;
pub const LUAC_NUM: f64 = 370.5;

pub const TAG_NIL: u8 = 0x00;
pub const TAG_BOOLEAN: u8 = 0x01;
pub const TAG_NUMBER: u8 = 0x03;
pub const TAG_INTEGER: u8 = 0x13;
pub const TAG_SHORT_STR: u8 = 0x04;
pub const TAG_LONG_STR: u8 = 0x14;

/// 从IABC模式指令中提取A、B、C参数
pub fn a_b_c(code: u32) [3]i32 {
    return [3]i32{
        @as(i32, @intCast((code >> 6) & 0xFF)), // A
        @as(i32, @intCast((code >> 23) & 0x1FF)), // B
        @as(i32, @intCast(code & 0x7FF)), // C
    };
}

pub const BinaryReader = struct {
    bytes: []const u8,

    pub fn read_byte(self: *BinaryReader) u8 {
        const byte = self.bytes[0];
        self.bytes = self.bytes[1..];
        return byte;
    }

    pub fn read_bytes(self: *BinaryReader, len: usize) []const u8 {
        const bytes = self.bytes[0..len];
        self.bytes = self.bytes[len..];
        return bytes;
    }

    pub fn read_uint(self: *BinaryReader) u32 {
        const bytes = self.read_bytes(4);
        return @as(u32, bytes[0]) |
            @as(u32, bytes[1]) << 8 |
            @as(u32, bytes[2]) << 16 |
            @as(u32, bytes[3]) << 24;
    }

    pub fn read_ulong(self: *BinaryReader) u64 {
        const bytes = self.read_bytes(8);
        return @as(u64, bytes[0]) |
            @as(u64, bytes[1]) << 8 |
            @as(u64, bytes[2]) << 16 |
            @as(u64, bytes[3]) << 24 |
            @as(u64, bytes[4]) << 32 |
            @as(u64, bytes[5]) << 40 |
            @as(u64, bytes[6]) << 48 |
            @as(u64, bytes[7]) << 56;
    }

    pub fn read_lua_int64(self: *BinaryReader) i64 {
        return @as(i64, @bitCast(self.read_ulong()));
    }

    pub fn read_lua_number(self: *BinaryReader) f64 {
        return @as(f64, @bitCast(self.read_ulong()));
    }

    pub fn read_code(self: *BinaryReader, allocator: std.mem.Allocator) ![]u32 {
        const size = self.read_uint();
        var codes = std.ArrayList(u32).init(allocator);
        defer codes.deinit();
        for (0..size) |_| {
            try codes.append(self.read_uint());
        }
        return codes.toOwnedSlice();
    }

    pub fn read_string(self: *BinaryReader, allocator: std.mem.Allocator) ![]const u8 {
        var size = self.read_byte();
        if (size == 0) return "";
        if (size == 0xFF) size = @as(u8, @truncate(self.read_ulong()));
        size -= 1;
        const bytes = self.read_bytes(size);
        return allocator.dupe(u8, bytes);
    }

    pub fn check_header(self: *BinaryReader) !void {
        const signature = self.read_bytes(4);
        if (!std.mem.eql(u8, signature, LUA_SIGNATURE)) return error.InvalidSignature;
        if (self.read_byte() != LUAC_VERSION) return error.VersionMismatch;
        if (self.read_byte() != LUAC_FORMAT) return error.FormatMismatch;
        if (!std.mem.eql(u8, self.read_bytes(6), LUAC_DATA)) return error.CorruptedData;
        if (self.read_byte() != CINT_SIZE) return error.IntSizeMismatch;
        if (self.read_byte() != CSIZET_SIZE) return error.SizeTSizeMismatch;
        if (self.read_byte() != INSTRUCTION_SIZE) return error.InstructionSizeMismatch;
        if (self.read_byte() != LUA_INTEGER_SIZE) return error.LuaIntegerSizeMismatch;
        if (self.read_byte() != LUA_NUMBER_SIZE) return error.LuaNumberSizeMismatch;
        if (self.read_lua_int64() != LUAC_INT) return error.EndiannessMismatch;
        if (self.read_lua_number() != LUAC_NUM) return error.FloatFormatMismatch;
    }

    pub fn read_header(self: *BinaryReader) Header {
        _ = self.check_header() catch unreachable;
        return .{
            .signature = LUA_SIGNATURE,
            .version = LUAC_VERSION,
            .format = LUAC_FORMAT,
            .luac_date = LUAC_DATA,
            .cint_size = CINT_SIZE,
            .sizet_size = CSIZET_SIZE,
            .instruction_size = INSTRUCTION_SIZE,
            .lua_integer_size = LUA_INTEGER_SIZE,
            .lua_number_size = LUA_NUMBER_SIZE,
            .luac_int = LUAC_INT,
            .luac_num = LUAC_NUM,
        };
    }

    pub fn read_constant(self: *BinaryReader, allocator: std.mem.Allocator) !Constant {
        const tag = self.read_byte();
        return switch (tag) {
            TAG_NIL => .NIL,
            TAG_BOOLEAN => .{ .BOOL = self.read_byte() != 0 },
            TAG_INTEGER => .{ .INTEGER = self.read_lua_int64() },
            TAG_NUMBER => .{ .NUMBER = self.read_lua_number() },
            TAG_SHORT_STR => .{ .SHORT_STR = try self.read_string(allocator) },
            TAG_LONG_STR => .{ .LONG_STR = try self.read_string(allocator) },
            else => error.InvalidTag,
        };
    }

    pub fn read_constants(self: *BinaryReader, allocator: std.mem.Allocator) ![]Constant {
        const count = self.read_uint();
        var list = std.ArrayList(Constant).init(allocator);
        defer list.deinit();
        for (0..count) |_| {
            try list.append(try self.read_constant(allocator));
        }
        return list.toOwnedSlice();
    }

    pub fn read_upvalues(self: *BinaryReader, allocator: std.mem.Allocator) ![]Upvalue {
        const size = self.read_uint();
        var list = std.ArrayList(Upvalue).init(allocator);
        defer list.deinit();
        for (0..size) |_| {
            try list.append(.{
                .instack = self.read_byte(),
                .index = self.read_byte(),
            });
        }
        return list.toOwnedSlice();
    }

    pub fn read_protos(self: *BinaryReader, allocator: std.mem.Allocator, parentSource: []const u8) ![]Prototype {
        const size = self.read_uint();
        var protos = std.ArrayList(Prototype).init(allocator);
        defer protos.deinit();
        for (0..size) |_| {
            try protos.append(try self.read_prototype(allocator, parentSource));
        }
        return protos.toOwnedSlice();
    }

    pub fn read_line_info(self: *BinaryReader, allocator: std.mem.Allocator) ![]u32 {
        const size = self.read_uint();
        var list = std.ArrayList(u32).init(allocator);
        defer list.deinit();
        for (0..size) |_| {
            try list.append(self.read_uint());
        }
        return list.toOwnedSlice();
    }

    pub fn read_loc_vars(self: *BinaryReader, allocator: std.mem.Allocator) ![]LocVar {
        const size = self.read_uint();
        var list = std.ArrayList(LocVar).init(allocator);
        defer list.deinit();
        for (0..size) |_| {
            try list.append(.{
                .var_name = try self.read_string(allocator),
                .start_pc = self.read_uint(),
                .end_pc = self.read_uint(),
            });
        }
        return list.toOwnedSlice();
    }

    pub fn read_upvalue_names(self: *BinaryReader, allocator: std.mem.Allocator) ![][]const u8 {
        const size = self.read_uint();
        var list = std.ArrayList([]const u8).init(allocator);
        defer list.deinit();
        for (0..size) |_| {
            try list.append(try self.read_string(allocator));
        }
        return list.toOwnedSlice();
    }

    pub fn read_prototype(self: *BinaryReader, allocator: std.mem.Allocator, parentSource: []const u8) anyerror!Prototype {
        var source = try self.read_string(allocator);
        if (source.len == 0) source = parentSource;
        return .{
            .source = source,
            .line_defined = self.read_uint(),
            .last_line_defined = self.read_uint(),
            .num_params = self.read_byte(),
            .is_vararg = self.read_byte(),
            .max_stack_size = self.read_byte(),
            .codes = try self.read_code(allocator),
            .constants = try self.read_constants(allocator),
            .upvalues = try self.read_upvalues(allocator),
            .protos = try self.read_protos(allocator, source),
            .line_info = try self.read_line_info(allocator),
            .loc_vars = try self.read_loc_vars(allocator),
            .upvalue_names = try self.read_upvalue_names(allocator),
        };
    }

    pub fn undump(self: *BinaryReader, allocator: std.mem.Allocator) !BinaryChunk {
        return .{
            .header = self.read_header(),
            .size_upvalues = self.read_byte(),
            .main_func = try self.read_prototype(allocator, ""),
        };
    }
};

/// 常量转字符串辅助函数
pub fn to_string(constant: Constant) []const u8 {
    return switch (constant) {
        .NIL => "nil",
        .BOOL => |b| if (b) "true" else "false",
        .INTEGER => |i| std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{i}) catch "",
        .NUMBER => |n| std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{n}) catch "",
        .SHORT_STR => |s| s,
        .LONG_STR => |s| s,
    };
}

// 测试函数
const testing = std.testing;

// 内存泄漏测试
var leak_test_allocator = std.testing.allocator;

test "read_uint" {
    var reader = BinaryReader{ .bytes = &.{ 0x12, 0x34, 0x56, 0x78 } };
    try testing.expectEqual(@as(u32, 0x78563412), reader.read_uint());
}

test "read_ulong" {
    var reader = BinaryReader{ .bytes = &.{ 0xEF, 0xCD, 0xAB, 0x89, 0x67, 0x45, 0x23, 0x01 } };
    try testing.expectEqual(@as(u64, 0x0123456789ABCDEF), reader.read_ulong());

    reader = BinaryReader{ .bytes = ([_]u8{0} ** 8)[0..] };
    try testing.expectEqual(@as(u64, 0), reader.read_ulong());

    reader = BinaryReader{ .bytes = ([_]u8{0xFF})[0..] ++ ([_]u8{0} ** 7)[0..] };
    try testing.expectEqual(@as(u64, 0xFF), reader.read_ulong());

    reader = BinaryReader{ .bytes = ([_]u8{0} ** 7)[0..] ++ ([_]u8{0xFF})[0..] };
    try testing.expectEqual(@as(u64, 0xFF00000000000000), reader.read_ulong());

    reader = BinaryReader{ .bytes = &.{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF } };
    try testing.expectEqual(@as(u64, 0xEFCDAB8967452301), reader.read_ulong());
}

test "read_lua_number" {
    var reader = BinaryReader{ .bytes = &.{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x28, 0x77, 0x40 } };
    try testing.expectEqual(@as(f64, 370.5), reader.read_lua_number());
}
