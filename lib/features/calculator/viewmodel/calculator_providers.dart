import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/calculator_state.dart';
import '../service/expression_compiler.dart';
import '../service/expression_navigator.dart';
import '../service/expression_validator.dart';
import '../service/tree_calculator_engine.dart';
import '../service/tree_expression_editor.dart';
import '../service/tree_expression_tex_serializer.dart';
import 'calculator_view_model.dart';

/// Expression Tree 編輯器。
final treeExpressionEditorProvider = Provider<TreeExpressionEditor>((ref) {
  return const TreeExpressionEditor();
});

/// Expression Tree 結構化導航。
final expressionNavigatorProvider = Provider<ExpressionNavigator>((ref) {
  return const ExpressionNavigator();
});

/// Expression Tree -> TeX 序列化器（含閃爍游標）。
final treeExpressionTexSerializerProvider =
    Provider<TreeExpressionTexSerializer>((ref) {
      return const TreeExpressionTexSerializer();
    });

/// Expression Tree 驗證器。
final expressionValidatorProvider = Provider<ExpressionValidator>((ref) {
  return const ExpressionValidator();
});

/// Expression Tree 編譯器。
final expressionCompilerProvider = Provider<ExpressionCompiler>((ref) {
  return const ExpressionCompiler();
});

/// Expression Tree 求值器。
final treeCalculatorEngineProvider = Provider<TreeCalculatorEngine>((ref) {
  return TreeCalculatorEngine(
    validator: ref.watch(expressionValidatorProvider),
    compiler: ref.watch(expressionCompilerProvider),
  );
});

final calculatorViewModelProvider =
    NotifierProvider<CalculatorViewModel, CalculatorState>(
      CalculatorViewModel.new,
    );
