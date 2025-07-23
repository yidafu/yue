module vm;

import std::io;

alias Instruction = uint;

const int MAX_ARG_BX = (1 << 18) - 1;
const int MAX_ARG_SBX = MAX_ARG_BX >> 1;

fn OpCode Instruction.op_code(Instruction self) {
  char code_int = (char) (self & 0x3f);
  return OpCode.from_ordinal(code_int);
}


fn String Instruction.op_name(Instruction self) {
  return self.op_code().desc;
}

fn int[<3>] Instruction.a_b_c(self) {
  int a = (self >> 6 & 0xff);
  int c = (self >> 14 & 0x1ff);
  int b = (self >> 23 & 0x1ff);
  return {a, b, c};
}

fn int[<2>] Instruction.a_bx(self) {
  int a = self >> 6 & 0xff;
  int bx = self >> 14;
  // io::printfn("a -> %b bx -> %b",a, bx);

  return {a, bx};
}
fn int[<2>] Instruction.a_sbx(self) {
  int[<2>] a_bx = self.a_bx();
  // io::printfn("a -> %b sbx -> %b", a_bx[0], a_bx[1] - MAX_ARG_SBX);

  return {a_bx[0], a_bx[1] - MAX_ARG_SBX};
}
fn int Instruction.ax(self) {
  return self >> 6;
}