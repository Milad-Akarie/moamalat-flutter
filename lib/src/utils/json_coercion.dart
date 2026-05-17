String? jsonString(Object? value) => value?.toString();

int? jsonInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool? jsonBool(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}
