module state;


import std::collections::list;
import std::io;
import chunk;





fn void lua_state_test() @test {
  Prototype proto;
	LuaState state = new_state(32, proto);
  defer state.free();
	state.push_bool(true);                state.print_stack();
	state.push_integer(10);               state.print_stack();
	state.push_nil();                     state.print_stack();
	state.push_string("hello");           state.print_stack();
	state.push_value(-4);                 state.print_stack();
	state.replace(3);                     state.print_stack();
	state.set_top(6);                     state.print_stack();
	state.remove(-3);                     state.print_stack();
	state.set_top(-5);                    state.print_stack();
}

fn void lua_state_arith_test() @test {
  Prototype proto;
	LuaState state = new_state(32, proto);
  defer state.free();
  state.push_integer(1);
  state.push_string("2.0");
  state.push_string("3.0");
  state.push_number(4.0);
  state.print_stack();

  
  state.arith(ArithOp.LUA_OPADD);               state.print_stack();
  state.arith(ArithOp.LUA_OPBNOT);              state.print_stack();
  state.len(2);                                 state.print_stack();
  state.concat(3);                              state.print_stack();
  state.push_bool(state.compare(1, 2, CompareOp.LUA_OPEQ));
  state.print_stack();
  test::eq(state.to_bool(-1).as_bool, false);
  test::eq(state.to_string(-2).as_str, "3-82.0");
  test::eq(state.to_bool(1).as_integer, 1);
}

