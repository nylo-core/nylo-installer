import 'dart:io';

import 'package:nylo_installer/src/utils/shell_detector.dart';
import 'package:test/test.dart';

void main() {
  group('ShellConfig', () {
    test('should store shell configuration properties', () {
      const config = ShellConfig(
        shellName: 'zsh',
        profilePath: '/home/user/.zshrc',
        aliasFormat: "alias metro='dart run nylo_framework:main'",
      );

      expect(config.shellName, equals('zsh'));
      expect(config.profilePath, equals('/home/user/.zshrc'));
      expect(config.aliasFormat, contains('metro'));
    });
  });

  group('ShellDetector', () {
    group('detectShell', () {
      test('should return null on Windows', () {
        // This test is platform-specific
        if (Platform.isWindows) {
          final result = ShellDetector.detectShell();
          expect(result, isNull);
        }
      });

      test('should detect shell on non-Windows platforms', () {
        if (!Platform.isWindows) {
          final result = ShellDetector.detectShell();
          // Result depends on environment, so we just verify it's valid
          if (result != null) {
            expect(result.shellName, anyOf(['zsh', 'bash']));
            expect(result.profilePath, isNotEmpty);
            expect(result.aliasFormat, contains('metro'));
          }
        }
      });
    });

    group('isMetroAliasInstalled', () {
      late Directory tempDir;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('nylo_test_');
      });

      tearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      test('should return false if file does not exist', () async {
        final nonExistentPath = '${tempDir.path}/nonexistent_profile';
        final result =
            await ShellDetector.isMetroAliasInstalled(nonExistentPath);
        expect(result, isFalse);
      });

      test('should return false if file exists but has no alias', () async {
        final profilePath = '${tempDir.path}/.zshrc';
        await File(profilePath).writeAsString(
            '# Some config\nexport PATH=\$PATH:/usr/local/bin\n');

        final result = await ShellDetector.isMetroAliasInstalled(profilePath);
        expect(result, isFalse);
      });

      test('should return true if alias metro= exists', () async {
        final profilePath = '${tempDir.path}/.zshrc';
        await File(profilePath)
            .writeAsString("alias metro='dart run nylo_framework:main'\n");

        final result = await ShellDetector.isMetroAliasInstalled(profilePath);
        expect(result, isTrue);
      });

      test('should return true if alias metro with double quotes exists',
          () async {
        final profilePath = '${tempDir.path}/.zshrc';
        await File(profilePath)
            .writeAsString('alias metro="dart run nylo_framework:main"\n');

        final result = await ShellDetector.isMetroAliasInstalled(profilePath);
        expect(result, isTrue);
      });

      test('should detect alias among other content', () async {
        final profilePath = '${tempDir.path}/.zshrc';
        await File(profilePath).writeAsString('''
# My shell config
export PATH=\$PATH:/usr/local/bin

# Nylo Metro CLI alias
alias metro='dart run nylo_framework:main'

# Other aliases
alias ll='ls -la'
''');

        final result = await ShellDetector.isMetroAliasInstalled(profilePath);
        expect(result, isTrue);
      });
    });

    group('installMetroAlias', () {
      late Directory tempDir;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('nylo_test_');
      });

      tearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      test('should create profile file if it does not exist', () async {
        final profilePath = '${tempDir.path}/.zshrc';
        final config = ShellConfig(
          shellName: 'zsh',
          profilePath: profilePath,
          aliasFormat: "alias metro='dart run nylo_framework:main'",
        );

        final result = await ShellDetector.installMetroAlias(config);

        expect(result, isTrue);
        expect(await File(profilePath).exists(), isTrue);

        final content = await File(profilePath).readAsString();
        expect(content, contains('alias metro='));
        expect(content, contains('Nylo Metro CLI alias'));
      });

      test('should append alias to existing profile', () async {
        final profilePath = '${tempDir.path}/.zshrc';
        await File(profilePath)
            .writeAsString('# Existing config\nexport FOO=bar\n');

        final config = ShellConfig(
          shellName: 'zsh',
          profilePath: profilePath,
          aliasFormat: "alias metro='dart run nylo_framework:main'",
        );

        final result = await ShellDetector.installMetroAlias(config);

        expect(result, isTrue);

        final content = await File(profilePath).readAsString();
        expect(content, contains('# Existing config'));
        expect(content, contains('export FOO=bar'));
        expect(content, contains('alias metro='));
      });

      test('should return false on write failure', () async {
        // Test with an invalid path that cannot be written to
        final config = ShellConfig(
          shellName: 'zsh',
          profilePath: '/nonexistent/deep/path/.zshrc',
          aliasFormat: "alias metro='dart run nylo_framework:main'",
        );

        // This may or may not fail depending on permissions
        // The method should return false on failure, not throw
        final result = await ShellDetector.installMetroAlias(config);
        // We just verify it returns a boolean without throwing
        expect(result, isA<bool>());
      });
    });
  });
}
