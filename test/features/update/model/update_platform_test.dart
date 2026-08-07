import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/features/update/model/release_info.dart';
import 'package:scientific_calculator/features/update/model/update_platform.dart';

import 'release_fixture.dart';

void main() {
  final release = ReleaseInfo.fromJson(
    jsonDecode(latestReleaseJson) as Map<String, dynamic>,
  );

  group('selectAsset', () {
    test('每個平台都挑到 CI 為它產出的安裝檔', () {
      expect(
        UpdatePlatform.android.selectAsset(release.assets)?.name,
        'scientific_calculator-Android.apk',
      );
      expect(
        UpdatePlatform.windows.selectAsset(release.assets)?.name,
        'scientific_calculator-Windows-Setup.exe',
      );
      expect(
        UpdatePlatform.macos.selectAsset(release.assets)?.name,
        'scientific_calculator.dmg',
      );
    });

    test('不支援的平台永遠拿不到 asset', () {
      expect(UpdatePlatform.unsupported.selectAsset(release.assets), isNull);
    });

    test('找不到對應檔案時回傳 null', () {
      const assets = [
        ReleaseAsset(
          name: 'source.tar.gz',
          browserDownloadUrl: 'https://example.com/source.tar.gz',
          size: 1,
          contentType: 'application/gzip',
        ),
      ];

      expect(UpdatePlatform.windows.selectAsset(assets), isNull);
      expect(UpdatePlatform.macos.selectAsset(assets), isNull);
    });

    test('app 更名導致檔名前綴改變時，仍能靠副檔名找到安裝檔', () {
      const assets = [
        ReleaseAsset(
          name: 'sci_calc-Setup.exe',
          browserDownloadUrl: 'https://example.com/sci_calc-Setup.exe',
          size: 1,
          contentType: 'application/octet-stream',
        ),
      ];

      expect(
        UpdatePlatform.windows.selectAsset(assets)?.name,
        'sci_calc-Setup.exe',
      );
    });

    test('完整後綴優先於寬鬆的副檔名比對', () {
      const assets = [
        ReleaseAsset(
          name: 'debug-symbols.exe',
          browserDownloadUrl: 'https://example.com/debug-symbols.exe',
          size: 1,
          contentType: 'application/octet-stream',
        ),
        ReleaseAsset(
          name: 'scientific_calculator-Windows-Setup.exe',
          browserDownloadUrl: 'https://example.com/setup.exe',
          size: 2,
          contentType: 'application/octet-stream',
        ),
      ];

      expect(
        UpdatePlatform.windows.selectAsset(assets)?.name,
        'scientific_calculator-Windows-Setup.exe',
      );
    });
  });

  test('isSupported 只對有 CI 產出的平台為 true', () {
    expect(UpdatePlatform.android.isSupported, isTrue);
    expect(UpdatePlatform.windows.isSupported, isTrue);
    expect(UpdatePlatform.macos.isSupported, isTrue);
    expect(UpdatePlatform.unsupported.isSupported, isFalse);
  });
}
