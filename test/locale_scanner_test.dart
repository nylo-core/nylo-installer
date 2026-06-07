import 'dart:io';

import 'package:nylo_installer/nylo_installer.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('nylo_scan_test');
  });

  tearDown(() => temp.deleteSync(recursive: true));

  List<Finding> scanSource(String dart) {
    final file = File(p.join(temp.path, 'page.dart'))..writeAsStringSync(dart);
    final config = AuditConfig(projectRoot: temp.path);
    return StringScanner(config).scanFile(file);
  }

  test('flags hardcoded user-facing text', () {
    final findings = scanSource('''
class P {
  build() {
    return Text("Welcome to the app");
  }
}
''');
    expect(findings, hasLength(1));
    expect(findings.single.value, 'Welcome to the app');
    // Dart strips the leading newline after `'''`, so the string sits on
    // line 3 (not 4). Verified by the scanner and the end-to-end smoke test.
    expect(findings.single.line, 3);
  });

  test('ignores .tr() and trans() calls', () {
    final findings = scanSource('''
class P {
  build() {
    Text("welcome".tr());
    Text(trans("settings"));
    Text("navigation.home".tr());
  }
}
''');
    expect(findings, isEmpty);
  });

  test('ignores assets, urls, hex, and const-style strings', () {
    final findings = scanSource('''
class P {
  build() {
    Image.asset("assets/logo.png");
    var url = "https://example.com";
    var color = "#FFAABB";
    var code = "MAX_RETRIES";
  }
}
''');
    expect(findings, isEmpty);
  });

  test('ignores key-like identifiers', () {
    final findings = scanSource('''
class P {
  build() {
    Text("nav.profile");
    Text("sign_in_button");
  }
}
''');
    expect(findings, isEmpty);
  });

  test('respects i18n-ignore marker', () {
    final findings = scanSource('''
class P {
  build() {
    // i18n-ignore
    Text("Deliberately hardcoded");
    Text("This one is flagged");
  }
}
''');
    expect(findings, hasLength(1));
    expect(findings.single.value, 'This one is flagged');
  });

  test('ignore marker must lead the comment, not just appear in it', () {
    final findings = scanSource('''
class P {
  build() {
    // see the i18n-ignore docs for details
    Text("Still flagged despite the mention");
    // i18n-ignore: not translated yet
    Text("Suppressed with a reason");
  }
}
''');
    // Prose that merely mentions the marker must NOT suppress the next line;
    // a leading marker (even with a trailing `: reason`) must.
    expect(findings, hasLength(1));
    expect(findings.single.value, 'Still flagged despite the mention');
  });

  test('ignores bare maps and imports; flags only text inside a widget', () {
    final findings = scanSource('''
import "package:flutter/material.dart";
class P {
  build() {
    var m = {"home_key": "Home value shown"};
    return Text("Visible label");
  }
}
''');
    final values = findings.map((f) => f.value);
    // Only the string inside Text() is user-facing copy; the bare map (key and
    // value) and the import URI are not.
    expect(values, contains('Visible label'));
    expect(values, isNot(contains('home_key')));
    expect(values, isNot(contains('Home value shown')));
  });

  test('flags other text widgets (SelectableText, TextSpan)', () {
    final findings = scanSource('''
class P {
  build() {
    SelectableText("Tap to copy");
    TextSpan(text: "Rich label");
  }
}
''');
    expect(
      findings.map((f) => f.value),
      containsAll(['Tap to copy', 'Rich label']),
    );
  });

  test('ignores strings in non-text widgets, data ctors, routes', () {
    final findings = scanSource('''
class P {
  build() {
    ValueKey("home_card");
    ExerciseOption(label: "annyeonghaseyo");
    var path = "/profile-page";
    routeTo("/settings");
  }
}
''');
    expect(findings, isEmpty);
  });

  test('ignores map-lookup keys even inside a text widget', () {
    final findings = scanSource('''
class P {
  build() {
    Text(currentWord["translation"] ?? "");
    Text(labels["Greeting Text"]);
  }
}
''');
    // The bracketed strings are map keys; the displayed value is dynamic.
    expect(findings, isEmpty);
  });

  test('still filters keys and urls even inside a text widget', () {
    final findings = scanSource('''
class P {
  build() {
    Text("https://example.com");
    Text("nav.profile");
  }
}
''');
    expect(findings, isEmpty);
  });

  test('honors a custom text widget from config', () {
    final file = File(p.join(temp.path, 'page.dart'))
      ..writeAsStringSync('''
class P {
  build() {
    AppHeading("Welcome home");
    Text("Plain label");
  }
}
''');
    final config = AuditConfig(
      projectRoot: temp.path,
      textWidgets: const {'Text', 'AppHeading'},
    );
    final findings = StringScanner(config).scanFile(file);
    expect(
      findings.map((f) => f.value),
      containsAll(['Welcome home', 'Plain label']),
    );
  });
}
