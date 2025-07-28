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
