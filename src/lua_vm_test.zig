const std = @import("std");

const lua_vm = @import("lua_vm.zig");
const lua_state = @import("lua_state.zig");
const lua_value = @import("lua_value.zig");
const binary_chunk = @import("binary_chunk.zig");
const instruction = @import("instruction.zig");

const testing = std.testing;
const LuaState = lua_state.LuaState;
const Prototype = binary_chunk.Prototype;
const Constant = binary_chunk.Constant;
const LuaVm = lua_vm.LuaVm;
const Instruction = instruction.Instruction;

fn new_vm_test(constants: []Constant) LuaVm {
    const proto = Prototype{
        .source = "",
        .line_defined = 0,
        .last_line_defined = 0,
        .num_params = 0,
        .is_vararg = 0,
        .max_stack_size = 0,
        .codes = &[_]u32{},
        .constants = constants,
        .upvalues = &[_]binary_chunk.Upvalue{},
        .protos = &[_]Prototype{},
        .line_info = &[_]u32{},
        .loc_vars = &[_]binary_chunk.LocVar{},
        .upvalue_names = &[_][]const u8{},
    };
    const state = lua_state.LuaState.init(std.testing.allocator, 32, proto);
    return LuaVm{ .state = state };
}

test "instruction move" {
    var empty_constants = [_]Constant{};
    var vm = new_vm_test(empty_constants[0..]);
    defer vm.deinit(std.testing.allocator);

    // vm.set_top(5);
    vm.push_number(1.0);
    vm.push_number(2.0);
    vm.push_number(3.0);
    vm.push_number(4.0);
    vm.push_number(5.0);

    const move_instr: Instruction = 0x8000C0;

    const value1 = vm.to_number(-2);
    try std.testing.expectEqual(value1, 4.0);
    vm.op_move(move_instr);

    const value2 = vm.to_number(-2);
    try testing.expectEqual(value2, 2.0);
}

test "instruction jump" {
    var empty_constants = [_]Constant{};
    var vm = new_vm_test(empty_constants[0..]);
    defer vm.deinit(std.testing.allocator);

    const jump_instr: Instruction = 0x7FFF801E;
    vm.add_pc(1);
    vm.op_jump(jump_instr);

    try testing.expectEqual(vm.get_pc(), 0);
}

test "instruction load nil" {
    var empty_constants = [_]Constant{};
    var vm = new_vm_test(empty_constants[0..]);
    defer vm.deinit(std.testing.allocator);

    const load_nil_instr: Instruction = 0x2000004;
    vm.set_top(5);
    vm.op_load_nil(load_nil_instr);

    try testing.expect(vm.is_nil(1));
    try testing.expect(vm.is_nil(2));
    try testing.expect(vm.is_nil(3));
    try testing.expect(vm.is_nil(4));
    try testing.expect(vm.is_nil(5));
    const load_bool_instr: Instruction = 0x800083;
    vm.op_load_bool(load_bool_instr);
    try testing.expect(vm.is_bool(3));
    // vm.print_stack();
}

test "instruction load k" {
    var list = [_]Constant{ binary_chunk.const_int(1), binary_chunk.const_int(2), binary_chunk.const_str("foo") };
    var vm = new_vm_test(list[0..]);
    defer vm.deinit(std.testing.allocator);

    vm.set_top(6);
    const load_nil_instr: Instruction = 0x4;
    vm.op_load_nil(load_nil_instr);
    const load_k_instr1: Instruction = 0x41;
    vm.op_load_k(load_k_instr1);
    const load_k_instr2: Instruction = 0x4081;
    vm.op_load_k(load_k_instr2);
    const load_k_instr3: Instruction = 0x40c1;
    vm.op_load_k(load_k_instr3);
    const load_k_instr4: Instruction = 0x8101;
    vm.op_load_k(load_k_instr4);

    try testing.expectEqual(vm.to_integer(2), 1);
    try testing.expectEqual(vm.to_integer(3), 2);
    try testing.expectEqual(vm.to_integer(4), 2);
    try testing.expectEqualStrings(vm.to_string(5), "foo");
    std.debug.print("load k \n", .{});
}

test "instruction binary operator" {
    var list = [_]Constant{
        binary_chunk.const_int(100),
    };
    var vm = new_vm_test(list[0..]);
    defer vm.deinit(std.testing.allocator);
    vm.set_top(6);
    // vm.print_stack();

    const load_nil_instr: Instruction = 0x2000004;
    vm.op_load_nil(load_nil_instr);
    // vm.print_stack();

    const addition_instr: Instruction = 0xc0010d;
    vm.op_addition(addition_instr);
    // vm.print_stack();

    const value1 = vm.to_number(-2);
    try testing.expectEqual(value1, 100.0);
    // vm.print_stack();
}

test "instruction unary operator" {
    var list = [_]Constant{
        binary_chunk.const_int(1),
    };
    var vm = new_vm_test(list[0..]);
    defer vm.deinit(std.testing.allocator);

    vm.set_top(5);
    const load_k_instr: Instruction = 0x1;
    vm.op_load_k(load_k_instr);
    const unary_unm_instr: Instruction = 0x59;
    vm.op_unary_unm(unary_unm_instr);
    // vm.print_stack();

    const value1 = vm.to_number(1);
    try testing.expectEqual(value1, 1.0);
}

test "instruction length operator" {
    var list = [_]Constant{
        binary_chunk.const_str("foo"),
    };
    var vm = new_vm_test(list[0..]);
    defer vm.deinit(std.testing.allocator);

    vm.set_top(5);
    const load_k_instr: Instruction = 0x1;
    vm.op_load_k(load_k_instr);
    const length_instr: Instruction = 0x5c;
    vm.op_length(length_instr);
    // vm.print_stack();
    const value1 = vm.to_number(2);
    try testing.expectEqual(value1, 3.0);
}

test "instruction concat operator" {
    var list = [_]Constant{
        binary_chunk.const_str("foo"),
    };
    var vm = new_vm_test(list[0..]);
    defer vm.deinit(std.testing.allocator);

    vm.set_top(5);
    const load_k_instr: Instruction = 0x1;
    vm.op_load_k(load_k_instr);
    const move_instr1: Instruction = 0x40;
    vm.op_move(move_instr1);
    const move_instr2: Instruction = 0x80;
    vm.op_move(move_instr2);
    const iconcat_instr: Instruction = 0x80805d;
    vm.op_iconcat(iconcat_instr);

    const value1 = vm.to_string(2);
    // vm.print_stack();
    try testing.expectEqualStrings(value1, "foofoo");
}

test "instruction equal operator" {
    // .codes = &[_]u32{ 0x4, 0x40005f, 0x8000001e, 0x4043, 0x800043 },
    var list = [_]Constant{
        binary_chunk.const_str("foo"),
        binary_chunk.const_nil(),
    };
    var vm = new_vm_test(list[0..]);
    defer vm.deinit(std.testing.allocator);

    vm.set_top(5);
    const load_nil_instr: Instruction = 0x4;
    vm.op_load_nil(load_nil_instr);
    std.debug.print("pc 111 {d}\n", .{vm.get_pc()});
    const equal_instr1: Instruction = 0x40005f;
    vm.op_equal(equal_instr1);
    std.debug.print("pc 222 {d}\n", .{vm.get_pc()});
    try testing.expectEqual(vm.get_pc(), 0);
    const equal_instr2: Instruction = 0x40405f;
    vm.op_equal(equal_instr2);
    try testing.expectEqual(vm.state.pc, 1);
}

test "instruction not" {
    var empty_constants = [_]Constant{};
    var vm = new_vm_test(empty_constants[0..]);
    defer vm.deinit(std.testing.allocator);

    vm.set_top(5);
    const load_nil_instr: Instruction = 0x4;
    vm.op_load_nil(load_nil_instr);
    const not_instr: Instruction = 0x5b;
    vm.op_not(not_instr);
    // vm.print_stack();
    try testing.expect(vm.to_bool(2));
}

test "instruction testset" {
    var empty_constants = [_]Constant{};
    var vm = new_vm_test(empty_constants[0..]);
    defer vm.deinit(std.testing.allocator);

    vm.set_top(5);
    const load_nil_instr: Instruction = 0x1000004;
    vm.op_load_nil(load_nil_instr);
    const test_set_instr: Instruction = 0xa3;
    vm.op_test_set(test_set_instr);
    const jump_instr: Instruction = 0x8000001e;
    vm.op_jump(jump_instr);
    // vm.print_stack();
    try testing.expectEqual(vm.state.pc, 1);
}

test "instruction test" {
    var empty_constants = [_]Constant{};
    var vm = new_vm_test(empty_constants[0..]);
    defer vm.deinit(std.testing.allocator);

    vm.set_top(5);
    const load_nil_instr: Instruction = 0x800004;
    vm.op_load_nil(load_nil_instr);
    const test_instr: Instruction = 0x62;
    vm.op_test(test_instr);
    const jump_instr: Instruction = 0x8000001e;
    vm.op_jump(jump_instr);
    // vm.print_stack();
    try testing.expectEqual(vm.state.pc, 2);
}

test "instruction for" {
    var list = [_]Constant{
        binary_chunk.const_int(1),
        binary_chunk.const_int(100),
        binary_chunk.const_int(2),
    };
    var vm = new_vm_test(list[0..]);
    defer vm.deinit(std.testing.allocator);
    //  .loc_vars = &[_]binary_chunk.LocVar{
    //             lua_value.loc_var("j", 2, 9),
    //             lua_value.loc_var("(for index)", 5, 8),
    //             lua_value.loc_var("(for limit)", 5, 8),
    //             lua_value.loc_var("(for step)", 5, 8),
    //             lua_value.loc_var("i", 6, 7),
    //         },

    vm.set_top(5);
    const load_nil_instr: Instruction = 0x4;
    vm.op_load_nil(load_nil_instr);
    const load_k_instr1: Instruction = 0x41;
    vm.op_load_k(load_k_instr1);
    const load_k_instr2: Instruction = 0x4081;
    vm.op_load_k(load_k_instr2);
    const load_k_instr3: Instruction = 0x80c1;
    vm.op_load_k(load_k_instr3);
    // vm.print_stack();

    const for_prep_instr: Instruction = 0x80000068;
    vm.op_for_prep(for_prep_instr);
    const load_k_instr4: Instruction = 0x1;
    vm.op_load_k(load_k_instr4);
    const for_loop_instr: Instruction = 0x7fff4067;
    vm.op_for_loop(for_loop_instr);

    vm.op_load_k(load_k_instr4);
    vm.op_for_loop(for_loop_instr);

    // vm.print_stack();
    const value = vm.to_number(2);
    // vm.print_stack();
    try testing.expectEqual(value, 3.0);
}
