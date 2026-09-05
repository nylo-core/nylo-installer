import 'dart:io';
import '../console/console.dart';
import 'process_runner.dart';

/// Outcome of a prerequisite check (see [Validators.verifyPrerequisites]).
class PrerequisiteCheck {
  /// Detected git version (e.g. `2.50.1`), or null if unknown.
  final String? gitVersion;

  /// Detected Flutter version (e.g. `3.47.2`), or null if unknown.
  final String? flutterVersion;

  /// Human-readable problems. Empty when every prerequisite is available.
  final List<String> problems;

  const PrerequisiteCheck({
    this.gitVersion,
    this.flutterVersion,
    this.problems = const [],
  });

  /// True when all prerequisites are available.
  bool get ok => problems.isEmpty;

  /// Short description of the detected tools, e.g.
  /// `Flutter 3.47.2 · Git 2.50.1`. Null when nothing could be detected.
  String? get summary {
    final parts = [
      if (flutterVersion != null) 'Flutter $flutterVersion',
      if (gitVersion != null) 'Git $gitVersion',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// Validates system prerequisites for project creation
class Validators {
  static const String _gitMissing =
      'Git is not installed or not in PATH.\n'
      'Install Git: https://git-scm.com/downloads';

  static const String _flutterMissing =
      'Flutter is not installed or not in PATH.\n'
      'Install Flutter: https://docs.flutter.dev/get-started/install';

  /// Check that git and Flutter are available, without printing or exiting.
  ///
  /// Both tools are probed concurrently. The result carries the detected
  /// versions and a list of problems for anything that is missing.
  static Future<PrerequisiteCheck> verifyPrerequisites() async {
    final results = await Future.wait([
      ProcessRunner.run('git', ['--version']),
      ProcessRunner.run('flutter', ['--version']),
    ]);
    final git = results[0];
    final flutter = results[1];

    return PrerequisiteCheck(
      gitVersion: git.exitCode == 0 ? parseGitVersion(git.stdout) : null,
      flutterVersion: flutter.exitCode == 0
          ? parseFlutterVersion(flutter.stdout)
          : null,
      problems: [
        if (git.exitCode != 0) _gitMissing,
        if (flutter.exitCode != 0) _flutterMissing,
      ],
    );
  }

  /// Check all prerequisites (git, flutter), printing an error and exiting
  /// the process if any are missing.
  static Future<void> checkPrerequisites() async {
    final check = await verifyPrerequisites();
    if (!check.ok) {
      for (final problem in check.problems) {
        NyloConsole.writeError(problem);
      }
      exit(1);
    }
    NyloConsole.writeSubtaskComplete('Prerequisites verified');
  }

  /// Extracts the version from `git --version` output
  /// (e.g. `git version 2.50.1 (Apple Git-155)` → `2.50.1`).
  static String? parseGitVersion(String output) {
    return RegExp(r'git version (\d+(?:\.\d+)+)').firstMatch(output)?.group(1);
  }

  /// Extracts the version from `flutter --version` output
  /// (e.g. `Flutter 3.47.2 • channel stable • …` → `3.47.2`).
  static String? parseFlutterVersion(String output) {
    return RegExp(
      r'Flutter (\d+(?:\.\d+)+(?:-[\w.]+)?)',
    ).firstMatch(output)?.group(1);
  }
}
