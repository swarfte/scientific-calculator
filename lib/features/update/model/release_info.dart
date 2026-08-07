import 'app_version.dart';

/// GitHub Release 中的單一檔案（asset）。
class ReleaseAsset {
  const ReleaseAsset({
    required this.name,
    required this.browserDownloadUrl,
    required this.size,
    required this.contentType,
  });

  /// 檔名，例如 `scientific_calculator-Windows-Setup.exe`。
  final String name;

  /// 可直接下載的 URL（不需驗證）。
  final String browserDownloadUrl;

  /// 檔案大小（bytes）；GitHub 未提供時為 `0`。
  final int size;

  final String contentType;

  /// 人類可讀的大小，例如 `11.0 MB`；未知大小時回傳 `null`。
  String? get humanSize => size > 0 ? formatBytes(size) : null;

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final url = json['browser_download_url'];

    if (name is! String || url is! String) {
      throw const FormatException('Release asset 缺少 name 或 browser_download_url');
    }

    return ReleaseAsset(
      name: name,
      browserDownloadUrl: url,
      size: json['size'] is int ? json['size'] as int : 0,
      contentType: json['content_type'] is String
          ? json['content_type'] as String
          : 'application/octet-stream',
    );
  }
}

/// 把 bytes 格式化為 `11.0 MB` 這類字串。
///
/// 以 1024 為基底；小於 1 KB 時直接顯示 bytes。
String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];

  var value = bytes.toDouble();
  var unitIndex = 0;

  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  // bytes 沒有小數點的意義。
  final digits = unitIndex == 0 ? 0 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unitIndex]}';
}

/// `GET /repos/{owner}/{repo}/releases/latest` 回傳的 Release 資訊。
class ReleaseInfo {
  const ReleaseInfo({
    required this.version,
    required this.tagName,
    required this.title,
    required this.htmlUrl,
    required this.body,
    required this.publishedAt,
    required this.assets,
  });

  /// 由 [tagName]（優先）或 [title] 解析出的版本。
  final AppVersion version;

  /// 例如 `v2026.8.7-build.6-attempt.1`。
  final String tagName;

  /// 例如 `2026.8.7 (Build 6)`。
  final String title;

  /// Release 頁面網址；下載失敗時作為使用者的後備出口。
  final String htmlUrl;

  /// Release notes（Markdown 原文）。
  final String body;

  final DateTime? publishedAt;

  final List<ReleaseAsset> assets;

  /// 解析 GitHub API 的 JSON。
  ///
  /// 版本解析順序為 `tag_name` → `name`；兩者都解析不出版本時擲回
  /// [FormatException]，讓呼叫端一律以「檢查失敗」處理，而不是誤判成有更新。
  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    final tagName = json['tag_name'] is String ? json['tag_name'] as String : '';
    final title = json['name'] is String ? json['name'] as String : '';

    final version =
        AppVersion.tryParseTag(tagName) ?? AppVersion.tryParseTitle(title);

    if (version == null) {
      throw FormatException(
        '無法從 Release 解析版本（tag_name: "$tagName", name: "$title"）',
      );
    }

    final rawAssets = json['assets'];
    final assets = <ReleaseAsset>[];

    if (rawAssets is List) {
      for (final rawAsset in rawAssets) {
        if (rawAsset is Map<String, dynamic>) {
          assets.add(ReleaseAsset.fromJson(rawAsset));
        }
      }
    }

    return ReleaseInfo(
      version: version,
      tagName: tagName,
      title: title.isNotEmpty ? title : version.display,
      htmlUrl: json['html_url'] is String ? json['html_url'] as String : '',
      body: json['body'] is String ? json['body'] as String : '',
      publishedAt: json['published_at'] is String
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      assets: assets,
    );
  }
}
