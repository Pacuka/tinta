// ignore_for_file: avoid_print

/// Parses a KRÉTA list item by item. One malformed item (KRÉTA changed a
/// field's type, say) is skipped and logged instead of failing the whole
/// list, which would freeze every grade at the last good sync.
///
/// If every item fails, KRÉTA changed the format itself: this throws, so the
/// caller keeps the stored data instead of replacing it with nothing.
List<T> parseEach<T>(Iterable json, T Function(Map json) parse,
    {required String what}) {
  final out = <T>[];
  var failed = 0;
  for (final e in json) {
    try {
      out.add(parse(e as Map));
    } catch (error) {
      failed++;
      print("WARNING: skipped $what: ${error.runtimeType}");
    }
  }
  if (failed > 0 && out.isEmpty) {
    throw FormatException("Every $what failed to parse ($failed)");
  }
  return out;
}
