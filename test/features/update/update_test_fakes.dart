import 'dart:convert';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:scientific_calculator/features/update/model/release_info.dart';
import 'package:scientific_calculator/features/update/model/update_exception.dart';
import 'package:scientific_calculator/features/update/service/github_release_client.dart';
import 'package:scientific_calculator/features/update/service/update_downloader.dart';

import 'model/release_fixture.dart';

/// 以固定回應取代真正的 GitHub API。
class FakeGithubReleaseClient implements GithubReleaseClient {
  FakeGithubReleaseClient({this.release, this.error});

  /// 成功時回傳的 Release；為 `null` 且 [error] 也為 `null` 時回傳 fixture。
  final ReleaseInfo? release;

  /// 不為 `null` 時，[fetchLatestRelease] 會擲出它。
  final Object? error;

  int callCount = 0;

  @override
  Future<ReleaseInfo> fetchLatestRelease() async {
    callCount++;

    final failure = error;
    if (failure != null) {
      throw failure;
    }

    return release ?? fixtureRelease();
  }
}

/// 可控制進度與失敗點的下載器。
class FakeUpdateDownloader implements UpdateDownloader {
  FakeUpdateDownloader({
    this.path = '/tmp/scientific_calculator-Windows-Setup.exe',
    this.downloadError,
    this.openError,
    this.progressSteps = const [],
  });

  final String path;
  final Object? downloadError;
  final Object? openError;

  /// 下載期間要回報的 `(received, total)` 序列。
  final List<(int, int)> progressSteps;

  final List<String> openedPaths = [];
  int downloadCount = 0;

  @override
  Future<String> download(
    ReleaseAsset asset, {
    DownloadProgressCallback? onProgress,
  }) async {
    downloadCount++;

    for (final (received, total) in progressSteps) {
      onProgress?.call(received, total);
    }

    final failure = downloadError;
    if (failure != null) {
      throw failure;
    }

    return path;
  }

  @override
  Future<void> openDownloadedFile(String path) async {
    openedPaths.add(path);

    final failure = openError;
    if (failure != null) {
      throw failure;
    }
  }
}

/// 由真實 API 回應 fixture 建出的 Release（2026.8.7 build 6）。
ReleaseInfo fixtureRelease() {
  return ReleaseInfo.fromJson(
    jsonDecode(latestReleaseJson) as Map<String, dynamic>,
  );
}

/// 測試用的 PackageInfo。
PackageInfo packageInfo({String version = '2026.8.7', String buildNumber = '6'}) {
  return PackageInfo(
    appName: 'Sci Calc',
    packageName: 'scientific_calculator',
    version: version,
    buildNumber: buildNumber,
    buildSignature: '',
    installerStore: null,
  );
}

/// 常見的網路失敗，已經被 service 層翻譯成可顯示的訊息。
const networkFailure = UpdateException('無法連線到 GitHub，請檢查網路連線');
