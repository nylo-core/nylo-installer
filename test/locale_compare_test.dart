import 'dart:io';

import 'package:nylo_installer/nylo_installer.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory temp;
  late String langDir;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('nylo_i18n_test');
    langDir = p.join(temp.path, 'lang');
    Directory(langDir).createSync();
  });

  tearDown(() => temp.deleteSync(recursive: true));

  void writeLocale(String name, String json) {
    File(p.join(langDir, name)).writeAsStringSync(json);
  }

  test('flattens nested keys and detects missing/empty/extra', () {
    writeLocale('en.json', '''
{
  "welcome": "Welcome",
  "settings": "Settings",
  "navigation": { "home": "Home", "profile": "Profile" }
}
''');
    writeLocale('es.json', '''
{
  "welcome": "Bienvenido",
  "navigation": { "home": "Inicio" },
  "settings": ""
}
''');
    writeLocale('fr.json', '''
{
  "welcome": "Bienvenue",
  "settings": "Paramètres",
  "navigation": { "home": "Accueil", "profile": "Profil" },
  "extra": "x"
}
''');
    writeLocale('de.json', '''
{
  "welcome": "Willkommen",
  "settings": "Einstellungen",
  "navigation": { "home": "Startseite", "profile": "Profil" }
}
''');

    final comparator = LocaleComparator(langDir);
    final results = comparator.compareAgainst('en.json');

    final es = results.firstWhere((c) => c.locale == 'es');
    expect(es.missing, equals(['navigation.profile']));
    expect(es.empty, equals(['settings']));
    expect(es.extra, isEmpty);
    expect(es.isClean, isFalse);

    final fr = results.firstWhere((c) => c.locale == 'fr');
    expect(fr.missing, isEmpty);
    expect(fr.empty, isEmpty);
    expect(fr.extra, equals(['extra']));
    expect(fr.isClean, isTrue);
    // fr has an extra key: lenient-clean, but NOT strictly clean.
    expect(fr.isStrictlyClean, isFalse);

    // es has missing/empty: not clean under either rule.
    expect(es.isStrictlyClean, isFalse);

    // de mirrors the baseline exactly: clean under both rules.
    final de = results.firstWhere((c) => c.locale == 'de');
    expect(de.missing, isEmpty);
    expect(de.empty, isEmpty);
    expect(de.extra, isEmpty);
    expect(de.isClean, isTrue);
    expect(de.isStrictlyClean, isTrue);
  });

  test('throws on missing baseline file', () {
    writeLocale('en.json', '{"a": "b"}');
    final comparator = LocaleComparator(langDir);
    expect(
      () => comparator.compareAgainst('de.json'),
      throwsA(isA<LocaleException>()),
    );
  });

  test('throws on invalid JSON', () {
    writeLocale('en.json', '{ not valid json ');
    final comparator = LocaleComparator(langDir);
    expect(
      () => comparator.compareAgainst('en.json'),
      throwsA(isA<LocaleException>()),
    );
  });
}
