import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:scientific_calculator/app/package_info_providers.dart';
import 'package:scientific_calculator/app/theme_settings.dart';
import 'package:scientific_calculator/features/calculator/view/widgets/settings_button.dart';
import 'package:scientific_calculator/features/calculator/view/widgets/settings_dialog.dart';
import 'package:scientific_calculator/features/update/model/update_platform.dart';
import 'package:scientific_calculator/features/update/viewmodel/update_providers.dart';

import '../../../../helpers/shared_preferences_test_helper.dart';
import '../../../update/update_test_fakes.dart';

/// 設定對話框 widget 測試。
void main() {
  setUp(setupSharedPreferencesForTest);

  /// 平台固定為 windows：CI 會在 ubuntu / windows / macos 上跑測試，不鎖定的話
  /// `UpdatePlatform.current` 會隨 runner 改變，更新區塊的內容也跟著變。
  Future<void> pumpDialog(
    WidgetTester tester, {
    List<Override> overrides = const [],
    UpdatePlatform platform = UpdatePlatform.windows,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          updatePlatformProvider.overrideWithValue(platform),
          ...overrides,
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showSettingsDialog(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('顯示三個主題選項與版本區塊', (tester) async {
    await pumpDialog(
      tester,
      overrides: [
        packageInfoProvider.overrideWith(
          (ref) async => PackageInfo(
            appName: 'Scientific Calculator',
            packageName: 'scientific_calculator',
            version: '1.0.0',
            buildNumber: '1',
            buildSignature: '',
            installerStore: null,
          ),
        ),
      ],
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('1.0.0 (build 1)'), findsOneWidget);
  });

  testWidgets('顯示更新區塊，且開啟對話框不會自動連網', (tester) async {
    final client = FakeGithubReleaseClient();

    await pumpDialog(
      tester,
      overrides: [
        packageInfoProvider.overrideWith((ref) async => _emptyPackageInfo()),
        githubReleaseClientProvider.overrideWithValue(client),
      ],
    );

    expect(find.text('Update'), findsOneWidget);
    expect(find.text('Check for updates'), findsOneWidget);
    // 只有 UpdateCheckStarter（app 啟動）與使用者手動按鈕才會打 API。
    expect(client.callCount, 0);
  });

  testWidgets('在對話框中按下 Check for updates 會取得新版本', (tester) async {
    final client = FakeGithubReleaseClient();

    await pumpDialog(
      tester,
      overrides: [
        packageInfoProvider.overrideWith((ref) async => _emptyPackageInfo()),
        githubReleaseClientProvider.overrideWithValue(client),
        updateDownloaderProvider.overrideWithValue(FakeUpdateDownloader()),
      ],
    );

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();

    expect(client.callCount, 1);
    expect(find.text('Update available: 2026.8.7 (build 6)'), findsOneWidget);
    expect(find.text('Download & install'), findsOneWidget);
  });

  testWidgets('預設選中 System，點 Light 後切換狀態', (tester) async {
    await pumpDialog(
      tester,
      overrides: [
        packageInfoProvider.overrideWith((ref) async => _emptyPackageInfo()),
      ],
    );

    // 群組值現在由 RadioGroup 祖先持有（RadioListTile.groupValue 已棄用）。
    ThemePreference groupValue() => tester
        .widget<RadioGroup<ThemePreference>>(
          find.byType(RadioGroup<ThemePreference>),
        )
        .groupValue!;

    // 初始：選中 System。
    expect(groupValue(), ThemePreference.system);

    // 點 Light。
    await tester.tap(find.text('Light'));
    await tester.pump();

    // 切換後：選中 Light。
    expect(groupValue(), ThemePreference.light);
  });

  testWidgets('Close 按鈕關閉對話框', (tester) async {
    await pumpDialog(
      tester,
      overrides: [
        packageInfoProvider.overrideWith((ref) async => _emptyPackageInfo()),
      ],
    );

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('SettingsButton 點擊後開啟對話框', (tester) async {
    await pumpSettingsButton(tester);

    await tester.tap(find.byType(SettingsButton));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('沒有新版本時設定按鈕不顯示紅點', (tester) async {
    await pumpSettingsButton(tester);

    expect(badgeVisible(tester), isFalse);
    expect(find.byTooltip('Settings'), findsOneWidget);
  });

  testWidgets('背景檢查找到新版本後設定按鈕出現紅點', (tester) async {
    await pumpSettingsButton(tester);

    // 模擬 UpdateCheckStarter 在 app 啟動時做的事。
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsButton)),
    );
    await container
        .read(updateControllerProvider.notifier)
        .checkForUpdates(background: true);
    await tester.pump();

    expect(badgeVisible(tester), isTrue);
    expect(find.byTooltip('Settings — update available'), findsOneWidget);
  });
}

/// 掛上單獨的 [SettingsButton]，並把更新相關的依賴換成假實作。
Future<void> pumpSettingsButton(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        updatePlatformProvider.overrideWithValue(UpdatePlatform.windows),
        // 1.0.0+1 比 fixture 的 2026.8.7 build 6 舊，因此檢查後會有更新。
        packageInfoProvider.overrideWith((ref) async => _emptyPackageInfo()),
        githubReleaseClientProvider.overrideWithValue(FakeGithubReleaseClient()),
        updateDownloaderProvider.overrideWithValue(FakeUpdateDownloader()),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SettingsButton()),
      ),
    ),
  );

  await tester.pump();
}

/// 設定圖示上的紅點是否可見。
bool badgeVisible(WidgetTester tester) {
  return tester.widget<Badge>(find.byType(Badge)).isLabelVisible;
}

PackageInfo _emptyPackageInfo() {
  return PackageInfo(
    appName: '',
    packageName: '',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
    installerStore: null,
  );
}
