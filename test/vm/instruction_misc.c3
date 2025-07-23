module vm;

import state;
import chunk;
import std::io;

fn LuaVm new_vm() {
  Prototype proto;
  LuaState state = state::new_state(32, proto);
  LuaVm vm = { state };
  return vm;
}

fn void test_instruction_move() @test {
  LuaVm vm = new_vm();
  defer vm.free();
	vm.push_number(1.0);
	vm.push_number(2.0);
	vm.push_number(3.0);
	vm.push_number(4.0);
	vm.push_number(5.0);
  Instruction move = 0x8000C0;

  LuaValue value1 = vm.to_number(-2);
  test::eq(value1.as_number, 4.0);
  // vm.print_stack();
  vm.move(move);
  // vm.print_stack();
  LuaValue value2 = vm.to_number(-2);
  test::eq(value2.as_number, 2.0);
}

fn void test_instruction_jump() @test {
  LuaVm vm = new_vm();
  defer vm.free();
  Instruction jump = 0x7FFF801E;
  vm.add_pc(1);
  vm.jump(jump);
  test::eq(vm.pc, 0);
}

fn void test_instruction_load_nil() @test {
  LuaVm vm = new_vm();
  defer vm.free();
  Instruction load_nil = 0x2000004;
  vm.set_top(5);
  vm.load_nil(load_nil);
 
  test::eq(vm.is_nil(1), true);
  test::eq(vm.is_nil(2), true);
  test::eq(vm.is_nil(3), true);
  test::eq(vm.is_nil(4), true);
  test::eq(vm.is_nil(5), true);

  Instruction load_bool = 0x800083;
  vm.load_bool(load_bool);
  test::eq(vm.is_bool(3), true);

}

fn void test_instruction_load_k() @test {
  LuaVm vm = new_vm();
  vm.proto = {
    "",
    0,
    0,

    0,
    0,
    0,

    {},
    // constants
    { chunk::const_int(1), chunk::const_int(2) , chunk::const_str("foo") },
    {},
    {},
    {},
    {},
    {},
  };
  defer vm.free();
  vm.set_top(6);
  vm.load_nil(0x4);
  vm.load_k(0x41);
  vm.load_k(0x4081);
  vm.load_k(0x40c1);
  vm.load_k(0x8101);

  test::eq(vm.to_integer(2).as_number, 1);
  test::eq(vm.to_integer(3).as_number, 2);
  test::eq(vm.to_integer(4).as_number, 2);

  test::eq(vm.to_string(5).as_str, "foo");
}
