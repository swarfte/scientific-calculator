import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/features/update/model/app_version.dart';

/// 版本解析與比較。
///
/// 這些格式全部來自 `.github/workflows/build-release.yml`：
/// tag `v2026.8.7-build.6-attempt.1`、標題 `2026.8.7 (Build 6)`，
/// 以及 `--build-name` / `--build-number` 帶進 PackageInfo 的值。
void main() {
  group('tryParseTag', () {
    test('解析 CI 產生的完整 tag', () {
      final version = AppVersion.tryParseTag('v2026.8.7-build.6-attempt.1');

      expect(version, isNotNull);
      expect(version!.segments, [2026, 8, 7]);
      expect(version.build, 6);
    });

    test('attempt 後綴可省略', () {
      final version = AppVersion.tryParseTag('v2026.8.7-build.6');

      expect(version!.segments, [2026, 8, 7]);
      expect(version.build, 6);
    });

    test('沒有 build 段的純版本 tag 視為 build 0', () {
      final version = AppVersion.tryParseTag('v2026.8.7');

      expect(version!.segments, [2026, 8, 7]);
      expect(version.build, 0);
    });

    test('無法解析時回傳 null，而不是擲例外', () {
      expect(AppVersion.tryParseTag('nightly'), isNull);
      expect(AppVersion.tryParseTag(''), isNull);
      expect(AppVersion.tryParseTag('v2026.x.7-build.6'), isNull);
    });
  });

  group('tryParseTitle', () {
    test('解析 Release 標題', () {
      final version = AppVersion.tryParseTitle('2026.8.7 (Build 6)');

      expect(version!.segments, [2026, 8, 7]);
      expect(version.build, 6);
    });

    test('大小寫不敏感', () {
      expect(AppVersion.tryParseTitle('2026.8.7 (build 6)')!.build, 6);
    });

    test('格式不符時回傳 null', () {
      expect(AppVersion.tryParseTitle('Latest release'), isNull);
    });
  });

  group('tryParsePackageInfo', () {
    test('解析 release build 帶進來的版本', () {
      final version = AppVersion.tryParsePackageInfo('2026.8.7', '6');

      expect(version!.segments, [2026, 8, 7]);
      expect(version.build, 6);
    });

    test('忽略 version 的 +build 後綴，一律以 buildNumber 為準', () {
      final version = AppVersion.tryParsePackageInfo('1.0.0+1', '1');

      expect(version!.segments, [1, 0, 0]);
      expect(version.build, 1);
    });

    test('buildNumber 為空字串時視為 0', () {
      expect(AppVersion.tryParsePackageInfo('2026.8.7', '')!.build, 0);
    });

    test('版本無法解析時回傳 null', () {
      expect(AppVersion.tryParsePackageInfo('', '1'), isNull);
      expect(AppVersion.tryParsePackageInfo('unknown', '1'), isNull);
    });
  });

  group('比較', () {
    AppVersion tag(String value) => AppVersion.tryParseTag(value)!;

    test('日期較新者勝出', () {
      expect(
        tag('v2026.8.8-build.1').isNewerThan(tag('v2026.8.7-build.99')),
        isTrue,
      );
    });

    test('日期相同時比較 build 編號', () {
      expect(
        tag('v2026.8.7-build.7').isNewerThan(tag('v2026.8.7-build.6')),
        isTrue,
      );
      expect(
        tag('v2026.8.7-build.6').isNewerThan(tag('v2026.8.7-build.7')),
        isFalse,
      );
    });

    test('完全相同的版本不算比較新', () {
      expect(
        tag('v2026.8.7-build.6').isNewerThan(tag('v2026.8.7-build.6')),
        isFalse,
      );
    });

    test('本機的 1.0.0+1 一定比 CI 的日期版本舊', () {
      final local = AppVersion.tryParsePackageInfo('1.0.0', '1')!;

      expect(tag('v2026.8.7-build.6').isNewerThan(local), isTrue);
    });

    test('段數不同時以 0 補齊', () {
      expect(tag('v2026.8-build.1'), equals(tag('v2026.8.0-build.1')));
      expect(tag('v2026.8.1-build.1').isNewerThan(tag('v2026.8-build.1')), isTrue);
    });

    test('== 與 hashCode 對補零版本保持一致', () {
      expect(
        tag('v2026.8.7-build.6').hashCode,
        tag('v2026.8.7.0-build.6').hashCode,
      );
      expect(tag('v2026.8.7-build.6'), equals(tag('v2026.8.7.0-build.6')));
    });
  });

  test('display 顯示版本與 build', () {
    expect(AppVersion.tryParseTag('v2026.8.7-build.6')!.display, '2026.8.7 (build 6)');
  });
}
