import 'dart:io';
import 'package:args/args.dart';
import '../console/console.dart';
import '../utils/command_usage.dart';
import '../utils/process_runner.dart';

/// Handles the "nylo clean" command
/// Runs flutter clean followed by flutter pub get
/// Supports --ios, --android, and --all flags for platform-specific deep cleaning
class CleanCommand {
  /// Execute the clean command
  Future<void> run([List<String> arguments = const []]) async {
    final parser = ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Show usage information',
      )
      ..addFlag('ios', negatable: false, help: 'Deep clean iOS')
      ..addFlag('android', negatable: false, help: 'Deep clean Android')
      ..addFlag('all', negatable: false, help: 'Deep clean iOS and Android');

    const description =
        'Run flutter clean and flutter pub get, with optional platform '
        'deep-cleaning.';

    final ArgResults results;
    try {
      results = parser.parse(arguments);
    } on FormatException catch (e) {
      NyloConsole.writeError(e.message);
      printCommandUsage(
        command: 'clean',
        description: description,
        parser: parser,
      );
      exit(1);
    }

    if (results['help'] as bool) {
      printCommandUsage(
        command: 'clean',
        description: description,
        parser: parser,
      );
      exit(0);
    }

    bool cleanIos = results['ios'] as bool || results['all'] as bool;
    bool cleanAndroid = results['android'] as bool || results['all'] as bool;

    // Validate platform directories exist
    if (cleanIos && !await Directory('ios').exists()) {
      NyloConsole.writeWarning('ios/ directory not found. Skipping iOS clean.');
      cleanIos = false;
    }
    if (cleanAndroid && !await Directory('android').exists()) {
      NyloConsole.writeWarning(
        'android/ directory not found. Skipping Android clean.',
      );
      cleanAndroid = false;
    }

    // Calculate steps dynamically
    int totalSteps = 2; // flutter clean + flutter pub get
    if (cleanIos) totalSteps += 2; // rm artifacts + pod install
    if (cleanAndroid) totalSteps += 1; // gradlew clean
    int currentStep = 0;
    String stepLabel() {
      currentStep++;
      return '[$currentStep/$totalSteps]';
    }

    NyloConsole.writeBanner();
    NyloConsole.write('');
    NyloConsole.writeInfo('Cleaning project...');
    NyloConsole.write('');

    // Step: Run flutter clean
    final cleanSpinner = Spinner('');
    cleanSpinner.start('${stepLabel()} Running flutter clean...');
    final cleanResult = await ProcessRunner.run('flutter', ['clean']);
    cleanSpinner.stop('flutter clean complete');

    if (cleanResult.exitCode != 0) {
      NyloConsole.writeError('flutter clean failed');
      NyloConsole.writeError(cleanResult.stderr);
      exit(1);
    }

    // iOS deep clean
    if (cleanIos) {
      // Step: Remove iOS artifacts
      final rmSpinner = Spinner('');
      rmSpinner.start('${stepLabel()} Removing iOS build artifacts...');
      await _removeIosArtifacts();
      rmSpinner.stop('iOS artifacts removed (Pods, .symlinks, Podfile.lock)');

      // Step: pod install --repo-update
      final podSpinner = Spinner('');
      podSpinner.start('${stepLabel()} Running pod install --repo-update...');
      if (!Platform.isMacOS) {
        podSpinner.stop('pod install skipped (not macOS)');
        NyloConsole.writeWarning(
          'pod install is only available on macOS. Skipping.',
        );
      } else {
        final podResult = await ProcessRunner.run('pod', [
          'install',
          '--repo-update',
        ], workingDirectory: 'ios');
        podSpinner.stop('pod install complete');

        if (podResult.exitCode != 0) {
          NyloConsole.writeWarning('pod install completed with warnings');
          NyloConsole.writeWarning(podResult.stderr);
        }
      }
    }

    // Android deep clean
    if (cleanAndroid) {
      final gradleSpinner = Spinner('');
      gradleSpinner.start('${stepLabel()} Running gradlew clean...');
      final gradlew = Platform.isWindows ? 'gradlew.bat' : './gradlew';
      final gradleResult = await ProcessRunner.run(gradlew, [
        'clean',
      ], workingDirectory: 'android');
      gradleSpinner.stop('gradlew clean complete');

      if (gradleResult.exitCode != 0) {
        NyloConsole.writeWarning('gradlew clean completed with warnings');
        NyloConsole.writeWarning(gradleResult.stderr);
      }
    }

    // Step: Run flutter pub get
    final pubGetSpinner = Spinner('');
    pubGetSpinner.start('${stepLabel()} Running flutter pub get...');
    final pubGetResult = await ProcessRunner.run('flutter', ['pub', 'get']);
    pubGetSpinner.stop('flutter pub get complete');

    if (pubGetResult.exitCode != 0) {
      NyloConsole.writeWarning('flutter pub get completed with warnings');
    }

    NyloConsole.write('');
    NyloConsole.writeSuccess('Project cleaned successfully!');
  }

  /// Remove iOS build artifacts (Pods, .symlinks, Podfile.lock)
  Future<void> _removeIosArtifacts() async {
    final directories = [Directory('ios/Pods'), Directory('ios/.symlinks')];
    final files = [File('ios/Podfile.lock')];

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
