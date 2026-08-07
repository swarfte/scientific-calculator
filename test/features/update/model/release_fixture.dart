/// `GET /repos/swarfte/sci-calc/releases/latest` 的真實回應（節錄）。
///
/// 只保留解析會用到的欄位；tag、標題與三個 asset 的檔名／大小／URL 都與正式
/// 回應一字不差，作為 CI 產出格式的迴歸基準。
const latestReleaseJson = '''
{
  "html_url": "https://github.com/swarfte/Sci-Calc/releases/tag/v2026.8.7-build.6-attempt.1",
  "id": 366530658,
  "tag_name": "v2026.8.7-build.6-attempt.1",
  "name": "2026.8.7 (Build 6)",
  "draft": false,
  "prerelease": false,
  "created_at": "2026-08-07T04:57:10Z",
  "published_at": "2026-08-07T05:02:14Z",
  "assets": [
    {
      "id": 504680180,
      "name": "scientific_calculator-Android.apk",
      "label": "scientific_calculator Android APK",
      "content_type": "application/vnd.android.package-archive",
      "state": "uploaded",
      "size": 51874918,
      "download_count": 0,
      "browser_download_url": "https://github.com/swarfte/Sci-Calc/releases/download/v2026.8.7-build.6-attempt.1/scientific_calculator-Android.apk"
    },
    {
      "id": 504680182,
      "name": "scientific_calculator-Windows-Setup.exe",
      "label": "scientific_calculator Windows Installer",
      "content_type": "application/octet-stream",
      "state": "uploaded",
      "size": 11575039,
      "download_count": 1,
      "browser_download_url": "https://github.com/swarfte/Sci-Calc/releases/download/v2026.8.7-build.6-attempt.1/scientific_calculator-Windows-Setup.exe"
    },
    {
      "id": 504680181,
      "name": "scientific_calculator.dmg",
      "label": "scientific_calculator macOS Apple Silicon DMG",
      "content_type": "application/x-apple-diskimage",
      "state": "uploaded",
      "size": 20481644,
      "download_count": 0,
      "browser_download_url": "https://github.com/swarfte/Sci-Calc/releases/download/v2026.8.7-build.6-attempt.1/scientific_calculator.dmg"
    }
  ],
  "body": "## What's Changed\\n* Skip invisible cursor steps and fix TeX spacing by @swarfte in https://github.com/swarfte/scientific-calculator/pull/26"
}
''';
