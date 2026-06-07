#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'package:nylo_installer/src/commands/clean_command.dart';
import 'package:nylo_installer/src/commands/init_command.dart';
import 'package:nylo_installer/src/commands/ios_pod_refresh_command.dart';
import 'package:nylo_installer/src/commands/locale_check_missing_keys_command.dart';
import 'package:nylo_installer/src/commands/locale_find_untranslated_command.dart';
import 'package:nylo_installer/src/commands/metro_command.dart';
import 'package:nylo_installer/src/commands/new_command.dart';
import 'package:nylo_installer/src/commands/self_update_command.dart';
import 'package:nylo_installer/src/commands/test_command.dart';
import 'package:nylo_installer/src/console/console.dart';
import 'package:nylo_installer/src/constants.dart';
import 'package:nylo_installer/src/utils/version_checker.dart';

void main(List<String> arguments) async {
  final parser = ArgParser(allowTrailingOptions: false)
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage information',
    )
    ..addFlag('version', abbr: 'v', negatable: false, help: 'Show version');

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
        final projectArgs = results.rest.length > 1
            ? results.rest.sublist(1)
            : <String>[];
        await NewCommand().run(projectArgs);
        break;
      case 'init':
        await InitCommand().run();
        break;
      case 'clean':
        final cleanArgs = results.rest.length > 1
            ? results.rest.sublist(1)
            : <String>[];
        await CleanCommand().run(cleanArgs);
        break;
      case 'test':
        final testArgs = results.rest.length > 1
            ? results.rest.sublist(1)
            : <String>[];
        await TestCommand().run(testArgs);
        break;
      case 'metro':
        final metroArgs = results.rest.length > 1
            ? results.rest.sublist(1)
            : <String>[];
        await MetroCommand().run(metroArgs);
        break;
      case 'ios:pod-refresh':
        final iosPodArgs = results.rest.length > 1
            ? results.rest.sublist(1)
            : <String>[];
        await IosPodRefreshCommand().run(iosPodArgs);
        break;
      case 'locale:find-untranslated':
        final localeFindArgs = results.rest.length > 1
            ? results.rest.sublist(1)
            : <String>[];
        await LocaleFindUntranslatedCommand().run(localeFindArgs);
        break;
      case 'locale:check-missing-keys':
        final localeCheckArgs = results.rest.length > 1
            ? results.rest.sublist(1)
            : <String>[];
        await LocaleCheckMissingKeysCommand().run(localeCheckArgs);
        break;
      case 'self-update':
        final selfUpdateArgs = results.rest.length > 1
            ? results.rest.sublist(1)
            : <String>[];
        await SelfUpdateCommand().run(selfUpdateArgs);
        break;
      default:
        NyloConsole.writeError('Unknown command: $command');
        _printUsage();
        exit(1);
    }

    // Check for updates after a command completes, but only in an interactive
    // terminal. Never nag in CI or when output is piped/redirected: the banner
    // prints to stdout and would pollute machine-readable output (e.g. the
    // locale:* JSON reports). Skipped for self-update, which has its own
    // version messaging.
    if (command != 'self-update' && stdout.hasTerminal) {
      final updateInfo = await VersionChecker().checkForUpdate();
      if (updateInfo != null) {
        VersionChecker.printUpdateBanner(updateInfo);
      }
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
      --ios               Deep clean iOS (remove Pods, re-run pod install)
      --android           Deep clean Android (run gradlew clean)
      --all               Deep clean both iOS and Android
    metro <command>       Run a metro command (e.g. make:model)
    ios:pod-refresh       Remove iOS pods and run pod install --repo-update
    locale:find-untranslated   Find hardcoded strings not wrapped in .tr()
      --format=<md|json>       Report format (default: md)
      --stdout                 Print the report instead of writing a file
      --ci                     Exit 1 if any untranslated string is found
    locale:check-missing-keys  Compare lang/*.json against a baseline locale
      --file=<name>            Baseline locale file (default: en.json)
      --format=<md|txt|json>   Report format (default: md)
      --stdout                 Print the report instead of writing a file
      --ci                     Exit 1 if any locale has missing/empty keys
      --strict                 Also flag extra keys (enforce identical key sets)
    test                  Format and run Flutter tests
      --no-format         Skip formatting before running tests
      --filter=<pattern>  Filter tests by name
      --coverage          Collect code coverage
      --path=<dir>        Test directory path (default: test)
    self-update           Update nylo to the latest version

  Options:
    -h, --help            Show usage information
    -v, --version         Show version

  Run 'nylo <command> -h' for command-specific help.

  Example:
    nylo new my_app
    nylo new MyAwesomeApp
    nylo init
    nylo clean
    nylo clean --ios
    nylo clean --all
    nylo test
    nylo test --filter "login" --coverage
    nylo metro make:model User
    nylo ios:pod-refresh
    nylo locale:find-untranslated
    nylo locale:check-missing-keys --ci
    nylo self-update

  Documentation: ${Constants.docsUrl}
''');
}
