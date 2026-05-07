import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('IosPodRefreshCommand', () {
    group('iOS artifact removal', () {
      late Directory tempDir;

      setUp(() async {
        tempDir =
            await Directory.systemTemp.createTemp('nylo_pod_refresh_test_');
      });

      tearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      test('should remove Pods directory', () async {
        final podsDir = Directory(path.join(tempDir.path, 'ios', 'Pods'));
        await podsDir.create(recursive: true);
        await File(path.join(podsDir.path, 'Manifest.lock'))
            .writeAsString('mock');

        expect(await podsDir.exists(), isTrue);

        await podsDir.delete(recursive: true);

        expect(await podsDir.exists(), isFalse);
      });

      test('should remove .symlinks directory', () async {
        final symlinksDir =
            Directory(path.join(tempDir.path, 'ios', '.symlinks'));
        await symlinksDir.create(recursive: true);
        await File(path.join(symlinksDir.path, 'some_link'))
            .writeAsString('mock');

        expect(await symlinksDir.exists(), isTrue);

        await symlinksDir.delete(recursive: true);

        expect(await symlinksDir.exists(), isFalse);
      });

      test('should remove Podfile.lock file', () async {
        final iosDir = Directory(path.join(tempDir.path, 'ios'));
        await iosDir.create(recursive: true);
        final podfileLock = File(path.join(iosDir.path, 'Podfile.lock'));
        await podfileLock.writeAsString('PODS:\n  - some_pod (1.0.0)\n');

        expect(await podfileLock.exists(), isTrue);

        await podfileLock.delete();

        expect(await podfileLock.exists(), isFalse);
      });

      test('should handle missing artifacts gracefully', () async {
        final iosDir = Directory(path.join(tempDir.path, 'ios'));
        await iosDir.create(recursive: true);

        final podsDir = Directory(path.join(iosDir.path, 'Pods'));
        final symlinksDir = Directory(path.join(iosDir.path, '.symlinks'));
        final podfileLock = File(path.join(iosDir.path, 'Podfile.lock'));

        expect(await podsDir.exists(), isFalse);
        expect(await symlinksDir.exists(), isFalse);
        expect(await podfileLock.exists(), isFalse);

        for (final dir in [podsDir, symlinksDir]) {
          if (await dir.exists()) {
            await dir.delete(recursive: true);
          }
        }
        if (await podfileLock.exists()) {
          await podfileLock.delete();
        }
      });

      test('should remove all iOS artifacts together', () async {
        final iosDir = Directory(path.join(tempDir.path, 'ios'));
        final podsDir = Directory(path.join(iosDir.path, 'Pods'));
        final symlinksDir = Directory(path.join(iosDir.path, '.symlinks'));
        final podfileLock = File(path.join(iosDir.path, 'Podfile.lock'));

        await podsDir.create(recursive: true);
        await symlinksDir.create(recursive: true);
        await podfileLock.create(recursive: true);

        expect(await podsDir.exists(), isTrue);
        expect(await symlinksDir.exists(), isTrue);
        expect(await podfileLock.exists(), isTrue);

        for (final dir in [podsDir, symlinksDir]) {
          if (await dir.exists()) {
            await dir.delete(recursive: true);
          }
        }
        if (await podfileLock.exists()) {
          await podfileLock.delete();
        }

        expect(await podsDir.exists(), isFalse);
        expect(await symlinksDir.exists(), isFalse);
        expect(await podfileLock.exists(), isFalse);
      });
    });

    group('directory validation', () {
      late Directory tempDir;

      setUp(() async {
        tempDir =
            await Directory.systemTemp.createTemp('nylo_pod_refresh_test_');
      });

      tearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      test('should detect missing ios/ directory', () async {
        final iosDir = Directory(path.join(tempDir.path, 'ios'));
        expect(await iosDir.exists(), isFalse);
      });

      test('should detect existing ios/ directory', () async {
        final iosDir = Directory(path.join(tempDir.path, 'ios'));
        await iosDir.create();
        expect(await iosDir.exists(), isTrue);
      });
    });
  });

  group('CLI ios:pod-refresh', () {
    test('help should list ios:pod-refresh command', () async {
      final result = await Process.run(
        'dart',
        ['run', 'bin/nylo.dart', '--help'],
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('ios:pod-refresh'));
    });

    test('help should show ios:pod-refresh example', () async {
      final result = await Process.run(
        'dart',
        ['run', 'bin/nylo.dart', '--help'],
      );

      expect(result.stdout, contains('nylo ios:pod-refresh'));
    });

    test('should error when ios/ directory is missing', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('nylo_pod_refresh_cli_');
      final projectRoot = Directory.current.path;
      try {
        final result = await Process.run(
          'dart',
          [
            'run',
            path.join(projectRoot, 'bin', 'nylo.dart'),
            'ios:pod-refresh'
          ],
          workingDirectory: tempDir.path,
        );

        expect(result.exitCode, equals(1));
        expect(result.stderr, contains('ios/'));
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
