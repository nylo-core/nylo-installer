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
