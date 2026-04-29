import 'dart:convert';
import 'dart:io';

/// Result of a process execution
class ProcessResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  ProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });
}

/// Utility for running external processes
class ProcessRunner {
  /// Run a command and return the result
  static Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool inheritStdio = false,
  }) async {
    try {
      if (inheritStdio) {
        final process = await Process.start(
          executable,
          arguments,
          workingDirectory: workingDirectory,
          runInShell: Platform.isWindows,
          mode: ProcessStartMode.inheritStdio,
        );
        final exitCode = await process.exitCode;
        return ProcessResult(exitCode: exitCode, stdout: '', stderr: '');
      }

      final process = await Process.start(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        runInShell: Platform.isWindows,
      );

      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();

      await Future.wait([
        process.stdout.transform(utf8.decoder).forEach(stdoutBuffer.write),
        process.stderr.transform(utf8.decoder).forEach(stderrBuffer.write),
      ]);

      final exitCode = await process.exitCode;

      return ProcessResult(
        exitCode: exitCode,
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
      );
    } catch (e) {
      return ProcessResult(
        exitCode: 1,
        stdout: '',
        stderr: e.toString(),
      );
    }
  }
}
