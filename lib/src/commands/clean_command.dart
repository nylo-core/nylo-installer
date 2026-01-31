import 'dart:io';

import '../console/console.dart';
import '../utils/process_runner.dart';

/// Handles the "nylo clean" command
/// Runs flutter clean followed by flutter pub get
class CleanCommand {
  /// Execute the clean command
  Future<void> run() async {
    NyloConsole.writeBanner();
    NyloConsole.write('');
    NyloConsole.writeInfo('Cleaning project...');
    NyloConsole.write('');

    // Step 1: Run flutter clean
    final cleanSpinner = Spinner('');
    cleanSpinner.start('[1/2] Running flutter clean...');
    final cleanResult = await ProcessRunner.run('flutter', ['clean']);
    cleanSpinner.stop('flutter clean complete');

    if (cleanResult.exitCode != 0) {
      NyloConsole.writeError('flutter clean failed');
      NyloConsole.writeError(cleanResult.stderr);
      exit(1);
    }

    // Step 2: Run flutter pub get
    final pubGetSpinner = Spinner('');
    pubGetSpinner.start('[2/2] Running flutter pub get...');
    final pubGetResult = await ProcessRunner.run('flutter', ['pub', 'get']);
    pubGetSpinner.stop('flutter pub get complete');

    if (pubGetResult.exitCode != 0) {
      NyloConsole.writeWarning('flutter pub get completed with warnings');
    }

    NyloConsole.write('');
    NyloConsole.writeSuccess('Project cleaned successfully!');
  }
}
