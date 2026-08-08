# Sci Calc 科學計算機

> 一個以 Flutter 打造、跨平台的科學計算機,核心採用**可編輯運算式樹(Editable Expression Tree)**,
> 讓你在輸入的同時就能看到自然的數學排版(分數、根號、次方),並支援精確分數/根式結果。

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%5E3.12-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-green)](#平台支援)

---

## 目錄

- [特色功能](#特色功能)
- [支援的數學運算](#支援的數學運算)
- [鍵盤快速鍵](#鍵盤快速鍵)
- [技術棧](#技術棧)
- [架構概覽](#架構概覽)
- [專案結構](#專案結構)
- [開始使用](#開始使用)
- [建置與發佈](#建置與發佈)
- [測試](#測試)
- [CI/CD](#cicd)
- [平台支援](#平台支援)
- [授權](#授權)

---

## 特色功能

- **自然數學排版** — 輸入即所見,分數、根號、次方、對數全部以教科書般的排版顯示(透過 `flutter_math_fork` 渲染 TeX)。
- **可編輯運算式樹** — 不使用字串拼湊,而是以一棵支援「不完整但合法」編輯狀態的抽象語法樹作為單一資料來源,游標可在任意巢狀結構(分數的分母的函數引數……)之間精準移動。
- **精確結果模式(FRAC)** — 切換到分數模式後,結果會以最簡分數、帶分數或簡化根式呈現(例如 `√12 → 2√3`、`33/55 → 3/5`),由基於 `BigInt` 的符號運算引擎計算;無法精確表示時自動退回小數。
- **DEG / RAD 切換** — 角度模式在編譯階段正確換算,不靠字串改寫。
- **閃爍游標** — 顯示中的游標以等寬佔位符實現,公式在閃爍時不會左右跳動。
- **跨平台** — 同一份程式碼同時支援 Android、iOS、Web、Windows、macOS、Linux。
- **桌面視窗體驗** — 視窗位置與大小自動記憶與還原(並驗證螢幕仍存在)、支援「視窗置頂」。
- **應用程式內更新** — 自動檢查 GitHub Releases 並引導安裝(Android APK、Windows 安裝程式、macOS DMG)。
- **硬體鍵盤支援** — 桌面與網頁端可直接用鍵盤輸入(數字、運算子、函數快速鍵)。
- **主題切換** — Material 3,支援系統/淺色/深色三種偏好並持久化。

## 支援的數學運算

| 類別 | 功能 |
|------|------|
| **基本運算** | `+` `−` `×` `÷`、括號分組、一元負號 |
| **分數** | 簡單分數 `a/b`、帶分數 `a b/c` |
| **次方與根號** | 平方 `x²`、次方 `xʸ`、平方根 `√`、n 次方根 `ⁿ√` |
| **三角函數** | `sin` `cos` `tan` 與反三角 `sin⁻¹` `cos⁻¹` `tan⁻¹`(DEG/RAD) |
| **對數** | 自然對數 `ln`、常用對數 `log₁₀`、二進位對數 `log₂`、任意底數 `logₓy` |
| **常數** | `π`(圓周率)、`e`(尤拉數)、`Ans`(上一次答案) |
| **科學記號** | `Exp` → `m × 10ⁿ` |
| **絕對值** | `abs` |
| **結果模式** | **DEC**(小數,預設)/ **FRAC**(精確分數與根式) |

## 鍵盤快速鍵

桌面與網頁端可使用硬體鍵盤(行動裝置僅使用螢幕按鍵):

| 按鍵 | 動作 | | 按鍵 | 動作 |
|------|------|-|------|------|
| `0`–`9` | 輸入數字 | | `s` / `c` / `t` | sin / cos / tan |
| `.` 或 `,` | 小數點 | | `^` | 次方 `xʸ` |
| `+` `-` `*` `/` | 四則運算(`x` 亦可乘) | | `?` | 分數 `a/b` |
| `(` `)` | 括號 | | `p` / `P` | π |
| `=` / `Enter` | 計算 | | `e` / `E` | 尤拉數 e |
| `Backspace` | 刪除 | |方向鍵| 移動游標 |
| `Escape` | 清除(AC) | | | |

> 鍵盤輸入僅在桌面/網頁平台啟用;數字鍵盤(numpad)透過 `keyId` 統一處理。

## 技術棧

| 領域 | 技術 |
|------|------|
| 框架 | **Flutter**(Material 3)、Dart `^3.12.2` |
| 狀態管理 | **Riverpod**(`flutter_riverpod`,`Notifier` API) |
| 數學排版 | `flutter_math_fork`(TeX 渲染) |
| 數值運算 | `math_expressions`(隔離於轉接器後方) |
| 設定持久化 | `shared_preferences`(`SharedPreferencesAsync`) |
| 桌面視窗 | `window_manager` + `screen_retriever` |
| 應用內更新 | `http` + `path_provider` + `open_filex` + `url_launcher`(GitHub Releases) |
| 版本資訊 | `package_info_plus` |
| 測試 | `flutter_test`(內建)、`flutter_lints` |

## 架構概覽

本專案採用 **MVVM + Feature-first 分層 + Riverpod**,嚴格的關注點分離:

```
main.dart → app/ → view + widgets → viewmodel → service → model
```

各層職責:

- **`model/`** — 純 Dart 資料模型(不可變、無 Flutter、無 Riverpod、無第三方數學庫)。
- **`service/`** — 純邏輯:編輯、游標導航、TeX 序列化、驗證、編譯、求值。不含任何 Flutter widget。
- **`viewmodel/`** — Riverpod `Notifier`,協調各 service;不直接修改運算式樹。
- **`view/`** — 僅含 Flutter widget;呼叫 viewmodel 方法、渲染 TeX。

### 可編輯運算式樹(核心設計)

傳統計算機以字串拼湊運算式,本專案則以一棵**支援不完整編輯狀態**的抽象語法樹作為單一資料來源(`TreeExpressionDocument`,包含 `root` 與 `cursor`)。狀態中不存放任何求值字串或 TeX 字串——兩者皆在需要時衍生。

**為什麼重要:**

- **游標穩定性** — 每個節點擁有穩定 ID,`copyWith` 保留 ID;`TreeRewriter` 沿父鏈不可變地重建整棵樹,讓深層編輯(例如分數分母內的函數引數)能正確傳播回根,同時游標位置不漂移。
- **兩套平行 Pratt 剖析器** — `ExpressionCompiler`(→ `math_expressions`,`double`)與 `ExactValueEvaluator`(→ `ExactNumber`,`BigInt` 精確)共用相同文法與優先序,差別僅在數值域。
- **第三方程式庫隔離** — `math_expressions` 被封裝在轉接器後方,UI 從不直接接觸剖析器型別,未來可整替換。
- **驗證不拋例外** — `ExpressionValidator` 回傳第一個 `ValidationFailure`(含位置資訊),保留未來錯誤高亮的能力。
- **精確數以「根式和」表示** — `ExactNumber` 能以 `BigInt` 精確表示 `2 + 3√5 + (1/2)√7` 這類值。

完整的設計細節(節點模型、游標慣例、導航規則、序列化規則、13 個編輯方法與 8 條退格規則)記錄於 [`EXPRESSION_TREE_REFACTOR_PLAN.md`](EXPRESSION_TREE_REFACTOR_PLAN.md)。

### 計算管線

```
運算式樹 → ExpressionValidator → ExpressionCompiler(Pratt)
         → TreeExpressionEvaluator → ResultFormatter → CalculationResult
                                    ↘ (FRAC 模式) ExactValueEvaluator → ExactValueFormatter
```

## 專案結構

```
lib/
├── main.dart                          # 入口(呼叫 bootstrap)
├── app/
│   ├── app.dart                       # MaterialApp 根 widget
│   ├── bootstrap.dart                 # 啟動:視窗、偏好、主題
│   ├── theme.dart                     # Material 3 主題(淺/深)
│   └── *_settings.dart                # 各項偏好設定與持久化
├── core/
│   ├── errors/                        # CalculatorException + 錯誤類型
│   ├── math/                          # AngleMode、結果格式化
│   └── platform/                      # Web 安全的平台偵測、視窗服務
└── features/
    ├── calculator/
    │   ├── model/expression/          # ★ 運算式樹資料模型
    │   │   ├── tree_expression_document.dart   # {root, cursor} 單一來源
    │   │   ├── node/                           # 各種節點型別
    │   │   ├── cursor_position.dart            # gap 模式 / 文字模式
    │   │   └── tree_index.dart                 # DFS 查詢索引
    │   ├── service/
    │   │   ├── tree_expression_editor.dart     # 按鍵編輯(13+ 方法)
    │   │   ├── tree_rewriter.dart              # 不可變樹狀變更
    │   │   ├── expression_navigator.dart       # 游標移動(L/R/U/D)
    │   │   ├── tree_expression_tex_serializer.dart  # 樹 → TeX + 閃爍游標
    │   │   ├── expression_validator.dart       # 結構驗證
    │   │   ├── expression_compiler.dart        # Pratt → math_expressions
    │   │   ├── tree_expression_evaluator.dart  # math_expressions → double
    │   │   ├── tree_calculator_engine.dart     # 管線指揮
    │   │   └── exact_math/                     # BigInt 精確運算
    │   ├── view/
    │   │   ├── calculator_screen.dart          # 主畫面組合
    │   │   └── widgets/                        # 鍵盤、顯示、設定對話框…
    │   └── viewmodel/                          # Riverpod Notifier + providers
    └── update/                                 # 應用程式內更新功能
```

## 開始使用

### 環境需求

- [Flutter](https://docs.flutter.dev/get-started/install) stable channel(建議 ≥ 3.x)
- Dart SDK `^3.12.2`
- 各平台額外工具:
  - **Android**:Android Studio + JDK 17
  - **iOS/macOS**:Xcode(macOS 主機)
  - **Windows**:Visual Studio 含 C++ 桌面開發工具
  - **Linux**:clang、cmake、ninja、GTK 開發標頭
  - **Web**:無額外需求

### 安裝與執行

```bash
# 1. 複製專案
git clone https://github.com/swarfte/sci-calc.git
cd sci-calc

# 2. 安裝依賴
flutter pub get

# 3. 執行(指定平台)
flutter run -d chrome       # Web
flutter run -d windows      # Windows
flutter run -d macos        # macOS
flutter run -d <device-id>  # Android / iOS
```

### 程式碼品質

```bash
flutter analyze             # 靜態分析(flutter_lints)
dart format lib test        # 格式化
```

## 建置與發佈

```bash
# Release 建置
flutter build apk --release        # Android
flutter build appbundle --release  # Android App Bundle
flutter build web --release        # Web
flutter build windows --release    # Windows
flutter build macos --release      # macOS
flutter build linux --release      # Linux
```

可透過 `--build-name` / `--build-number` 覆寫版本號。

應用程式圖示由 `flutter_launcher_icons` 從 `assets/icons/calculator.png` 自動產生至各平台;
顯示名稱「Sci Calc」由 `rename_app` 設定(見 `pubspec.yaml` 的 `config_name`)。

## 測試

本專案有完整的單元與 widget 測試(21 個測試檔,涵蓋運算式樹編輯、游標導航、精確運算、編譯/求值引擎、序列化、ViewModel、更新控制器等):

```bash
flutter test               # 執行全部測試
flutter test --coverage    # 產生覆蓋率報告
```

> **測試小提醒:** `NaturalMathDisplay` 含無限循環的游標閃爍動畫,相關 widget 測試必須使用 `pump()` 而非 `pumpAndSettle()`(後者會逾時)。

## CI/CD

[`.github/workflows/build-release.yml`](.github/workflows/build-release.yml) 在推送至 `main` 或手動觸發時執行:

1. 產生日期版本號 `YYYY.M.D`(澳門時區)。
2. 對每個平台執行 `flutter analyze` → `flutter test` → release 建置。
3. 產出三個產物:
   - **Android** — 簽署 APK(以 GitHub Secrets 還原 keystore,並用 `apksigner` 驗證簽章指紋)。
   - **Windows** — Inno Setup 安裝程式(`windows/installer.iss`)。
   - **macOS** — Apple Silicon(arm64)DMG。
4. 建立含三個產物的 GitHub Release,並標記為 `latest`。

應用程式內更新功能會檢查同一個 GitHub 儲存庫(`swarfte/sci-calc`)的最新 Release。

## 平台支援

| 平台 | 狀態 | 備註 |
|------|------|------|
| Android | ✅ 完整支援 | 應用內更新下載 APK 並觸發系統安裝程式 |
| iOS | ✅ 可建置 | (需自行簽署與發佈) |
| Web | ✅ 完整支援 | 鍵盤輸入已啟用 |
| Windows | ✅ 完整支援 | 視窗狀態記憶、置頂、應用內更新 |
| macOS | ✅ 完整支援 | Apple Silicon arm64;視窗狀態記憶、置頂 |
| Linux | ✅ 可建置 | 桌面視窗功能適用 |

桌面端最小視窗尺寸為 `400 × 700`。

## 授權

本專案以 [Apache License 2.0](LICENSE) 授權。
