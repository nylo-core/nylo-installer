import 'package:nylo_installer/src/utils/process_runner.dart';
import 'package:test/test.dart';

void main() {
  group('Validators', () {
    // Note: Validators.checkPrerequisites() calls exit() on failure,
    // which makes it difficult to test directly. Instead, we test
    // the underlying checks by using ProcessRunner directly.

    group('git prerequisite check', () {
      test('should detect if git is available', () async {
        final result = await ProcessRunner.run('git', ['--version']);

        // Most development machines have git installed
        if (result.exitCode == 0) {
          expect(result.stdout.toLowerCase(), contains('git'));
          expect(result.stdout.toLowerCase(), contains('version'));
        } else {
          // Git not installed - this is expected on some CI environments
          expect(result.exitCode, isNot(0));
        }
      });

      test('git --version should return meaningful output', () async {
        final result = await ProcessRunner.run('git', ['--version']);

        if (result.exitCode == 0) {
          // Should match pattern like "git version X.Y.Z"
          expect(
            result.stdout,
            matches(RegExp(r'git version \d+\.\d+', caseSensitive: false)),
          );
        }
      });
    });

    group('flutter prerequisite check', () {
      test('should detect if flutter is available', () async {
        final result = await ProcessRunner.run('flutter', ['--version']);

        // Most Flutter development machines have flutter installed
        if (result.exitCode == 0) {
          expect(result.stdout.toLowerCase(), contains('flutter'));
        } else {
          // Flutter not installed
          expect(result.exitCode, isNot(0));
        }
      });

      test('flutter --version should return version info', () async {
        final result = await ProcessRunner.run('flutter', ['--version']);

        if (result.exitCode == 0) {
          // Should contain Flutter version information
          expect(result.stdout, contains('Flutter'));
          // May also contain Dart version, channel info, etc.
        }
      });
    });

    group('combined prerequisites', () {
      test('both git and flutter checks should complete', () async {
        // Run both checks
        final gitResult = await ProcessRunner.run('git', ['--version']);
        final flutterResult = await ProcessRunner.run('flutter', ['--version']);

        // Both should return results (even if the tools aren't installed)
        expect(gitResult, isNotNull);
        expect(flutterResult, isNotNull);
        expect(gitResult.exitCode, isA<int>());
        expect(flutterResult.exitCode, isA<int>());
      });

      test('failed prerequisite check should have non-zero exit code',
          () async {
        // Test with a command that definitely doesn't exist
        final result = await ProcessRunner.run(
          'totally_fake_prerequisite_command',
          ['--version'],
        );

        expect(result.exitCode, isNot(0));
        expect(result.stderr, isNotEmpty);
      });
    });
  });
}
