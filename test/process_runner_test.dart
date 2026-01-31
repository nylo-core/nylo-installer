import 'dart:io';

import 'package:nylo_installer/src/utils/process_runner.dart';
import 'package:test/test.dart';

void main() {
  group('ProcessResult', () {
    test('should store exit code, stdout, and stderr', () {
      final result = ProcessResult(
        exitCode: 0,
        stdout: 'output text',
        stderr: 'error text',
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout, equals('output text'));
      expect(result.stderr, equals('error text'));
    });

    test('should handle empty output', () {
      final result = ProcessResult(
        exitCode: 1,
        stdout: '',
        stderr: '',
      );

      expect(result.exitCode, equals(1));
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
    });
  });

  group('ProcessRunner', () {
    group('run', () {
      test('should execute a simple command successfully', () async {
        // Use 'echo' which works on all platforms
        final result = await ProcessRunner.run(
          Platform.isWindows ? 'cmd' : 'echo',
          Platform.isWindows ? ['/c', 'echo', 'hello'] : ['hello'],
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout.trim(), equals('hello'));
        expect(result.stderr, isEmpty);
      });

      test('should capture stderr on command failure', () async {
        // Try to run a command that doesn't exist
        final result = await ProcessRunner.run(
          'nonexistent_command_xyz_12345',
          [],
        );

        expect(result.exitCode, isNot(0));
        expect(result.stderr, isNotEmpty);
      });

      test('should work with working directory', () async {
        final tempDir = await Directory.systemTemp.createTemp('nylo_test_');
        try {
          final result = await ProcessRunner.run(
            Platform.isWindows ? 'cmd' : 'pwd',
            Platform.isWindows ? ['/c', 'cd'] : [],
            workingDirectory: tempDir.path,
          );

          expect(result.exitCode, equals(0));
          // The output should contain the temp directory path
          expect(result.stdout, contains(tempDir.path.split('/').last));
        } finally {
          await tempDir.delete(recursive: true);
        }
      });

      test('should capture multi-line output', () async {
        final result = await ProcessRunner.run(
          Platform.isWindows ? 'cmd' : 'printf',
          Platform.isWindows
              ? ['/c', 'echo line1 & echo line2']
              : ['line1\nline2\nline3'],
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('line1'));
        expect(result.stdout, contains('line2'));
      });

      test('should return exit code 1 for invalid executable', () async {
        final result = await ProcessRunner.run(
          'totally_fake_command_that_does_not_exist',
          ['arg1', 'arg2'],
        );

        expect(result.exitCode, equals(1));
        expect(result.stderr, isNotEmpty);
      });

      test('should execute git --version if git is installed', () async {
        final result = await ProcessRunner.run('git', ['--version']);

        // This test assumes git is installed on the test machine
        if (result.exitCode == 0) {
          expect(result.stdout, contains('git'));
          expect(result.stdout.toLowerCase(), contains('version'));
        }
      });
    });
  });
}
