module vm;

import chunk;
import state;

fn void test_instruction_binary_operator() @test {
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
    { chunk::const_int(100), },
    {},
    {},
    {},
    {},
    {},
  };
  defer vm.free();
  vm.set_top(6);
  vm.load_nil(0x2000004);
  vm.addition(0xc0010d);
  LuaValue value1 = vm.to_number(-2);
  test::eq(value1.as_number, 100);
}

fn void test_instruction_unary_operator() @test {
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
    { chunk::const_int(1), },
    {},
    {},
    {},
    {},
    {},
  };
  defer vm.free();
  vm.set_top(5);
  vm.load_k(0x1);
  vm.unary_unm(0x59);
  vm.print_stack();

  LuaValue value1 = vm.to_number(1);
  test::eq(value1.as_number, 1.0);
}


fn void test_instruction_length_operator() @test {
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
    { chunk::const_str("foo"), },
    {},
    {},
    {},
    {},
    {},
  };
  defer vm.free();
  vm.set_top(5);
  vm.load_k(0x1);
  vm.length(0x5c);
  vm.print_stack();
  LuaValue value1 = vm.to_number(2);
  test::eq(value1.as_number, 3.0);
}

fn void test_instruction_concat_operator() @test {
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
    { chunk::const_str("foo"), },
    {},
    {},
    {},
    {},
    {},
  };
  defer vm.free();
  vm.set_top(5);
  vm.load_k(0x1);
  vm.move(0x40);
  vm.move(0x80);
  vm.i_concat(0x80805d);

  LuaValue value1 = vm.to_string(2);
  test::eq(value1.as_str, "foofoo");
}


fn void test_instruction_equal_operator() @test {
  LuaVm vm = new_vm();
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
  vm.load_nil(0x4);
  vm.equal(0x40005f);
  test::eq(vm.pc, 0);
  vm.equal(0x40405f);
  test::eq(vm.pc, 1);
}