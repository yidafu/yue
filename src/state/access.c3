module state;

import std::collections::list;
import std::io;


// ======= access method =======
fn String LuaState.type_name(&self, LuaValueType luaType) {
  return luaType.desc;
}

fn LuaValueType LuaState.type(&self, int index) { 
  int abs_idx = self.stack.abs_index(index);
  if (self.stack.is_valid(abs_idx)) {
    LuaValue value = self.stack._get(abs_idx);
    return type_of(value);
  }
  return LuaValueType.LUA_TNONE;
}

fn bool LuaState.is_none(&self, int index) {
  return self.type(index) == LuaValueType.LUA_TNONE;
}

fn bool LuaState.is_nil(&self, int index) {
  return self.type(index) == LuaValueType.LUA_TNIL;
}

fn bool LuaState.is_none_or_nil(&self, int index) {
  LuaValueType type = self.type(index);
  return type == LuaValueType.LUA_TNIL || type == LuaValueType.LUA_TNONE;
}

fn bool LuaState.is_bool(&self, int index) {
  return self.type(index) == LuaValueType.LUA_TBOOLEAN;
}

fn bool LuaState.is_integer(&self, int index) {
  return self.type(index) == LuaValueType.LUA_TNUMBER;
}

fn bool LuaState.is_number(&self, int index) {
  LuaValueType type = self.type(index);
  return type == LuaValueType.LUA_TNUMBER || type == LuaValueType.LUA_TINTEGER;
}


fn bool LuaState.is_string(&self, int index) {
  LuaValueType type = self.type(index);
  return type == LuaValueType.LUA_TSTRING
    || type == LuaValueType.LUA_TNUMBER 
    || type == LuaValueType.LUA_TINTEGER;
}

fn LuaValue LuaState.to_bool(&self, int index) {
  LuaValue value = self.stack._get(index);
  return value.to_bool();
}


fn LuaValue LuaState.to_integer(&self, int index) {
  return self.to_number_x(index) ?? lua_integer(0);
}

fn LuaValue? LuaState.to_integer_x(&self, int index) {
  LuaValue value = self.stack._get(index);
  return value.convert_to_long();
}


fn LuaValue LuaState.to_number(&self, int index) {
  return self.to_number_x(index) ?? lua_number(0.0);
}

fn LuaValue? LuaState.to_number_x(&self, int index) {
  LuaValue value = self.stack._get(index);
  return value.convert_to_double();
}

fn LuaValue LuaState.to_string(&self, int index) {
  return self.to_string_x(index) ?? lua_string("");
}

fn LuaValue? LuaState.to_string_x(&self, int index) {
  LuaValue value = self.stack._get(index);
  LuaValue? res;
  switch(value.type) {
    case LuaValueType.LUA_TSTRING: {
      return value;
    }
    case LuaValueType.LUA_TINTEGER: {
      LuaValue strValue = lua_string(string::tformat("%d", value.as_integer));
      self.stack._set(index, strValue);
      return strValue;
    }
    case LuaValueType.LUA_TNUMBER: {
      LuaValue strValue = lua_string(string::tformat("%f", value.as_integer));
      self.stack._set(index, strValue);
      return strValue;
    }
    default: {
      return TYPE_MISS_MATCH?;
    }
  }
}
// ======= access method =======
