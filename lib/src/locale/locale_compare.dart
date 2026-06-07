import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'models.dart';

/// Raised for any recoverable locale-comparison error (missing directory,
/// missing baseline, malformed JSON). The CLI renders it as a clean message.
class LocaleException implements Exception {
  LocaleException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Compares `lang/*.json` locale files against a baseline locale, surfacing
/// missing, empty, and extra keys per locale.
class LocaleComparator {
  LocaleComparator(this.langDir);

  /// Absolute path to the directory holding the locale files.
  final String langDir;

  /// Every `*.json` file in [langDir], sorted by path.
  List<File> localeFiles() {
    final dir = Directory(langDir);
    if (!dir.existsSync()) {
      throw LocaleException('Language directory not found: $langDir');
    }
    final files =
        dir
            .listSync(followLinks: false)
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  List<LocaleComparison> compareAgainst(String baselineFileName) {
    final baselineFile = File(p.join(langDir, baselineFileName));
    if (!baselineFile.existsSync()) {
      throw LocaleException('Baseline file not found: ${baselineFile.path}');
    }

    final baseline = _flatten(_readJson(baselineFile));
    final baselineKeys = baseline.keys.toSet();
    final baselineLocale = p.basenameWithoutExtension(baselineFileName);

    final results = <LocaleComparison>[];
    for (final file in localeFiles()) {
      final locale = p.basenameWithoutExtension(file.path);
      if (locale == baselineLocale) continue;

      final flattened = _flatten(_readJson(file));
      final keys = flattened.keys.toSet();

      final missing = baselineKeys.difference(keys).toList()..sort();
      final extra = keys.difference(baselineKeys).toList()..sort();
      final empty =
          flattened.entries
              .where((e) => e.value.trim().isEmpty)
              .map((e) => e.key)
              .toList()
            ..sort();

      results.add(
        LocaleComparison(
          locale: locale,
          missing: missing,
          extra: extra,
          empty: empty,
        ),
      );
    }
    return results;
  }

  Map<String, dynamic> _readJson(File file) {
    final name = p.basename(file.path);
    final Object? decoded;
    try {
      decoded = jsonDecode(file.readAsStringSync());
    } on FormatException catch (e) {
      throw LocaleException('Invalid JSON in $name: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw LocaleException('$name must contain a JSON object at the root.');
    }
    return decoded;
  }

  Map<String, String> _flatten(
    Map<String, dynamic> input, [
    String prefix = '',
  ]) {
    final out = <String, String>{};
    input.forEach((key, value) {
      final path = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        out.addAll(_flatten(value, path));
      } else {
        out[path] = value?.toString() ?? '';
      }
    });
    return out;
  }
}
