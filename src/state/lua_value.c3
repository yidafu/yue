module state;

import number;

enum LuaValueType : int (String desc) {
  LUA_TNONE = "no value",
  LUA_TNIL = "nil",
  LUA_TBOOLEAN = "boolean",
  LUA_TLIGHTUSERDATA = "light userdata",
  LUA_TNUMBER = "number",
  LUA_TSTRING = "string",
  LUA_TTABLE = "table",
  LUA_TFUNCTION = "function",
  LUA_TUSERDATA = "userdata",
  LUA_TTHREAD = "thread",
  LUA_TINTEGER = "number"
}

struct LuaValue {
  LuaValueType type;
  union {
    char as_null;
    bool as_bool;
    long as_integer;
    double as_number;
    String as_str;
  }
}

fn LuaValue? LuaValue.convert_to_double(&self) {
  switch(self.type) {
    case LuaValueType.LUA_TNUMBER: {
      return *self;
    }
    case LuaValueType.LUA_TINTEGER: {
      return lua_number((double) self.as_integer);
    }
    case LuaValueType.LUA_TSTRING: {
      return lua_number(number::parse_intger(self.as_str));
    }
    default: {
      return TYPE_MISS_MATCH?;
    }
  }
}


fn LuaValue? LuaValue.convert_to_long(&self) {
  switch(self.type) {
    case LuaValueType.LUA_TNUMBER: {
      return lua_integer(number::double_to_long(self.as_number));
    }
    case LuaValueType.LUA_TINTEGER: {
      return *self;
    }
    case LuaValueType.LUA_TSTRING: {
      long? long_value = number::string_to_long(self.as_str);
      if (try long_value) {
        return lua_integer(long_value);
      }
      return lua_integer(0);
    }
    default: {
      return TYPE_MISS_MATCH?;
    }
  }
}



macro LuaValueType type_of(LuaValue value) {
  return value.type;
}

macro LuaValue lua_nil() {
  LuaValue nil;
  nil.type = LuaValueType.LUA_TNIL;
  return nil;
}

macro LuaValue lua_bool(bool value) {
  LuaValue luaValue;
  luaValue.type = LuaValueType.LUA_TBOOLEAN;
  luaValue.as_bool = value;
  return luaValue;
}


macro LuaValue lua_integer(long value) {
  LuaValue luaValue;
  luaValue.type = LuaValueType.LUA_TINTEGER;
  luaValue.as_integer = value;
  return luaValue;
}

macro LuaValue lua_number(double value) {
  LuaValue luaValue;
  luaValue.type = LuaValueType.LUA_TNUMBER;
  luaValue.as_number = value;
  return luaValue;
}

macro LuaValue lua_string(String value) {
  LuaValue luaValue;
  luaValue.type = LuaValueType.LUA_TSTRING;
  luaValue.as_str = value;
  return luaValue;
}

macro LuaValue LuaValue.to_bool(&self) {
  switch(self.type) {
    case LuaValueType.LUA_TNIL: {
      return lua_bool(false);
    }
    case LuaValueType.LUA_TBOOLEAN: {
      return lua_bool(self.as_bool);
    }
    default: {
      return lua_bool(true);
    }
  }
}

fn int string_compare(String a, String b) {
  usz min_len = min(a.len, b.len);
  if (min_len == 0) {
    return b.len - a.len;
  }
  for(int i = 0; i < min_len; i++) {
    if (a[i] != b[i]) {
      return a[i] - b[i];
    }
  }
  return a[min_len] - b[min_len];
}
faultdef TYPE_MISS_MATCH;