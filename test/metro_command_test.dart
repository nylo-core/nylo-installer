import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('MetroCommand', () {
    group('CLI integration', () {
      test('help should list metro command', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart', '--help'],
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('metro'));
        expect(result.stdout, contains('metro <command>'));
      });

      test('metro should be a recognized command', () async {
        // Running metro without being in a Nylo project will fail,
        // but it should NOT trigger the "Unknown command" error path.
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart', 'metro'],
        );

        expect(result.stderr, isNot(contains('Unknown command')));
      }, timeout: Timeout(Duration(seconds: 30)));

      test('metro with arguments should be a recognized command', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart', 'metro', 'make:model', 'User'],
        );

        expect(result.stderr, isNot(contains('Unknown command')));
      }, timeout: Timeout(Duration(seconds: 30)));

      test('metro example should appear in help', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart', '--help'],
        );

        expect(result.stdout, contains('nylo metro'));
      });
    });
  });
}
