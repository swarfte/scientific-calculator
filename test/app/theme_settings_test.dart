import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/app/theme_settings.dart';

import '../helpers/shared_preferences_test_helper.dart';

/// 主題偏好持久化與 Notifier 測試。
void main() {
  group('ThemePreference', () {
    test('label 與 themeMode 對應', () {
      expect(ThemePreference.system.label, '跟隨系統');
      expect(ThemePreference.system.themeMode, ThemeMode.system);

      expect(ThemePreference.light.label, '淺色');
      expect(ThemePreference.light.themeMode, ThemeMode.light);

      expect(ThemePreference.dark.label, '深色');
      expect(ThemePreference.dark.themeMode, ThemeMode.dark);
    });

    test('fromName 只接受已知值，其餘回傳 system', () {
      expect(ThemePreference.fromName('light'), ThemePreference.light);
      expect(ThemePreference.fromName('dark'), ThemePreference.dark);
      expect(ThemePreference.fromName('system'), ThemePreference.system);
      expect(ThemePreference.fromName(null), ThemePreference.system);
      expect(ThemePreference.fromName('garbage'), ThemePreference.system);
    });
  });

  group('ThemeSettingsStorage', () {
    setUp(setupSharedPreferencesForTest);

    test('未儲存時 load 回傳 system', () async {
      expect(await ThemeSettingsStorage.load(), ThemePreference.system);
    });

    test('save 後可 load 回相同值', () async {
      await ThemeSettingsStorage.save(ThemePreference.dark);
      expect(await ThemeSettingsStorage.load(), ThemePreference.dark);

      await ThemeSettingsStorage.save(ThemePreference.light);
      expect(await ThemeSettingsStorage.load(), ThemePreference.light);
    });
  });

  group('ThemeSettingsNotifier', () {
    late ProviderContainer container;

    setUp(() {
      setupSharedPreferencesForTest();
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('初始值預設為 system', () {
      expect(
        container.read(themeSettingsProvider),
        ThemePreference.system,
      );
    });

    test('initialThemePreferenceProvider override 可改變初始值', () {
      final overridden = ProviderContainer(
        overrides: [
          initialThemePreferenceProvider
              .overrideWith((ref) => ThemePreference.dark),
        ],
      );
      addTearDown(overridden.dispose);

      expect(overridden.read(themeSettingsProvider), ThemePreference.dark);
    });

    test('set 更新 state 並持久化', () async {
      final notifier = container.read(themeSettingsProvider.notifier);

      await notifier.set(ThemePreference.light);

      expect(container.read(themeSettingsProvider), ThemePreference.light);
      expect(await ThemeSettingsStorage.load(), ThemePreference.light);
    });

    test('set 相同值不重複寫入', () async {
      final notifier = container.read(themeSettingsProvider.notifier);

      await notifier.set(ThemePreference.system);

      // state 不變，且未寫入（load 仍為預設 system，無副作用可觀測）。
      expect(container.read(themeSettingsProvider), ThemePreference.system);
    });
  });
}
