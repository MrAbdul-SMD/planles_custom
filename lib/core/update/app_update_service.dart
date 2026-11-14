import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.tagName,
    required this.releaseName,
    required this.releaseNotes,
    required this.htmlUrl,
    required this.assetUrl,
    required this.assetName,
    required this.publishedAt,
  });

  final String currentVersion;
  final String latestVersion;
  final String tagName;
  final String releaseName;
  final String releaseNotes;
  final String htmlUrl;
  final String? assetUrl;
  final String? assetName;
  final DateTime? publishedAt;
}

class AppUpdateService {
  AppUpdateService({Dio? dio, String? repo})
      : _dio = dio ??
            Dio(
              BaseOptions(
                headers: const {
                  'Accept': 'application/vnd.github+json',
                  'X-GitHub-Api-Version': '2022-11-28',
                },
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
              ),
            ),
        _repo = repo ?? 'MrAbdul-SMD/planles_custom';

  final Dio _dio;
  final String _repo;

  static const String releasesApiBase = 'https://api.github.com/repos';

  Future<AppUpdateInfo?> checkForUpdate({bool includePrereleases = false}) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final current = _normalizeVersion(packageInfo.version);
    final release = await _fetchLatestRelease(includePrereleases: includePrereleases);
    if (release == null) return null;

    final tag = (release['tag_name'] as String? ?? '').trim();
    final latestRaw = tag.isNotEmpty ? tag : (release['name'] as String? ?? '');
    final latest = _normalizeVersion(latestRaw);
    final latestBuild = _parseBuildNumber(latestRaw);
    final currentBuild = _parseBuildNumber(packageInfo.version);

    final hasUpdate = _isNewerVersion(
      latest: latest,
      current: current,
      latestBuild: latestBuild,
      currentBuild: currentBuild,
      latestTagRaw: latestRaw,
    );
    if (!hasUpdate) return null;

    final displayLatest = latest.isNotEmpty ? latest : latestRaw.trim().replaceFirst(RegExp(r'^v', caseSensitive: false), '');

    final asset = _selectAsset(release['assets'] as List<dynamic>? ?? const []);
    DateTime? publishedAt;
    final publishedRaw = release['published_at'] as String?;
    if (publishedRaw != null && publishedRaw.isNotEmpty) {
      publishedAt = DateTime.tryParse(publishedRaw);
    }

    return AppUpdateInfo(
      currentVersion: packageInfo.version,
      latestVersion: displayLatest,
      tagName: tag,
      releaseName: (release['name'] as String? ?? tag).trim(),
      releaseNotes: (release['body'] as String? ?? '').trim(),
      htmlUrl: (release['html_url'] as String? ?? 'https://github.com/$_repo/releases').trim(),
      assetUrl: asset?.url,
      assetName: asset?.name,
      publishedAt: publishedAt,
    );
  }

  Future<Map<String, dynamic>?> _fetchLatestRelease({required bool includePrereleases}) async {
    try {
      if (!includePrereleases) {
        final res = await _dio.get<Map<String, dynamic>>('$releasesApiBase/$_repo/releases/latest');
        final data = res.data;
        if (data == null) return null;
        if (data['draft'] == true) return null;
        return data;
      }

      final res = await _dio.get<List<dynamic>>(
        '$releasesApiBase/$_repo/releases',
        queryParameters: const {'per_page': 10},
      );
      final list = res.data ?? const [];
      for (final item in list) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        if (map['draft'] == true) continue;
        return map;
      }
      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('AppUpdateService: release check failed: ${e.message}');
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  _ReleaseAsset? _selectAsset(List<dynamic> assets) {
    final parsed = <_ReleaseAsset>[];
    for (final a in assets) {
      if (a is! Map) continue;
      final name = (a['name'] as String? ?? '').trim();
      final url = (a['browser_download_url'] as String? ?? '').trim();
      if (name.isEmpty || url.isEmpty) continue;
      parsed.add(_ReleaseAsset(name: name, url: url));
    }
    if (parsed.isEmpty) return null;

    if (kIsWeb) return null;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _pickByPriority(parsed, const [
          'app-release.apk',
          'arm64-v8a-release.apk',
          '.apk',
        ]);
      case TargetPlatform.windows:
        return _pickByPriority(parsed, const [
          'windows-x64-setup.exe',
          '-setup.exe',
          '.exe',
          'windows',
          '.msi',
        ]);
      case TargetPlatform.macOS:
        return _pickByPriority(parsed, const [
          '.dmg',
          'macos-app.zip',
          'macos',
          '.zip',
        ]);
      case TargetPlatform.linux:
        return _pickByPriority(parsed, const [
          '.AppImage',
          '.deb',
          '.tar.gz',
          'linux',
        ]);
      case TargetPlatform.iOS:
        return _pickByPriority(parsed, const ['.ipa']);
      case TargetPlatform.fuchsia:
        return parsed.first;
    }
  }

  _ReleaseAsset? _pickByPriority(List<_ReleaseAsset> assets, List<String> needles) {
    for (final needle in needles) {
      for (final asset in assets) {
        if (asset.name.toLowerCase().contains(needle.toLowerCase())) return asset;
      }
    }
    return null;
  }

  static String _normalizeVersion(String raw) {
    var v = raw.trim();
    if (v.startsWith('v') || v.startsWith('V')) v = v.substring(1);
    final plus = v.indexOf('+');
    if (plus >= 0) v = v.substring(0, plus);
    if (v.startsWith('build-')) return '';
    return v;
  }

  static int? _parseBuildNumber(String raw) {
    final match = RegExp(r'build[-_]?(\d+)', caseSensitive: false).firstMatch(raw.trim());
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  static bool _isNewerVersion({
    required String latest,
    required String current,
    required int? latestBuild,
    required int? currentBuild,
    required String latestTagRaw,
  }) {
    if (latestBuild != null && currentBuild != null) {
      return latestBuild > currentBuild;
    }

    final l = _parseSemver(latest);
    final c = _parseSemver(current);
    if (l != null && c != null) {
      for (var i = 0; i < 3; i++) {
        if (l[i] != c[i]) return l[i] > c[i];
      }
      // Same semver: a build-tagged release newer than a plain semver install is treated as update.
      if (latestBuild != null && currentBuild == null) return true;
      return false;
    }

    // If latest is a build/prerelease tag and current is semver, offer it (useful for CI "everytime" builds).
    if (latestBuild != null && latest.isEmpty) return true;

    return latest.isNotEmpty && current.isNotEmpty && latest != current && latestTagRaw.trim().isNotEmpty;
  }

  static List<int>? _parseSemver(String v) {
    final core = v.split('-').first.trim();
    final parts = core.split('.');
    if (parts.isEmpty || parts.length > 4) return null;
    final nums = <int>[0, 0, 0];
    for (var i = 0; i < parts.length && i < 3; i++) {
      final n = int.tryParse(parts[i].replaceAll(RegExp(r'[^0-9]'), ''));
      if (n == null) return null;
      nums[i] = n;
    }
    return nums;
  }
}

class _ReleaseAsset {
  const _ReleaseAsset({required this.name, required this.url});
  final String name;
  final String url;
}
