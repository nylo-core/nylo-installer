import 'dart:io';
import '../console/console.dart';
import '../utils/process_runner.dart';

/// Handles the "nylo ios:pod-refresh" command
/// Removes iOS build artifacts (Pods, .symlinks, Podfile.lock) and runs
/// `pod install --repo-update` to refresh CocoaPods dependencies.
class IosPodRefreshCommand {
  /// Execute the ios:pod-refresh command
  Future<void> run([List<String> arguments = const []]) async {
    if (!await Directory('ios').exists()) {
      NyloConsole.writeError(
          'ios/ directory not found. Are you in a Flutter project?');
      exit(1);
    }

    if (!Platform.isMacOS) {
      NyloConsole.writeError('pod install is only available on macOS.');
      exit(1);
    }

    NyloConsole.writeBanner();
    NyloConsole.write('');
    NyloConsole.writeInfo('Refreshing iOS pods...');
    NyloConsole.write('');

    final rmSpinner = Spinner('');
    rmSpinner.start('[1/2] Removing iOS build artifacts...');
    await _removeIosArtifacts();
    rmSpinner.stop('iOS artifacts removed (Pods, .symlinks, Podfile.lock)');

    final podSpinner = Spinner('');
    podSpinner.start('[2/2] Running pod install --repo-update...');
    final podResult = await ProcessRunner.run(
      'pod',
      ['install', '--repo-update'],
      workingDirectory: 'ios',
    );
    podSpinner.stop('pod install complete');

    if (podResult.exitCode != 0) {
      NyloConsole.writeWarning('pod install completed with warnings');
      NyloConsole.writeWarning(podResult.stderr);
    }

    NyloConsole.write('');
    NyloConsole.writeSuccess('iOS pods refreshed successfully!');
  }

  /// Remove iOS build artifacts (Pods, .symlinks, Podfile.lock)
  Future<void> _removeIosArtifacts() async {
    final directories = [
      Directory('ios/Pods'),
      Directory('ios/.symlinks'),
    ];
    final files = [
      File('ios/Podfile.lock'),
    ];

    for (final dir in directories) {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
    for (final file in files) {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
