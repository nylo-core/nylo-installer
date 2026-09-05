## [1.9.0] - 2026-09-05

### Added
- `Spinner.succeed`, `Spinner.fail` and `Spinner.warn` (✓ / ✗ / ! completion lines, with an optional dimmed detail and the step duration), plus `Spinner.isRunning`, `Spinner.elapsed`, `Spinner.isInteractive` and `Spinner.interactiveOverride`
- `NyloConsole` inline style helpers (`bold`, `dim`, `green`, `red`, `yellow`, `cyan`, `magenta`), `formatDuration`, `friendlyPath` (home directory shown as `~`), `writeErrorDetail` and `writeWarningDetail`
- `Validators.verifyPrerequisites()` returns a `PrerequisiteCheck` (detected Git and Flutter versions plus a list of problems) without printing or exiting, and probes both tools concurrently. `Validators.parseGitVersion` and `Validators.parseFlutterVersion` extract version numbers from the tools' output. `checkPrerequisites()` behaves as before
- Tests for the spinner, the formatting helpers, prerequisite parsing, and the rendering of a failed `nylo new` step

### Changed
- `nylo new` output redesign. Every step, including the prerequisites check, now runs under the spinner (the old `├ □ Checking prerequisites...` line never resolved). The spinner draws its first frame immediately instead of leaving a blank line between steps, shows the elapsed time on steps that take longer than a couple of seconds, and each completed step shows its duration. The header now names the project folder and where it is being created, the banner carries the installer version, the prerequisites line shows the detected Flutter and Git versions, and the closing summary reports the total time in place of the `[SUCCESS]` label
- `nylo new` failure output: a failed step is rendered as a `✗` line with the underlying error indented beneath it (git's "Cloning into" progress noise is dropped) instead of being printed over a running spinner. When `flutter pub get` fails the command now exits 1 and prints the commands needed to finish the setup, instead of reporting success. App key warnings list the failing metro command and how to retry it
- `Spinner` hides the cursor while animating and restores it when a step finishes or the command is interrupted with Ctrl+C (exit code 130), and degrades to plain line-based output when stdout is not a terminal (CI, piped output, or consoles without ANSI support). Completed steps in every command that uses the spinner (`clean`, `test`, `ios:pod-refresh`) show their duration when it is one second or more
- Reformatted three test files with the current Dart formatter so the publish workflow's format check passes

## [1.8.0] - 2026-06-08

### Added
- `nylo locale:find-untranslated` command: scans Dart source via the analyzer AST for hardcoded, user-facing strings that are not wrapped in Nylo's `.tr()` / `trans()` translation calls. Only strings inside text widgets (`Text`, `SelectableText`, `RichText`, `TextSpan`) are reported, so keys, route paths, and data values are ignored. Supports `--format=<md|json>`, `--stdout`, `--ci` (exit 1 on findings), `--output/-o`, and `--path`, plus `// i18n-ignore` line suppression and an optional `nylo_i18n.yaml` config to override scan globs and text widgets/functions
- `nylo locale:check-missing-keys` command: compares every `lang/*.json` locale file against a baseline locale (default `en.json`) and reports missing, empty, and extra keys per locale, flattening nested JSON to dot-notation to match Nylo's key resolution. Supports `--file`, `--format=<md|txt|json>`, `--stdout`, `--ci` (exit 1 on missing/empty keys), `--strict` (also fail on extra keys), `--output/-o`, and `--path`; invalid JSON or a missing baseline produces a clean error and exit code 1
- Per-command help: `nylo <command> -h` / `--help` now prints a usage block (description, usage line, and option list) for `new`, `clean`, `test`, `ios:pod-refresh`, `self-update`, and both `locale:*` commands. The main usage output gained the locale commands, per-command examples, and a `Run 'nylo <command> -h' for command-specific help.` hint
- Exported the locale audit commands and supporting library (`models`, `config`, `file_collector`, `locale_compare`, `scanner`, `reporter`) from `nylo_installer.dart` for programmatic use

### Changed
- Update-available banner is now suppressed when stdout is not an interactive terminal (CI or piped/redirected output), preventing it from polluting machine-readable output such as the `locale:*` JSON reports
- `self-update` now parses arguments and supports `-h` / `--help`
- Raised the minimum Dart SDK to `>=3.9.0` and added the `analyzer: ^12.0.0` and `glob: ^2.1.0` dependencies, used by the locale scanner and file collector
- Reformatted the codebase with the Dart 3.9 formatter (trailing-comma style)

## [1.7.0] - 2026-05-07

### Added
- `nylo ios:pod-refresh` command: removes iOS build artifacts (`ios/Pods`, `ios/.symlinks`, `ios/Podfile.lock`) and runs `pod install --repo-update` to refresh CocoaPods dependencies. macOS-only; errors when `ios/` is missing or when run on a non-macOS platform
- Comprehensive tests for `IosPodRefreshCommand` covering artifact removal, directory validation, and CLI help output

## [1.6.3] - 2026-04-29

### Fixed
- Metro command output: build hook progress and success messages now render on separate lines. `ProcessRunner.run` with `inheritStdio: true` now uses `ProcessStartMode.inheritStdio` so the child process is connected directly to the terminal and detects a TTY (also enables interactive metro prompts via inherited stdin)

## [1.6.2] - 2026-04-23

### Changed
- Bumped dependency version constraints: `args` to `^2.7.0`, `path` to `^1.9.1`, and `test` to `^1.31.0`
- Refreshed `pubspec.lock` with updated transitive dependencies (analyzer, matcher, meta, source_span, vm_service, etc.)

## [1.6.1] - 2026-03-29

### Changed
- Test command: redesigned output to group results by test suite with bold suite headers (e.g. `Test\AuthTest`)
- Test command: results now stream in real-time as each test completes, rather than buffering all output
- Test command: updated summary format to show `Tests: X passed` and `Duration: Xs`
- Test command: added suite display name derivation from file paths using PascalCase

## [1.6.0] - 2026-03-28

### Added
- `nylo metro <command>` command: run metro commands via `dart run nylo_framework:main` (e.g. `nylo metro make:model User`)

### Fixed
- Self-update command: use plain `write()` instead of `writeSuccess()` for the "Updated nylo_installer" confirmation message to remove misleading `[SUCCESS]` prefix

## [1.5.3] - 2026-03-28

### Changed
- Test command: removed step counter labels ([1/2], [2/2]) from output for cleaner UI

## [1.5.2] - 2026-03-28

### Changed
- README: added `self-update` command to the usage summary and as its own command section

## [1.5.1] - 2026-03-28

### Fixed
- Self-update command: use plain `write()` instead of `writeSuccess()` for the "already on latest version" message to remove misleading `[SUCCESS]` prefix

## [1.5.0] - 2026-03-28

### Added
- `nylo self-update` command: updates nylo_installer to the latest version from pub.dev
- Automatic update detection: shows a styled banner after any command when a newer version is available
- Version check caching in `~/.nylo/version_cache.json` with 24-hour TTL
- 2-second HTTP timeout for version checks — network failures are silently ignored
- `nylo test` command: format and run Flutter tests with pretty JSON output, per-test timing, and aggregated pass/fail summary
- `nylo test` flags: `--no-format`, `--filter=<pattern>`, `--coverage`, `--path=<dir>`
- `nylo clean` platform-specific deep cleaning with `--ios`, `--android`, and `--all` flags
- iOS deep clean: removes Pods, .symlinks, Podfile.lock and re-runs `pod install --repo-update`
- Android deep clean: runs `gradlew clean`
- Platform directory validation before attempting platform-specific cleans
- Comprehensive tests for `CleanCommand` and `TestCommand`

### Changed
- `CleanCommand.run()` now accepts optional arguments for flag parsing
- CLI argument parser uses `allowTrailingOptions: false` for correct subcommand argument routing
- Updated help text with all new command flags and usage examples

## [1.4.0] - 2026-02-14

### Added
- Pubspec description rebranding: replaces `A new Nylo Flutter application.` with `A new Flutter application.` in scaffolded projects
- iOS `RunnerTests` bundle identifier replacement in `project.pbxproj` (`com.nylo.dev.RunnerTests` to `com.<projectName>.ios.RunnerTests`)
- iOS `Info.plist` display name replacement (updates `Nylo` to project title case name)
- Android `AndroidManifest.xml` label replacement (updates `android:label="Nylo"` to project title case name)
- Comprehensive test coverage for all file operations in `NewCommand` (pubspec, Android, iOS, .env, .git removal, test imports)

## [1.3.1] - 2026-02-12

### Fixed
- Use backticks instead of double quotes in `NewCommand` doc comment to prevent angle brackets from being interpreted as HTML (fixes pub points static analysis)

## [1.3.0] - 2026-02-10

### Added
- Kotlin source directory renaming during project scaffolding (renames `com/nylo/` to `com/<projectName>/`)
- Automatic `package` declaration update in `MainActivity.kt` to match the new project name

## [1.2.0] - 2026-02-06

### Added
- Test file import rewriting in NewCommand: updates `import '/` to `import 'package:<project_name>/` when scaffolding new Nylo projects

## [1.1.0] - 2026-02-01

### Added
- Automatic environment file setup (copies `.env-example` to `.env`)
- App key generation step using `nylo_framework:main make:key`
- New console UI methods: `writeTaskHeader`, `writeSubtaskPending`, `writeSubtaskComplete`

### Changed
- Improved console output with task headers and subtask indicators
- Updated spinner alignment for better visual consistency
- Updated bundle identifier patterns for Android (`com.nylo.android`) and iOS (`com.nylo.ios`)

## [1.0.2] - 2026-01-31

* Update screenshots

## [1.0.1] - 2026-01-31

* Update screenshots

## [1.0.0] - 2026-01-31

* Initial release
* Added `nylo new <project_name>` command to create new Nylo Flutter projects
* Added `nylo init` command to initialize Nylo in the current directory
* Automatic project scaffolding from official Nylo template
* Platform-specific configuration updates (Android, iOS)
* Automatic dependency installation with `flutter pub get`
