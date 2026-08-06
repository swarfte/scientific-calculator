# Scientific Calculator Expression Tree 重構計劃

> 專案：`scientific_calculator`  
> 架構：Flutter + Riverpod + MVVM + Editable Expression Tree  
> 文件狀態：Phase 1～Phase 6 全部完成，重構已收尾  
> 最後更新：2026-08-06

---

## 1. 文件目的

本文件定義科學計數器由「雙字串與字串游標」模型遷移至 **Editable Expression Tree** 的完整六階段計劃。

目前舊版輸入模型同時維護以下資料：

```text
evaluationExpression
texExpression
evaluationCursorOffset
texCursorOffset
openParentheses
FractionDraft
```

這種設計在只處理簡單四則運算時尚可運作，但加入函數、根式、指數、分數及方向鍵後，會產生多個結構性問題：

- evaluation string 與 TeX string 長度不同，游標位置很難同步。
- `sin(30)`、`log(100)` 等函數的 argument 和外層位置無法可靠導航。
- 分數需要特殊的 `FractionDraft` 模式，容易重複提交或錯誤插入乘號。
- 根式及指數尚未真正擁有可編輯的內部區域。
- Backspace 不知道應刪除字元、函數、分數，還是移除整個節點。
- 未完成算式需要靠補括號、補 TeX braces 等方式維持預覽。
- 後續加入微積分、矩陣、方程及複數時，字串模型會迅速失控。

重構後，每條算式只保存一份結構化資料：

```text
TreeExpressionDocument
├── root: SequenceNode
└── cursor: CursorPosition
```

顯示、驗證及計算均由同一棵 Tree 推導：

```text
Editable Expression Tree
├── ExpressionTexSerializer  -> TeX -> flutter_math_fork
├── ExpressionValidator      -> validation result
└── ExpressionCompiler       -> executable expression -> evaluator
```

---

## 2. 最終設計原則

### 2.1 單一資料來源

Expression Tree 是算式的唯一 source of truth。最終版本不得再把 evaluation string、TeX string 或 TeX offset 保存於 State。

### 2.2 可編輯 Tree，而不是只處理完整 AST

一般 AST 通常只接受完整算式，例如：

```text
2 + 3
```

計算器必須容許以下暫時不完整但合法的編輯狀態：

```text
2 +
sin( )
□ / □
5 ^
```

因此 editable model 以 `SequenceNode` 表示水平輸入內容，容許 sequence 暫時以 operator 結尾或包含空的 child sequence。

### 2.3 游標定位於數學結構

游標不再保存 evaluation/TeX 字元 offset，而是保存：

- 所屬 `SequenceNode` 的 `NodeId`
- 位於哪一個 child 前方
- 若位於 `NumberNode` 內，保存文字 offset

### 2.4 編輯、導航、顯示、驗證及計算分離

```text
ExpressionEditor
負責插入、取代、刪除與重組節點

ExpressionNavigator
負責左、右、上、下及進出 child sequence

ExpressionTexSerializer
只負責 Tree -> TeX

ExpressionValidator
只負責判斷 Tree 是否可計算

ExpressionCompiler
只負責 Tree -> 可執行數學表示

CalculatorEngine
協調 validation、compilation、evaluation 及 result formatting
```

### 2.5 每個階段保持可驗收

每個 Phase 完成後至少執行：

```powershell
dart format lib test
flutter analyze
flutter test
```

除最終切換階段外，應盡量讓舊版和新版並行，避免一次修改整個專案後無法定位錯誤。

---

## 3. 六階段總覽

```text
Phase 1  Expression Tree Model
Phase 2  Tree Index 與結構化導航
Phase 3  Tree TeX Serializer 與游標顯示
Phase 4  Tree Expression Editor
Phase 5  Validator、Compiler、Evaluator 與 Engine
Phase 6  Riverpod MVVM、UI 接駁及移除舊架構
```

目前進度：

```text
[x] Phase 1：Expression Tree Model
[x] Phase 2：Tree Index 與結構化導航
[x] Phase 3：Tree TeX Serializer 與游標顯示
[x] Phase 4：Tree Expression Editor
[x] Phase 5：Validator、Compiler、Evaluator 與 Engine
[x] Phase 6：Riverpod MVVM、UI 接駁及移除舊架構
```

---

# Phase 1：Expression Tree Model

## 狀態

**已完成。**

目前已建立或調整以下結構：

```text
lib/features/calculator/model/expression/
├── cursor_position.dart
├── expression_document.dart
├── expression_node.dart
├── node_id.dart
└── node/
    ├── binary_node.dart
    ├── constant_node.dart
    ├── fraction_node.dart
    ├── function_node.dart
    ├── group_node.dart
    ├── number_node.dart
    ├── operator_node.dart
    ├── power_node.dart
    ├── root_node.dart
    └── sequence_node.dart
```

## 目標

建立不依賴 Flutter Widget、不依賴 Riverpod、不依賴 TeX，也不依賴 `math_expressions` 的純 Dart 數學資料模型。

## 已完成內容

### `node_id.dart`

為每個節點提供穩定 ID。游標和 Tree 查找以 `NodeId` 定位節點，不依賴容易因插入、刪除而改變的 List index。

要求：

- 同一 App session 內產生唯一 ID。
- 實作 equality 與 `hashCode`。
- 複製 Node 時預設保留原 ID。
- 建立新 Node 時產生新 ID。

### `expression_node.dart`

所有數學節點的抽象基礎類別，只保存共同的 `NodeId`。

不應在基礎類別內加入 TeX、evaluation 或 Widget 方法，避免 Model 依賴輸出格式。

### `sequence_node.dart`

表示一段水平數學內容，是 editable tree 的核心 container。

例如：

```text
2 + sin(30)
```

可以表示為：

```text
SequenceNode
├── NumberNode("2")
├── OperatorNode.add
└── FunctionNode.sin
    └── argument: SequenceNode
        └── NumberNode("30")
```

`SequenceNode` 必須容許：

- 空 children
- operator 位於末端
- 函數 argument 暫時為空
- immutable insert、replace、remove

### `number_node.dart`

以 `String` 保存正在輸入的數字，而不是立即轉成 `double`。

這使以下狀態可以保留：

```text
3.
0.
0.00
```

### `operator_node.dart`

表示 editable sequence 中的四則運算符。輸入階段不強制建立完整 `BinaryNode`，因為 `2 +` 是合法編輯狀態。

MVP operator：

```text
add
subtract
multiply
divide
```

### `constant_node.dart`

表示：

```text
π
e
Ans
```

常數不是普通字串，也不是 `NumberNode`。

### `function_node.dart`

表示函數及其 argument sequence：

```text
sin
cos
tan
asin
acos
atan
log10
ln
absolute
```

按下函數鍵後建立一個 `FunctionNode`，游標進入 `argument`，不再插入 `"sin("` 字串。

### `fraction_node.dart`

分子和分母均為 `SequenceNode`，因此可以自然保存：

```text
sqrt(2) / sqrt(3)
```

以及後續的巢狀分數。

它最終會完全取代 `FractionDraft`。

### `root_node.dart`

保存 radicand，並可選擇保存 degree：

```text
sqrt(2)
cuberoot(8)
nth-root(x)
```

### `power_node.dart`

底數及指數均為 `SequenceNode`，使指數內可包含分數、根式及函數。

### `group_node.dart`

表示明確括號及其 content sequence。括號結構不再依賴 `openParentheses` 計數器。

### `cursor_position.dart`

Tree cursor 保存：

```text
sequenceId
nodeOffset
textOffset
```

`nodeOffset` 表示游標位於 Sequence children 的哪個位置，`textOffset` 僅在 NumberNode 內使用。

### `binary_node.dart`

暫時保留，但不作為 primary editable node。它可在編譯階段用作規範化 AST，或在確認不需要後刪除。

## Phase 1 不包含

- Tree 查找
- parent relationship
- 游標導航
- TeX 產生
- 插入及刪除
- Tree validation
- Tree evaluation
- ViewModel 接駁

## Phase 1 驗收條件

- 所有 Node 可獨立建立。
- 所有 copy operation 維持 immutable semantics。
- `SequenceNode` 可插入、替換及刪除 child。
- 能在測試中手動建立：
  - `2 + 3`
  - `sin(30)`
  - `sqrt(2) / sqrt(3)`
  - `5^(3/2)`
- `flutter analyze` 不因 Tree Model 產生錯誤。

---

# Phase 2：Tree Index 與結構化導航

## 狀態

**已完成。**

已建立以下結構（UI-free 平行層，未修改任何 production code）：

```text
lib/features/calculator/model/expression/
├── sequence_role.dart
├── tree_expression_document.dart
└── tree_index.dart
lib/features/calculator/service/
└── expression_navigator.dart
test/features/calculator/
├── model/expression/tree_index_test.dart
└── service/expression_navigator_test.dart
```

### Cursor 慣例（已明確化）

`CursorPosition` 有兩種模式：

- **Gap mode**（`textOffset == null`）：`nodeOffset ∈ [0, len]` 表示游標位於
  `sequence.children[nodeOffset]` 前方的間隙。`0` = sequence 開頭，`len` = 結尾。
- **Text mode**（`textOffset != null`）：游標位於 NumberNode
  `sequence.children[nodeOffset]` 內，字元位置 `textOffset ∈ [0, value.length]`。

並為 `CursorPosition` 補上 `==` / `hashCode`（Phase 1 測試矩陣所列項目）。

### Leaf node 橫向跨越規則

- NumberNode 兩側都會進入文字（向右進 offset 0、向左進末端）。
- Operator / Constant 等無文字 leaf 直接跨越（向右至後方間隙、向左至前方間隙）。
- 同一 owner 的 child sequence 形成水平鏈：numerator 末端向右進入 denominator
  開頭，反之亦然；只有鏈的邊緣才會離開 owner（function argument / group
  content 為單一 child，因此邊緣即離開）。

## 目標

建立可查找任意 Sequence、可識別 parent/owner relationship，以及可在 Tree 中進行左、右、上、下移動的導航層。

此 Phase 只移動 Cursor，不修改 Tree 內容。

## 建議檔案

```text
lib/features/calculator/model/expression/tree_expression_document.dart
lib/features/calculator/model/expression/tree_index.dart
lib/features/calculator/model/expression/sequence_role.dart
lib/features/calculator/service/expression_navigator.dart
```

如果希望減少過渡檔案，也可待 Phase 6 再把 `TreeExpressionDocument` 改名為正式 `ExpressionDocument`。

## `tree_expression_document.dart`

保存：

```text
root: SequenceNode
cursor: CursorPosition
```

不保存任何 derived string。

## `tree_index.dart`

建議建立一次 traversal index，避免 Navigator、Editor、Serializer 各自反覆遞迴找節點。

Index 最少提供：

```text
findSequence(sequenceId)
findNode(nodeId)
findParentOfSequence(sequenceId)
findParentOfNode(nodeId)
```

Parent relationship 建議包含：

```text
parentSequence
ownerNode
ownerIndex
sequenceRole
```

`sequenceRole` 用來分辨 child sequence 的語義：

```text
functionArgument
groupContent
fractionNumerator
fractionDenominator
rootRadicand
rootDegree
powerBase
powerExponent
```

## `expression_navigator.dart`

### 向左

優先順序：

1. 若在 NumberNode 內且 `textOffset > 0`，向左一個字元。
2. 若在 NumberNode 開頭，離開數字至 Node 前方。
3. 若左方 Node 是 NumberNode，進入其文字末端。
4. 若左方 Node 是 FunctionNode，進入 argument 末端。
5. 若左方 Node 是 FractionNode，預設進入 denominator 末端。
6. 若左方 Node 是 RootNode，進入 radicand 末端。
7. 若左方 Node 是 PowerNode，進入 exponent 末端。
8. 若已到 child sequence 開頭，離開 owner node 至 parent sequence 前方。

### 向右

與向左對稱：

1. NumberNode 文字內向右。
2. NumberNode 末端離開至 Node 後方。
3. 進入右方複合 Node 的第一個可編輯 child。
4. 到 child sequence 末端時離開 owner node。

### 向上

MVP 行為：

- Fraction denominator -> numerator
- Power base -> exponent
- Root radicand -> degree，如果 degree 存在
- 其他位置保持不動

### 向下

MVP 行為：

- Fraction numerator -> denominator
- Power exponent -> base
- Root degree -> radicand
- 其他位置保持不動

### 水平位置保持

上下移動時，應盡可能保留原本的 `nodeOffset` 和 `textOffset`，並 clamp 到目標 Sequence 的合法範圍。

## Phase 2 過渡策略

如果舊 App 仍引用 `fraction_draft.dart`，不要在此階段刪除。可以暫時恢復相容檔，使舊版保持可編譯，直到 Phase 6 完成正式切換。

## Phase 2 測試

最少建立：

```text
test/features/calculator/service/expression_navigator_test.dart
```

案例：

- 在 `123` 內由 `1|23` 移到 `12|3`。
- `sin(30|)` 向右後變成 `sin(30)|`。
- `sin(|30)` 向左後移到 FunctionNode 前。
- 分子末端向右進入分母開頭。
- 分母開頭向左進入分子末端。
- 分子向下保持大致水平位置。
- 分母向上保持大致水平位置。
- 指數和底數之間移動。
- 在 root 開頭/末端繼續移動不應 throw。
- 遇到無效 CursorPosition 時安全返回原 document，或回復至 root end。

## Phase 2 驗收條件

- Navigator 不使用 TeX string。
- Navigator 不使用 evaluation string。
- `sin()` 及 `log10()` argument 可正確進出。
- Fraction、Power、Root child sequence 可正確導航。
- Navigator 不修改 Tree。
- 所有 navigation unit tests 通過。

---

# Phase 3：Tree TeX Serializer 與游標顯示

## 狀態

**已完成。**

已建立以下結構（UI-free 平行層，未修改任何 production code，舊
`expression_tex_serializer.dart` 仍保留至 Phase 6）：

```text
lib/features/calculator/model/expression/
└── tex_serialization_result.dart
lib/features/calculator/service/
└── tree_expression_tex_serializer.dart
test/features/calculator/service/
└── tree_expression_tex_serializer_test.dart
```

### 實作重點

- `TreeExpressionTexSerializer.serialize(document, {cursorVisible})` 回傳
  `TexSerializationResult`，包含 `withVisibleCursor` 與 `withHiddenCursor`
  兩個等寬 TeX 字串，供 `NaturalMathDisplay` 閃爍動畫切換。
- 游標 marker 採單一 placeholder（private-use char）寫入，最後一次替換成
  visible（`\vert`）/ hidden（`\phantom{\vert}`），確保兩版本結構完全一致、
  閃爍時不左右位移。
- 空 sequence：非 active 用 `\phantom{0}`；active 用 cursor marker +
  `\phantom{0}`。
- `cursorVisible=false`（例如已按 `=`）時，兩版本都用 hidden marker，游標
  完全不顯示。

## 目標

直接遍歷 Expression Tree 產生 TeX，並根據 `CursorPosition` 在正確數學位置插入閃爍游標。

此階段完成後，不再需要 `texExpression` 或 `texCursorOffset`。

## 建議檔案

```text
lib/features/calculator/service/tree_expression_tex_serializer.dart
lib/features/calculator/model/expression/tex_serialization_result.dart
```

待 Phase 6 切換後，將 Tree serializer 取代舊 `expression_tex_serializer.dart`。

## Serializer 規則

### SequenceNode

依序 serialize children，並在與 cursor 相符的 node boundary 或 NumberNode text position 插入 cursor marker。

### NumberNode

將數值文字直接輸出。若 cursor 位於 NumberNode 內：

```text
value = 123
textOffset = 1
```

輸出：

```tex
1\vert23
```

### OperatorNode

```text
add       -> +
subtract  -> -
multiply  -> \times
divide    -> \div
```

注意：將來如果 `/` 按鍵改為建立 FractionNode，`divide` 仍可保留給線性除法。

### ConstantNode

```text
pi      -> \pi
e       -> e
answer  -> \operatorname{Ans}
```

### FunctionNode

```text
sin    -> \sin\left(argument\right)
cos    -> \cos\left(argument\right)
tan    -> \tan\left(argument\right)
asin   -> \sin^{-1}\left(argument\right)
log10  -> \log_{10}\left(argument\right)
ln     -> \ln\left(argument\right)
abs    -> \left|argument\right|
```

游標在 argument sequence 中時自然出現在括號內，不需要補字串 offset。

### FractionNode

```tex
\frac{numerator}{denominator}
```

空且非 active 的 sequence 使用：

```tex
\phantom{0}
```

空且 active 的 sequence使用 cursor 加 phantom width。

### RootNode

平方根：

```tex
\sqrt{radicand}
```

n 次根：

```tex
\sqrt[degree]{radicand}
```

### PowerNode

```tex
{base}^{exponent}
```

### GroupNode

```tex
\left(content\right)
```

## 穩定閃爍游標

需要產生兩個等寬 TeX 版本：

```text
visible cursor: \vert
hidden cursor:  \phantom{\vert}
```

必須確保 visible/hidden 版本寬度一致，以免公式閃爍時左右移動。

建議 API：

```text
serialize(document, cursorVisible: true)
serialize(document, cursorVisible: false)
```

## Renderer error 規則

- TeX renderer error 不能成為 calculator evaluation error。
- `NaturalMathDisplay` 的 fallback 只顯示安全文字或空白，不在輸入欄顯示 `Expression error`。
- 真正算式錯誤只允許在使用者按下 `=` 後由 ResultDisplay 顯示。

## Phase 3 測試

建立：

```text
test/features/calculator/service/tree_expression_tex_serializer_test.dart
```

至少驗證：

```text
2 + 3              -> 2+3
sin(30)            -> \sin\left(30\right)
log10(100)         -> \log_{10}\left(100\right)
sqrt(2)            -> \sqrt{2}
sqrt(2)/sqrt(3)    -> \frac{\sqrt{2}}{\sqrt{3}}
5^(3/2)            -> {5}^{\frac{3}{2}}
```

另測試游標：

- `sin(30|)` 與 `sin(30)|` 輸出不同且位置正確。
- 分子游標只出現在 numerator。
- 分母游標只出現在 denominator。
- visible 和 hidden cursor 版本均包含等寬占位。

## Phase 3 驗收條件

- Serializer 不讀取舊 `texExpression`。
- Serializer 不維護 TeX offset。
- 所有現有 MVP node 都能產生合法 TeX。
- 空 sequence 可安全顯示。
- 游標位置正確且閃爍不改變 layout width。

---

# Phase 4：Tree Expression Editor

## 狀態

**已完成。**

已建立以下結構（UI-free 平行層，未修改任何 production code，舊
`expression_editor.dart` 仍保留至 Phase 6）：

```text
lib/features/calculator/model/expression/
└── edit_result.dart
lib/features/calculator/service/
├── tree_rewriter.dart
└── tree_expression_editor.dart
test/features/calculator/service/
└── tree_expression_editor_test.dart
```

### 實作重點

- `TreeRewriter` 提供三個 immutable 基本操作：`replaceSequence` /
  `replaceNode` / `removeNode`，沿 parent path 向上重建（透過
  `TreeIndex.findParentOfSequence` 取得 owner chain）。由於每個 composite
  node 的 `copyWith` 保留 ID（Phase 1 invariant），深層修改後其他 node ID
  不變。
- `TreeExpressionEditor` 提供 13 個方法（`insertDigit` /
  `insertDecimalPoint` / `insertOperator` / `insertConstant` /
  `insertFunction` / `insertFraction` / `insertSquareRoot` /
  `insertNthRoot` / `insertPower` / `insertSquare` / `insertGroup` /
  `backspace` / `clear`），每個 input/output 為 immutable
  `TreeExpressionDocument`，方法直接回傳 document。
- `EditResult` 為 Phase 6 ViewModel 提示用途預留（editor 內部目前直接回傳
  document）。
- Backspace 實作計劃的 8 條優先規則，含深層 unwrap（空 exponent 解除
  PowerNode 保留 base、空 function/root/fraction 的降級或移除）。

### 已知設計細節

- 編輯深層 sequence 時，操作目標是 cursor 所在 sequence（`_commit` 以
  `cursor.sequenceId` 為 target）；但 backspace 處理 owner 時操作的是
  parent sequence，需直接呼叫 rewriter 而非 `_commit`（已在
  `_unwrapPowerKeepBase` / `_removeOwnerAndCommit` 處理）。
- 連續 operator 規則：`*` / `/` 後接 `-` 例外保留（允許 `3*-2`），其餘連續
  operator 替換前一個。

## 目標

重寫輸入編輯器，使所有按鍵操作直接修改 Expression Tree，並返回新的 immutable `TreeExpressionDocument`。

## 建議檔案

```text
lib/features/calculator/service/tree_expression_editor.dart
lib/features/calculator/service/tree_rewriter.dart
lib/features/calculator/model/expression/edit_result.dart
```

待 Phase 6 切換後，由 Tree Editor 取代舊 `expression_editor.dart`。

## 主要 API

```text
insertDigit
insertDecimalPoint
insertOperator
insertConstant
insertFunction
insertFraction
insertSquareRoot
insertNthRoot
insertPower
insertSquare
insertGroup
backspace
clear
```

## Immutable Tree 更新問題

游標可能位於深層 Sequence：

```text
root
└── FractionNode
    └── denominator
        └── FunctionNode
            └── argument
```

修改 argument 時，不能只修改找到的 Sequence。必須沿 parent path 向上重建：

```text
argument
-> FunctionNode.copyWith(argument: updated)
-> denominator.copyWith(children: ...)
-> FractionNode.copyWith(denominator: updated)
-> root.copyWith(children: ...)
```

因此建議建立 `TreeRewriter`：

```text
replaceSequence(root, sequenceId, replacement)
replaceNode(root, nodeId, replacement)
removeNode(root, nodeId)
```

## 數字輸入

### 游標位於 NumberNode 內

在 `textOffset` 插入數字：

```text
12|3 + input 9 -> 129|3
```

保留 NumberNode ID，只更新 value。

### 游標位於 nodes 之間

- 如果左邊是 NumberNode，可在其末端追加並進入 NumberNode。
- 如果右邊是 NumberNode，可在其開始插入。
- 否則建立新的 NumberNode。

## 小數點

- 同一 NumberNode 最多一個小數點。
- 空位置按 `.` 建立 `0.`。
- 不自動把其他 NumberNode 的小數點視為衝突。

## 運算符

MVP 規則：

- 空 root 最初只允許 unary subtract。
- 連續 operator 應替換前一個 operator，特殊情況允許乘號後的負號。
- operator 插入後，Cursor 位於 operator 後方。
- validator 最終決定算式是否完整。

## 函數

按下 `sin`：

1. 在 current sequence 插入 FunctionNode。
2. FunctionNode 建立空 argument SequenceNode。
3. Cursor 進入 argument 開頭。

離開函數由 Navigator 處理，不需要插入右括號字元。

## 分數

不再使用 `FractionDraft` 或 `OK`。

建議行為：

### 空位置按 `a/b`

建立空 FractionNode，游標進入 numerator。

### NumberNode 或可選取左側 expression 後按 `a/b`

MVP 可先只提升「游標左側緊鄰的一個 Node」為 numerator。例如：

```text
33| + a/b
```

若 `33` 是單一 NumberNode：

```text
FractionNode
├── numerator: 33
└── denominator: empty
```

游標進入 denominator。

後續版本再支援把整個左側 sequence 或選取範圍提升為 numerator。

## 根號

建立 RootNode，游標進入 radicand。

如果希望 Casio-style 行為，可讓左側完整 Node 被包入 root，但 MVP 先使用空 root slot 較簡單。

## 指數

按 `x^y` 時，建議提升游標左側 Node 成為 PowerNode.base，建立空 exponent，游標進入 exponent。

例如：

```text
5| + x^y
```

變成：

```text
PowerNode
├── base: 5
└── exponent: empty with cursor
```

按 `x^2` 則直接建立 exponent `2`，游標移到 PowerNode 後方。

## Backspace

Backspace 是本階段最重要的行為之一。

優先規則：

1. NumberNode 內且左方有字元，刪除一個字元。
2. NumberNode 變空後移除 NumberNode。
3. 位於 Node 後方時，若前一 Node 是簡單 Node，移除該 Node。
4. 位於空 child sequence 開頭時，離開並 unwrap 或移除 owner node。
5. 在 Fraction denominator 空白開頭按 DEL，可返回 numerator 或將 FractionNode 降級。
6. 在 Function argument 空白開頭按 DEL，移除 FunctionNode 並回到 parent。
7. 在 Root radicand 空白開頭按 DEL，移除 RootNode。
8. 在 exponent 空白開頭按 DEL，解除 PowerNode 並保留 base。

Backspace 必須有大量 unit tests，不能只依靠手動測試。

## Phase 4 測試

建立：

```text
test/features/calculator/service/tree_expression_editor_test.dart
```

至少涵蓋：

- 連續輸入 `123` 合併為單一 NumberNode。
- 在 `1|23` 插入 `9`。
- 同一數字不能有兩個小數點。
- 插入及替換 operator。
- 建立函數並將 cursor 移入 argument。
- 建立 fraction 並進入 numerator/denominator。
- 將 `33` 提升為 fraction numerator。
- 建立 root 並進入 radicand。
- 將 `5` 提升為 power base。
- Number 內 Backspace。
- 刪除空 FunctionNode、RootNode、FractionNode、PowerNode。
- 深層 Tree 修改保持其他 Node ID 不變。

## Phase 4 驗收條件

- 所有 MVP 按鍵不再修改 expression string。
- Fraction 不再需要 draft/OK 模式。
- Function、Root、Power 由真實 child sequence 表示。
- Editor 返回 immutable document。
- Navigator 與 Editor 能組合使用。

---

# Phase 5：Validator、Compiler、Evaluator 與 Engine

## 狀態

**已完成。**

已建立以下結構（UI-free 平行層，未修改任何 production ViewModel/State/UI。
為避免破壞仍在運作的舊字串版 evaluator/engine，Tree 版本以獨立檔名建立，
舊 `expression_evaluator.dart` / `calculator_engine.dart` 保留至 Phase 6）：

```text
lib/core/errors/
└── calculator_exception.dart           （擴充 overflow + undefinedAnswer）
lib/features/calculator/model/expression/
└── validation_failure.dart
lib/features/calculator/service/
├── expression_validator.dart           （新增）
├── expression_compiler.dart            （新增，Pratt parser）
├── tree_expression_evaluator.dart      （Tree 版，獨立檔名）
└── tree_calculator_engine.dart         （Tree 版，獨立檔名）
test/features/calculator/service/
├── expression_validator_test.dart
└── tree_calculator_engine_test.dart
```

### 實作重點

- `ExpressionValidator` 遍歷 Tree 回傳第一個 `ValidationFailure`（type /
  message / nodeId 或 sequenceId），不 throw。檢查空 root、operator 結尾、
  非法連續 operator、NumberNode 只是 `.`、所有 composite node 的 child
  sequence 非空、Ans 未定義等。
- `ExpressionCompiler` 內建 Pratt parser 處理 operator 優先順序（先乘除後
  加減、unary minus），直接把 Node 編譯成 `math_expressions` 的
  `Expression`，不再轉回字串。
- DEG/RAD 在 Compiler 階段處理：trig argument 在 DEG 模式乘上 `pi/180`，
  反三角函數輸出乘上 `180/pi`（不再用 regex 改字串）。
- `TreeExpressionEvaluator` 將 `NaN` 映射為 `domainError`、`Infinity` 映射
  為 `overflow`、divide-by-zero 訊息映射為 `divisionByZero`。
- `TreeCalculatorEngine` 協調 Validator -> Compiler -> Evaluator ->
  ResultFormatter，回傳 `CalculationResult`，失敗時拋 `CalculatorException`。

### 已知設計細節

- Pratt parser 以 `_position` 追蹤目前 token；遞迴進入子 sequence（fraction
  / group / power 的 child）時必須 save/restore `_position`，否則外層解析
  進度會被破壞（例如 `(2+3)*4` 會丟失 `*4`）。
- IEEE 除法對 `1/0` 回傳 `Infinity`，對 `log(0)` 回傳 `-Infinity`，因此
  Evaluator 將這類情況映射為 `overflow`；測試以 `anyOf(divisionByZero,
  overflow)` / `anyOf(domainError, overflow)` 接受這兩種合理歸類。

## 目標

讓 Tree 可以被驗證並計算。按 `=` 時依序執行：

```text
ExpressionValidator
-> ExpressionCompiler
-> ExpressionEvaluator
-> ResultFormatter
-> CalculationResult
```

## 建議檔案

```text
lib/features/calculator/service/expression_validator.dart
lib/features/calculator/service/expression_compiler.dart
lib/features/calculator/service/expression_evaluator.dart
lib/features/calculator/service/calculator_engine.dart
lib/features/calculator/model/expression/validation_failure.dart
```

## Validator

Validator 需要回傳 domain-level error，而不是直接 throw parser exception。

需要檢查：

- Root sequence 不可為空。
- Sequence 不可以 operator 結尾。
- 不允許非法連續 operator。
- NumberNode 不可只是 `.`。
- Function argument 不可為空。
- Fraction numerator/denominator 不可為空。
- Fraction denominator 不可在可確定情況下為零。
- Root radicand 不可為空。
- Power base/exponent 不可為空。
- Group content 不可為空。
- Ans 在尚無上一個答案時的行為明確。

Validation error 應包含：

```text
type
message
nodeId 或 sequenceId
```

這讓未來 UI 可將錯誤位置標示出來。

## Compiler

Compiler 不應把 Tree 轉回字串後再交給 `GrammarParser`。它應直接把 Node 編譯成 `math_expressions` 的 Expression，或編譯成自訂 evaluation AST。

### Operator 優先順序

`SequenceNode` 是線性輸入，Compiler 必須處理：

```text
2 + 3 * 4 = 14
```

可採用：

- Shunting-yard，先轉 postfix，再建立 Expression。
- Pratt parser，以 Sequence children 作 token stream。
- 兩階段 reduce，先乘除後加減。

建議使用 Pratt parser 或 shunting-yard，便於未來加入 unary operator、百分比及階乘。

### Node compilation

概念對應：

```text
NumberNode    -> Number
Constant pi  -> Number(pi) 或 bound variable
Constant e   -> Number(e)
FractionNode -> numerator / denominator
RootNode     -> power(radicand, 1 / degree)
PowerNode    -> Power(base, exponent)
FunctionNode -> Sin/Cos/Tan/Ln/Log 或 custom expression
GroupNode    -> compile(content)
```

### DEG/RAD

不要再用 regex 修改 `sin(...)` 字串。

Compiler 或 Evaluator 根據 `AngleMode` 將三角函數 argument 轉換：

```text
DEG: argument * pi / 180
RAD: argument
```

反三角函數在 DEG 模式下需要將輸出由 radians 轉成 degrees。

### log10 與 ln

語義必須清楚：

```text
log10(x) = ln(x) / ln(10)
ln(x)    = natural log
```

按鍵標籤顯示 `log₁₀`，Model 使用 `MathFunction.log10`。

## Exact 與 Approximate Result

MVP 可先回傳 double，但為中學自然顯示預留：

```text
exactNode
approximateValue
formattedValue
```

後續可加入 `rational` 支援精確分數：

```text
33/55 -> 3/5
```

更進一步才處理：

```text
sqrt(8) -> 2sqrt(2)
```

Phase 5 不必一次完成完整 symbolic algebra，但 API 不應把結果鎖死為單一 String。

## Error Mapping

Evaluator 或數學套件的錯誤必須翻譯為：

```text
emptyExpression
invalidExpression
divisionByZero
domainError
nonFiniteResult
overflow
undefinedAnswer
```

錯誤只在按 `=` 後出現在結果區，不出現在輸入欄。

## Phase 5 測試

建立：

```text
test/features/calculator/service/expression_validator_test.dart
test/features/calculator/service/expression_compiler_test.dart
test/features/calculator/service/calculator_engine_test.dart
```

必測：

```text
2 + 3 * 4       -> 14
(2 + 3) * 4     -> 20
5^2             -> 25
sqrt(9)         -> 3
sqrt(2)/sqrt(3) -> approximately 0.8164965809
sin(30 DEG)     -> approximately 0.5
sin(pi/2 RAD)   -> approximately 1
cos(60 DEG)     -> approximately 0.5
tan(45 DEG)     -> approximately 1
log10(100)      -> 2
ln(e)           -> 1
```

錯誤案例：

```text
1 / 0
sqrt(-1)
log10(0)
ln(-1)
empty function
empty denominator
operator at end
```

浮點測試使用 tolerance，不直接比較 double equality。

## Phase 5 驗收條件

- Engine 完全以 Tree 作為輸入。
- 不再 parse UI TeX。
- 不再依賴 evaluation string。
- DEG/RAD 對巢狀 argument 仍正確。
- Domain error 被安全轉換。
- 核心中學範圍運算測試通過。

---

# Phase 6：Riverpod MVVM、UI 接駁及移除舊架構

## 狀態

**已完成。**

Expression Tree 重構全數收尾。production state 已改用
`TreeExpressionDocument`，舊字串架構（evaluationExpression、texExpression、
cursor offset、openParentheses、FractionDraft）與舊字串版 service 全數移除。

### 重寫的 production 檔案

```text
lib/features/calculator/model/expression/expression_document.dart  （typedef -> TreeExpressionDocument）
lib/features/calculator/model/calculator_state.dart                （Tree 欄位，移除 FractionDraft）
lib/features/calculator/viewmodel/calculator_providers.dart        （註冊 Tree services）
lib/features/calculator/viewmodel/calculator_view_model.dart       （Tree editor/navigator/engine）
lib/features/calculator/view/calculator_screen.dart                （Tree serializer）
lib/features/calculator/view/widgets/natural_math_display.dart     （移除 fallbackText）
```

### 刪除的舊檔案

```text
lib/features/calculator/model/expression/fraction_draft.dart
lib/features/calculator/service/expression_editor.dart        （字串版）
lib/features/calculator/service/expression_tex_serializer.dart （字串版）
lib/features/calculator/service/expression_evaluator.dart     （字串版）
lib/features/calculator/service/calculator_engine.dart        （字串版）
lib/features/calculator/model/calculator_action.dart          （空佔位檔）
lib/features/calculator/model/expression/node/binary_node.dart （空佔位檔）
```

### 新增測試

```text
test/features/calculator/viewmodel/calculator_view_model_test.dart  （9 個 state transition）
test/features/calculator/view/calculator_screen_test.dart           （5 個 widget test）
```

### 已知設計細節

- `)` 鍵在 Tree 模型沒有對應的「關閉群組」操作（離開群組由方向鍵處理），
  因此 `)` 鍵與 `(` 鍵行為一致（都呼叫 `insertGroup`），保留既有 keypad 版面。
- 任何輸入後清除 error（backspace、數字、方向鍵等都會清）。
- `NaturalMathDisplay` 使用無限循環閃爍動畫，widget test 需用 `pump()` 而非
  `pumpAndSettle()`（後者會因動畫永不完結而 timeout）。
- Tree 版 service 檔名仍保留 `tree_` 前綴（`tree_calculator_engine.dart` 等），
  未強制改名，避免影響 import；後續可視需要再改名。

## 目標

將 Tree Model、Navigator、Serializer、Editor、Validator、Compiler 及 Engine 接回正式 App，完成舊雙字串架構退役。

這是唯一需要集中修改多個 production files 的階段。

## 主要修改檔案

```text
lib/features/calculator/model/expression/expression_document.dart
lib/features/calculator/model/calculator_state.dart
lib/features/calculator/viewmodel/calculator_providers.dart
lib/features/calculator/viewmodel/calculator_view_model.dart
lib/features/calculator/view/calculator_screen.dart
lib/features/calculator/view/widgets/natural_math_display.dart
lib/features/calculator/view/widgets/calculator_keypad.dart
```

## ExpressionDocument 正式切換

將 Tree document 正式改名為：

```text
ExpressionDocument
```

內容只保留：

```text
root
cursor
```

刪除：

```text
evaluationExpression
texExpression
openParentheses
evaluationCursorOffset
texCursorOffset
```

## CalculatorState

建議最終欄位：

```text
document
result
angleMode
error
hasEvaluated
answer
```

刪除：

```text
fractionDraft
isEditingFraction
```

分數已是 Tree 中的正常 Node，不再有特殊狀態。

## Providers

Provider dependency graph：

```text
ExpressionNavigator Provider
TreeRewriter Provider
ExpressionEditor Provider
ExpressionTexSerializer Provider
ExpressionValidator Provider
ExpressionCompiler Provider
ExpressionEvaluator Provider
CalculatorEngine Provider
CalculatorViewModel NotifierProvider
```

避免加入第二套 service locator，例如 `get_it`。

## CalculatorViewModel

ViewModel 方法保持以 UI intent 命名：

```text
inputDigit
inputDecimalPoint
inputAdd
inputSubtract
inputMultiply
inputDivide
inputSin
inputCos
inputTan
inputLog10
inputLn
inputPi
inputEulerNumber
inputFraction
inputSquareRoot
inputPower
inputSquare
inputOpenGroup
moveLeft
moveRight
moveUp
moveDown
backspace
clear
calculate
toggleAngleMode
```

每個輸入方法只做：

1. 呼叫 Editor 或 Navigator。
2. 將回傳 document 寫入新 state。
3. 清除舊 result/error。

`calculate()` 才呼叫 Engine，失敗時將 domain error 放入 ResultDisplay。

ViewModel 不應：

- 建立 TeX。
- 持有 BuildContext。
- 操作 Widget。
- 直接建立 `math_expressions` 物件。
- 自己遞迴修改 Tree。

## CalculatorScreen

Screen 監聽 state，透過 serializer 產生：

```text
visibleCursorTex
hiddenCursorTex
```

並將按鍵 callbacks 連接至 ViewModel。

輸入欄只顯示 expression，結果欄只顯示 result/error。

## NaturalMathDisplay

保留閃爍動畫，但不管理 cursor location。

職責：

- 在 visible/hidden TeX 間切換。
- 維持等寬 cursor layout。
- 水平捲動。
- Renderer 失敗時顯示安全 fallback。

## Keypad

MVP 應包含：

```text
0-9
.
+
-
*
/
(
)
sin
cos
tan
log10
ln
sqrt
x^2
x^y
pi
e
a/b
left
right
up
down
DEL
AC
=
DEG/RAD
```

`a/b` 不再有 OK 鍵。方向鍵直接導航 Tree。

## 移除舊檔案及舊程式碼

完成接駁後才刪除：

```text
lib/features/calculator/model/expression/fraction_draft.dart
```

並從所有檔案移除：

```text
FractionDraft
FractionPart
evaluationExpression
texExpression
evaluationCursorOffset
texCursorOffset
openParentheses
_previousTexTokenLength
_nextTexTokenLength
字串補括號及補 TeX brace 邏輯
```

舊 `expression_editor.dart`、`expression_tex_serializer.dart` 若有 parallel Tree 版本，完成後以 Tree 版本取代並刪除過渡檔。

## Migration 順序

建議用以下次序降低中途破壞：

1. Providers 先註冊 Tree services，但 ViewModel 暫不使用。
2. CalculatorState 改用 Tree document。
3. ViewModel 所有 input method 改接 Tree Editor。
4. 左右上下改接 Tree Navigator。
5. Screen 改接 Tree Serializer。
6. Engine 改接 Tree Compiler。
7. 執行所有 tests。
8. 刪除舊 string model 及 FractionDraft。
9. 再次執行 analyze/test。

## Phase 6 測試

### ViewModel tests

```text
test/features/calculator/viewmodel/calculator_view_model_test.dart
```

驗證 state transition：

- 輸入 `123`。
- 插入函數後 cursor 進入 argument。
- 從 function argument 向右離開。
- 建立 fraction 並在 numerator/denominator 導航。
- 計算成功後 result 更新。
- 計算失敗只更新 result error。
- 繼續輸入後清除 error。
- AC 清空 Tree 但保留 angle mode。

### Widget tests

```text
test/features/calculator/view/calculator_screen_test.dart
```

驗證：

- expression display 存在。
- result display 存在。
- 所有核心按鍵存在。
- 按鍵會觸發預期 state。
- 錯誤不顯示於 expression field。

### Golden tests，可延後

針對：

- 普通算式
- 函數
- 分數
- 根式
- 指數
- 深色/亮色
- 小型手機及 Desktop 寬度

## Phase 6 最終驗收流程

### Function navigation

```text
按 sin
輸入 30
按 right
```

游標必須從 `sin(30|)` 移到 `sin(30)|`。

### Fraction

```text
輸入 33
按 a/b
輸入 55
按 =
```

應顯示 `33/55` 的自然分數並計算為 `0.6`，不得產生 `33 * (33/55)`。

### Root fraction

```text
按 a/b
按 sqrt
輸入 2
按 down
按 sqrt
輸入 3
按 =
```

顯示：

```text
sqrt(2)
-------
sqrt(3)
```

結果約為 `0.816496580928`。

### Cursor stability

- 游標可見/隱藏時公式不移動。
- 游標可在 Number 內移動。
- 游標可進出 function、group、root、power、fraction。
- 分數上下鍵可保持大致水平位置。

### Error placement

- 輸入途中不顯示 `Expression error`。
- 只有按 `=` 後，validation/evaluation error 才顯示於 ResultDisplay。
- 使用者繼續輸入後 error 清除。

## Phase 6 驗收條件

- `flutter analyze`：No issues found。
- 全部 unit/widget tests 通過。
- production state 不再保存 expression/TeX string。
- `fraction_draft.dart` 已刪除。
- 函數、分數、根式、指數及方向鍵使用 Tree 行為。
- App 可在至少 Windows 及一個 mobile/web target 啟動。

---

# 4. 測試矩陣

## Model

```text
NodeId uniqueness
Node immutable copy
Sequence insert/replace/remove
Nested node construction
CursorPosition equality
```

## Navigation

```text
Number text offsets
Root boundaries
Function enter/leave
Group enter/leave
Fraction left/right/up/down
Power left/right/up/down
Nth-root degree/radicand navigation
Invalid cursor recovery
```

## Serialization

```text
All node types
Empty active sequence
Empty inactive sequence
Cursor inside Number
Cursor between Nodes
Visible/hidden cursor width stability
Nested TeX structures
```

## Editing

```text
Digit merge
Decimal guards
Operator replacement
Function insertion
Fraction promotion
Root insertion
Power promotion
Backspace at every structural boundary
Deep immutable rewrite
```

## Validation and calculation

```text
Operator precedence
Groups
Fractions
Roots
Powers
DEG/RAD
log10/ln
Constants
Domain errors
Division by zero
Non-finite results
```

## MVVM and UI

```text
Provider wiring
State transitions
Result/error separation
Key callbacks
Cursor animation
Responsive layout
```

---

# 5. Definition of Done

整個 Expression Tree 重構只有在以下條件全部滿足時才算完成：

- [x] Expression Tree 是唯一算式資料來源。
- [x] 沒有 production code 儲存 evaluation expression string。
- [x] 沒有 production code 儲存 TeX expression string。
- [x] 沒有 evaluation/TeX cursor offset 同步邏輯。
- [x] FractionDraft 已移除。
- [x] 所有輸入操作透過 Tree Editor。
- [x] 所有方向移動透過 Tree Navigator。
- [x] TeX 完全由 Tree Serializer 產生。
- [x] 計算完全由 Tree Compiler 產生。
- [x] 錯誤只在按 `=` 後出現於 ResultDisplay。
- [x] 函數 argument 可進出。
- [x] 分子、分母可上下及左右導航。
- [x] 根式及指數可進出。
- [x] 游標閃爍不造成公式位移。
- [x] `flutter analyze` 無問題。
- [x] 全部 unit/widget tests 通過（140 tests）。
- [ ] Windows App 可執行（本機為 macOS，未驗證 Windows target）。
- [x] 至少另一個 Flutter target 可執行（macOS debug build 成功）。

---

# 6. 目前下一步

六個 Phase 全數完成，Expression Tree 重構已收尾。後續可考慮的方向：

- 將 Tree 版 service 檔案改名去掉 `tree_` 前綴（`tree_calculator_engine.dart` ->
  `calculator_engine.dart` 等），目前保留前綴以避免影響 import。
- 在 Windows target 上驗證 App 可執行（本機為 macOS，已驗證 macOS debug build）。
- 加入 Golden tests（普通算式、函數、分數、根式、指數、深色/亮色）。
- 擴充功能（見第 9 節）：精確 Rational 結果、階乘與百分比、反三角函數、
  科學記數法模板、Ans 與計算歷史、方程求解、複數、微積分、矩陣模式等。

---

# 7. 常用檢查命令

```powershell
dart format lib test
flutter analyze
flutter test
flutter run -d windows
```

建議每個 Phase 使用獨立 Git commit：

```text
refactor(expression): add editable tree model
refactor(expression): add structural navigator
refactor(expression): add tree tex serializer
refactor(expression): add tree editor
refactor(expression): add tree compiler and validator
refactor(calculator): migrate mvvm and ui to expression tree
```

---

# 8. 風險及控制

## 風險：一次改動太多 production files

控制：Phase 2 至 Phase 5 使用 parallel Tree implementation，Phase 6 才集中切換。

## 風險：Tree immutable 更新過於複雜

控制：建立 TreeIndex 及 TreeRewriter，不讓 ViewModel 或 Editor 手工重建每一層。

## 風險：Backspace 行為不一致

控制：先寫行為規格及 unit tests，再實作每個 structural boundary。

## 風險：TeX 顯示成功但計算語義不同

控制：Serializer 與 Compiler 都從同一 Tree 讀取，不可互相轉換輸出。

## 風險：保留舊版造成混淆

控制：過渡檔加上 migration 註解，Phase 6 建立明確刪除清單。

## 風險：過早加入微積分及矩陣

控制：完成中學 MVP 的 Tree、導航、分數、根式、指數及函數後，才擴充新 mode。矩陣應使用專用 Node 和 Editor mode，不應硬塞進目前的 scalar Sequence 規則。

---

# 9. 後續功能方向

六個 Phase 完成後，可逐步加入：

```text
精確 Rational 結果及 S<->D
階乘與百分比
反三角函數
一般 n 次根
科學記數法模板
Ans 與計算歷史
方程求解
複數
微分及定積分節點
矩陣模式
向量模式
統計模式
```

新增功能仍應遵守相同分層：

```text
Node
-> Editor behavior
-> Navigator behavior
-> Serializer
-> Validator
-> Compiler/Evaluator
-> ViewModel action
-> Keypad/UI
-> Tests
```
