import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/package_info_providers.dart';
import '../model/app_version.dart';
import '../model/update_exception.dart';
import '../model/update_platform.dart';
import '../model/update_state.dart';
import '../service/github_release_client.dart';
import '../service/update_check_storage.dart';
import '../service/update_downloader.dart';

/// 取得最新 Release 的 client；測試以假實作覆寫。
final githubReleaseClientProvider = Provider<GithubReleaseClient>((ref) {
  return HttpGithubReleaseClient();
});

/// 下載並開啟安裝檔的服務；測試以假實作覆寫。
final updateDownloaderProvider = Provider<UpdateDownloader>((ref) {
  return HttpUpdateDownloader();
});

/// 目前平台；測試可覆寫成任一平台以驗證 asset 選取。
final updatePlatformProvider = Provider<UpdatePlatform>((ref) {
  return UpdatePlatform.current;
});

/// 目前平台是否有 CI 產出的安裝檔（Android / Windows / macOS）。
final updateSupportedProvider = Provider<bool>((ref) {
  return ref.watch(updatePlatformProvider).isSupported;
});

/// 設定按鈕上是否要顯示紅點。
final updateBadgeVisibleProvider = Provider<bool>((ref) {
  return ref.watch(updateControllerProvider).hasUpdate;
});

final updateControllerProvider = NotifierProvider<UpdateController, UpdateState>(
  UpdateController.new,
);

/// 更新檢查與下載的協調者。
class UpdateController extends Notifier<UpdateState> {
  /// [build] 刻意不做任何 side effect。
  ///
  /// 這樣任何只是渲染設定畫面的 widget 測試都不會意外連網；背景檢查一律由
  /// `UpdateCheckStarter` 在 app 啟動時明確觸發。
  @override
  UpdateState build() => const UpdateState.idle();

  /// 檢查是否有新版本。
  ///
  /// [background] 為 `true` 時（app 啟動）會先套用上次快取的 tag 讓紅點立刻
  /// 出現，而且不顯示「檢查中」狀態——啟動時的檢查應該保持安靜，使用者並沒有
  /// 主動要求它。
  Future<void> checkForUpdates({bool background = false}) async {
    if (state.isChecking) {
      return;
    }

    final platform = ref.read(updatePlatformProvider);
    final currentVersion = await _currentVersion();

    if (background && currentVersion != null) {
      await _applyCachedTag(currentVersion);
    }

    if (!background) {
      state = state.copyWith(
        checkPhase: UpdateCheckPhase.checking,
        clearCheckError: true,
      );
    }

    try {
      final release = await ref
          .read(githubReleaseClientProvider)
          .fetchLatestRelease();

      await UpdateCheckStorage.saveLatestTag(release.tagName);

      if (currentVersion == null) {
        // 讀不到自己的版本就無從比較；當成檢查失敗，不要誤報有更新。
        state = state.copyWith(
          checkPhase: UpdateCheckPhase.failed,
          checkError: '無法讀取目前的應用程式版本',
        );
        return;
      }

      if (!release.version.isNewerThan(currentVersion)) {
        state = state.copyWith(
          checkPhase: UpdateCheckPhase.upToDate,
          latestRelease: release,
          clearAsset: true,
          clearCheckError: true,
        );
        return;
      }

      final asset = platform.selectAsset(release.assets);

      state = state.copyWith(
        checkPhase: UpdateCheckPhase.updateAvailable,
        latestRelease: release,
        asset: asset,
        // asset 為 null（平台不支援，或 Release 少了對應檔案）時要真的清空，
        // 否則 copyWith 的 `??` 會保留上一輪的 asset。
        clearAsset: asset == null,
        clearCheckError: true,
      );
    } on Object catch (error) {
      if (background && state.hasUpdate) {
        // 背景檢查失敗，但快取已經判定有更新：保留紅點，不要因為一次網路
        // 失誤就把提示收回去。
        return;
      }

      state = state.copyWith(
        checkPhase: UpdateCheckPhase.failed,
        checkError: _describeError(error),
      );
    }
  }

  /// 下載目前平台的安裝檔，完成後交給作業系統開啟。
  Future<void> downloadAndInstall() async {
    final asset = state.asset;

    if (asset == null || state.isDownloading) {
      return;
    }

    state = state.copyWith(
      downloadPhase: UpdateDownloadPhase.downloading,
      receivedBytes: 0,
      totalBytes: asset.size,
      clearDownloadError: true,
      clearDownloadedPath: true,
    );

    final downloader = ref.read(updateDownloaderProvider);

    try {
      final path = await downloader.download(
        asset,
        onProgress: (received, total) {
          // 進度回呼可能在下載被取代／結束後才送達；只在仍處於下載階段時更新。
          if (state.downloadPhase != UpdateDownloadPhase.downloading) {
            return;
          }
          state = state.copyWith(receivedBytes: received, totalBytes: total);
        },
      );

      state = state.copyWith(
        downloadPhase: UpdateDownloadPhase.opening,
        downloadedPath: path,
      );

      await downloader.openDownloadedFile(path);

      state = state.copyWith(downloadPhase: UpdateDownloadPhase.completed);
    } on Object catch (error) {
      // downloadedPath 刻意保留：即使「開啟」失敗，使用者仍看得到檔案在哪。
      state = state.copyWith(
        downloadPhase: UpdateDownloadPhase.failed,
        downloadError: _describeError(error),
      );
    }
  }

  /// 開啟安裝檔失敗後重試「開啟」，不必重新下載。
  Future<void> retryOpenDownloadedFile() async {
    final path = state.downloadedPath;

    if (path == null || state.isDownloading) {
      return;
    }

    state = state.copyWith(
      downloadPhase: UpdateDownloadPhase.opening,
      clearDownloadError: true,
    );

    try {
      await ref.read(updateDownloaderProvider).openDownloadedFile(path);
      state = state.copyWith(downloadPhase: UpdateDownloadPhase.completed);
    } on Object catch (error) {
      state = state.copyWith(
        downloadPhase: UpdateDownloadPhase.failed,
        downloadError: _describeError(error),
      );
    }
  }

  /// 以快取的 tag 先行判斷是否有更新，讓紅點在網路回應前就出現。
  Future<void> _applyCachedTag(AppVersion currentVersion) async {
    final cachedTag = await UpdateCheckStorage.loadLatestTag();

    if (cachedTag == null) {
      return;
    }

    final cachedVersion = AppVersion.tryParseTag(cachedTag);

    if (cachedVersion != null && cachedVersion.isNewerThan(currentVersion)) {
      state = state.copyWith(checkPhase: UpdateCheckPhase.updateAvailable);
    }
  }

  Future<AppVersion?> _currentVersion() async {
    try {
      final info = await ref.read(packageInfoProvider.future);
      return AppVersion.tryParsePackageInfo(info.version, info.buildNumber);
    } on Object {
      return null;
    }
  }

  static String _describeError(Object error) {
    // service 層已經把低階失敗翻譯成可顯示的訊息。
    if (error is UpdateException) {
      return error.message;
    }
    if (error is FormatException) {
      return error.message;
    }
    return error.toString();
  }
}
