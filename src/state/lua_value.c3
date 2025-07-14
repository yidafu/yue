module state;

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

fn LuaValueType typeOf(LuaValue value) {
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

faultdef TYPE_MISS_MATCH;