module vm;

import state;
import chunk;

struct LuaVm {
  inline LuaState state;
}


fn void LuaVm.add_pc(&self, int n) {
  self.pc += n;
}
fn Instruction LuaVm.patch(&self) {
  Instruction i = self.proto.codes[self.pc];
  self.pc ++;
  return i;
}

fn void LuaVm.get_constant(&self, int idx) {
  Constant c = self.proto.constants[idx];
  switch(c.tag) {
    case TagValue.NIL: self.push_nil();
    case TagValue.BOOL: self.push_bool(c.as_bool);
    case TagValue.INTEGER: self.push_integer(c.as_integer);
    case TagValue.NUMBER: self.push_number(c.as_number);
    case TagValue.SHORT_STR:
    case TagValue.LONG_STR:
     self.push_string(c.as_str);
  }
}

fn void LuaVm.get_rk(&self, int rk) {
  if (rk > 0xff) {
    self.get_constant(rk & 0xff);
  } else {
    self.push_value(rk + 1);
  }
}

