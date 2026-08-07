## Overview

Add a **DEC/FRAC display toggle** next to the DEG/RAD chip. In **FRAC** mode, results are shown exactly as **simplified fractions / mixed numbers / surds** (e.g. `4/3 → 1⅓`, `√12 → 2√3`, `√2+√3`), rendered as rich math (TeX) like the expression area. In **DEC** mode, behavior is unchanged (decimals). The preference is persisted via `SharedPreferences`, following the existing `theme_settings.dart` pattern.

**Key design decision — exact (symbolic) evaluation, not double-guessing.** The expression is already a *typed AST* (`NumberNode`, `FractionNode`, `RootNode`, `PowerNode`, …). I'll walk that AST with exact `BigInt` arithmetic to produce the simplified form directly. This guarantees correctness for the middle-school simplification rules. When an exact form is impossible (trig, `π`, `e`, `ln`, `log`, non-integer powers, `³√x`, huge radicands, rationalizing failures), the exact path gracefully *bails out → falls back to the existing decimal path*. Exactly the fallback the user asked for.

No new dependencies (`BigInt` is built-in; `flutter_math_fork` already in use).

## Core algorithm — exact algebra (new, under `lib/features/calculator/service/exact_math/`)

1. **`rational.dart` — `Rational`**: a minimal exact-fraction type (`BigInt` numerator, `BigInt` denominator > 0, always reduced). Supports `+ - * /`, comparisons, `fromDecimalString` (parses `"2.5" → 5/2` exactly from the `NumberNode` string), and sign handling.

2. **`exact_number.dart` — `ExactNumber`**: represents a sum of surd terms `Σ coeff_i · √radicand_i`, stored as a `Map<BigInt radicand, Rational coeff>` (radicand square-free; radicand `1` = rational part). Supports:
   - **add/sub**: merge matching radicands.
   - **mul**: distribute; product of `√r1·√r2` is resimplified to `√(squarefree)·k` and the `k` folded into the coefficient (so `√2·√8 = √16 = 4`).
   - **div**: invert via rationalization; invertible for single-term or two-term (`a+b√d`) denominators; otherwise bail (return `null`).
   - **integer power**: repeated multiplication.
   - **sqrtOf(n)**: factor out the largest perfect square → `k·√squarefree`.
   - `toApproximate` (double), `isZero`, and a **bail-out** convention (`null`).
   - Square-free extraction by trial division up to √n, capped (radicand > 1e15 → bail to avoid slow factorization).

3. **`exact_value_evaluator.dart`**: walks the typed AST (`SequenceNode`) into `ExactNumber?`, using the same operator-precedence table as `ExpressionCompiler` (`+/-` =1, `*/` ÷ =2, unary `-` =3). Node handling:
   - `NumberNode` → `Rational.fromDecimalString(value)`; `ConstantNode.pi/e` → bail (transcendental); `ConstantNode.answer` → exact only if Ans is an integer, else bail.
   - `FractionNode` → num ÷ den; `GroupNode` → recurse; `RootNode` square root → exact (rationalize perfect squares / surd); `RootNode` *n-th* (degree set) → bail.
   - `PowerNode` → exact if exponent is an integer; non-integer exponent → bail. (`x^0.5` not specially handled → bail; users have the dedicated √ key for surds.)
   - `FunctionNode` (sin/cos/tan/asin/acos/atan/log10/ln/abs) → bail (DEG/RAD irrelevant — they always bail).
   - Any bail propagates as `null` (→ decimal fallback).

4. **`exact_value_formatter.dart`**: `ExactNumber` → TeX string for `flutter_math_fork`:
   - Rational-only result → integer (plain), proper/improper fraction `\frac{n}{d}`, or **mixed** `w\frac{n}{d}` when `|numerator| > denominator`.
   - Surd terms: `2\sqrt{3}`, `\sqrt{2}` (coeff ±1 omitted), `-\frac{1}{2}\sqrt{3}`, combined as a signed sum with the rational part first, e.g. `1\frac{1}{2}-\frac{1}{2}\sqrt{3}`.
   - Never emits TeX for trivial results (integers, 0) — those stay plain text.

## Persistence + UI (mirrors `theme_settings.dart`)

5. **`lib/app/result_format_settings.dart`** — `ResultFormatPreference { decimal, fraction }` with `.label` (`'DEC'`/`'FRAC'`), `.fromName`; `ResultFormatSettingsStorage` (key `'result_format_preference'`, `getString`/`setString`); `initialResultFormatPreferenceProvider`, `ResultFormatSettingsNotifier`, `resultFormatSettingsProvider`. Default `decimal` (preserves current behavior).

6. **`lib/app/bootstrap.dart`** — pre-load `ResultFormatSettingsStorage.load()` and override `initialResultFormatPreferenceProvider` in `ProviderScope`.

7. **`lib/features/calculator/view/widgets/result_format_indicator.dart`** — an `ActionChip` (clone of `mode_indicator.dart`, icon `Icons.calculate`), label = current mode's `.label`.

8. **`lib/features/calculator/view/calculator_screen.dart`** — add `ResultFormatIndicator` to the AppBar actions immediately **after** the DEG/RAD chip; pass `formattedTex` into `ResultDisplay`.

9. **`lib/features/calculator/view/widgets/result_display.dart`** — accept optional `String? tex`; when present, render via `Math.tex(tex, mathStyle: MathStyle.text)` inside a right-aligned, horizontally-scrollable container matching existing typography (`headlineMedium`, weight 600, `onSurface`/error colors); errors and plain results unchanged. Decimals are unaffected.

## Engine + view-model wiring

10. **`lib/features/calculator/model/calculation_result.dart`** — add optional `String? formattedTex` (default `null`). `formattedValue` stays the plain decimal (used for `Ans`/errors).

11. **`lib/features/calculator/service/tree_calculator_engine.dart`** — `evaluate(...)` gains a `ResultFormatPreference resultFormat` param. In **fraction** mode it additionally runs `ExactValueEvaluator` → `ExactValueFormatter`; sets `formattedTex` to the TeX (or leaves `null` on bail-out → decimal shows). The numeric `value` is always the existing `double` (so `Ans` stays consistent across modes).

12. **`lib/features/calculator/viewmodel/calculator_view_model.dart`**:
    - `calculate()` reads `ref.read(resultFormatSettingsProvider)` and passes it to the engine.
    - New `toggleResultFormat()` flips the persisted preference (via the notifier) **and**, if a result is currently shown (`state.result != null`), re-evaluates the current `document.root` with the new format so the display updates instantly without pressing `=`.

## Tests
- **`test/features/calculator/service/exact_math/*_test.dart`** — heavy unit tests on `Rational`, `ExactNumber` (add/mul/div/rationalize/sqrtOf, simplification √12→2√3, √2·√8→4, 1/√2→√2/2, bail-outs), `ExactValueEvaluator` (build trees from nodes; assert exact outputs and bail-outs), `ExactValueFormatter` (TeX strings incl. mixed `1\frac{1}{3}`, surds, signed sums).
- **`test/app/result_format_settings_test.dart`** — mirrors `theme_settings_test.dart` (storage round-trip, notifier, override) using the existing `setupSharedPreferencesForTest` helper.
- Extend **`tree_calculator_engine_test.dart`** — assert `formattedTex` in fraction mode for representative cases (fractions, surds, mixed) and `null` (bail-out) for trig.
- Run `flutter analyze` + full test suite; the existing DEG/RAD and decimal tests must stay green (decimal is the default).

## Behavior summary
| Input | DEC mode (unchanged) | FRAC mode (new) |
|---|---|---|
| `4 / 3` | `1.33333333333` | `1⅓` (TeX) |
| `√12` | `3.46410161514` | `2√3` (TeX) |
| `1 / √2` | `0.707106781187` | `√2/2` (TeX) |
| `√2 + √3` | `3.14626436994` | `√2 + √3` (TeX) |
| `sin(30°)` | `0.5` | `0.5` (bail-out → decimal, since trig) |
| `2 + 3` | `5` | `5` (plain — trivial) |

Files touched: **6 new** (`result_format_settings.dart`, 4 exact-math files, `result_format_indicator.dart`) + **6 modified** (`calculation_result.dart`, `tree_calculator_engine.dart`, `calculator_view_model.dart`, `calculator_screen.dart`, `result_display.dart`, `bootstrap.dart`), plus tests. No new dependencies.