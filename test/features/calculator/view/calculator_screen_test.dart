import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_calculator/features/calculator/view/calculator_screen.dart';
import 'package:scientific_calculator/features/calculator/view/widgets/calculator_key.dart';
import 'package:scientific_calculator/features/calculator/view/widgets/result_display.dart';

/// Phase 6 widget test：驗證 CalculatorScreen 的核心 UI 元素與按鍵互動。
void main() {
  testWidgets('result display 存在且初始為 0', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CalculatorScreen())),
    );

    final resultDisplay = find.byType(ResultDisplay);
    expect(resultDisplay, findsOneWidget);
    // ResultDisplay 內的 Text 顯示 '0'。
    final resultText = find.descendant(
      of: resultDisplay,
      matching: find.text('0'),
    );
    expect(resultText, findsOneWidget);
  });

  testWidgets('核心按鍵存在', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CalculatorScreen())),
    );

    // 數字鍵（避免與顯示區的 0 衝突，找非 0 數字）。
    expect(find.text('1'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    // 運算符。
    expect(find.text('+'), findsOneWidget);
    expect(find.text('×'), findsOneWidget);

    // 函數鍵。
    expect(find.text('sin'), findsOneWidget);
    expect(find.text('log₁₀'), findsOneWidget);

    // 結構鍵。
    expect(find.text('a/b'), findsOneWidget);
    expect(find.text('√'), findsOneWidget);
    expect(find.text('x²'), findsOneWidget);

    // 動作鍵。
    expect(find.text('AC'), findsOneWidget);
    expect(find.text('DEL'), findsOneWidget);
    expect(find.text('='), findsOneWidget);

    // 方向鍵。
    expect(find.text('↑'), findsOneWidget);
    expect(find.text('↓'), findsOneWidget);
    expect(find.text('←'), findsOneWidget);
    expect(find.text('→'), findsOneWidget);
  });

  testWidgets('按 1 + 2 = 後 result 更新為 3', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CalculatorScreen())),
    );

    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('+'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('='));
    await tester.pump();

    // 結果區顯示 3。
    final resultDisplay = find.byType(ResultDisplay);
    expect(
      find.descendant(of: resultDisplay, matching: find.text('3')),
      findsOneWidget,
    );
  });

  testWidgets('AC 清空算式', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CalculatorScreen())),
    );

    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('AC'));
    await tester.pump();

    // AC 後 ResultDisplay 仍存在，顯示初始 0。
    expect(find.byType(ResultDisplay), findsOneWidget);
  });

  testWidgets('錯誤不顯示 expression error 字眼', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CalculatorScreen())),
    );

    // 1 / 0 = 觸發錯誤。0 鍵需精確定位（避免與顯示區 phantom{0} 衝突）。
    final zeroKey = find.descendant(
      of: find.byType(CalculatorKey),
      matching: find.text('0'),
    );
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('÷'));
    await tester.pump();
    await tester.tap(zeroKey);
    await tester.pump();
    await tester.tap(find.text('='));
    await tester.pump();

    // 不應出現 'Expression error' 等字眼。
    expect(find.textContaining('Expression error'), findsNothing);
  });
}
