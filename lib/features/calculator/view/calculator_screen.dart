import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodel/calculator_providers.dart';
import 'widgets/calculator_keypad.dart';
import 'widgets/mode_indicator.dart';
import 'widgets/natural_math_display.dart';
import 'widgets/result_display.dart';

class CalculatorScreen extends ConsumerWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calculatorViewModelProvider);

    final viewModel = ref.read(calculatorViewModelProvider.notifier);

    final serializer = ref.watch(expressionTexSerializerProvider);

    final displayTex = serializer.serialize(
      state.document,
      fractionDraft: state.fractionDraft,
      showCursor: false,
    );

    final displayTexWithCursor = serializer.serialize(
      state.document,
      fractionDraft: state.fractionDraft,
      showCursor: true,
    );

    final activeDocument =
        state.fractionDraft?.activeDocument ?? state.document;

    final fallbackText = activeDocument.evaluationExpression;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scientific Calculator'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ModeIndicator(
              angleMode: state.angleMode,
              onPressed: viewModel.toggleAngleMode,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        NaturalMathDisplay(
                          tex: displayTex,
                          texWithCursor: displayTexWithCursor,
                          fallbackText: fallbackText,
                          showCursor: !state.hasEvaluated,
                        ),
                        const Divider(height: 1),
                        ResultDisplay(
                          result: state.result?.formattedValue,
                          errorMessage: state.errorMessage,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: CalculatorKeypad(
                      onDigit: viewModel.inputDigit,
                      onDecimal: viewModel.inputDecimalPoint,
                      onAdd: viewModel.inputAdd,
                      onSubtract: viewModel.inputSubtract,
                      onMultiply: viewModel.inputMultiply,
                      onDivide: viewModel.inputDivide,
                      onOpenParenthesis: viewModel.inputOpenParenthesis,
                      onCloseParenthesis: viewModel.inputCloseParenthesis,
                      onSquare: viewModel.inputSquare,
                      onPower: viewModel.inputPower,
                      onSquareRoot: viewModel.inputSquareRoot,
                      onSin: viewModel.inputSin,
                      onCos: viewModel.inputCos,
                      onTan: viewModel.inputTan,
                      onLog: viewModel.inputLog,
                      onLn: viewModel.inputLn,
                      onPi: viewModel.inputPi,
                      onEulerNumber: viewModel.inputEulerNumber,
                      onBackspace: viewModel.backspace,
                      onClear: viewModel.clear,
                      onCalculate: viewModel.calculate,
                      onFraction: viewModel.startFraction,
                      onMoveUp: viewModel.moveFractionUp,
                      onMoveDown: viewModel.moveFractionDown,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
