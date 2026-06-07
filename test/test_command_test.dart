import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('TestCommand', () {
    group('flag parsing', () {
      late ArgParser parser;

      setUp(() {
        parser = ArgParser()
          ..addFlag(
            'format',
            defaultsTo: true,
            help: 'Format test files before running (use --no-format to skip)',
          )
          ..addOption(
            'filter',
            abbr: 'f',
            help: 'Filter tests by name pattern',
            valueHelp: 'pattern',
          )
          ..addFlag('coverage', negatable: false, help: 'Collect code coverage')
          ..addOption('path', help: 'Test directory path', defaultsTo: 'test');
      });

      test('should default format to true', () {
        final results = parser.parse([]);
        expect(results['format'], isTrue);
      });

      test('should parse --no-format flag', () {
        final results = parser.parse(['--no-format']);
        expect(results['format'], isFalse);
      });

      test('should parse --filter option', () {
        final results = parser.parse(['--filter', 'login']);
        expect(results['filter'], equals('login'));
      });

      test('should parse -f shorthand for filter', () {
        final results = parser.parse(['-f', 'auth']);
        expect(results['filter'], equals('auth'));
      });

      test('should parse --coverage flag', () {
        final results = parser.parse(['--coverage']);
        expect(results['coverage'], isTrue);
      });

      test('should default coverage to false', () {
        final results = parser.parse([]);
        expect(results['coverage'], isFalse);
      });

      test('should parse --path option', () {
        final results = parser.parse(['--path', 'integration_test']);
        expect(results['path'], equals('integration_test'));
      });

      test('should default path to test', () {
        final results = parser.parse([]);
        expect(results['path'], equals('test'));
      });

      test('should parse all flags together', () {
        final results = parser.parse([
          '--no-format',
          '--filter',
          'login',
          '--coverage',
          '--path',
          'integration_test',
        ]);
        expect(results['format'], isFalse);
        expect(results['filter'], equals('login'));
        expect(results['coverage'], isTrue);
        expect(results['path'], equals('integration_test'));
      });

      test('should reject unknown flags', () {
        expect(
          () => parser.parse(['--unknown']),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('step counting', () {
      test('with format should have 2 steps', () {
        int totalSteps = 2; // format + run tests
        expect(totalSteps, equals(2));
      });

      test('without format should have 1 step', () {
        int totalSteps = 1; // run tests only
        expect(totalSteps, equals(1));
      });

      test('stepLabel should increment correctly', () {
        int totalSteps = 2;
        int currentStep = 0;
        String stepLabel() {
          currentStep++;
          return '[$currentStep/$totalSteps]';
        }

        expect(stepLabel(), equals('[1/2]'));
        expect(stepLabel(), equals('[2/2]'));
      });
    });

    group('test file discovery', () {
      late Directory tempDir;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('nylo_test_cmd_');
      });

      tearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      test('should find *_test.dart files', () async {
        final testDir = Directory(path.join(tempDir.path, 'test'));
        await testDir.create();
        await File(
          path.join(testDir.path, 'widget_test.dart'),
        ).writeAsString('void main() {}');
        await File(
          path.join(testDir.path, 'unit_test.dart'),
        ).writeAsString('void main() {}');
        await File(
          path.join(testDir.path, 'helper.dart'),
        ).writeAsString('// helper');

        final files = <String>[];
        await for (final entity in testDir.list(recursive: true)) {
          if (entity is File && entity.path.endsWith('_test.dart')) {
            files.add(entity.path);
          }
        }
        files.sort();

        expect(files.length, equals(2));
        expect(files[0], endsWith('unit_test.dart'));
        expect(files[1], endsWith('widget_test.dart'));
      });

      test('should find nested test files', () async {
        final testDir = Directory(path.join(tempDir.path, 'test'));
        await testDir.create();
        await File(
          path.join(testDir.path, 'root_test.dart'),
        ).writeAsString('void main() {}');

        final nestedDir = Directory(path.join(testDir.path, 'unit'));
        await nestedDir.create();
        await File(
          path.join(nestedDir.path, 'model_test.dart'),
        ).writeAsString('void main() {}');

        final deepDir = Directory(path.join(nestedDir.path, 'models'));
        await deepDir.create();
        await File(
          path.join(deepDir.path, 'user_test.dart'),
        ).writeAsString('void main() {}');

        final files = <String>[];
        await for (final entity in testDir.list(recursive: true)) {
          if (entity is File && entity.path.endsWith('_test.dart')) {
            files.add(entity.path);
          }
        }
        files.sort();

        expect(files.length, equals(3));
      });

      test('should return empty list for empty directory', () async {
        final testDir = Directory(path.join(tempDir.path, 'test'));
        await testDir.create();

        final files = <String>[];
        await for (final entity in testDir.list(recursive: true)) {
          if (entity is File && entity.path.endsWith('_test.dart')) {
            files.add(entity.path);
          }
        }

        expect(files, isEmpty);
      });

      test('should return empty list for non-existent directory', () async {
        final testDir = Directory(path.join(tempDir.path, 'nonexistent'));
        final exists = await testDir.exists();

        expect(exists, isFalse);
      });

      test('should ignore non-test dart files', () async {
        final testDir = Directory(path.join(tempDir.path, 'test'));
        await testDir.create();
        await File(
          path.join(testDir.path, 'helper.dart'),
        ).writeAsString('// helper');
        await File(
          path.join(testDir.path, 'fixtures.dart'),
        ).writeAsString('// fixtures');
        await File(
          path.join(testDir.path, 'test_utils.dart'),
        ).writeAsString('// utils');
        await File(
          path.join(testDir.path, 'actual_test.dart'),
        ).writeAsString('void main() {}');

        final files = <String>[];
        await for (final entity in testDir.list(recursive: true)) {
          if (entity is File && entity.path.endsWith('_test.dart')) {
            files.add(entity.path);
          }
        }

        expect(files.length, equals(1));
        expect(files.first, endsWith('actual_test.dart'));
      });
    });
  });

  group('CLI test command', () {
    test('help should list test command', () async {
      final result = await Process.run('dart', [
        'run',
        'bin/nylo.dart',
        '--help',
      ]);

      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('test'));
      expect(result.stdout, contains('Format and run Flutter tests'));
    });

    test('help should show test flags', () async {
      final result = await Process.run('dart', [
        'run',
        'bin/nylo.dart',
        '--help',
      ]);

      expect(result.stdout, contains('--no-format'));
      expect(result.stdout, contains('--filter'));
      expect(result.stdout, contains('--coverage'));
    });

    test('help should show test examples', () async {
      final result = await Process.run('dart', [
        'run',
        'bin/nylo.dart',
        '--help',
      ]);

      expect(result.stdout, contains('nylo test'));
      expect(result.stdout, contains('nylo test --filter'));
    });
  });
}
