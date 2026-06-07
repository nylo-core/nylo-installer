import 'dart:io';

import 'package:path/path.dart' as p;

/// Runtime configuration for both commands. Sensible Nylo defaults are baked
/// in; a `nylo_i18n.yaml` at the project root can override any of them.
///
/// `find-untranslated` uses an allowlist model: a string is only flagged when
/// it sits inside one of [textWidgets] (e.g. `Text`). Everything else — keys,
/// routes, data models, `.tr()` calls — is skipped by default.
class AuditConfig {
  AuditConfig({
    required this.projectRoot,
    this.langDir = 'lang',
    // Only the user-facing UI layers are scanned by default: Nylo keeps pages
    // and widgets under lib/resources. Broaden via `scan:` in nylo_i18n.yaml.
    this.scanGlobs = const [
      'lib/resources/pages/**.dart',
      'lib/resources/widgets/**.dart',
    ],
    this.excludeGlobs = const [
      'lib/generated/**',
      '**/*.g.dart',
      '**/*.freezed.dart',
    ],
    this.minLength = 2,
    this.treatKeysAsTranslated = true,
    Set<String>? textWidgets,
    Set<String>? textFunctions,
    List<RegExp>? skipPatterns,
    List<String>? ignoreMarkers,
  }) : textWidgets =
           textWidgets ??
           const {'Text', 'SelectableText', 'RichText', 'TextSpan'},
       textFunctions = textFunctions ?? const {},
       skipPatterns =
           skipPatterns ??
           [
             RegExp(r'^https?://'),
             RegExp(r'^[\w./-]+\.(png|jpg|jpeg|svg|webp|gif|json|ttf|otf)$'),
             RegExp(r'^#?[0-9a-fA-F]{3,8}$'),
             RegExp(r'^[\d\s.,:%+\-/*()]+$'),
             RegExp(r'^[A-Z0-9_]+$'),
             RegExp(r'^\s*$'),
           ],
       ignoreMarkers = ignoreMarkers ?? ['i18n-ignore', 'nylo-i18n-ignore'];

  final String projectRoot;
  final String langDir;
  final List<String> scanGlobs;
  final List<String> excludeGlobs;
  final int minLength;
  final bool treatKeysAsTranslated;

  /// Widgets whose string content is user-facing copy. A literal is only
  /// flagged when its nearest enclosing call is one of these (e.g. `Text`).
  final Set<String> textWidgets;

  /// Functions/methods whose string arguments are user-facing (e.g. a custom
  /// `showSnack`). Empty by default — add your own via `text_functions`.
  final Set<String> textFunctions;
  final List<RegExp> skipPatterns;
  final List<String> ignoreMarkers;

  String get langDirAbsolute => p.join(projectRoot, langDir);

  String relativeTo(String absolutePath) =>
      p.relative(absolutePath, from: projectRoot);

  /// Load config from `nylo_i18n.yaml` if present, else return defaults.
  factory AuditConfig.load(String projectRoot) {
    final file = File(p.join(projectRoot, 'nylo_i18n.yaml'));
    if (!file.existsSync()) {
      return AuditConfig(projectRoot: projectRoot);
    }
    final map = _parseSimpleYaml(file.readAsStringSync());

    List<String>? listOf(String key) {
      final v = map[key];
      if (v is List) return v.map((e) => e.toString()).toList();
      return null;
    }

    return AuditConfig(
      projectRoot: projectRoot,
      langDir: (map['lang_dir'] as String?) ?? 'lang',
      scanGlobs:
          listOf('scan') ??
          const [
            'lib/resources/pages/**.dart',
            'lib/resources/widgets/**.dart',
          ],
      excludeGlobs:
          listOf('exclude') ??
          const ['lib/generated/**', '**/*.g.dart', '**/*.freezed.dart'],
      minLength: int.tryParse('${map['min_length'] ?? 2}') ?? 2,
      textWidgets: listOf('text_widgets')?.toSet(),
      textFunctions: listOf('text_functions')?.toSet(),
      skipPatterns: listOf('skip_patterns')?.map((s) => RegExp(s)).toList(),
      ignoreMarkers: listOf('ignore_markers'),
    );
  }

  /// Minimal YAML reader: top-level `key: value` and `key:` followed by
  /// `  - item` lists. Enough for this config; not a general YAML parser.
  static Map<String, Object> _parseSimpleYaml(String text) {
    final result = <String, Object>{};
    final lines = text.split('\n');
    String? currentListKey;
    List<String>? currentList;

    void flush() {
      if (currentListKey != null && currentList != null) {
        result[currentListKey!] = currentList!;
      }
      currentListKey = null;
      currentList = null;
    }

    for (final raw in lines) {
      final line = raw.replaceAll('\t', '  ');
      if (line.trim().isEmpty || line.trim().startsWith('#')) continue;

      final listItem = RegExp(r'^\s*-\s+(.*)$').firstMatch(line);
      if (listItem != null && currentList != null) {
        currentList!.add(_unquote(listItem.group(1)!.trim()));
        continue;
      }

      final kv = RegExp(r'^([A-Za-z0-9_]+):\s*(.*)$').firstMatch(line);
      if (kv != null) {
        flush();
        final key = kv.group(1)!;
        final value = kv.group(2)!.trim();
        if (value.isEmpty) {
          currentListKey = key;
          currentList = [];
        } else {
          result[key] = _unquote(value);
        }
      }
    }
    flush();
    return result;
  }

  static String _unquote(String s) {
    if (s.length >= 2 &&
        ((s.startsWith('"') && s.endsWith('"')) ||
            (s.startsWith("'") && s.endsWith("'")))) {
      return s.substring(1, s.length - 1);
    }
    return s;
  }
}
