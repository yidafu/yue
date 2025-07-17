module vm;

import state;
import chunk;

fn LuaVm new_vm() {
  Prototype proto;
  LuaState state = state::new_state(32, proto);
  LuaVm vm = { state };
  return vm;
}

fn void instruction_move_test() @test {
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