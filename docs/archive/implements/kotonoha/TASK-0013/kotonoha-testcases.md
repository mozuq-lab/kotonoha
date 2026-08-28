# TDDテストケース定義 - TASK-0013: Riverpod状態管理セットアップ・プロバイダー基盤実装

## タスク情報

- **タスクID**: TASK-0013
- **タスク名**: Riverpod状態管理セットアップ・プロバイダー基盤実装
- **タスクタイプ**: TDD
- **推定工数**: 8時間
- **フェーズ**: Phase 1 - Week 3, Day 13
- **依存タスク**: TASK-0012 (Flutter依存パッケージ追加・pubspec.yaml設定)

## 関連文書

- **TDD要件定義書**: [kotonoha-requirements.md](./kotonoha-requirements.md)
- **EARS要件定義書**: [docs/spec/kotonoha-requirements.md](../../spec/kotonoha-requirements.md)
- **TypeScript型定義**: [docs/design/kotonoha/interfaces.dart](../../design/kotonoha/interfaces.dart)

---

## 開発言語・フレームワーク

### プログラミング言語: Dart / Flutter

- **言語選択の理由**: 🔵
  - EARS要件定義書・architecture.mdで「Flutter 3.38.1」が明示されている
  - クロスプラットフォーム対応（iOS 14.0+、Android 10+、Web）が要件
  - Null Safety対応で型安全性が高い

- **テストに適した機能**: 🔵
  - `flutter_test`パッケージによる包括的なテストフレームワーク
  - `flutter_riverpod`のテスタビリティ（ProviderContainer使用）
  - モックライブラリ（mocktail）との親和性が高い
  - ホットリロードによる高速な開発サイクル

### テストフレームワーク: flutter_test + Riverpod Testing

- **フレームワーク選択の理由**: 🔵
  - Flutter公式テストフレームワーク（flutter_test）
  - Riverpod公式のテストユーティリティ（ProviderContainer）
  - SharedPreferencesのモック化が容易（shared_preferences_test）

- **テスト実行環境**: 🔵
  - ローカル開発環境: `flutter test`コマンド
  - CI/CD環境: GitHub Actions（`.github/workflows/flutter.yml`）
  - カバレッジ計測: `flutter test --coverage`
  - 目標カバレッジ: 80%以上（NFR-501）

---

## テストケース分類

### 1. 正常系テストケース（基本的な動作）

#### TC-001: SettingsNotifierの初期状態確認

- **テスト名**: 「SettingsNotifierの初期状態がデフォルト値（medium、light）であることを確認」
  - **何をテストするか**: SettingsNotifierが初回ビルド時に正しいデフォルト値を返すこと
  - **期待される動作**: SharedPreferencesに保存データがない場合、`fontSize: FontSize.medium`、`themeMode: AppTheme.light`が設定される

- **入力値**:
  - SharedPreferences: 空（保存データなし）
  - **入力データの意味**: アプリ初回起動時の状態を模擬
  - **実際の使用場面**: ユーザーがアプリを初めて起動したとき

- **期待される結果**:
  - `state.value.fontSize == FontSize.medium`
  - `state.value.themeMode == AppTheme.light`
  - **期待結果の理由**: REQ-801、REQ-803で「中サイズ」「ライトモード」がデフォルトとして妥当

- **テストの目的**:
  - 初期状態の整合性確認
  - **確認ポイント**: デフォルト値がinterfaces.dartの定義と一致すること

- 🔵 **信頼性レベル**: 青信号（要件定義書・interfaces.dartのデフォルト値に基づく）

---

#### TC-002: フォントサイズ変更（small）

- **テスト名**: 「setFontSize(FontSize.small)でフォントサイズが「小」に変更されることを確認」
  - **何をテストするか**: フォントサイズを「小」に変更し、状態が正しく更新されること
  - **期待される動作**: `setFontSize(FontSize.small)`呼び出し後、stateが更新され、SharedPreferencesに永続化される

- **入力値**:
  - `FontSize.small`
  - **入力データの意味**: REQ-801で定義された3段階のうち最小サイズ
  - **実際の使用場面**: 視力が良く、画面を広く使いたいユーザーが「小」を選択

- **期待される結果**:
  - `state.value.fontSize == FontSize.small`
  - SharedPreferencesに`'fontSize' = 0`（small.index）が保存される
  - **期待結果の理由**: 設定変更が即座に反映され、再起動後も保持される必要がある（REQ-2007、REQ-5003）

- **テストの目的**:
  - フォントサイズ変更機能の動作確認
  - **確認ポイント**: 状態更新とSharedPreferences永続化が両方成功すること

- 🔵 **信頼性レベル**: 青信号（REQ-801の3段階選択要件に基づく）

---

#### TC-003: フォントサイズ変更（medium）

- **テスト名**: 「setFontSize(FontSize.medium)でフォントサイズが「中」に変更されることを確認」
  - **何をテストするか**: フォントサイズを「中」に変更し、状態が正しく更新されること
  - **期待される動作**: デフォルト値への明示的な変更も正常動作すること

- **入力値**:
  - `FontSize.medium`
  - **入力データの意味**: REQ-801で定義された標準サイズ
  - **実際の使用場面**: ユーザーが一度「大」に変更した後、「中」に戻す操作

- **期待される結果**:
  - `state.value.fontSize == FontSize.medium`
  - SharedPreferencesに`'fontSize' = 1`（medium.index）が保存される

- **テストの目的**:
  - デフォルト値への明示的な変更が正常動作することを確認
  - **確認ポイント**: 任意の値から任意の値への変更が可能

- 🔵 **信頼性レベル**: 青信号

---

#### TC-004: フォントサイズ変更（large）

- **テスト名**: 「setFontSize(FontSize.large)でフォントサイズが「大」に変更されることを確認」
  - **何をテストするか**: フォントサイズを「大」に変更し、状態が正しく更新されること
  - **期待される動作**: 最大サイズへの変更が正常動作すること

- **入力値**:
  - `FontSize.large`
  - **入力データの意味**: REQ-801で定義された最大サイズ
  - **実際の使用場面**: 視力が弱い高齢者・視覚障害者が「大」を選択

- **期待される結果**:
  - `state.value.fontSize == FontSize.large`
  - SharedPreferencesに`'fontSize' = 2`（large.index）が保存される

- **テストの目的**:
  - 最大フォントサイズへの変更確認
  - **確認ポイント**: アクセシビリティ対応として最も重要なサイズ

- 🔵 **信頼性レベル**: 青信号

---

#### TC-005: テーマモード変更（light）

- **テスト名**: 「setThemeMode(AppTheme.light)でテーマが「ライトモード」に変更されることを確認」
  - **何をテストするか**: テーマモードを「ライトモード」に変更し、状態が正しく更新されること
  - **期待される動作**: `setThemeMode(AppTheme.light)`呼び出し後、stateが更新され、SharedPreferencesに永続化される

- **入力値**:
  - `AppTheme.light`
  - **入力データの意味**: REQ-803で定義された標準テーマ
  - **実際の使用場面**: 明るい環境でアプリを使用するユーザー

- **期待される結果**:
  - `state.value.themeMode == AppTheme.light`
  - SharedPreferencesに`'themeMode' = 0`（light.index）が保存される

- **テストの目的**:
  - テーマモード変更機能の動作確認
  - **確認ポイント**: REQ-2008（テーマ即座変更）の基盤確認

- 🔵 **信頼性レベル**: 青信号

---

#### TC-006: テーマモード変更（dark）

- **テスト名**: 「setThemeMode(AppTheme.dark)でテーマが「ダークモード」に変更されることを確認」
  - **何をテストするか**: テーマモードを「ダークモード」に変更し、状態が正しく更新されること
  - **期待される動作**: 暗い環境向けのテーマが適用される

- **入力値**:
  - `AppTheme.dark`
  - **入力データの意味**: REQ-803で定義されたダークモード
  - **実際の使用場面**: 夜間や暗い環境でアプリを使用するユーザー

- **期待される結果**:
  - `state.value.themeMode == AppTheme.dark`
  - SharedPreferencesに`'themeMode' = 1`（dark.index）が保存される

- **テストの目的**:
  - ダークモード切り替え確認
  - **確認ポイント**: 目への負担軽減のための重要機能

- 🔵 **信頼性レベル**: 青信号

---

#### TC-007: テーマモード変更（highContrast）

- **テスト名**: 「setThemeMode(AppTheme.highContrast)でテーマが「高コントラストモード」に変更されることを確認」
  - **何をテストするか**: テーマモードを「高コントラストモード」に変更し、状態が正しく更新されること
  - **期待される動作**: 視認性が最も高いテーマが適用される

- **入力値**:
  - `AppTheme.highContrast`
  - **入力データの意味**: REQ-803、REQ-5006で定義されたWCAG 2.1 AA準拠テーマ
  - **実際の使用場面**: 強い視覚障害のあるユーザー、明るい屋外環境

- **期待される結果**:
  - `state.value.themeMode == AppTheme.highContrast`
  - SharedPreferencesに`'themeMode' = 2`（highContrast.index）が保存される

- **テストの目的**:
  - 高コントラストモード切り替え確認
  - **確認ポイント**: アクセシビリティの最重要機能

- 🔵 **信頼性レベル**: 青信号

---

#### TC-008: アプリ再起動後の設定復元（フォントサイズ）

- **テスト名**: 「アプリ再起動後、保存されたフォントサイズ設定が正しく復元されることを確認」
  - **何をテストするか**: SharedPreferencesに保存されたフォントサイズが再起動後も復元されること
  - **期待される動作**: `build()`メソッドがSharedPreferencesから設定を読み込み、前回の設定を復元する

- **入力値**:
  - SharedPreferencesに事前保存: `'fontSize' = 2`（large）
  - **入力データの意味**: 前回のアプリセッションでユーザーが「大」を選択していた状態
  - **実際の使用場面**: アプリを終了し、翌日再度起動したとき

- **期待される結果**:
  - 新しいProviderContainer作成後、`state.value.fontSize == FontSize.large`
  - **期待結果の理由**: REQ-5003（設定永続化）の要件を満たすため

- **テストの目的**:
  - データ永続化の確認
  - **確認ポイント**: SharedPreferences読み込みロジックが正常動作すること

- 🔵 **信頼性レベル**: 青信号（REQ-5003の永続化要件に基づく）

---

#### TC-009: アプリ再起動後の設定復元（テーマモード）

- **テスト名**: 「アプリ再起動後、保存されたテーマモード設定が正しく復元されることを確認」
  - **何をテストするか**: SharedPreferencesに保存されたテーマモードが再起動後も復元されること
  - **期待される動作**: ダークモードで終了したアプリが再起動時にもダークモードで開く

- **入力値**:
  - SharedPreferencesに事前保存: `'themeMode' = 1`（dark）
  - **入力データの意味**: 前回のセッションでダークモードを選択していた状態
  - **実際の使用場面**: 夜間にアプリを使用し、翌朝再起動したとき

- **期待される結果**:
  - 新しいProviderContainer作成後、`state.value.themeMode == AppTheme.dark`

- **テストの目的**:
  - テーマモード永続化の確認
  - **確認ポイント**: ユーザー体験の一貫性維持

- 🔵 **信頼性レベル**: 青信号

---

#### TC-010: 複数設定の同時変更

- **テスト名**: 「フォントサイズとテーマモードを連続して変更した場合、両方が正しく保存・復元されることを確認」
  - **何をテストするか**: 複数設定を連続変更しても、すべて正しく永続化されること
  - **期待される動作**: `setFontSize(FontSize.large)`と`setThemeMode(AppTheme.dark)`を連続実行し、両方が保存される

- **入力値**:
  - 1. `setFontSize(FontSize.large)`
  - 2. `setThemeMode(AppTheme.dark)`
  - **入力データの意味**: ユーザーが設定画面で複数の項目を変更する実際の操作
  - **実際の使用場面**: 夜間使用のため「大・ダーク」に設定変更

- **期待される結果**:
  - `state.value.fontSize == FontSize.large`
  - `state.value.themeMode == AppTheme.dark`
  - SharedPreferencesに両方の値が保存されている

- **テストの目的**:
  - 複数設定の独立性確認
  - **確認ポイント**: 一方の変更が他方に影響しないこと

- 🔵 **信頼性レベル**: 青信号

---

### 2. 異常系テストケース（エラーハンドリング）

#### TC-011: SharedPreferences初期化失敗時のエラーハンドリング

- **テスト名**: 「SharedPreferences.getInstance()が失敗した場合、AsyncValue.errorを返すことを確認」
  - **エラーケースの概要**: SharedPreferencesの初期化に失敗する状況（モック化してエラーをスロー）
  - **エラー処理の重要性**: NFR-301（重大エラー時も基本機能継続）のため、デフォルト値で継続動作が必要

- **入力値**:
  - SharedPreferences.getInstance()がExceptionをスロー
  - **不正な理由**: 端末のストレージ障害、権限エラーなど
  - **実際の発生シナリオ**: ストレージ容量不足、OSバージョン非互換、権限エラー

- **期待される結果**:
  - `state is AsyncError`
  - または、デフォルト値（medium、light）でAsyncValue.dataを返す（フォールバック）
  - **エラーメッセージの内容**: 「設定の読み込みに失敗しました」（NFR-204: 分かりやすい日本語）
  - **システムの安全性**: エラー発生でもアプリがクラッシュせず、デフォルト設定で動作継続

- **テストの目的**:
  - エラーハンドリングの確認
  - **品質保証の観点**: NFR-301（基本機能継続）を満たすこと

- 🟡 **信頼性レベル**: 黄信号（NFR-301、NFR-304のエラーハンドリング要件から類推）

---

#### TC-012: SharedPreferences書き込み失敗時の楽観的更新

- **テスト名**: 「setFontSize()でSharedPreferences書き込みが失敗しても、状態更新は成功することを確認」
  - **エラーケースの概要**: `setInt()`が失敗しても、Riverpod stateは更新される（楽観的更新）
  - **エラー処理の重要性**: UI反応性を維持しつつ、再起動時は古い設定に戻る可能性をユーザーに通知

- **入力値**:
  - `setFontSize(FontSize.large)`
  - SharedPreferences.setInt()がfalseを返す（失敗）
  - **不正な理由**: ストレージ書き込み権限エラー、容量不足
  - **実際の発生シナリオ**: ストレージ満杯、アプリが読み取り専用モードで動作

- **期待される結果**:
  - `state.value.fontSize == FontSize.large`（状態は更新される）
  - ログに警告メッセージ記録（`AppLogger.warning()`）
  - **エラーメッセージの内容**: 「設定の保存に失敗しました。次回起動時は以前の設定に戻る可能性があります」
  - **システムの安全性**: UIがフリーズせず、ユーザー操作は継続可能

- **テストの目的**:
  - 楽観的更新の動作確認
  - **品質保証の観点**: NFR-2007（即座反映）とNFR-304（エラーハンドリング）の両立

- 🟡 **信頼性レベル**: 黄信号（楽観的更新は一般的パターンだが、要件定義書に明示されていない）

---

#### TC-013: 不正なenum index値がSharedPreferencesに保存されている場合のフォールバック

- **テスト名**: 「SharedPreferencesに不正なenum index（範囲外の整数）が保存されている場合、デフォルト値にフォールバックすることを確認」
  - **エラーケースの概要**: `getInt('fontSize')`が99など範囲外の値を返す（データ破損）
  - **エラー処理の重要性**: データ破損時もアプリがクラッシュせず、安全に動作継続

- **入力値**:
  - SharedPreferences: `'fontSize' = 99`（FontSize.values[99]は存在しない）
  - **不正な理由**: データ破損、手動編集、アプリバージョン間の不整合
  - **実際の発生シナリオ**: OSアップデート時のデータ移行エラー、開発時の不具合

- **期待される結果**:
  - `state.value.fontSize == FontSize.medium`（デフォルト値）
  - ログにエラーメッセージ記録（`AppLogger.error()`）
  - **エラーメッセージの内容**: 「無効な設定値を検出しました。デフォルト値を使用します」
  - **システムの安全性**: RangeErrorをキャッチし、デフォルト値で継続動作

- **テストの目的**:
  - データ破損時の堅牢性確認
  - **品質保証の観点**: NFR-304（データベースエラー時の適切なエラーハンドリング）の類推

- 🟡 **信頼性レベル**: 黄信号（データ破損対応は推測を含む）

---

#### TC-014: SharedPreferencesがnullを返す場合のデフォルト値使用

- **テスト名**: 「SharedPreferences.getInt()がnullを返す場合、デフォルト値（medium、light）を使用することを確認」
  - **エラーケースの概要**: 保存データが存在しない（初回起動と同じ状態）
  - **エラー処理の重要性**: null安全性の確認、Dart Null Safetyへの準拠

- **入力値**:
  - SharedPreferences: `getInt('fontSize') == null`
  - **不正な理由**: 正常なケース（初回起動、データ削除後）
  - **実際の発生シナリオ**: アプリ初回起動、アンインストール後の再インストール

- **期待される結果**:
  - `state.value.fontSize == FontSize.medium`
  - `state.value.themeMode == AppTheme.light`
  - **期待結果の理由**: Dart Null Safetyで`??`演算子によるデフォルト値提供

- **テストの目的**:
  - Null安全性の確認
  - **品質保証の観点**: 型安全性の保証

- 🔵 **信頼性レベル**: 青信号（Dart Null Safetyの基本動作）

---

### 3. 境界値テストケース（最小値、最大値、null等）

#### TC-015: FontSize enumの全値テスト（small, medium, large）

- **テスト名**: 「FontSize enumのすべての値（small=0, medium=1, large=2）が正しくSharedPreferencesに保存・復元されることを確認」
  - **境界値の意味**: enum indexの最小値（0）から最大値（2）までをすべてテスト
  - **境界値での動作保証**: 3段階すべてが正常動作することを確認

- **入力値**:
  - `FontSize.small`（index=0）
  - `FontSize.medium`（index=1）
  - `FontSize.large`（index=2）
  - **境界値選択の根拠**: REQ-801で定義された3段階がすべて
  - **実際の使用場面**: ユーザーがすべての選択肢を試す

- **期待される結果**:
  - 各値が正しくSharedPreferencesに保存される
  - 各値が正しく復元される
  - **境界での正確性**: index 0, 1, 2がすべて正常動作
  - **一貫した動作**: どの値でも同じ品質で動作

- **テストの目的**:
  - 全選択肢の網羅的確認
  - **堅牢性の確認**: enum境界値の安全性

- 🔵 **信頼性レベル**: 青信号

---

#### TC-016: AppTheme enumの全値テスト（light, dark, highContrast）

- **テスト名**: 「AppTheme enumのすべての値（light=0, dark=1, highContrast=2）が正しくSharedPreferencesに保存・復元されることを確認」
  - **境界値の意味**: enum indexの最小値（0）から最大値（2）まで
  - **境界値での動作保証**: 3種類すべてが正常動作することを確認

- **入力値**:
  - `AppTheme.light`（index=0）
  - `AppTheme.dark`（index=1）
  - `AppTheme.highContrast`（index=2）
  - **境界値選択の根拠**: REQ-803で定義された3種類がすべて
  - **実際の使用場面**: 異なる環境・ユーザーがすべてのテーマを試す

- **期待される結果**:
  - 各値が正しくSharedPreferencesに保存される
  - 各値が正しく復元される

- **テストの目的**:
  - 全テーマの網羅的確認
  - **堅牢性の確認**: WCAG準拠含むすべてのテーマが動作

- 🔵 **信頼性レベル**: 青信号

---

#### TC-017: SharedPreferences書き込み成功・失敗の境界確認

- **テスト名**: 「SharedPreferences.setInt()が成功（true）と失敗（false）の両方のケースで正しく動作することを確認」
  - **境界値の意味**: bool型の境界値（true/false）
  - **境界値での動作保証**: 成功時と失敗時で適切に処理が分岐すること

- **入力値**:
  - ケース1: setInt()がtrueを返す（成功）
  - ケース2: setInt()がfalseを返す（失敗）
  - **境界値選択の根拠**: SharedPreferencesの戻り値仕様
  - **実際の使用場面**: 正常時と異常時の両方

- **期待される結果**:
  - 成功時: ログなし、状態更新のみ
  - 失敗時: 警告ログ出力、状態は更新される（楽観的更新）
  - **境界での正確性**: true/falseで適切に処理分岐
  - **一貫した動作**: どちらでもアプリがクラッシュしない

- **テストの目的**:
  - bool境界値の処理確認
  - **堅牢性の確認**: 成功・失敗両方で安全動作

- 🟡 **信頼性レベル**: 黄信号（楽観的更新は推測を含む）

---

#### TC-018: AsyncValue状態遷移の確認（loading → data / error）

- **テスト名**: 「SettingsNotifierのbuild()がAsyncValue.loading → AsyncValue.dataに遷移することを確認」
  - **境界値の意味**: AsyncValueの状態遷移の境界
  - **境界値での動作保証**: 非同期処理が正しく完了すること

- **入力値**:
  - build()メソッド実行
  - SharedPreferencesの非同期読み込み
  - **境界値選択の根拠**: Riverpod AsyncNotifierの標準動作
  - **実際の使用場面**: アプリ起動時のProvider初期化

- **期待される結果**:
  - 初期状態: `state is AsyncLoading`（または即座にdata）
  - 完了後: `state is AsyncData<AppSettings>`
  - エラー時: `state is AsyncError`
  - **境界での正確性**: 状態遷移が正しい順序で発生
  - **一貫した動作**: どのタイミングでも状態が明確

- **テストの目的**:
  - 非同期処理の状態管理確認
  - **堅牢性の確認**: AsyncValueの適切な使用

- 🔵 **信頼性レベル**: 青信号（Riverpod公式パターン）

---

#### TC-019: ProviderContainer破棄時のリソース解放確認

- **テスト名**: 「ProviderContainerをdisposeした後、再度新しいContainerで初期化してもリソースリークが発生しないことを確認」
  - **境界値の意味**: Providerライフサイクルの境界（作成・破棄）
  - **境界値での動作保証**: メモリリークがないこと

- **入力値**:
  - 1. ProviderContainer作成 → 使用 → dispose
  - 2. 新しいProviderContainer作成 → 使用
  - **境界値選択の根拠**: Flutterアプリの画面遷移・再起動時の挙動
  - **実際の使用場面**: アプリのホットリスタート、画面遷移時のProvider再作成

- **期待される結果**:
  - dispose後、リソースが解放される
  - 新しいContainerが独立して動作する
  - メモリリークがない
  - **境界での正確性**: 複数回の作成・破棄が安全
  - **一貫した動作**: 何度実行しても同じ品質

- **テストの目的**:
  - リソース管理の確認
  - **堅牢性の確認**: メモリリーク防止

- 🟡 **信頼性レベル**: 黄信号（メモリリークテストは推測を含む）

---

## テストケース実装時の日本語コメント指針

### テストケース開始時のコメント

```dart
// 【テスト目的】: SettingsNotifierの初期状態がデフォルト値（medium、light）であることを確認
// 【テスト内容】: SharedPreferencesが空の状態でbuild()を実行し、デフォルト値が返されることを検証
// 【期待される動作】: fontSize=medium、themeMode=lightが設定される
// 🔵 青信号: REQ-801、REQ-803のデフォルト値要件に基づく
```

### Given（準備フェーズ）のコメント

```dart
// 【テストデータ準備】: SharedPreferencesをモック化し、空の状態（getInt()がnullを返す）を設定
// 【初期条件設定】: アプリ初回起動時の状態を模擬
// 【前提条件確認】: SharedPreferencesインスタンスが正しく初期化されていることを確認
```

### When（実行フェーズ）のコメント

```dart
// 【実際の処理実行】: ProviderContainerを作成し、settingsNotifierProviderをread
// 【処理内容】: build()メソッドが非同期でSharedPreferencesから設定を読み込む
// 【実行タイミング】: Provider初回アクセス時にbuild()が自動実行される
```

### Then（検証フェーズ）のコメント

```dart
// 【結果検証】: state.value.fontSizeがFontSize.mediumであることを確認
// 【期待値確認】: デフォルト値が正しく設定されている理由は、SharedPreferencesが空だから
// 【品質保証】: この検証によりREQ-801の要件（フォントサイズ3段階選択）の基盤が保証される
```

### 各expectステートメントのコメント

```dart
// 【検証項目】: フォントサイズがmediumであること
// 🔵 青信号: interfaces.dartのデフォルト値定義に基づく
expect(settings.fontSize, FontSize.medium); // 【確認内容】: デフォルト値が正しく設定されていることを確認

// 【検証項目】: テーマモードがlightであること
// 🔵 青信号: interfaces.dartのデフォルト値定義に基づく
expect(settings.themeMode, AppTheme.light); // 【確認内容】: デフォルト値が正しく設定されていることを確認
```

### セットアップ・クリーンアップのコメント

```dart
setUp(() async {
  // 【テスト前準備】: SharedPreferencesのモックを初期化
  // 【環境初期化】: 各テストが独立して実行できるよう、クリーンな状態から開始
  SharedPreferences.setMockInitialValues({});
});

tearDown(() {
  // 【テスト後処理】: ProviderContainerを破棄し、次のテストに影響しないようにする
  // 【状態復元】: メモリリークを防ぐため、リソースを解放
  container.dispose();
});
```

---

## テストケース実装例（サンプルコード）

### TC-001: SettingsNotifierの初期状態確認 - 実装例

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';

void main() {
  group('SettingsNotifier - 初期状態テスト', () {
    late ProviderContainer container;

    setUp(() async {
      // 【テスト前準備】: SharedPreferencesのモックを初期化（空の状態）
      // 【環境初期化】: アプリ初回起動時の状態を模擬
      SharedPreferences.setMockInitialValues({});

      // 【ProviderContainer作成】: テスト用のRiverpodコンテナを作成
      container = ProviderContainer();
    });

    tearDown(() {
      // 【テスト後処理】: ProviderContainerを破棄
      // 【状態復元】: メモリリークを防ぐため、リソースを解放
      container.dispose();
    });

    test('TC-001: 初期状態がデフォルト値（medium、light）であることを確認', () async {
      // 【テスト目的】: SettingsNotifierの初期状態がデフォルト値であることを確認
      // 【テスト内容】: SharedPreferencesが空の状態でbuild()を実行し、デフォルト値が返されることを検証
      // 【期待される動作】: fontSize=medium、themeMode=lightが設定される
      // 🔵 青信号: REQ-801、REQ-803のデフォルト値要件に基づく

      // Given（準備フェーズ）
      // 【テストデータ準備】: SharedPreferencesは空（setUpで設定済み）
      // 【初期条件設定】: アプリ初回起動時の状態
      // 【前提条件確認】: SharedPreferencesが空であることを確認

      // When（実行フェーズ）
      // 【実際の処理実行】: settingsNotifierProviderを読み込み
      // 【処理内容】: build()メソッドが非同期でSharedPreferencesから設定を読み込む
      // 【実行タイミング】: Provider初回アクセス時にbuild()が自動実行される
      final settingsAsync = container.read(settingsNotifierProvider);

      // 【非同期処理待機】: AsyncValueがdataになるまで待機
      final settings = await settingsAsync.future;

      // Then（検証フェーズ）
      // 【結果検証】: デフォルト値が正しく設定されていることを確認
      // 【期待値確認】: interfaces.dartで定義されたデフォルト値と一致
      // 【品質保証】: REQ-801、REQ-803の要件を満たすことを確認

      // 【検証項目】: フォントサイズがmediumであること
      // 🔵 青信号: interfaces.dartのデフォルト値定義に基づく
      expect(settings.fontSize, FontSize.medium); // 【確認内容】: デフォルト値が正しく設定されていることを確認

      // 【検証項目】: テーマモードがlightであること
      // 🔵 青信号: interfaces.dartのデフォルト値定義に基づく
      expect(settings.themeMode, AppTheme.light); // 【確認内容】: デフォルト値が正しく設定されていることを確認
    });
  });
}
```

---

## テストケース一覧サマリー

### 正常系テストケース（10件）

| ID | テスト名 | 信頼性 | 優先度 |
|----|---------|--------|--------|
| TC-001 | 初期状態がデフォルト値（medium、light）であることを確認 | 🔵 | 高 |
| TC-002 | setFontSize(small)でフォントサイズが「小」に変更 | 🔵 | 高 |
| TC-003 | setFontSize(medium)でフォントサイズが「中」に変更 | 🔵 | 中 |
| TC-004 | setFontSize(large)でフォントサイズが「大」に変更 | 🔵 | 高 |
| TC-005 | setThemeMode(light)でテーマが「ライトモード」に変更 | 🔵 | 高 |
| TC-006 | setThemeMode(dark)でテーマが「ダークモード」に変更 | 🔵 | 高 |
| TC-007 | setThemeMode(highContrast)でテーマが「高コントラストモード」に変更 | 🔵 | 高 |
| TC-008 | アプリ再起動後、フォントサイズ設定が復元される | 🔵 | 高 |
| TC-009 | アプリ再起動後、テーマモード設定が復元される | 🔵 | 高 |
| TC-010 | フォントサイズとテーマモードを連続変更しても両方が保存される | 🔵 | 中 |

### 異常系テストケース（4件）

| ID | テスト名 | 信頼性 | 優先度 |
|----|---------|--------|--------|
| TC-011 | SharedPreferences初期化失敗時のエラーハンドリング | 🟡 | 高 |
| TC-012 | SharedPreferences書き込み失敗時の楽観的更新 | 🟡 | 中 |
| TC-013 | 不正なenum index値がある場合のデフォルト値フォールバック | 🟡 | 中 |
| TC-014 | SharedPreferencesがnullを返す場合のデフォルト値使用 | 🔵 | 高 |

### 境界値テストケース（5件）

| ID | テスト名 | 信頼性 | 優先度 |
|----|---------|--------|--------|
| TC-015 | FontSize enumの全値（small, medium, large）テスト | 🔵 | 高 |
| TC-016 | AppTheme enumの全値（light, dark, highContrast）テスト | 🔵 | 高 |
| TC-017 | SharedPreferences書き込み成功・失敗の境界確認 | 🟡 | 中 |
| TC-018 | AsyncValue状態遷移の確認（loading → data / error） | 🔵 | 中 |
| TC-019 | ProviderContainer破棄時のリソース解放確認 | 🟡 | 低 |

### テストケース総数: 19件

- **正常系**: 10件
- **異常系**: 4件
- **境界値**: 5件
- **優先度 高**: 13件
- **優先度 中**: 5件
- **優先度 低**: 1件
- **信頼性 🔵（青信号）**: 14件
- **信頼性 🟡（黄信号）**: 5件

---

## 品質判定

### ✅ 高品質

- **テストケース分類**: 正常系・異常系・境界値が網羅されている ✅
  - 正常系: 基本動作、複数設定変更、永続化を網羅
  - 異常系: SharedPreferences失敗、データ破損を網羅
  - 境界値: enum全値、状態遷移、リソース管理を網羅

- **期待値定義**: 各テストケースの期待値が明確 ✅
  - すべてのテストケースで具体的な期待値を記載
  - 「なぜこの結果が正しいか」を明記
  - REQ-801、REQ-803、REQ-5003との対応関係が明確

- **技術選択**: プログラミング言語・テストフレームワークが確定 ✅
  - Dart / Flutter（architecture.md準拠）
  - flutter_test + Riverpod Testing（公式推奨）
  - shared_preferences_testでモック化対応

- **実装可能性**: 現在の技術スタックで実現可能 ✅
  - TASK-0012で依存パッケージ追加済み
  - Riverpod Generatorによるコード生成基盤あり
  - SharedPreferencesのモック化が標準サポート

### 改善点なし

すべての品質基準を満たしています。

---

## 次のステップ

### 推奨コマンド

次は `/tsumiki:tdd-red` でRedフェーズ（失敗テスト作成）を開始します。

### Redフェーズでの実装項目

1. **テストファイル作成**:
   - `frontend/kotonoha_app/test/features/settings/providers/settings_provider_test.dart`

2. **テストケース実装順序**（優先度順）:
   1. TC-001: 初期状態テスト（最重要）
   2. TC-002, TC-004: フォントサイズ変更（small, large）
   3. TC-005, TC-006, TC-007: テーマモード変更（全3種類）
   4. TC-008, TC-009: アプリ再起動後の復元テスト
   5. TC-015, TC-016: enum全値テスト
   6. TC-011, TC-014: エラーハンドリングテスト
   7. その他の境界値・複合テスト

3. **テスト実行確認**:
   - `flutter test test/features/settings/providers/settings_provider_test.dart`
   - すべてのテストが失敗することを確認（Redフェーズ）

---

## 更新履歴

- **2025-11-20**: TDDテストケース定義書作成（/tsumiki:tdd-testcasesにより生成）
  - 要件定義書（kotonoha-requirements.md）を参照
  - interfaces.dartのエンティティ定義を反映
  - 正常系10件、異常系4件、境界値5件の合計19件のテストケースを定義
  - 信頼性レベル（🔵🟡）を各テストケースに明記
  - 日本語コメント指針とサンプルコード実装例を追加
