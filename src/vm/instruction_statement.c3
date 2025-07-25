module vm;

import state;
import std::io;

fn void LuaVm.op_for_prep(&self, Instruction i) {
  int[<2>] res = i.a_sbx();
  int a = res[0] + 1;
  int sBx = res[1];
  self.push_value(a);
  self.push_value(a + 2);
  self.arith(ArithOp.LUA_OPSUB);
  self.replace(a);
  self.add_pc(sBx);
}

fn void LuaVm.op_for_loop(&self, Instruction i) {
  int[<2>] res = i.a_sbx();
  int a = res[0] + 1;
  int sBx = res[1];

  // io::printfn("for loop %d", a);
  // self.print_stack();
  self.push_value(a+2);
  self.push_value(a);
  self.arith(ArithOp.LUA_OPADD);
  self.replace(a);

  bool is_positive_step = self.to_number(a + 2).as_number >= 0;
  if ((is_positive_step && self.compare(a, a + 1, CompareOp.LUA_OPLE)) ||
    (!is_positive_step && self.compare(a + 1, a, CompareOp.LUA_OPLE))
  ) {
    self.add_pc(sBx);
    self.copy(a, a+3);
  }
}