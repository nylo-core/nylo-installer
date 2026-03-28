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
