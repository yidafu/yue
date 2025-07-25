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

fn void LuaVm.execute(&self, Instruction i) {

  switch(i.op_code()) {
    case OP_MOVE: {
      self.op_move(i);
    }
    case OP_LOADK: {
      self.op_load_k(i);
    }
    case OP_LOADKX: {
      self.op_load_kx(i);
    }
    case OP_LOADBOOL: {
      self.op_load_bool(i);
    }
    case OP_LOADNIL: {
      self.op_load_nil(i);
    }
    case OP_GETUPVAL: {
      unreachable("op code not support");
      // self.op_addition(i);
    }
    case OP_GETTABUP: {
      unreachable("op code not support");
    }
    case OP_GETTABLE: {
      unreachable("op code not support");
      
    }
    case OP_SETTABUP: {
      unreachable("op code not support");
      
    }
    case OP_SETUPVAL: {
      unreachable("op code not support");
      
    }
    case OP_SETTABLE: {
      unreachable("op code not support");

    }
    case OP_NEWTABLE: {
      unreachable("op code not support");
      
    }
    case OP_SELF: {
      unreachable("op code not support");
      
    }
    case OP_ADD: {
      self.op_addition(i);
    }
    case OP_SUB: {
      self.op_substract(i);
    }
    case OP_MUL: {
      self.op_multiple(i);
    }
    case OP_MOD: {
      self.op_modulo(i);
    }
    case OP_POW: {
      self.op_power(i);
    }
    case OP_DIV: {
      self.op_division(i);
    }
    case OP_IDIV: {
      self.op_idivision(i);
    }
    case OP_BAND: {
      self.op_binary_and(i);
    }
    case OP_BOR: {
      self.op_binary_or(i);
    }
    case OP_BXOR: {
      self.op_binary_xor(i);
    }
    case OP_SHL: {
      self.op_shift_left(i);
    }
    case OP_SHR: {
      self.op_shift_right(i);
    }
    case OP_UNM: {
      self.op_unary_unm(i);
    }
    case OP_BNOT: {
      self.op_unary_not(i);
    }
    case OP_NOT: {
      self.op_not(i);
    }
    case OP_LEN: {
      self.op_length(i);
    }
    case OP_CONCAT: {
      self.op_i_concat(i);
    }
    case OP_JMP: {
      self.op_jump(i);
    }
    case OP_EQ: {
      self.op_equal(i);
    }
    case OP_LT: {
      self.op_less_than(i);
    }
    case OP_LE: {
      self.op_less_equal(i);
    }
    case OP_TEST: {
      self.op_test(i);
    }
    case OP_TESTSET: {
      self.op_test_set(i);
    }
    case OP_CALL: {
      unreachable("op code not support");
      
    }
    case OP_TAILCALL: {
      unreachable("op code not support");
      
    }
    case OP_RETURN: {
      unreachable("op code not support");
      
    }
    case OP_FORLOOP: {
      self.op_for_loop(i);
    }
    case OP_FORPREP: {
      self.op_for_prep(i);
    }
    case OP_TFORCALL: {
      unreachable("op code not support");
    }
    case OP_TFORLOOP: {
      unreachable("op code not support");
    }
    case OP_SETLIST: {
      unreachable("op code not support");
      
    }
    case OP_CLOSURE: {
      unreachable("op code not support");
      
    }
    case OP_VARARG: {
      unreachable("op code not support");
      
    }
    case OP_EXTRAARG: {
      unreachable("op code not support");
      
    }
  }
}

fn LuaVm new_vm(usz size, Prototype proto) {
  LuaState state = state::new_state(size, proto);
  LuaVm vm = { state };
  return vm;
}

