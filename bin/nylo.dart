#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'package:nylo_installer/src/commands/clean_command.dart';
import 'package:nylo_installer/src/commands/init_command.dart';
import 'package:nylo_installer/src/commands/new_command.dart';
import 'package:nylo_installer/src/console/console.dart';
import 'package:nylo_installer/src/constants.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage information')
    ..addFlag('version', abbr: 'v', negatable: false, help: 'Show version')
;

  try {
    final results = parser.parse(arguments);

    // Handle version flag
    if (results['version'] as bool) {
      NyloConsole.write('Nylo Installer v${Constants.version}');
      exit(0);
    }

    // Handle help flag or no arguments
    if (results['help'] as bool || arguments.isEmpty) {
      _printUsage();
      exit(0);
    }

    // Get the command (first positional argument)
    final command = results.rest.isNotEmpty ? results.rest.first : null;

    if (command == null) {
      _printUsage();
      exit(0);
    }

    // Route to appropriate command
    switch (command) {
      case 'new':
        final projectArgs = results.rest.length > 1 ? results.rest.sublist(1) : <String>[];
        await NewCommand().run(projectArgs);
        break;
      case 'init':
        await InitCommand().run();
        break;
      case 'clean':
        await CleanCommand().run();
        break;
      default:
        NyloConsole.writeError('Unknown command: $command');
        _printUsage();
        exit(1);
    }
  } on FormatException catch (e) {
    NyloConsole.writeError('Error: ${e.message}');
    _printUsage();
    exit(1);
  }
}

void _printUsage() {
  NyloConsole.write('''

  Nylo Installer - Create new Nylo Flutter projects

  Usage: nylo <command> [arguments]

  Commands:
    new <project_name>    Create a new Nylo project
    init                  Set up the metro CLI alias
    clean                 Run flutter clean and flutter pub get

  Options:
    -h, --help            Show usage information
    -v, --version         Show version

  Example:
    nylo new my_app
    nylo new MyAwesomeApp
    nylo init
    nylo clean

  Documentation: ${Constants.docsUrl}
''');
}
