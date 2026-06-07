import 'dart:convert';
import 'dart:io';

import '../constants.dart';

/// Information about an available update
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;

  UpdateInfo({required this.currentVersion, required this.latestVersion});
}

/// Checks pub.dev for newer versions of nylo_installer
class VersionChecker {
  static const Duration _checkInterval = Duration(hours: 24);
  static const Duration _httpTimeout = Duration(seconds: 2);

  /// Check if an update is available, using a cached result when possible.
  /// Returns [UpdateInfo] if a newer version exists, null otherwise.
  /// Never throws — all errors are silently caught.
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final cache = _readCache();
      final now = DateTime.now().millisecondsSinceEpoch;

      String? latestVersion;

      if (cache != null) {
        final lastCheck = cache['lastCheck'] as int? ?? 0;
        final elapsed = Duration(milliseconds: now - lastCheck);

        if (elapsed < _checkInterval) {
          // Use cached version
          latestVersion = cache['latestVersion'] as String?;
        }
      }

      // Fetch fresh version if cache is missing or expired
      latestVersion ??= await fetchLatestVersion();
      if (latestVersion == null) return null;

      _writeCache(now, latestVersion);

      if (_isNewer(latestVersion, Constants.version)) {
        return UpdateInfo(
          currentVersion: Constants.version,
          latestVersion: latestVersion,
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch the latest version string from pub.dev.
  /// Returns null on any failure.
  Future<String?> fetchLatestVersion() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = _httpTimeout;

      final request = await client.getUrl(Uri.parse(Constants.pubDevApiUrl));
      final response = await request.close().timeout(_httpTimeout);

      if (response.statusCode != 200) {
        client.close();
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      client.close();

      final json = jsonDecode(body) as Map<String, dynamic>;
      final latest = json['latest'] as Map<String, dynamic>?;
      return latest?['version'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Read the cached version check result.
  Map<String, dynamic>? _readCache() {
    try {
      final file = File('${Constants.cacheDirPath}/${Constants.cacheFileName}');
      if (!file.existsSync()) return null;
      final content = file.readAsStringSync();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Write a version check result to the cache file.
  void _writeCache(int timestampMs, String latestVersion) {
    try {
      final dir = Directory(Constants.cacheDirPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final file = File('${Constants.cacheDirPath}/${Constants.cacheFileName}');
      file.writeAsStringSync(
        jsonEncode({'lastCheck': timestampMs, 'latestVersion': latestVersion}),
      );
    } catch (_) {
      // Silently ignore write failures
    }
  }

  /// Returns true if [latest] is a newer semver than [current].
  static bool _isNewer(String latest, String current) {
    final latestParts = latest.split('.').map(int.tryParse).toList();
    final currentParts = current.split('.').map(int.tryParse).toList();

    for (var i = 0; i < 3; i++) {
      final l = i < latestParts.length ? (latestParts[i] ?? 0) : 0;
      final c = i < currentParts.length ? (currentParts[i] ?? 0) : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  /// Print the update available banner.
  static void printUpdateBanner(UpdateInfo info) {
    final message =
        'Update available: ${info.currentVersion} → ${info.latestVersion}';
    final action = 'Run `nylo self-update` to update';
    final innerWidth = message.length > action.length
        ? message.length + 4
        : action.length + 4;

    final topBorder = '╔${'═' * innerWidth}╗';
    final bottomBorder = '╚${'═' * innerWidth}╝';
    final messageLine =
        '║  $message${' ' * (innerWidth - message.length - 2)}║';
    final actionLine = '║  $action${' ' * (innerWidth - action.length - 2)}║';

    stdout.writeln('');
    stdout.writeln('\x1B[93m$topBorder\x1B[0m');
    stdout.writeln('\x1B[93m$messageLine\x1B[0m');
    stdout.writeln('\x1B[93m$actionLine\x1B[0m');
    stdout.writeln('\x1B[93m$bottomBorder\x1B[0m');
  }
}
