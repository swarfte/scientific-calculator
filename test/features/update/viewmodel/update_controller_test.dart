import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/app/package_info_providers.dart';
import 'package:scientific_calculator/features/update/model/update_platform.dart';
import 'package:scientific_calculator/features/update/model/update_state.dart';
import 'package:scientific_calculator/features/update/service/update_check_storage.dart';
import 'package:scientific_calculator/features/update/viewmodel/update_providers.dart';

import '../../../helpers/shared_preferences_test_helper.dart';
import '../update_test_fakes.dart';

void main() {
  setUp(setupSharedPreferencesForTest);

  ProviderContainer makeContainer({
    FakeGithubReleaseClient? client,
    FakeUpdateDownloader? downloader,
    UpdatePlatform platform = UpdatePlatform.windows,
    String version = '2026.8.7',
    String buildNumber = '6',
    List<Override> extraOverrides = const [],
  }) {
    return ProviderContainer.test(
      overrides: [
        packageInfoProvider.overrideWith(
          (ref) async => packageInfo(version: version, buildNumber: buildNumber),
        ),
        githubReleaseClientProvider.overrideWithValue(
          client ?? FakeGithubReleaseClient(),
        ),
        updateDownloaderProvider.overrideWithValue(
          downloader ?? FakeUpdateDownloader(),
        ),
        updatePlatformProvider.overrideWithValue(platform),
        ...extraOverrides,
      ],
    );
  }

  UpdateState stateOf(ProviderContainer container) =>
      container.read(updateControllerProvider);

  group('checkForUpdates', () {
    test('目前版本與最新 Release 相同時回報已是最新版', () async {
      final container = makeContainer();

      await container
          .read(updateControllerProvider.notifier)
          .checkForUpdates();

      final state = stateOf(container);
      expect(state.checkPhase, UpdateCheckPhase.upToDate);
      expect(state.hasUpdate, isFalse);
      // 已是最新版時不該留下可下載的 asset。
      expect(state.asset, isNull);
      expect(state.latestRelease?.tagName, 'v2026.8.7-build.6-attempt.1');
    });

    test('本機的 1.0.0+1 會被判定為有更新，並挑到 Windows 安裝檔', () async {
      final container = makeContainer(version: '1.0.0', buildNumber: '1');

      await container
          .read(updateControllerProvider.notifier)
          .checkForUpdates();

      final state = stateOf(container);
      expect(state.checkPhase, UpdateCheckPhase.updateAvailable);
      expect(state.hasUpdate, isTrue);
      expect(state.asset?.name, 'scientific_calculator-Windows-Setup.exe');
    });

    test('build 編號較舊也算有更新', () async {
      final container = makeContainer(buildNumber: '5');

      await container
          .read(updateControllerProvider.notifier)
          .checkForUpdates();

      expect(stateOf(container).checkPhase, UpdateCheckPhase.updateAvailable);
    });

    test('平台沒有對應安裝檔時仍回報有更新，但 asset 為 null', () async {
      final container = makeContainer(
        platform: UpdatePlatform.unsupported,
        version: '1.0.0',
        buildNumber: '1',
      );

      await container
          .read(updateControllerProvider.notifier)
          .checkForUpdates();

      final state = stateOf(container);
      expect(state.checkPhase, UpdateCheckPhase.updateAvailable);
      expect(state.asset, isNull);
      expect(state.hasUpdateWithoutAsset, isTrue);
    });

    test('網路失敗時顯示 service 翻譯過的訊息', () async {
      final container = makeContainer(
        client: FakeGithubReleaseClient(error: networkFailure),
      );

      await container
          .read(updateControllerProvider.notifier)
          .checkForUpdates();

      final state = stateOf(container);
      expect(state.checkPhase, UpdateCheckPhase.failed);
      expect(state.checkError, '無法連線到 GitHub，請檢查網路連線');
      expect(state.hasUpdate, isFalse);
    });

    test('讀不到自己的版本時當成檢查失敗，不誤報有更新', () async {
      final container = makeContainer(version: 'unknown');

      await container
          .read(updateControllerProvider.notifier)
          .checkForUpdates();

      final state = stateOf(container);
      expect(state.checkPhase, UpdateCheckPhase.failed);
      expect(state.hasUpdate, isFalse);
    });

    test('成功檢查後會把 tag 寫進快取', () async {
      final container = makeContainer();

      await container
          .read(updateControllerProvider.notifier)
          .checkForUpdates();

      expect(
        await UpdateCheckStorage.loadLatestTag(),
        'v2026.8.7-build.6-attempt.1',
      );
    });
  });

  group('背景檢查', () {
    test('先用快取的 tag 點亮紅點，再由網路結果確認', () async {
      setupSharedPreferencesForTest({
        'update_latest_tag': 'v2026.8.7-build.6-attempt.1',
      });

      final container = makeContainer(version: '1.0.0', buildNumber: '1');

      await container
          .read(updateControllerProvider.notifier)
          .checkForUpdates(background: true);

      final state = stateOf(container);
      expect(state.checkPhase, UpdateCheckPhase.updateAvailable);
      expect(state.asset?.name, 'scientific_calculator-Windows-Setup.exe');
    });

    test('快取說有更新但網路失敗時，保留紅點', () async {
      setupSharedPreferencesForTest({
        'update_latest_tag': 'v2026.8.7-build.6-attempt.1',
      });

      final container = makeContainer(
        client: FakeGithubReleaseClient(error: networkFailure),
        version: '1.0.0',
        buildNumber: '1',
      );

      await container
          .read(updateControllerProvider.notifier)
          .checkForUpdates(background: true);

      final state = stateOf(container);
      expect(state.checkPhase, UpdateCheckPhase.updateAvailable);
      // 使用者沒有主動要求檢查，失敗訊息不該冒出來。
      expect(state.checkError, isNull);
    });

    test('沒有快取又網路失敗時安靜地標記失敗，不顯示紅點', () async {
      final container = makeContainer(
        client: FakeGithubReleaseClient(error: networkFailure),
        version: '1.0.0',
        buildNumber: '1',
      );

      await container
          .read(updateControllerProvider.notifier)
          .checkForUpdates(background: true);

      expect(stateOf(container).hasUpdate, isFalse);
    });
  });

  group('downloadAndInstall', () {
    Future<ProviderContainer> withUpdateAvailable({
      FakeUpdateDownloader? downloader,
    }) async {
      final container = makeContainer(
        downloader: downloader,
        version: '1.0.0',
        buildNumber: '1',
      );

      await container
          .read(updateControllerProvider.notifier)
          .checkForUpdates();

      return container;
    }

    test('下載成功後把檔案交給作業系統開啟', () async {
      final downloader = FakeUpdateDownloader(
        path: r'C:\Users\me\Downloads\scientific_calculator-Windows-Setup.exe',
      );
      final container = await withUpdateAvailable(downloader: downloader);

      await container
          .read(updateControllerProvider.notifier)
          .downloadAndInstall();

      final state = stateOf(container);
      expect(state.downloadPhase, UpdateDownloadPhase.completed);
      expect(state.downloadedPath, downloader.path);
      expect(downloader.openedPaths, [downloader.path]);
    });

    test('進度回呼會反映到 state', () async {
      final downloader = FakeUpdateDownloader(
        progressSteps: const [(1000, 4000), (4000, 4000)],
      );
      final container = await withUpdateAvailable(downloader: downloader);

      await container
          .read(updateControllerProvider.notifier)
          .downloadAndInstall();

      // 下載結束後停在最後一次回報的數值。
      final state = stateOf(container);
      expect(state.receivedBytes, 4000);
      expect(state.totalBytes, 4000);
    });

    test('下載失敗時標記失敗，且不留下檔案路徑', () async {
      final container = await withUpdateAvailable(
        downloader: FakeUpdateDownloader(downloadError: networkFailure),
      );

      await container
          .read(updateControllerProvider.notifier)
          .downloadAndInstall();

      final state = stateOf(container);
      expect(state.downloadPhase, UpdateDownloadPhase.failed);
      expect(state.downloadError, '無法連線到 GitHub，請檢查網路連線');
      expect(state.downloadedPath, isNull);
    });

    test('開啟失敗時保留檔案路徑，讓使用者能自行開啟或重試', () async {
      final downloader = FakeUpdateDownloader(
        openError: const FormatException('作業系統拒絕開啟安裝檔'),
      );
      final container = await withUpdateAvailable(downloader: downloader);
      final notifier = container.read(updateControllerProvider.notifier);

      await notifier.downloadAndInstall();

      var state = stateOf(container);
      expect(state.downloadPhase, UpdateDownloadPhase.failed);
      expect(state.downloadedPath, downloader.path);

      // 重試「開啟」不應該重新下載。
      await notifier.retryOpenDownloadedFile();

      state = stateOf(container);
      expect(state.downloadPhase, UpdateDownloadPhase.failed);
      expect(downloader.downloadCount, 1);
      expect(downloader.openedPaths.length, 2);
    });

    test('沒有 asset 時不會嘗試下載', () async {
      final downloader = FakeUpdateDownloader();
      final container = makeContainer(downloader: downloader);

      await container
          .read(updateControllerProvider.notifier)
          .downloadAndInstall();

      expect(downloader.downloadCount, 0);
      expect(stateOf(container).downloadPhase, UpdateDownloadPhase.idle);
    });
  });
}
