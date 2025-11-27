# TASK-0059: データ永続化テスト テストケース仕様書

## 概要

**タスクID**: TASK-0059
**機能名**: データ永続化テスト
**推定工数**: 8時間
**タスクタイプ**: TDD
**要件名**: kotonoha

## 1. テストケース概要

このテストケース仕様書は、TASK-0059（データ永続化テスト）の全テストケースを定義します。アプリ強制終了・クラッシュ時のデータ永続性を検証し、Hive（定型文・履歴・お気に入り）とshared_preferences（設定）が正しく永続化されることを確認します。

### 参照した要件定義書
- `docs/implements/kotonoha/TASK-0059/data-persistence-requirements.md`

### 参照したEARS要件
- **REQ-5003**: システムはアプリが強制終了しても定型文・設定・履歴を失わない永続化機構を実装しなければならない 🔵
- **NFR-301**: システムは重大なエラーが発生しても、基本機能（文字盤+読み上げ）を継続して利用可能に保たなければならない 🔵
- **NFR-302**: システムはアプリクラッシュからの復旧時に、最後の入力状態を復元しなければならない 🟡
- **NFR-304**: システムはデータベースエラー発生時に適切なエラーハンドリングを行い、データ損失を防がなければならない 🟡
- **EDGE-003**: ストレージ容量不足時の処理 🟡
- **EDGE-101**: 入力文字数上限（1000文字） 🟡
- **EDGE-201**: バックグラウンドから復帰した場合、前回の画面状態・入力内容を復元 🟡

### テストケースの分類

| カテゴリ | テストケース数 | 範囲 |
|---------|--------------|------|
| 基本的なテストパターン | 4件 | TC-059-001 ~ TC-059-004 |
| エッジケース | 4件 | TC-059-005 ~ TC-059-008 |
| 統合テストシナリオ | 1件 | TC-059-009 |
| パフォーマンステスト | 1件 | TC-059-010 |
| **合計** | **10件** | TC-059-001 ~ TC-059-010 |

---

## 2. 基本的なテストパターン（TC-059-001 ~ TC-059-004）

### TC-059-001: アプリ強制終了後のデータ保持テスト

**テスト目的**: アプリ強制終了後も定型文・設定・履歴がすべて保持されることを検証

**信頼性レベル**: 🔵 青信号 - REQ-5003、NFR-301に基づく

**前提条件**:
- アプリが起動している
- Hiveが初期化されている
- shared_preferencesが初期化されている

**テスト手順**:
1. 定型文を5件追加する
   ```dart
   // 定型文データ例
   PresetPhrase(id: 'test-001', content: 'こんにちは', category: 'daily', ...)
   PresetPhrase(id: 'test-002', content: 'お水をください', category: 'health', ...)
   PresetPhrase(id: 'test-003', content: 'ありがとう', category: 'daily', ...)
   PresetPhrase(id: 'test-004', content: '助けてください', category: 'health', ...)
   PresetPhrase(id: 'test-005', content: 'さようなら', category: 'daily', ...)
   ```
2. 設定でフォントサイズを「大（large）」に変更する
3. 履歴を3件保存する
   ```dart
   // 履歴データ例
   History(id: 'hist-001', content: 'テスト履歴1', type: HistoryType.tts, ...)
   History(id: 'hist-002', content: 'テスト履歴2', type: HistoryType.display, ...)
   History(id: 'hist-003', content: 'テスト履歴3', type: HistoryType.tts, ...)
   ```
4. Hive Boxを閉じる（`await Hive.close()`）
5. Hive Boxを再度開く（アプリ再起動をシミュレート）
6. 定型文・設定・履歴を読み込む

**期待結果**:
- 定型文5件がすべて保持されている
- 各定型文のid、content、category、isFavorite、displayOrder、createdAt、updatedAtが完全一致する
- フォントサイズ設定が「大（large）」のまま保持されている
- 履歴3件がすべて保持されている
- 各履歴のid、content、type、createdAtが完全一致する
- データの順序が保持されている

**実装ファイル**: `test/integration_test/data_persistence_test.dart`

**テストカテゴリ**: 統合テスト（Integration Test）

---

### TC-059-002: 入力中のテキスト復元テスト

**テスト目的**: アプリクラッシュ時の入力バッファが復元されることを検証

**信頼性レベル**: 🔵 青信号 - NFR-302、EDGE-201に基づく

**前提条件**:
- アプリが起動している
- InputBufferProviderが初期化されている
- 入力バッファに何も入力されていない状態

**テスト手順**:
1. 文字盤で「こんにちは」と入力する（読み上げ前）
   ```dart
   ref.read(inputBufferProvider.notifier).setText('こんにちは');
   ```
2. 入力バッファをshared_preferencesに保存する
   ```dart
   await prefs.setString('input_buffer', 'こんにちは');
   await prefs.setString('input_buffer_timestamp', DateTime.now().toIso8601String());
   ```
3. ProviderContainerを破棄する（アプリクラッシュをシミュレート）
   ```dart
   container.dispose();
   ```
4. ProviderContainerを再作成する（アプリ再起動をシミュレート）
   ```dart
   container = ProviderContainer();
   ```
5. 入力バッファをshared_preferencesから読み込み、InputBufferProviderに復元する

**期待結果**:
- 入力バッファに「こんにちは」が復元されている
- `ref.watch(inputBufferProvider)` の戻り値が `'こんにちは'` である
- 文字の欠落がない
- ユーザーは入力を続けられる（追加入力が可能）

**実装ファイル**: `test/integration_test/data_persistence_test.dart`

**テストカテゴリ**: 統合テスト（Integration Test）

**備考**:
- 入力バッファの永続化機能は未実装の可能性がある（🟡）
- テストで永続化機能の実装を検証する

---

### TC-059-003: トランザクション整合性テスト（定型文追加中のクラッシュ）

**テスト目的**: 定型文追加中のクラッシュでもデータ整合性が保たれることを検証

**信頼性レベル**: 🔵 青信号 - NFR-304に基づく

**前提条件**:
- アプリが起動している
- Hiveが初期化されている
- 定型文が0件の状態

**テスト手順**:
1. 定型文を10件追加する処理を開始する
   ```dart
   for (var i = 0; i < 10; i++) {
     final phrase = PresetPhrase(id: 'batch-$i', content: '定型文$i', ...);
     await repository.save(phrase);
     if (i == 4) {
       // 5件追加した時点でHiveを強制クローズ（クラッシュシミュレート）
       await Hive.close();
       break;
     }
   }
   ```
2. Hive Boxを再度開く（アプリ再起動をシミュレート）
3. 定型文を全件読み込む

**期待結果**:
- 追加が完了した5件（batch-0 ~ batch-4）は保存されている
- 追加が完了していない5件（batch-5 ~ batch-9）は保存されていない
- データ破損がない（既存の定型文は影響を受けていない）
- データの整合性が保たれている
- `repository.loadAll()` の戻り値の長さが5である
- 保存された5件のidが `'batch-0'`, `'batch-1'`, `'batch-2'`, `'batch-3'`, `'batch-4'` である

**実装ファイル**: `test/features/preset_phrase/data/preset_phrase_repository_crash_test.dart`

**テストカテゴリ**: ユニットテスト（Unit Test）

**備考**:
- Hiveのトランザクション単位は`save()`メソッド単位
- `save()`完了後にクラッシュしても、その時点までのデータは保持される

---

### TC-059-004: バックグラウンド復帰時の状態復元テスト

**テスト目的**: アプリがバックグラウンドから復帰した際に前回の状態が復元されることを検証

**信頼性レベル**: 🟡 黄信号 - NFR-302、EDGE-201に基づく（受け入れ基準からの推測）

**前提条件**:
- アプリが起動している
- 定型文一覧画面を表示している
- 文字盤で「ありがとう」と入力している

**テスト手順**:
1. 定型文一覧画面を表示する
2. 文字盤で「ありがとう」と入力する
   ```dart
   ref.read(inputBufferProvider.notifier).setText('ありがとう');
   ```
3. 現在のアプリ状態をshared_preferencesに保存する
   ```dart
   await prefs.setString('last_screen', 'preset_phrase_list');
   await prefs.setString('input_buffer', 'ありがとう');
   ```
4. アプリをバックグラウンドに移行する（`AppLifecycleState.paused`をシミュレート）
5. 5秒後にアプリを再度開く（`AppLifecycleState.resumed`をシミュレート）
6. アプリ状態をshared_preferencesから読み込み、復元する

**期待結果**:
- 定型文一覧画面が表示されている
- 入力バッファに「ありがとう」が保持されている
- スクロール位置が保持されている（可能であれば、🟡）

**実装ファイル**: `test/integration_test/data_persistence_test.dart`

**テストカテゴリ**: 統合テスト（Integration Test）

**備考**:
- スクロール位置の復元は実装難易度が高いため、必須ではない（🟡）
- 入力バッファの復元のみでも要件を満たす

---

## 3. エッジケース（TC-059-005 ~ TC-059-008）

### TC-059-005: ストレージ容量不足時のエラーハンドリング

**テスト目的**: ストレージ容量不足時に適切なエラーハンドリングが行われることを検証

**信頼性レベル**: 🟡 黄信号 - EDGE-003、NFR-304に基づく

**前提条件**:
- アプリが起動している
- ストレージ容量が極めて少ない（モックで容量不足をシミュレート）

**テスト手順**:
1. HiveのMockを作成し、`put()`メソッドで容量不足エラーを投げるようにする
   ```dart
   when(mockBox.put(any, any)).thenThrow(HiveError('Insufficient storage'));
   ```
2. 定型文を追加しようとする
   ```dart
   try {
     await repository.save(phrase);
   } catch (e) {
     // エラーをキャッチ
   }
   ```
3. エラーハンドリングの動作を確認する

**期待結果**:
- `HiveError` または `StorageException` がスローされる
- エラーメッセージが適切に設定されている（例: 「容量が不足しています」）
- アプリはクラッシュしない（エラーが適切にキャッチされる）
- 既存データは保持されている（データ破損なし）
- UI層でエラー通知が表示される（統合テストで確認）

**実装ファイル**: `test/features/preset_phrase/data/preset_phrase_repository_crash_test.dart`

**テストカテゴリ**: ユニットテスト（Unit Test）

**備考**:
- 実際のストレージ容量不足をシミュレートするのは困難なため、Mockを使用
- UI層でのエラー表示は別途統合テストで確認

---

### TC-059-006: Hive Box破損時の復旧処理

**テスト目的**: Hive Boxが破損した際に復旧処理が正常に動作することを検証

**信頼性レベル**: 🟡 黄信号 - NFR-304に基づく

**前提条件**:
- Hive Boxが破損している（手動で破損ファイルを配置、または無効なデータを書き込み）

**テスト手順**:
1. Hive Boxを開く前に、Box ファイルに無効なデータを書き込む（破損をシミュレート）
   ```dart
   final boxFile = File('${tempDir.path}/presetPhrases.hive');
   await boxFile.writeAsString('INVALID_DATA_CORRUPTION');
   ```
2. アプリを起動し、Hive Boxを開く
   ```dart
   try {
     final box = await Hive.openBox<PresetPhrase>('presetPhrases');
   } catch (e) {
     // エラーをキャッチし、復旧処理を実行
   }
   ```
3. 破損したBoxを削除し、新規作成する復旧処理を実行する
4. デフォルト定型文を投入する（オプション）

**期待結果**:
- エラーログが記録される
- 破損したBoxが削除される（`await Hive.deleteBoxFromDisk('presetPhrases')`）
- 新規Boxが作成される
- アプリはクラッシュしない
- ユーザーにエラー通知が表示される（例: 「データが破損していたため、初期化しました」）
- デフォルト定型文が再投入される（REQ-107に準拠）

**実装ファイル**: `test/core/utils/hive_init_test.dart`（Hive初期化テスト）

**テストカテゴリ**: ユニットテスト（Unit Test）

**備考**:
- Box破損のシミュレートは環境依存のため、実装難易度が高い（🔴）
- 最低限、破損検出とエラーログ記録を確認する

---

### TC-059-007: 1000文字入力中のクラッシュ復元

**テスト目的**: 入力バッファの境界値（1000文字）でのクラッシュ復元を検証

**信頼性レベル**: 🔵 青信号 - NFR-302、EDGE-101に基づく

**前提条件**:
- アプリが起動している
- 入力バッファが空の状態

**テスト手順**:
1. 文字盤で1000文字入力する（境界値テスト）
   ```dart
   final longText = 'あ' * 1000;
   ref.read(inputBufferProvider.notifier).setText(longText);
   ```
2. 入力バッファをshared_preferencesに保存する
   ```dart
   await prefs.setString('input_buffer', longText);
   ```
3. ProviderContainerを破棄する（アプリクラッシュをシミュレート）
4. ProviderContainerを再作成する（アプリ再起動をシミュレート）
5. 入力バッファをshared_preferencesから読み込み、復元する

**期待結果**:
- 入力バッファに1000文字が完全に復元されている
- `ref.watch(inputBufferProvider).length` が `1000` である
- 文字の欠落がない（完全一致）
- 入力バッファの内容が元の1000文字と一致する

**実装ファイル**: `test/integration_test/data_persistence_test.dart`

**テストカテゴリ**: 統合テスト（Integration Test）

**備考**:
- EDGE-101（入力文字数上限1000文字）の境界値テスト
- shared_preferencesの文字列保存上限を確認（通常は問題ない）

---

### TC-059-008: 複数の設定同時変更後のクラッシュ

**テスト目的**: 複数の設定を同時変更した際のトランザクション整合性を検証

**信頼性レベル**: 🔵 青信号 - NFR-304に基づく

**前提条件**:
- アプリが起動している
- 設定がすべてデフォルト値の状態

**テスト手順**:
1. 設定画面で複数の設定を変更する
   ```dart
   final settings = AppSettings(
     fontSize: FontSize.large,
     theme: AppTheme.dark,
     ttsSpeed: TtsSpeed.fast,
     politenessLevel: PolitenessLevel.polite,
   );
   ```
2. 設定を一括保存する
   ```dart
   await repository.saveAll(settings);
   ```
3. 保存中にSharedPreferencesのMockで例外をスローする（保存途中でのクラッシュをシミュレート）
4. 新しいRepositoryインスタンスで設定を読み込む

**期待結果**:
- すべての設定が正しく保存されている、**または**
- すべての設定が元のデフォルト値に戻っている（部分的な保存がない）
- データの整合性が保たれている
- 「fontSize: large、theme: light（デフォルト）」のような部分的な保存状態にならない

**実装ファイル**: `test/features/settings/data/app_settings_repository_crash_test.dart`

**テストカテゴリ**: ユニットテスト（Unit Test）

**備考**:
- shared_preferencesは個別の`setString()`呼び出し単位でトランザクションが完了する
- `saveAll()`メソッドの実装次第で、部分的な保存が発生する可能性がある
- このテストで`saveAll()`の原子性を検証する

---

## 4. 統合テストシナリオ（TC-059-009）

### TC-059-009: エンドツーエンドデータ永続化テスト

**テスト目的**: 実際のユーザー操作を再現し、すべてのデータ永続化機能が統合的に動作することを検証

**信頼性レベル**: 🔵 青信号 - REQ-5003、REQ-104、REQ-601、REQ-801、NFR-301、NFR-302に基づく

**前提条件**:
- アプリが起動している（初回起動）
- すべてのデータが空の状態

**テスト手順**:
1. アプリを初回起動する
2. デフォルト定型文（70件）が自動投入される
3. ユーザーが定型文を3件追加する
   ```dart
   await repository.save(PresetPhrase(id: 'user-001', content: 'こんにちは', ...));
   await repository.save(PresetPhrase(id: 'user-002', content: 'お水をください', ...));
   await repository.save(PresetPhrase(id: 'user-003', content: 'ありがとう', ...));
   ```
4. 定型文1件（user-001）をお気に入りに追加する
   ```dart
   final updated = phrase.copyWith(isFavorite: true);
   await repository.save(updated);
   ```
5. 設定でフォントサイズを「大（large）」に変更する
   ```dart
   await settingsRepository.saveFontSize(FontSize.large);
   ```
6. 文字盤で「お水をください」と入力する
7. 読み上げボタンをタップ（履歴に保存）
   ```dart
   final history = History(id: 'hist-001', content: 'お水をください', type: HistoryType.tts, ...);
   await historyRepository.save(history);
   ```
8. アプリを強制終了する（Hive.close()）
9. アプリを再起動する（Hive再オープン）
10. すべてのデータを読み込む

**期待結果**:
- デフォルト定型文70件 + 追加3件 = 計73件の定型文が保持されている
- お気に入り定型文（user-001）が`isFavorite: true`で保存されている
- お気に入り定型文がUI上部に表示されている（表示順序の確認）
- フォントサイズが「大（large）」のまま保持されている
- 履歴に「お水をください」が保存されている
- すべてのデータが整合性を保っている
- データの欠落・破損がない

**実装ファイル**: `test/integration_test/data_persistence_test.dart`

**テストカテゴリ**: 統合テスト（Integration Test）

**備考**:
- 最も重要なテストケース
- 実際のユーザー操作フローを網羅的に検証
- このテストが合格すれば、TASK-0059の完了条件をほぼ満たす

---

## 5. パフォーマンステスト（TC-059-010）

### TC-059-010: 起動時データ読み込み速度テスト

**テスト目的**: 大量データ保存時のアプリ起動速度を検証

**信頼性レベル**: 🟡 黄信号 - NFR-004に基づく（定型文一覧表示1秒以内）

**前提条件**:
- アプリが終了している
- 定型文100件が保存されている
- 履歴50件が保存されている
- 設定が保存されている

**テスト手順**:
1. 定型文100件、履歴50件、設定を事前に保存する
   ```dart
   final phrases = List.generate(100, (i) => PresetPhrase(id: 'phrase-$i', ...));
   await repository.saveAll(phrases);

   final histories = List.generate(50, (i) => History(id: 'hist-$i', ...));
   await historyRepository.saveAll(histories);

   await settingsRepository.saveAll(settings);
   ```
2. Hive Boxを閉じる
3. アプリを起動する（Hive再オープン）
4. 起動時間を計測する
   ```dart
   final stopwatch = Stopwatch()..start();
   await initHive();
   final phrases = await repository.loadAll();
   final histories = await historyRepository.loadAll();
   final settings = await settingsRepository.load();
   stopwatch.stop();
   ```
5. すべてのデータが読み込まれるまでの時間を記録する

**期待結果**:
- すべてのデータが1秒以内に読み込まれる（`stopwatch.elapsedMilliseconds <= 1000`）
- UIがブロックされない（非同期処理が正常に動作）
- ローディング表示が出る（1秒以内なら任意）
- データの欠落がない（100件の定型文、50件の履歴がすべて読み込まれる）

**実装ファイル**: `test/performance/data_load_performance_test.dart`

**テストカテゴリ**: パフォーマンステスト（Performance Test）

**備考**:
- NFR-004（定型文一覧表示1秒以内）に基づく
- CI/CD環境では実行環境の性能差により結果がばらつく可能性がある
- 実機テストを推奨

---

## 6. テストケース一覧表

| テストID | テスト名 | カテゴリ | 信頼性 | 対応要件 | 実装ファイル |
|---------|---------|---------|-------|---------|-------------|
| TC-059-001 | アプリ強制終了後のデータ保持テスト | 基本 | 🔵 | REQ-5003, NFR-301 | `integration_test/data_persistence_test.dart` |
| TC-059-002 | 入力中のテキスト復元テスト | 基本 | 🔵 | NFR-302, EDGE-201 | `integration_test/data_persistence_test.dart` |
| TC-059-003 | トランザクション整合性テスト | 基本 | 🔵 | NFR-304 | `features/preset_phrase/data/preset_phrase_repository_crash_test.dart` |
| TC-059-004 | バックグラウンド復帰時の状態復元テスト | 基本 | 🟡 | NFR-302, EDGE-201 | `integration_test/data_persistence_test.dart` |
| TC-059-005 | ストレージ容量不足時のエラーハンドリング | エッジ | 🟡 | EDGE-003, NFR-304 | `features/preset_phrase/data/preset_phrase_repository_crash_test.dart` |
| TC-059-006 | Hive Box破損時の復旧処理 | エッジ | 🟡 | NFR-304 | `core/utils/hive_init_test.dart` |
| TC-059-007 | 1000文字入力中のクラッシュ復元 | エッジ | 🔵 | NFR-302, EDGE-101 | `integration_test/data_persistence_test.dart` |
| TC-059-008 | 複数の設定同時変更後のクラッシュ | エッジ | 🔵 | NFR-304 | `features/settings/data/app_settings_repository_crash_test.dart` |
| TC-059-009 | エンドツーエンドデータ永続化テスト | 統合 | 🔵 | REQ-5003, REQ-104, REQ-601, REQ-801, NFR-301, NFR-302 | `integration_test/data_persistence_test.dart` |
| TC-059-010 | 起動時データ読み込み速度テスト | パフォーマンス | 🟡 | NFR-004 | `performance/data_load_performance_test.dart` |

---

## 7. テスト実装方針

### 7.1 アプリ強制終了のシミュレーション方法

#### 方法1: Hive Boxを明示的に閉じて再オープン
```dart
// アプリ終了をシミュレート
await Hive.close();

// アプリ再起動をシミュレート
await Hive.initFlutter();
Hive.registerAdapter(PresetPhraseAdapter());
final box = await Hive.openBox<PresetPhrase>('presetPhrases');
```

#### 方法2: ProviderContainerを破棄して再作成
```dart
// アプリクラッシュをシミュレート
container.dispose();

// アプリ再起動をシミュレート
container = ProviderContainer();
```

#### 方法3: integration_testでアプリプロセスを再起動
```dart
// iOS/Android実機で実際にアプリを終了・再起動
// この方法はintegration_testで実現可能
```

### 7.2 データ整合性の検証方法

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

### 7.3 テストヘルパー関数

#### Hive データベースをクリアする（テスト前準備）
```dart
Future<void> clearHiveDatabase() async {
  await Hive.deleteBoxFromDisk('presetPhrases');
  await Hive.deleteBoxFromDisk('history');
  await Hive.deleteBoxFromDisk('favorites');
}
```

#### アプリ強制終了をシミュレート
```dart
Future<void> simulateCrash() async {
  await Hive.close();
  // 再初期化
  await initHive();
}
```

#### ストレージ容量不足をシミュレート（モック使用）
```dart
Future<void> simulateStorageFull() async {
  // MockHiveInterface を使用してエラーを投げる
  when(mockBox.put(any, any)).thenThrow(HiveError('Insufficient storage'));
}
```

#### データの完全一致を検証
```dart
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

## 8. 完了条件

- [ ] TC-059-001〜010のすべてのテストケースが実装されている
- [ ] すべてのテストケースが合格している
- [ ] アプリ強制終了後も定型文・設定が100%保持される（TC-059-001）
- [ ] 入力中のテキストが100%復元される（TC-059-002）
- [ ] データの整合性が100%保たれる（TC-059-003）
- [ ] ストレージ容量不足時のエラーハンドリングが正常動作する（TC-059-005）
- [ ] データ破損時の復旧処理が正常動作する（TC-059-006）
- [ ] パフォーマンステストで1秒以内のデータ読み込みを達成（TC-059-010）
- [ ] iOS/Android両方で統合テストが合格している（TC-059-009）
- [ ] テストカバレッジレポートが生成されている

---

## 9. テスト実行コマンド

### ユニットテスト実行
```bash
cd frontend/kotonoha_app

# 定型文リポジトリクラッシュテスト
flutter test test/features/preset_phrase/data/preset_phrase_repository_crash_test.dart

# 設定リポジトリクラッシュテスト
flutter test test/features/settings/data/app_settings_repository_crash_test.dart

# Hive初期化テスト
flutter test test/core/utils/hive_init_test.dart
```

### 統合テスト実行
```bash
cd frontend/kotonoha_app

# データ永続化統合テスト
flutter test integration_test/data_persistence_test.dart
```

### パフォーマンステスト実行
```bash
cd frontend/kotonoha_app

# データ読み込みパフォーマンステスト
flutter test test/performance/data_load_performance_test.dart
```

### カバレッジレポート生成
```bash
cd frontend/kotonoha_app

flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### iOS実機での統合テスト
```bash
cd frontend/kotonoha_app

flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/data_persistence_test.dart \
  -d <device-id>
```

### Android実機での統合テスト
```bash
cd frontend/kotonoha_app

flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/data_persistence_test.dart \
  -d <device-id>
```

---

## 10. EARS要件・設計文書との対応関係

### 参照した機能要件
- **REQ-5003**: アプリが強制終了しても定型文・設定・履歴を失わない永続化機構 🔵
- **REQ-104**: 定型文の追加・編集・削除機能 🔵
- **REQ-601**: 履歴の自動保存 🔵
- **REQ-801-804**: フォントサイズ・テーマ設定 🔵

### 参照した非機能要件
- **NFR-301**: 重大なエラー発生時も基本機能を継続利用可能に保つ 🔵
- **NFR-302**: アプリクラッシュからの復旧時に、最後の入力状態を復元 🟡
- **NFR-304**: データベースエラー発生時に適切なエラーハンドリング、データ損失を防ぐ 🟡
- **NFR-004**: 定型文一覧表示1秒以内 🔵

### 参照したEdgeケース
- **EDGE-003**: ストレージ容量不足時の処理 🟡
- **EDGE-101**: 入力文字数上限（1000文字） 🟡
- **EDGE-201**: バックグラウンドから復帰した場合、前回の画面状態・入力内容を復元 🟡

### 参照した受け入れ基準
- **AC-NFR-302**: データ復元テスト 🟡
  - アプリクラッシュ後、再起動時に最後の入力状態が復元されることを確認
  - バックグラウンドから復帰時に、前回の画面状態が復元されることを確認
  - 定型文・履歴・設定が失われずに保持されることを確認

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

## 11. 品質判定

### ✅ 高品質
- **要件の曖昧さ**: なし - REQ-5003、NFR-301、NFR-302から明確に定義 🔵
- **テストケース定義**: 完全 - 10個のテストケース（基本4件、エッジ4件、統合1件、パフォーマンス1件） 🔵
- **制約条件**: 明確 - パフォーマンス、信頼性、互換性要件を網羅 🔵
- **実装可能性**: 確実 - TASK-0055、TASK-0056で基盤実装済み 🔵

---

## 12. 次のステップ

次のお勧めステップ: `/tsumiki:tdd-red` で失敗するテストを作成します。

---

**生成日時**: 2025-11-27
**作成者**: Claude Code (TDD開発者)
**バージョン**: 1.0
