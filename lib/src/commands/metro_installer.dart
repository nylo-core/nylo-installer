import 'dart:io';

import '../console/console.dart';
import '../utils/prompt.dart';
import '../utils/shell_detector.dart';

/// Handles optional metro CLI installation
class MetroInstaller {
  /// Offer to install the metro CLI alias.
  /// This should be called after project creation is complete.
  /// Returns true if installation was successful, false if skipped or failed.
  static Future<bool> offerInstallation() async {
    // Skip on Windows
    if (Platform.isWindows) {
      _printWindowsInstructions();
      return false;
    }

    // Detect shell
    final config = ShellDetector.detectShell();
    if (config == null) {
      NyloConsole.writeWarning(
        'Could not detect your shell. Metro CLI setup skipped.',
      );
      _printManualInstructions();
      return false;
    }

    // Check if already installed
    final alreadyInstalled = await ShellDetector.isMetroAliasInstalled(
      config.profilePath,
    );

    if (alreadyInstalled) {
      NyloConsole.writeInfo('Metro CLI is already configured.');
      return false;
    }

    // Ask user
    NyloConsole.write('');
    NyloConsole.writeInfo(
      'Metro CLI helps you generate files for your Nylo project.',
    );

    final shouldInstall = Prompt.confirm(
      'Would you like to install the metro CLI?',
      defaultYes: true,
    );

    if (!shouldInstall) {
      NyloConsole.write('Skipping metro CLI installation.');
      return false;
    }

    // Install
    NyloConsole.writeStep('Installing metro CLI alias...');
    final success = await ShellDetector.installMetroAlias(config);

    if (success) {
      NyloConsole.writeStepComplete(
        'Metro CLI alias added to ${config.profilePath}',
      );
      NyloConsole.write('');
      NyloConsole.writeInfo('To use metro, restart your terminal or run:');
      NyloConsole.writeHighlight('  source ${config.profilePath}');
      NyloConsole.write('');
      NyloConsole.write('Then in your project directory, use:');
      NyloConsole.writeHighlight('  metro make:page HomePage');
      return true;
    } else {
      NyloConsole.writeWarning(
        'Could not add metro alias. You may not have write permission.',
      );
      _printManualInstructions();
      return false;
    }
  }

  static void _printWindowsInstructions() {
    NyloConsole.write('');
    NyloConsole.writeInfo('Metro CLI on Windows:');
    NyloConsole.write(
      'Windows requires manual setup. In your project directory, run:',
    );
    NyloConsole.writeHighlight('  dart run nylo_framework:main <command>');
    NyloConsole.write('');
    NyloConsole.write('Or create a batch file/PowerShell alias manually.');
  }

  static void _printManualInstructions() {
    NyloConsole.write('');
    NyloConsole.write(
      'To set up metro manually, add this to your shell profile:',
    );
    NyloConsole.writeHighlight("  alias metro='dart run nylo_framework:main'");
  }
}
