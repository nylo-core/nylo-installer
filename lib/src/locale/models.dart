/// One hardcoded-string hit produced by [StringScanner].
class Finding {
  Finding({
    required this.relativePath,
    required this.line,
    required this.column,
    required this.value,
    required this.context,
  });

  final String relativePath;
  final int line;
  final int column;
  final String value;
  final String context;

  Map<String, Object> toJson() => {
    'file': relativePath,
    'line': line,
    'column': column,
    'value': value,
    'context': context,
  };
}

/// One locale's diff against the baseline locale.
class LocaleComparison {
  LocaleComparison({
    required this.locale,
    required this.missing,
    required this.extra,
    required this.empty,
  });

  final String locale;
  final List<String> missing;
  final List<String> extra;
  final List<String> empty;

  /// Extra keys do not affect cleanliness — only missing/empty values do.
  bool get isClean => missing.isEmpty && empty.isEmpty;

  /// True only when this locale's key set is identical to the baseline: no
  /// missing, empty, OR extra keys. Stricter than [isClean], which permits
  /// extra keys not present in the baseline.
  bool get isStrictlyClean => isClean && extra.isEmpty;

  Map<String, Object> toJson() => {
    'locale': locale,
    'missing': missing,
    'extra': extra,
    'empty': empty,
  };
}
