import 'dart:io';

import 'package:test/test.dart';

/// Verifies that every `nylo` subcommand responds to `-h` / `--help` with a
/// usage block and exit code 0, instead of erroring on the unknown flag.
///
/// Each command exits before performing any side effect (no clone, no
/// `flutter clean`, no pub.dev call, no `ios/` check), so driving the real CLI
/// is safe on any platform.
void main() {
  group('subcommand help', () {
    Future<ProcessResult> runNylo(List<String> args) =>
        Process.run('dart', ['run', 'bin/nylo.dart', ...args]);

    const commands = [
      'new',
      'clean',
      'test',
      'ios:pod-refresh',
      'self-update',
      'locale:find-untranslated',
      'locale:check-missing-keys',
    ];

    for (final command in commands) {
      for (final flag in ['-h', '--help']) {
        test('$command $flag prints usage and exits 0', () async {
          final result = await runNylo([command, flag]);
          expect(
            result.exitCode,
            equals(0),
            reason: 'stderr: ${result.stderr}',
          );
          expect(result.stdout as String, contains('Usage: nylo $command'));
        });
      }
    }

    test('an invalid flag prints the error and the usage block', () async {
      final result = await runNylo(['clean', '--definitely-not-a-flag']);
      expect(result.exitCode, equals(1));
      expect(result.stderr as String, contains('definitely-not-a-flag'));
      expect(result.stdout as String, contains('Usage: nylo clean'));
    });
  });
}
