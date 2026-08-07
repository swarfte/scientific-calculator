import 'release_info.dart';

/// 更新檢查的階段。
enum UpdateCheckPhase {
  /// 尚未檢查。
  idle,

  /// 正在向 GitHub 查詢。
  checking,

  /// 已是最新版本。
  upToDate,

  /// 有可用的新版本。
  updateAvailable,

  /// 檢查失敗（網路錯誤、API 回應無法解析等）。
  failed,
}

/// 下載／開啟安裝檔的階段。
enum UpdateDownloadPhase {
  idle,

  /// 正在下載安裝檔。
  downloading,

  /// 下載完成，正在交給作業系統開啟。
  opening,

  /// 已交給作業系統（安裝程式應該已經啟動）。
  completed,

  /// 下載或開啟失敗。
  failed,
}

/// 更新功能的完整 UI 狀態。
///
/// 檢查與下載的錯誤分開存放，避免下載失敗時把「有新版本」的資訊蓋掉——
/// 使用者仍然看得到版本號，也還能重試。
class UpdateState {
  const UpdateState({
    this.checkPhase = UpdateCheckPhase.idle,
    this.downloadPhase = UpdateDownloadPhase.idle,
    this.latestRelease,
    this.asset,
    this.checkError,
    this.downloadError,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.downloadedPath,
  });

  const UpdateState.idle() : this();

  final UpdateCheckPhase checkPhase;
  final UpdateDownloadPhase downloadPhase;

  /// 最新的 Release；只有背景檢查靠快取先亮紅點、尚未取得完整資料時才為 `null`。
  final ReleaseInfo? latestRelease;

  /// 目前平台對應的安裝檔；平台不支援或 Release 沒有對應檔案時為 `null`。
  final ReleaseAsset? asset;

  final String? checkError;
  final String? downloadError;

  final int receivedBytes;

  /// 伺服器回報的總長度；未提供 `Content-Length` 時為 `0`。
  final int totalBytes;

  /// 下載完成的檔案路徑；即使後續「開啟」失敗也會保留，讓使用者能自行開啟。
  final String? downloadedPath;

  /// 是否要在設定按鈕上顯示紅點。
  bool get hasUpdate => checkPhase == UpdateCheckPhase.updateAvailable;

  bool get isChecking => checkPhase == UpdateCheckPhase.checking;

  bool get isDownloading =>
      downloadPhase == UpdateDownloadPhase.downloading ||
      downloadPhase == UpdateDownloadPhase.opening;

  /// 有新版本但這個平台沒有對應的安裝檔（Linux / iOS / Web，或 CI 尚未上傳）。
  bool get hasUpdateWithoutAsset => hasUpdate && asset == null;

  /// 下載進度 0.0–1.0；總長度未知時回傳 `null`（UI 顯示不確定進度）。
  double? get progress {
    if (totalBytes <= 0) {
      return null;
    }
    return (receivedBytes / totalBytes).clamp(0.0, 1.0);
  }

  /// 例如 `6.7 MB / 11.0 MB`；總長度未知時只顯示已下載量。
  String get progressLabel {
    final received = formatBytes(receivedBytes);
    if (totalBytes <= 0) {
      return received;
    }
    return '$received / ${formatBytes(totalBytes)}';
  }

  UpdateState copyWith({
    UpdateCheckPhase? checkPhase,
    UpdateDownloadPhase? downloadPhase,
    ReleaseInfo? latestRelease,
    ReleaseAsset? asset,
    String? checkError,
    String? downloadError,
    int? receivedBytes,
    int? totalBytes,
    String? downloadedPath,
    bool clearLatestRelease = false,
    bool clearAsset = false,
    bool clearCheckError = false,
    bool clearDownloadError = false,
    bool clearDownloadedPath = false,
  }) {
    return UpdateState(
      checkPhase: checkPhase ?? this.checkPhase,
      downloadPhase: downloadPhase ?? this.downloadPhase,
      latestRelease: clearLatestRelease
          ? null
          : (latestRelease ?? this.latestRelease),
      asset: clearAsset ? null : (asset ?? this.asset),
      checkError: clearCheckError ? null : (checkError ?? this.checkError),
      downloadError: clearDownloadError
          ? null
          : (downloadError ?? this.downloadError),
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedPath: clearDownloadedPath
          ? null
          : (downloadedPath ?? this.downloadedPath),
    );
  }
}
