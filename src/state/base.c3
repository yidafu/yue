module state;

import std::collections::list;
import std::io;

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
  if (abs_idx > 0 && abs_idx <= self.len()) {
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