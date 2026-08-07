/// 可比較的應用程式版本。
///
/// CI (`.github/workflows/build-release.yml`) 產生的版本格式為：
///
/// - `app-version`：`date '+%Y.%-m.%-d'`，例如 `2026.8.7`
/// - `build-number`：`GITHUB_RUN_NUMBER`，單調遞增的整數，例如 `6`
/// - `release-tag`：`v2026.8.7-build.6-attempt.1`
/// - `release-title`：`2026.8.7 (Build 6)`
///
/// 每個平台都以 `--build-name=<app-version> --build-number=<build-number>`
/// 建置，因此 `PackageInfo.version` / `PackageInfo.buildNumber` 會剛好等於
/// `2026.8.7` / `6`，可以直接與 Release 解析出的版本比較。
class AppVersion implements Comparable<AppVersion> {
  const AppVersion({required this.segments, required this.build});

  /// 以 `.` 分隔的數字區段，例如 `2026.8.7` → `[2026, 8, 7]`。
  final List<int> segments;

  /// 建置編號；解析不到時為 `0`。
  final int build;

  /// `v2026.8.7-build.6-attempt.1` 或 `2026.8.7-build.6`。
  ///
  /// `attempt` 只是同一次 CI run 的重試序號，不參與版本比較。
  static final RegExp _tagPattern = RegExp(
    r'^v?(\d+(?:\.\d+)*)-build\.(\d+)(?:-attempt\.\d+)?$',
  );

  /// Release 標題，例如 `2026.8.7 (Build 6)`。
  static final RegExp _titlePattern = RegExp(
    r'^(\d+(?:\.\d+)*)\s*\(\s*build\s+(\d+)\s*\)$',
    caseSensitive: false,
  );

  /// 純版本號，例如 `v2026.8.7`（沒有 build 資訊時視為 build `0`）。
  static final RegExp _plainPattern = RegExp(r'^v?(\d+(?:\.\d+)*)$');

  /// 從 `PackageInfo` 解析目前執行中的版本。
  ///
  /// `version` 允許帶有 `+n` 或 `-suffix` 後綴（本機以 `flutter run` 執行時，
  /// 某些平台會把 pubspec 的 `1.0.0+1` 原封不動帶進來）；此時後綴會被忽略，
  /// 建置編號一律以 `buildNumber` 為準。
  ///
  /// 無法解析時回傳 `null`。
  static AppVersion? tryParsePackageInfo(String version, String buildNumber) {
    final trimmed = version.trim();
    final withoutSuffix = trimmed.split(RegExp(r'[+\-]')).first;

    final segments = _tryParseSegments(withoutSuffix);
    if (segments == null) {
      return null;
    }

    return AppVersion(
      segments: segments,
      build: int.tryParse(buildNumber.trim()) ?? 0,
    );
  }

  /// 從 GitHub Release 的 `tag_name` 解析版本。無法解析時回傳 `null`。
  static AppVersion? tryParseTag(String tag) {
    final trimmed = tag.trim();

    final tagMatch = _tagPattern.firstMatch(trimmed);
    if (tagMatch != null) {
      final segments = _tryParseSegments(tagMatch.group(1)!);
      if (segments != null) {
        return AppVersion(
          segments: segments,
          build: int.parse(tagMatch.group(2)!),
        );
      }
    }

    final plainMatch = _plainPattern.firstMatch(trimmed);
    if (plainMatch != null) {
      final segments = _tryParseSegments(plainMatch.group(1)!);
      if (segments != null) {
        return AppVersion(segments: segments, build: 0);
      }
    }

    return null;
  }

  /// 從 GitHub Release 的 `name`（標題）解析版本。無法解析時回傳 `null`。
  ///
  /// 作為 [tryParseTag] 的後備：若哪天 CI 改了 tag 格式但標題仍維持
  /// `2026.8.7 (Build 6)`，更新檢查仍能運作。
  static AppVersion? tryParseTitle(String name) {
    final match = _titlePattern.firstMatch(name.trim());
    if (match == null) {
      return null;
    }

    final segments = _tryParseSegments(match.group(1)!);
    if (segments == null) {
      return null;
    }

    return AppVersion(segments: segments, build: int.parse(match.group(2)!));
  }

  static List<int>? _tryParseSegments(String raw) {
    if (raw.isEmpty) {
      return null;
    }

    final segments = <int>[];
    for (final part in raw.split('.')) {
      final value = int.tryParse(part);
      if (value == null || value < 0) {
        return null;
      }
      segments.add(value);
    }

    return segments;
  }

  /// 先逐段比較版本號（長度不同時以 `0` 補齊），相同時再比較建置編號。
  @override
  int compareTo(AppVersion other) {
    final length = segments.length > other.segments.length
        ? segments.length
        : other.segments.length;

    for (var i = 0; i < length; i++) {
      final left = i < segments.length ? segments[i] : 0;
      final right = i < other.segments.length ? other.segments[i] : 0;

      if (left != right) {
        return left.compareTo(right);
      }
    }

    return build.compareTo(other.build);
  }

  bool isNewerThan(AppVersion other) => compareTo(other) > 0;

  /// 例如 `2026.8.7 (build 6)`。
  String get display => '${segments.join('.')} (build $build)';

  /// 只有版本號，例如 `2026.8.7`。
  String get versionName => segments.join('.');

  /// 去掉尾端的 `0` 區段，讓 `2026.8.7` 與 `2026.8.7.0` 有相同的
  /// [operator ==] 與 [hashCode]（與 [compareTo] 的結果一致）。
  List<int> get _normalized {
    var end = segments.length;
    while (end > 1 && segments[end - 1] == 0) {
      end--;
    }
    return segments.sublist(0, end);
  }

  @override
  bool operator ==(Object other) {
    return other is AppVersion && compareTo(other) == 0;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(_normalized), build);

  @override
  String toString() => display;
}
