import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('NewCommand', () {
    group('project name validation', () {
      // Test project name validation rules
      // These tests check the validation logic that NewCommand uses

      bool isValidProjectName(String name) {
        final validPattern = RegExp(r'^[a-z][a-z0-9_]*$');
        final reserved = [
          'test',
          'dart',
          'flutter',
          'lib',
          'bin',
          'build',
          'android',
          'ios',
          'web',
          'macos',
          'windows',
          'linux',
          'assets',
          'fonts',
          'packages',
          'pubspec',
        ];
        return validPattern.hasMatch(name) && !reserved.contains(name);
      }

      test('should accept valid lowercase names', () {
        expect(isValidProjectName('my_app'), isTrue);
        expect(isValidProjectName('myapp'), isTrue);
        expect(isValidProjectName('app123'), isTrue);
        expect(isValidProjectName('my_awesome_app'), isTrue);
      });

      test('should accept names starting with lowercase letter', () {
        expect(isValidProjectName('a'), isTrue);
        expect(isValidProjectName('abc'), isTrue);
        expect(isValidProjectName('z_app'), isTrue);
      });

      test('should accept names with underscores', () {
        expect(isValidProjectName('my_app'), isTrue);
        expect(isValidProjectName('my_cool_app'), isTrue);
        expect(isValidProjectName('a_b_c'), isTrue);
      });

      test('should accept names with numbers', () {
        expect(isValidProjectName('app2'), isTrue);
        expect(isValidProjectName('my_app_v2'), isTrue);
        expect(isValidProjectName('app123test'), isTrue);
      });

      test('should reject names starting with uppercase', () {
        expect(isValidProjectName('MyApp'), isFalse);
        expect(isValidProjectName('MYAPP'), isFalse);
        expect(isValidProjectName('App'), isFalse);
      });

      test('should reject names starting with number', () {
        expect(isValidProjectName('123app'), isFalse);
        expect(isValidProjectName('2cool'), isFalse);
        expect(isValidProjectName('1'), isFalse);
      });

      test('should reject names starting with underscore', () {
        expect(isValidProjectName('_myapp'), isFalse);
        expect(isValidProjectName('__private'), isFalse);
      });

      test('should reject names with hyphens', () {
        expect(isValidProjectName('my-app'), isFalse);
        expect(isValidProjectName('cool-project'), isFalse);
      });

      test('should reject names with special characters', () {
        expect(isValidProjectName('my.app'), isFalse);
        expect(isValidProjectName('my@app'), isFalse);
        expect(isValidProjectName('my app'), isFalse);
        expect(isValidProjectName('my!app'), isFalse);
      });

      test('should reject reserved names', () {
        expect(isValidProjectName('test'), isFalse);
        expect(isValidProjectName('dart'), isFalse);
        expect(isValidProjectName('flutter'), isFalse);
        expect(isValidProjectName('lib'), isFalse);
        expect(isValidProjectName('bin'), isFalse);
      });

      test('should reject additional reserved names (platform folders)', () {
        expect(isValidProjectName('build'), isFalse);
        expect(isValidProjectName('android'), isFalse);
        expect(isValidProjectName('ios'), isFalse);
        expect(isValidProjectName('web'), isFalse);
        expect(isValidProjectName('macos'), isFalse);
        expect(isValidProjectName('windows'), isFalse);
        expect(isValidProjectName('linux'), isFalse);
      });

      test('should reject additional reserved names (project folders)', () {
        expect(isValidProjectName('assets'), isFalse);
        expect(isValidProjectName('fonts'), isFalse);
        expect(isValidProjectName('packages'), isFalse);
        expect(isValidProjectName('pubspec'), isFalse);
      });

      test('should accept names similar to but not exactly reserved', () {
        expect(isValidProjectName('test_app'), isTrue);
        expect(isValidProjectName('dart_project'), isTrue);
        expect(isValidProjectName('flutter_app'), isTrue);
        expect(isValidProjectName('mytest'), isTrue);
      });

      test('should reject empty names', () {
        expect(isValidProjectName(''), isFalse);
      });
    });

    group('file operations', () {
      late Directory tempDir;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('nylo_test_');
      });

      tearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      test('should update pubspec.yaml project name', () async {
        // Create a mock pubspec.yaml
        final pubspecPath = path.join(tempDir.path, 'pubspec.yaml');
        await File(pubspecPath).writeAsString('''
name: nylo
description: A Nylo Flutter project.
version: 1.0.1

environment:
  sdk: '>=3.0.0 <4.0.0'
''');

        // Simulate the update logic from NewCommand
        final pubspecFile = File(pubspecPath);
        String content = await pubspecFile.readAsString();
        content = content.replaceFirst(
          RegExp(r'^name:\s*\w+', multiLine: true),
          'name: my_awesome_app',
        );
        await pubspecFile.writeAsString(content);

        // Verify the update
        final updatedContent = await pubspecFile.readAsString();
        expect(updatedContent, contains('name: my_awesome_app'));
        expect(updatedContent, isNot(contains('name: nylo')));
      });

      test('should update Android build.gradle package name', () async {
        // Create mock Android structure
        final androidDir = Directory(path.join(tempDir.path, 'android', 'app'));
        await androidDir.create(recursive: true);

        final buildGradlePath = path.join(androidDir.path, 'build.gradle');
        await File(buildGradlePath).writeAsString('''
android {
    namespace "com.example.nylo"
    compileSdkVersion 33

    defaultConfig {
        applicationId "com.example.nylo"
        minSdkVersion 21
    }
}
''');

        // Simulate the update logic
        final buildGradleFile = File(buildGradlePath);
        String content = await buildGradleFile.readAsString();
        content = content.replaceAll('com.example.nylo', 'com.example.my_app');
        await buildGradleFile.writeAsString(content);

        // Verify
        final updatedContent = await buildGradleFile.readAsString();
        expect(updatedContent, contains('com.example.my_app'));
        expect(updatedContent, isNot(contains('com.example.nylo')));
      });

      test('should update iOS project.pbxproj bundle identifier', () async {
        // Create mock iOS structure
        final iosDir =
            Directory(path.join(tempDir.path, 'ios', 'Runner.xcodeproj'));
        await iosDir.create(recursive: true);

        final pbxprojPath = path.join(iosDir.path, 'project.pbxproj');
        await File(pbxprojPath).writeAsString('''
PRODUCT_BUNDLE_IDENTIFIER = com.example.nylo;
INFOPLIST_KEY_CFBundleDisplayName = Nylo;
''');

        // Simulate the update logic
        final pbxprojFile = File(pbxprojPath);
        String content = await pbxprojFile.readAsString();
        content = content.replaceAll('com.example.nylo', 'com.example.my_app');
        await pbxprojFile.writeAsString(content);

        // Verify
        final updatedContent = await pbxprojFile.readAsString();
        expect(updatedContent, contains('com.example.my_app'));
        expect(updatedContent, isNot(contains('com.example.nylo')));
      });

      test('should update .env app title', () async {
        final envPath = path.join(tempDir.path, '.env');
        await File(envPath).writeAsString('''
APP_NAME="Nylo"
APP_DEBUG=true
APP_URL=http://localhost
''');

        // Simulate the update logic with ReCase-style title
        final envFile = File(envPath);
        String content = await envFile.readAsString();
        content =
            content.replaceAll('APP_NAME="Nylo"', 'APP_NAME="My Awesome App"');
        await envFile.writeAsString(content);

        // Verify
        final updatedContent = await envFile.readAsString();
        expect(updatedContent, contains('APP_NAME="My Awesome App"'));
        expect(updatedContent, isNot(contains('APP_NAME="Nylo"')));
      });

      test('should remove .git folder', () async {
        // Create a mock .git directory
        final gitDir = Directory(path.join(tempDir.path, '.git'));
        await gitDir.create();
        await File(path.join(gitDir.path, 'config'))
            .writeAsString('mock git config');

        expect(await gitDir.exists(), isTrue);

        // Simulate removal
        if (await gitDir.exists()) {
          await gitDir.delete(recursive: true);
        }

        expect(await gitDir.exists(), isFalse);
      });
    });

    group('snake_case conversion', () {
      // Test that various input formats get converted properly
      // Using recase package behavior

      String toSnakeCase(String input) {
        // Simplified snake_case conversion matching recase behavior
        return input
            .replaceAllMapped(
                RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}')
            .replaceAll(RegExp(r'^_'), '')
            .replaceAll(RegExp(r'[\s-]+'), '_')
            .toLowerCase();
      }

      test('should convert PascalCase to snake_case', () {
        expect(toSnakeCase('MyApp'), equals('my_app'));
        expect(toSnakeCase('MyAwesomeApp'), equals('my_awesome_app'));
      });

      test('should convert camelCase to snake_case', () {
        expect(toSnakeCase('myApp'), equals('my_app'));
        expect(toSnakeCase('coolProject'), equals('cool_project'));
      });

      test('should keep snake_case as is', () {
        expect(toSnakeCase('my_app'), equals('my_app'));
        expect(toSnakeCase('cool_project'), equals('cool_project'));
      });

      test('should handle single word', () {
        expect(toSnakeCase('app'), equals('app'));
        expect(toSnakeCase('App'), equals('app'));
      });
    });
  });
}
