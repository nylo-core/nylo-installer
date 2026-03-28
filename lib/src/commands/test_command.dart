import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import '../console/console.dart';

/// Tracks a test that has started but not yet finished
class _TestInfo {
  final String name;
  final int suiteId;
  final int startTime;

  _TestInfo({
    required this.name,
    required this.suiteId,
    required this.startTime,
  });
}

/// Result of a single individual test case
class _IndividualTestResult {
  final String suitePath;
  final String testName;
  final Duration duration;
  final bool passed;
  final String? errorMessage;

  _IndividualTestResult({
    required this.suitePath,
    required this.testName,
    required this.duration,
    required this.passed,
    this.errorMessage,
  });
}

/// Handles the "nylo test" command
/// Formats and runs Flutter test files with pretty output
class TestCommand {
  /// Execute the test command
  Future<void> run([List<String> arguments = const []]) async {
    final parser = ArgParser()
      ..addFlag('format',
          defaultsTo: true,
          help: 'Format test files before running (use --no-format to skip)')
      ..addOption('filter',
          abbr: 'f', help: 'Filter tests by name pattern', valueHelp: 'pattern')
      ..addFlag('coverage', negatable: false, help: 'Collect code coverage')
      ..addOption('path', help: 'Test directory path', defaultsTo: 'test');

    final ArgResults results;
    try {
      results = parser.parse(arguments);
    } on FormatException catch (e) {
      NyloConsole.writeError(e.message);
      exit(1);
    }

    final bool shouldFormat = results['format'] as bool;
    final String? filter = results['filter'] as String?;
    final bool coverage = results['coverage'] as bool;
    final String testPath = results['path'] as String;

    // Validate test directory exists
    if (!await Directory(testPath).exists()) {
      NyloConsole.writeError(
          '$testPath/ directory not found. Are you in a Flutter project?');
      exit(1);
    }

    NyloConsole.writeBanner();
    NyloConsole.write('');
    NyloConsole.writeInfo('Running tests...');
    NyloConsole.write('');

    // Format test files
    if (shouldFormat) {
      final formatSpinner = Spinner('');
      formatSpinner.start('Formatting test files...');
      final formatResult = await Process.run('dart', ['format', testPath]);
      if (formatResult.exitCode != 0) {
        formatSpinner.stop('Formatting completed with warnings');
        NyloConsole.writeWarning(formatResult.stderr as String);
      } else {
        formatSpinner.stop('Test files formatted');
      }
    }

    // Run tests
    final args = <String>['test', '--reporter', 'json'];
    if (filter != null) args.addAll(['--name', filter]);
    if (coverage) args.add('--coverage');
    args.add(testPath);

    NyloConsole.writeStep('Running tests...');
    NyloConsole.write('');

    final process = await Process.start(
      'flutter',
      args,
      runInShell: Platform.isWindows,
    );

    final suites = <int, String>{};
    final tests = <int, _TestInfo>{};
    final testErrors = <int, String>{};
    final allResults = <_IndividualTestResult>[];
    final rawOutput = StringBuffer();
    final stderrBuffer = StringBuffer();

    await Future.wait([
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach((line) {
        rawOutput.writeln(line);
        final result = _processJsonLine(line, suites, tests, testErrors);
        if (result != null) {
          allResults.add(result);
          _printTestResult(result);
        }
      }),
      process.stderr.transform(utf8.decoder).forEach((data) {
        stderrBuffer.write(data);
      }),
    ]);

    final exitCode = await process.exitCode;

    // Fallback: if JSON parsing yielded no results, show raw output
    if (allResults.isEmpty && rawOutput.isNotEmpty) {
      NyloConsole.write(rawOutput.toString());
    }

    _printSummary(allResults);

    if (exitCode != 0) {
      exit(1);
    }
  }

  /// Process a single JSON line from the test reporter
  /// Returns an [_IndividualTestResult] if this line completes a test
  _IndividualTestResult? _processJsonLine(
    String line,
    Map<int, String> suites,
    Map<int, _TestInfo> tests,
    Map<int, String> testErrors,
  ) {
    if (line.trim().isEmpty) return null;

    final Map<String, dynamic> event;
    try {
      event = jsonDecode(line) as Map<String, dynamic>;
    } catch (_) {
      return null; // Skip non-JSON lines
    }

    final type = event['type'] as String?;

    switch (type) {
      case 'suite':
        final suite = event['suite'] as Map<String, dynamic>;
        final id = suite['id'] as int;
        final suitePath = suite['path'] as String? ?? '';
        suites[id] = suitePath;
        break;

      case 'testStart':
        final test = event['test'] as Map<String, dynamic>;
        final id = test['id'] as int;
        final name = test['name'] as String;
        final suiteId = test['suiteID'] as int;
        final time = event['time'] as int;
        tests[id] = _TestInfo(name: name, suiteId: suiteId, startTime: time);
        break;

      case 'error':
        final testId = event['testID'] as int;
        final error = event['error'] as String? ?? '';
        testErrors[testId] = error;
        break;

      case 'testDone':
        final testId = event['testID'] as int;
        final hidden = event['hidden'] as bool? ?? false;
        if (hidden) break; // Skip internal loading tests

        final testInfo = tests[testId];
        if (testInfo == null) break;

        final result = event['result'] as String;
        final endTime = event['time'] as int;
        final duration = Duration(milliseconds: endTime - testInfo.startTime);
        final suitePath = suites[testInfo.suiteId] ?? '';
        final passed = result == 'success';

        return _IndividualTestResult(
          suitePath: suitePath,
          testName: testInfo.name,
          duration: duration,
          passed: passed,
          errorMessage: testErrors[testId],
        );
    }

    return null;
  }

  /// Print a formatted test result line
  void _printTestResult(_IndividualTestResult result) {
    final termWidth = _getTerminalWidth();
    final durationStr = _formatTestDuration(result.duration);
    final suitePath = path.relative(result.suitePath);
    final testName = result.testName;

    // Build visible label (no ANSI) for width calculations
    final visibleLabel = '$suitePath > $testName';
    final prefixLen = 4; // "  ✓ " or "  ✗ "
    final availableWidth = termWidth - prefixLen - durationStr.length - 1;

    // Truncate if too long
    String displayVisible;
    if (availableWidth > 3 && visibleLabel.length > availableWidth) {
      displayVisible = '${visibleLabel.substring(0, availableWidth - 1)}\u2026';
    } else {
      displayVisible = visibleLabel;
    }

    // Pad for right-aligned duration
    final padLen =
        termWidth - prefixLen - displayVisible.length - durationStr.length;
    final pad = padLen > 0 ? ' ' * padLen : ' ';

    // Add ANSI color to the ">" separator
    String ansiLabel;
    if (displayVisible.length > suitePath.length + 3) {
      final testPart = displayVisible.substring(suitePath.length + 3);
      ansiLabel = '$suitePath \x1B[90m>\x1B[0m $testPart';
    } else {
      ansiLabel = displayVisible;
    }

    final icon =
        result.passed ? '\x1B[92m\u2713\x1B[0m' : '\x1B[91m\u2717\x1B[0m';
    final coloredDuration = _colorDuration(result.duration, durationStr);

    stdout.writeln('  $icon $ansiLabel$pad$coloredDuration');
  }

  /// Print aggregated test summary
  void _printSummary(List<_IndividualTestResult> results) {
    final passed = results.where((r) => r.passed).length;
    final failed = results.where((r) => !r.passed).length;
    final total = results.length;

    NyloConsole.write('');
    NyloConsole.write('  ${'─' * 50}');
    NyloConsole.write('');

    // Print failure details
    if (failed > 0) {
      NyloConsole.writeError('Failed tests:');
      NyloConsole.write('');
      for (final r in results.where((r) => !r.passed)) {
        final suitePath = path.relative(r.suitePath);
        NyloConsole.writeError('  $suitePath > ${r.testName}');
        if (r.errorMessage != null && r.errorMessage!.trim().isNotEmpty) {
          final cleanError = _stripAnsiCodes(r.errorMessage!);
          for (final errorLine in cleanError.split('\n')) {
            if (errorLine.trim().isNotEmpty) {
              NyloConsole.write('    $errorLine');
            }
          }
        }
        NyloConsole.write('');
      }
    }

    final summary = 'Tests: $passed passed, $failed failed, $total total';
    final totalTime = results.fold<Duration>(
      Duration.zero,
      (sum, r) => sum + r.duration,
    );
    final time = 'Time:  ${_formatDuration(totalTime)}';

    if (failed > 0) {
      stdout.writeln('\x1B[91m  \u2717 $summary\x1B[0m');
      stdout.writeln('\x1B[91m    $time\x1B[0m');
    } else {
      NyloConsole.writeStepComplete(summary);
      NyloConsole.write('    $time');
    }
  }

  /// Color a duration string based on speed
  String _colorDuration(Duration duration, String text) {
    if (duration.inMilliseconds >= 2000) {
      return '\x1B[91m$text\x1B[0m'; // bright red for slow
    }
    return '\x1B[93m$text\x1B[0m'; // yellow for normal
  }

  /// Format duration for per-test display (always 2 decimal places)
  String _formatTestDuration(Duration duration) {
    final seconds = duration.inMilliseconds / 1000;
    return '${seconds.toStringAsFixed(2)}s';
  }

  /// Format duration for summary display
  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    }
    if (duration.inSeconds > 0) {
      final ms = duration.inMilliseconds.remainder(1000);
      return '${duration.inSeconds}.${(ms ~/ 100)}s';
    }
    return '${duration.inMilliseconds}ms';
  }

  /// Strip ANSI escape codes and their literal representations from text
  String _stripAnsiCodes(String text) {
    // Strip actual ANSI escape sequences (byte 0x1B)
    text = text.replaceAll(RegExp('\x1B\\[[0-9;]*m'), '');
    // Strip literal \x1B representations (from test matcher output)
    text = text.replaceAll(RegExp(r'\\x1B\[[0-9;]*m'), '');
    return text;
  }

  /// Get terminal width, defaulting to 80
  int _getTerminalWidth() {
    try {
      return stdout.terminalColumns;
    } catch (_) {
      return 80;
    }
  }
}
