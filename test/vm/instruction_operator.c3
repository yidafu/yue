module vm;

import chunk;
import state;

fn void test_instruction_binary_operator() @test {
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
    { chunk::const_int(100), },
    {},
    {},
    {},
    {},
    {},
  };
  defer vm.free();
  vm.set_top(6);
  vm.op_load_nil(0x2000004);
  vm.op_addition(0xc0010d);
  LuaValue value1 = vm.to_number(-2);
  test::eq(value1.as_number, 100);
}

fn void test_instruction_unary_operator() @test {
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
    { chunk::const_int(1), },
    {},
    {},
    {},
    {},
    {},
  };
  defer vm.free();
  vm.set_top(5);
  vm.op_load_k(0x1);
  vm.op_unary_unm(0x59);
  vm.print_stack();

  LuaValue value1 = vm.to_number(1);
  test::eq(value1.as_number, 1.0);
}


fn void test_instruction_length_operator() @test {
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
    { chunk::const_str("foo"), },
    {},
    {},
    {},
    {},
    {},
  };
  defer vm.free();
  vm.set_top(5);
  vm.op_load_k(0x1);
  vm.op_length(0x5c);
  vm.print_stack();
  LuaValue value1 = vm.to_number(2);
  test::eq(value1.as_number, 3.0);
}

fn void test_instruction_concat_operator() @test {
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
    { chunk::const_str("foo"), },
    {},
    {},
    {},
    {},
    {},
  };
  defer vm.free();
  vm.set_top(5);
  vm.op_load_k(0x1);
  vm.op_move(0x40);
  vm.op_move(0x80);
  vm.op_i_concat(0x80805d);

  LuaValue value1 = vm.to_string(2);
  test::eq(value1.as_str, "foofoo");
}


fn void test_instruction_equal_operator() @test {
  LuaVm vm = new_vm_test();
  vm.proto = {
    "",
    0,
    0,

    0,
    0,
    0,
    {0x4, 0x40005f, 0x8000001e, 0x4043, 0x800043},
    // constants
    { chunk::const_str("foo"), chunk::const_nil(), },
    {},
    {},
    {},
    {},
    {},
  };
  defer vm.free();
  vm.set_top(5);
  vm.op_load_nil(0x4);
  vm.op_equal(0x40005f);
  test::eq(vm.pc, 0);
  vm.op_equal(0x40405f);
  test::eq(vm.pc, 1);
}


fn void test_instruction_not() @test {
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
    {},
    {},
    {},
    {},
    {},
    {},
  };
  defer vm.free();
  vm.set_top(5);
  vm.op_load_nil(0x4);
  vm.op_not(0x5b);
  vm.print_stack();
  test::eq(vm.to_bool(2).as_bool, true);
}



fn void test_instruction_testset() @test {
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
    {},
    {},
    {},
    {},
    {},
    {},
  };
  defer vm.free();
  vm.set_top(5);
  vm.op_load_nil(0x1000004);
  vm.op_test_set(0xa3);
  vm.op_jump(0x8000001e);
  // vm.move(0x800080);
  vm.print_stack();
  test::eq(vm.pc, 1);
}


fn void test_instruction_test() @test {
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
    {},
    {},
    {},
    {},
    {},
    {},
  };
  defer vm.free();
  vm.set_top(5);
  vm.op_load_nil(0x800004);
  vm.op_test(0x62);
  vm.op_jump(0x8000001e);
  // vm.move(0x40);
  vm.print_stack();
  test::eq(vm.pc, 2);
}