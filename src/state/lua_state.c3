module state;

import std::collections::list;
import std::io;
import chunk;

alias ListLuaValue =  List { LuaValue };


struct LuaState {
  ListLuaValue stack;
  Prototype proto;
  int pc;
}

fn LuaState new_state(usz size, Prototype proto) {
  ListLuaValue stack;
  stack.init(mem, size);
  LuaState state = { stack, proto, 0 };
  return state;
}

fn void LuaState.free(&self) {
  self.stack.free();
}
