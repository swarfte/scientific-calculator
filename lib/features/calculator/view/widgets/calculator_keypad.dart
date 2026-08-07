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
    required this.onNthRoot,
    required this.onSin,
    required this.onCos,
    required this.onTan,
    required this.onArcSin,
    required this.onArcCos,
    required this.onArcTan,
    required this.onLog10,
    required this.onLogarithm,
    required this.onLogarithmBase2,
    required this.onLn,
    required this.onPi,
    required this.onEulerNumber,
    required this.onBackspace,
    required this.onClear,
    required this.onCalculate,
    required this.onFraction,
    required this.onMixedFraction,
    required this.onScientific,
    required this.onAnswer,
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
  final VoidCallback onNthRoot;
  final VoidCallback onSin;
  final VoidCallback onCos;
  final VoidCallback onTan;
  final VoidCallback onArcSin;
  final VoidCallback onArcCos;
  final VoidCallback onArcTan;
  final VoidCallback onLog10;
  final VoidCallback onLogarithm;
  final VoidCallback onLogarithmBase2;
  final VoidCallback onLn;
  final VoidCallback onPi;
  final VoidCallback onEulerNumber;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onCalculate;
  final VoidCallback onFraction;
  final VoidCallback onMixedFraction;
  final VoidCallback onScientific;
  final VoidCallback onAnswer;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row([
          _widgetKey(
            semanticLabel: 'a/b',
            callback: onFraction,
            style: CalculatorKeyStyle.function,
            label: const _SimpleFractionIcon(),
          ),
          _widgetKey(
            semanticLabel: 'a b/c',
            callback: onMixedFraction,
            style: CalculatorKeyStyle.function,
            label: const _MixedFractionIcon(),
          ),
          _widgetKey(
            semanticLabel: '↑',
            callback: onMoveUp,
            style: CalculatorKeyStyle.function,
            label: const _TextIcon('↑'),
          ),
          _widgetKey(
            semanticLabel: '↓',
            callback: onMoveDown,
            style: CalculatorKeyStyle.function,
            label: const _TextIcon('↓'),
          ),
          _widgetKey(
            semanticLabel: '←',
            callback: onMoveLeft,
            style: CalculatorKeyStyle.function,
            label: const _TextIcon('←'),
          ),
          _widgetKey(
            semanticLabel: '→',
            callback: onMoveRight,
            style: CalculatorKeyStyle.function,
            label: const _TextIcon('→'),
          ),
        ]),
        _row([
          _widgetKey(
            semanticLabel: 'sin',
            callback: onSin,
            style: CalculatorKeyStyle.function,
            label: const _TextIcon('sin'),
          ),
          _widgetKey(
            semanticLabel: 'cos',
            callback: onCos,
            style: CalculatorKeyStyle.function,
            label: const _TextIcon('cos'),
          ),
          _widgetKey(
            semanticLabel: 'tan',
            callback: onTan,
            style: CalculatorKeyStyle.function,
            label: const _TextIcon('tan'),
          ),
          _widgetKey(
            semanticLabel: 'sin⁻¹',
            callback: onArcSin,
            style: CalculatorKeyStyle.function,
            // Unicode 上標 ⁻¹（U+207B U+00B9）自帶正確的垂直位置。
            label: const _TextIcon('sin⁻¹'),
          ),
          _widgetKey(
            semanticLabel: 'cos⁻¹',
            callback: onArcCos,
            style: CalculatorKeyStyle.function,
            label: const _TextIcon('cos⁻¹'),
          ),
          _widgetKey(
            semanticLabel: 'tan⁻¹',
            callback: onArcTan,
            style: CalculatorKeyStyle.function,
            label: const _TextIcon('tan⁻¹'),
          ),
        ]),
        _row([
          _widgetKey(
            semanticLabel: 'logₓy',
            callback: onLogarithm,
            style: CalculatorKeyStyle.function,
            // Unicode 下標 x（U+2093）作底數，y 為正常大小真數。
            label: const _TextIcon('logₓy'),
          ),
          _widgetKey(
            semanticLabel: 'ln',
            callback: onLn,
            style: CalculatorKeyStyle.function,
            label: const _TextIcon('ln'),
          ),
          _widgetKey(
            semanticLabel: 'π',
            callback: onPi,
            style: CalculatorKeyStyle.function,
            label: const _TextIcon('π'),
          ),
          _widgetKey(
            semanticLabel: 'e',
            callback: onEulerNumber,
            style: CalculatorKeyStyle.function,
            label: const _TextIcon('e'),
          ),
          _widgetKey(
            semanticLabel: '√',
            callback: onSquareRoot,
            style: CalculatorKeyStyle.function,
            label: const _TextIcon('√'),
          ),
          _widgetKey(
            semanticLabel: 'ⁿ√',
            callback: onNthRoot,
            style: CalculatorKeyStyle.function,
            // Unicode 上標 ⁿ（U+207F）+ 根號 √（U+221A）。
            label: const _TextIcon('ⁿ√'),
          ),
        ]),
        _row([
          _widgetKey(
            semanticLabel: 'log₂',
            callback: onLogarithmBase2,
            style: CalculatorKeyStyle.function,
            // Unicode 下標 ₂（U+2082）。
            label: const _TextIcon('log₂'),
          ),
          _widgetKey(
            semanticLabel: 'log₁₀',
            callback: onLog10,
            style: CalculatorKeyStyle.function,
            label: const _TextIcon('log₁₀'),
          ),
          _widgetKey(
            semanticLabel: '(',
            callback: onOpenParenthesis,
            style: CalculatorKeyStyle.function,
            label: const _TextIcon('('),
          ),
          _widgetKey(
            semanticLabel: ')',
            callback: onCloseParenthesis,
            style: CalculatorKeyStyle.function,
            label: const _TextIcon(')'),
          ),
          _widgetKey(
            semanticLabel: 'x²',
            callback: onSquare,
            style: CalculatorKeyStyle.function,
            // Unicode 上標 ²（U+00B2）自帶正確位置。
            label: const _TextIcon('x²'),
          ),
          _widgetKey(
            semanticLabel: 'xʸ',
            callback: onPower,
            style: CalculatorKeyStyle.function,
            // Unicode 上標 ʸ（U+02B8）。
            label: const _TextIcon('xʸ'),
          ),
        ]),
        _row([
          _widgetKey(
            semanticLabel: '7',
            callback: () => onDigit('7'),
            style: CalculatorKeyStyle.normal,
            label: const _TextIcon('7'),
          ),
          _widgetKey(
            semanticLabel: '8',
            callback: () => onDigit('8'),
            style: CalculatorKeyStyle.normal,
            label: const _TextIcon('8'),
          ),
          _widgetKey(
            semanticLabel: '9',
            callback: () => onDigit('9'),
            style: CalculatorKeyStyle.normal,
            label: const _TextIcon('9'),
          ),
          _widgetKey(
            semanticLabel: 'DEL',
            callback: onBackspace,
            style: CalculatorKeyStyle.destructive,
            label: const _TextIcon('DEL'),
          ),
          _widgetKey(
            semanticLabel: 'AC',
            callback: onClear,
            style: CalculatorKeyStyle.destructive,
            label: const _TextIcon('AC'),
          ),
        ]),
        _row([
          _widgetKey(
            semanticLabel: '4',
            callback: () => onDigit('4'),
            style: CalculatorKeyStyle.normal,
            label: const _TextIcon('4'),
          ),
          _widgetKey(
            semanticLabel: '5',
            callback: () => onDigit('5'),
            style: CalculatorKeyStyle.normal,
            label: const _TextIcon('5'),
          ),
          _widgetKey(
            semanticLabel: '6',
            callback: () => onDigit('6'),
            style: CalculatorKeyStyle.normal,
            label: const _TextIcon('6'),
          ),
          _widgetKey(
            semanticLabel: '×',
            callback: onMultiply,
            style: CalculatorKeyStyle.operator,
            label: const _TextIcon('×'),
          ),
          _widgetKey(
            semanticLabel: '÷',
            callback: onDivide,
            style: CalculatorKeyStyle.operator,
            label: const _TextIcon('÷'),
          ),
        ]),
        _row([
          _widgetKey(
            semanticLabel: '1',
            callback: () => onDigit('1'),
            style: CalculatorKeyStyle.normal,
            label: const _TextIcon('1'),
          ),
          _widgetKey(
            semanticLabel: '2',
            callback: () => onDigit('2'),
            style: CalculatorKeyStyle.normal,
            label: const _TextIcon('2'),
          ),
          _widgetKey(
            semanticLabel: '3',
            callback: () => onDigit('3'),
            style: CalculatorKeyStyle.normal,
            label: const _TextIcon('3'),
          ),
          _widgetKey(
            semanticLabel: '+',
            callback: onAdd,
            style: CalculatorKeyStyle.operator,
            label: const _TextIcon('+'),
          ),
          _widgetKey(
            semanticLabel: '−',
            callback: onSubtract,
            style: CalculatorKeyStyle.operator,
            label: const _TextIcon('−'),
          ),
        ]),
        _row([
          _widgetKey(
            semanticLabel: '0',
            callback: () => onDigit('0'),
            style: CalculatorKeyStyle.normal,
            label: const _TextIcon('0'),
          ),
          _widgetKey(
            semanticLabel: '.',
            callback: onDecimal,
            style: CalculatorKeyStyle.normal,
            label: const _TextIcon('.'),
          ),
          _widgetKey(
            semanticLabel: 'Exp',
            callback: onScientific,
            style: CalculatorKeyStyle.normal,
            label: const _TextIcon('Exp'),
          ),
          _widgetKey(
            semanticLabel: 'Ans',
            callback: onAnswer,
            style: CalculatorKeyStyle.normal,
            label: const _TextIcon('Ans'),
          ),
          _widgetKey(
            semanticLabel: '=',
            callback: onCalculate,
            style: CalculatorKeyStyle.equals,
            label: const _TextIcon('='),
          ),
        ]),
      ],
    );
  }

  Widget _row(List<Widget> children) {
    return Expanded(child: Row(children: children));
  }

  Widget _widgetKey({
    required String semanticLabel,
    required VoidCallback callback,
    required CalculatorKeyStyle style,
    required Widget label,
    int flex = 1,
  }) {
    return CalculatorKey(
      label: semanticLabel,
      flex: flex,
      style: style,
      labelWidget: label,
      onPressed: callback,
    );
  }
}

/// 取得當前按鍵應使用的前景色（由 [CalculatorKey] 透過 [DefaultTextStyle]
/// 注入）。所有 icon 統一呼叫此方法，確保顏色一致。
Color _keyForegroundColor(BuildContext context) {
  return DefaultTextStyle.of(context).style.color!;
}

/// 純文字按鍵圖標。統一所有單行文字按鍵走相同渲染路徑，確保字級與顏色一致。
///
/// 上下標一律使用 Unicode 字符（如 ² ʸ ⁻¹ ⁿ ₓ ₂），由字型自帶正確的垂直
/// 位置，避免手動拼湊 RichText 導致的定位錯誤。
class _TextIcon extends StatelessWidget {
  const _TextIcon(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text);
  }
}

/// 簡分數 `a/b` 按鍵圖標：分子 `a` 在上、橫線、分母 `b` 在下。
class _SimpleFractionIcon extends StatelessWidget {
  const _SimpleFractionIcon();

  @override
  Widget build(BuildContext context) {
    return const _FractionStack(numerator: 'a', denominator: 'b');
  }
}

/// 帶分數 `a b/c` 按鍵圖標：整數 `a` 旁接小分數 `b/c`。
class _MixedFractionIcon extends StatelessWidget {
  const _MixedFractionIcon();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('a'),
        SizedBox(width: 2),
        _FractionStack(numerator: 'b', denominator: 'c'),
      ],
    );
  }
}

/// 直排分數：分子在上、橫線、分母在下。
///
/// 以 [FittedBox] 包住，在按鍵有限高度內自動等比縮小，避免 Column 溢出。
class _FractionStack extends StatelessWidget {
  const _FractionStack({required this.numerator, required this.denominator});

  final String numerator;
  final String denominator;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(numerator, style: const TextStyle(fontSize: 11, height: 1.0)),
          _FractionBar(),
          Text(denominator, style: const TextStyle(fontSize: 11, height: 1.0)),
        ],
      ),
    );
  }
}

class _FractionBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 1.2,
      margin: const EdgeInsets.symmetric(vertical: 1),
      color: _keyForegroundColor(context),
    );
  }
}
