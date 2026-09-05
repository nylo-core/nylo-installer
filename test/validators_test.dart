import 'package:nylo_installer/src/utils/process_runner.dart';
import 'package:nylo_installer/src/utils/validators.dart';
import 'package:test/test.dart';

void main() {
  group('Validators', () {
    // Note: Validators.checkPrerequisites() calls exit() on failure,
    // which makes it difficult to test directly. Instead, we test
    // verifyPrerequisites() (which never exits) and the underlying
    // checks by using ProcessRunner directly.

    group('version parsing', () {
      test('parseGitVersion extracts the version number', () {
        expect(
          Validators.parseGitVersion('git version 2.50.1 (Apple Git-155)\n'),
          equals('2.50.1'),
        );
        expect(
          Validators.parseGitVersion('git version 2.43.0.windows.1'),
          equals('2.43.0'),
        );
      });

      test('parseGitVersion returns null for unexpected output', () {
        expect(Validators.parseGitVersion(''), isNull);
        expect(Validators.parseGitVersion('command not found'), isNull);
      });

      test('parseFlutterVersion extracts the version number', () {
        expect(
          Validators.parseFlutterVersion(
            'Flutter 3.47.2 • channel stable • '
            'https://github.com/flutter/flutter.git\n'
            'Framework • revision abc123 (3 days ago) • 2026-09-01\n'
            'Engine • revision def456\n'
            'Tools • Dart 3.13.2 • DevTools 2.50.0\n',
          ),
          equals('3.47.2'),
        );
      });

      test('parseFlutterVersion keeps pre-release suffixes', () {
        expect(
          Validators.parseFlutterVersion(
            'Flutter 3.48.0-0.1.pre • channel beta',
          ),
          equals('3.48.0-0.1.pre'),
        );
      });

      test('parseFlutterVersion returns null for unexpected output', () {
        expect(Validators.parseFlutterVersion(''), isNull);
        expect(
          Validators.parseFlutterVersion('zsh: command not found'),
          isNull,
        );
      });
    });

    group('PrerequisiteCheck', () {
      test('is ok when there are no problems', () {
        const check = PrerequisiteCheck(
          gitVersion: '2.50.1',
          flutterVersion: '3.47.2',
        );
        expect(check.ok, isTrue);
        expect(check.summary, equals('Flutter 3.47.2 · Git 2.50.1'));
      });

      test('is not ok when a problem is reported', () {
        const check = PrerequisiteCheck(
          gitVersion: '2.50.1',
          problems: ['Flutter is not installed'],
        );
        expect(check.ok, isFalse);
        expect(check.summary, equals('Git 2.50.1'));
      });

      test('summary is null when nothing was detected', () {
        const check = PrerequisiteCheck(problems: ['a', 'b']);
        expect(check.summary, isNull);
      });
    });

    group('verifyPrerequisites', () {
      test('returns a result instead of exiting', () async {
        final check = await Validators.verifyPrerequisites();

        if (check.ok) {
          // Both tools are installed on this machine
          expect(check.gitVersion, isNotNull);
          expect(check.flutterVersion, isNotNull);
          expect(check.summary, contains('Flutter'));
          expect(check.summary, contains('Git'));
        } else {
          // At least one tool is missing; every problem carries an install hint
          expect(check.problems, isNotEmpty);
          for (final problem in check.problems) {
            expect(problem, contains('https://'));
          }
        }
      });
    });

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

      test(
        'failed prerequisite check should have non-zero exit code',
        () async {
          // Test with a command that definitely doesn't exist
          final result = await ProcessRunner.run(
            'totally_fake_prerequisite_command',
            ['--version'],
          );

          expect(result.exitCode, isNot(0));
          expect(result.stderr, isNotEmpty);
        },
      );
    });
  });
}
