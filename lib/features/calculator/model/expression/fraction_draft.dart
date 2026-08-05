import 'expression_document.dart';

enum FractionPart { numerator, denominator }

class FractionDraft {
  const FractionDraft({
    required this.numerator,
    required this.denominator,
    this.activePart = FractionPart.numerator,
  });

  factory FractionDraft.empty() {
    return FractionDraft(
      numerator: ExpressionDocument.empty(),
      denominator: ExpressionDocument.empty(),
    );
  }

  final ExpressionDocument numerator;
  final ExpressionDocument denominator;
  final FractionPart activePart;

  ExpressionDocument get activeDocument {
    return switch (activePart) {
      FractionPart.numerator => numerator,
      FractionPart.denominator => denominator,
    };
  }

  bool get isComplete {
    return !numerator.isEmpty && !denominator.isEmpty;
  }

  FractionDraft updateActiveDocument(ExpressionDocument document) {
    return switch (activePart) {
      FractionPart.numerator => copyWith(numerator: document),
      FractionPart.denominator => copyWith(denominator: document),
    };
  }

  FractionDraft moveToNumerator() {
    return copyWith(activePart: FractionPart.numerator);
  }

  FractionDraft moveToDenominator() {
    return copyWith(activePart: FractionPart.denominator);
  }

  FractionDraft copyWith({
    ExpressionDocument? numerator,
    ExpressionDocument? denominator,
    FractionPart? activePart,
  }) {
    return FractionDraft(
      numerator: numerator ?? this.numerator,
      denominator: denominator ?? this.denominator,
      activePart: activePart ?? this.activePart,
    );
  }
}
