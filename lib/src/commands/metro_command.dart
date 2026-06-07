import 'dart:io';

import 'package:nylo_installer/src/utils/process_runner.dart';

/// Command to run metro commands via dart run nylo_framework:main
class MetroCommand {
  Future<void> run(List<String> arguments) async {
    final result = await ProcessRunner.run('dart', [
      'run',
      'nylo_framework:main',
      ...arguments,
    ], inheritStdio: true);

    if (result.exitCode != 0) {
      exit(result.exitCode);
    }
  }
}
