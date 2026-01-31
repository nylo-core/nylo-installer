# Nylo Installer

A CLI tool to scaffold new [Nylo](https://nylo.dev) Flutter projects.

## Installation

```bash
dart pub global activate nylo_installer
```

## Usage

Create a new Nylo project:

```bash
nylo new my_app
```

This will:
1. Clone the Nylo template
2. Configure your project name across all platform files
3. Install Flutter dependencies

### Options

```
nylo new <project_name>

Options:
  -h, --help    Show usage information
  -v, --version Show version
```

## Metro CLI

To set up the Metro CLI, run:

```bash
nylo init
```

Metro helps generate files for your Nylo project:

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
