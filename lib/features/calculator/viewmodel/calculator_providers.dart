import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/calculator_state.dart';
import '../service/calculator_engine.dart';
import '../service/expression_editor.dart';
import '../service/expression_evaluator.dart';
import '../service/expression_tex_serializer.dart';
import 'calculator_view_model.dart';

final expressionEditorProvider = Provider<ExpressionEditor>((ref) {
  return const ExpressionEditor();
});

final expressionEvaluatorProvider = Provider<ExpressionEvaluator>((ref) {
  return const ExpressionEvaluator();
});

final expressionTexSerializerProvider = Provider<ExpressionTexSerializer>((
  ref,
) {
  return const ExpressionTexSerializer();
});

final calculatorEngineProvider = Provider<CalculatorEngine>((ref) {
  return CalculatorEngine(
    evaluator: ref.watch(expressionEvaluatorProvider),
    editor: ref.watch(expressionEditorProvider),
  );
});

final calculatorViewModelProvider =
    NotifierProvider<CalculatorViewModel, CalculatorState>(
      CalculatorViewModel.new,
    );
