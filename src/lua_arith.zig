const std = @import("std");
const LuaValue = @import("lua_value.zig").LuaValue;

/// 算术操作枚举
pub const ArithOp = enum {
    LUA_OPADD,
    LUA_OPSUB,
    LUA_OPMUL,
    LUA_OPMOD,
    LUA_OPPOW,
    LUA_OPDIV,
    LUA_OPIDIV,
    LUA_OPBAND,
    LUA_OPBOR,
    LUA_OPBXOR,
    LUA_OPSHL,
    LUA_OPSHR,
    LUA_OPUNM,
    LUA_OPBNOT,
};

/// 比较操作枚举
pub const CompareOp = enum {
    LUA_OPEQ,
    LUA_OPLT,
    LUA_OPLE,
};

/// 长整型二元操作函数类型
const LongBinaryOperator = *const fn (i64, i64) i64;
/// 双精度浮点型二元操作函数类型
const DoubleBinaryOperator = *const fn (f64, f64) f64;

/// 二元操作符结构体
const BinaryOperator = struct {
    long_fn: ?LongBinaryOperator = null,
    double_fn: ?DoubleBinaryOperator = null,
};

// 具体操作函数实现
fn add_long(a: i64, b: i64) i64 {
    return a + b;
}
fn add_double(a: f64, b: f64) f64 {
    return a + b;
}
fn sub_long(a: i64, b: i64) i64 {
    return a - b;
}
fn sub_double(a: f64, b: f64) f64 {
    return a - b;
}
fn mul_long(a: i64, b: i64) i64 {
    return a * b;
}
fn mul_double(a: f64, b: f64) f64 {
    return a * b;
}
fn mod_long(a: i64, b: i64) i64 {
    return @mod(a, b);
}
fn mod_double(a: f64, b: f64) f64 {
    return @mod(a, b);
}
fn pow_double(a: f64, b: f64) f64 {
    return std.math.pow(f64, a, b);
}
fn div_long(a: i64, b: i64) i64 {
    return @divTrunc(a, b);
}
fn div_double(a: f64, b: f64) f64 {
    return a / b;
}
fn idiv_long(a: i64, b: i64) i64 {
    return @divTrunc(a, b);
}
fn idiv_double(a: f64, b: f64) f64 {
    return @floor(a / b);
}
fn band_long(a: i64, b: i64) i64 {
    return a & b;
}
fn bor_long(a: i64, b: i64) i64 {
    return a | b;
}
fn bxor_long(a: i64, b: i64) i64 {
    return a ^ b;
}
fn shl_long(a: i64, b: i64) i64 {
    return a << @as(u6, @intCast(b));
}
fn shr_long(a: i64, b: i64) i64 {
    return a >> @as(u6, @intCast(b));
}
fn unm_long(a: i64, _: i64) i64 {
    return -a;
}
fn unm_double(a: f64, _: f64) f64 {
    return -a;
}
fn bnot_long(a: i64, _: i64) i64 {
    return ~a;
}

/// 操作符映射表 (使用 initFullWith 静态初始化)
pub const operator_map = std.EnumMap(ArithOp, BinaryOperator).init(.{
    .LUA_OPADD = .{ .long_fn = add_long, .double_fn = add_double },
    .LUA_OPSUB = .{ .long_fn = sub_long, .double_fn = sub_double },
    .LUA_OPMUL = .{ .long_fn = mul_long, .double_fn = mul_double },
    .LUA_OPMOD = .{ .long_fn = mod_long, .double_fn = mod_double },
    .LUA_OPPOW = .{ .double_fn = pow_double },
    .LUA_OPDIV = .{ .long_fn = div_long, .double_fn = div_double },
    .LUA_OPIDIV = .{ .long_fn = idiv_long, .double_fn = idiv_double },
    .LUA_OPBAND = .{ .long_fn = band_long, .double_fn = null },
    .LUA_OPBOR = .{ .long_fn = bor_long, .double_fn = null },
    .LUA_OPBXOR = .{ .long_fn = bxor_long, .double_fn = null },
    .LUA_OPSHL = .{ .long_fn = shl_long, .double_fn = null },
    .LUA_OPSHR = .{ .long_fn = shr_long, .double_fn = null },
    .LUA_OPUNM = .{ .long_fn = unm_long, .double_fn = unm_double },
    .LUA_OPBNOT = .{ .long_fn = bnot_long, .double_fn = null },
});

/// 内部算术计算函数
pub fn arith_fn(a: LuaValue, b: LuaValue, op: BinaryOperator) !LuaValue {
    if (op.double_fn == null) {
        // 位运算处理
        const x = a.convert_to_long() catch return error.InvalidOperator;
        const y = b.convert_to_long() catch return error.InvalidOperator;
        return .{ .LUA_TINTEGER = op.long_fn.?(x, y) };
    } else {
        // 数值运算处理
        if (op.long_fn != null) {
            if (a.convert_to_long() catch null) |x| {
                if (b.convert_to_long() catch null) |y| {
                    return .{ .LUA_TINTEGER = op.long_fn.?(x, y) };
                }
            }
        }
        if (op.double_fn != null) {
            const x = a.convert_to_double() catch return error.InvalidOperator;
            const y = b.convert_to_double() catch return error.InvalidOperator;
            return .{ .LUA_TNUMBER = op.double_fn.?(x, y) };
        }
    }
    return error.InvalidOperator;
}
