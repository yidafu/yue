const std = @import("std");

pub const convert_type_fail = error.ConvertTypeFail;

pub fn parse_integer(str: []const u8) !i64 {
    return std.fmt.parseInt(i64, str, 10);
}

pub fn parse_double(str: []const u8) !f64 {
    return std.fmt.parseFloat(f64, str);
}

pub fn double_to_long(value: f64) i64 {
    return @intFromFloat(value);
}

pub fn string_to_long(value: []const u8) !i64 {
    if (parse_integer(value)) |int_val| {
        return int_val;
    } else |_| {
        const double_val = try parse_double(value);
        return double_to_long(double_val);
    }
}

pub fn float_byte_to_integer(value: i32) i32 {
    return if (value < 8)
        value
    else {
        const shift_amount: u5 = @as(u5, @intCast((value >> 3) - 1));
        return ((value & 7) + 8) << shift_amount;
    };
}

/// 'eeeee xxx'
/// if (eeeee == 0) xxx else 1xxx * 2^(eeeee-1)
pub fn integer_to_float_byte(value: i32) i32 {
    var e: i32 = 0;
    var v = value;
    if (v < 8) {
        return v;
    }
    while (v >= (8 << 4)) {
        v = (v + 0xf) >> 4; // value = ceil(value /16)
        e += 4;
    }
    while (v >= (8 << 1)) {
        v = (v + 1) >> 1; // value = ceil(value /2)
        e += 1;
    }
    return ((e + 1) << 3) | (v - 8);
}

const testing = std.testing;

// 运行测试
test "float_byte_to_integer" {
    // 测试负数输入
    // try testing.expectEqual(@as(i32, -5), float_byte_to_integer(-5));
    // try testing.expectEqual(@as(i32, -100), float_byte_to_integer(-100));

    // 测试 eeeee = 0 的情况 (value < 8)
    try testing.expectEqual(@as(i32, 0), float_byte_to_integer(0));

    // 测试 eeeee != 0 的情况
    // 0b00001_000 -> ((0) + 8) << (1 - 1) = 8 << 0 = 8
    try testing.expectEqual(@as(i32, 8), float_byte_to_integer(8));
    // 0b00010_001 -> ((1) + 8) << (2 - 1) = 9 << 1 = 18
    try testing.expectEqual(@as(i32, 18), float_byte_to_integer(17));
    // 0b00100_111 -> ((7) + 8) << (4 - 1) = 15 << 3 = 120
    try testing.expectEqual(@as(i32, 120), float_byte_to_integer(39));
}

test "integer <==> float_byte" {
    // 测试 value < 8 的情况
    try testing.expectEqual(@as(i32, 0), integer_to_float_byte(0));
    try testing.expectEqual(@as(i32, 7), integer_to_float_byte(7));
    try testing.expectEqual(@as(i32, 7), float_byte_to_integer(7));

    // 测试 value >= 8 且 value < 16 的情况
    try testing.expectEqual(@as(i32, 8), integer_to_float_byte(8)); // 0b00001_000
    try testing.expectEqual(@as(i32, 8), float_byte_to_integer(8));

    try testing.expectEqual(@as(i32, 9), integer_to_float_byte(9)); // 0b00001_001

    try testing.expectEqual(@as(i32, 15), integer_to_float_byte(15)); // 0b00001_111
    try testing.expectEqual(@as(i32, 15), float_byte_to_integer(15)); // 0b00001_111

    // 测试 value >= 16 且 value < 32 的情况
    try testing.expectEqual(@as(i32, 16), integer_to_float_byte(16)); // 0b00010_000
    try testing.expectEqual(@as(i32, 16), float_byte_to_integer(16));

    try testing.expectEqual(@as(i32, 17), integer_to_float_byte(17)); // 0b00010_001

    try testing.expectEqual(@as(i32, 24), integer_to_float_byte(32)); // 0b00010_111
    try testing.expectEqual(@as(i32, 32), float_byte_to_integer(24));

    // 测试更大的值
    try testing.expectEqual(@as(i32, 32), integer_to_float_byte(64)); // 0b00101_000
    try testing.expectEqual(@as(i32, 64), float_byte_to_integer(32));
    try testing.expectEqual(@as(i32, 48), integer_to_float_byte(256)); // 0b01001_000
    try testing.expectEqual(@as(i32, 256), float_byte_to_integer(48));
}
