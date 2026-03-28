import 'dart:io';

import '../console/console.dart';
import '../constants.dart';
import '../utils/process_runner.dart';
import '../utils/version_checker.dart';

/// Handles the "nylo self-update" command
/// Updates the nylo_installer to the latest version from pub.dev
class SelfUpdateCommand {
  /// Execute the self-update command
  Future<void> run() async {
    NyloConsole.writeInfo('Checking for updates...');

    final checker = VersionChecker();
    final latestVersion = await checker.fetchLatestVersion();

    if (latestVersion == null) {
      NyloConsole.writeError(
          'Could not check for updates. Please check your internet connection.');
      exit(1);
    }

    if (latestVersion == Constants.version) {
      NyloConsole.write(
          'You\'re already on the latest version (${Constants.version})');
      return;
    }

    NyloConsole.write('');
    NyloConsole.writeInfo(
        'Updating nylo_installer ${Constants.version} → $latestVersion...');
    NyloConsole.write('');

    final spinner = Spinner('');
    spinner.start('Installing update...');

    final result = await ProcessRunner.run(
      'dart',
      ['pub', 'global', 'activate', Constants.packageName],
    );

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
