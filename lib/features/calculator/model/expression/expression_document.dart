import 'tree_expression_document.dart';

/// 算式的唯一資料來源：Expression Tree。
///
/// Phase 6 後，此型別即為 [TreeExpressionDocument] 的正式別名。State、
/// ViewModel、Screen 與所有 service 均以此為算式模型，不再保存 evaluation
/// string、TeX string 或 cursor offset。
typedef ExpressionDocument = TreeExpressionDocument;
