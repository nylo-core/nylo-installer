import 'dart:async';
import 'dart:io';

/// Animated spinner for long-running operations
class Spinner {
  static const _frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
  Timer? _timer;
  int _frameIndex = 0;
  String _message;

  Spinner(this._message);

  /// Start the spinner animation
  void start(String message) {
    _message = message;
    _frameIndex = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      stdout.write('\r\x1B[96m  ${_frames[_frameIndex]} $_message\x1B[0m');
      _frameIndex = (_frameIndex + 1) % _frames.length;
    });
  }

  /// Stop the spinner and show optional completion message
  void stop([String? completionMessage]) {
    _timer?.cancel();
    _timer = null;
    stdout.write('\r\x1B[K'); // Clear the line
    if (completionMessage != null) {
      stdout.writeln('\x1B[92m  ✓ $completionMessage\x1B[0m');
    }
  }
}

/// Console output styling for the Nylo installer
class NyloConsole {
  // ANSI escape codes
  static const String _reset = '\x1B[0m';
  static const String _bold = '\x1B[1m';

  // Colors (using bright variants for better visibility)
  static const String _green = '\x1B[92m';
  static const String _red = '\x1B[91m';
  static const String _yellow = '\x1B[93m';
  static const String _cyan = '\x1B[96m';
  static const String _blue = '\x1B[94m';
  static const String _magenta = '\x1B[95m';

  /// Write a plain message
  static void write(String message) {
    stdout.writeln(message);
  }

  /// Write without newline
  static void writeInline(String message) {
    stdout.write(message);
  }

  /// Write a success message (green)
  static void writeSuccess(String message) {
    stdout.writeln('$_green$_bold[SUCCESS]$_reset $_green$message$_reset');
  }

  /// Write an error message (red)
  static void writeError(String message) {
    stderr.writeln('$_red$_bold[ERROR]$_reset $_red$message$_reset');
  }

  /// Write a warning message (yellow)
  static void writeWarning(String message) {
    stdout.writeln('$_yellow$_bold[WARNING]$_reset $_yellow$message$_reset');
  }

  /// Write an info message (cyan)
  static void writeInfo(String message) {
    stdout.writeln('$_cyan$message$_reset');
  }

  /// Write a step/progress message (blue)
  static void writeStep(String message) {
    stdout.writeln('$_blue  > $message$_reset');
  }

  /// Write a completed step (green with checkmark)
  static void writeStepComplete(String message) {
    stdout.writeln('$_green  ✓ $message$_reset');
  }

  /// Write the main task header (filled bullet)
  static void writeTaskHeader(String message) {
    stdout.writeln('$_yellow● $message$_reset');
  }

  /// Write a pending subtask (empty checkbox with tree connector)
  static void writeSubtaskPending(String message, {bool isFirst = false}) {
    final prefix = isFirst ? '├ □' : '  □';
    stdout.writeln('$_cyan$prefix $message$_reset');
  }

  /// Write a completed subtask (checkmark)
  static void writeSubtaskComplete(String message) {
    stdout.writeln('$_green  ✓ $message$_reset');
  }

  /// Write highlighted text (magenta - for commands)
  static void writeHighlight(String message) {
    stdout.writeln('$_magenta$message$_reset');
  }

  /// Write bold text
  static void writeBold(String message) {
    stdout.writeln('$_bold$message$_reset');
  }

  /// Print the Nylo banner
  static void writeBanner() {
    stdout.writeln('''
$_cyan$_bold
    _   __      __
   / | / /_  __/ /___
  /  |/ / / / / / __ \\
 / /|  / /_/ / / /_/ /
/_/ |_/\\__, /_/\\____/
      /____/
$_reset''');
  }
}
