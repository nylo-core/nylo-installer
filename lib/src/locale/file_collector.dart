import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import 'config.dart';

/// Discovers the `.dart` files to scan by walking the project root and applying
/// the configured include (`scanGlobs`) / exclude (`excludeGlobs`) globs.
class FileCollector {
  FileCollector(this.config);

  final AuditConfig config;

  List<File> collect() {
    final root = Directory(config.projectRoot);
    if (!root.existsSync()) return const [];

    final scan = config.scanGlobs.map(Glob.new).toList();
    final exclude = config.excludeGlobs.map(Glob.new).toList();

    final result = <File>[];
    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      // Normalize to a POSIX-relative path so globs behave identically on
      // Windows (where the native separator is `\`).
      final relative = p.relative(entity.path, from: config.projectRoot);
      final posixRelative = p.posix.joinAll(p.split(relative));

      final included = scan.any((g) => g.matches(posixRelative));
      if (!included) continue;
      final excluded = exclude.any((g) => g.matches(posixRelative));
      if (excluded) continue;

      result.add(entity);
    }

    result.sort((a, b) => a.path.compareTo(b.path));
    return result;
  }
}
