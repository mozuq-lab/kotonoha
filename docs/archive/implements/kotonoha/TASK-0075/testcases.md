# TASK-0075: ヘルプ画面・初回チュートリアル - テストケース

## テスト概要

- **タスクID**: TASK-0075
- **総テストケース数**: 36件
- **テストファイル**:
  - `test/features/help/presentation/screens/help_screen_test.dart` (15件)
  - `test/features/help/presentation/widgets/help_section_widget_test.dart` (4件)
  - `test/features/help/presentation/widgets/tutorial_overlay_test.dart` (11件)
  - `test/features/help/providers/tutorial_provider_test.dart` (9件)

---

## 1. ヘルプ画面テスト（HelpScreen）

### 1.1 基本表示テスト

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-075-001 | ヘルプ画面が表示される | アプリ起動済み | HelpScreenを表示 | 「使い方」タイトルが表示される | HELP-001 |
| TC-075-002 | AppBarにタイトルが表示される | - | HelpScreenを表示 | AppBarに「使い方」が表示される | HELP-001 |
| TC-075-003 | 基本操作セクションが表示される | - | HelpScreenを表示 | 「基本操作」セクションが表示される | HELP-002 |
| TC-075-004 | 文字盤の説明が表示される | - | HelpScreenを表示 | 「文字盤」を含むテキストが表示される | HELP-002 |
| TC-075-005 | 定型文の説明が表示される | - | HelpScreenを表示 | 「定型文」を含むテキストが表示される | HELP-002 |
| TC-075-006 | TTS読み上げの説明が表示される | - | HelpScreenを表示 | 「読み上げ」を含むテキストが表示される | HELP-002 |
| TC-075-007 | 緊急ボタンの説明が表示される | - | HelpScreenを表示 | 「緊急」を含むテキストが表示される | HELP-003 |

### 1.2 誤操作防止設定テスト（NFR-205）

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-075-008 | 誤操作防止設定セクションが表示される | - | HelpScreenを表示 | 「誤操作防止の設定」セクションが表示される | HELP-004, NFR-205 |
| TC-075-009 | iOSガイド付きアクセスの説明が表示される | - | HelpScreenを表示 | 「ガイド付きアクセス」を含むテキストが表示される | HELP-005, NFR-205 |
| TC-075-010 | Android画面ピン留めの説明が表示される | - | HelpScreenを表示 | 「画面ピン留め」を含むテキストが表示される | HELP-006, NFR-205 |

### 1.3 UI/UXテスト

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-075-011 | スクロール可能なコンテンツ | - | HelpScreenを表示 | SingleChildScrollViewが存在する | HELP-007 |
| TC-075-012 | アクセシビリティ対応 | - | HelpScreenを表示 | Semanticsが設定されている | HELP-009 |

### 1.4 ナビゲーションテスト

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-075-013 | 戻るボタンで前の画面に戻れる | 他画面から遷移 | BackButtonをタップ | 元の画面に戻る | HELP-008 |

---

## 2. ヘルプセクションウィジェットテスト

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-075-014 | セクションタイトルが表示される | - | HelpSectionWidgetを表示 | タイトルが表示される | - |
| TC-075-015 | セクションアイコンが表示される | - | HelpSectionWidgetを表示 | アイコンが表示される | - |
| TC-075-016 | セクションコンテンツが表示される | - | HelpSectionWidgetを表示 | 子ウィジェットが表示される | - |
| TC-075-017 | カード形式で表示される | - | HelpSectionWidgetを表示 | Card内にコンテンツが表示される | - |

---

## 3. チュートリアルオーバーレイテスト（TutorialOverlay）

### 3.1 基本表示テスト

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-075-018 | オーバーレイが表示される | - | TutorialOverlayを表示 | TutorialOverlayウィジェットが存在する | TUT-001 |
| TC-075-019 | ウェルカムメッセージが表示される | - | TutorialOverlayを表示 | 「ようこそ」を含むテキストが表示される | TUT-002 |
| TC-075-020 | ステップインジケーターが表示される | - | TutorialOverlayを表示 | TutorialStepIndicatorが存在する | TUT-010 |

### 3.2 ナビゲーションテスト

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-075-021 | 「次へ」ボタンが表示される | - | TutorialOverlayを表示 | 「次へ」ボタンが存在する | TUT-007 |
| TC-075-022 | 「次へ」ボタンで次のステップに進む | ステップ1表示中 | 「次へ」をタップ | 「文字盤」の説明が表示される | TUT-003, TUT-007 |
| TC-075-023 | 「スキップ」ボタンが表示される | - | TutorialOverlayを表示 | 「スキップ」ボタンが存在する | TUT-008 |
| TC-075-024 | 「スキップ」ボタンでチュートリアルが終了する | - | 「スキップ」をタップ | onCompleteが呼ばれる | TUT-008, TUT-011 |
| TC-075-025 | 最後のステップで「はじめる」ボタンが表示される | - | 最後まで進む | 「はじめる」ボタンが存在する | TUT-009 |
| TC-075-026 | 「はじめる」ボタンでチュートリアルが完了する | 最後のステップ | 「はじめる」をタップ | onCompleteが呼ばれる | TUT-009, TUT-011 |

### 3.3 ステップコンテンツテスト

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-075-027 | 各ステップの説明が正しく表示される | - | 各ステップに進む | 適切な説明テキストが表示される | TUT-002〜TUT-006 |

---

## 4. チュートリアルプロバイダーテスト（TutorialProvider）

### 4.1 初期状態テスト

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-075-028 | 初回起動時はチュートリアル未完了状態 | SharedPreferences空 | Providerを初期化 | isCompleted=false, shouldShowTutorial=true | PROV-001, REQ-3001 |
| TC-075-029 | TutorialState初期状態 | - | 状態を生成 | isCompleted=false | PROV-001 |
| TC-075-030 | isLoading状態の管理 | - | 状態を生成 | isLoading管理が正しく動作 | - |

### 4.2 完了状態テスト

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-075-031 | チュートリアル完了後はフラグがtrueになる | 初期化済み | completeTutorial()を呼ぶ | isCompleted=true, shouldShowTutorial=false | PROV-002 |
| TC-075-032 | 完了フラグがSharedPreferencesに保存される | - | completeTutorial()を呼ぶ | 新コンテナでもisCompleted=true | PROV-003 |
| TC-075-033 | 2回目以降の起動ではチュートリアルは表示されない | tutorial_completed=true | Providerを初期化 | shouldShowTutorial=false | PROV-004, REQ-3001 |

### 4.3 状態操作テスト

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-075-034 | チュートリアルをリセットできる | 完了状態 | resetTutorial()を呼ぶ | isCompleted=false | PROV-005 |
| TC-075-035 | 読み込み完了後はshouldShowTutorial=true | isLoading=false | 状態を確認 | shouldShowTutorial=true | - |
| TC-075-036 | 完了状態のcopyWith | - | copyWithを呼ぶ | 新しい状態が正しく生成される | - |

---

## テスト実行コマンド

```bash
# 全テスト実行
flutter test test/features/help/

# 個別テスト実行
flutter test test/features/help/presentation/screens/help_screen_test.dart
flutter test test/features/help/presentation/widgets/help_section_widget_test.dart
flutter test test/features/help/presentation/widgets/tutorial_overlay_test.dart
flutter test test/features/help/providers/tutorial_provider_test.dart
```

## テスト結果

```
36 tests passed
```
