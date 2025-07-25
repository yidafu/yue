module vm;

import std::io;

fn void LuaVm.op_move(&self, Instruction i) @inline {
  int[<3>] abc = i.a_b_c();
  int a = abc[0] + 1;
  int b = abc[1] + 1;
  self.copy(b, a);
}

fn void LuaVm.op_jump(&self, Instruction i) @inline {
  int[<2>] a_sbx = i.a_sbx();
  self.add_pc(a_sbx[1]);
  if (a_sbx[0] != 0) {
    unreachable("Todo!");
  }
}


fn void LuaVm.op_load_nil(&self, Instruction i) @inline {
  int[<3>] abc = i.a_b_c();
  int a= abc[0];
  int b = abc[1];
  int c = abc[2];
  a += 1;
  // io::printfn("load nil => a %d b %d c %d", a, b, c);
  self.push_nil();
  for(int j = a; j <= a + b; j++) {
    // self.print_stack();
    self.copy(-1, j);
  }
  self.pop(1);
}

fn void LuaVm.op_load_bool(&self, Instruction i) @inline {
  int[<3>] abc = i.a_b_c();
  int a= abc[0];
  int b = abc[1];
  int c = abc[2];
  a += 1;
  // io::printfn("a %d b %d c %d", a, b, c);
  self.push_bool(b != 0);
  self.replace(a);
  if (c != 0) {
    self.add_pc(1);
  }
}

fn void LuaVm.op_load_k(&self, Instruction i) @inline {
  int[<2>] a_bx = i.a_bx();
  int a = a_bx[0];
  int bx = a_bx[1];
  a+=1;
  // io::printfn("load k a %d bx %d", a, bx);
  self.get_constant(bx);
  // self.print_stack();
  self.replace(a);
}


fn void LuaVm.op_load_kx(&self, Instruction i) @inline {
  int[<2>] a_bx = i.a_bx();
  int a = a_bx[0];
  int bx = a_bx[1];

  int ax = self.patch().ax();
  self.get_constant(ax);
  self.replace(a);
}