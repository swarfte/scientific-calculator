/// 更新流程中可直接顯示給使用者的錯誤。
///
/// service 層負責把 `SocketException` / `TimeoutException` / HTTP 狀態碼等
/// 低階失敗翻譯成這個型別，viewmodel 就不需要 `import 'dart:io'`，也不必
/// 靠字串比對去猜錯誤成因。
class UpdateException implements Exception {
  const UpdateException(this.message);

  /// 已經寫成人話、可直接放進 UI 的訊息。
  final String message;

  @override
  String toString() => message;
}
