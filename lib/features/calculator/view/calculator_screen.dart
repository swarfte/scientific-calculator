import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/always_on_top_settings.dart';
import '../viewmodel/calculator_providers.dart';
import 'widgets/calculator_keypad.dart';
import 'widgets/mode_indicator.dart';
import 'widgets/natural_math_display.dart';
import 'widgets/pin_button.dart';
import 'widgets/result_display.dart';
import 'widgets/settings_button.dart';

class CalculatorScreen extends ConsumerWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calculatorViewModelProvider);
    final viewModel = ref.read(calculatorViewModelProvider.notifier);
    final serializer = ref.watch(treeExpressionTexSerializerProvider);

    // TeX 完全由 Tree Serializer 產生；按 `=` 後游標不顯示。
    final texResult = serializer.serialize(
      state.document,
      cursorVisible: !state.hasEvaluated,
    );

    // 釘選 (always-on-top) 只在桌面平台提供。
    final isDesktop = ref.watch(isDesktopPlatformProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        centerTitle: false,
        actions: [
          if (isDesktop) const PinButton(),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ModeIndicator(
              angleMode: state.angleMode,
              onPressed: viewModel.toggleAngleMode,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: SettingsButton(),
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
                          tex: texResult.withHiddenCursor,
                          texWithCursor: texResult.withVisibleCursor,
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
                      onOpenParenthesis: viewModel.inputOpenGroup,
                      onCloseParenthesis: viewModel.inputCloseGroup,
                      onSquare: viewModel.inputSquare,
                      onPower: viewModel.inputPower,
                      onSquareRoot: viewModel.inputSquareRoot,
                      onSin: viewModel.inputSin,
                      onCos: viewModel.inputCos,
                      onTan: viewModel.inputTan,
                      onLog: viewModel.inputLog10,
                      onLn: viewModel.inputLn,
                      onPi: viewModel.inputPi,
                      onEulerNumber: viewModel.inputEulerNumber,
                      onBackspace: viewModel.backspace,
                      onClear: viewModel.clear,
                      onCalculate: viewModel.calculate,
                      onFraction: viewModel.inputFraction,
                      onMoveUp: viewModel.moveUp,
                      onMoveDown: viewModel.moveDown,
                      onMoveLeft: viewModel.moveLeft,
                      onMoveRight: viewModel.moveRight,
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
