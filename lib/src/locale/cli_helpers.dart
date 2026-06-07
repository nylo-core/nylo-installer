import 'dart:io';

import 'package:path/path.dart' as p;

/// Resolve the project root to a normalized absolute path.
String resolveProjectRoot(String? provided) =>
    p.normalize(p.absolute(provided ?? Directory.current.path));

/// Ensure [path] ends with the extension matching [format] (`md`/`txt`/`json`),
/// swapping any existing extension if it does not already match.
String withExtension(String path, String format) {
  final ext = '.$format';
  if (p.extension(path) == ext) return path;
  return p.setExtension(path, ext);
}
