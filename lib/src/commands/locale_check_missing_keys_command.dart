import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import '../console/console.dart';
import '../locale/cli_helpers.dart';
import '../locale/config.dart';
import '../locale/locale_compare.dart';
import '../locale/models.dart';
import '../locale/reporter.dart';
import '../utils/command_usage.dart';

/// Handles the "nylo locale:check-missing-keys" command.
///
/// Compares every `lang/*.json` locale file against a baseline locale
/// (default `en.json`) and reports missing, empty, and extra keys per locale.
class LocaleCheckMissingKeysCommand {
  /// Execute the locale:check-missing-keys command.
  Future<void> run([List<String> arguments = const []]) async {
    final parser = ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Show usage information',
      )
      ..addOption('path', help: 'Project root.', defaultsTo: '.')
      ..addOption(
        'file',
        help: 'Baseline locale file name.',
        defaultsTo: 'en.json',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output file path.',
        defaultsTo: 'nylo-i18n-missing-keys.md',
      )
      ..addOption(
        'format',
        help: 'Output format.',
        allowed: ['md', 'txt', 'json'],
        defaultsTo: 'md',
      )
      ..addFlag(
        'stdout',
        help: 'Print the report instead of writing a file.',
        negatable: false,
      )
      ..addFlag(
        'ci',
        help: 'Exit with code 1 if any locale has missing or empty keys.',
        negatable: false,
      )
      ..addFlag(
        'strict',
        help: 'Treat extra keys (not in the baseline) as problems too.',
        negatable: false,
      );

    const description =
        'Compare lang/*.json against a baseline locale and '
        'report missing, empty, and extra keys per locale.';

    final ArgResults results;
    try {
      results = parser.parse(arguments);
    } on FormatException catch (e) {
      NyloConsole.writeError(e.message);
      printCommandUsage(
        command: 'locale:check-missing-keys',
        description: description,
        parser: parser,
      );
      exit(1);
    }

    if (results['help'] as bool) {
      printCommandUsage(
        command: 'locale:check-missing-keys',
        description: description,
        parser: parser,
      );
      exit(0);
    }

    final root = resolveProjectRoot(results['path'] as String);
    final config = AuditConfig.load(root);
    final baseline = results['file'] as String;

    final List<LocaleComparison> comparisons;
    try {
      comparisons = LocaleComparator(
        config.langDirAbsolute,
      ).compareAgainst(baseline);
    } on LocaleException catch (e) {
      NyloConsole.writeError('$e');
      exit(1);
    }

    final format = results['format'] as String;
    final generatedAt = DateTime.now();
    final content = switch (format) {
      'json' => Reporter.missingKeysJson(
        comparisons,
        baseline: baseline,
        generatedAt: generatedAt,
      ),
      'txt' => Reporter.missingKeysText(
        comparisons,
        baseline: baseline,
        generatedAt: generatedAt,
      ),
      _ => Reporter.missingKeysMarkdown(
        comparisons,
        baseline: baseline,
        generatedAt: generatedAt,
      ),
    };

    final ci = results['ci'] as bool;
    final strict = results['strict'] as bool;
    final hasProblems = comparisons.any(
      (c) => strict ? !c.isStrictlyClean : !c.isClean,
    );

    if (results['stdout'] as bool) {
      stdout.write(content);
      if (!content.endsWith('\n')) stdout.writeln();
    } else {
      final outPath = p.join(
        root,
        withExtension(results['output'] as String, format),
      );
      File(outPath).writeAsStringSync(content);
      final totalMissing = comparisons.fold<int>(
        0,
        (sum, c) => sum + c.missing.length,
      );
      final totalEmpty = comparisons.fold<int>(
        0,
        (sum, c) => sum + c.empty.length,
      );
      final totalExtra = comparisons.fold<int>(
        0,
        (sum, c) => sum + c.extra.length,
      );
      NyloConsole.writeInfo(
        'Compared ${comparisons.length} locale(s). '
        'Missing: $totalMissing, Empty: $totalEmpty, Extra: $totalExtra.',
      );
      if (hasProblems) {
        NyloConsole.writeWarning(
          strict
              ? 'Some locales have missing, empty, or extra keys.'
              : 'Some locales have missing or empty keys.',
        );
      } else {
        NyloConsole.writeSuccess('All locales are complete.');
      }
      NyloConsole.write('Report written to $outPath');
    }

    exit(ci && hasProblems ? 1 : 0);
  }
}
