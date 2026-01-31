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
