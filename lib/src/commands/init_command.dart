import '../console/console.dart';
import 'metro_installer.dart';

/// Handles the "nylo init" command
/// Sets up the metro CLI alias for an existing Nylo project
class InitCommand {
  /// Execute the init command
  Future<void> run() async {
    NyloConsole.writeBanner();
    NyloConsole.write('');
    NyloConsole.writeInfo('Initializing metro CLI...');
    await MetroInstaller.offerInstallation();
  }
}
