module state;

import std::collections::list;
import std::io;


// ======= push method =======
fn void LuaState.push_value(&self, int index) {
  LuaValue value = self.stack._get(index);
  self.stack.push(value);
}

fn void LuaState.push_nil(&self) {
  self.stack.push(lua_nil());
}

fn void LuaState.push_bool(&self, bool value) {
  self.stack.push(lua_bool(value));
}

fn void LuaState.push_integer(&self, long value) {
  self.stack.push(lua_integer(value));
}

fn void LuaState.push_number(&self, double value) {
  self.stack.push(lua_number(value));
}

fn void LuaState.push_string(&self, String value) {
  self.stack.push(lua_string(value));
}
// ======= push method =======
