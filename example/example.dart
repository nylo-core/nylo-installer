/// Nylo Installer CLI Example
///
/// The Nylo Installer is a command-line tool for scaffolding new Nylo Flutter
/// projects. It handles cloning the template, renaming the project, updating
/// platform configurations, and installing dependencies.
///
/// ## Installation
///
/// ```bash
/// dart pub global activate nylo_installer
/// ```
///
/// ## Usage
///
/// ### Create a new project
///
/// Create a new Nylo project in a new directory:
///
/// ```bash
/// nylo new my_app
/// ```
///
/// This will:
/// - Create a new directory called `my_app`
/// - Clone the Nylo Flutter template
/// - Update all project configurations with the new name
/// - Run `flutter pub get` to install dependencies
///
/// ### Initialize in current directory
///
/// Initialize a Nylo project in the current directory:
///
/// ```bash
/// nylo init
/// ```
///
/// This will scaffold the Nylo template in your current working directory.
///
/// ## Requirements
///
/// - Git must be installed and available in PATH
/// - Flutter must be installed and available in PATH
///
/// ## More Information
///
/// For complete documentation, visit: https://nylo.dev/docs
library;

void main() {
  // This is a CLI tool - run it from the command line.
  // See the documentation above for usage examples.
}
