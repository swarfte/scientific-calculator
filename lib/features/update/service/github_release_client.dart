import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../model/release_info.dart';
import '../model/update_exception.dart';

/// 取得最新 Release 的抽象介面。
///
/// 抽出介面是為了讓 viewmodel 測試能以假實作覆寫
/// `githubReleaseClientProvider`，不需要真的連網。
abstract class GithubReleaseClient {
  /// 成功時回傳最新 Release；所有失敗都以 [UpdateException] 呈現。
  Future<ReleaseInfo> fetchLatestRelease();
}

/// 以 GitHub REST API 取得最新 Release。
class HttpGithubReleaseClient implements GithubReleaseClient {
  HttpGithubReleaseClient({
    http.Client? httpClient,
    this.timeout = _defaultTimeout,
  }) : _httpClient = httpClient ?? http.Client();

  /// 發佈 Release 的 repository。
  ///
  /// `/releases/latest` 會自動略過草稿與 pre-release，正好符合需求。
  static const latestReleaseUrl =
      'https://api.github.com/repos/swarfte/sci-calc/releases/latest';

  /// GitHub API 會拒絕沒有 User-Agent 的請求。
  static const userAgent = 'scientific-calculator-app';

  static const _defaultTimeout = Duration(seconds: 15);

  final http.Client _httpClient;
  final Duration timeout;

  @override
  Future<ReleaseInfo> fetchLatestRelease() async {
    final http.Response response;

    try {
      response = await _httpClient
          .get(
            Uri.parse(latestReleaseUrl),
            headers: const {
              'Accept': 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2022-11-28',
              'User-Agent': userAgent,
            },
          )
          .timeout(timeout);
    } on SocketException {
      throw const UpdateException('無法連線到 GitHub，請檢查網路連線');
    } on TimeoutException {
      throw const UpdateException('連線逾時，請稍後再試');
    } on http.ClientException catch (error) {
      throw UpdateException('連線失敗：${error.message}');
    }

    if (response.statusCode == 404) {
      throw const UpdateException('尚未發佈任何 Release');
    }

    // 未驗證的 GitHub API 每小時只有 60 次額度；額度用完會回 403 或 429。
    if (response.statusCode == 403 || response.statusCode == 429) {
      throw const UpdateException('GitHub API 查詢次數已達上限，請稍後再試');
    }

    if (response.statusCode != 200) {
      throw UpdateException('GitHub API 回應 ${response.statusCode}');
    }

    try {
      // GitHub 回傳 UTF-8；`response.body` 預設以 latin1 解碼，Release notes
      // 含非 ASCII 字元時會亂碼，因此明確以 UTF-8 解碼。
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('GitHub API 回應格式不正確');
      }

      return ReleaseInfo.fromJson(decoded);
    } on FormatException catch (error) {
      throw UpdateException(error.message);
    }
  }
}
