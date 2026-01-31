import 'dart:io';

import '../console/console.dart';

/// Utilities for prompting user input
class Prompt {
  /// Ask a yes/no confirmation question.
  ///
  /// Returns true if user answers yes, false otherwise.
  /// [defaultYes] determines the default if user presses Enter.
  static bool confirm(String question, {bool defaultYes = true}) {
    final defaultHint = defaultYes ? '[Y/n]' : '[y/N]';
    NyloConsole.writeInline('$question $defaultHint ');

    final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';

    if (input.isEmpty) {
      return defaultYes;
    }

    return input == 'y' || input == 'yes';
  }
}
