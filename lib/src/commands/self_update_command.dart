import 'dart:io';

import 'package:args/args.dart';

import '../console/console.dart';
import '../constants.dart';
import '../utils/command_usage.dart';
import '../utils/process_runner.dart';
import '../utils/version_checker.dart';

/// Handles the "nylo self-update" command
/// Updates the nylo_installer to the latest version from pub.dev
class SelfUpdateCommand {
  /// Execute the self-update command
  Future<void> run([List<String> arguments = const []]) async {
    final parser = ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Show usage information',
      );

    const description =
        'Update nylo_installer to the latest version from pub.dev.';

    final ArgResults results;
    try {
      results = parser.parse(arguments);
    } on FormatException catch (e) {
      NyloConsole.writeError(e.message);
      printCommandUsage(
        command: 'self-update',
        description: description,
        parser: parser,
      );
      exit(1);
    }

    if (results['help'] as bool) {
      printCommandUsage(
        command: 'self-update',
        description: description,
        parser: parser,
      );
      exit(0);
    }

    NyloConsole.writeInfo('Checking for updates...');

    final checker = VersionChecker();
    final latestVersion = await checker.fetchLatestVersion();

    if (latestVersion == null) {
      NyloConsole.writeError(
        'Could not check for updates. Please check your internet connection.',
      );
      exit(1);
    }

    if (latestVersion == Constants.version) {
      NyloConsole.write(
        'You\'re already on the latest version (${Constants.version})',
      );
      return;
    }

    NyloConsole.write('');
    NyloConsole.writeInfo(
      'Updating nylo_installer ${Constants.version} → $latestVersion...',
    );
    NyloConsole.write('');

    final spinner = Spinner('');
    spinner.start('Installing update...');

    final result = await ProcessRunner.run('dart', [
      'pub',
      'global',
      'activate',
      Constants.packageName,
    ]);

    spinner.stop();

    if (result.exitCode != 0) {
      NyloConsole.writeError('Update failed.');
      if (result.stderr.isNotEmpty) {
        NyloConsole.writeError(result.stderr);
      }
      exit(1);
    }

    NyloConsole.write('Updated nylo_installer to $latestVersion');
  }
}
