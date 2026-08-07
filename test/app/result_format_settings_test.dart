import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/app/result_format_settings.dart';

import '../helpers/shared_preferences_test_helper.dart';

/// 結果顯示格式偏好持久化與 Notifier 測試（鏡像 theme_settings_test.dart）。
void main() {
  group('ResultFormatPreference', () {
    test('label 對應', () {
      expect(ResultFormatPreference.decimal.label, 'DEC');
      expect(ResultFormatPreference.fraction.label, 'FRAC');
    });

    test('fromName 只接受已知值，其餘回傳 decimal', () {
      expect(
        ResultFormatPreference.fromName('fraction'),
        ResultFormatPreference.fraction,
      );
      expect(
        ResultFormatPreference.fromName('decimal'),
        ResultFormatPreference.decimal,
      );
      expect(ResultFormatPreference.fromName(null), ResultFormatPreference.decimal);
      expect(
        ResultFormatPreference.fromName('garbage'),
        ResultFormatPreference.decimal,
      );
    });
  });

  group('ResultFormatSettingsStorage', () {
    setUp(setupSharedPreferencesForTest);

    test('未儲存時 load 回傳 decimal', () async {
      expect(
        await ResultFormatSettingsStorage.load(),
        ResultFormatPreference.decimal,
      );
    });

    test('save 後可 load 回相同值', () async {
      await ResultFormatSettingsStorage.save(ResultFormatPreference.fraction);
      expect(
        await ResultFormatSettingsStorage.load(),
        ResultFormatPreference.fraction,
      );

      await ResultFormatSettingsStorage.save(ResultFormatPreference.decimal);
      expect(
        await ResultFormatSettingsStorage.load(),
        ResultFormatPreference.decimal,
      );
    });
  });

  group('ResultFormatSettingsNotifier', () {
    late ProviderContainer container;

    setUp(() {
      setupSharedPreferencesForTest();
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('初始值預設為 decimal', () {
      expect(
        container.read(resultFormatSettingsProvider),
        ResultFormatPreference.decimal,
      );
    });

    test('initialResultFormatPreferenceProvider override 可改變初始值', () {
      final overridden = ProviderContainer(
        overrides: [
          initialResultFormatPreferenceProvider.overrideWith(
            (ref) => ResultFormatPreference.fraction,
          ),
        ],
      );
      addTearDown(overridden.dispose);

      expect(
        overridden.read(resultFormatSettingsProvider),
        ResultFormatPreference.fraction,
      );
    });

    test('set 更新 state 並持久化', () async {
      final notifier = container.read(resultFormatSettingsProvider.notifier);

      await notifier.set(ResultFormatPreference.fraction);

      expect(
        container.read(resultFormatSettingsProvider),
        ResultFormatPreference.fraction,
      );
      expect(
        await ResultFormatSettingsStorage.load(),
        ResultFormatPreference.fraction,
      );
    });

    test('set 相同值不重複寫入', () async {
      final notifier = container.read(resultFormatSettingsProvider.notifier);

      await notifier.set(ResultFormatPreference.decimal);

      expect(
        container.read(resultFormatSettingsProvider),
        ResultFormatPreference.decimal,
      );
    });
  });
}
