import 'dart:io';

import 'package:path/path.dart' as path;

/// Represents a user's shell configuration
class ShellConfig {
  final String shellName;
  final String profilePath;
  final String aliasFormat;

  const ShellConfig({
    required this.shellName,
    required this.profilePath,
    required this.aliasFormat,
  });
}

/// Detects user's shell and provides profile management
class ShellDetector {
  /// Detect the user's shell and return configuration.
  /// Returns null if shell is unsupported or cannot be detected.
  static ShellConfig? detectShell() {
    if (Platform.isWindows) {
      return null;
    }

    final shell = Platform.environment['SHELL'] ?? '';
    final home = Platform.environment['HOME'] ?? '';

    if (home.isEmpty) {
      return null;
    }

    if (shell.endsWith('/zsh')) {
      return ShellConfig(
        shellName: 'zsh',
        profilePath: path.join(home, '.zshrc'),
        aliasFormat: "alias metro='dart run nylo_framework:main'",
      );
    }

    if (shell.endsWith('/bash')) {
      // macOS uses .bash_profile, Linux uses .bashrc
      final profileFile = Platform.isMacOS ? '.bash_profile' : '.bashrc';
      return ShellConfig(
        shellName: 'bash',
        profilePath: path.join(home, profileFile),
        aliasFormat: "alias metro='dart run nylo_framework:main'",
      );
    }

    return null;
  }

  /// Check if metro alias already exists in the profile
  static Future<bool> isMetroAliasInstalled(String profilePath) async {
    final file = File(profilePath);
    if (!await file.exists()) {
      return false;
    }

    final content = await file.readAsString();
    return content.contains('alias metro=') ||
        content.contains("alias metro='") ||
        content.contains('alias metro="');
  }

  /// Add the metro alias to the shell profile.
  /// Returns true on success, false on failure.
  static Future<bool> installMetroAlias(ShellConfig config) async {
    try {
      final file = File(config.profilePath);

      // Create file if it doesn't exist
      if (!await file.exists()) {
        await file.create(recursive: true);
      }

      // Append alias with a comment
      final aliasBlock = '''

# Nylo Metro CLI alias (added by nylo installer)
${config.aliasFormat}
''';

      await file.writeAsString(aliasBlock, mode: FileMode.append);
      return true;
    } catch (e) {
      return false;
    }
  }
}
