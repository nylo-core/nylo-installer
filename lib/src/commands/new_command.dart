import 'dart:io';
import 'package:recase/recase.dart';
import 'package:path/path.dart' as path;
import '../console/console.dart';
import '../utils/validators.dart';
import '../utils/process_runner.dart';
import '../constants.dart';

/// Handles the `nylo new <project_name>` command
class NewCommand {
  /// Execute the new project creation
  Future<void> run(List<String> arguments) async {
    // Step 1: Validate arguments
    if (arguments.isEmpty) {
      NyloConsole.writeError('Please provide a project name');
      NyloConsole.write('Usage: nylo new <project_name>');
      exit(1);
    }

    final projectName = arguments.first;
    final projectNameSnake = ReCase(projectName).snakeCase;
    final projectPath = path.join(Directory.current.path, projectNameSnake);

    // Step 2: Validate project name
    if (!_isValidProjectName(projectNameSnake)) {
      NyloConsole.writeError(
        'Invalid project name: "$projectName"\n'
        'Project names must be valid Dart package names (lowercase with underscores)',
      );
      exit(1);
    }

    // Step 3: Check if directory already exists
    if (await Directory(projectPath).exists()) {
      NyloConsole.writeError('Directory "$projectNameSnake" already exists');
      exit(1);
    }

    NyloConsole.writeBanner();
    NyloConsole.write('');
    NyloConsole.writeTaskHeader('Creating new Nylo project: $projectNameSnake');

    // Step 1: Validate prerequisites
    NyloConsole.writeSubtaskPending('Checking prerequisites...', isFirst: true);
    await Validators.checkPrerequisites();

    // Step 2: Clone the template repository
    final cloneSpinner = Spinner('');
    cloneSpinner.start('Cloning Nylo template...');
    await _cloneTemplate(projectPath);
    cloneSpinner.stop('Template cloned');

    // Step 3: Remove .git folder for fresh start
    final initSpinner = Spinner('');
    initSpinner.start('Initializing project...');
    await _removeGitFolder(projectPath);
    initSpinner.stop('Project initialized');

    // Step 4: Update project configuration
    final configSpinner = Spinner('');
    configSpinner.start('Configuring project...');
    await _setupEnvFile(projectPath);
    await _updateProjectName(projectPath, projectNameSnake);
    configSpinner.stop('Project configured');

    // Step 5: Run flutter pub get
    final pubGetSpinner = Spinner('');
    pubGetSpinner.start('Installing dependencies...');
    await _runPubGet(projectPath);
    pubGetSpinner.stop('Dependencies installed');

    // Step 6: Generate app key
    final keySpinner = Spinner('');
    keySpinner.start('Generating app key...');
    await _generateAppKey(projectPath);
    keySpinner.stop('App key generated');

    // Show success message
    _printSuccessMessage(projectNameSnake);
  }

  /// Validates the project name follows Dart package naming conventions
  bool _isValidProjectName(String name) {
    final validPattern = RegExp(r'^[a-z][a-z0-9_]*$');
    final reserved = [
      'test',
      'dart',
      'flutter',
      'lib',
      'bin',
      'build',
      'android',
      'ios',
      'web',
      'macos',
      'windows',
      'linux',
      'assets',
      'fonts',
      'packages',
      'pubspec',
    ];
    return validPattern.hasMatch(name) && !reserved.contains(name);
  }

  /// Clones the Nylo template repository
  Future<void> _cloneTemplate(String targetPath) async {
    final result = await ProcessRunner.run(
      'git',
      ['clone', '--depth', '1', Constants.templateRepoUrl, targetPath],
    );

    if (result.exitCode != 0) {
      NyloConsole.writeError('Failed to clone template repository');
      NyloConsole.writeError(result.stderr);
      exit(1);
    }
  }

  /// Removes the .git folder for a fresh start
  Future<void> _removeGitFolder(String projectPath) async {
    final gitDir = Directory(path.join(projectPath, '.git'));
    if (await gitDir.exists()) {
      await gitDir.delete(recursive: true);
    }
  }

  /// Updates the project name in pubspec.yaml and other files
  Future<void> _updateProjectName(
      String projectPath, String projectName) async {
    // Update pubspec.yaml
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    if (await pubspecFile.exists()) {
      String content = await pubspecFile.readAsString();
      content = content.replaceFirst(
        RegExp(r'^name:\s*\w+', multiLine: true),
        'name: $projectName',
      );
      await pubspecFile.writeAsString(content);
    }

    // Update Android package name
    await _updateAndroidConfig(projectPath, projectName);

    // Update iOS bundle identifier
    await _updateIosConfig(projectPath, projectName);

    // Update app title
    await _updateAppTitle(projectPath, projectName);

    // Update test file imports
    await _updateTestImports(projectPath, projectName);
  }

  /// Updates Android-specific configuration
  Future<void> _updateAndroidConfig(
      String projectPath, String projectName) async {
    final buildGradlePath =
        path.join(projectPath, 'android', 'app', 'build.gradle');
    final buildGradleFile = File(buildGradlePath);

    if (await buildGradleFile.exists()) {
      String content = await buildGradleFile.readAsString();
      content =
          content.replaceAll('com.nylo.android', 'com.$projectName.android');
      await buildGradleFile.writeAsString(content);
    }

    // Also update build.gradle.kts if it exists
    final buildGradleKtsPath =
        path.join(projectPath, 'android', 'app', 'build.gradle.kts');
    final buildGradleKtsFile = File(buildGradleKtsPath);

    if (await buildGradleKtsFile.exists()) {
      String content = await buildGradleKtsFile.readAsString();
      content =
          content.replaceAll('com.nylo.android', 'com.$projectName.android');
      await buildGradleKtsFile.writeAsString(content);
    }

    // Rename Kotlin source directory from com/nylo/ to com/<projectName>/
    final kotlinNyloDir = Directory(path.join(
        projectPath, 'android', 'app', 'src', 'main', 'kotlin', 'com', 'nylo'));
    if (await kotlinNyloDir.exists()) {
      final kotlinNewDir = Directory(path.join(projectPath, 'android', 'app',
          'src', 'main', 'kotlin', 'com', projectName));
      await kotlinNyloDir.rename(kotlinNewDir.path);
    }

    // Update package declaration in MainActivity.kt
    final mainActivityPath = path.join(projectPath, 'android', 'app', 'src',
        'main', 'kotlin', 'com', projectName, 'android', 'MainActivity.kt');
    final mainActivityFile = File(mainActivityPath);
    if (await mainActivityFile.exists()) {
      String content = await mainActivityFile.readAsString();
      content = content.replaceAll(
          'package com.nylo.android', 'package com.$projectName.android');
      await mainActivityFile.writeAsString(content);
    }
  }

  /// Updates iOS-specific configuration
  Future<void> _updateIosConfig(String projectPath, String projectName) async {
    final pbxprojPath = path.join(
      projectPath,
      'ios',
      'Runner.xcodeproj',
      'project.pbxproj',
    );
    final pbxprojFile = File(pbxprojPath);

    if (await pbxprojFile.exists()) {
      String content = await pbxprojFile.readAsString();
      content = content.replaceAll('com.nylo.ios', 'com.$projectName.ios');
      await pbxprojFile.writeAsString(content);
    }
  }

  /// Updates app display title
  Future<void> _updateAppTitle(String projectPath, String projectName) async {
    final titleCase = ReCase(projectName).titleCase;

    // Update .env file if it exists
    final envFile = File(path.join(projectPath, '.env'));
    if (await envFile.exists()) {
      String content = await envFile.readAsString();
      content = content.replaceAll('APP_NAME="Nylo"', 'APP_NAME="$titleCase"');
      content = content.replaceAll("APP_NAME='Nylo'", "APP_NAME='$titleCase'");
      await envFile.writeAsString(content);
    }
  }

  /// Updates test file imports from `import '/` to `import 'package:<name>/`
  Future<void> _updateTestImports(
      String projectPath, String projectName) async {
    final testDir = Directory(path.join(projectPath, 'test'));
    if (!await testDir.exists()) return;

    await for (final entity in testDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        String content = await entity.readAsString();
        if (content.contains("import '/")) {
          content =
              content.replaceAll("import '/", "import 'package:$projectName/");
          await entity.writeAsString(content);
        }
      }
    }
  }

  /// Runs flutter pub get in the project directory
  Future<void> _runPubGet(String projectPath) async {
    final result = await ProcessRunner.run(
      'flutter',
      ['pub', 'get'],
      workingDirectory: projectPath,
    );

    if (result.exitCode != 0) {
      NyloConsole.writeWarning('flutter pub get completed with warnings');
    }
  }

  /// Copies .env-example to .env
  Future<void> _setupEnvFile(String projectPath) async {
    final envExampleFile = File(path.join(projectPath, '.env-example'));
    final envFile = File(path.join(projectPath, '.env'));

    if (await envExampleFile.exists()) {
      await envExampleFile.copy(envFile.path);
    }
  }

  /// Generates app key using nylo_framework
  Future<void> _generateAppKey(String projectPath) async {
    final result = await ProcessRunner.run(
      'dart',
      ['run', 'nylo_framework:main', 'make:key'],
      workingDirectory: projectPath,
    );
    if (result.exitCode != 0 && result.stderr.trim().isNotEmpty) {
      NyloConsole.writeWarning('App key generation completed with warnings');
    }

    final resultMakeEnv = await ProcessRunner.run(
      'dart',
      ['run', 'nylo_framework:main', 'make:env'],
      workingDirectory: projectPath,
    );
    if (resultMakeEnv.exitCode != 0) {
      NyloConsole.writeWarning('App key generation completed with warnings');
    }
  }

  /// Prints the success message with next steps
  void _printSuccessMessage(String projectName) {
    NyloConsole.write('');
    NyloConsole.writeSuccess('Project "$projectName" created successfully!');
    NyloConsole.write('');
    NyloConsole.write('Next steps:');
    NyloConsole.write('');
    NyloConsole.writeHighlight('  cd $projectName');
    NyloConsole.writeHighlight('  flutter run');
    NyloConsole.write('');
    NyloConsole.write('Documentation: ${Constants.docsUrl}');
    NyloConsole.write('');
  }
}
