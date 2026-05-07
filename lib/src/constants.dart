import 'dart:io';

/// Constants used throughout the Nylo installer
class Constants {
  Constants._();

  /// The Nylo template repository URL
  static const String templateRepoUrl = 'https://github.com/nylo-core/nylo';

  /// Installer version
  static const String version = '1.7.0';

  /// Documentation URL
  static const String docsUrl = 'https://nylo.dev/docs';

  /// Package name on pub.dev
  static const String packageName = 'nylo_installer';

  /// pub.dev API URL for version checking
  static const String pubDevApiUrl =
      'https://pub.dev/api/packages/$packageName';

  /// Cache directory path (~/.nylo)
  static String get cacheDirPath {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return '$home/.nylo';
  }

  /// Cache file name for version checks
  static const String cacheFileName = 'version_cache.json';
}
