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

fn void LuaVm.addition(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPADD);
}


fn void LuaVm.substract(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPSUB);
}

fn void LuaVm.multiple(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPMUL);
}

fn void LuaVm.modulo(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPMOD);
}


fn void LuaVm.power(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPPOW);
}

fn void LuaVm.division(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPDIV);
}

fn void LuaVm.idivision(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPIDIV);
}

fn void LuaVm.binary_and(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPBAND);
}

fn void LuaVm.binary_or(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPBOR);
}

fn void LuaVm.binary_xor(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPBXOR);
}

fn void LuaVm.shift_left(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPSHL);
}

fn void LuaVm.shift_right(&self, Instruction i) @inline {
    self.binary_arith(i, ArithOp.LUA_OPSHR);
}

fn void LuaVm.unary_unm(&self, Instruction i) @inline {
    self.unary_arith(i, ArithOp.LUA_OPUNM);
}

fn void LuaVm.unary_not(&self, Instruction i) @inline {
    self.unary_arith(i, ArithOp.LUA_OPBNOT);
}

fn void LuaVm.length(&self, Instruction i) @inline {
  int[<3>] abc = i.a_b_c();
  int a= abc[0] + 1;
  int b = abc[1] + 1;
  int c = abc[2] + 1;

  self.len(b);
  self.replace(a);
}


fn void LuaVm.i_concat(&self, Instruction i) @inline {
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

fn void LuaVm.equal(&self, Instruction i) @inline {
  self._compare(i, CompareOp.LUA_OPEQ);
}

fn void LuaVm.less_than(&self, Instruction i) @inline {
  self._compare(i, CompareOp.LUA_OPLT);
}

fn void LuaVm.less_equal(&self, Instruction i) @inline {
  self._compare(i, CompareOp.LUA_OPLE);
}