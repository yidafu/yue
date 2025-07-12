module chunk;

import std::io;
import vm;

fn void Prototype.print(Prototype* self) {
  self.print_header();
  self.print_code();
  self.print_detail();
  foreach (proto : self.protos)
  {
    proto.print();
  }
}

fn void Prototype.print_header(Prototype* self) {
  String funcType = "main";
  if (self.lineDefined > 0) {
    funcType = "function";
  }
  String varvargFlag = "";
  if (self.isVararg) {
    varvargFlag = "+";
  }
  io::printfn(
    "%s <%s:%d,%d> (%d instructions)",
    funcType,
    self.source,
    self.lineDefined,
    self.lastLineDefined,
    self.codes.len,
  );

  io::printfn(
    "%d%s params, %d slots %d upvalues",
    self.numParams,
    varvargFlag,
    self.maxStackSize,
    self.upvalues.len,
  );
  io::printfn(
    "%d locals, %d constants, %d functions",
    self.locVars.len,
    self.constants.len,
    self.protos.len,
  );
}

fn void Prototype.print_code(Prototype* self) {
  foreach (index,code : self.codes) {
      DString line =  dstring::temp_with_capacity(64);
      if (self.lineInfo.len > 0) {
         line.appendf("%d", self.lineInfo[index]);
      } else {
        line.append("-");
      }
      OpCode op_code = code.op_code();
      io::printf("\t%d\t[%s]\t%8s\t", index + 1, line, op_code.desc);
      switch (op_code.mode) {
        case OpMode.IABC: {
          int[<3>] abc = code.a_b_c();
          io::printf("%d", abc[0]);
          if (op_code.arg_b_mode != OpArgMode.OP_ARG_N) {
            if (abc[1] > 0xff) {
              io::printf("  %d", -1 - abc[1] & 0xff);
            } else {
              io::printf("  %d", abc[1]);
            }
          }

           if (op_code.arg_c_mode != OpArgMode.OP_ARG_N) {
            if (abc[2] > 0xff) {
              io::printf("  %d", -1 - abc[2] & 0xff);
            } else {
              io::printf("  %d", abc[2]);
            }
          }
        }
        case OpMode.IA_BX: {
          int[<2>] a_bx = code.a_bx();
          io::printf("%d", a_bx[0]);
          if (op_code.arg_b_mode == OpArgMode.OP_ARG_K) {
            io::printf("  %d", -1 - a_bx[1]);
          } else if (op_code.arg_b_mode == OpArgMode.OP_ARG_U) {
            io::printf("  %d", a_bx[1]);
          }
        }
        case OpMode.IA_SBX: {
          int[<2>] a_sbx = code.a_sbx();
          io::printf("%d  %d", a_sbx[0], a_sbx[1]);
        }
        case OpMode.I_AX: {
          int ax = code.ax();
          io::printf("%d", -1 - ax);

        }
        default: {
          unreachable("unknow op mode");
        }
      }
      io::printfn("");
  }
}



fn void Prototype.print_detail(Prototype* self) {
  io::printfn("constants (%d):", self.constants.len);
  foreach(index, constant : self.constants) {
    io::printfn("\t%d\t%s", index + 1, constant.to_string());
  }
  io::printfn("locals (%d):", self.locVars.len);
  foreach(index, locVar : self.locVars) {
    io::printfn("\t%d\t%s\t%d\t%d", index, locVar.varName, locVar.startPc + 1, locVar.endPc + 1);
  }

  io::printfn("upvalues (%d):", self.upvalues.len);
  foreach(index, upvalue : self.upvalues) {
    io::printfn(
      "\t%d\t%s\t%d\t%d",
      index,
      self.upvalue_name(index),
      upvalue.instack,
      upvalue.index
    );
  }
}

fn String Prototype.upvalue_name(Prototype* self, usz index) {
  if (self.upvalueNames.len > 0) {
    return self.upvalueNames[index];
  }
  return "-";
}
fn String Constant.to_string(Constant* self) @private {
  switch(self.tag) {
    case TagValue.NIL: {
      return "nill";
    }
    case TagValue.BOOL: {
      if (self.as_bool) {
        return "true";
      } else {
        return "false";
      }
    }
    case TagValue.INTEGER: {
      DString str = dstring::temp();
      str.appendf("%d", self.as_integer);
      return str.tcopy_str();
    }
    case TagValue.NUMBER: {
      DString str = dstring::temp();
      str.appendf("%f", self.as_integer);
      return str.tcopy_str();
    }
    case TagValue.SHORT_STR: {
      return self.as_str;
    }
    case TagValue.LONG_STR: {
      return self.as_str;
    }
  }
}