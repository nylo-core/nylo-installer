import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// End-to-end tests that drive the real `nylo locale:*` dispatch via
/// `dart run bin/nylo.dart`, against a throwaway fixture project.
void main() {
  group('locale commands', () {
    late Directory fixture;

    setUp(() {
      fixture = Directory.systemTemp.createTempSync('nylo_locale_cli');
      Directory(
        p.join(fixture.path, 'lib', 'resources', 'pages'),
      ).createSync(recursive: true);
      Directory(
        p.join(fixture.path, 'lib', 'resources', 'widgets'),
      ).createSync(recursive: true);
      Directory(p.join(fixture.path, 'lib', 'app')).createSync(recursive: true);
      Directory(p.join(fixture.path, 'lang')).createSync();

      File(
        p.join(fixture.path, 'lib', 'resources', 'pages', 'page.dart'),
      ).writeAsStringSync('''
class HomePage {
  var routePath = "/home-route";
  build() {
    Text("Welcome to the app");
    Text("welcome".tr());
    Text(trans("settings"));
    Image.asset("assets/logo.png");
    routeTo("/home");
    ValueKey("homeCardKey");
    Text("Sign in to continue");
  }
}
''');
      // A widget under lib/resources/widgets is scanned too.
      File(
        p.join(fixture.path, 'lib', 'resources', 'widgets', 'badge.dart'),
      ).writeAsStringSync('''
class Badge {
  build() {
    Text("New widget label");
  }
}
''');
      // A file outside pages/widgets must be ignored by the default scan.
      File(p.join(fixture.path, 'lib', 'app', 'helper.dart')).writeAsStringSync(
        '''
class Helper {
  build() {
    Text("Should not be scanned");
  }
}
''',
      );
      File(p.join(fixture.path, 'lang', 'en.json')).writeAsStringSync(
        '{ "welcome": "Welcome", "settings": "Settings", '
        '"navigation": { "home": "Home", "profile": "Profile" } }',
      );
      File(p.join(fixture.path, 'lang', 'es.json')).writeAsStringSync(
        '{ "welcome": "Bienvenido", "navigation": { "home": "Inicio" }, '
        '"settings": "" }',
      );
    });

    tearDown(() => fixture.deleteSync(recursive: true));

    Future<ProcessResult> runNylo(List<String> args) =>
        Process.run('dart', ['run', 'bin/nylo.dart', ...args]);

    test(
      'find-untranslated --stdout reports findings only from pages/widgets',
      () async {
        final result = await runNylo([
          'locale:find-untranslated',
          '--path',
          fixture.path,
          '--stdout',
        ]);
        expect(result.exitCode, equals(0));
        final out = result.stdout as String;
        // Pages and widgets are scanned.
        expect(out, contains('Welcome to the app'));
        expect(out, contains('Sign in to continue'));
        expect(out, contains('New widget label'));
        // Translated / ignored strings must NOT appear.
        expect(out, isNot(contains('assets/logo.png')));
        // Only text-widget strings are flagged: route paths and widget keys
        // (not inside a Text/SelectableText/...) are out.
        expect(out, isNot(contains('/home-route')));
        expect(out, isNot(contains('homeCardKey')));
        // Files outside lib/resources/pages and /widgets are out of scope.
        expect(out, isNot(contains('Should not be scanned')));
      },
    );

    test('find-untranslated --ci exits 1 when findings exist', () async {
      final result = await runNylo([
        'locale:find-untranslated',
        '--path',
        fixture.path,
        '--ci',
        '--stdout',
      ]);
      expect(result.exitCode, equals(1));
    });

    test('check-missing-keys --stdout reports es missing/empty', () async {
      final result = await runNylo([
        'locale:check-missing-keys',
        '--path',
        fixture.path,
        '--stdout',
      ]);
      expect(result.exitCode, equals(0));
      final out = result.stdout as String;
      expect(out, contains('es'));
      expect(out, contains('navigation.profile'));
      expect(out, contains('settings'));
    });

    test(
      'check-missing-keys --ci exits 1 when a locale is incomplete',
      () async {
        final result = await runNylo([
          'locale:check-missing-keys',
          '--path',
          fixture.path,
          '--ci',
          '--stdout',
        ]);
        expect(result.exitCode, equals(1));
      },
    );

    test(
      'check-missing-keys reports a clean error for a missing baseline',
      () async {
        final result = await runNylo([
          'locale:check-missing-keys',
          '--path',
          fixture.path,
          '--file',
          'de.json',
          '--stdout',
        ]);
        expect(result.exitCode, equals(1));
        expect(result.stderr as String, contains('Baseline file not found'));
      },
    );

    test('help lists the locale commands', () async {
      final result = await runNylo(['--help']);
      expect(result.exitCode, equals(0));
      expect(result.stdout as String, contains('locale:find-untranslated'));
      expect(result.stdout as String, contains('locale:check-missing-keys'));
    });

    test('check-missing-keys -h prints command usage with options', () async {
      final result = await runNylo(['locale:check-missing-keys', '-h']);
      expect(result.exitCode, equals(0));
      final out = result.stdout as String;
      expect(out, contains('Usage: nylo locale:check-missing-keys'));
      expect(out, contains('--file'));
    });

    test(
      'find-untranslated --help prints command usage with options',
      () async {
        final result = await runNylo(['locale:find-untranslated', '--help']);
        expect(result.exitCode, equals(0));
        final out = result.stdout as String;
        expect(out, contains('Usage: nylo locale:find-untranslated'));
        expect(out, contains('--format'));
      },
    );

    test('check-missing-keys --strict --ci fails only on extra keys', () async {
      final dir = Directory.systemTemp.createTempSync('nylo_locale_strict');
      addTearDown(() => dir.deleteSync(recursive: true));
      Directory(p.join(dir.path, 'lang')).createSync();
      File(
        p.join(dir.path, 'lang', 'en.json'),
      ).writeAsStringSync('{"a": "A", "b": "B"}');
      // fr is complete but carries one extra key absent from the baseline.
      File(
        p.join(dir.path, 'lang', 'fr.json'),
      ).writeAsStringSync('{"a": "A", "b": "B", "c": "C"}');

      final lenient = await runNylo([
        'locale:check-missing-keys',
        '--path',
        dir.path,
        '--ci',
        '--stdout',
      ]);
      expect(
        lenient.exitCode,
        equals(0),
        reason: '--ci alone must ignore extra keys',
      );

      final strict = await runNylo([
        'locale:check-missing-keys',
        '--path',
        dir.path,
        '--ci',
        '--strict',
        '--stdout',
      ]);
      expect(
        strict.exitCode,
        equals(1),
        reason: '--strict must fail on the extra key',
      );
    });
  });
}
