import 'dart:io' hide ProcessResult;
import 'package:args/args.dart';
import 'package:recase/recase.dart';
import 'package:path/path.dart' as path;
import '../console/console.dart';
import '../utils/command_usage.dart';
import '../utils/validators.dart';
import '../utils/process_runner.dart';
import '../constants.dart';

/// A metro command that exited with a non-zero code during setup
class _MetroFailure {
  final String command;
  final ProcessResult result;

  _MetroFailure(this.command, this.result);
}

/// Handles the `nylo new <project_name>` command
class NewCommand {
  /// Execute the new project creation
  Future<void> run(List<String> arguments) async {
    final parser = ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Show usage information',
      );

    const description = 'Create a new Nylo project from the starter template.';

    final ArgResults results;
    try {
      results = parser.parse(arguments);
    } on FormatException catch (e) {
      NyloConsole.writeError(e.message);
      printCommandUsage(
        command: 'new',
        description: description,
        parser: parser,
        invocation: '<project_name>',
      );
      exit(1);
    }

    if (results['help'] as bool) {
      printCommandUsage(
        command: 'new',
        description: description,
        parser: parser,
        invocation: '<project_name>',
      );
      exit(0);
    }

    // Step 1: Validate arguments
    if (results.rest.isEmpty) {
      NyloConsole.writeError('Please provide a project name');
      NyloConsole.write('Usage: nylo new <project_name>');
      exit(1);
    }

    final projectName = results.rest.first;
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

    final totalTime = Stopwatch()..start();
    final location = NyloConsole.friendlyPath(Directory.current.path);

    NyloConsole.writeBanner();
    NyloConsole.write(
      '  ${NyloConsole.bold('Creating $projectNameSnake')} '
      '${NyloConsole.dim('in $location')}',
    );
    NyloConsole.write('');

    // Step 1: Validate prerequisites
    await _step('Checking prerequisites...', (spinner) async {
      final check = await Validators.verifyPrerequisites();
      if (!check.ok) {
        spinner.fail('Prerequisites check failed', showDuration: false);
        for (final problem in check.problems) {
          NyloConsole.writeErrorDetail(problem);
        }
        exit(1);
      }
      spinner.succeed(
        'Prerequisites verified',
        detail: check.summary == null ? null : '(${check.summary})',
        showDuration: false,
      );
    });

    // Step 2: Clone the template repository
    await _step('Cloning Nylo template...', (spinner) async {
      final result = await _cloneTemplate(projectPath);
      if (result.exitCode != 0) {
        spinner.fail('Failed to clone the Nylo template');
        // Drop git's progress line so only the actual error is shown
        final detail = result.stderr
            .split('\n')
            .where((line) => !line.startsWith('Cloning into '))
            .join('\n');
        NyloConsole.writeErrorDetail(_lastLines(detail));
        NyloConsole.writeErrorDetail(
          'Check your internet connection and try again.',
        );
        exit(1);
      }
      spinner.succeed('Template cloned');
    });

    // Step 3: Remove .git folder for fresh start
    await _step('Initializing project...', (spinner) async {
      await _removeGitFolder(projectPath);
      spinner.succeed('Project initialized');
    });

    // Step 4: Update project configuration
    await _step('Configuring project...', (spinner) async {
      await _setupEnvFile(projectPath);
      await _updateProjectName(projectPath, projectNameSnake);
      spinner.succeed('Project configured');
    });

    // Step 5: Run flutter pub get
    await _step('Installing dependencies...', (spinner) async {
      final result = await _runPubGet(projectPath);
      if (result.exitCode != 0) {
        spinner.fail('Dependencies failed to install');
        final output = result.stderr.trim().isNotEmpty
            ? result.stderr
            : result.stdout;
        NyloConsole.writeErrorDetail(_lastLines(output));
        _printIncompleteMessage(projectNameSnake, [
          'flutter pub get',
          'nylo metro make:key',
          'nylo metro make:env',
        ]);
        exit(1);
      }
      spinner.succeed('Dependencies installed');
    });

    // Step 6: Generate app key
    await _step('Generating app key...', (spinner) async {
      final failures = await _generateAppKey(projectPath);
      if (failures.isEmpty) {
        spinner.succeed('App key generated');
        return;
      }
      spinner.warn('App key generation completed with warnings');
      for (final failure in failures) {
        final output = failure.result.stderr.trim().isNotEmpty
            ? failure.result.stderr
            : failure.result.stdout;
        NyloConsole.writeWarningDetail(
          '${failure.command} exited with code ${failure.result.exitCode}',
        );
        if (output.trim().isNotEmpty) {
          NyloConsole.writeWarningDetail(_lastLines(output, 5));
        }
      }
      final retry = failures
          .map((failure) => 'nylo metro ${failure.command}')
          .join(' && ');
      NyloConsole.writeWarningDetail(
        'To retry, run inside the project: $retry',
      );
    });

    // Show success message
    _printSuccessMessage(projectNameSnake, totalTime.elapsed);
  }

  /// Runs one setup step under a spinner.
  ///
  /// [action] is responsible for finishing the spinner (succeed/fail/warn).
  /// If it throws instead, the step is marked as failed, the error is printed
  /// and the process exits, so an unexpected exception never leaves a spinner
  /// running or the cursor hidden.
  Future<void> _step(
    String message,
    Future<void> Function(Spinner spinner) action,
  ) async {
    final spinner = Spinner()..start(message);
    try {
      await action(spinner);
    } catch (error) {
      if (spinner.isRunning) {
        final label = message.replaceFirst(RegExp(r'\.\.\.$'), '');
        spinner.fail('$label failed');
      }
      NyloConsole.writeErrorDetail('$error');
      exit(1);
    }
  }

  /// Returns the last [maxLines] non-empty lines of [text], prefixed with an
  /// ellipsis line when output was truncated.
  String _lastLines(String text, [int maxLines = 12]) {
    final lines = text
        .trim()
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.length <= maxLines) return lines.join('\n');
    return ['…', ...lines.sublist(lines.length - maxLines)].join('\n');
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
  Future<ProcessResult> _cloneTemplate(String targetPath) {
    return ProcessRunner.run('git', [
      'clone',
      '--depth',
      '1',
      Constants.templateRepoUrl,
      targetPath,
    ]);
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
    String projectPath,
    String projectName,
  ) async {
    // Update pubspec.yaml
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    if (await pubspecFile.exists()) {
      String content = await pubspecFile.readAsString();
      content = content.replaceFirst(
        RegExp(r'^name:\s*\w+', multiLine: true),
        'name: $projectName',
      );
      content = content.replaceFirst(
        'description: A new Nylo Flutter application.',
        'description: A new Flutter application.',
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
    String projectPath,
    String projectName,
  ) async {
    final buildGradlePath = path.join(
      projectPath,
      'android',
      'app',
      'build.gradle',
    );
    final buildGradleFile = File(buildGradlePath);

    if (await buildGradleFile.exists()) {
      String content = await buildGradleFile.readAsString();
      content = content.replaceAll(
        'com.nylo.android',
        'com.$projectName.android',
      );
      await buildGradleFile.writeAsString(content);
    }

    // Also update build.gradle.kts if it exists
    final buildGradleKtsPath = path.join(
      projectPath,
      'android',
      'app',
      'build.gradle.kts',
    );
    final buildGradleKtsFile = File(buildGradleKtsPath);

    if (await buildGradleKtsFile.exists()) {
      String content = await buildGradleKtsFile.readAsString();
      content = content.replaceAll(
        'com.nylo.android',
        'com.$projectName.android',
      );
      await buildGradleKtsFile.writeAsString(content);
    }

    // Rename Kotlin source directory from com/nylo/ to com/<projectName>/
    final kotlinNyloDir = Directory(
      path.join(
        projectPath,
        'android',
        'app',
        'src',
        'main',
        'kotlin',
        'com',
        'nylo',
      ),
    );
    if (await kotlinNyloDir.exists()) {
      final kotlinNewDir = Directory(
        path.join(
          projectPath,
          'android',
          'app',
          'src',
          'main',
          'kotlin',
          'com',
          projectName,
        ),
      );
      await kotlinNyloDir.rename(kotlinNewDir.path);
    }

    // Update package declaration in MainActivity.kt
    final mainActivityPath = path.join(
      projectPath,
      'android',
      'app',
      'src',
      'main',
      'kotlin',
      'com',
      projectName,
      'android',
      'MainActivity.kt',
    );
    final mainActivityFile = File(mainActivityPath);
    if (await mainActivityFile.exists()) {
      String content = await mainActivityFile.readAsString();
      content = content.replaceAll(
        'package com.nylo.android',
        'package com.$projectName.android',
      );
      await mainActivityFile.writeAsString(content);
    }

    // Update android:label in AndroidManifest.xml
    final manifestPath = path.join(
      projectPath,
      'android',
      'app',
      'src',
      'main',
      'AndroidManifest.xml',
    );
    final manifestFile = File(manifestPath);
    if (await manifestFile.exists()) {
      String content = await manifestFile.readAsString();
      final titleCase = ReCase(projectName).titleCase;
      content = content.replaceAll(
        'android:label="Nylo"',
        'android:label="$titleCase"',
      );
      await manifestFile.writeAsString(content);
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
      content = content.replaceAll(
        'com.nylo.dev.RunnerTests',
        'com.$projectName.ios.RunnerTests',
      );
      await pbxprojFile.writeAsString(content);
    }

    // Update app display name in Info.plist
    final infoPlistPath = path.join(projectPath, 'ios', 'Runner', 'Info.plist');
    final infoPlistFile = File(infoPlistPath);
    if (await infoPlistFile.exists()) {
      String content = await infoPlistFile.readAsString();
      final titleCase = ReCase(projectName).titleCase;
      content = content.replaceAll(
        '<string>Nylo</string>',
        '<string>$titleCase</string>',
      );
      await infoPlistFile.writeAsString(content);
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
    String projectPath,
    String projectName,
  ) async {
    final testDir = Directory(path.join(projectPath, 'test'));
    if (!await testDir.exists()) return;

    await for (final entity in testDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        String content = await entity.readAsString();
        if (content.contains("import '/")) {
          content = content.replaceAll(
            "import '/",
            "import 'package:$projectName/",
          );
          await entity.writeAsString(content);
        }
      }
    }
  }

  /// Runs flutter pub get in the project directory
  Future<ProcessResult> _runPubGet(String projectPath) {
    return ProcessRunner.run('flutter', [
      'pub',
      'get',
    ], workingDirectory: projectPath);
  }

  /// Copies .env-example to .env
  Future<void> _setupEnvFile(String projectPath) async {
    final envExampleFile = File(path.join(projectPath, '.env-example'));
    final envFile = File(path.join(projectPath, '.env'));

    if (await envExampleFile.exists()) {
      await envExampleFile.copy(envFile.path);
    }
  }

  /// Generates the app key (`make:key`) and the encrypted env file
  /// (`make:env`) using nylo_framework. Returns the commands that failed.
  Future<List<_MetroFailure>> _generateAppKey(String projectPath) async {
    final failures = <_MetroFailure>[];

    final keyResult = await _runMetro(projectPath, 'make:key');
    if (keyResult.exitCode != 0 && keyResult.stderr.trim().isNotEmpty) {
      failures.add(_MetroFailure('make:key', keyResult));
    }

    final envResult = await _runMetro(projectPath, 'make:env');
    if (envResult.exitCode != 0) {
      failures.add(_MetroFailure('make:env', envResult));
    }

    return failures;
  }

  /// Runs a metro [command] inside the project
  Future<ProcessResult> _runMetro(String projectPath, String command) {
    return ProcessRunner.run('dart', [
      'run',
      'nylo_framework:main',
      command,
    ], workingDirectory: projectPath);
  }

  /// Prints the success message with next steps
  void _printSuccessMessage(String projectName, Duration elapsed) {
    final duration = NyloConsole.formatDuration(elapsed);

    NyloConsole.write('');
    NyloConsole.writeSuccessLine('Created $projectName in $duration');
    NyloConsole.write('');
    NyloConsole.write('  ${NyloConsole.bold('Next steps:')}');
    NyloConsole.write('');
    NyloConsole.writeHighlight('    cd $projectName');
    NyloConsole.writeHighlight('    flutter run');
    NyloConsole.write('');
    NyloConsole.write('  Documentation: ${Constants.docsUrl}');
    NyloConsole.write('');
  }

  /// Printed when the project directory exists but a later step failed, so
  /// the user knows the work is not lost and how to finish the setup.
  void _printIncompleteMessage(
    String projectName,
    List<String> remainingCommands,
  ) {
    final title = NyloConsole.yellow(NyloConsole.bold('Setup incomplete.'));

    NyloConsole.write('');
    NyloConsole.write(
      '  $title Project $projectName was created, '
      'but not every step finished.',
    );
    NyloConsole.write('');
    NyloConsole.write('  ${NyloConsole.bold('To finish setting up, run:')}');
    NyloConsole.write('');
    NyloConsole.writeHighlight('    cd $projectName');
    for (final command in remainingCommands) {
      NyloConsole.writeHighlight('    $command');
    }
    NyloConsole.write('');
  }
}
