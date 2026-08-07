class CalculationResult {
  const CalculationResult({
    required this.value,
    required this.formattedValue,
    this.formattedTex,
  });

  final num value;

  /// 顯示用的純文字值（小數格式）；供 `ResultDisplay` 在沒有 [formattedTex]
  /// 時顯示，也作為 `Ans` 等以純文字傳遞時的來源。
  final String formattedValue;

  /// 以 TeX 表示的精確結果（最簡分數／帶分數／根式）。
  ///
  /// 僅在「分數」顯示模式且結果可精確化簡時為非 `null`。為 `null` 時
  /// [ResultDisplay] 退回使用 [formattedValue]（小數）。
  final String? formattedTex;
}
