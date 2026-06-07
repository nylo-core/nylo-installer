# Nylo Installer

A CLI tool to scaffold new [Nylo](https://nylo.dev) Flutter projects.

## Installation

```bash
dart pub global activate nylo_installer
```

## Usage

```
nylo <command> [arguments]

Commands:
  new <project_name>    Create a new Nylo project
  init                  Set up the Metro CLI alias
  clean                 Run flutter clean and flutter pub get
    --ios               Deep clean iOS (remove Pods, re-run pod install)
    --android           Deep clean Android (run gradlew clean)
    --all               Deep clean both iOS and Android
  metro <command>       Run a metro command (e.g. make:model)
  ios:pod-refresh       Remove iOS pods and run pod install --repo-update
  locale:find-untranslated   Find hardcoded strings not wrapped in .tr()/trans()
    --format=<md|json>  Report format; --stdout to print; --ci to fail on findings
  locale:check-missing-keys  Compare lang/*.json against a baseline locale
    --file=<name>       Baseline locale (default: en.json); --stdout; --ci; --strict
  test                  Format and run Flutter tests
    --no-format         Skip formatting before running tests
    --filter=<pattern>  Filter tests by name
    --coverage          Collect code coverage
    --path=<dir>        Test directory path (default: test)
  self-update           Update nylo to the latest version

Options:
  -h, --help            Show usage information
  -v, --version         Show version
```

## Commands

### `nylo new <project_name>`

Create a new Nylo project:

```bash
nylo new my_app
```

This will:
1. Clone the Nylo template
2. Configure your project name across all platform files (Android, iOS, pubspec.yaml, .env)
3. Install Flutter dependencies

Project names are automatically converted to snake_case.

### `nylo init`

Set up the Metro CLI alias for an existing Nylo project:

```bash
nylo init
```

This configures the `metro` command in your shell so you can use it from anywhere within your project.

### `nylo clean`

Clean your Flutter project and reinstall dependencies:

```bash
nylo clean
```

This runs:
1. `flutter clean` - Removes build artifacts
2. `flutter pub get` - Reinstalls dependencies

Use platform flags for deep cleaning:

```bash
nylo clean --ios       # Deep clean iOS (removes Pods, .symlinks, Podfile.lock, re-runs pod install)
nylo clean --android   # Deep clean Android (runs gradlew clean)
nylo clean --all       # Deep clean both iOS and Android
```

### `nylo test`

Format and run Flutter tests with pretty output:

```bash
nylo test
```

Options:

```bash
nylo test --no-format              # Skip formatting before running tests
nylo test --filter "login"         # Filter tests by name
nylo test --coverage               # Collect code coverage
nylo test --path integration_test  # Specify test directory
nylo test --filter "auth" --coverage
```

### `nylo metro <command>`

Run metro commands without needing the metro alias:

```bash
nylo metro make:model User
nylo metro make:page HomePage
nylo metro make:controller HomeController
```

This runs `dart run nylo_framework:main <command>` behind the scenes.

### `nylo ios:pod-refresh`

Refresh CocoaPods dependencies for an iOS project:

```bash
nylo ios:pod-refresh
```

This runs:
1. Removes `ios/Pods`, `ios/.symlinks`, and `ios/Podfile.lock`
2. Runs `pod install --repo-update` in the `ios/` directory

macOS-only. Useful when pods become stale or out of sync.

### `nylo locale:find-untranslated`

Scan your `lib/resources/pages/` and `lib/resources/widgets/` for hardcoded, user-facing strings that are **not** wrapped in Nylo's `.tr()` / `trans()` translation calls. To stay focused on real UI copy, only strings inside text widgets (`Text`, `SelectableText`, `RichText`, `TextSpan`) are reported — keys, route paths, and data-model values are ignored. Parsing happens via the analyzer AST, so `"welcome".tr()` is never a false positive:

```bash
nylo locale:find-untranslated                      # writes nylo-i18n-baseline.md
nylo locale:find-untranslated --stdout             # print the report instead
nylo locale:find-untranslated --format json -o report.json
nylo locale:find-untranslated --ci                 # exit 1 if any finding exists
```

Add a `// i18n-ignore` comment above a line to suppress it. Defaults (scan globs, the text widgets to inspect, etc.) can be overridden with an optional `nylo_i18n.yaml` at your project root — e.g. add your own text widgets via `text_widgets:` (or string-bearing helpers via `text_functions:`).

### `nylo locale:check-missing-keys`

Compare every `lang/*.json` locale file against a baseline locale (default `en.json`) and report missing, empty, and extra keys per locale. Nested JSON is flattened to dot-notation (`navigation.home`), matching Nylo's key resolution:

```bash
nylo locale:check-missing-keys                     # writes nylo-i18n-missing-keys.md
nylo locale:check-missing-keys --stdout
nylo locale:check-missing-keys --file en.json --format txt
nylo locale:check-missing-keys --ci                # exit 1 on missing/empty keys
nylo locale:check-missing-keys --ci --strict       # also exit 1 on extra keys
```

By default, extra keys alone do not fail `--ci`; add `--strict` to enforce identical key sets, so locales with keys absent from the baseline also fail. Invalid JSON or a missing baseline produces a clean error and exit code 1.

### `nylo self-update`

Update nylo to the latest version from pub.dev:

```bash
nylo self-update
```

## Metro CLI

Once Metro is set up via `nylo init`, you can generate files for your Nylo project:

```bash
metro make:page HomePage
metro make:controller HomeController
metro make:model User
```

## Requirements

- Dart SDK >= 3.9.0
- Flutter
- Git

## Links

- [Nylo Documentation](https://nylo.dev/docs)
- [GitHub Repository](https://github.com/nylo-core/nylo_installer)
