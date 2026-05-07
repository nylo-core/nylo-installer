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

- Dart SDK >= 3.0.0
- Flutter
- Git

## Links

- [Nylo Documentation](https://nylo.dev/docs)
- [GitHub Repository](https://github.com/nylo-core/nylo_installer)
