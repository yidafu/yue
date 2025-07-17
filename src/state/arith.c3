module state;

import std::collections::enummap;
import std::io;

enum ArithOp {
  LUA_OPADD,
  LUA_OPSUB,
  LUA_OPMUL,
  LUA_OPMOD,
  LUA_OPPOW,
  LUA_OPDIV,
  LUA_OPIDIV,
  LUA_OPBAND,
  LUA_OPBOR,
  LUA_OPBXOR,
  LUA_OPSHL,
  LUA_OPSHR,
  LUA_OPUNM,
  LUA_OPBNOT,  
}

enum CompareOp {
  LUA_OPEQ,
  LUA_OPLT,
  LUA_OPLE,
}

alias LongBinaryOperator = fn long(long, long);
alias DoubleBinaryOperator = fn double(double, double);

struct BinaryOperator {
  LongBinaryOperator long_fn;
  DoubleBinaryOperator double_fn;
}

alias OperatorMap = EnumMap {ArithOp, BinaryOperator};


OperatorMap operatorMap;
fn void init_map() @init {
  operatorMap[ArithOp.LUA_OPADD] = {
    fn (a, b) => a + b,
    fn (a, b) => a + b,
  };
  operatorMap[ArithOp.LUA_OPSUB] = {
    fn (a, b) => a - b,
    fn (a, b) => a - b,
  };
  operatorMap[ArithOp.LUA_OPMUL] = {
    fn (a, b) => a * b,
    fn (a, b) => a * b,
  };
  operatorMap[ArithOp.LUA_OPMOD] = {
    fn (a, b) => a % b,
    fn (a, b) => a % b,
  };
  operatorMap[ArithOp.LUA_OPPOW] = {
    null, // empty implement
    fn (a, b) => a.pow(b),
  };
  operatorMap[ArithOp.LUA_OPDIV] = {
    fn (a, b) => a / b,
    fn (a, b) => a / b,
  };
  operatorMap[ArithOp.LUA_OPIDIV] = {
    fn (a, b) => a / b,
    fn (a, b) => a / b,
  };

  operatorMap[ArithOp.LUA_OPBAND] = {
    fn (a, b) => a & b,
    null,
  };

  operatorMap[ArithOp.LUA_OPBOR] = {
    fn (a, b) => a | b,
    null,
  };
  operatorMap[ArithOp.LUA_OPBXOR] = {
    fn (a, b) => a ^ b,
    null,
  };
  operatorMap[ArithOp.LUA_OPSHL] = {
    fn (a, b) => a << b,
    null,
  };
  operatorMap[ArithOp.LUA_OPSHL] = {
    fn (a, b) => a >> b,
    null,
  };

  operatorMap[ArithOp.LUA_OPUNM] = {
    fn (a, b) => -a,
    fn (a, b) => -a,
  };

  operatorMap[ArithOp.LUA_OPBNOT] = {
    fn (a, b) => ~a,
    null,
  };
  
}


// ======= arith method =======
fn void LuaState.arith(&self, ArithOp operator) {
  LuaValue b = self.stack.pop()!!;
  LuaValue a;
  if (operator != ArithOp.LUA_OPPOW && operator != ArithOp.LUA_OPBNOT) {
    a =  self.stack.pop()!!;
  } else {
    a = b;
  }
  BinaryOperator op = operatorMap[operator];

  LuaValue? result = arith_fn(a, b, op);
  if (try result) {
    self.stack.push(result);
    return;
  }
  unreachable("arithmetic errror!");
}
fn bool LuaState.compare(&self,int idx1, int idx2, CompareOp operator) {
  LuaValue a = self.stack._get(idx1);
  LuaValue b = self.stack._get(idx2);
  switch(operator) {
    case CompareOp.LUA_OPEQ: return equal(a, b);
    case CompareOp.LUA_OPLT: return less_then(a, b);
    case CompareOp.LUA_OPLE: return less_equal(a, b);
    default: unreachable("invalid compare operator!");
  }
}
fn void LuaState.len(&self, int idx) {
  LuaValue a = self.stack._get(idx);
  switch(a.type) {
    case LuaValueType.LUA_TSTRING: {
      self.push_integer(a.as_str.len);
    }
    default: {
      unreachable("lenght error!");
    }
  }
}
fn void LuaState.concat(&self, int n) {
  if (n == 0) {
    self.push_string("");
  } else if (n >= 2) {
    for (int i = 1; i < n; i++) {
      if (self.is_string(-1) && self.is_string(-2)) {
        LuaValue s1 = self.to_string(-1);
        LuaValue s2 = self.to_string(-2);
        io::printfn("%s + %s", s1.as_str, s2.as_str);
        self.pop(2);
        self.push_string(s1.as_str.tconcat(s2.as_str));
        continue;
      }
      unreachable("concatenation error!");
    }
  }
}
// ======= arith method =======

fn LuaValue? arith_fn(LuaValue a, LuaValue b, BinaryOperator op) {

  if (op.double_fn == null) { // bitwise
    LuaValue? x = a.convert_to_long();
    LuaValue? y = b.convert_to_long();
    if (try x) {
      if (try y) {
        long result = op.long_fn(x.as_integer, y.as_integer);
        return lua_integer(result);
      }
    }
  } else {
    if (op.long_fn != null) {
        LuaValue? x = a.convert_to_long();
        LuaValue? y = b.convert_to_long();
        if (try x) {
          if (try y) {
            long result = op.long_fn(x.as_integer, y.as_integer);
            return lua_integer(result);
          }
        }
    }


    if (op.double_fn != null) {
      LuaValue? x = a.convert_to_double();
      LuaValue? y = b.convert_to_double();
      if (try x) {
        if (try y) {
          double result = op.double_fn(x.as_number, y.as_number);
          return lua_number(result);
        }
      }
    }
  }
  return INVLID_OPERATOR?;
}

fn bool equal(LuaValue a, LuaValue b) {
  switch(a.type) {
    case LuaValueType.LUA_TNIL: {
      return b.type == LuaValueType.LUA_TNIL;
    }
    case LuaValueType.LUA_TBOOLEAN: {
      return a.as_bool == b.as_bool;
    }
    case LuaValueType.LUA_TSTRING: {
      return a.as_str == b.as_str;
    }
    case LuaValueType.LUA_TINTEGER: {
      switch(b.type) {
        case LuaValueType.LUA_TINTEGER: return b.as_integer == a.as_integer;
        case LuaValueType.LUA_TNUMBER: return (double)a.as_integer == b.as_number;
        default: return false;
      }
    }
    case LuaValueType.LUA_TNUMBER: {
      switch(b.type) {
        case LuaValueType.LUA_TINTEGER: return a.as_number == (double)b.as_integer;
        case LuaValueType.LUA_TNUMBER: return a.as_number == b.as_number;
        default: return false;
      }
    }
    default: {
      // TODO: a==b;
      return false;
    }
  }
}

fn bool less_then(LuaValue a, LuaValue b) {
  switch(a.type) {
    case LuaValueType.LUA_TSTRING: {
      switch(b.type) {
        case LuaValueType.LUA_TSTRING: 
          return string_compare(a.as_str, a.as_str) < 0;
        default: {}
        // default: return false;
      }
    }
    case LuaValueType.LUA_TINTEGER: {
      switch(b.type) {
        case LuaValueType.LUA_TINTEGER: 
          return a.as_integer < b.as_integer;
        case LuaValueType.LUA_TNUMBER: 
          return (double)a.as_integer < b.as_number;
        default: {}
        // default: return false;
      }
    }
    case LuaValueType.LUA_TNUMBER: {
      switch(b.type) {
        case LuaValueType.LUA_TINTEGER: 
          return a.as_number < (double)b.as_integer;
        case LuaValueType.LUA_TNUMBER: 
          return a.as_number < b.as_number;
        default: {}
        // default: return false;
      }
    }
    default: {}
  }
  unreachable("comparision error!");
  // return false;
}
fn bool less_equal(LuaValue a, LuaValue b) {
 switch(a.type) {
    case LuaValueType.LUA_TSTRING: {
      switch(b.type) {
        case LuaValueType.LUA_TSTRING: 
          return string_compare(a.as_str, a.as_str) <= 0;
        default: {}
        // default: return false;
      }
    }
    case LuaValueType.LUA_TINTEGER: {
      switch(b.type) {
        case LuaValueType.LUA_TINTEGER: 
          return a.as_integer <= b.as_integer;
        case LuaValueType.LUA_TNUMBER: 
          return (double)a.as_integer <= b.as_number;
        default: {}
        // default: return false;
      }
    }
    case LuaValueType.LUA_TNUMBER: {
      switch(b.type) {
        case LuaValueType.LUA_TINTEGER: 
          return a.as_number <= (double)b.as_integer;
        case LuaValueType.LUA_TNUMBER: 
          return a.as_number <= b.as_number;
        default: {}
        // default: return false;
      }
    }
    default: {}
  }
  unreachable("comparision error!");
}
faultdef INVLID_OPERATOR;