# TDD要件定義・機能仕様 - TASK-0038: 文字入力バッファ管理（Riverpod StateNotifier）

## タスク情報

- **タスクID**: TASK-0038
- **タスク名**: 文字入力バッファ管理（Riverpod StateNotifier）
- **タスクタイプ**: TDD
- **推定工数**: 8時間
- **フェーズ**: Phase 3 - Week 9, Day 2
- **依存タスク**: TASK-0013 (Riverpod設定), TASK-0037 (五十音文字盤UI実装)

## 関連文書

- **EARS要件定義書**: [docs/spec/kotonoha-requirements.md](../../spec/kotonoha-requirements.md)
- **アーキテクチャ設計**: [docs/design/kotonoha/architecture.md](../../design/kotonoha/architecture.md)
- **データフロー図**: [docs/design/kotonoha/dataflow.md](../../design/kotonoha/dataflow.md)
- **インターフェース定義**: [docs/design/kotonoha/interfaces.dart](../../design/kotonoha/interfaces.dart)
- **Phase 3タスク**: [docs/tasks/kotonoha-phase3.md](../../tasks/kotonoha-phase3.md)

---

## 1. 機能の概要（EARS要件定義書・設計文書ベース）

### 機能概要 🔵

この機能は、五十音文字盤からタップ入力された文字を管理する入力バッファの状態管理を実装します。Riverpod StateNotifierを使用して、文字の追加・削除・全消去を行い、UIと状態を同期します。

### 何をする機能か

- 文字盤から入力された文字を入力バッファに追加する
- 削除ボタンで最後の1文字を削除する
- 全消去ボタンでバッファをクリアする
- 最大1000文字の制限を設ける
- バッファの状態変更をリアルタイムでUIに反映する
- 入力中のテキストを永続化し、アプリクラッシュ時も復元可能にする

### どのような問題を解決するか

**文字入力の状態管理の必要性 🔵**:
- REQ-002: 文字盤の文字をタップすると入力欄に文字を追加する機能が必要
- REQ-003: 削除ボタンで最後の1文字を削除する機能が必要
- REQ-004: 全消去ボタンで入力欄のすべての文字を削除する機能が必要
- EDGE-101: 入力欄の文字数が1000文字を超えた場合の制限が必要

**状態管理の一元化 🔵**:
- TASK-0013で構築したRiverpod基盤を活用
- 入力バッファの状態をアプリ全体で一貫して管理
- テスタビリティの高い、型安全な状態管理

### 想定されるユーザー

- 発話が困難で、タブレットの文字盤を使ってコミュニケーションするユーザー
- 介護スタッフや家族（支援者）

### システム内での位置づけ

**アーキテクチャ上の位置 🔵**:
- **Presentation層**: 入力バッファの状態を管理するStateNotifier
- **TASK-0037（五十音文字盤UI）との連携**: 文字タップ時にバッファに文字を追加
- **後続タスク（TASK-0039: 削除・全消去ボタン）との連携**: バッファの操作メソッドを提供
- **TTS読み上げ機能との連携**: バッファ内容を読み上げに渡す

### 参照したEARS要件

- **REQ-002**: システムは文字盤の文字をタップすると入力欄に文字を追加しなければならない 🔵
- **REQ-003**: システムは削除ボタンで最後の1文字を削除する機能を提供しなければならない 🔵
- **REQ-004**: システムは全消去ボタンで入力欄のすべての文字を削除する機能を提供しなければならない 🔵
- **EDGE-101**: 入力欄の文字数が1000文字を超えた場合、システムは警告を表示し、1000文字で入力を制限しなければならない 🟡

### 参照した設計文書

- **architecture.md**: フロントエンド（Flutter）セクション - Riverpod 2.x状態管理
- **dataflow.md**: 状態管理フロー（Riverpod）セクション
- **interfaces.dart**: `InputScreenState`クラス（469-515行目）

---

## 2. 入力・出力の仕様（EARS機能要件・TypeScript型定義ベース）

### 入力パラメータ 🔵

#### InputBufferNotifier.addCharacter(String character)
- **型**: `String`（1文字）
- **制約**:
  - 空文字列は許可しない
  - 制御文字は許可しない
  - 1回の呼び出しで1文字のみ追加
- **使用例**: `addCharacter('あ')`, `addCharacter('ん')`

#### InputBufferNotifier.deleteLastCharacter()
- **パラメータ**: なし
- **動作**: 入力バッファの最後の1文字を削除
- **制約**: バッファが空の場合は何もしない

#### InputBufferNotifier.clear()
- **パラメータ**: なし
- **動作**: 入力バッファをすべてクリア

#### InputBufferNotifier.setText(String text)
- **型**: `String`
- **制約**:
  - 1000文字を超える場合は1000文字で切り捨て
  - 空文字列も許可（クリア目的）
- **使用例**: `setText('こんにちは')`, `setText('')`

### 出力値 🔵

#### InputBufferNotifier state
- **型**: `String`
- **初期値**: `''`（空文字列）
- **最大長**: 1000文字（EDGE-101）
- **更新タイミング**: 各操作メソッド呼び出し直後

### 入出力の関係性 🔵

1. **文字追加フロー**:
   - ユーザーが文字盤で文字をタップ
   - `CharacterBoardWidget.onCharacterTap`コールバック発火
   - `addCharacter(character)`呼び出し
   - 現在のバッファ + 新文字 = 新バッファ（1000文字以内）
   - Riverpod stateが更新
   - UIが自動的に再描画

2. **文字削除フロー**:
   - ユーザーが削除ボタンをタップ
   - `deleteLastCharacter()`呼び出し
   - 現在のバッファの最後1文字を削除
   - Riverpod stateが更新

3. **全消去フロー**:
   - ユーザーが全消去を確認
   - `clear()`呼び出し
   - バッファを空文字列にリセット
   - Riverpod stateが更新

### データフロー 🔵

```
[五十音文字盤 (CharacterBoardWidget)]
  ↓ onCharacterTap('あ')
[InputBufferNotifier]
  ├→ state = state + 'あ' (1000文字制限チェック)
  └→ 状態通知
  ↓
[UI Components (入力欄表示, 文字カウンター等)]
  ↓ 再描画
[ユーザーに表示]
```

### 参照したEARS要件

- **REQ-002**: 文字タップで入力欄に追加 🔵
- **REQ-003**: 削除ボタンで最後の1文字削除 🔵
- **REQ-004**: 全消去ボタンで全削除 🔵
- **EDGE-101**: 1000文字制限 🟡

### 参照した設計文書

- **interfaces.dart**: 469-515行目（`InputScreenState`クラス - `inputText`フィールド参照）
- **dataflow.md**: 状態管理フロー（Riverpod）セクション

---

## 3. 制約条件（EARS非機能要件・アーキテクチャ設計ベース）

### パフォーマンス要件 🔵

#### 入力応答速度
- **NFR-003**: 文字盤タップから入力欄への文字反映までの遅延を100ms以内
- **目標**: 文字追加・削除・全消去すべてが100ms以内に完了
- **測定方法**: タップイベント発生からUI更新完了まで

#### メモリ効率
- **最大バッファサイズ**: 1000文字（EDGE-101）
- **String操作**: 不変オブジェクトとして管理（Dartの標準）
- **メモリリーク防止**: StateNotifierのdisposeで適切にリソース解放

### 永続化要件 🟡

#### 入力状態の復元
- **NFR-302**: アプリクラッシュからの復旧時に、最後の入力状態を復元
- **実装方針**: SharedPreferencesまたはHiveに入力中テキストを定期保存
- **保存タイミング**: 文字追加・削除時に非同期で保存（デバウンス処理推奨）

### セキュリティ要件 🔵

- **NFR-101**: 入力内容は端末内にのみ保存
- **機密性**: 入力バッファの内容は外部送信しない（AI変換時を除く）

### アーキテクチャ制約 🔵

**architecture.md「フロントエンド（Flutter）」セクションから抽出**:
- **状態管理**: Riverpod 2.x必須
- **StateNotifier**: 同期的な状態更新に適したパターン
- **immutable state**: 状態は不変オブジェクトとして管理

### 文字制限の詳細 🟡

#### EDGE-101: 1000文字制限
- **挙動**:
  - 1000文字に達している状態で文字追加を試みた場合、追加しない
  - `setText()`で1000文字超のテキストが渡された場合、1000文字で切り捨て
  - 警告表示は別途UIで対応（後続タスク）
- **理由**:
  - TTS読み上げの負荷軽減
  - UI表示のパフォーマンス維持
  - 実用上のコミュニケーション文として十分な長さ

### 参照したEARS要件

- **NFR-003**: 文字盤タップ応答100ms以内 🔵
- **NFR-101**: 端末内保存 🔵
- **NFR-302**: クラッシュ復旧時の入力復元 🟡
- **EDGE-101**: 1000文字制限 🟡

### 参照した設計文書

- **architecture.md**: フロントエンド（Flutter）セクション - Riverpod 2.x状態管理

---

## 4. 想定される使用例（EARSエッジケース・データフローベース）

### 基本的な使用パターン 🔵

#### パターン1: 文字入力
**REQ-002の通常動作**:
```dart
// ユーザーが「あ」「い」「う」を順にタップ
final container = ProviderContainer();
final notifier = container.read(inputBufferProvider.notifier);

notifier.addCharacter('あ');
expect(container.read(inputBufferProvider), 'あ');

notifier.addCharacter('い');
expect(container.read(inputBufferProvider), 'あい');

notifier.addCharacter('う');
expect(container.read(inputBufferProvider), 'あいう');
```

#### パターン2: 文字削除
**REQ-003の通常動作**:
```dart
// 現在の入力: 'こんにちは'
final container = ProviderContainer();
final notifier = container.read(inputBufferProvider.notifier);
notifier.setText('こんにちは');

notifier.deleteLastCharacter();
expect(container.read(inputBufferProvider), 'こんにち');

notifier.deleteLastCharacter();
expect(container.read(inputBufferProvider), 'こんに');
```

#### パターン3: 全消去
**REQ-004の通常動作**:
```dart
// 現在の入力: 'おはようございます'
final container = ProviderContainer();
final notifier = container.read(inputBufferProvider.notifier);
notifier.setText('おはようございます');

notifier.clear();
expect(container.read(inputBufferProvider), '');
```

### エッジケース 🟡

#### EDGE-1: 1000文字制限到達
**EDGE-101の動作**:
```dart
final container = ProviderContainer();
final notifier = container.read(inputBufferProvider.notifier);

// 1000文字のテキストを設定
final longText = 'あ' * 1000;
notifier.setText(longText);
expect(container.read(inputBufferProvider).length, 1000);

// 追加の文字を入力しようとする
notifier.addCharacter('い');
// 文字は追加されない（1000文字のまま）
expect(container.read(inputBufferProvider).length, 1000);
```

#### EDGE-2: setTextで1000文字超過
```dart
final container = ProviderContainer();
final notifier = container.read(inputBufferProvider.notifier);

// 1001文字のテキストを設定
final overflowText = 'あ' * 1001;
notifier.setText(overflowText);

// 1000文字で切り捨て
expect(container.read(inputBufferProvider).length, 1000);
```

#### EDGE-3: 空バッファでの削除
```dart
final container = ProviderContainer();
final notifier = container.read(inputBufferProvider.notifier);

// 空の状態で削除
notifier.deleteLastCharacter();

// 何も起こらない（空のまま）
expect(container.read(inputBufferProvider), '');
```

#### EDGE-4: 空文字の追加試行
```dart
final container = ProviderContainer();
final notifier = container.read(inputBufferProvider.notifier);
notifier.setText('あいう');

// 空文字を追加しようとする
notifier.addCharacter('');

// 何も起こらない
expect(container.read(inputBufferProvider), 'あいう');
```

#### EDGE-5: Unicode絵文字の取り扱い 🔴
```dart
final container = ProviderContainer();
final notifier = container.read(inputBufferProvider.notifier);

// 絵文字を追加（サロゲートペアを含む可能性）
notifier.addCharacter('😀');

// 絵文字も1文字として扱う（grapheme cluster単位）
expect(container.read(inputBufferProvider), '😀');
```

### エラーケース 🟡

#### エラー1: 制御文字の入力
```dart
// 制御文字（改行、タブ等）は許可しない
notifier.addCharacter('\n');
// 入力されない、またはエラー
```

### 参照したEARS要件

- **REQ-002**: 文字追加 🔵
- **REQ-003**: 文字削除 🔵
- **REQ-004**: 全消去 🔵
- **EDGE-101**: 1000文字制限 🟡

### 参照した設計文書

- **dataflow.md**: 状態管理フロー（Riverpod）セクション

---

## 5. EARS要件・設計文書との対応関係

### 参照したユーザストーリー 🔵

- **ストーリー名**: 「文字入力機能」
- **As a**: 発話が困難なユーザー
- **I want to**: 文字盤をタップして文字を入力したい
- **So that**: 自分の伝えたいことをテキストとして作成できる

### 参照した機能要件 🔵

| 要件ID | 要件内容 | 信頼性レベル |
|--------|----------|--------------|
| REQ-002 | システムは文字盤の文字をタップすると入力欄に文字を追加しなければならない | 🔵 |
| REQ-003 | システムは削除ボタンで最後の1文字を削除する機能を提供しなければならない | 🔵 |
| REQ-004 | システムは全消去ボタンで入力欄のすべての文字を削除する機能を提供しなければならない | 🔵 |

### 参照した非機能要件 🟡

| 要件ID | 要件内容 | 信頼性レベル |
|--------|----------|--------------|
| NFR-003 | 文字盤タップから入力欄への文字反映まで100ms以内 | 🔵 |
| NFR-101 | 入力内容は端末内にのみ保存 | 🔵 |
| NFR-301 | 重大なエラーでも基本機能は継続動作 | 🔵 |
| NFR-302 | クラッシュ復旧時に入力状態を復元 | 🟡 |

### 参照したEdgeケース 🟡

| 要件ID | 要件内容 | 信頼性レベル |
|--------|----------|--------------|
| EDGE-101 | 1000文字制限時の警告・制限 | 🟡 |
| EDGE-201 | バックグラウンド復帰時の状態復元 | 🟡 |

### 参照した設計文書 🔵

#### アーキテクチャ
- **architecture.md**: フロントエンド（Flutter）- Riverpod 2.x状態管理設計

#### データフロー
- **dataflow.md**: 状態管理フロー（Riverpod）

#### 型定義
- **interfaces.dart**: 469-515行目（`InputScreenState`クラス - inputTextフィールド）

---

## 6. 実装範囲の定義

### 実装対象 🔵

#### 本タスクで実装する機能

1. **InputBufferNotifier クラス**:
   - Riverpod StateNotifierを使用
   - 状態の型は`String`（入力バッファの内容）

2. **入力バッファ操作メソッド**:
   - `addCharacter(String character)`: 1文字追加
   - `deleteLastCharacter()`: 最後の1文字削除
   - `clear()`: 全消去
   - `setText(String text)`: テキスト設定（定型文挿入等に使用）

3. **バリデーション**:
   - 1000文字制限のチェック
   - 空文字追加の防止
   - 空バッファ削除時の安全処理

4. **Providerの定義**:
   ```dart
   final inputBufferProvider = StateNotifierProvider<InputBufferNotifier, String>((ref) {
     return InputBufferNotifier();
   });
   ```

5. **テスト実装**:
   - 初期状態テスト（空文字列）
   - 文字追加テスト
   - 文字削除テスト
   - 全消去テスト
   - 1000文字制限テスト
   - エッジケーステスト

### 実装範囲外（後続タスクで実装） 🟡

#### TASK-0039（削除・全消去ボタン）で実装
- 削除ボタンUI
- 全消去ボタンUI
- 全消去確認ダイアログ

#### TASK-0059（データ永続化テスト）で実装
- 入力バッファの永続化（SharedPreferences/Hive）
- アプリクラッシュからの復元

#### Phase 3後半以降で実装
- 入力バッファとTTS読み上げの連携
- AI変換との連携
- 履歴保存との連携

---

## 7. 受け入れ基準

### 機能要件の受け入れ基準 🔵

| ID | 基準 | 検証方法 |
|----|------|----------|
| AC-001 | 文字を追加すると入力バッファに反映される | 単体テスト |
| AC-002 | 複数の文字を連続して追加できる | 単体テスト |
| AC-003 | 削除で最後の1文字が削除される | 単体テスト |
| AC-004 | 全消去でバッファが空になる | 単体テスト |
| AC-005 | setTextでバッファ内容を設定できる | 単体テスト |
| AC-006 | 状態変更がリアルタイムでUIに反映される | ウィジェットテスト |

### 非機能要件の受け入れ基準 🔵

| ID | 基準 | 検証方法 |
|----|------|----------|
| AC-007 | 文字追加が100ms以内に完了する | パフォーマンステスト |
| AC-008 | 1000文字を超える入力は制限される | 単体テスト |
| AC-009 | 空バッファでの削除はエラーにならない | 単体テスト |
| AC-010 | 空文字の追加は無視される | 単体テスト |

### エッジケースの受け入れ基準 🟡

| ID | 基準 | 検証方法 |
|----|------|----------|
| AC-011 | 1000文字のバッファに追加しても1000文字のまま | 単体テスト |
| AC-012 | 1001文字以上のsetTextは1000文字で切り捨て | 単体テスト |
| AC-013 | 絵文字も1文字として正しく扱われる | 単体テスト |

---

## 8. 品質判定基準

### 高品質の条件

#### 要件の明確さ
- [x] 入力バッファの操作メソッドが明確（addCharacter, deleteLastCharacter, clear, setText）
- [x] 入力制限が具体的（1000文字）
- [x] 状態管理のパターンが明確（Riverpod StateNotifier）

#### 入出力定義の完全性
- [x] 状態の型が明確（String）
- [x] 初期値が明確（空文字列）
- [x] 各メソッドの引数・戻り値が明確

#### 制約条件の明確さ
- [x] パフォーマンス要件: 100ms以内
- [x] 文字数制限: 最大1000文字
- [x] エラーハンドリング: 空バッファ削除時の安全処理

#### 実装可能性
- [x] Riverpod 2.xのベストプラクティスに準拠
- [x] TASK-0013で構築した基盤を活用
- [x] テストが実装可能（ProviderContainerを使用）

### 改善が必要な点

#### 永続化の詳細
- 入力バッファの永続化タイミング・方法は後続タスクで詳細化
- デバウンス処理の実装詳細は実装時に決定

#### Unicode処理の詳細 🔴
- 絵文字（サロゲートペア、grapheme cluster）の取り扱いは実装時に検証
- 現時点では基本的な日本語文字を想定

---

## 9. 次のステップ

### 推奨コマンド
次は `/tsumiki:tdd-testcases` でテストケースの洗い出しを行います。

### テストケースで確認すべき項目

1. **初期状態テスト**: 空文字列の確認
2. **文字追加テスト**: 単一文字、連続追加
3. **文字削除テスト**: 通常削除、空バッファでの削除
4. **全消去テスト**: 入力ありからの消去
5. **setText テスト**: 通常設定、空文字設定
6. **1000文字制限テスト**: 境界値テスト（999, 1000, 1001文字）
7. **状態通知テスト**: Riverpod stateが正しく更新されることを確認
8. **エッジケーステスト**: 空文字追加、連続削除

---

## 更新履歴

- **2025-11-22**: TDD要件定義書作成
  - EARS要件定義書（REQ-002, REQ-003, REQ-004, EDGE-101）を参照
  - architecture.md、dataflow.md、interfaces.dartから設計情報を抽出
  - Phase 3タスク（TASK-0038）の実装詳細を反映
  - TASK-0013（Riverpod設定）の実装パターンを参考に作成
  - 信頼性レベル（🔵🟡🔴）を各セクションに明記
