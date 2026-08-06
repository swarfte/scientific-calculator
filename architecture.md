# Scientific Calculator Architecture

> 本文件說明 `scientific_calculator` 專案目前 `lib/` 目錄的架構、各檔案的責任邊界、依賴方向，以及新增功能時應放置的位置。

## 1. 架構目標

本專案是一個以 Flutter 建立的本地科學計算機，第一階段支援高中常用數學功能，包括：

- 四則運算與括號
- 分數
- 指數與根號
- 對數與自然對數
- 三角函數
- DEG／RAD 角度模式
- 百分比
- 餘數運算
- 常數，例如 `pi`、`e`
- 結果格式化與計算歷史

架構的核心目標是將以下責任分開：

1. **畫面顯示與使用者輸入**
2. **應用狀態與操作協調**
3. **算式正規化與數學計算**
4. **結果與錯誤的資料模型**
5. **使用者設定持久化**

這樣可避免畫面直接依賴 `math_expressions`，亦方便日後替換計算引擎、加入精確分數、複數、矩陣或其他模式。

---

## 2. 目前目錄結構

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── theme.dart
├── controller/
│   └── calculator_controller.dart
├── engine/
│   ├── calculation_engine.dart
│   ├── calculator_exception.dart
│   ├── expression_normalizer.dart
│   ├── math_expressions_engine.dart
│   └── result_formatter.dart
├── models/
│   ├── angle_unit.dart
│   ├── calculation_record.dart
│   └── calculation_result.dart
├── settings/
│   └── settings_service.dart
├── views/
│   └── home.dart
└── widgets/
    ├── calculator_keyboard.dart
    ├── expression_input.dart
    └── result_display.dart
```

---

## 3. 建議依賴方向

依賴應保持由外向內，避免底層計算邏輯反向依賴 UI 或 GetX。

```text
main.dart
   ↓
app/
   ↓
views/ + widgets/
   ↓
controller/
   ↓
engine/ + settings/
   ↓
models/
```

更具體的資料流如下：

```text
使用者按鍵／輸入算式
        ↓
CalculatorKeyboard / ExpressionInput
        ↓
CalculatorController
        ↓
CalculationEngine
        ↓
ExpressionNormalizer
        ↓
MathExpressionsEngine
        ↓
ResultFormatter
        ↓
CalculationResult
        ↓
CalculatorController 更新狀態
        ↓
ResultDisplay / ExpressionInput 重建
```

### 依賴規則

- `views/` 和 `widgets/` 可以依賴 `controller/` 及 `models/`。
- `controller/` 可以依賴 `engine/`、`settings/` 及 `models/`。
- `engine/` 可以依賴 `models/`，但不應依賴 `views/`、`widgets/` 或 GetX。
- `settings/` 可以依賴 `models/`，但不應依賴 UI。
- `models/` 應盡量保持純 Dart，不依賴 Flutter Widget、GetX 或第三方計算引擎。

---

# 4. 各檔案責任

## `lib/main.dart`

### 主要作用

應用程式的唯一正式進入點，負責完成啟動前初始化，然後執行根 Widget。

### 應該處理

- 呼叫 `WidgetsFlutterBinding.ensureInitialized()`。
- 初始化需要在 `runApp()` 前完成的服務。
- 建立或初始化 `SettingsService`。
- 註冊最上層 Dependency，例如 GetX service 或 calculation engine。
- 呼叫 `runApp(const ScientificCalculatorApp())`。
- 設定全域錯誤處理時，可在這裏放置最外層入口設定。

### 不應處理

- 不應包含計算邏輯。
- 不應建立計算機按鍵。
- 不應包含 Theme 的詳細定義。
- 不應直接讀寫 `SharedPreferences` 的各個設定鍵。
- 不應處理每次使用者按鍵事件。

### 建議範圍

`main.dart` 應保持很短，主要是「初始化及啟動」，而不是應用程式邏輯集中地。

---

## `lib/app/app.dart`

### 主要作用

定義應用程式最上層 Widget，例如 `ScientificCalculatorApp`，負責組合 App 級別設定。

### 應該處理

- 建立 `GetMaterialApp` 或 `MaterialApp`。
- 設定應用程式名稱。
- 指定 Light Theme、Dark Theme 及 Theme Mode。
- 指定首頁 `HomePage`。
- 設定 Locale、Debug Banner、Navigation 等 App 級選項。
- 如使用 GetX Dependency Injection，可在這裏連接 initial binding。

### 不應處理

- 不應計算算式。
- 不應處理數字或運算符按鍵。
- 不應直接保存設定。
- 不應包含 Home Page 的詳細版面。
- 不應建立 `math_expressions` Parser。

### 責任邊界

`app.dart` 只決定「整個 App 如何組裝」，不決定「計算機如何計算」。

---

## `lib/app/theme.dart`

### 主要作用

集中管理整個 App 的視覺主題與 Design Tokens。

### 應該處理

- `ThemeData` 定義。
- Light／Dark Theme。
- 顏色、字體、按鍵形狀、間距及圓角等共用視覺設定。
- 計算機顯示區、數字鍵、運算鍵及功能鍵的共用樣式。
- 如有需要，可定義 `ThemeExtension` 表達計算機專用顏色。

### 不應處理

- 不應保存目前 Theme Mode。
- 不應使用 GetX Controller 執行業務操作。
- 不應處理按鍵點擊。
- 不應包含計算邏輯。

### 建議

如果檔案日後變得太大，可拆分成：

```text
app/theme/
├── app_theme.dart
├── app_colors.dart
├── app_typography.dart
└── calculator_theme_extension.dart
```

---

## `lib/controller/calculator_controller.dart`

### 主要作用

這是畫面與計算核心之間的協調層。它管理 Calculator Session 狀態，接收 UI 操作，呼叫計算引擎，再把結果公開給畫面。

### 應該處理

- 當前算式狀態。
- 當前顯示結果。
- DEG／RAD 模式。
- 上一次答案 `Ans`。
- 計算歷史。
- Loading、錯誤及可用狀態。
- Clear、Backspace、Calculate、切換角度模式等使用案例。
- 呼叫 `CalculationEngine`。
- 呼叫 `SettingsService` 載入或保存設定。
- 將成功結果加入 `CalculationRecord`。
- 將底層 Exception 轉換成 UI 可顯示的狀態。

### 不應處理

- 不應直接建立 `GrammarParser` 或 `RealEvaluator`。
- 不應包含大量 `replaceAll()` 來轉換算式。
- 不應直接使用 `SharedPreferences`。
- 不應包含 Widget、Dialog 或畫面布局。
- 不應決定浮點數顯示的詳細規則。
- 不應把第三方 Library 的型別直接公開給 UI。

### 建議公開狀態

```text
expression
result
angleUnit
history
lastAnswer
errorMessage
isCalculating
```

### 建議公開操作

```text
updateExpression(...)
appendToken(...)
backspace()
clearExpression()
clearAll()
calculate()
toggleAngleUnit()
usePreviousAnswer()
clearHistory()
```

### 負責範圍

Controller 處理的是「一次計算工作階段及 UI 狀態」，不是數學規則本身。

---

## `lib/engine/calculation_engine.dart`

### 主要作用

定義計算引擎的抽象 Contract，讓 Controller 不需要知道底層使用 `math_expressions`、自訂 AST 或其他 Library。

### 應該處理

- 定義統一的 `evaluate` 方法。
- 定義輸入、角度模式及計算選項。
- 指定回傳 `CalculationResult`。
- 保持實作可替換及可 Mock。

### 建議概念

```dart
abstract interface class CalculationEngine {
  CalculationResult evaluate(
    String expression, {
    required AngleUnit angleUnit,
    num? previousAnswer,
  });
}
```

### 不應處理

- 不應包含 UI。
- 不應保存 Calculator Session。
- 不應讀取設定檔。
- 抽象介面本身不應綁定 `math_expressions` 的 `Expression` 或 `ContextModel`。

### 負責範圍

這個檔案只描述「計算引擎能做甚麼」，實際「怎樣做」由 `math_expressions_engine.dart` 負責。

---

## `lib/engine/calculator_exception.dart`

### 主要作用

定義計算領域的可預期錯誤，避免把 `FormatException`、Parser Exception 或第三方 Library 錯誤直接顯示給使用者。

### 應該處理

建議最少區分：

- `SyntaxCalculatorException`：算式語法錯誤。
- `MathCalculatorException`：除以零、負數偶次根、無效對數等。
- `DomainCalculatorException`：輸入超出函數定義域。
- `OverflowCalculatorException`：數值過大或超出限制。
- `UnsupportedCalculatorException`：暫未支援的功能，例如複數結果。

### 不應處理

- 不應顯示 Snackbar 或 Dialog。
- 不應存取 GetX。
- 不應執行計算。
- 不應記錄畫面狀態。

### 負責範圍

只負責提供可預期、可測試及可翻譯的錯誤類型。建議錯誤型別帶有穩定的 error code，而畫面文字可在 UI 或 localization 層處理。

---

## `lib/engine/expression_normalizer.dart`

### 主要作用

將 UI／MathField 產生的算式轉換為計算引擎可理解的標準表示。

### 應該處理

- `×` 轉成 `*`。
- `÷` 轉成 `/`。
- 將 Unicode minus 正規化。
- 將 `π` 轉成 `pi`。
- 將百分比轉換為明確運算，例如 `20%` 轉為 `(20/100)`。
- 將 `mod` 轉換成引擎可處理的 Function 或 Operator。
- 將自訂底數對數轉換成換底公式。
- 視需要補上明確乘號，例如 `2π` 轉成 `2*pi`。
- 處理 DEG／RAD 函數轉換時所需的中介表示。
- 驗證不允許或暫不支援的 Token。

### 不應處理

- 不應直接更新 GetX 狀態。
- 不應決定結果顯示小數位數。
- 不應保存歷史。
- 不應顯示 Error Widget。
- 不應承擔所有語法解析；複雜括號及優先級仍應交給 Parser。

### 重要原則

不要把所有正規化都寫成無上下文的 `replaceAll()`。百分比、負號、隱式乘法及三角函數可能與上下文有關，應透過 Token 或明確規則處理，並建立單元測試。

---

## `lib/engine/math_expressions_engine.dart`

### 主要作用

`CalculationEngine` 的具體實作，使用 `math_expressions` 執行實數算式。

### 應該處理

1. 接收原始算式與角度模式。
2. 呼叫 `ExpressionNormalizer`。
3. 建立 `GrammarParser`。
4. 將正規化算式解析成 Expression。
5. 建立 `ContextModel`，綁定 `Ans` 或其他變數。
6. 使用 `RealEvaluator` 計算。
7. 檢查 `NaN`、Infinity 及定義域問題。
8. 呼叫 `ResultFormatter`。
9. 建立並回傳 `CalculationResult`。
10. 將第三方 Exception 轉換成 Calculator Exception。

### 可處理的首階段功能

- 四則運算。
- 括號及運算優先級。
- 實數指數。
- 平方根及 n 次根。
- `log`、`ln`。
- `sin`、`cos`、`tan` 與反三角函數。
- `pi`、`e`。
- 經 Normalizer 轉換後的百分比與餘數。

### 不應處理

- 不應直接更新畫面。
- 不應保存歷史。
- 不應保存 DEG／RAD 偏好。
- 不應使用 GetX。
- 不應將 `math_expressions.Expression` 公開至 Controller。
- 不應聲稱支援複數、矩陣等底層 Library 未完整支援的功能。

### 負責範圍

此檔案是第三方 Library 的 Adapter。所有對 `math_expressions` 的直接依賴應盡量集中於此，以降低日後更換計算引擎的成本。

---

## `lib/engine/result_formatter.dart`

### 主要作用

將原始數值轉換成適合計算機顯示的字串。

### 應該處理

- 移除不必要的尾隨零。
- 避免顯示 `0.30000000000000004` 一類浮點尾數。
- 將極接近零的結果正規化為 `0`。
- 在適當情況使用科學記數法。
- 控制有效位數。
- 處理 `-0`。
- 檢查 `NaN` 和 Infinity。
- 未來支援 `Fix`、`Sci`、`Norm` 顯示模式。

### 不應處理

- 不應重新計算算式。
- 不應判斷 Operator 優先級。
- 不應保存設定。
- 不應更新 Controller。
- 不應把百分比或 DEG／RAD 轉換放在這裏。

### 負責範圍

它只負責「數值怎樣顯示」，不負責「數值怎樣計算」。

---

## `lib/models/angle_unit.dart`

### 主要作用

定義三角函數的角度單位。

### 建議內容

```dart
enum AngleUnit {
  degree,
  radian,
}
```

未來如需要，可加入：

```text
gradian
```

### 應該處理

- 提供穩定的型別，避免在系統內傳遞 `'DEG'`、`'RAD'` 字串。
- 可透過 extension 提供顯示文字或持久化值。

### 不應處理

- 不應執行角度轉換。
- 不應讀取 SharedPreferences。
- 不應包含 UI Widget。

---

## `lib/models/calculation_record.dart`

### 主要作用

表示一筆已完成的計算歷史。

### 建議欄位

```text
id
originalExpression
normalizedExpression（可選，主要供除錯）
displayExpression／latexExpression
result
displayResult
angleUnit
calculatedAt
```

### 應該處理

- 以不可變資料結構保存一次計算紀錄。
- 提供必要的序列化能力，以便日後保存少量歷史。
- 支援重新使用歷史算式或結果。

### 不應處理

- 不應自己執行計算。
- 不應自行加入 History List。
- 不應讀寫 SharedPreferences。
- 不應格式化整個畫面。

### 負責範圍

一個 Record 只代表一次已經發生的計算，不代表目前編輯中的算式。

---

## `lib/models/calculation_result.dart`

### 主要作用

表示一次成功計算的正式輸出，將原始數值、顯示值及相關資訊包裝成穩定型別。

### 建議欄位

```text
rawValue
displayValue
normalizedExpression
isApproximate
exactValue（未來可選，例如精確分數）
```

### 應該處理

- 保存計算結果資料。
- 區分原始數值與顯示字串。
- 為日後精確值／近似值切換預留空間。

### 不應處理

- 不應執行 Parser。
- 不應自行格式化浮點數。
- 不應更新 GetX 狀態。
- 不應包含 Widget。

### 負責範圍

它是 Engine 與 Controller 之間的資料傳輸物件，不是計算引擎本身。

---

## `lib/settings/settings_service.dart`

### 主要作用

集中處理使用者偏好的持久化，讓 Controller 不直接依賴 `shared_preferences`。

### 應該處理

- 載入及保存 `AngleUnit`。
- 載入及保存 Theme Mode。
- 載入及保存顯示精度或顯示模式。
- 保存「是否保留歷史」等非敏感偏好。
- 集中定義 preference keys。
- 處理缺少設定時的預設值。
- 建議新程式使用 `SharedPreferencesAsync` 或 `SharedPreferencesWithCache`。

### 不應處理

- 不應執行數學計算。
- 不應處理按鍵。
- 不應顯示畫面。
- 不應保存每次輸入的暫時字元。
- 不應把整個 Controller 序列化。
- 不應用來保存關鍵或敏感資料。

### 建議 API

```text
loadAngleUnit()
saveAngleUnit(...)
loadThemeMode()
saveThemeMode(...)
loadDisplayPrecision()
saveDisplayPrecision(...)
```

---

## `lib/views/home.dart`

### 主要作用

科學計算機主畫面，負責安排高層 Layout 及組合各 Widget。

### 應該處理

- `Scaffold`。
- App Bar 或頂部狀態列。
- 組合 `ExpressionInput`。
- 組合 `ResultDisplay`。
- 組合 `CalculatorKeyboard`。
- 使用 `Obx` 或 GetX Builder 觀察 Controller 狀態。
- 因應手機、平板、桌面及橫直方向安排版面。
- 顯示 DEG／RAD、Error、History 等畫面狀態。

### 不應處理

- 不應建立 Parser 或 Evaluator。
- 不應包含數學轉換規則。
- 不應直接使用 `SharedPreferences`。
- 不應自行格式化結果。
- 不應在 `build()` 內註冊永久 Dependency。

### 負責範圍

`home.dart` 是頁面級組合器，應避免成為包含所有細節的巨大 Widget。具體顯示及鍵盤區應交給 `widgets/`。

---

## `lib/widgets/calculator_keyboard.dart`

### 主要作用

顯示計算機的輸入按鍵，並將使用者操作轉換成清晰的命令或 Callback。

### 應該處理

- 數字鍵。
- 四則運算鍵。
- 括號、根號、指數、分數鍵。
- `sin`、`cos`、`tan`、`log`、`ln`。
- 百分比及 `mod`。
- Clear、Backspace、Equals。
- 按鍵 Layout、大小、顏色及觸控回饋。
- 響應式欄數或橫向配置。
- 將點擊轉為語意化命令或 Callback。

### 建議方式

比起把按鍵 label 直接當成 Parser Token，較穩健的做法是定義命令：

```text
insertDigit
insertOperator
insertFraction
insertPower
insertRoot
insertFunction
backspace
clear
calculate
```

### 不應處理

- 不應直接執行計算。
- 不應直接呼叫 `GrammarParser`。
- 不應定義角度轉換公式。
- 不應保存歷史。
- 不應直接讀寫 Settings。

### 負責範圍

Keyboard 負責「使用者按了甚麼」，Controller／Input Editor 負責「這個操作如何改變算式」。

---

## `lib/widgets/expression_input.dart`

### 主要作用

顯示及編輯目前算式，提供自然數學格式，例如上下分數、上標指數及根號。

### 應該處理

- 數學輸入欄位。
- Cursor、Focus 及選取狀態。
- 使用 `math_keyboard` 的 `MathField`，或包裝你選擇的公式編輯器。
- 接收初始算式。
- 透過 Callback 回報輸入變化。
- 顯示分數、指數、根號及函數的自然排版。
- 處理畫面捲動，避免長算式超出顯示區。

### 不應處理

- 不應執行最終計算。
- 不應直接持有 `math_expressions` Parser。
- 不應保存 DEG／RAD。
- 不應決定結果有效位數。
- 不應直接寫入 SharedPreferences。

### 重要邊界

此 Widget 應盡量包裝第三方輸入 Library。外部只看見你自己的參數及 Callback，避免 `MathField` 的 Controller 或特定型別散落到整個 App。

---

## `lib/widgets/result_display.dart`

### 主要作用

顯示計算結果、錯誤狀態及必要的結果操作。

### 應該處理

- 顯示 `CalculationResult.displayValue`。
- 顯示 `Math ERROR`、`Syntax ERROR` 等使用者可理解訊息。
- 在有精確值與近似值時提供切換入口。
- 提供 Copy Result、Use as Ans 等操作入口。
- 支援長結果的水平捲動或自動縮放。
- 保持數字對齊及易讀性。

### 不應處理

- 不應自行重新計算。
- 不應接收原始算式後直接 Parse。
- 不應自行修剪浮點尾數。
- 不應讀寫歷史或設定。

### 負責範圍

它只顯示 Controller 已準備好的結果狀態；錯誤分類、數值計算及格式化應在其他層完成。

---

# 5. 功能放置指南

新增功能時，可依照以下準則決定位置。

## 新增 `DEG／RAD` 切換

- Enum：`models/angle_unit.dart`
- 狀態與操作：`controller/calculator_controller.dart`
- 計算方法：`engine/math_expressions_engine.dart`
- 保存偏好：`settings/settings_service.dart`
- UI 按鍵：`widgets/calculator_keyboard.dart`
- 畫面顯示：`views/home.dart`

## 新增百分比

- 按鍵：`widgets/calculator_keyboard.dart`
- 輸入呈現：`widgets/expression_input.dart`
- 語意轉換：`engine/expression_normalizer.dart`
- 計算：`engine/math_expressions_engine.dart`
- 測試：Normalizer 與 Engine 的單元測試

## 新增 `mod`

- 按鍵：`widgets/calculator_keyboard.dart`
- 正規化或自訂 Function：`engine/expression_normalizer.dart`
- 實際運算及定義域檢查：`engine/math_expressions_engine.dart`
- 除數為零錯誤：`engine/calculator_exception.dart`

## 新增精確分數結果

- 新結果模型：擴充 `models/calculation_result.dart`
- 精確運算：新增 Engine 或 Engine component
- 顯示格式：`engine/result_formatter.dart`
- 顯示切換：`widgets/result_display.dart`
- S⇔D 狀態：`controller/calculator_controller.dart`

## 新增計算歷史

- Record：`models/calculation_record.dart`
- History 狀態：`controller/calculator_controller.dart`
- History UI：建議新增 `views/history_page.dart` 或 `widgets/history_panel.dart`
- 是否持久化：由 `settings/` 或未來獨立 `history/` repository 處理

---

# 6. 不應出現的跨層耦合

以下做法應避免：

```text
home.dart 直接建立 GrammarParser
calculator_keyboard.dart 直接呼叫 evaluate()
result_display.dart 自行修剪浮點數
calculator_controller.dart 直接呼叫 SharedPreferences.getInstance()
math_expressions_engine.dart 使用 Get.snackbar()
settings_service.dart import HomePage
models/ 依賴 GetX Rx 型別
```

原因是這些做法會令 UI、狀態、計算及資料持久化互相綁定，使測試及日後替換 Library 變得困難。

---

# 7. 建議測試分佈

建議在 `test/` 建立與 `lib/` 相近的結構：

```text
test/
├── controller/
│   └── calculator_controller_test.dart
├── engine/
│   ├── expression_normalizer_test.dart
│   ├── math_expressions_engine_test.dart
│   └── result_formatter_test.dart
├── settings/
│   └── settings_service_test.dart
└── widgets/
    ├── calculator_keyboard_test.dart
    ├── expression_input_test.dart
    └── result_display_test.dart
```

## Engine 測試重點

```text
2 + 3 * 4 = 14
(2 + 3) * 4 = 20
1 / 2 = 0.5
2 ^ 10 = 1024
sqrt(16) = 4
log(100) = 2
ln(e) = 1
DEG: sin(30) = 0.5
RAD: sin(pi / 2) = 1
20% = 0.2
10 mod 3 = 1
1 / 0 = Math ERROR
sqrt(-1) = Math ERROR
```

## Formatter 測試重點

```text
0.30000000000000004 → 0.3
-0.0 → 0
極大值 → 科學記數法
極小但非零值 → 科學記數法
NaN → Math ERROR
Infinity → Math ERROR
```

## Controller 測試重點

- 成功計算時更新結果。
- 失敗時更新錯誤狀態。
- 成功後建立 History Record。
- 切換 DEG／RAD 時保存設定。
- Clear 不應留下舊錯誤。
- Engine 可用 Mock 取代，Controller 測試不應依賴真正 Parser。

---

# 8. 未來擴展建議

當功能增加後，可考慮由目前的 technical-layer 結構轉成 feature-first 結構：

```text
lib/
├── app/
├── core/
│   ├── engine/
│   └── settings/
├── features/
│   ├── calculator/
│   │   ├── controller/
│   │   ├── models/
│   │   ├── views/
│   │   └── widgets/
│   ├── history/
│   └── settings/
└── main.dart
```

目前只有一個主要功能時，現有結構已足夠，不需要立即重構。當 History、Settings、Statistics 或 Equation Solver 各自形成完整畫面及業務流程時，再轉成 feature-first 會比較合理。

---

# 9. 架構決策摘要

1. `main.dart` 只負責初始化和啟動。
2. `app/` 負責 App 級組裝及主題。
3. `views/` 負責頁面布局。
4. `widgets/` 負責可重用 UI 元件及輸入呈現。
5. `calculator_controller.dart` 負責 Calculator Session 與操作協調。
6. `calculation_engine.dart` 定義計算能力的抽象介面。
7. `math_expressions_engine.dart` 集中包裝 `math_expressions`。
8. `expression_normalizer.dart` 負責 UI 算式到引擎算式的轉換。
9. `result_formatter.dart` 只處理結果顯示格式。
10. `models/` 保持單純，不綁定 UI、GetX 或第三方計算引擎。
11. `settings_service.dart` 是持久化設定的唯一入口。
12. UI 不直接接觸 Parser；計算引擎不直接接觸 UI。

這些邊界能讓第一版快速完成高中數學功能，同時為日後加入精確分數、複數、矩陣、統計或其他計算模式保留擴展空間。
