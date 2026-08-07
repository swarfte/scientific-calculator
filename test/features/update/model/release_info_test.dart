import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/features/update/model/release_info.dart';

import 'release_fixture.dart';

void main() {
  Map<String, dynamic> decode(String json) =>
      jsonDecode(json) as Map<String, dynamic>;

  group('ReleaseInfo.fromJson', () {
    test('解析真實的 GitHub Release 回應', () {
      final release = ReleaseInfo.fromJson(decode(latestReleaseJson));

      expect(release.tagName, 'v2026.8.7-build.6-attempt.1');
      expect(release.title, '2026.8.7 (Build 6)');
      expect(release.version.versionName, '2026.8.7');
      expect(release.version.build, 6);
      expect(release.publishedAt, DateTime.utc(2026, 8, 7, 5, 2, 14));
      expect(release.htmlUrl, contains('/releases/tag/'));
      expect(release.body, contains("What's Changed"));
    });

    test('三個平台的 asset 都被解析出來', () {
      final release = ReleaseInfo.fromJson(decode(latestReleaseJson));

      expect(release.assets.map((asset) => asset.name), [
        'scientific_calculator-Android.apk',
        'scientific_calculator-Windows-Setup.exe',
        'scientific_calculator.dmg',
      ]);

      final windows = release.assets[1];
      expect(windows.size, 11575039);
      expect(windows.humanSize, '11.0 MB');
      expect(
        windows.browserDownloadUrl,
        'https://github.com/swarfte/Sci-Calc/releases/download/'
        'v2026.8.7-build.6-attempt.1/scientific_calculator-Windows-Setup.exe',
      );
    });

    test('tag_name 無法解析時退回用 name（標題）', () {
      final release = ReleaseInfo.fromJson({
        'tag_name': 'nightly',
        'name': '2026.8.7 (Build 6)',
        'assets': <dynamic>[],
      });

      expect(release.version.versionName, '2026.8.7');
      expect(release.version.build, 6);
    });

    test('tag 與標題都無法解析時擲 FormatException', () {
      expect(
        () => ReleaseInfo.fromJson({
          'tag_name': 'nightly',
          'name': 'Latest',
          'assets': <dynamic>[],
        }),
        throwsFormatException,
      );
    });

    test('缺少 assets 欄位時視為沒有任何 asset', () {
      final release = ReleaseInfo.fromJson({
        'tag_name': 'v2026.8.7-build.6-attempt.1',
      });

      expect(release.assets, isEmpty);
      // 標題缺席時退回以版本字串作為顯示名稱。
      expect(release.title, '2026.8.7 (build 6)');
    });

    test('asset 缺少必要欄位時擲 FormatException', () {
      expect(
        () => ReleaseInfo.fromJson({
          'tag_name': 'v2026.8.7-build.6',
          'assets': [
            {'name': 'broken.exe'},
          ],
        }),
        throwsFormatException,
      );
    });
  });

  group('formatBytes', () {
    test('依大小選擇單位', () {
      expect(formatBytes(512), '512 B');
      expect(formatBytes(11575039), '11.0 MB');
      expect(formatBytes(51874918), '49.5 MB');
    });

    test('大小為 0 時 humanSize 為 null', () {
      const asset = ReleaseAsset(
        name: 'x.exe',
        browserDownloadUrl: 'https://example.com/x.exe',
        size: 0,
        contentType: 'application/octet-stream',
      );

      expect(asset.humanSize, isNull);
    });
  });
}
