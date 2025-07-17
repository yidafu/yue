module number;


faultdef CONVERT_TYPE_FAIL;

fn long? parse_intger(String str) {
  return str.to_long();
}

fn double? parse_double(String str) {
  return str.to_double();
}
fn long double_to_long(double value) {
  return (long) value;
}

fn long? string_to_long(String value) {
  long? long_value = parse_intger(value);
  if (try long_value) {
    return long_value;
  }

  double? double_value = parse_double(value);
  if(try double_value) {
    return (long)double_value;
  }
  return CONVERT_TYPE_FAIL?;
}
