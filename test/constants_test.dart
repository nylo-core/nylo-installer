import 'package:nylo_installer/src/constants.dart';
import 'package:test/test.dart';

void main() {
  group('Constants', () {
    test('templateRepoUrl should be a valid GitHub URL', () {
      expect(Constants.templateRepoUrl, startsWith('https://github.com/'));
      expect(Constants.templateRepoUrl, contains('nylo'));
    });

    test('version should follow semantic versioning format', () {
      final semverPattern = RegExp(r'^\d+\.\d+\.\d+$');
      expect(semverPattern.hasMatch(Constants.version), isTrue);
    });

    test('docsUrl should be a valid HTTPS URL', () {
      expect(Constants.docsUrl, startsWith('https://'));
      expect(Uri.tryParse(Constants.docsUrl)?.hasAbsolutePath, isTrue);
    });
  });
}
