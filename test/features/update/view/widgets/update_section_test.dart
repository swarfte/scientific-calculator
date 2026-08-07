import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/app/package_info_providers.dart';
import 'package:scientific_calculator/features/update/model/update_platform.dart';
import 'package:scientific_calculator/features/update/model/update_state.dart';
import 'package:scientific_calculator/features/update/view/widgets/update_section.dart';
import 'package:scientific_calculator/features/update/viewmodel/update_providers.dart';

import '../../../../helpers/shared_preferences_test_helper.dart';
import '../../update_test_fakes.dart';

/// 讓 widget 測試能直接指定 [UpdateController] 的狀態。
///
/// 只覆寫 `build()`，其餘行為（下載、重試）維持真實實作，因此按鈕的接線也一併
/// 受測。
class _StubUpdateController extends UpdateController {
  _StubUpdateController(this.initial);

  final UpdateState initial;

  @override
  UpdateState build() => initial;
}

void main() {
  setUp(setupSharedPreferencesForTest);

  /// 平台預設固定為 windows：CI 會在 ubuntu / windows / macos 三種 runner 上跑
  /// 測試，不鎖定的話 `UpdatePlatform.current` 會隨 runner 改變。
  Future<void> pumpSection(
    WidgetTester tester, {
    UpdateState? state,
    UpdatePlatform platform = UpdatePlatform.windows,
    FakeGithubReleaseClient? client,
    FakeUpdateDownloader? downloader,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          updatePlatformProvider.overrideWithValue(platform),
          packageInfoProvider.overrideWith(
            (ref) async => packageInfo(version: '1.0.0', buildNumber: '1'),
          ),
          githubReleaseClientProvider.overrideWithValue(
            client ?? FakeGithubReleaseClient(),
          ),
          updateDownloaderProvider.overrideWithValue(
            downloader ?? FakeUpdateDownloader(),
          ),
          if (state != null)
            updateControllerProvider.overrideWith(
              () => _StubUpdateController(state),
            ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: UpdateSection(),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
  }

  testWidgets('預設顯示 Check for updates，且不會自動連網', (tester) async {
    final client = FakeGithubReleaseClient();

    await pumpSection(
      tester,
      client: client,
    );

    expect(find.text('Update'), findsOneWidget);
    expect(find.text('Check for updates'), findsOneWidget);
    // 背景檢查由 UpdateCheckStarter 觸發，光是渲染區塊不該打 API。
    expect(client.callCount, 0);
  });

  testWidgets('按下 Check for updates 後顯示可用的新版本與安裝檔', (tester) async {
    final client = FakeGithubReleaseClient();

    await pumpSection(
      tester,
      client: client,
    );

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();

    expect(client.callCount, 1);
    expect(find.text('Update available: 2026.8.7 (build 6)'), findsOneWidget);
    expect(
      find.text('scientific_calculator-Windows-Setup.exe · 11.0 MB'),
      findsOneWidget,
    );
    expect(find.text('Download & install'), findsOneWidget);
  });

  testWidgets('檢查中顯示進度指示', (tester) async {
    await pumpSection(
      tester,
      state: const UpdateState(checkPhase: UpdateCheckPhase.checking),
    );

    expect(find.text('Checking for updates…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('已是最新版時顯示確認訊息與重新檢查', (tester) async {
    await pumpSection(
      tester,
      state: const UpdateState(checkPhase: UpdateCheckPhase.upToDate),
    );

    expect(find.text("You're on the latest version"), findsOneWidget);
    expect(find.text('Check again'), findsOneWidget);
  });

  testWidgets('檢查失敗時顯示訊息、重試與 Release 頁面連結', (tester) async {
    await pumpSection(
      tester,
      state: const UpdateState(
        checkPhase: UpdateCheckPhase.failed,
        checkError: '無法連線到 GitHub，請檢查網路連線',
      ),
    );

    expect(find.text('無法連線到 GitHub，請檢查網路連線'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Open release page'), findsOneWidget);
  });

  testWidgets('下載中顯示進度條與已下載大小', (tester) async {
    await pumpSection(
      tester,
      state: UpdateState(
        checkPhase: UpdateCheckPhase.updateAvailable,
        downloadPhase: UpdateDownloadPhase.downloading,
        latestRelease: fixtureRelease(),
        asset: UpdatePlatform.windows.selectAsset(fixtureRelease().assets),
        receivedBytes: 5787519,
        totalBytes: 11575039,
      ),
    );

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );

    expect(indicator.value, closeTo(0.5, 0.01));
    expect(find.text('5.5 MB / 11.0 MB'), findsOneWidget);
  });

  testWidgets('下載完成後提示使用者依安裝程式完成更新', (tester) async {
    await pumpSection(
      tester,
      state: UpdateState(
        checkPhase: UpdateCheckPhase.updateAvailable,
        downloadPhase: UpdateDownloadPhase.completed,
        latestRelease: fixtureRelease(),
        asset: UpdatePlatform.windows.selectAsset(fixtureRelease().assets),
        downloadedPath: r'C:\Users\me\Downloads\setup.exe',
      ),
    );

    expect(
      find.text('Downloaded — follow the installer to finish.'),
      findsOneWidget,
    );
    expect(find.text(r'C:\Users\me\Downloads\setup.exe'), findsOneWidget);
  });

  testWidgets('開啟安裝檔失敗時仍顯示檔案路徑與「Open installer」', (tester) async {
    await pumpSection(
      tester,
      state: UpdateState(
        checkPhase: UpdateCheckPhase.updateAvailable,
        downloadPhase: UpdateDownloadPhase.failed,
        latestRelease: fixtureRelease(),
        asset: UpdatePlatform.windows.selectAsset(fixtureRelease().assets),
        downloadError: '作業系統拒絕開啟安裝檔',
        downloadedPath: r'C:\Users\me\Downloads\setup.exe',
      ),
    );

    expect(find.text('作業系統拒絕開啟安裝檔'), findsOneWidget);
    expect(find.text(r'C:\Users\me\Downloads\setup.exe'), findsOneWidget);
    expect(find.text('Open installer'), findsOneWidget);
    // 檔案已在本機，不該叫使用者重新下載。
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('有新版本但這個 Release 沒有本平台安裝檔時只提供 Release 頁面', (tester) async {
    await pumpSection(
      tester,
      state: UpdateState(
        checkPhase: UpdateCheckPhase.updateAvailable,
        latestRelease: fixtureRelease(),
      ),
    );

    expect(
      find.text('No installer for this platform in that release.'),
      findsOneWidget,
    );
    expect(find.text('Open release page'), findsOneWidget);
    expect(find.text('Download & install'), findsNothing);
  });

  testWidgets('不支援的平台不提供檢查，只提供 Release 頁面', (tester) async {
    await pumpSection(tester, platform: UpdatePlatform.unsupported);

    expect(
      find.text('Automatic updates are not available on this platform.'),
      findsOneWidget,
    );
    expect(find.text('Open release page'), findsOneWidget);
    expect(find.text('Check for updates'), findsNothing);
  });

  testWidgets('macOS 的按鈕文字為 Download & open', (tester) async {
    await pumpSection(
      tester,
      platform: UpdatePlatform.macos,
      state: UpdateState(
        checkPhase: UpdateCheckPhase.updateAvailable,
        latestRelease: fixtureRelease(),
        asset: UpdatePlatform.macos.selectAsset(fixtureRelease().assets),
      ),
    );

    expect(find.text('Download & open'), findsOneWidget);
    expect(
      find.text('scientific_calculator.dmg · 19.5 MB'),
      findsOneWidget,
    );
  });
}
