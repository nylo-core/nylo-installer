import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('CLI', () {
    group('argument parsing', () {
      test('should show help with --help flag', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart', '--help'],
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('Usage:'));
        expect(result.stdout, contains('nylo'));
        expect(result.stdout, contains('new'));
      });

      test('should show help with -h flag', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart', '-h'],
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('Usage:'));
      });

      test('should show version with --version flag', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart', '--version'],
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('Nylo Installer'));
        // Version should match semantic versioning
        expect(result.stdout, matches(RegExp(r'\d+\.\d+\.\d+')));
      });

      test('should show version with -v flag', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart', '-v'],
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('Nylo Installer'));
      });

      test('should show help when no arguments provided', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart'],
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('Usage:'));
        expect(result.stdout, contains('Commands:'));
      });

      test('should show error for unknown command', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart', 'unknown'],
        );

        expect(result.exitCode, equals(1));
        expect(result.stderr, contains('Unknown command'));
      });

      test('should show error when new command has no project name', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart', 'new'],
        );

        expect(result.exitCode, equals(1));
        expect(result.stderr, contains('project name'));
      });

      test('should show error for invalid project name', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart', 'new', '123invalid'],
        );

        expect(result.exitCode, equals(1));
        expect(result.stderr, contains('Invalid project name'));
      });

      test('should show error for reserved project names', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart', 'new', 'test'],
        );

        expect(result.exitCode, equals(1));
        expect(result.stderr, contains('Invalid project name'));
      });
    });

    group('help content', () {
      test('help should list available commands', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart', '--help'],
        );

        expect(result.stdout, contains('new'));
        expect(result.stdout, contains('<project_name>'));
      });

      test('help should list available options', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart', '--help'],
        );

        expect(result.stdout, contains('--help'));
        expect(result.stdout, contains('--version'));
      });

      test('help should show example usage', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart', '--help'],
        );

        expect(result.stdout, contains('Example:'));
        expect(result.stdout, contains('nylo new'));
      });

      test('help should show documentation URL', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart', '--help'],
        );

        expect(result.stdout, contains('Documentation:'));
        expect(result.stdout, contains('nylo.dev'));
      });
    });
  });
}
