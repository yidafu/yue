module vm;

import std::io;

fn void LuaVm.move(&self, Instruction i) {
  int[<3>] abc = i.a_b_c();
  int a = abc[0] + 1;
  int b = abc[1] + 1;
  self.copy(b, a);
}