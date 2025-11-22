# TDDテストケース一覧: TASK-0016 テーマ実装（ライト・ダーク・高コントラスト）

## 概要

| 項目 | 内容 |
|------|------|
| **TASK-ID** | TASK-0016 |
| **タスク名** | テーマ実装（ライト・ダーク・高コントラスト） |
| **要件定義書** | tdd-requirements.md |
| **作成日** | 2025-11-22 |

---

## 1. テーマプロバイダーのテストケース

### TC-001: 初期状態でライトテーマが返される

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-001 |
| **テストケース名** | 初期状態でライトテーマが返される |
| **テストファイル** | `test/core/themes/theme_provider_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- アプリが初期起動状態である
- SharedPreferencesにテーマ設定が保存されていない
- `settingsNotifierProvider`がデフォルト値（`AppTheme.light`）を返す

**実行手順**:
1. `ProviderContainer`を作成する
2. `currentThemeProvider`を購読する
3. 返されたThemeDataのプロパティを検証する

**期待結果**:
- `currentThemeProvider`が`lightTheme`を返す
- ThemeDataの`brightness`が`Brightness.light`である
- ThemeDataの`scaffoldBackgroundColor`が`AppColors.backgroundLight`である

---

### TC-002: 設定がlightの場合、lightThemeが返される

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-002 |
| **テストケース名** | 設定がlightの場合、lightThemeが返される |
| **テストファイル** | `test/core/themes/theme_provider_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `settingsNotifierProvider`の状態が`AppTheme.light`に設定されている

**実行手順**:
1. `ProviderContainer`を作成する
2. `settingsNotifierProvider`でテーマを`AppTheme.light`に設定する
3. `currentThemeProvider`を購読する
4. 返されたThemeDataを検証する

**期待結果**:
- `currentThemeProvider`が`lightTheme`と同等のThemeDataを返す
- ThemeDataの`brightness`が`Brightness.light`である

---

### TC-003: 設定がdarkの場合、darkThemeが返される

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-003 |
| **テストケース名** | 設定がdarkの場合、darkThemeが返される |
| **テストファイル** | `test/core/themes/theme_provider_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `settingsNotifierProvider`の状態が`AppTheme.dark`に設定されている

**実行手順**:
1. `ProviderContainer`を作成する
2. `settingsNotifierProvider`でテーマを`AppTheme.dark`に設定する
3. `currentThemeProvider`を購読する
4. 返されたThemeDataを検証する

**期待結果**:
- `currentThemeProvider`が`darkTheme`と同等のThemeDataを返す
- ThemeDataの`brightness`が`Brightness.dark`である

---

### TC-004: 設定がhighContrastの場合、highContrastThemeが返される

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-004 |
| **テストケース名** | 設定がhighContrastの場合、highContrastThemeが返される |
| **テストファイル** | `test/core/themes/theme_provider_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `settingsNotifierProvider`の状態が`AppTheme.highContrast`に設定されている

**実行手順**:
1. `ProviderContainer`を作成する
2. `settingsNotifierProvider`でテーマを`AppTheme.highContrast`に設定する
3. `currentThemeProvider`を購読する
4. 返されたThemeDataを検証する

**期待結果**:
- `currentThemeProvider`が`highContrastTheme`と同等のThemeDataを返す
- ThemeDataの`scaffoldBackgroundColor`が`AppColors.backgroundHighContrast`（純白）である

---

## 2. テーマ切り替えのテストケース

### TC-005: テーマ設定変更時にプロバイダーが即座に更新される

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-005 |
| **テストケース名** | テーマ設定変更時にプロバイダーが即座に更新される |
| **テストファイル** | `test/core/themes/theme_provider_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- 初期状態で`AppTheme.light`が設定されている

**実行手順**:
1. `ProviderContainer`を作成する
2. `currentThemeProvider`の初期値を確認する（ライトテーマ）
3. `settingsNotifierProvider`でテーマを`AppTheme.dark`に変更する
4. `currentThemeProvider`の値が即座に更新されることを確認する

**期待結果**:
- テーマ変更後、`currentThemeProvider`が新しいテーマを返す
- プロバイダーの更新が同期的に行われる（明示的なリビルドが不要）

---

### TC-006: light -> dark -> highContrast の順序でテーマが正しく切り替わる

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-006 |
| **テストケース名** | light -> dark -> highContrast の順序でテーマが正しく切り替わる |
| **テストファイル** | `test/core/themes/theme_provider_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- 初期状態で`AppTheme.light`が設定されている

**実行手順**:
1. `ProviderContainer`を作成する
2. `currentThemeProvider`がライトテーマを返すことを確認する
3. `settingsNotifierProvider`でテーマを`AppTheme.dark`に変更する
4. `currentThemeProvider`がダークテーマを返すことを確認する
5. `settingsNotifierProvider`でテーマを`AppTheme.highContrast`に変更する
6. `currentThemeProvider`が高コントラストテーマを返すことを確認する

**期待結果**:
- 各テーマ変更後に正しいThemeDataが返される
- テーマの切り替えが一貫して動作する

---

### TC-007: highContrast -> light への切り替えが正しく動作する

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-007 |
| **テストケース名** | highContrast -> light への切り替えが正しく動作する |
| **テストファイル** | `test/core/themes/theme_provider_test.dart` |
| **優先度** | 中 |
| **信頼性** | 🔵 |

**前提条件**:
- `AppTheme.highContrast`が設定されている

**実行手順**:
1. `ProviderContainer`を作成する
2. `settingsNotifierProvider`でテーマを`AppTheme.highContrast`に設定する
3. `currentThemeProvider`が高コントラストテーマを返すことを確認する
4. `settingsNotifierProvider`でテーマを`AppTheme.light`に変更する
5. `currentThemeProvider`がライトテーマを返すことを確認する

**期待結果**:
- 高コントラストモードからライトモードへの切り替えが正しく動作する
- ThemeDataの全プロパティが正しく変更される

---

## 3. ライトテーマのテストケース

### TC-101: ライトテーマのbrightnessがlightである

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-101 |
| **テストケース名** | ライトテーマのbrightnessがlightである |
| **テストファイル** | `test/core/themes/light_theme_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `lightTheme`がインポートされている

**実行手順**:
1. `lightTheme`の`brightness`プロパティを検証する

**期待結果**:
- `lightTheme.brightness`が`Brightness.light`である

---

### TC-102: ライトテーマの背景色が白系である

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-102 |
| **テストケース名** | ライトテーマの背景色が白系である |
| **テストファイル** | `test/core/themes/light_theme_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `lightTheme`がインポートされている

**実行手順**:
1. `lightTheme`の`scaffoldBackgroundColor`プロパティを検証する

**期待結果**:
- `lightTheme.scaffoldBackgroundColor`が`AppColors.backgroundLight`（`#FFFFFF`）である

---

### TC-103: ライトテーマのプライマリ色が青系である

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-103 |
| **テストケース名** | ライトテーマのプライマリ色が青系である |
| **テストファイル** | `test/core/themes/light_theme_test.dart` |
| **優先度** | 中 |
| **信頼性** | 🔵 |

**前提条件**:
- `lightTheme`がインポートされている

**実行手順**:
1. `lightTheme`の`colorScheme.primary`プロパティを検証する

**期待結果**:
- `lightTheme.colorScheme.primary`が`AppColors.primaryLight`（`#2196F3`）である

---

### TC-104: ライトテーマのElevatedButton最小サイズが60pxである

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-104 |
| **テストケース名** | ライトテーマのElevatedButton最小サイズが60pxである |
| **テストファイル** | `test/core/themes/light_theme_test.dart` |
| **優先度** | 中 |
| **信頼性** | 🔵 |

**前提条件**:
- `lightTheme`がインポートされている

**実行手順**:
1. `lightTheme.elevatedButtonTheme.style`の`minimumSize`プロパティを検証する

**期待結果**:
- minimumSizeが`Size(60.0, 60.0)`である

---

### TC-105: ライトテーマのIconButton最小サイズが44pxである

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-105 |
| **テストケース名** | ライトテーマのIconButton最小サイズが44pxである |
| **テストファイル** | `test/core/themes/light_theme_test.dart` |
| **優先度** | 中 |
| **信頼性** | 🔵 |

**前提条件**:
- `lightTheme`がインポートされている

**実行手順**:
1. `lightTheme.iconButtonTheme.style`の`minimumSize`プロパティを検証する

**期待結果**:
- minimumSizeが`Size(44.0, 44.0)`である

---

## 4. ダークテーマのテストケース

### TC-201: ダークテーマのbrightnessがdarkである

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-201 |
| **テストケース名** | ダークテーマのbrightnessがdarkである |
| **テストファイル** | `test/core/themes/dark_theme_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `darkTheme`がインポートされている

**実行手順**:
1. `darkTheme`の`brightness`プロパティを検証する

**期待結果**:
- `darkTheme.brightness`が`Brightness.dark`である

---

### TC-202: ダークテーマの背景色が暗い灰色系である

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-202 |
| **テストケース名** | ダークテーマの背景色が暗い灰色系である |
| **テストファイル** | `test/core/themes/dark_theme_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `darkTheme`がインポートされている

**実行手順**:
1. `darkTheme`の`scaffoldBackgroundColor`プロパティを検証する

**期待結果**:
- `darkTheme.scaffoldBackgroundColor`が`AppColors.backgroundDark`（`#121212`）である

---

### TC-203: ダークテーマのテキスト色が白系である

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-203 |
| **テストケース名** | ダークテーマのテキスト色が白系である |
| **テストファイル** | `test/core/themes/dark_theme_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `darkTheme`がインポートされている

**実行手順**:
1. `darkTheme`の`textTheme.bodyLarge.color`プロパティを検証する

**期待結果**:
- テキスト色が`AppColors.onBackgroundDark`（`#FFFFFF`）である

---

### TC-204: ダークテーマのElevatedButton最小サイズが60pxである

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-204 |
| **テストケース名** | ダークテーマのElevatedButton最小サイズが60pxである |
| **テストファイル** | `test/core/themes/dark_theme_test.dart` |
| **優先度** | 中 |
| **信頼性** | 🔵 |

**前提条件**:
- `darkTheme`がインポートされている

**実行手順**:
1. `darkTheme.elevatedButtonTheme.style`の`minimumSize`プロパティを検証する

**期待結果**:
- minimumSizeが`Size(60.0, 60.0)`である

---

### TC-205: ダークテーマのIconButton最小サイズが44pxである

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-205 |
| **テストケース名** | ダークテーマのIconButton最小サイズが44pxである |
| **テストファイル** | `test/core/themes/dark_theme_test.dart` |
| **優先度** | 中 |
| **信頼性** | 🔵 |

**前提条件**:
- `darkTheme`がインポートされている

**実行手順**:
1. `darkTheme.iconButtonTheme.style`の`minimumSize`プロパティを検証する

**期待結果**:
- minimumSizeが`Size(44.0, 44.0)`である

---

## 5. 高コントラストテーマのテストケース

### TC-301: 高コントラストテーマの背景色が純白である

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-301 |
| **テストケース名** | 高コントラストテーマの背景色が純白である |
| **テストファイル** | `test/core/themes/high_contrast_theme_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `highContrastTheme`がインポートされている

**実行手順**:
1. `highContrastTheme`の`scaffoldBackgroundColor`プロパティを検証する

**期待結果**:
- `highContrastTheme.scaffoldBackgroundColor`が`AppColors.backgroundHighContrast`（`#FFFFFF`）である

---

### TC-302: 高コントラストテーマのテキスト色が純黒である

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-302 |
| **テストケース名** | 高コントラストテーマのテキスト色が純黒である |
| **テストファイル** | `test/core/themes/high_contrast_theme_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `highContrastTheme`がインポートされている

**実行手順**:
1. `highContrastTheme`の`textTheme.bodyLarge.color`プロパティを検証する

**期待結果**:
- テキスト色が`AppColors.onBackgroundHighContrast`（`#000000`）である

---

### TC-303: 高コントラストテーマのElevatedButtonボーダーが2px以上である

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-303 |
| **テストケース名** | 高コントラストテーマのElevatedButtonボーダーが2px以上である |
| **テストファイル** | `test/core/themes/high_contrast_theme_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `highContrastTheme`がインポートされている

**実行手順**:
1. `highContrastTheme.elevatedButtonTheme.style`の`side`プロパティを検証する

**期待結果**:
- ボーダー幅が2.0px以上である
- ボーダー色が黒（`Colors.black`）である

---

### TC-304: 高コントラストテーマのInputFieldボーダーが2px以上である

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-304 |
| **テストケース名** | 高コントラストテーマのInputFieldボーダーが2px以上である |
| **テストファイル** | `test/core/themes/high_contrast_theme_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `highContrastTheme`がインポートされている

**実行手順**:
1. `highContrastTheme.inputDecorationTheme`の`enabledBorder`プロパティを検証する

**期待結果**:
- enabledBorderのボーダー幅が2.0px以上である
- ボーダー色が黒（`Colors.black`）である

---

### TC-305: 高コントラストテーマのElevatedButton最小サイズが60pxである

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-305 |
| **テストケース名** | 高コントラストテーマのElevatedButton最小サイズが60pxである |
| **テストファイル** | `test/core/themes/high_contrast_theme_test.dart` |
| **優先度** | 中 |
| **信頼性** | 🔵 |

**前提条件**:
- `highContrastTheme`がインポートされている

**実行手順**:
1. `highContrastTheme.elevatedButtonTheme.style`の`minimumSize`プロパティを検証する

**期待結果**:
- minimumSizeが`Size(60.0, 60.0)`である

---

### TC-306: 高コントラストテーマのIconButton最小サイズが44pxである

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-306 |
| **テストケース名** | 高コントラストテーマのIconButton最小サイズが44pxである |
| **テストファイル** | `test/core/themes/high_contrast_theme_test.dart` |
| **優先度** | 中 |
| **信頼性** | 🔵 |

**前提条件**:
- `highContrastTheme`がインポートされている

**実行手順**:
1. `highContrastTheme.iconButtonTheme.style`の`minimumSize`プロパティを検証する

**期待結果**:
- minimumSizeが`Size(44.0, 44.0)`である

---

## 6. WCAG準拠（コントラスト比）のテストケース

### TC-401: 高コントラストテーマのテキスト/背景コントラスト比が4.5:1以上である

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-401 |
| **テストケース名** | 高コントラストテーマのテキスト/背景コントラスト比が4.5:1以上である |
| **テストファイル** | `test/core/themes/high_contrast_theme_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `highContrastTheme`がインポートされている
- コントラスト比計算関数が実装されている

**実行手順**:
1. 背景色（`scaffoldBackgroundColor`）を取得する
2. テキスト色（`textTheme.bodyLarge.color`）を取得する
3. WCAG 2.1のコントラスト比計算式で比率を算出する
4. 計算結果が4.5以上であることを検証する

**期待結果**:
- コントラスト比が4.5:1以上である（実際は21:1）
- WCAG 2.1 AAレベルの要件を満たす

**コントラスト比計算式**:
```
contrast_ratio = (L1 + 0.05) / (L2 + 0.05)
```
ここで L1 は明るい色の相対輝度、L2 は暗い色の相対輝度。

---

### TC-402: 高コントラストテーマのボタン背景/テキストコントラスト比が4.5:1以上である

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-402 |
| **テストケース名** | 高コントラストテーマのボタン背景/テキストコントラスト比が4.5:1以上である |
| **テストファイル** | `test/core/themes/high_contrast_theme_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `highContrastTheme`がインポートされている
- コントラスト比計算関数が実装されている

**実行手順**:
1. ボタン背景色（`elevatedButtonTheme.style.backgroundColor`）を取得する
2. ボタンテキスト色（`elevatedButtonTheme.style.foregroundColor`）を取得する
3. コントラスト比を算出する
4. 計算結果が4.5以上であることを検証する

**期待結果**:
- コントラスト比が4.5:1以上である（白背景に黒テキストで21:1）
- WCAG 2.1 AAレベルの要件を満たす

---

### TC-403: 高コントラストテーマのボーダー/背景コントラスト比が3:1以上である

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-403 |
| **テストケース名** | 高コントラストテーマのボーダー/背景コントラスト比が3:1以上である |
| **テストファイル** | `test/core/themes/high_contrast_theme_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `highContrastTheme`がインポートされている
- コントラスト比計算関数が実装されている

**実行手順**:
1. 背景色（`scaffoldBackgroundColor`）を取得する
2. ボーダー色（`colorScheme.outline`）を取得する
3. コントラスト比を算出する
4. 計算結果が3.0以上であることを検証する

**期待結果**:
- コントラスト比が3:1以上である（UIコンポーネント要件）
- WCAG 2.1 AA UIコンポーネント要件を満たす

---

### TC-404: ライトテーマのテキスト/背景コントラスト比検証

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-404 |
| **テストケース名** | ライトテーマのテキスト/背景コントラスト比検証 |
| **テストファイル** | `test/core/themes/light_theme_test.dart` |
| **優先度** | 中 |
| **信頼性** | 🔵 |

**前提条件**:
- `lightTheme`がインポートされている
- コントラスト比計算関数が実装されている

**実行手順**:
1. 背景色（`scaffoldBackgroundColor`）を取得する
2. テキスト色（`textTheme.bodyLarge.color`）を取得する
3. コントラスト比を算出する

**期待結果**:
- コントラスト比が算出される（白背景に黒テキストで21:1）
- 通常のWCAGコントラスト要件を満たす

---

### TC-405: ダークテーマのテキスト/背景コントラスト比検証

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-405 |
| **テストケース名** | ダークテーマのテキスト/背景コントラスト比検証 |
| **テストファイル** | `test/core/themes/dark_theme_test.dart` |
| **優先度** | 中 |
| **信頼性** | 🔵 |

**前提条件**:
- `darkTheme`がインポートされている
- コントラスト比計算関数が実装されている

**実行手順**:
1. 背景色（`scaffoldBackgroundColor`）を取得する
2. テキスト色（`textTheme.bodyLarge.color`）を取得する
3. コントラスト比を算出する

**期待結果**:
- コントラスト比が算出される（暗い灰色背景に白テキスト）
- 通常の読みやすさ要件を満たす

---

## 7. アクセシビリティ要件のテストケース

### TC-501: 全テーマでElevatedButtonの最小サイズが60px以上である

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-501 |
| **テストケース名** | 全テーマでElevatedButtonの最小サイズが60px以上である |
| **テストファイル** | `test/core/themes/theme_accessibility_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `lightTheme`、`darkTheme`、`highContrastTheme`がインポートされている

**実行手順**:
1. 各テーマの`elevatedButtonTheme.style.minimumSize`を取得する
2. すべてのテーマで60px × 60px以上であることを検証する

**期待結果**:
- `lightTheme.elevatedButtonTheme.style.minimumSize` >= 60px × 60px
- `darkTheme.elevatedButtonTheme.style.minimumSize` >= 60px × 60px
- `highContrastTheme.elevatedButtonTheme.style.minimumSize` >= 60px × 60px

---

### TC-502: 全テーマでIconButtonの最小サイズが44px以上である

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-502 |
| **テストケース名** | 全テーマでIconButtonの最小サイズが44px以上である |
| **テストファイル** | `test/core/themes/theme_accessibility_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `lightTheme`、`darkTheme`、`highContrastTheme`がインポートされている

**実行手順**:
1. 各テーマの`iconButtonTheme.style.minimumSize`を取得する
2. すべてのテーマで44px × 44px以上であることを検証する

**期待結果**:
- `lightTheme.iconButtonTheme.style.minimumSize` >= 44px × 44px
- `darkTheme.iconButtonTheme.style.minimumSize` >= 44px × 44px
- `highContrastTheme.iconButtonTheme.style.minimumSize` >= 44px × 44px

---

### TC-503: 全テーマで同じフォントサイズが使用されている

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-503 |
| **テストケース名** | 全テーマで同じフォントサイズが使用されている |
| **テストファイル** | `test/core/themes/theme_accessibility_test.dart` |
| **優先度** | 中 |
| **信頼性** | 🔵 |

**前提条件**:
- `lightTheme`、`darkTheme`、`highContrastTheme`がインポートされている

**実行手順**:
1. 各テーマの`textTheme.bodyMedium.fontSize`を取得する
2. すべてのテーマで同じフォントサイズであることを検証する

**期待結果**:
- 全テーマで`bodyMedium`のフォントサイズが`AppSizes.fontSizeMedium`（20px）である
- テーマ間でフォントサイズの一貫性が保たれている

---

### TC-504: AppSizes定数のタップターゲット最小サイズが44px以上である

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-504 |
| **テストケース名** | AppSizes定数のタップターゲット最小サイズが44px以上である |
| **テストファイル** | `test/core/constants/app_sizes_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `AppSizes`がインポートされている

**実行手順**:
1. `AppSizes.minTapTarget`の値を検証する

**期待結果**:
- `AppSizes.minTapTarget`が44.0以上である
- WCAG 2.1のタップターゲット最小サイズ要件を満たす

---

### TC-505: AppSizes定数の推奨タップターゲットサイズが60px以上である

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-505 |
| **テストケース名** | AppSizes定数の推奨タップターゲットサイズが60px以上である |
| **テストファイル** | `test/core/constants/app_sizes_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `AppSizes`がインポートされている

**実行手順**:
1. `AppSizes.recommendedTapTarget`の値を検証する

**期待結果**:
- `AppSizes.recommendedTapTarget`が60.0以上である
- アクセシビリティ推奨サイズ要件を満たす

---

### TC-506: フォントサイズ定数が小(16px)・中(20px)・大(24px)である

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-506 |
| **テストケース名** | フォントサイズ定数が小(16px)・中(20px)・大(24px)である |
| **テストファイル** | `test/core/constants/app_sizes_test.dart` |
| **優先度** | 中 |
| **信頼性** | 🔵 |

**前提条件**:
- `AppSizes`がインポートされている

**実行手順**:
1. `AppSizes.fontSizeSmall`、`fontSizeMedium`、`fontSizeLarge`の値を検証する

**期待結果**:
- `AppSizes.fontSizeSmall` = 16.0
- `AppSizes.fontSizeMedium` = 20.0
- `AppSizes.fontSizeLarge` = 24.0

---

## 8. 統合テストケース

### TC-601: 設定プロバイダーとテーマプロバイダーの連携

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-601 |
| **テストケース名** | 設定プロバイダーとテーマプロバイダーの連携 |
| **テストファイル** | `test/core/themes/theme_integration_test.dart` |
| **優先度** | 高 |
| **信頼性** | 🔵 |

**前提条件**:
- `settingsNotifierProvider`と`currentThemeProvider`が連携するよう実装されている

**実行手順**:
1. `ProviderContainer`を作成する
2. `settingsNotifierProvider`でテーマを変更する
3. `currentThemeProvider`の値が連動して変更されることを確認する

**期待結果**:
- `settingsNotifierProvider`のテーマ変更が`currentThemeProvider`に反映される
- 両プロバイダーが正しく連携している

---

### TC-602: テーマ変更がMaterialAppに反映される（ウィジェットテスト）

| 項目 | 内容 |
|------|------|
| **テストケースID** | TC-602 |
| **テストケース名** | テーマ変更がMaterialAppに反映される |
| **テストファイル** | `test/core/themes/theme_widget_test.dart` |
| **優先度** | 中 |
| **信頼性** | 🔵 |

**前提条件**:
- ウィジェットテスト環境が設定されている
- `ProviderScope`でラップされた`MaterialApp`がある

**実行手順**:
1. ウィジェットツリーを構築する
2. 初期テーマを確認する
3. テーマを変更する
4. ウィジェットツリーが再構築され、新しいテーマが適用されることを確認する

**期待結果**:
- テーマ変更後にウィジェットが新しいテーマで再描画される
- 背景色、テキスト色などが変更される

---

## テストケースサマリー

### カテゴリ別テストケース数

| カテゴリ | テストケース数 | 優先度高 | 優先度中 |
|----------|---------------|---------|---------|
| テーマプロバイダー | 7 | 6 | 1 |
| ライトテーマ | 5 | 2 | 3 |
| ダークテーマ | 5 | 3 | 2 |
| 高コントラストテーマ | 6 | 4 | 2 |
| WCAG準拠 | 5 | 3 | 2 |
| アクセシビリティ | 6 | 4 | 2 |
| 統合テスト | 2 | 1 | 1 |
| **合計** | **36** | **23** | **13** |

### テストファイル一覧

| テストファイル | 対象テストケース |
|---------------|-----------------|
| `test/core/themes/theme_provider_test.dart` | TC-001 ~ TC-007 |
| `test/core/themes/light_theme_test.dart` | TC-101 ~ TC-105, TC-404 |
| `test/core/themes/dark_theme_test.dart` | TC-201 ~ TC-205, TC-405 |
| `test/core/themes/high_contrast_theme_test.dart` | TC-301 ~ TC-306, TC-401 ~ TC-403 |
| `test/core/themes/theme_accessibility_test.dart` | TC-501 ~ TC-503 |
| `test/core/constants/app_sizes_test.dart` | TC-504 ~ TC-506 |
| `test/core/themes/theme_integration_test.dart` | TC-601 |
| `test/core/themes/theme_widget_test.dart` | TC-602 |

---

## 実装優先順位

### Phase 1: テーマプロバイダー実装（必須）

1. **TC-001**: 初期状態でライトテーマが返される
2. **TC-002**: 設定がlightの場合、lightThemeが返される
3. **TC-003**: 設定がdarkの場合、darkThemeが返される
4. **TC-004**: 設定がhighContrastの場合、highContrastThemeが返される
5. **TC-005**: テーマ設定変更時にプロバイダーが即座に更新される

### Phase 2: 各テーマ検証（必須）

1. **TC-101, TC-102**: ライトテーマの基本プロパティ
2. **TC-201, TC-202, TC-203**: ダークテーマの基本プロパティ
3. **TC-301, TC-302, TC-303, TC-304**: 高コントラストテーマの基本プロパティ

### Phase 3: WCAG準拠検証（必須）

1. **TC-401**: 高コントラストテーマのコントラスト比4.5:1以上
2. **TC-402, TC-403**: ボタン・ボーダーのコントラスト比

### Phase 4: アクセシビリティ検証（推奨）

1. **TC-501, TC-502**: タップターゲットサイズ
2. **TC-504, TC-505**: AppSizes定数検証

### Phase 5: 統合テスト・その他（推奨）

1. **TC-601**: プロバイダー連携
2. **TC-602**: ウィジェットテスト
3. その他の中優先度テストケース

---

## 更新履歴

| 日付 | バージョン | 変更内容 |
|------|-----------|----------|
| 2025-11-22 | 1.0 | 初版作成 |
