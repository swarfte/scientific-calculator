import '../model/expression/expression_document.dart';

class ExpressionTexSerializer {
  const ExpressionTexSerializer();

  String serialize(ExpressionDocument document) {
    if (document.texExpression.trim().isEmpty) {
      return r'\square';
    }

    var tex = document.texExpression;

    final openingBraces = RegExp(r'\{').allMatches(tex).length;
    final closingBraces = RegExp(r'\}').allMatches(tex).length;

    if (openingBraces > closingBraces) {
      tex += List.filled(openingBraces - closingBraces, '}').join();
    }

    return tex;
  }
}
