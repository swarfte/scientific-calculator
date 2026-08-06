import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:scientific_calculator/app/package_info_providers.dart';
import 'package:scientific_calculator/app/theme_settings.dart';
import 'package:scientific_calculator/features/calculator/view/widgets/settings_button.dart';
import 'package:scientific_calculator/features/calculator/view/widgets/settings_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 設定對話框 widget 測試。
void main() {
  setUp(SharedPreferences.setMockInitialValues);

  Future<void> pumpDialog(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
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

  testWidgets('預設選中 System，點 Light 後切換狀態', (tester) async {
    await pumpDialog(
      tester,
      overrides: [
        packageInfoProvider.overrideWith((ref) async => _emptyPackageInfo()),
      ],
    );

    // 初始：System RadioListTile 為已選。
    final systemRadio =
        find.widgetWithText(RadioListTile<ThemePreference>, 'System');
    expect(
      tester.widget<RadioListTile<ThemePreference>>(systemRadio).groupValue,
      ThemePreference.system,
    );

    // 點 Light。
    await tester.tap(find.text('Light'));
    await tester.pump();

    // 切換後：Light RadioListTile 為已選。
    final lightRadio =
        find.widgetWithText(RadioListTile<ThemePreference>, 'Light');
    expect(
      tester.widget<RadioListTile<ThemePreference>>(lightRadio).groupValue,
      ThemePreference.light,
    );
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          packageInfoProvider.overrideWith((ref) async => _emptyPackageInfo()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SettingsButton()),
        ),
      ),
    );

    await tester.tap(find.byType(SettingsButton));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
  });
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
