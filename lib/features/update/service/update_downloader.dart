import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/release_info.dart';
import '../model/update_exception.dart';
import '../model/update_platform.dart';
import 'github_release_client.dart';

/// 下載進度回呼。[total] 為 `0` 表示伺服器沒有提供總長度。
typedef DownloadProgressCallback = void Function(int received, int total);

/// 下載並開啟安裝檔的抽象介面（測試以假實作覆寫）。
abstract class UpdateDownloader {
  /// 下載 [asset]，回傳落地檔案的絕對路徑。
  Future<String> download(
    ReleaseAsset asset, {
    DownloadProgressCallback? onProgress,
  });

  /// 把 [path] 的檔案交給作業系統開啟（安裝程式 / DMG / APK 安裝器）。
  ///
  /// 失敗時擲回 [UpdateException]，讓 UI 能改為顯示檔案路徑作為後備。
  Future<void> openDownloadedFile(String path);
}

/// 以 `http` 串流下載，再依平台交給作業系統開啟。
class HttpUpdateDownloader implements UpdateDownloader {
  HttpUpdateDownloader({http.Client? httpClient, UpdatePlatform? platform})
    : _httpClient = httpClient ?? http.Client(),
      _platform = platform ?? UpdatePlatform.current;

  final http.Client _httpClient;
  final UpdatePlatform _platform;

  @override
  Future<String> download(
    ReleaseAsset asset, {
    DownloadProgressCallback? onProgress,
  }) async {
    final directory = await _resolveDownloadDirectory();
    await directory.create(recursive: true);

    final target = File(p.join(directory.path, asset.name));

    // 先寫入 `.part`，成功後才 rename 成正式檔名；這樣中途失敗留下的半截檔案
    // 不可能被誤當成安裝檔開啟。
    final partial = File('${target.path}.part');

    if (await partial.exists()) {
      await partial.delete();
    }
    if (await target.exists()) {
      await target.delete();
    }

    final request = http.Request(
      'GET',
      Uri.parse(asset.browserDownloadUrl),
    )..headers['User-Agent'] = HttpGithubReleaseClient.userAgent;

    final http.StreamedResponse response;

    try {
      response = await _httpClient.send(request);
    } on SocketException {
      throw const UpdateException('無法連線到 GitHub，請檢查網路連線');
    } on TimeoutException {
      throw const UpdateException('連線逾時，請稍後再試');
    } on http.ClientException catch (error) {
      throw UpdateException('下載失敗：${error.message}');
    }

    if (response.statusCode != 200) {
      throw UpdateException('下載失敗：HTTP ${response.statusCode}');
    }

    // GitHub 的下載端點會經過重導向，不保證回傳 Content-Length；此時退回使用
    // Release API 提供的 asset 大小，讓進度條仍能顯示百分比。
    final total = response.contentLength ?? asset.size;
    var received = 0;

    final sink = partial.openWrite();

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.flush();
      await sink.close();
    } on Object {
      // close() 可能因為前面的錯誤再次擲例外，這裡的目的只是確保檔案代碼釋放。
      await sink.close().catchError((_) {});
      if (await partial.exists()) {
        await partial.delete();
      }
      rethrow;
    }

    final file = await partial.rename(target.path);
    return file.path;
  }

  /// 安裝檔的存放位置。
  ///
  /// Android 刻意放在 app 專屬目錄（`getExternalStorageDirectory()` 對應
  /// `getExternalFilesDir(null)`）：`open_filex` 的 `pathRequiresPermission()`
  /// 對 app 目錄底下的檔案回傳 `false`，因此不需要任何執行期儲存權限。
  Future<Directory> _resolveDownloadDirectory() async {
    switch (_platform) {
      case UpdatePlatform.android:
        return await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      case UpdatePlatform.windows:
        return await getDownloadsDirectory() ?? await getTemporaryDirectory();
      case UpdatePlatform.macos:
        return await getDownloadsDirectory() ??
            await getApplicationSupportDirectory();
      case UpdatePlatform.unsupported:
        return getTemporaryDirectory();
    }
  }

  @override
  Future<void> openDownloadedFile(String path) async {
    switch (_platform) {
      case UpdatePlatform.android:
        // open_filex 內建 FileProvider，並把 `.apk` 對應到
        // `application/vnd.android.package-archive`，因此會叫起系統安裝程式。
        // （open_filex 為了 Play 政策移除了 REQUEST_INSTALL_PACKAGES，所以要由
        // app 自己在 AndroidManifest 宣告。）
        final result = await OpenFilex.open(path);
        if (result.type != ResultType.done) {
          throw UpdateException('無法開啟安裝檔：${result.message}');
        }

      case UpdatePlatform.windows:
      case UpdatePlatform.macos:
      case UpdatePlatform.unsupported:
        // 桌面平台不使用 open_filex：它在 macOS 是 `Process.start('open', ...)`，
        // 在 App Sandbox 下會被擋。url_launcher 走的是 NSWorkspace（macOS）與
        // ShellExecute（Windows），兩者在目前的設定下都能運作。
        final launched = await launchUrl(Uri.file(path));
        if (!launched) {
          throw const UpdateException('作業系統拒絕開啟安裝檔');
        }
    }
  }
}
