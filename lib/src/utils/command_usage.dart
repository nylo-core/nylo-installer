import 'package:args/args.dart';

import '../console/console.dart';

/// Prints a standard help/usage block for a `nylo` subcommand.
///
/// Renders a short [description], a `Usage:` line, and the option list derived
/// from [parser] (reusing each option's `help:` text). Call this when the user
/// passes `-h`/`--help` or supplies an invalid flag.
void printCommandUsage({
  required String command,
  required String description,
  required ArgParser parser,
  String invocation = '[options]',
}) {
  final options = parser.usage
      .split('\n')
      .map((line) => line.isEmpty ? line : '    $line')
      .join('\n'); // indent option lines to match the surrounding block

  NyloConsole.write('''

  $description

  Usage: nylo $command $invocation

  Options:
$options
''');
}
