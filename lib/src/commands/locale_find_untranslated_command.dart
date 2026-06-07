import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import '../console/console.dart';
import '../locale/cli_helpers.dart';
import '../locale/config.dart';
import '../locale/file_collector.dart';
import '../locale/reporter.dart';
import '../locale/scanner.dart';
import '../utils/command_usage.dart';

/// Handles the "nylo locale:find-untranslated" command.
///
/// Scans Dart source (via the analyzer AST) for hardcoded, user-facing string
/// literals that are not wrapped in Nylo's `.tr()` / `trans()` translation
/// calls, then writes or prints a report.
class LocaleFindUntranslatedCommand {
  /// Execute the locale:find-untranslated command.
  Future<void> run([List<String> arguments = const []]) async {
    final parser = ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Show usage information',
      )
      ..addOption('path', help: 'Project root to scan.', defaultsTo: '.')
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output file path.',
        defaultsTo: 'nylo-i18n-baseline.md',
      )
      ..addOption(
        'format',
        help: 'Output format.',
        allowed: ['md', 'json'],
        defaultsTo: 'md',
      )
      ..addFlag(
        'stdout',
        help: 'Print the report instead of writing a file.',
        negatable: false,
      )
      ..addFlag(
        'ci',
        help: 'Exit with code 1 if any untranslated string is found.',
        negatable: false,
      );

    const description =
        "Find hardcoded user-facing strings not wrapped in Nylo's "
        '.tr() / trans() translation calls.';

    final ArgResults results;
    try {
      results = parser.parse(arguments);
    } on FormatException catch (e) {
      NyloConsole.writeError(e.message);
      printCommandUsage(
        command: 'locale:find-untranslated',
        description: description,
        parser: parser,
      );
      exit(1);
    }

    if (results['help'] as bool) {
      printCommandUsage(
        command: 'locale:find-untranslated',
        description: description,
        parser: parser,
      );
      exit(0);
    }

    final root = resolveProjectRoot(results['path'] as String);
    final config = AuditConfig.load(root);

    final files = FileCollector(config).collect();
    final findings = StringScanner(config).scan(files);

    final format = results['format'] as String;
    final generatedAt = DateTime.now();
    final projectName = p.basename(root);
    final content = format == 'json'
        ? Reporter.findingsJson(
            findings,
            projectName: projectName,
            generatedAt: generatedAt,
          )
        : Reporter.findingsMarkdown(
            findings,
            projectName: projectName,
            generatedAt: generatedAt,
          );

    final ci = results['ci'] as bool;
    final hasProblems = findings.isNotEmpty;

    if (results['stdout'] as bool) {
      stdout.write(content);
      if (!content.endsWith('\n')) stdout.writeln();
    } else {
      final outPath = p.join(
        root,
        withExtension(results['output'] as String, format),
      );
      File(outPath).writeAsStringSync(content);
      NyloConsole.writeInfo(
        'Scanned ${files.length} file(s). '
        'Found ${findings.length} untranslated string(s).',
      );
      if (findings.isEmpty) {
        NyloConsole.writeSuccess('No untranslated strings found.');
      } else {
        NyloConsole.writeWarning(
          '${findings.length} untranslated string(s) need attention.',
        );
      }
      NyloConsole.write('Report written to $outPath');
    }

    exit(ci && hasProblems ? 1 : 0);
  }
}
