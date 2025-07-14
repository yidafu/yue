module state;

import std::collections::list;
import std::io;

alias ListLuaValue =  List { LuaValue };
struct LuaState {
  ListLuaValue stack;
}

fn LuaState new_state() {
  ListLuaValue stack;
  stack.init(mem, 32);
  LuaState state = { stack };
  return state;
}

fn void LuaState.free(&self) {
  self.stack.free();
}
<*
  @param index : `lua 里 index 从 1 开始`
*>
fn bool ListLuaValue.is_valid(&self, int index) @private {
  int abs_idx = self.abs_index(index);
  return abs_idx > 0 && abs_idx <= self.len();
}
fn int ListLuaValue.abs_index(&self, int index) @private {
  if (index > 0) {
    return index;
  }
  // io::printf("{abs idx %d len %d}", index, self.len());
  return index + (int)self.len() + 1;
}

fn  LuaValue ListLuaValue._get(&self, int index) @private {
  int abs_idx = self.abs_index(index);
  // io::printf("(index %d abs index %d)", index, abs_idx);
   if (abs_idx > 0 && abs_idx <= self.len()) {
    return self.get((usz)(abs_idx - 1));
   }
   return lua_nil();
}

fn void ListLuaValue._set(&self, int index, LuaValue value) @private {
  int abs_idx = self.abs_index(index);
  if (abs_idx > 0 && abs_idx < self.len()) {
    self.set((usz)(abs_idx - 1), value);
    return;
  }
  unreachable("invalid index!");
}
fn void ListLuaValue._reverse(&self, int from, int to) {
  while (from < to) {
    self.swap(to, from);
    from ++;
    to--;
  }
}


fn int LuaState.get_top(&self) {
  return (int)self.stack.len() + 1;
}
fn int LuaState.abs_index(&self, int index) {
  return self.stack.abs_index(index);
}

<*
always return true. because base on C3 Dynmic List.
@param size
@require size > 0 
*>
fn bool LuaState.check_stack(&self, int size) {
  return true;
}

<*
  pop n element
  @param n
  @require n > 0
*>
fn void LuaState.pop(&self, int n) {
  for (int i = 0; i < n; i += 1)
  {
    self.stack.pop()!!;
  }
  // self.set_top(-n - 1);
}

fn void LuaState.copy(&self, int form_index, int to_index) {
  LuaValue from_value = self.stack._get(form_index);
  self.stack._set(to_index, from_value);
}
fn void LuaState.push_value(&self, int index) {
  LuaValue value = self.stack._get(index);
  self.stack.push(value);
}
fn void LuaState.replace(&self, int index) {
  LuaValue value = self.stack.pop()!!;
  self.stack._set(index, value);
}
fn void LuaState.insert(&self, int index) {
  self.rotate(index, 1);
}
fn void LuaState.remove(&self, int index) {
  self.rotate(index, -1);
  self.pop(1);
}
fn void LuaState.rotate(&self, int index, int n) {
  int top = (int)self.stack.len() - 1;
  int p = self.abs_index(index) - 1;
  int middle;
  if (n > 0) {
    middle = top - n;
  } else {
    middle = p - n - 1;
  }
  io::printfn("index %d top %d, middle %d, low: %d", index, top, middle, p);
  self.stack._reverse(p, middle);
  self.stack._reverse(middle + 1, top);
  self.stack._reverse(p, top);
}
fn void LuaState.set_top(&self, int index) {
  int new_top = (int)self.stack.abs_index(index);
  io::printfn("new top %d", new_top);
  if (new_top < 0) {
    unreachable("stack underflow!");
  }
  int n = (int)self.stack.len() - new_top;
  io::printfn("count %d len %d", n, self.stack.len());
  if (n > 0) {
    for (int i = 0; i < n; i ++) {
      self.stack.pop()!!;
    }
  } else if (n < 0) {
    for (int i = 0; i > n; i --) {
      self.stack.push(lua_nil());
    }
  }
}

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
  LuaValue? res;
  switch(value.type) {
    case LuaValueType.LUA_TINTEGER: {
      return lua_number(value.as_integer);
    }
    default: {
      return TYPE_MISS_MATCH?;
    }
  }
}

fn LuaValue LuaState.to_number(&self, int index) {
  return self.to_number_x(index) ?? lua_number(0.0);
}
fn LuaValue? LuaState.to_number_x(&self, int index) {
  LuaValue value = self.stack._get(index);
  LuaValue? res;
  switch(value.type) {
    case LuaValueType.LUA_TNUMBER: {
      return value;
    }
    case LuaValueType.LUA_TINTEGER: {
      return lua_number((double) value.as_integer);
    }
    default: {
      return TYPE_MISS_MATCH?;
    }
  }
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


// ======= push method =======
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


macro LuaValueType type_of(LuaValue value) {
  return value.type;
}

