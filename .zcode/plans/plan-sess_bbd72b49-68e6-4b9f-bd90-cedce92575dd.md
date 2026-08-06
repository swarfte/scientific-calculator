## Overview
Add a **settings button** next to the DEG/RAD chip in the AppBar. It opens a settings dialog with two things:
1. A **theme switcher** (Light / Dark / System) — persisted to `SharedPreferences` so it's remembered across launches.
2. The **app version** displayed as `x.y.z (build n)` (e.g. `1.0.0 (build 1)`), read at runtime from `package_info_plus`.

The app already has `AppTheme.light`/`AppTheme.dark`, `shared_preferences` (via `SharedPreferencesAsync`), Riverpod, and `package_info_plus` (declared but unused) — so this is mostly wiring, using existing patterns (mirror `WindowStateStorage` for persistence, mirror `CalculatorViewModel` Notifier for state).

## Files to create

### 1. `lib/app/theme_settings.dart` — persistence + Riverpod state
Mirrors the `WindowStateStorage` pattern (same `SharedPreferencesAsync` API, same Chinese-comment style already used in the file).

- **`ThemePreference` enum**: `light`, `dark`, `system`, each with:
  - a `label` getter ('Light' / 'Dark' / 'System') — mirrors `AngleMode.label` style in `angle_mode.dart`.
  - a `ThemeMode` material getter mapping to `ThemeMode.light` / `ThemeMode.dark` / `ThemeMode.system`.
- **`ThemeSettingsStorage`** (static class like `WindowStateStorage`):
  - key `'theme_preference'` (stored as `String`).
  - `Future<ThemePreference> load()` → returns saved value or `ThemePreference.system` default.
  - `Future<void> save(ThemePreference)` → persists.
- **`themeSettingsProvider`** — a `Notifier<ThemePreference>`:
  - `build()` reads `ref` is not async-friendly for Notifier, so load lazily: initialize to `ThemePreference.system`, then on construction kick off an async load via an async notifier. **Use `AsyncNotifier`** to avoid blocking: `AsyncNotifierProvider<ThemeSettingsNotifier, ThemePreference>`.
    - Actually simpler/cleaner with the existing codebase's sync `Notifier` pattern: bootstrap.dart (which already does async init) loads the saved preference *before* `runApp` and passes it as an override to `ProviderScope.overrides`. This guarantees the correct theme on the very first frame (no flash). The Notifier then just holds/updates it and saves on change.
  - `void set(ThemePreference)` → `state = x; unawaited(ThemeSettingsStorage.save(x));`

**Chosen approach (flash-free, matches existing bootstrap pattern):**
- `ThemeSettingsNotifier extends Notifier<ThemePreference>` with `build()` returning the initial value.
- A `Future<ThemePreference> Function()` is **not** needed because `bootstrap()` already runs async init before `runApp`. It will load the saved preference and override the provider's initial value via `ProviderScope(overrides: [...])`.

### 2. `lib/features/calculator/view/widgets/settings_button.dart`
A small `StatelessWidget` rendering an `IconButton(icon: Icons.settings, ...)` whose `onPressed` shows the settings dialog. Kept as its own widget to mirror the `mode_indicator.dart` separation.

### 3. `lib/features/calculator/view/widgets/settings_dialog.dart`
A `ConsumerWidget` (needs `ref` to read/write `themeSettingsProvider` and watch package info) returning an `AlertDialog`:
- Title: "Settings".
- **Theme section**: a `Column` of three `RadioListTile<ThemePreference>` (System / Light / Dark). Selecting one calls `ref.read(themeSettingsProvider.notifier).set(value)`.
- **About section**: a `ListTile` showing version as `1.0.0 (build 1)`. Version comes from a new `packageInfoProvider` (a `FutureProvider<PackageInfo>` using `package_info_plus`) — displayed via `FutureBuilder` so it shows `'—'` until loaded.
- A single Close action button.

## Files to modify

### 4. `lib/app/app.dart`
- Make `ScientificCalculatorApp` a **`ConsumerWidget`** (currently `StatelessWidget`).
- Replace the hardcoded `themeMode: ThemeMode.system` with `themeMode: ref.watch(themeSettingsProvider).themeMode`.

### 5. `lib/app/bootstrap.dart`
- After window setup, before `runApp`: load `final savedTheme = await ThemeSettingsStorage.load();`
- Pass it as an override: `ProviderScope(overrides: [themeSettingsProvider.overrideWith(() => ThemeSettingsNotifier()..preload(savedTheme))], child: ...)`. Concretely the notifier takes the initial value; to keep it simple I'll give `ThemeSettingsNotifier` an injectable initial via a constructor arg consumed in `build()`, or use a top-level `late` init value. Cleanest: `Notifier.build()` reads the value, so I'll pass it through an override that constructs the notifier with the value. Final detail resolved at implementation time to satisfy Riverpod 3.x `overrideWith`.

### 6. `lib/features/calculator/view/calculator_screen.dart`
- Add a `SettingsButton` next to `ModeIndicator` inside the AppBar `actions` `Row`/`Padding` (the DEG/RAD chip stays; settings icon goes to its right).

## Tests to add (match existing `test/` mirror structure)

### 7. `test/app/theme_settings_test.dart`
- `ThemePreference.label` values, `.themeMode` mapping.
- `ThemeSettingsStorage.save`/`load` round-trip (use `SharedPreferences` test setup — `SharedPreferences.setMockInitialValues({})`). Verifies default = system when unset.

### 8. `test/features/calculator/view/widgets/settings_dialog_test.dart`
- Pump the dialog in a `ProviderScope` + `MaterialApp`, tap a radio, assert provider state changed and label rendered.
- Assert version row renders once `PackageInfo` future resolves (mock via provider override).

## Verification
- `flutter analyze` — no new warnings.
- `flutter test` — all existing + new tests pass.
- Manual (optional): run app, toggle themes, restart, confirm persistence and the `1.0.0 (build 1)` string in the dialog.

## Notes / non-goals
- Angle mode is **not** persisted (out of scope; you only asked for theme).
- No new dependencies added — everything (`shared_preferences`, `package_info_plus`, `flutter_riverpod`) is already in pubspec.
- Existing "follow system" behavior is preserved as the **System** option and remains the default.