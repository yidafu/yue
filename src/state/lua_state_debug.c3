module state;

import std::collections::list;
import std::io;
import chunk;



fn void LuaState.print_stack(&self) {
  usz top = self.get_top();
  for (int i = 1; i < top; i += 1)
  {
    // io::printf("{%d}", i);

    LuaValueType type = self.type(i);
    switch(type) {
      case LuaValueType.LUA_TBOOLEAN: {
        io::printf("[%s]", self.to_bool(i).as_bool);
      }
      case LuaValueType.LUA_TINTEGER:
      case LuaValueType.LUA_TNUMBER: {
        io::printf("[%f]", self.to_number(i).as_number);
      }
      case LuaValueType.LUA_TSTRING: {
        io::printf("[%s]", self.to_string(i).as_str);
      }
      default: {
        io::printf("[%s]", self.type_name(type));
      }
    }
  }
  io::printfn("");
}