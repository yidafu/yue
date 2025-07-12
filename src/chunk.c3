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