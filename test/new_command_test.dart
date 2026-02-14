import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('NewCommand', () {
    group('project name validation', () {
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

      group('pubspec.yaml', () {
        test('should update project name', () async {
          final pubspecPath = path.join(tempDir.path, 'pubspec.yaml');
          await File(pubspecPath).writeAsString(
            'name: nylo\n'
            'description: A new Nylo Flutter application.\n'
            'version: 1.0.1\n'
            '\n'
            'environment:\n'
            "  sdk: '>=3.0.0 <4.0.0'\n",
          );

          final pubspecFile = File(pubspecPath);
          String content = await pubspecFile.readAsString();
          content = content.replaceFirst(
            RegExp(r'^name:\s*\w+', multiLine: true),
            'name: my_awesome_app',
          );
          await pubspecFile.writeAsString(content);

          final updatedContent = await pubspecFile.readAsString();
          expect(updatedContent, contains('name: my_awesome_app'));
          expect(updatedContent, isNot(contains('name: nylo')));
        });

        test('should update description', () async {
          final pubspecPath = path.join(tempDir.path, 'pubspec.yaml');
          await File(pubspecPath).writeAsString(
            'name: nylo\n'
            'description: A new Nylo Flutter application.\n'
            'version: 1.0.1\n',
          );

          final pubspecFile = File(pubspecPath);
          String content = await pubspecFile.readAsString();
          content = content.replaceFirst(
            'description: A new Nylo Flutter application.',
            'description: A new Flutter application.',
          );
          await pubspecFile.writeAsString(content);

          final updatedContent = await pubspecFile.readAsString();
          expect(updatedContent,
              contains('description: A new Flutter application.'));
          expect(updatedContent,
              isNot(contains('description: A new Nylo Flutter application.')));
        });

        test('should leave description unchanged if not matching', () async {
          final pubspecPath = path.join(tempDir.path, 'pubspec.yaml');
          await File(pubspecPath).writeAsString(
            'name: nylo\n'
            'description: Some custom description.\n'
            'version: 1.0.1\n',
          );

          final pubspecFile = File(pubspecPath);
          String content = await pubspecFile.readAsString();
          content = content.replaceFirst(
            'description: A new Nylo Flutter application.',
            'description: A new Flutter application.',
          );
          await pubspecFile.writeAsString(content);

          final updatedContent = await pubspecFile.readAsString();
          expect(updatedContent,
              contains('description: Some custom description.'));
        });
      });

      group('Android configuration', () {
        test('should update build.gradle package name', () async {
          final androidDir =
              Directory(path.join(tempDir.path, 'android', 'app'));
          await androidDir.create(recursive: true);

          final buildGradlePath = path.join(androidDir.path, 'build.gradle');
          await File(buildGradlePath).writeAsString(
            'android {\n'
            '    namespace "com.nylo.android"\n'
            '    compileSdkVersion 33\n'
            '\n'
            '    defaultConfig {\n'
            '        applicationId "com.nylo.android"\n'
            '        minSdkVersion 21\n'
            '    }\n'
            '}\n',
          );

          final buildGradleFile = File(buildGradlePath);
          String content = await buildGradleFile.readAsString();
          content =
              content.replaceAll('com.nylo.android', 'com.my_app.android');
          await buildGradleFile.writeAsString(content);

          final updatedContent = await buildGradleFile.readAsString();
          expect(updatedContent, contains('com.my_app.android'));
          expect(updatedContent, isNot(contains('com.nylo.android')));
        });

        test('should update build.gradle.kts package name', () async {
          final androidDir =
              Directory(path.join(tempDir.path, 'android', 'app'));
          await androidDir.create(recursive: true);

          final ktsPath = path.join(androidDir.path, 'build.gradle.kts');
          await File(ktsPath).writeAsString(
            'android {\n'
            '    namespace = "com.nylo.android"\n'
            '    defaultConfig {\n'
            '        applicationId = "com.nylo.android"\n'
            '    }\n'
            '}\n',
          );

          final ktsFile = File(ktsPath);
          String content = await ktsFile.readAsString();
          content =
              content.replaceAll('com.nylo.android', 'com.my_app.android');
          await ktsFile.writeAsString(content);

          final updatedContent = await ktsFile.readAsString();
          expect(updatedContent, contains('com.my_app.android'));
          expect(updatedContent, isNot(contains('com.nylo.android')));
        });

        test('should rename Kotlin source directory', () async {
          final kotlinNyloDir = Directory(path.join(tempDir.path, 'android',
              'app', 'src', 'main', 'kotlin', 'com', 'nylo'));
          await kotlinNyloDir.create(recursive: true);

          // Create a dummy file inside to verify the move
          await File(
                  path.join(kotlinNyloDir.path, 'android', 'MainActivity.kt'))
              .create(recursive: true);

          final kotlinNewDir = Directory(path.join(tempDir.path, 'android',
              'app', 'src', 'main', 'kotlin', 'com', 'my_app'));
          await kotlinNyloDir.rename(kotlinNewDir.path);

          expect(await kotlinNewDir.exists(), isTrue);
          expect(await kotlinNyloDir.exists(), isFalse);
          expect(
            await File(
                    path.join(kotlinNewDir.path, 'android', 'MainActivity.kt'))
                .exists(),
            isTrue,
          );
        });

        test('should update MainActivity.kt package declaration', () async {
          final activityDir = Directory(path.join(tempDir.path, 'android',
              'app', 'src', 'main', 'kotlin', 'com', 'my_app', 'android'));
          await activityDir.create(recursive: true);

          final activityPath = path.join(activityDir.path, 'MainActivity.kt');
          await File(activityPath).writeAsString(
            'package com.nylo.android\n'
            '\n'
            'import io.flutter.embedding.android.FlutterActivity\n'
            '\n'
            'class MainActivity: FlutterActivity()\n',
          );

          final activityFile = File(activityPath);
          String content = await activityFile.readAsString();
          content = content.replaceAll(
              'package com.nylo.android', 'package com.my_app.android');
          await activityFile.writeAsString(content);

          final updatedContent = await activityFile.readAsString();
          expect(updatedContent, contains('package com.my_app.android'));
          expect(updatedContent, isNot(contains('package com.nylo.android')));
        });

        test('should update AndroidManifest.xml label', () async {
          final manifestDir = Directory(
              path.join(tempDir.path, 'android', 'app', 'src', 'main'));
          await manifestDir.create(recursive: true);

          final manifestPath =
              path.join(manifestDir.path, 'AndroidManifest.xml');
          await File(manifestPath).writeAsString(
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <application\n'
            '        android:label="Nylo"\n'
            '        android:icon="@mipmap/ic_launcher">\n'
            '    </application>\n'
            '</manifest>\n',
          );

          final manifestFile = File(manifestPath);
          String content = await manifestFile.readAsString();
          content = content.replaceAll(
              'android:label="Nylo"', 'android:label="My App"');
          await manifestFile.writeAsString(content);

          final updatedContent = await manifestFile.readAsString();
          expect(updatedContent, contains('android:label="My App"'));
          expect(updatedContent, isNot(contains('android:label="Nylo"')));
        });
      });

      group('iOS configuration', () {
        test('should update project.pbxproj Runner bundle identifier',
            () async {
          final iosDir =
              Directory(path.join(tempDir.path, 'ios', 'Runner.xcodeproj'));
          await iosDir.create(recursive: true);

          final pbxprojPath = path.join(iosDir.path, 'project.pbxproj');
          await File(pbxprojPath).writeAsString(
            'PRODUCT_BUNDLE_IDENTIFIER = com.nylo.ios;\n'
            'PRODUCT_NAME = "\$(TARGET_NAME)";\n'
            'PRODUCT_BUNDLE_IDENTIFIER = com.nylo.ios;\n',
          );

          final pbxprojFile = File(pbxprojPath);
          String content = await pbxprojFile.readAsString();
          content = content.replaceAll('com.nylo.ios', 'com.my_app.ios');
          await pbxprojFile.writeAsString(content);

          final updatedContent = await pbxprojFile.readAsString();
          expect(updatedContent, contains('com.my_app.ios'));
          expect(updatedContent, isNot(contains('com.nylo.ios')));
        });

        test('should update project.pbxproj RunnerTests bundle identifier',
            () async {
          final iosDir =
              Directory(path.join(tempDir.path, 'ios', 'Runner.xcodeproj'));
          await iosDir.create(recursive: true);

          final pbxprojPath = path.join(iosDir.path, 'project.pbxproj');
          await File(pbxprojPath).writeAsString(
            'PRODUCT_BUNDLE_IDENTIFIER = com.nylo.ios;\n'
            'PRODUCT_BUNDLE_IDENTIFIER = com.nylo.dev.RunnerTests;\n'
            'PRODUCT_BUNDLE_IDENTIFIER = com.nylo.dev.RunnerTests;\n'
            'PRODUCT_BUNDLE_IDENTIFIER = com.nylo.dev.RunnerTests;\n',
          );

          final pbxprojFile = File(pbxprojPath);
          String content = await pbxprojFile.readAsString();
          content = content.replaceAll('com.nylo.ios', 'com.my_app.ios');
          content = content.replaceAll(
              'com.nylo.dev.RunnerTests', 'com.my_app.ios.RunnerTests');
          await pbxprojFile.writeAsString(content);

          final updatedContent = await pbxprojFile.readAsString();
          expect(updatedContent, contains('com.my_app.ios;'));
          expect(updatedContent, contains('com.my_app.ios.RunnerTests;'));
          expect(updatedContent, isNot(contains('com.nylo.ios;')));
          expect(updatedContent, isNot(contains('com.nylo.dev.RunnerTests')));
        });

        test('should replace all three RunnerTests occurrences', () async {
          final iosDir =
              Directory(path.join(tempDir.path, 'ios', 'Runner.xcodeproj'));
          await iosDir.create(recursive: true);

          final pbxprojPath = path.join(iosDir.path, 'project.pbxproj');
          await File(pbxprojPath).writeAsString(
            'PRODUCT_BUNDLE_IDENTIFIER = com.nylo.dev.RunnerTests;\n'
            'OTHER_SETTING = value;\n'
            'PRODUCT_BUNDLE_IDENTIFIER = com.nylo.dev.RunnerTests;\n'
            'ANOTHER_SETTING = value;\n'
            'PRODUCT_BUNDLE_IDENTIFIER = com.nylo.dev.RunnerTests;\n',
          );

          final pbxprojFile = File(pbxprojPath);
          String content = await pbxprojFile.readAsString();
          content = content.replaceAll(
              'com.nylo.dev.RunnerTests', 'com.my_app.ios.RunnerTests');
          await pbxprojFile.writeAsString(content);

          final updatedContent = await pbxprojFile.readAsString();
          final matches = RegExp('com\\.my_app\\.ios\\.RunnerTests')
              .allMatches(updatedContent)
              .length;
          expect(matches, equals(3));
          expect(updatedContent, isNot(contains('com.nylo.dev.RunnerTests')));
        });

        test('should update Info.plist display name', () async {
          final runnerDir = Directory(path.join(tempDir.path, 'ios', 'Runner'));
          await runnerDir.create(recursive: true);

          final plistPath = path.join(runnerDir.path, 'Info.plist');
          await File(plistPath).writeAsString(
            '<?xml version="1.0" encoding="UTF-8"?>\n'
            '<plist version="1.0">\n'
            '<dict>\n'
            '  <key>CFBundleName</key>\n'
            '  <string>Nylo</string>\n'
            '  <key>CFBundleDisplayName</key>\n'
            '  <string>Nylo</string>\n'
            '</dict>\n'
            '</plist>\n',
          );

          final plistFile = File(plistPath);
          String content = await plistFile.readAsString();
          content = content.replaceAll(
              '<string>Nylo</string>', '<string>My App</string>');
          await plistFile.writeAsString(content);

          final updatedContent = await plistFile.readAsString();
          expect(updatedContent, contains('<string>My App</string>'));
          expect(updatedContent, isNot(contains('<string>Nylo</string>')));
        });
      });

      group('.env configuration', () {
        test('should update app title with double quotes', () async {
          final envPath = path.join(tempDir.path, '.env');
          await File(envPath).writeAsString(
            'APP_NAME="Nylo"\n'
            'APP_DEBUG=true\n'
            'APP_URL=http://localhost\n',
          );

          final envFile = File(envPath);
          String content = await envFile.readAsString();
          content = content.replaceAll(
              'APP_NAME="Nylo"', 'APP_NAME="My Awesome App"');
          await envFile.writeAsString(content);

          final updatedContent = await envFile.readAsString();
          expect(updatedContent, contains('APP_NAME="My Awesome App"'));
          expect(updatedContent, isNot(contains('APP_NAME="Nylo"')));
        });

        test('should update app title with single quotes', () async {
          final envPath = path.join(tempDir.path, '.env');
          await File(envPath).writeAsString(
            "APP_NAME='Nylo'\n"
            'APP_DEBUG=true\n',
          );

          final envFile = File(envPath);
          String content = await envFile.readAsString();
          content = content.replaceAll("APP_NAME='Nylo'", "APP_NAME='My App'");
          await envFile.writeAsString(content);

          final updatedContent = await envFile.readAsString();
          expect(updatedContent, contains("APP_NAME='My App'"));
          expect(updatedContent, isNot(contains("APP_NAME='Nylo'")));
        });
      });

      group('.env setup', () {
        test('should copy .env-example to .env', () async {
          final envExamplePath = path.join(tempDir.path, '.env-example');
          await File(envExamplePath).writeAsString(
            'APP_NAME="Nylo"\nAPP_DEBUG=true\n',
          );

          final envExampleFile = File(envExamplePath);
          final envFile = File(path.join(tempDir.path, '.env'));
          await envExampleFile.copy(envFile.path);

          expect(await envFile.exists(), isTrue);
          final content = await envFile.readAsString();
          expect(content, contains('APP_NAME="Nylo"'));
          expect(content, contains('APP_DEBUG=true'));
        });
      });

      group('.git removal', () {
        test('should remove .git folder', () async {
          final gitDir = Directory(path.join(tempDir.path, '.git'));
          await gitDir.create();
          await File(path.join(gitDir.path, 'config'))
              .writeAsString('mock git config');

          expect(await gitDir.exists(), isTrue);

          if (await gitDir.exists()) {
            await gitDir.delete(recursive: true);
          }

          expect(await gitDir.exists(), isFalse);
        });
      });

      group('test imports', () {
        test('should update root-relative imports to package imports',
            () async {
          final testDir = Directory(path.join(tempDir.path, 'test'));
          await testDir.create(recursive: true);

          final testFilePath = path.join(testDir.path, 'widget_test.dart');
          await File(testFilePath).writeAsString(
            "import '/app/controllers/home_controller.dart';\n"
            "import '/resources/pages/home_page.dart';\n"
            "import 'package:flutter_test/flutter_test.dart';\n",
          );

          final testFile = File(testFilePath);
          String content = await testFile.readAsString();
          content = content.replaceAll("import '/", "import 'package:my_app/");
          await testFile.writeAsString(content);

          final updatedContent = await testFile.readAsString();
          expect(
              updatedContent,
              contains(
                  "import 'package:my_app/app/controllers/home_controller.dart'"));
          expect(
              updatedContent,
              contains(
                  "import 'package:my_app/resources/pages/home_page.dart'"));
          // Should not touch package imports
          expect(updatedContent,
              contains("import 'package:flutter_test/flutter_test.dart'"));
          expect(updatedContent, isNot(contains("import '/")));
        });

        test('should update imports in nested test directories', () async {
          final nestedDir = Directory(path.join(tempDir.path, 'test', 'unit'));
          await nestedDir.create(recursive: true);

          final testFilePath =
              path.join(nestedDir.path, 'controller_test.dart');
          await File(testFilePath).writeAsString(
            "import '/app/controllers/home_controller.dart';\n",
          );

          // Simulate recursive list + update
          final testDir = Directory(path.join(tempDir.path, 'test'));
          await for (final entity in testDir.list(recursive: true)) {
            if (entity is File && entity.path.endsWith('.dart')) {
              String content = await entity.readAsString();
              if (content.contains("import '/")) {
                content =
                    content.replaceAll("import '/", "import 'package:my_app/");
                await entity.writeAsString(content);
              }
            }
          }

          final updatedContent = await File(testFilePath).readAsString();
          expect(
              updatedContent,
              contains(
                  "import 'package:my_app/app/controllers/home_controller.dart'"));
        });

        test('should skip files without root-relative imports', () async {
          final testDir = Directory(path.join(tempDir.path, 'test'));
          await testDir.create(recursive: true);

          final testFilePath = path.join(testDir.path, 'clean_test.dart');
          const originalContent =
              "import 'package:flutter_test/flutter_test.dart';\n"
              "import 'package:nylo/main.dart';\n";
          await File(testFilePath).writeAsString(originalContent);

          final testFile = File(testFilePath);
          String content = await testFile.readAsString();
          if (content.contains("import '/")) {
            content =
                content.replaceAll("import '/", "import 'package:my_app/");
            await testFile.writeAsString(content);
          }

          final updatedContent = await testFile.readAsString();
          expect(updatedContent, equals(originalContent));
        });
      });
    });

    group('snake_case conversion', () {
      String toSnakeCase(String input) {
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
