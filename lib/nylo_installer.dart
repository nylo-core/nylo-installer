/// Nylo Installer - CLI tool to create new Nylo Flutter projects
library nylo_installer;

export 'src/commands/metro_installer.dart';
export 'src/commands/new_command.dart';
export 'src/commands/self_update_command.dart';
export 'src/commands/test_command.dart';
export 'src/utils/version_checker.dart';
export 'src/console/console.dart';
export 'src/constants.dart';
export 'src/utils/process_runner.dart';
export 'src/utils/prompt.dart';
export 'src/utils/shell_detector.dart';
export 'src/utils/validators.dart';

// Localization audit (locale:find-untranslated / locale:check-missing-keys)
export 'src/commands/locale_find_untranslated_command.dart';
export 'src/commands/locale_check_missing_keys_command.dart';
export 'src/locale/models.dart';
export 'src/locale/config.dart';
export 'src/locale/file_collector.dart';
export 'src/locale/locale_compare.dart';
export 'src/locale/scanner.dart';
export 'src/locale/reporter.dart';
