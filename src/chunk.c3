module chunk;

enum TagValue : char {
  NIL,
  BOOL,
  INTEGER,
  NUMBER,
  SHORT_STR,
  LONG_STR,
}

struct BinaryChunk {
  Header header;
  char sizeUpvalues;
  Prototype mainFunc;
}


struct Header {
  String signature;
  char version;
  char format;
  String luacDate;
  char cintSize;
  char sizetSize;
  char instructionSize;
  char luaIntergerSize;
  char luaNumberSize;
  int luacInt;
  double luacNum;
}

struct Constant {
  TagValue tag;

  union {
    bool as_bool;
    long as_integer;
    double as_number;
    String as_str;
  }
}

struct Upvalue {
  char instack;
  char index;
}

struct LocVar {
  String varName;
  uint startPc;
  uint endPc;
}

struct Prototype {
  String source;
  usz lineDefined;
  usz lastLineDefined;
  char numParams;
  char isVararg;
  char maxStackSize;
  uint[] codes;
  Constant[] constants;
  Upvalue[] upvalues;
  Prototype[] protos;
  uint[] lineInfo;
  LocVar[] locVars;
  String[] upvalueNames;
}


fn Constant const_int(long value) {
  Constant int_value;
  int_value.tag = TagValue.INTEGER;
  int_value.as_integer = value;
  return int_value;
}

fn Constant const_str(String value) {
  Constant int_value;
  int_value.tag = TagValue.SHORT_STR;
  int_value.as_str = value;
  return int_value;
}

fn Constant const_nil() {
  Constant nil_value;
  nil_value.tag = TagValue.NIL;
  return nil_value;
}

