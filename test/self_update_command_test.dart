import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('SelfUpdateCommand', () {
    group('CLI integration', () {
      test('help should list self-update command', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart', '--help'],
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('self-update'));
        expect(result.stdout, contains('Update nylo'));
      });

      test('self-update should be a recognized command', () async {
        // Running self-update will actually try to update, so we just verify
        // it doesn't trigger the "Unknown command" error path.
        // The command will likely fail or succeed depending on network,
        // but it should NOT print "Unknown command".
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart', 'self-update'],
        );

        expect(result.stderr, isNot(contains('Unknown command')));
      }, timeout: Timeout(Duration(seconds: 30)));

      test('self-update example should appear in help', () async {
        final result = await Process.run(
          'dart',
          ['run', 'bin/nylo.dart', '--help'],
        );

        expect(result.stdout, contains('nylo self-update'));
      });
    });
  });
}
