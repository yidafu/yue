const std = @import("std");
const chunk = @import("binary_chunk.zig");
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len < 2) {
        std.log.err("Error: please provide a luac file path", .{});
        return error.MissingArgument;
    }
    const luac_file = args[1];

    const content = try std.fs.cwd().readFileAlloc(allocator, luac_file, std.math.maxInt(usize));
    defer allocator.free(content);
    var reader = chunk.BinaryReader{ .bytes = content };
    var chunk_data = try reader.undump(allocator);
    defer chunk_data.deinit(allocator);
    chunk_data.main_func.print();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
