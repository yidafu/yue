const std = @import("std");
const binary_chunk = @import("binary_chunk.zig");
const lua_vm = @import("lua_vm.zig");
const instruction = @import("instruction.zig");
const OpCode = @import("op_code.zig").OpCode;
const Instruction = instruction.Instruction;
const LuaVm = lua_vm.LuaVm;

fn lua_main(proto: binary_chunk.Prototype, allocator: std.mem.Allocator) !void {
    const regs = @as(usize, @intCast(proto.max_stack_size));
    var vm = LuaVm.init(allocator, regs + 8, proto);
    defer vm.deinit(allocator);
    vm.set_top(@as(i32, @intCast(regs)));

    while (true) {
        const pc = vm.get_pc();
        const instr: Instruction = vm.patch();
        const op_code = instruction.op_code(instr);
        if (op_code != OpCode.OP_RETURN) {
            std.debug.print("[{d}] {s}\n", .{ pc + 1, op_code.info().desc });
            vm.execute(instr);
            vm.print_stack();
            std.debug.print("\n", .{});
        } else {
            break;
        }
    }
}

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
    var reader = binary_chunk.BinaryReader{ .bytes = content };
    var chunk_data = try reader.undump(allocator);
    defer chunk_data.deinit(allocator);
    chunk_data.main_func.print();

    try lua_main(chunk_data.main_func, allocator);
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
