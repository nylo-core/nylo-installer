import 'dart:convert';

import 'models.dart';

/// Renders [Finding]s and [LocaleComparison]s into deterministic Markdown,
/// plain-text, and JSON reports. All methods are pure: same input + timestamp
/// always yields byte-identical output.
class Reporter {
  Reporter._();

  static const JsonEncoder _json = JsonEncoder.withIndent('  ');
  static const int _maxCell = 120;

  // ---- find-untranslated ---------------------------------------------------

  static String findingsMarkdown(
    List<Finding> findings, {
    required String projectName,
    required DateTime generatedAt,
  }) {
    final buffer = StringBuffer()
      ..writeln('# $projectName — Untranslated Strings')
      ..writeln()
      ..writeln('*Generated at ${_iso(generatedAt)}*')
      ..writeln();

    if (findings.isEmpty) {
      buffer.writeln('No untranslated strings found.');
      return buffer.toString();
    }

    final files = findings.map((f) => f.relativePath).toSet().toList()..sort();
    buffer
      ..writeln(
        'Found **${findings.length}** untranslated string(s) across '
        '**${files.length}** file(s).',
      )
      ..writeln();

    for (final file in files) {
      final rows = findings.where((f) => f.relativePath == file).toList()
        ..sort((a, b) => a.line.compareTo(b.line));
      buffer
        ..writeln('## $file')
        ..writeln()
        ..writeln('| Line | Context | String |')
        ..writeln('| --- | --- | --- |');
      for (final f in rows) {
        buffer.writeln(
          '| ${f.line} | ${_cell(f.context)} | ${_cell(f.value)} |',
        );
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  static String findingsJson(
    List<Finding> findings, {
    required String projectName,
    required DateTime generatedAt,
  }) {
    return _json.convert({
      'project': projectName,
      'generated_at': _iso(generatedAt),
      'count': findings.length,
      'findings': findings.map((f) => f.toJson()).toList(),
    });
  }

  // ---- check-missing-keys --------------------------------------------------

  static String missingKeysMarkdown(
    List<LocaleComparison> locales, {
    required String baseline,
    required DateTime generatedAt,
  }) {
    final buffer = StringBuffer()
      ..writeln('# Missing Translation Keys')
      ..writeln()
      ..writeln('*Baseline: `$baseline` · Generated at ${_iso(generatedAt)}*')
      ..writeln();

    if (locales.isEmpty) {
      buffer.writeln('No other locale files found to compare against.');
      return buffer.toString();
    }

    buffer
      ..writeln('| Locale | Missing | Empty | Extra |')
      ..writeln('| --- | --- | --- | --- |');
    for (final c in locales) {
      buffer.writeln(
        '| ${c.locale} | ${c.missing.length} | ${c.empty.length} | '
        '${c.extra.length} |',
      );
    }
    buffer.writeln();

    for (final c in locales) {
      buffer
        ..writeln('## ${c.locale}')
        ..writeln();
      if (c.isStrictlyClean) {
        buffer
          ..writeln('Complete — no missing, empty, or extra keys.')
          ..writeln();
        continue;
      }
      _keyList(buffer, 'Missing keys', c.missing);
      _keyList(buffer, 'Empty values', c.empty);
      _keyList(buffer, 'Extra keys', c.extra);
    }
    return buffer.toString();
  }

  static String missingKeysText(
    List<LocaleComparison> locales, {
    required String baseline,
    required DateTime generatedAt,
  }) {
    final buffer = StringBuffer()
      ..writeln('Missing Translation Keys')
      ..writeln('Baseline: $baseline')
      ..writeln('Generated at: ${_iso(generatedAt)}')
      ..writeln();

    if (locales.isEmpty) {
      buffer.writeln('No other locale files found to compare against.');
      return buffer.toString();
    }

    for (final c in locales) {
      buffer.writeln(
        '[${c.locale}] missing=${c.missing.length} '
        'empty=${c.empty.length} extra=${c.extra.length}',
      );
      for (final key in c.missing) {
        buffer.writeln('  - missing: $key');
      }
      for (final key in c.empty) {
        buffer.writeln('  - empty: $key');
      }
      for (final key in c.extra) {
        buffer.writeln('  - extra: $key');
      }
    }
    return buffer.toString();
  }

  static String missingKeysJson(
    List<LocaleComparison> locales, {
    required String baseline,
    required DateTime generatedAt,
  }) {
    return _json.convert({
      'baseline': baseline,
      'generated_at': _iso(generatedAt),
      'locales': locales.map((c) => c.toJson()).toList(),
    });
  }

  // ---- helpers -------------------------------------------------------------

  static void _keyList(StringBuffer buffer, String title, List<String> keys) {
    if (keys.isEmpty) return;
    buffer
      ..writeln('**$title (${keys.length}):**')
      ..writeln();
    for (final key in keys) {
      buffer.writeln('- `$key`');
    }
    buffer.writeln();
  }

  static String _iso(DateTime dt) => dt.toIso8601String();

  /// Clip overly long strings and make a value safe for a Markdown table cell.
  static String _cell(String value) {
    final clipped = value.length <= _maxCell
        ? value
        : '${value.substring(0, _maxCell)}…';
    return clipped
        .replaceAll('\r\n', r'\n')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\n')
        .replaceAll('|', r'\|');
  }
}
