# テストケース定義書: TASK-0074 TTS速度・AI丁寧さレベル設定UI

## メタ情報

- **タスクID**: TASK-0074
- **タスク名**: TTS速度・AI丁寧さレベル設定UI
- **関連要件**: REQ-404, REQ-903
- **依存タスク**: TASK-0071（設定画面UI実装）, TASK-0049（TTS速度設定）
- **作成日**: 2025-11-29
- **TDDフェーズ**: Redフェーズ（テストケース定義）

## 完了条件

- TTS速度を3段階（遅い/普通/速い）から選択できる
- AI丁寧さレベルを3段階（カジュアル/普通/丁寧）から選択できる
- 設定が即座に反映される
- 設定がアプリ再起動後も保持される

## 信頼性レベル凡例

- 🔵 青信号: 要件定義書に基づく確実なテストケース（REQ-404, REQ-903）
- 🟡 黄信号: 要件定義書から妥当な推測によるテストケース
- 🔴 赤信号: 要件定義書にない推測によるテストケース（実装後に要件確認が必要）

---

## 1. 正常系テストケース（基本動作）

### TC-074-001: 設定画面でTTS速度選択UIが表示される

**優先度**: P0（必須）
**関連要件**: REQ-404
**信頼性レベル**: 🔵 青信号
**テスト目的**: 設定画面にTTS速度選択UIが正しく表示されることを確認

**前提条件**:
- アプリが正常に起動している
- 設定画面にアクセスできる

**テストステップ**:
1. 設定画面を開く
2. TTS速度セクションを確認

**期待される結果**:
- 「TTS速度」ラベルが表示される
- 「遅い」「普通」「速い」の3つの選択肢が表示される

**実装方針**:
- SettingsScreen に TTS速度選択ウィジェットが含まれる
- RadioButton または SegmentedButton で3段階選択が可能

---

### TC-074-002: 設定画面でAI丁寧さレベル選択UIが表示される

**優先度**: P0（必須）
**関連要件**: REQ-903
**信頼性レベル**: 🔵 青信号
**テスト目的**: 設定画面にAI丁寧さレベル選択UIが正しく表示されることを確認

**前提条件**:
- アプリが正常に起動している
- 設定画面にアクセスできる

**テストステップ**:
1. 設定画面を開く
2. AI丁寧さレベルセクションを確認

**期待される結果**:
- 「AI丁寧さレベル」ラベルが表示される
- 「カジュアル」「普通」「丁寧」の3つの選択肢が表示される

**実装方針**:
- SettingsScreen に AI丁寧さレベル選択ウィジェットが含まれる
- RadioButton または SegmentedButton で3段階選択が可能

---

### TC-074-003: TTS速度「遅い」の選択と保存

**優先度**: P0（必須）
**関連要件**: REQ-404, REQ-5003
**信頼性レベル**: 🔵 青信号
**テスト目的**: TTS速度「遅い」が正しく選択・保存されることを確認

**前提条件**:
- 設定画面が表示されている
- SharedPreferencesが初期化されている

**テストステップ**:
1. ProviderContainerを作成
2. settingsNotifierProvider.setTTSSpeed(TTSSpeed.slow)を呼び出し
3. 状態を確認

**期待される結果**:
- stateのttsSpeedがslowに更新される
- SharedPreferencesにtts_speed: "slow"が保存される

**実装方針**:
- SettingsNotifier.setTTSSpeed()メソッドを実装
- AppSettings.toJson()で"tts_speed"キーに保存

---

### TC-074-004: TTS速度「普通」の選択と保存（デフォルト）

**優先度**: P0（必須）
**関連要件**: REQ-404, REQ-5003
**信頼性レベル**: 🔵 青信号
**テスト目的**: デフォルト値「普通」が正しく動作することを確認

**前提条件**:
- SharedPreferencesが空（初回起動状態）

**テストステップ**:
1. ProviderContainerを作成
2. 初期状態を確認

**期待される結果**:
- 初期状態のttsSpeedがnormalになる
- デフォルト値として明示的に設定されている

**実装方針**:
- AppSettings()コンストラクタのデフォルト引数でnormalを設定

---

### TC-074-005: TTS速度「速い」の選択と保存

**優先度**: P0（必須）
**関連要件**: REQ-404, REQ-5003
**信頼性レベル**: 🔵 青信号
**テスト目的**: TTS速度「速い」が正しく選択・保存されることを確認

**前提条件**:
- 設定画面が表示されている
- SharedPreferencesが初期化されている

**テストステップ**:
1. ProviderContainerを作成
2. settingsNotifierProvider.setTTSSpeed(TTSSpeed.fast)を呼び出し
3. 状態を確認

**期待される結果**:
- stateのttsSpeedがfastに更新される
- SharedPreferencesにtts_speed: "fast"が保存される

**実装方針**:
- SettingsNotifier.setTTSSpeed()メソッドを実装

---

### TC-074-006: AI丁寧さレベル「カジュアル」の選択と保存

**優先度**: P0（必須）
**関連要件**: REQ-903, REQ-5003
**信頼性レベル**: 🔵 青信号
**テスト目的**: AI丁寧さレベル「カジュアル」が正しく選択・保存されることを確認

**前提条件**:
- 設定画面が表示されている
- SharedPreferencesが初期化されている

**テストステップ**:
1. ProviderContainerを作成
2. settingsNotifierProvider.setAIPoliteness(PolitenessLevel.casual)を呼び出し
3. 状態を確認

**期待される結果**:
- stateのaiPolitenessがcasualに更新される
- SharedPreferencesにai_politeness: "casual"が保存される

**実装方針**:
- SettingsNotifier.setAIPoliteness()メソッドを実装
- AppSettings.toJson()で"ai_politeness"キーに保存

---

### TC-074-007: AI丁寧さレベル「普通」の選択と保存（デフォルト）

**優先度**: P0（必須）
**関連要件**: REQ-903, REQ-5003
**信頼性レベル**: 🔵 青信号
**テスト目的**: デフォルト値「普通」が正しく動作することを確認

**前提条件**:
- SharedPreferencesが空（初回起動状態）

**テストステップ**:
1. ProviderContainerを作成
2. 初期状態を確認

**期待される結果**:
- 初期状態のaiPolitenessがnormalになる
- デフォルト値として明示的に設定されている

**実装方針**:
- AppSettings()コンストラクタのデフォルト引数でnormalを設定

---

### TC-074-008: AI丁寧さレベル「丁寧」の選択と保存

**優先度**: P0（必須）
**関連要件**: REQ-903, REQ-5003
**信頼性レベル**: 🔵 青信号
**テスト目的**: AI丁寧さレベル「丁寧」が正しく選択・保存されることを確認

**前提条件**:
- 設定画面が表示されている
- SharedPreferencesが初期化されている

**テストステップ**:
1. ProviderContainerを作成
2. settingsNotifierProvider.setAIPoliteness(PolitenessLevel.polite)を呼び出し
3. 状態を確認

**期待される結果**:
- stateのaiPolitenessがpoliteに更新される
- SharedPreferencesにai_politeness: "polite"が保存される

**実装方針**:
- SettingsNotifier.setAIPoliteness()メソッドを実装

---

### TC-074-009: TTS速度変更が即座に反映される

**優先度**: P0（必須）
**関連要件**: REQ-404
**信頼性レベル**: 🔵 青信号
**テスト目的**: TTS速度変更が楽観的更新で即座にstateに反映されることを確認

**前提条件**:
- ProviderContainerが初期化されている

**テストステップ**:
1. setTTSSpeed(TTSSpeed.slow)を呼び出し
2. 即座にstateを確認

**期待される結果**:
- SharedPreferences保存の完了を待たずにstateが更新される
- UI再描画がブロッキングされない

**実装方針**:
- 楽観的更新パターン（state更新後にSharedPreferences保存）

---

### TC-074-010: AI丁寧さレベル変更が即座に反映される

**優先度**: P0（必須）
**関連要件**: REQ-903
**信頼性レベル**: 🔵 青信号
**テスト目的**: AI丁寧さレベル変更が楽観的更新で即座にstateに反映されることを確認

**前提条件**:
- ProviderContainerが初期化されている

**テストステップ**:
1. setAIPoliteness(PolitenessLevel.polite)を呼び出し
2. 即座にstateを確認

**期待される結果**:
- SharedPreferences保存の完了を待たずにstateが更新される
- UI再描画がブロッキングされない

**実装方針**:
- 楽観的更新パターン（state更新後にSharedPreferences保存）

---

### TC-074-011: アプリ再起動後のTTS速度設定復元

**優先度**: P0（必須）
**関連要件**: REQ-5003
**信頼性レベル**: 🔵 青信号
**テスト目的**: アプリ再起動後に保存したTTS速度が復元されることを確認

**前提条件**:
- SharedPreferencesにtts_speed: "fast"が保存されている

**テストステップ**:
1. 新しいProviderContainerを作成（再起動を模擬）
2. settingsNotifierProvider.futureを読み込み
3. 設定を確認

**期待される結果**:
- ttsSpeedがfastとして復元される

**実装方針**:
- AppSettings.fromJson()でSharedPreferencesから復元

---

### TC-074-012: アプリ再起動後のAI丁寧さレベル設定復元

**優先度**: P0（必須）
**関連要件**: REQ-5003
**信頼性レベル**: 🔵 青信号
**テスト目的**: アプリ再起動後に保存したAI丁寧さレベルが復元されることを確認

**前提条件**:
- SharedPreferencesにai_politeness: "polite"が保存されている

**テストステップ**:
1. 新しいProviderContainerを作成（再起動を模擬）
2. settingsNotifierProvider.futureを読み込み
3. 設定を確認

**期待される結果**:
- aiPolitenessがpoliteとして復元される

**実装方針**:
- AppSettings.fromJson()でSharedPreferencesから復元

---

### TC-074-013: 複数設定の同時保存・復元

**優先度**: P0（必須）
**関連要件**: REQ-404, REQ-903, REQ-5003
**信頼性レベル**: 🔵 青信号
**テスト目的**: TTS速度とAI丁寧さレベルの両方が正しく保存・復元されることを確認

**前提条件**:
- SharedPreferencesが初期化されている

**テストステップ**:
1. setTTSSpeed(TTSSpeed.slow)を呼び出し
2. setAIPoliteness(PolitenessLevel.casual)を呼び出し
3. 新しいProviderContainerを作成（再起動を模擬）
4. 設定を確認

**期待される結果**:
- ttsSpeedがslowとして復元される
- aiPolitenessがcasualとして復元される
- 他の設定（fontSize, theme）も影響を受けない

**実装方針**:
- AppSettings.toJson()/fromJson()で全設定を保持

---

## 2. 異常系テストケース（エラーハンドリング）

### TC-074-014: TTS速度の不正値フォールバック

**優先度**: P1（高優先度）
**関連要件**: NFR-301（基本機能継続）
**信頼性レベル**: 🟡 黄信号
**テスト目的**: SharedPreferencesに不正なTTS速度値が保存されている場合のエラーハンドリング

**前提条件**:
- SharedPreferencesにtts_speed: "invalid_value"が保存されている

**テストステップ**:
1. ProviderContainerを作成
2. 設定読み込みを実行

**期待される結果**:
- エラーが発生せず、デフォルト値（normal）にフォールバックする
- アプリがクラッシュしない

**実装方針**:
- AppSettings.fromJson()でtry-catchを使用
- 不正値の場合はデフォルト値を使用

---

### TC-074-015: AI丁寧さレベルの不正値フォールバック

**優先度**: P1（高優先度）
**関連要件**: NFR-301（基本機能継続）
**信頼性レベル**: 🟡 黄信号
**テスト目的**: SharedPreferencesに不正なAI丁寧さレベル値が保存されている場合のエラーハンドリング

**前提条件**:
- SharedPreferencesにai_politeness: "invalid_value"が保存されている

**テストステップ**:
1. ProviderContainerを作成
2. 設定読み込みを実行

**期待される結果**:
- エラーが発生せず、デフォルト値（normal）にフォールバックする
- アプリがクラッシュしない

**実装方針**:
- AppSettings.fromJson()でtry-catchを使用
- 不正値の場合はデフォルト値を使用

---

### TC-074-016: SharedPreferences保存失敗時の楽観的更新

**優先度**: P1（高優先度）
**関連要件**: NFR-301（基本機能継続）
**信頼性レベル**: 🟡 黄信号
**テスト目的**: SharedPreferences保存が失敗してもUI状態は更新されることを確認

**前提条件**:
- SharedPreferencesが初期化されている

**テストステップ**:
1. setTTSSpeed(TTSSpeed.fast)を呼び出し
2. 保存失敗をシミュレート（実装後にモックで検証）
3. stateを確認

**期待される結果**:
- stateは即座に更新される（楽観的更新）
- 保存失敗はログに記録される

**実装方針**:
- 楽観的更新パターンを採用
- 保存失敗時はログ出力のみ（UI反応性を優先）

---

## 3. 境界値テストケース

### TC-074-017: TTSSpeed enumの全値テスト

**優先度**: P0（必須）
**関連要件**: REQ-404
**信頼性レベル**: 🔵 青信号
**テスト目的**: TTSSpeed enumのすべての値（slow, normal, fast）が正しく動作することを確認

**前提条件**:
- SharedPreferencesが初期化されている

**テストステップ**:
1. TTSSpeed.valuesをループで処理
2. 各値についてsetTTSSpeed()を呼び出し
3. 保存・復元を確認

**期待される結果**:
- slow, normal, fastすべてが正しく保存・復元される
- enum nameとして"slow", "normal", "fast"が保存される

**実装方針**:
- AppSettings.toJson()でenum.nameを保存
- fromJson()でenum.nameから復元

---

### TC-074-018: PolitenessLevel enumの全値テスト

**優先度**: P0（必須）
**関連要件**: REQ-903
**信頼性レベル**: 🔵 青信号
**テスト目的**: PolitenessLevel enumのすべての値（casual, normal, polite）が正しく動作することを確認

**前提条件**:
- SharedPreferencesが初期化されている

**テストステップ**:
1. PolitenessLevel.valuesをループで処理
2. 各値についてsetAIPoliteness()を呼び出し
3. 保存・復元を確認

**期待される結果**:
- casual, normal, politeすべてが正しく保存・復元される
- enum nameとして"casual", "normal", "polite"が保存される

**実装方針**:
- AppSettings.toJson()でenum.nameを保存
- fromJson()でenum.nameから復元

---

### TC-074-019: TTS速度の連続変更テスト

**優先度**: P1（高優先度）
**関連要件**: 一般的なUI動作
**信頼性レベル**: 🟡 黄信号
**テスト目的**: TTS速度を連続して変更しても状態が一貫することを確認

**前提条件**:
- ProviderContainerが初期化されている

**テストステップ**:
1. slow → normal → fast → slow の順に変更
2. 各変更後にstateを確認

**期待される結果**:
- すべての変更が正しく反映される
- 最終的にslowが設定されている
- SharedPreferencesにも最終値（slow）が保存されている

**実装方針**:
- 連続したsetTTSSpeed()呼び出しに対応

---

### TC-074-020: AI丁寧さレベルの連続変更テスト

**優先度**: P1（高優先度）
**関連要件**: 一般的なUI動作
**信頼性レベル**: 🟡 黄信号
**テスト目的**: AI丁寧さレベルを連続して変更しても状態が一貫することを確認

**前提条件**:
- ProviderContainerが初期化されている

**テストステップ**:
1. casual → normal → polite → casual の順に変更
2. 各変更後にstateを確認

**期待される結果**:
- すべての変更が正しく反映される
- 最終的にcasualが設定されている
- SharedPreferencesにも最終値（casual）が保存されている

**実装方針**:
- 連続したsetAIPoliteness()呼び出しに対応

---

## 4. 統合テストケース

### TC-074-021: SettingsProviderの全機能統合テスト

**優先度**: P0（必須）
**関連要件**: REQ-801, REQ-803, REQ-404, REQ-903
**信頼性レベル**: 🔵 青信号
**テスト目的**: AppSettingsの全フィールドが正しく動作することを確認

**前提条件**:
- SharedPreferencesが初期化されている

**テストステップ**:
1. フォントサイズ、テーマ、TTS速度、AI丁寧さレベルをすべて変更
2. 新しいProviderContainerを作成（再起動を模擬）
3. すべての設定が正しく復元されることを確認

**期待される結果**:
- fontSize: large
- theme: dark
- ttsSpeed: fast
- aiPoliteness: polite

すべての設定が正しく保存・復元される

**実装方針**:
- AppSettings.toJson()/fromJson()の統合動作確認

---

## テストカバレッジ目標

- **全体**: 80%以上
- **SettingsNotifier**: 90%以上（ビジネスロジック）
- **AppSettings**: 90%以上（データモデル）

## 実装順序

1. **TC-074-004, TC-074-007**: デフォルト値テスト（最も基本的な動作）
2. **TC-074-003, TC-074-005**: TTS速度の全選択肢テスト
3. **TC-074-006, TC-074-008**: AI丁寧さレベルの全選択肢テスト
4. **TC-074-009, TC-074-010**: 即座反映テスト
5. **TC-074-011, TC-074-012**: 再起動後復元テスト
6. **TC-074-013**: 複数設定の同時保存・復元テスト
7. **TC-074-017, TC-074-018**: enum全値テスト
8. **TC-074-001, TC-074-002**: UI表示テスト
9. **TC-074-014, TC-074-015**: 不正値フォールバックテスト
10. **TC-074-016**: SharedPreferences保存失敗テスト
11. **TC-074-019, TC-074-020**: 連続変更テスト
12. **TC-074-021**: 統合テスト

## 注意事項

### 既存実装との整合性
- AppSettings.fromJson()は既にTTS速度とAI丁寧さレベルのフォールバック処理を実装済み
- SettingsNotifierにsetTTSSpeed()とsetAIPoliteness()メソッドを追加する必要がある
- フォントサイズとテーマの既存テストに影響を与えないこと

### SharedPreferences保存形式
- TTS速度: `tts_speed: "slow" | "normal" | "fast"`（enum name）
- AI丁寧さレベル: `ai_politeness: "casual" | "normal" | "polite"`（enum name）

### パフォーマンス要件
- 設定変更は即座に反映される（楽観的更新）
- SharedPreferences保存は非同期で行われる

### エラーハンドリング
- 不正値の場合は必ずデフォルト値（normal）にフォールバックする
- アプリがクラッシュしないことを最優先

---

## 参考資料

- `lib/features/settings/models/app_settings.dart` - AppSettingsモデル（既存実装）
- `lib/features/tts/domain/models/tts_speed.dart` - TTSSpeed enum定義
- `lib/features/ai_conversion/domain/models/politeness_level.dart` - PolitenessLevel enum定義
- `test/features/settings/providers/settings_provider_test.dart` - 既存テストパターン
- `test/features/settings/providers/settings_provider_font_size_test.dart` - フォントサイズテストパターン
- `test/features/settings/providers/settings_provider_theme_test.dart` - テーマテストパターン

---

**作成者**: Claude (Tsumiki TDD)
**レビュー状態**: 未レビュー
**最終更新日**: 2025-11-29
