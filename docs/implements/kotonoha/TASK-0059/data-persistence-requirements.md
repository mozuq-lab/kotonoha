# TASK-0059: データ永続化テスト 要件定義書

## 概要

**タスクID**: TASK-0059
**機能名**: データ永続化テスト
**推定工数**: 8時間
**タスクタイプ**: TDD
**要件名**: kotonoha

## 1. 機能の概要（EARS要件定義書・設計文書ベース）

### 1.1 何をする機能か 🔵
- アプリ強制終了・クラッシュ時のデータ永続性を検証する統合テスト機能
- Hive（定型文・履歴・お気に入り）とshared_preferences（設定）が正しく永続化されることを確認
- アプリ再起動後のデータ復元・入力状態の復元を検証
- データの整合性（トランザクション整合性）を確認

### 1.2 どのような問題を解決するか 🔵
- **データ損失の防止**: アプリがクラッシュしてもユーザーデータが失われない
- **状態復元の保証**: 入力中のテキストが復元され、ユーザー体験が損なわれない
- **品質保証**: REQ-5003、NFR-301、NFR-302の要件を満たすことを検証

### 1.3 想定されるユーザー 🔵
- 脳梗塞・ALS・筋疾患などで発話が困難な方
- アプリを長時間使用し、定型文や設定をカスタマイズする方
- 重要なコミュニケーションでアプリの信頼性が必須の方

### 1.4 システム内での位置づけ 🔵
- **テスト層**: 統合テスト（Integration Test）
- **対象レイヤー**:
  - データ永続化層（Hive + shared_preferences）
  - 状態管理層（Riverpod StateNotifier）
  - UI層（状態復元ロジック）
- **依存タスク**:
  - TASK-0055: 定型文Hiveローカル保存実装 ✅
  - TASK-0056: アプリ設定shared_preferences保存実装 ✅
  - TASK-0057: Riverpod Provider構造設計 ✅

### 参照したEARS要件
- **REQ-5003**: システムはアプリが強制終了しても定型文・設定・履歴を失わない永続化機構を実装しなければならない 🔵
- **NFR-301**: システムは重大なエラーが発生しても、基本機能（文字盤+読み上げ）を継続して利用可能に保たなければならない 🔵
- **NFR-302**: システムはアプリクラッシュからの復旧時に、最後の入力状態を復元しなければならない 🟡
- **NFR-304**: システムはデータベースエラー発生時に適切なエラーハンドリングを行い、データ損失を防がなければならない 🟡

### 参照した受け入れ基準
- **AC-NFR-302**: データ復元テスト
  - アプリクラッシュ後、再起動時に最後の入力状態が復元されることを確認 🟡
  - バックグラウンドから復帰時に、前回の画面状態が復元されることを確認 🟡
  - 定型文・履歴・設定が失われずに保持されることを確認 🟡

### 参照した設計文書
- **architecture.md**:
  - データ永続化設計（REQ-5003）
  - 状態復元（NFR-302）
  - エラーハンドリング戦略
- **dataflow.md**:
  - データ処理フロー
  - データ保存エラー処理フロー
  - 状態管理フロー（Riverpod）

---

## 2. テスト対象の仕様（EARS機能要件・設計文書ベース）

### 2.1 テスト対象データ 🔵

#### 定型文データ（Hive: presetPhrases Box）
```dart
class PresetPhrase {
  final String id;           // UUID形式
  final String content;      // 定型文の内容（最大500文字）
  final String category;     // 'daily', 'health', 'other'
  final bool isFavorite;     // お気に入りフラグ
  final int displayOrder;    // 表示順序
  final DateTime createdAt;  // 作成日時
  final DateTime updatedAt;  // 更新日時
}
```

#### 履歴データ（Hive: history Box）🟡
```dart
class HistoryItem {
  final String id;           // UUID形式
  final String content;      // 履歴内容
  final DateTime timestamp;  // 記録日時
  final bool isFavorite;     // お気に入りフラグ
}
```

#### お気に入りデータ（Hive: favorites Box）🟡
```dart
class FavoriteItem {
  final String id;           // UUID形式
  final String content;      // お気に入り内容
  final DateTime addedAt;    // 追加日時
}
```

#### 設定データ（shared_preferences）🔵
```dart
class AppSettings {
  final FontSize fontSize;           // 'small', 'medium', 'large'
  final AppTheme theme;              // 'light', 'dark', 'highContrast'
  final TtsSpeed ttsSpeed;           // 'slow', 'normal', 'fast'
  final PolitenessLevel politenessLevel; // 'casual', 'normal', 'polite'
}
```

#### 入力状態データ 🟡
```dart
class InputState {
  final String inputBuffer;  // 入力中のテキスト（最大1000文字）
  final DateTime lastModified; // 最終更新日時
}
```

### 2.2 テストシナリオパラメータ 🔵

| テストシナリオ | 対象データ | 検証内容 |
|--------------|----------|---------|
| アプリ強制終了 | 定型文・設定・履歴 | 再起動後も保持される |
| 入力中のクラッシュ | 入力バッファ | 入力状態が復元される |
| トランザクション整合性 | 定型文・履歴 | 一貫性が保たれる |
| ストレージ容量不足 | 全データ | エラーハンドリング実行 |
| データ破損 | Hive Box | 復旧処理実行 |

### 参照したEARS要件
- REQ-104: 定型文の追加・編集・削除機能
- REQ-601: 読み上げまたは表示した文章を自動的に履歴として保存
- REQ-801-804: フォントサイズ・テーマ設定
- EDGE-201: アプリがバックグラウンドから復帰した場合、システムは前回の画面状態・入力内容を復元しなければならない 🟡

### 参照した設計文書
- dataflow.md: データ保存エラー処理フロー
- architecture.md: データ永続化設計

---

## 3. 制約条件（EARS非機能要件・アーキテクチャ設計ベース）

### 3.1 パフォーマンス要件 🟡
- **データ読み込み**: アプリ起動から1秒以内にすべての永続データを読み込む
- **データ保存**: UIブロックなし、非同期で保存処理を実行
- **状態復元**: アプリ起動から500ms以内に前回の入力状態を復元

### 3.2 信頼性要件 🔵
- **データ永続性**: アプリクラッシュ・強制終了後も100%のデータが保持される（NFR-301）
- **状態復元率**: 入力バッファの復元成功率100%（NFR-302）
- **トランザクション整合性**: データの一貫性が常に保たれる（NFR-304）

### 3.3 互換性要件 🔵
- **Hive互換性**: Hive 2.x の仕様に準拠
- **shared_preferences互換性**: shared_preferences 2.x の仕様に準拠
- **既存実装互換**: TASK-0055、TASK-0056の実装を破壊しない

### 3.4 テスト実行環境 🟡
- **iOS**: 14.0以上（実機・シミュレータ）
- **Android**: 10以上（実機・エミュレータ）
- **Flutter**: 3.38.1
- **Dart**: 3.10+

### 参照したEARS要件
- NFR-301: 基本機能の継続性
- NFR-302: データ復元
- NFR-304: データベースエラーハンドリング
- NFR-401: OSバージョン互換性

### 参照した設計文書
- architecture.md: 非機能要件への対応
- tech-stack.md: 開発環境・技術スタック

---

## 4. テストケースシナリオ（EARSEdgeケース・受け入れ基準ベース）

### 4.1 基本的なテストパターン 🔵

#### TC-059-001: アプリ強制終了後のデータ保持テスト
**Given（前提条件）**:
- アプリが起動している
- 定型文を5件追加している
- 設定でフォントサイズを「大」に変更している
- 履歴が3件保存されている

**When（実行条件）**:
- アプリを強制終了する（iOS: スワイプで終了、Android: タスクキル）
- アプリを再起動する

**Then（期待結果）**:
- 定型文5件がすべて保持されている
- フォントサイズ設定が「大」のまま保持されている
- 履歴3件がすべて保持されている
- データの内容（content）が完全一致する
- データの順序が保持されている

**参照要件**: REQ-5003, NFR-301

---

#### TC-059-002: 入力中のテキスト復元テスト
**Given（前提条件）**:
- アプリが起動している
- 文字盤で「こんにちは」と入力している（読み上げ前）

**When（実行条件）**:
- アプリがクラッシュする（シミュレーション: アプリを強制終了）
- アプリを再起動する

**Then（期待結果）**:
- 入力バッファに「こんにちは」が復元されている
- 入力欄に「こんにちは」が表示されている
- ユーザーは入力を続けられる

**参照要件**: NFR-302, EDGE-201

---

#### TC-059-003: トランザクション整合性テスト（定型文追加中のクラッシュ）
**Given（前提条件）**:
- アプリが起動している
- 定型文を10件追加する処理を実行中

**When（実行条件）**:
- 5件追加した時点でアプリがクラッシュする（シミュレーション）
- アプリを再起動する

**Then（期待結果）**:
- 追加が完了した5件は保存されている
- 追加が完了していない5件は保存されていない（データ破損なし）
- 既存の定型文は影響を受けていない
- データの整合性が保たれている

**参照要件**: NFR-304

---

#### TC-059-004: バックグラウンド復帰時の状態復元テスト
**Given（前提条件）**:
- アプリが起動している
- 定型文一覧画面を表示している
- 文字盤で「ありがとう」と入力している

**When（実行条件）**:
- アプリをバックグラウンドに移行する（ホームボタン押下）
- 5分後にアプリを再度開く

**Then（期待結果）**:
- 定型文一覧画面が表示されている
- 入力バッファに「ありがとう」が保持されている
- スクロール位置が保持されている（可能であれば）

**参照要件**: NFR-302, EDGE-201

---

### 4.2 エッジケース 🟡

#### TC-059-005: ストレージ容量不足時のエラーハンドリング
**Given（前提条件）**:
- ストレージ容量が極めて少ない（シミュレーション）
- アプリが起動している

**When（実行条件）**:
- 定型文を追加しようとする

**Then（期待結果）**:
- エラーメッセージが表示される（「容量が不足しています」）
- 古い履歴を削除する提案が表示される（EDGE-003）
- アプリはクラッシュしない
- 既存データは保持されている

**参照要件**: EDGE-003, NFR-304

---

#### TC-059-006: Hive Box破損時の復旧処理
**Given（前提条件）**:
- Hive Box が破損している（手動で破損ファイルを配置）

**When（実行条件）**:
- アプリを起動する

**Then（期待結果）**:
- エラーログが記録される
- 破損したBoxを削除して新規作成する
- デフォルト定型文（70件）が再投入される
- アプリはクラッシュしない
- ユーザーにエラー通知が表示される（「データが破損していたため、初期化しました」）

**参照要件**: NFR-304

---

#### TC-059-007: 1000文字入力中のクラッシュ復元
**Given（前提条件）**:
- アプリが起動している
- 文字盤で1000文字入力している（境界値テスト）

**When（実行条件）**:
- アプリがクラッシュする
- アプリを再起動する

**Then（期待結果）**:
- 入力バッファに1000文字が完全に復元されている
- 文字の欠落がない

**参照要件**: NFR-302, EDGE-101

---

#### TC-059-008: 複数の設定同時変更後のクラッシュ
**Given（前提条件）**:
- アプリが起動している
- 設定画面でフォントサイズ「大」、テーマ「ダーク」、TTS速度「速い」に変更

**When（実行条件）**:
- 設定を保存中にアプリがクラッシュする
- アプリを再起動する

**Then（期待結果）**:
- すべての設定が正しく保存されている、または
- すべての設定が元に戻っている（部分的な保存がない）
- データの整合性が保たれている

**参照要件**: NFR-304

---

### 4.3 統合テストシナリオ 🔵

#### TC-059-009: エンドツーエンドデータ永続化テスト
**シナリオ**: 実際のユーザー操作を再現

**Given（前提条件）**:
- アプリが起動している（初回起動）

**When（実行条件）**:
1. デフォルト定型文（70件）が投入される
2. ユーザーが定型文を3件追加する
3. 定型文1件をお気に入りに追加する
4. 設定でフォントサイズを「大」に変更
5. 文字盤で「お水をください」と入力する
6. 読み上げボタンをタップ（履歴に保存）
7. アプリを強制終了
8. アプリを再起動

**Then（期待結果）**:
- デフォルト定型文70件 + 追加3件 = 計73件の定型文が保持されている
- お気に入り定型文が上部に表示されている
- フォントサイズが「大」のまま
- 履歴に「お水をください」が保存されている
- すべてのデータが整合性を保っている

**参照要件**: REQ-5003, REQ-104, REQ-601, REQ-801, NFR-301, NFR-302

---

### 4.4 パフォーマンステスト 🟡

#### TC-059-010: 起動時データ読み込み速度テスト
**Given（前提条件）**:
- 定型文100件が保存されている
- 履歴50件が保存されている
- 設定が保存されている

**When（実行条件）**:
- アプリを起動する

**Then（期待結果）**:
- すべてのデータが1秒以内に読み込まれる
- UI がブロックされない
- ローディング表示が出る（1秒以内なら任意）

**参照要件**: NFR-004（定型文一覧表示1秒以内）

---

### 参照したEARS要件
- REQ-5003: データ永続化機構
- NFR-301: 基本機能の継続性
- NFR-302: データ復元
- NFR-304: エラーハンドリング
- EDGE-003: ストレージ容量不足時の処理
- EDGE-101: 入力文字数上限
- EDGE-201: バックグラウンドから復帰

### 参照した受け入れ基準
- AC-NFR-302: データ復元テスト基準

---

## 5. 実装詳細

### 5.1 テスト対象ファイル 🔵

| ファイル | 役割 |
|---------|------|
| `lib/features/preset_phrase/data/preset_phrase_repository.dart` | 定型文Hive永続化 |
| `lib/features/settings/data/app_settings_repository.dart` | 設定shared_preferences永続化 |
| `lib/features/input/providers/input_buffer_notifier.dart` | 入力バッファ状態管理 |
| `lib/core/hive/hive_init.dart` | Hive初期化処理 |

### 5.2 テストファイル配置 🔵

```
test/
├── integration_test/
│   └── data_persistence_test.dart      # 統合テスト（TC-059-001〜009）
├── features/
│   ├── preset_phrase/
│   │   └── data/
│   │       └── preset_phrase_repository_crash_test.dart  # クラッシュシミュレーション
│   └── settings/
│       └── data/
│           └── app_settings_repository_crash_test.dart   # クラッシュシミュレーション
└── performance/
    └── data_load_performance_test.dart  # パフォーマンステスト（TC-059-010）
```

### 5.3 テスト実装方針 🔵

#### アプリ強制終了のシミュレーション方法
```dart
// 方法1: Hive Boxを明示的に閉じて再オープン
await Hive.close();
await Hive.openBox<PresetPhrase>('presetPhrases');

// 方法2: ProviderContainerを破棄して再作成
container.dispose();
container = ProviderContainer();

// 方法3: integration_testでアプリプロセスを再起動
// iOS/Android実機で実際にアプリを終了・再起動
```

#### データ整合性の検証方法
```dart
// 保存前のデータをスナップショット
final beforeData = await repository.loadAll();

// クラッシュシミュレーション
await simulateCrash();

// 再起動後のデータを取得
final afterData = await repository.loadAll();

// 内容を比較
expect(afterData.length, beforeData.length);
expect(afterData, equals(beforeData)); // ディープイコール
```

### 5.4 テストヘルパー関数 🔵

```dart
/// Hive データベースをクリアする（テスト前準備）
Future<void> clearHiveDatabase() async {
  await Hive.deleteBoxFromDisk('presetPhrases');
  await Hive.deleteBoxFromDisk('history');
  await Hive.deleteBoxFromDisk('favorites');
}

/// アプリ強制終了をシミュレート
Future<void> simulateCrash() async {
  await Hive.close();
  // 再初期化
  await initHive();
}

/// ストレージ容量不足をシミュレート（モック使用）
Future<void> simulateStorageFull() async {
  // MockHiveInterface を使用してエラーを投げる
}

/// データの完全一致を検証
void verifyDataIntegrity(List<PresetPhrase> expected, List<PresetPhrase> actual) {
  expect(actual.length, expected.length);
  for (var i = 0; i < expected.length; i++) {
    expect(actual[i].id, expected[i].id);
    expect(actual[i].content, expected[i].content);
    expect(actual[i].category, expected[i].category);
    expect(actual[i].isFavorite, expected[i].isFavorite);
  }
}
```

---

## 6. 完了条件 🔵

- [ ] TC-059-001〜010のすべてのテストケースが実装されている
- [ ] すべてのテストケースが合格している
- [ ] アプリ強制終了後も定型文・設定が100%保持される
- [ ] 入力中のテキストが100%復元される
- [ ] データの整合性が100%保たれる
- [ ] ストレージ容量不足時のエラーハンドリングが正常動作する
- [ ] データ破損時の復旧処理が正常動作する
- [ ] パフォーマンステストで1秒以内のデータ読み込みを達成
- [ ] iOS/Android両方で統合テストが合格している
- [ ] テストカバレッジレポートが生成されている

---

## 7. EARS要件・設計文書との対応関係

### 参照したユーザストーリー
- なし（非機能要件のテスト）

### 参照した機能要件
- **REQ-5003**: アプリが強制終了しても定型文・設定・履歴を失わない永続化機構 🔵
- **REQ-104**: 定型文の追加・編集・削除機能 🔵
- **REQ-601**: 履歴の自動保存 🔵
- **REQ-801-804**: フォントサイズ・テーマ設定 🔵

### 参照した非機能要件
- **NFR-301**: 重大なエラー発生時も基本機能を継続利用可能に保つ 🔵
- **NFR-302**: アプリクラッシュからの復旧時に、最後の入力状態を復元 🟡
- **NFR-304**: データベースエラー発生時に適切なエラーハンドリング、データ損失を防ぐ 🟡

### 参照したEdgeケース
- **EDGE-003**: ストレージ容量不足時の処理 🟡
- **EDGE-101**: 入力文字数上限（1000文字） 🟡
- **EDGE-201**: バックグラウンドから復帰した場合、前回の画面状態・入力内容を復元 🟡

### 参照した受け入れ基準
- **AC-NFR-302**: データ復元テスト 🟡

### 参照した設計文書
- **architecture.md**:
  - データ永続化設計（REQ-5003）
  - 状態復元（NFR-302）
  - エラーハンドリング戦略
- **dataflow.md**:
  - データ処理フロー
  - データ保存エラー処理フロー
  - 状態管理フロー（Riverpod）
- **TASK-0055要件定義書**: 定型文Hiveローカル保存仕様
- **TASK-0056要件定義書**: アプリ設定shared_preferences保存仕様

---

## 8. 品質判定

### ✅ 高品質
- **要件の曖昧さ**: なし - REQ-5003、NFR-301、NFR-302から明確に定義 🔵
- **テストケース定義**: 完全 - 10個のテストケース（基本4件、エッジ4件、統合1件、パフォーマンス1件） 🔵
- **制約条件**: 明確 - パフォーマンス、信頼性、互換性要件を網羅 🔵
- **実装可能性**: 確実 - TASK-0055、TASK-0056で基盤実装済み 🔵

---

## 9. 次のステップ

次のお勧めステップ: `/tsumiki:tdd-testcases` でテストケースの詳細な洗い出しを行います。

---

## 10. 付録: テスト実行コマンド

### ユニットテスト実行
```bash
cd frontend/kotonoha_app
flutter test test/features/preset_phrase/data/preset_phrase_repository_crash_test.dart
flutter test test/features/settings/data/app_settings_repository_crash_test.dart
```

### 統合テスト実行
```bash
flutter test integration_test/data_persistence_test.dart
```

### カバレッジレポート生成
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### iOS実機での統合テスト
```bash
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/data_persistence_test.dart -d <device-id>
```

### Android実機での統合テスト
```bash
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/data_persistence_test.dart -d <device-id>
```
