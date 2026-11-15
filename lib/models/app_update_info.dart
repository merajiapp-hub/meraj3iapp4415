class AppUpdateInfo {
  final String latestVersion;
  final int latestBuildNumber;
  final String? minSupportedVersion;
  final String apkUrl;
  final String apkSize;
  final String releaseDate;
  final bool forceUpdate;
  final List<String> releaseNotes;
  final String? githubReleaseUrl;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.latestBuildNumber,
    this.minSupportedVersion,
    required this.apkUrl,
    required this.apkSize,
    required this.releaseDate,
    required this.forceUpdate,
    required this.releaseNotes,
    this.githubReleaseUrl,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      latestVersion: json['latestVersion']?.toString() ?? '1.0.0',
      latestBuildNumber: (json['latestBuildNumber'] as num?)?.toInt() ?? 0,
      minSupportedVersion: json['minSupportedVersion']?.toString(),
      apkUrl: json['apkUrl']?.toString() ?? '',
      apkSize: json['apkSize']?.toString() ?? '',
      releaseDate: json['releaseDate']?.toString() ?? '',
      forceUpdate: json['forceUpdate'] == true,
      releaseNotes: (json['releaseNotes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      githubReleaseUrl: json['githubReleaseUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latestVersion': latestVersion,
      'latestBuildNumber': latestBuildNumber,
      'minSupportedVersion': minSupportedVersion,
      'apkUrl': apkUrl,
      'apkSize': apkSize,
      'releaseDate': releaseDate,
      'forceUpdate': forceUpdate,
      'releaseNotes': releaseNotes,
      'githubReleaseUrl': githubReleaseUrl,
    };
  }

  /// يتحقق مما إذا كان هناك تحديث متوفر بمقارنة الإصدار ورقم البناء
  bool isUpdateAvailable({
    required String currentVersion,
    required int currentBuildNumber,
  }) {
    // 1) المقارنة برقم البناء أولاً (Build Number)
    if (latestBuildNumber > currentBuildNumber) {
      return true;
    }

    // 2) المقارنة برقم الإصدار النصي (Semantic Versioning: X.Y.Z)
    return _isNewerVersion(currentVersion, latestVersion);
  }

  static bool _isNewerVersion(String current, String latest) {
    try {
      final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < currentParts.length ? currentParts[i] : 0;
        final l = i < latestParts.length ? latestParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (_) {}
    return false;
  }
}
