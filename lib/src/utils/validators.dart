import 'dart:io';
import '../console/console.dart';
import 'process_runner.dart';

/// Validates system prerequisites for project creation
class Validators {
  /// Check all prerequisites (git, flutter)
  static Future<void> checkPrerequisites() async {
    await _checkGit();
    await _checkFlutter();
    NyloConsole.writeSubtaskComplete('Prerequisites verified');
  }

  /// Verify git is installed and accessible
  static Future<void> _checkGit() async {
    try {
      final result = await ProcessRunner.run('git', ['--version']);
      if (result.exitCode != 0) {
        throw Exception('git not found');
      }
    } catch (e) {
      NyloConsole.writeError(
        'Git is not installed or not in PATH\n'
        'Please install Git: https://git-scm.com/downloads',
      );
      exit(1);
    }
  }

  /// Verify flutter is installed and accessible
  static Future<void> _checkFlutter() async {
    try {
      final result = await ProcessRunner.run('flutter', ['--version']);
      if (result.exitCode != 0) {
        throw Exception('flutter not found');
      }
    } catch (e) {
      NyloConsole.writeError(
        'Flutter is not installed or not in PATH\n'
        'Please install Flutter: https://docs.flutter.dev/get-started/install',
      );
      exit(1);
    }
  }
}
