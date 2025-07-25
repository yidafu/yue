module vm;

import chunk;

fn void test_instruction_for() @test {
  LuaVm vm = new_vm_test();
  vm.proto = {
    "",
    0,
    0,

    0,
    0,
    0,

    {},
    // constants
    { chunk::const_int(1), chunk::const_int(100) , chunk::const_int(2) },
    {},
    {},
    {},
    {
      chunk::loc_var("j", 2, 9),
      chunk::loc_var("(for index)", 5, 8),
      chunk::loc_var("(for limit)", 5, 8),
      chunk::loc_var("(for step)", 5, 8),
      chunk::loc_var("i", 6, 7),
    },
    {},
  };
  defer vm.free();
  vm.set_top(5);
  vm.op_load_nil(0x4);
  vm.op_load_k(0x41);
  vm.op_load_k(0x4081);
  vm.op_load_k(0x80c1);
  vm.print_stack();

  vm.op_for_prep(0x80000068);
  vm.op_load_k(0x1);
  vm.op_for_loop(0x7fff4067);

  vm.op_load_k(0x1);
  vm.op_for_loop(0x7fff4067);

  vm.print_stack();
  test::eq(vm.to_number(2).as_number, 3);
}

