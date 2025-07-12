module reader;

import std::io;
import std::collections::list;
import chunk;

const String LUA_SIGNATURE = "\x1bLua";
// 5.3 => 5 * 16 + 3 = 0x53
// 0b0101_0011
// 前4位大版本，后4位小版本
const char LUAC_VERSION = 0x53;

const char LUAC_FORMAT = 0x0;

//                        "\x19\x93\x0d\x0a\x1a\x0a";
const String LUAC_DATA = { 0x19, 0x93, 0x0d, 0x0a, 0x1a, 0x0a};

const char CINT_SIZE = 4;
const char CSIZET_SIZE = 8;
const char INSTRUCTION_SIEZ = 4;
const char LUA_INTEGER_SIEZE = 8;
const char LUA_NUMBER_SIZE =8;

const long LUAC_INT = 22136; // 0x5678
const double LUAC_NUM = 370.5;


const char TAG_NIL = 0x00;
const char TAG_BOOLEAN = 0x01;
const char TAG_NUMBER = 0x03;
const char TAG_INTEGER = 0x13;
const char TAG_SHORT_STR = 0x04;
const char TAG_LONG_STR = 0x14;


alias ListConstant = List { Constant };
alias ListUpvalue = List { Upvalue };

struct Reader {
	char[] bytes;
}

fn char Reader.read_byte(Reader* self) {
	char byte = self.bytes[0];
  // io::printfn("read byte %02x -> %02x",byte, self.bytes[1]);
	self.bytes = self.bytes[1 ..];
  // io::printfn("----read byte %02x %02x %02x %02x",self.bytes[0], self.bytes[1], self.bytes[2], self.bytes[3]);
	return byte;
}

fn char[] Reader.read_bytes(Reader* self, usz len) {
	char[] bytes = self.bytes[0 : len];
	self.bytes = self.bytes[len ..];
	return bytes;
}

fn uint Reader.read_uint(Reader* self) {
  // io::printfn("read uint %02x %02x %02x %02x",self.bytes[0], self.bytes[1], self.bytes[2], self.bytes[3]);

  uint value = (uint)(
        (self.bytes[0]) |
        (self.bytes[1] << 8) |
        (self.bytes[2] << 16) |
        (self.bytes[3] << 24)
    );
	self.bytes = self.bytes[4..];
	return value;
}

fn ulong Reader.read_ulong(Reader* self) {
  ulong value = (ulong)(
       ((ulong)self.bytes[0]) |
      ((ulong)self.bytes[1] << 8) |
      ((ulong)self.bytes[2] << 16) |
      ((ulong)self.bytes[3] << 24) |
      ((ulong)self.bytes[4] << 32) |
      ((ulong)self.bytes[5] << 40) |
      ((ulong)self.bytes[6] << 48) |
      ((ulong)self.bytes[7] << 56)
    );
	self.bytes = self.bytes[8..];
	return value;
}

fn long Reader.read_lua_int64(Reader* self) {
  return (long) self.read_ulong();
}

fn double Reader.read_lua_number(Reader* self) {
  // FIXME: 未实现
  return bitcast(self.read_ulong(), double);
}

alias ListUint = List {uint};

fn uint[] Reader.read_code(Reader* self) {
  uint size = self.read_uint();
  // io::printfn("size %d", size);
  ListUint codes;
  for(int i = 0; i < size; i++) {
    codes.push(self.read_uint());
  }

  return ListUint.to_tarray(&codes);
}

fn String Reader.read_string(Reader* self) {
  ulong size = (ulong)self.read_byte();
  if (size == 0) {
    return "";
  }
  if (size == 0xFF) {
    size = self.read_ulong();
  }
  size = size - 1;

  char[] bytes = self.bytes[0 : size];
  // io::printfn("read string len %d, first char: %02X last char: %02X", size, bytes[0], bytes[size-1]);

  self.bytes = self.bytes[size..];

  return (String)bytes;
}

fn void Reader.check_header(Reader* self) {
  String signature = (String)self.read_bytes(4);
  if (signature != LUA_SIGNATURE) {
    unreachable("not a precompiled chuck!");
  }
  if (self.read_byte() != LUAC_VERSION) {
    unreachable("version mismatch!");
  }
  if (self.read_byte() != LUAC_FORMAT) {
    unreachable("format mismatch!");
  }
  if ((String)self.read_bytes(6) != LUAC_DATA) {
    unreachable("corrupted!");
  }
  if (self.read_byte()!= CINT_SIZE) {
    unreachable("int size mismatch!");
  }
  if (self.read_byte() != CSIZET_SIZE) {
    unreachable("sizet size mismatch!");
  }
  if (self.read_byte() != INSTRUCTION_SIEZ) {
    unreachable("instruction size mismatch!");
  }
  if (self.read_byte() != LUA_INTEGER_SIEZE) {
    unreachable("lua Integer size mismatch!");
  }
  if (self.read_byte() != LUA_NUMBER_SIZE) {
    unreachable("lua Number size mismatch!");
  }
  if (self.read_lua_int64() != LUAC_INT) {
    unreachable("endianness mismatch!");
  }
  if (self.read_lua_number() != LUAC_NUM) {
    unreachable("float format mismatch!");
  }
}

fn Header Reader.read_header(Reader* self) {
  self.check_header();

   Header header = {
    LUA_SIGNATURE,
    LUAC_VERSION,
    LUAC_FORMAT,
    LUAC_DATA,
    CINT_SIZE,
    CSIZET_SIZE,
    INSTRUCTION_SIEZ,
    LUA_INTEGER_SIEZE,
    LUA_NUMBER_SIZE,
    LUAC_INT,
    LUAC_NUM,
  };
  return header;
}
fn Constant Reader.read_constant(Reader* self) {
  char valueTag = self.read_byte();
  Constant constant;
  switch (valueTag)
  {
  case TAG_NIL: {
    constant.tag = TagValue.NIL;
  }
  case TAG_BOOLEAN: {
    constant.tag = TagValue.BOOL;
    constant.as_bool = self.read_byte() != 0;
  }
  case TAG_INTEGER: {
    constant.tag = TagValue.INTEGER;
    constant.as_integer = self.read_lua_int64();
  }
  case TAG_NUMBER: {
    constant.tag = TagValue.NUMBER;
    constant.as_number = self.read_lua_number();
  }
  case TAG_SHORT_STR: {
    constant.tag = TagValue.SHORT_STR;
    constant.as_str = self.read_string();
  }

  case TAG_LONG_STR: {
    constant.tag = TagValue.LONG_STR;
    constant.as_str = self.read_string();
  }
  default:
    unreachable("corrupted!");
  }

  return constant;
}
fn Constant[] Reader.read_constants(Reader* self) {
  ListConstant list;
  uint count = self.read_uint();
  for (int i = 0; i < count; i++) {
    list.push(self.read_constant());
  }
  return ListConstant.to_tarray(&list);
}

fn Upvalue[] Reader.read_upvalues(Reader* self) {
  uint size = self.read_uint();
  ListUpvalue list;
  for(int i = 0; i < size; i++) {
    list.push({
      self.read_byte(),
      self.read_byte(),
    });
  }
  return ListUpvalue.to_tarray(&list);
}
fn Prototype[] Reader.read_prototypes(Reader* self, String parentSource) {
  List { Prototype } protos;
  uint size = self.read_uint();
  for(int i = 0; i < size; i++) {
    protos.push(self.read_prototype(parentSource));
  }
  return List { Prototype }.to_tarray(&protos);
}

fn uint[] Reader.read_line_info(Reader* self) {
  uint size = self.read_uint();
  List{ uint } list;
  for(int i = 0; i < size; i++) {
    list.push(self.read_uint());
  }
  return List{ uint }.to_tarray(&list);
}

fn LocVar[] Reader.read_locvars(Reader* self) {
  uint size = self.read_uint();
  List{ LocVar } list;
  for(int i = 0; i < size; i++) {
    list.push({
      self.read_string(),
      self.read_uint(),
      self.read_uint(),
    });
  }
  return List{ LocVar }.to_tarray(&list);
}

fn String[] Reader.read_upvalue_names(Reader* self) {
  uint size = self.read_uint();
  List{ String } list;
  for(int i = 0; i < size; i++) {
    list.push(self.read_string());
  }
  return List{ String }.to_tarray(&list);
}

fn Prototype Reader.read_prototype(Reader* self, String parentSource) {
  String source = self.read_string();
  if (source == "") {
    source = parentSource;
  }
  Prototype proto = {
    source,
    self.read_uint(),
    self.read_uint(),

    self.read_byte(),
    self.read_byte(),
    self.read_byte(),

    self.read_code(),
    self.read_constants(),
    self.read_upvalues(),
    self.read_prototypes(source),
    self.read_line_info(),
    self.read_locvars(),
    self.read_upvalue_names(),
  };

  return proto;
}
fn BinaryChunk Reader.undump(Reader* self) {
  BinaryChunk chunk = {
    self.read_header(),
    self.read_byte(),// upvalue
    self.read_prototype("")
  };
  return chunk;
}


// macro Reader.@mapList(Reader* self, $Type; @body(list))
// {
//   uint size = self.read_uint();
//   List{ $Type } list;
//   for(int i = 0; i < size; i++) {
//     list.push(@body(list));
//   }
//   return List{ $Type }.to_tarray(&list);
// }


fn void read_uint_test() @test {
  char[] little_endian_bytes = {0x12, 0x34, 0x56, 0x78};
  Reader reader = { little_endian_bytes };
  test::eq(0x78563412, reader.read_uint());
}

fn void read_ulong_test() @test {
  char[] little_endian_bytes =  {0xEF, 0xCD, 0xAB, 0x89, 0x67, 0x45, 0x23, 0x01};
  Reader reader = { little_endian_bytes };
  test::eq(0x0123456789ABCDEF, reader.read_ulong());

  char[8] zero_bytes = { 0,0,0,0,0,0,0,0 };
  reader.bytes =  zero_bytes[..];
  test::eq(0x0, reader.read_ulong());


  char[8] lsb_bytes = { 0xff,0,0,0,0,0,0,0 };
  reader.bytes =  lsb_bytes[..];
  test::eq(0xff, reader.read_ulong());


  char[8] msb_bytes = { 0,0,0,0,0,0,0, 0xff };
  reader.bytes =  msb_bytes[..];
  test::eq(18374686479671623680, reader.read_ulong());


  char[8] pattern_bytes ={0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF};
  reader.bytes =  pattern_bytes[..];
  test::eq(0xEFCDAB8967452301, reader.read_ulong());

}

fn void read_lua_number_test() @test {
  char[] number_bytes = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x28, 0x77, 0x40};

  Reader reader = { number_bytes };

  test::eq(370.5, reader.read_lua_number());
}