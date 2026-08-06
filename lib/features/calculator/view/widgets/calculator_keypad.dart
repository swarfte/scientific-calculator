import 'package:flutter/material.dart';

import 'calculator_key.dart';

class CalculatorKeypad extends StatelessWidget {
  const CalculatorKeypad({
    required this.onDigit,
    required this.onDecimal,
    required this.onAdd,
    required this.onSubtract,
    required this.onMultiply,
    required this.onDivide,
    required this.onOpenParenthesis,
    required this.onCloseParenthesis,
    required this.onSquare,
    required this.onPower,
    required this.onSquareRoot,
    required this.onSin,
    required this.onCos,
    required this.onTan,
    required this.onLog,
    required this.onLn,
    required this.onPi,
    required this.onEulerNumber,
    required this.onBackspace,
    required this.onClear,
    required this.onCalculate,
    required this.onFraction,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onMoveLeft,
    required this.onMoveRight,
    super.key,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDecimal;
  final VoidCallback onAdd;
  final VoidCallback onSubtract;
  final VoidCallback onMultiply;
  final VoidCallback onDivide;
  final VoidCallback onOpenParenthesis;
  final VoidCallback onCloseParenthesis;
  final VoidCallback onSquare;
  final VoidCallback onPower;
  final VoidCallback onSquareRoot;
  final VoidCallback onSin;
  final VoidCallback onCos;
  final VoidCallback onTan;
  final VoidCallback onLog;
  final VoidCallback onLn;
  final VoidCallback onPi;
  final VoidCallback onEulerNumber;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onCalculate;
  final VoidCallback onFraction;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row([
          _key('a/b', onFraction, CalculatorKeyStyle.function),
          _key('↑', onMoveUp, CalculatorKeyStyle.function),
          _key('↓', onMoveDown, CalculatorKeyStyle.function),
          _key('←', onMoveLeft, CalculatorKeyStyle.function),
          _key('→', onMoveRight, CalculatorKeyStyle.function),
        ]),
        _row([
          _key('sin', onSin, CalculatorKeyStyle.function),
          _key('cos', onCos, CalculatorKeyStyle.function),
          _key('tan', onTan, CalculatorKeyStyle.function),
          _key('DEL', onBackspace, CalculatorKeyStyle.destructive),
          _key('AC', onClear, CalculatorKeyStyle.destructive),
        ]),
        _row([
          _key('log₁₀', onLog, CalculatorKeyStyle.function),
          _key('ln', onLn, CalculatorKeyStyle.function),
          _key('√', onSquareRoot, CalculatorKeyStyle.function),
          _key('x²', onSquare, CalculatorKeyStyle.function),
          _key('xʸ', onPower, CalculatorKeyStyle.function),
        ]),
        _row([
          _key('(', onOpenParenthesis, CalculatorKeyStyle.function),
          _key(')', onCloseParenthesis, CalculatorKeyStyle.function),

          _key('π', onPi, CalculatorKeyStyle.function),
          _key('÷', onDivide, CalculatorKeyStyle.operator),
        ]),
        _row([
          _digit('7'),
          _digit('8'),
          _digit('9'),
          _key('×', onMultiply, CalculatorKeyStyle.operator),
        ]),
        _row([
          _digit('4'),
          _digit('5'),
          _digit('6'),
          _key('−', onSubtract, CalculatorKeyStyle.operator),
        ]),
        _row([
          _digit('1'),
          _digit('2'),
          _digit('3'),
          _key('+', onAdd, CalculatorKeyStyle.operator),
        ]),
        _row([
          _digit('0'),
          _key('.', onDecimal, CalculatorKeyStyle.normal),
          _key('e', onEulerNumber, CalculatorKeyStyle.function),
          _key('=', onCalculate, CalculatorKeyStyle.equals),
        ]),
      ],
    );
  }

  Widget _row(List<Widget> children) {
    return Expanded(child: Row(children: children));
  }

  Widget _digit(String digit, {int flex = 1}) {
    return CalculatorKey(
      label: digit,
      flex: flex,
      onPressed: () => onDigit(digit),
    );
  }

  Widget _key(
    String label,
    VoidCallback callback,
    CalculatorKeyStyle style, {
    int flex = 1,
  }) {
    return CalculatorKey(
      label: label,
      flex: flex,
      style: style,
      onPressed: callback,
    );
  }
}
