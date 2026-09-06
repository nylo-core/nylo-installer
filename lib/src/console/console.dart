import 'dart:async';
import 'dart:io';

import '../constants.dart';

/// ANSI escape sequences shared by [Spinner] and [NyloConsole].
class _Ansi {
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';

  // Colors (bright variants for better visibility)
  static const String green = '\x1B[92m';
  static const String red = '\x1B[91m';
  static const String yellow = '\x1B[93m';
  static const String cyan = '\x1B[96m';
  static const String blue = '\x1B[94m';
  static const String magenta = '\x1B[95m';

  static const String clearLine = '\r\x1B[K';
  static const String hideCursor = '\x1B[?25l';
  static const String showCursor = '\x1B[?25h';
}

/// Animated progress indicator for a single long-running step.
///
/// In an interactive terminal the spinner animates in place, hides the cursor
/// while it runs, and shows the elapsed time once a step has taken more than a
/// couple of seconds. When stdout is not a terminal (CI, piped output, or a
/// console without ANSI support) it degrades to plain line-based output so
/// logs stay readable.
///
/// ```dart
/// final spinner = Spinner()..start('Cloning template...');
/// // ... do the work ...
/// spinner.succeed('Template cloned'); // prints: ✓ Template cloned (2.8s)
/// ```
class Spinner {
  static const _frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
  static const _frameInterval = Duration(milliseconds: 80);

  /// The running line starts showing its elapsed time after this long.
  static const _showElapsedAfter = Duration(seconds: 2);

  /// A completed line shows its duration when the step took at least this long.
  static const _showDurationAfter = Duration(seconds: 1);

  /// Overrides terminal detection. Set to `false` (e.g. in tests) to force the
  /// plain line-based output; leave `null` to auto-detect.
  static bool? interactiveOverride;

  /// Whether the spinner can animate in place on the current stdout.
  static bool get isInteractive =>
      interactiveOverride ?? (stdout.hasTerminal && stdout.supportsAnsiEscapes);

  static bool _cursorHidden = false;
  static StreamSubscription<ProcessSignal>? _sigintSubscription;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  int _frameIndex = 0;
  String _message;

  Spinner([this._message = '']);

  /// Whether [start] has been called and the spinner has not finished yet.
  bool get isRunning => _stopwatch.isRunning;

  /// Time since [start] was called.
  Duration get elapsed => _stopwatch.elapsed;

  /// Start the spinner, optionally replacing the message.
  void start([String? message]) {
    if (message != null) _message = message;
    _timer?.cancel();
    _frameIndex = 0;
    _stopwatch
      ..reset()
      ..start();

    if (!isInteractive) {
      stdout.writeln('${_Ansi.cyan}  > $_message${_Ansi.reset}');
      return;
    }

    _hideCursor();
    _renderFrame();
    _timer = Timer.periodic(_frameInterval, (_) => _renderFrame());
  }

  /// Stop the spinner. With a [completionMessage] this behaves like
  /// [succeed]; without one the running line is simply cleared.
  void stop([String? completionMessage]) {
    _finish(_Ansi.green, '✓', completionMessage);
  }

  /// Stop the spinner and print a completed (✓) line.
  ///
  /// [detail] is appended dimmed after the message (e.g. detected versions).
  /// The step duration is appended when it is worth showing, unless
  /// [showDuration] is `false`.
  void succeed(String message, {String? detail, bool showDuration = true}) {
    _finish(
      _Ansi.green,
      '✓',
      message,
      detail: detail,
      showDuration: showDuration,
    );
  }

  /// Stop the spinner and print a failed (✗) line.
  void fail(String message, {bool showDuration = true}) {
    _finish(_Ansi.red, '✗', message, showDuration: showDuration);
  }

  /// Stop the spinner and print a completed-with-warnings (!) line.
  void warn(String message, {bool showDuration = true}) {
    _finish(_Ansi.yellow, '!', message, showDuration: showDuration);
  }

  void _finish(
    String color,
    String symbol,
    String? message, {
    String? detail,
    bool showDuration = true,
  }) {
    _stopwatch.stop();
    _timer?.cancel();
    _timer = null;

    if (isInteractive) {
      stdout.write(_Ansi.clearLine);
      _showCursor();
    }

    if (message == null) return;

    final line = StringBuffer('$color  $symbol $message${_Ansi.reset}');
    if (detail != null) {
      line.write(' ${_Ansi.dim}$detail${_Ansi.reset}');
    }
    if (showDuration && _stopwatch.elapsed >= _showDurationAfter) {
      final duration = NyloConsole.formatDuration(_stopwatch.elapsed);
      line.write(' ${_Ansi.dim}($duration)${_Ansi.reset}');
    }
    stdout.writeln(line);
  }

  void _renderFrame() {
    final frame = _frames[_frameIndex];
    _frameIndex = (_frameIndex + 1) % _frames.length;

    final line = StringBuffer(
      '${_Ansi.clearLine}${_Ansi.cyan}  $frame $_message${_Ansi.reset}',
    );
    final elapsed = _stopwatch.elapsed;
    if (elapsed >= _showElapsedAfter) {
      line.write(' ${_Ansi.dim}${elapsed.inSeconds}s${_Ansi.reset}');
    }
    stdout.write(line);
  }

  static void _hideCursor() {
    if (_cursorHidden) return;
    _cursorHidden = true;
    stdout.write(_Ansi.hideCursor);
    _sigintSubscription ??= _watchSigint();
  }

  static void _showCursor() {
    if (!_cursorHidden) return;
    _cursorHidden = false;
    stdout.write(_Ansi.showCursor);
    // Drop the signal watcher: an open subscription would keep the process
    // alive after the command finishes.
    _sigintSubscription?.cancel();
    _sigintSubscription = null;
  }

  /// Restores the cursor if the user interrupts (Ctrl+C) mid-animation, so the
  /// terminal is not left without a cursor, and moves to a fresh line so the
  /// shell prompt does not appear after the spinner. Listening to SIGINT
  /// replaces the default handler, so the process has to exit itself.
  static StreamSubscription<ProcessSignal>? _watchSigint() {
    try {
      return ProcessSignal.sigint.watch().listen((_) {
        _showCursor();
        stdout.writeln();
        exit(130);
      });
    } on SignalException {
      return null;
    }
  }
}

/// Console output styling for the Nylo installer
class NyloConsole {
  // ANSI escape codes
  static const String _reset = _Ansi.reset;
  static const String _bold = _Ansi.bold;
  static const String _dim = _Ansi.dim;

  // Colors (using bright variants for better visibility)
  static const String _green = _Ansi.green;
  static const String _red = _Ansi.red;
  static const String _yellow = _Ansi.yellow;
  static const String _cyan = _Ansi.cyan;
  static const String _blue = _Ansi.blue;
  static const String _magenta = _Ansi.magenta;

  // ---------------------------------------------------------------------------
  // Inline styles: wrap text so callers can compose a line from several styles
  // ---------------------------------------------------------------------------

  /// Bold [text]
  static String bold(String text) => '$_bold$text$_reset';

  /// Dimmed [text] (secondary information such as paths or durations)
  static String dim(String text) => '$_dim$text$_reset';

  /// Green [text]
  static String green(String text) => '$_green$text$_reset';

  /// Red [text]
  static String red(String text) => '$_red$text$_reset';

  /// Yellow [text]
  static String yellow(String text) => '$_yellow$text$_reset';

  /// Cyan [text]
  static String cyan(String text) => '$_cyan$text$_reset';

  /// Magenta [text] (used for commands the user should run)
  static String magenta(String text) => '$_magenta$text$_reset';

  // ---------------------------------------------------------------------------
  // Formatting helpers
  // ---------------------------------------------------------------------------

  /// Formats a [duration] for display: `850ms`, `2.8s`, `26s`, `1m 5s`.
  static String formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    }
    if (duration.inSeconds < 10) {
      return '${(duration.inMilliseconds / 1000).toStringAsFixed(1)}s';
    }
    if (duration.inMinutes < 1) {
      return '${duration.inSeconds}s';
    }
    final seconds = duration.inSeconds % 60;
    return '${duration.inMinutes}m ${seconds}s';
  }

  /// Shortens [path] for display by replacing the user's home directory
  /// with `~`. Paths outside the home directory are returned unchanged.
  static String friendlyPath(String path) {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null || home.isEmpty) return path;
    if (path == home) return '~';
    final separator = Platform.pathSeparator;
    final prefix = home.endsWith(separator) ? home : '$home$separator';
    if (path.startsWith(prefix)) {
      return '~$separator${path.substring(prefix.length)}';
    }
    return path;
  }

  // ---------------------------------------------------------------------------
  // Line writers
  // ---------------------------------------------------------------------------

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

  /// Write the closing line of a command that finished successfully
  /// (`Success! <message>`), indented to line up with the step list above it.
  static void writeSuccessLine(String message) {
    stdout.writeln('  ${green(bold('Success!'))} $message');
  }

  /// Write an error message (red)
  static void writeError(String message) {
    stderr.writeln('$_red$_bold[ERROR]$_reset $_red$message$_reset');
  }

  /// Write error details (red, indented under a failed step) to stderr.
  /// Multi-line messages are indented line by line.
  static void writeErrorDetail(String message) {
    for (final line in message.trimRight().split('\n')) {
      stderr.writeln('$_red    ${line.trimRight()}$_reset');
    }
  }

  /// Write a warning message (yellow)
  static void writeWarning(String message) {
    stdout.writeln('$_yellow$_bold[WARNING]$_reset $_yellow$message$_reset');
  }

  /// Write warning details (yellow, indented under a step that completed with
  /// warnings). Multi-line messages are indented line by line.
  static void writeWarningDetail(String message) {
    for (final line in message.trimRight().split('\n')) {
      stdout.writeln('$_yellow    ${line.trimRight()}$_reset');
    }
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

  /// Print the Nylo banner with the installer version
  static void writeBanner() {
    stdout.writeln('''
$_cyan$_bold
    _   __      __
   / | / /_  __/ /___
  /  |/ / / / / / __ \\
 / /|  / /_/ / / /_/ /
/_/ |_/\\__, /_/\\____/
      /____/$_reset  ${_dim}v${Constants.version}$_reset
''');
  }
}
