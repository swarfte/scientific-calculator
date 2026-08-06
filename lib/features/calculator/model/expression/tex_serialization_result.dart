/// Tree TeX 序列化的結果。
///
/// 包含兩個等寬的 TeX 字串，用於閃爍游標動畫：
///
/// * [withVisibleCursor]：包含 visible cursor marker（`\vert`）。
/// * [withHiddenCursor]：包含 hidden cursor marker（`\phantom{\vert}`），
///   占位寬度與 visible 版本相同，確保公式閃爍時不左右位移。
///
/// 兩者只差在 cursor marker 本身，其餘結構完全相同。
class TexSerializationResult {
  const TexSerializationResult({
    required this.withVisibleCursor,
    required this.withHiddenCursor,
  });

  final String withVisibleCursor;
  final String withHiddenCursor;
}
