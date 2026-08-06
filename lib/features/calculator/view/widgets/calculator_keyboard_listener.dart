import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodel/calculator_providers.dart';
import '../../viewmodel/calculator_view_model.dart';

/// 鍵盤快速輸入處理器。
///
/// 將硬體鍵盤事件轉譯成對應的 [CalculatorViewModel] 方法。設計為純粹的
/// 事件路由器：不持有狀態、不修改 Tree，全部交給 ViewModel，方便單元測試。
///
/// 支援的按鍵（與行動版 keypad 行為一致）：
///
/// - 數字 `0`-`9` -> [CalculatorViewModel.inputDigit]
/// - `.` -> [CalculatorViewModel.inputDecimalPoint]
/// - `+` / `-` / `*` / `/` -> 加減乘除
/// - `(` / `)` -> 群組
/// - `e` -> 歐拉數
/// - `p` -> π（pi）
/// - `?` -> 分數 `a/b`
/// - `=` / `Enter` -> [CalculatorViewModel.calculate]
/// - `Backspace` -> [CalculatorViewModel.backspace]
/// - `Escape` -> [CalculatorViewModel.clear]
/// - 方向鍵 -> 游標移動
class CalculatorKeyboardHandler {
  CalculatorKeyboardHandler(this.viewModel);

  final CalculatorViewModel viewModel;

  /// 處理單一鍵盤事件；回傳 `true` 表示已消耗（已對應到某個操作）。
  ///
  /// 呼叫端通常會在回傳 `true` 時呼叫 `KeyEventResult.handled`。
  bool handle(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }

    final key = event.logicalKey;
    final character = event.character;

    // 1. 字元類按鍵：以 character 為主，能正確對應 shift 後的符號。
    if (character != null && character.isNotEmpty) {
      if (_handleCharacter(character)) {
        return true;
      }
    }

    // 2. 非字元類按鍵（Enter、Backspace、方向鍵等）以 logicalKey 判斷。
    return _handleLogicalKey(key);
  }

  bool _handleCharacter(String char) {
    switch (char) {
      // 數字。
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
        viewModel.inputDigit(char);
        return true;

      // 小數點。
      case '.':
      case ',':
        viewModel.inputDecimalPoint();
        return true;

      // 四則運算。
      case '+':
        viewModel.inputAdd();
        return true;
      case '-':
        viewModel.inputSubtract();
        return true;
      case '*':
      case 'x':
      case 'X':
        viewModel.inputMultiply();
        return true;
      case '/':
        viewModel.inputDivide();
        return true;

      // 括號。
      case '(':
        viewModel.inputOpenGroup();
        return true;
      case ')':
        viewModel.inputCloseGroup();
        return true;

      // 常數。
      case 'e':
      case 'E':
        viewModel.inputEulerNumber();
        return true;
      case 'p':
      case 'P':
        viewModel.inputPi();
        return true;

      // 分數 a/b。
      case '?':
        viewModel.inputFraction();
        return true;
      // 次方。
      case '^':
        viewModel.inputPower();
        return true;

      // sin
      case 's':
      case 'S':
        viewModel.inputSin();
        return true;

      // cos
      case 'c':
      case 'C':
        viewModel.inputCos();
        return true;

      // tan
      case 't':
      case 'T':
        viewModel.inputTan();
        return true;

      // 計算。
      case '=':
        viewModel.calculate();
        return true;
    }

    return false;
  }

  bool _handleLogicalKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      viewModel.calculate();
      return true;
    }
    if (key == LogicalKeyboardKey.backspace) {
      viewModel.backspace();
      return true;
    }
    if (key == LogicalKeyboardKey.escape) {
      viewModel.clear();
      return true;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      viewModel.moveLeft();
      return true;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      viewModel.moveRight();
      return true;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      viewModel.moveUp();
      return true;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      viewModel.moveDown();
      return true;
    }

    // Numpad 數字鍵（部份平台 / 瀏覽器不會產生 character）。
    final digit = key.keyId; // 0x30..0x39 為 '0'..'9'
    if (digit >= 0x30 && digit <= 0x39) {
      viewModel.inputDigit(String.fromCharCode(digit));
      return true;
    }

    return false;
  }
}

/// 包住子 widget，在桌面 / 瀏覽器環境下攔截硬體鍵盤輸入。
///
/// 行動裝置不會有硬體鍵盤事件，因此本 widget 只在
/// [PlatformInfo.isDesktop] 或 Web 上安裝；其餘平台直接回傳 child。
class CalculatorKeyboardListener extends ConsumerStatefulWidget {
  const CalculatorKeyboardListener({
    required this.child,
    required this.enabled,
    super.key,
  });

  final Widget child;

  /// 是否啟用鍵盤輸入（呼叫端依平台判斷後傳入）。
  final bool enabled;

  @override
  ConsumerState<CalculatorKeyboardListener> createState() =>
      _CalculatorKeyboardListenerState();
}

class _CalculatorKeyboardListenerState
    extends ConsumerState<CalculatorKeyboardListener> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final viewModel = ref.read(calculatorViewModelProvider.notifier);
    final handled = CalculatorKeyboardHandler(viewModel).handle(event);
    return handled ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: widget.child,
    );
  }
}
