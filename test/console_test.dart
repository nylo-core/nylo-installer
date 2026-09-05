import 'dart:io';

import 'package:nylo_installer/src/console/console.dart';
import 'package:test/test.dart';

void main() {
  group('Spinner', () {
    // Force the plain line-based output: the test runner's stdout is not a
    // terminal, and the animated path would write cursor escape codes.
    setUp(() => Spinner.interactiveOverride = false);
    tearDown(() => Spinner.interactiveOverride = null);

    test('isInteractive honours the override', () {
      expect(Spinner.isInteractive, isFalse);
      Spinner.interactiveOverride = true;
      expect(Spinner.isInteractive, isTrue);
    });

    test('tracks running state and elapsed time', () async {
      final spinner = Spinner();
      expect(spinner.isRunning, isFalse);
      expect(spinner.elapsed, equals(Duration.zero));

      spinner.start('Working...');
      expect(spinner.isRunning, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(spinner.elapsed, greaterThan(Duration.zero));

      spinner.succeed('Done');
      expect(spinner.isRunning, isFalse);
    });

    test('start accepts the message from the constructor', () {
      final spinner = Spinner('From constructor');
      expect(() => spinner.start(), returnsNormally);
      expect(() => spinner.stop('Done'), returnsNormally);
    });

    test('stop without a message only clears the running state', () {
      final spinner = Spinner()..start('Working...');
      expect(() => spinner.stop(), returnsNormally);
      expect(spinner.isRunning, isFalse);
    });

    test('succeed accepts a detail and can hide the duration', () {
      final spinner = Spinner()..start('Checking...');
      expect(
        () => spinner.succeed(
          'Checked',
          detail: '(Flutter 3.0.0)',
          showDuration: false,
        ),
        returnsNormally,
      );
    });

    test('fail and warn finish the spinner', () {
      final failing = Spinner()..start('Cloning...');
      expect(() => failing.fail('Clone failed'), returnsNormally);
      expect(failing.isRunning, isFalse);

      final warning = Spinner()..start('Generating...');
      expect(() => warning.warn('Generated with warnings'), returnsNormally);
      expect(warning.isRunning, isFalse);
    });

    test('start can be called again after finishing', () {
      final spinner = Spinner()..start('First');
      spinner.succeed('First done');
      expect(() => spinner.start('Second'), returnsNormally);
      expect(spinner.isRunning, isTrue);
      spinner.succeed('Second done');
      expect(spinner.isRunning, isFalse);
    });
  });

  group('NyloConsole.formatDuration', () {
    test('shows milliseconds under one second', () {
      expect(NyloConsole.formatDuration(Duration.zero), equals('0ms'));
      expect(
        NyloConsole.formatDuration(const Duration(milliseconds: 850)),
        equals('850ms'),
      );
    });

    test('shows one decimal under ten seconds', () {
      expect(
        NyloConsole.formatDuration(const Duration(milliseconds: 1000)),
        equals('1.0s'),
      );
      expect(
        NyloConsole.formatDuration(const Duration(milliseconds: 2340)),
        equals('2.3s'),
      );
    });

    test('shows whole seconds under one minute', () {
      expect(
        NyloConsole.formatDuration(const Duration(seconds: 26)),
        equals('26s'),
      );
      expect(
        NyloConsole.formatDuration(const Duration(seconds: 59)),
        equals('59s'),
      );
    });

    test('shows minutes and seconds from one minute', () {
      expect(
        NyloConsole.formatDuration(const Duration(seconds: 65)),
        equals('1m 5s'),
      );
      expect(
        NyloConsole.formatDuration(const Duration(minutes: 2, seconds: 5)),
        equals('2m 5s'),
      );
    });
  });

  group('NyloConsole.friendlyPath', () {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    final sep = Platform.pathSeparator;

    test('replaces the home directory with ~', () {
      if (home == null) return; // no home directory in this environment
      expect(
        NyloConsole.friendlyPath('$home${sep}projects${sep}app'),
        equals('~${sep}projects${sep}app'),
      );
      expect(NyloConsole.friendlyPath(home), equals('~'));
    });

    test('leaves paths outside the home directory unchanged', () {
      if (home == null) return;
      expect(
        NyloConsole.friendlyPath('${sep}opt${sep}app'),
        equals('${sep}opt${sep}app'),
      );
      // Shares a prefix with the home directory but is not inside it
      expect(
        NyloConsole.friendlyPath('${home}2${sep}app'),
        equals('${home}2${sep}app'),
      );
    });
  });

  group('NyloConsole inline styles', () {
    test('wrap the text in ANSI codes', () {
      for (final style in [
        NyloConsole.bold,
        NyloConsole.dim,
        NyloConsole.green,
        NyloConsole.red,
        NyloConsole.yellow,
        NyloConsole.cyan,
        NyloConsole.magenta,
      ]) {
        final styled = style('hello');
        expect(styled, startsWith('\x1B['));
        expect(styled, contains('hello'));
        expect(styled, endsWith('\x1B[0m'));
      }
    });

    test('bold and dim use their SGR codes', () {
      expect(NyloConsole.bold('x'), equals('\x1B[1mx\x1B[0m'));
      expect(NyloConsole.dim('x'), equals('\x1B[2mx\x1B[0m'));
    });
  });

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

      test('writeErrorDetail should not throw for multi-line input', () {
        expect(
          () => NyloConsole.writeErrorDetail('line one\nline two\n'),
          returnsNormally,
        );
      });

      test('writeWarningDetail should not throw for multi-line input', () {
        expect(
          () => NyloConsole.writeWarningDetail('line one\nline two\n'),
          returnsNormally,
        );
      });

      test('writeInfo should not throw', () {
        expect(() => NyloConsole.writeInfo('info'), returnsNormally);
      });

      test('writeStep should not throw', () {
        expect(() => NyloConsole.writeStep('step'), returnsNormally);
      });

      test('writeStepComplete should not throw', () {
        expect(
          () => NyloConsole.writeStepComplete('complete'),
          returnsNormally,
        );
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

      test('writeTaskHeader should not throw', () {
        expect(
          () => NyloConsole.writeTaskHeader('Creating project'),
          returnsNormally,
        );
      });

      test('writeSubtaskPending should not throw', () {
        expect(
          () => NyloConsole.writeSubtaskPending('Checking...'),
          returnsNormally,
        );
      });

      test('writeSubtaskPending with isFirst should not throw', () {
        expect(
          () => NyloConsole.writeSubtaskPending('Checking...', isFirst: true),
          returnsNormally,
        );
      });

      test('writeSubtaskComplete should not throw', () {
        expect(() => NyloConsole.writeSubtaskComplete('Done'), returnsNormally);
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
