module vm;

import std::io;
import state;

fn void LuaVm.binary_arith(&self,  Instruction i, ArithOp op) @inline @private {
  int[<3>] abc = i.a_b_c();
  int a= abc[0] + 1;
  int b = abc[1];
  int c = abc[2];

  // io::printfn("binary arith a %d b %d c %d", a, b, c);

  self.get_rk(b);
  self.get_rk(c);
  self.arith(op);
  self.replace(a);
}

fn void LuaVm.unary_arith(&self,  Instruction i, ArithOp op) @inline @private {
  int[<3>] abc = i.a_b_c();
  int a= abc[0] + 1;
  int b = abc[1] + 1;
  // int c = abc[2];

  // io::printfn("unary arith a %d b %d", a, b);

  self.push_value(b);
  self.arith(op);
  self.replace(a);
}

fn void LuaVm._compare(&self, Instruction i, CompareOp op) @inline @private {
  int[<3>] abc = i.a_b_c();
  int a= abc[0];
  int b = abc[1];
  int c = abc[2];

  self.get_rk(b);
  self.get_rk(c);
  if (self.compare(-2, -1, op)) {
    self.add_pc(1);
  }

  self.pop(2);
}

fn void LuaVm.op_addition(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPADD);
}


fn void LuaVm.op_substract(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPSUB);
}

fn void LuaVm.op_multiple(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPMUL);
}

fn void LuaVm.op_modulo(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPMOD);
}


fn void LuaVm.op_power(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPPOW);
}

fn void LuaVm.op_division(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPDIV);
}

fn void LuaVm.op_idivision(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPIDIV);
}

fn void LuaVm.op_binary_and(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPBAND);
}

fn void LuaVm.op_binary_or(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPBOR);
}

fn void LuaVm.op_binary_xor(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPBXOR);
}

fn void LuaVm.op_shift_left(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPSHL);
}

fn void LuaVm.op_shift_right(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPSHR);
}

fn void LuaVm.op_unary_unm(&self, Instruction i) @inline {
    self.unary_arith(i, ArithOp.LUA_OPUNM);
}

fn void LuaVm.op_unary_not(&self, Instruction i) @inline {
    self.unary_arith(i, ArithOp.LUA_OPBNOT);
}



fn void LuaVm.op_length(&self, Instruction i) @inline {
  int[<3>] abc = i.a_b_c();
  int a= abc[0] + 1;
  int b = abc[1] + 1;
  int c = abc[2] + 1;

  self.len(b);
  self.replace(a);
}

fn void LuaVm.op_i_concat(&self, Instruction i) @inline {
  int[<3>] abc = i.a_b_c();
  int a= abc[0] + 1;
  int b = abc[1] + 1;
  int c = abc[2] + 1;
  int n = c - b + 1;

  self.check_stack(n);

  for (int j = b; j <= c; j ++) {
    self.push_value(j);
  }

  self.concat(n);
  self.replace(a);
}

fn void LuaVm.op_equal(&self, Instruction i) @inline {
  self._compare(i, CompareOp.LUA_OPEQ);
}

fn void LuaVm.op_less_than(&self, Instruction i) @inline {
  self._compare(i, CompareOp.LUA_OPLT);
}

fn void LuaVm.op_less_equal(&self, Instruction i) @inline {
  self._compare(i, CompareOp.LUA_OPLE);
}

fn void LuaVm.op_not(&self, Instruction i) @inline {
  int[<3>] abc = i.a_b_c();
  int a= abc[0] + 1;
  int b = abc[1] + 1;
  // int c = abc[2] + 1;
  self.push_bool(!self.to_bool(b).as_bool);
  self.replace(a);
}

fn void LuaVm.op_test_set(&self, Instruction i) @inline {
  int[<3>] abc = i.a_b_c();
  int a= abc[0] + 1;
  int b = abc[1] + 1;
  int c = abc[2];
  if (self.to_bool(b).as_bool == (c !=0)) {
    self.copy(b, a);
  } else {
    self.add_pc(1);
  }
}


fn void LuaVm.op_test(&self, Instruction i) @inline {
  int[<3>] abc = i.a_b_c();
  int a= abc[0] + 1;
  int c = abc[2];
  if (self.to_bool(a).as_bool == (c !=0)) {
    self.add_pc(1);
  }
}