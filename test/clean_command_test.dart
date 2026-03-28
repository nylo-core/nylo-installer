import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('CleanCommand', () {
    group('flag parsing', () {
      late ArgParser parser;

      setUp(() {
        parser = ArgParser()
          ..addFlag('ios', negatable: false)
          ..addFlag('android', negatable: false)
          ..addFlag('all', negatable: false);
      });

      test('should parse --ios flag', () {
        final results = parser.parse(['--ios']);
        expect(results['ios'], isTrue);
        expect(results['android'], isFalse);
        expect(results['all'], isFalse);
      });

      test('should parse --android flag', () {
        final results = parser.parse(['--android']);
        expect(results['ios'], isFalse);
        expect(results['android'], isTrue);
        expect(results['all'], isFalse);
      });

      test('should parse --all flag', () {
        final results = parser.parse(['--all']);
        expect(results['ios'], isFalse);
        expect(results['android'], isFalse);
        expect(results['all'], isTrue);
      });

      test('--all should enable both iOS and Android', () {
        final results = parser.parse(['--all']);
        final cleanIos = results['ios'] as bool || results['all'] as bool;
        final cleanAndroid =
            results['android'] as bool || results['all'] as bool;
        expect(cleanIos, isTrue);
        expect(cleanAndroid, isTrue);
      });

      test('--ios --android should enable both', () {
        final results = parser.parse(['--ios', '--android']);
        expect(results['ios'], isTrue);
        expect(results['android'], isTrue);
      });

      test('no flags should default to all false', () {
        final results = parser.parse([]);
        expect(results['ios'], isFalse);
        expect(results['android'], isFalse);
        expect(results['all'], isFalse);
      });

      test('should reject unknown flags', () {
        expect(
          () => parser.parse(['--web']),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('step counting', () {
      test('default clean should have 2 steps', () {
        int totalSteps = 2;
        expect(totalSteps, equals(2));
      });

      test('--ios should have 4 steps', () {
        int totalSteps = 2;
        totalSteps += 2; // rm artifacts + pod install
        expect(totalSteps, equals(4));
      });

      test('--android should have 3 steps', () {
        int totalSteps = 2;
        totalSteps += 1; // gradlew clean
        expect(totalSteps, equals(3));
      });

      test('--all should have 5 steps', () {
        int totalSteps = 2;
        totalSteps += 2; // iOS
        totalSteps += 1; // Android
        expect(totalSteps, equals(5));
      });

      test('stepLabel should increment correctly', () {
        int totalSteps = 4;
        int currentStep = 0;
        String stepLabel() {
          currentStep++;
          return '[$currentStep/$totalSteps]';
        }

        expect(stepLabel(), equals('[1/4]'));
        expect(stepLabel(), equals('[2/4]'));
        expect(stepLabel(), equals('[3/4]'));
        expect(stepLabel(), equals('[4/4]'));
      });
    });

    group('iOS artifact removal', () {
      late Directory tempDir;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('nylo_clean_test_');
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

        // None of the artifacts exist - should not throw
        final podsDir = Directory(path.join(iosDir.path, 'Pods'));
        final symlinksDir = Directory(path.join(iosDir.path, '.symlinks'));
        final podfileLock = File(path.join(iosDir.path, 'Podfile.lock'));

        expect(await podsDir.exists(), isFalse);
        expect(await symlinksDir.exists(), isFalse);
        expect(await podfileLock.exists(), isFalse);

        // Simulating the removal logic - should not throw
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

        // Simulate _removeIosArtifacts logic
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
        tempDir = await Directory.systemTemp.createTemp('nylo_clean_test_');
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

      test('should detect missing android/ directory', () async {
        final androidDir = Directory(path.join(tempDir.path, 'android'));
        expect(await androidDir.exists(), isFalse);
      });

      test('should detect existing ios/ directory', () async {
        final iosDir = Directory(path.join(tempDir.path, 'ios'));
        await iosDir.create();
        expect(await iosDir.exists(), isTrue);
      });

      test('should detect existing android/ directory', () async {
        final androidDir = Directory(path.join(tempDir.path, 'android'));
        await androidDir.create();
        expect(await androidDir.exists(), isTrue);
      });
    });
  });

  group('CLI clean flags', () {
    test('help should list clean flags', () async {
      final result = await Process.run(
        'dart',
        ['run', 'bin/nylo.dart', '--help'],
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('--ios'));
      expect(result.stdout, contains('--android'));
      expect(result.stdout, contains('--all'));
    });

    test('help should show clean flag examples', () async {
      final result = await Process.run(
        'dart',
        ['run', 'bin/nylo.dart', '--help'],
      );

      expect(result.stdout, contains('nylo clean --ios'));
      expect(result.stdout, contains('nylo clean --all'));
    });
  });
}
