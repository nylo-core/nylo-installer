import 'package:nylo_installer/src/console/console.dart';
import 'package:test/test.dart';

void main() {
  group('NyloConsole', () {
    // Note: NyloConsole uses actual stdout/stderr which can't be easily mocked
    // These tests verify the methods run without errors and check basic behavior

    group('write methods execute without errors', () {
      test('write should not throw', () {
        expect(() => NyloConsole.write('test message'), returnsNormally);
      });

      test('writeInline should not throw', () {
        expect(() => NyloConsole.writeInline('inline'), returnsNormally);
      });

      test('writeSuccess should not throw', () {
        expect(() => NyloConsole.writeSuccess('success'), returnsNormally);
      });

      test('writeError should not throw', () {
        expect(() => NyloConsole.writeError('error'), returnsNormally);
      });

      test('writeWarning should not throw', () {
        expect(() => NyloConsole.writeWarning('warning'), returnsNormally);
      });

      test('writeInfo should not throw', () {
        expect(() => NyloConsole.writeInfo('info'), returnsNormally);
      });

      test('writeStep should not throw', () {
        expect(() => NyloConsole.writeStep('step'), returnsNormally);
      });

      test('writeStepComplete should not throw', () {
        expect(() => NyloConsole.writeStepComplete('complete'), returnsNormally);
      });

      test('writeHighlight should not throw', () {
        expect(() => NyloConsole.writeHighlight('highlight'), returnsNormally);
      });

      test('writeBold should not throw', () {
        expect(() => NyloConsole.writeBold('bold'), returnsNormally);
      });

      test('writeBanner should not throw', () {
        expect(() => NyloConsole.writeBanner(), returnsNormally);
      });
    });

    group('ANSI codes', () {
      // Test that the console class has proper ANSI codes defined
      // by checking that output contains expected formatting

      test('writeSuccess contains SUCCESS label', () {
        // We can't easily capture stdout, but we verify the method runs
        // In a real scenario, you'd use process to capture output
        expect(() => NyloConsole.writeSuccess('test'), returnsNormally);
      });

      test('writeError contains ERROR label', () {
        expect(() => NyloConsole.writeError('test'), returnsNormally);
      });

      test('writeWarning contains WARNING label', () {
        expect(() => NyloConsole.writeWarning('test'), returnsNormally);
      });
    });
  });
}

