# TASK-0074: TTS速度・AI丁寧さレベル設定UI - TDD要件定義書

## 概要

**タスクID**: TASK-0074
**タスク名**: TTS速度・AI丁寧さレベル設定UI
**要件名**: kotonoha
**関連要件**: REQ-404, REQ-903
**依存タスク**: TASK-0071（設定画面UI実装）、TASK-0049（TTS速度設定）
**作成日**: 2025-11-29

---

## 1. 機能の概要（EARS要件定義書・設計文書ベース）

### 機能概要 🔵

本機能は、設定画面においてTTS速度とAI丁寧さレベルの設定UIを提供するものである。既にTASK-0071で設定画面の基本構造は実装されており、TASK-0049でTTS速度設定のバックエンド機能は実装済みである。本タスクでは、これらの既存実装を統合し、ユーザーが直感的に設定を変更できるUIを完成させる。

**参照したEARS要件**:
- **REQ-404**: システムは読み上げ速度を「遅い」「普通」「速い」の3段階から選択できなければならない 🔵
- **REQ-903**: システムはAI変換の丁寧さレベルを「カジュアル」「普通」「丁寧」の3段階から選択できなければならない 🔵

### 何をする機能か 🔵

1. **TTS速度選択UI**（既に実装済み）
   - 読み上げ速度を「遅い」「普通」「速い」の3段階から選択
   - 選択状態を視覚的に明示（ハイライト表示）
   - 設定変更時の即時反映

2. **AI丁寧さレベル選択UI**（既に実装済み）
   - AI変換の丁寧さレベルを「カジュアル」「普通」「丁寧」の3段階から選択
   - 選択状態を視覚的に明示
   - 設定変更時の即時反映

3. **プレビュー機能**
   - TTS速度変更時にテスト読み上げボタンを提供（オプション）
   - 設定の永続化により、変更が即座に保存される

4. **設定の永続化** 🔵
   - SharedPreferencesによるローカル保存
   - アプリ再起動後も設定を保持

### どのような問題を解決するか 🔵

**ユーザストーリー**: "読み上げ設定・AI変換設定を調整したい"

**As a** 発話困難なユーザー
**I want to** 読み上げ速度とAI変換の丁寧さレベルを簡単に設定したい
**So that** コミュニケーションの相手や状況に応じて最適な設定で伝えられる

**解決する問題**:
1. 高齢者や聴覚に配慮が必要な相手には、ゆっくりとした速度（遅い: 0.7倍速）で伝える
2. 標準的な速度（普通: 1.0倍速）で自然な会話を実現する
3. アプリに慣れたユーザーは効率的な速度（速い: 1.3倍速）で素早く伝える
4. 家族との会話では「カジュアル」、医師との会話では「丁寧」など、相手に応じた丁寧さレベルを選択できる

### 想定されるユーザー 🔵

- 脳梗塞・ALS・筋疾患などで発話が困難だが、タブレットのタップ操作がある程度可能な方
- コミュニケーションの相手（家族、介護スタッフ、医師、看護師）の状況に応じて設定調整が必要な方
- 支援者（家族、介護スタッフ）がユーザーに代わって初期設定を行う場合

### システム内での位置づけ 🔵

**参照した設計文書**: architecture.md（オフラインファースト設計）

- **アーキテクチャ**: オフラインファーストクライアント
- **レイヤー**: プレゼンテーション層（UI）
- **既存実装との関係**:
  - `SettingsScreen`（TASK-0071で実装済み）にセクション分けされた設定UI
  - `TTSSpeedSettingsWidget`（TASK-0049で実装済み）を設定画面に統合
  - `AIPolitenessSettingsWidget`（TASK-0071で実装済み）を設定画面に統合
  - `SettingsNotifier`（Riverpod AsyncNotifier）で状態管理
  - `AppSettings`モデルで設定データ管理

---

## 2. 入力・出力の仕様（EARS機能要件・TypeScript型定義ベース）

### 入力パラメータ 🔵

**参照した設計文書**: interfaces.dart（298-319行目: TTSSpeed, 252-268行目: PolitenessLevel）

#### 2.1. TTS速度選択

**型**: `TTSSpeed` enum
```dart
enum TTSSpeed {
  slow,   // 遅い（0.7倍速）
  normal, // 普通（1.0倍速）
  fast,   // 速い（1.3倍速）
}
```

**選択方法**:
- 3つの選択肢ボタン（Row配置）
- タップで選択、現在の選択状態をハイライト表示
- 最小タップサイズ: 60px × 44px（アクセシビリティ要件準拠）

**初期値**: `TTSSpeed.normal`（1.0倍速）

#### 2.2. AI丁寧さレベル選択

**型**: `PolitenessLevel` enum
```dart
enum PolitenessLevel {
  casual, // カジュアル
  normal, // 普通
  polite, // 丁寧
}
```

**選択方法**:
- SegmentedButton（Flutter Material 3標準ウィジェット）
- 3つの選択肢から1つを選択
- 最小タップサイズ: 44px × 44px以上

**初期値**: `PolitenessLevel.normal`（普通）

### 出力値  🔵

#### 2.1. 状態管理への反映

**対象**: `SettingsNotifier` (Riverpod AsyncNotifier)

- `setTTSSpeed(TTSSpeed speed)`: TTS速度を変更
  - `AppSettings`の`ttsSpeed`フィールドを更新
  - SharedPreferencesに保存（キー: `'tts_speed'`, 値: enum name）
  - `TTSNotifier.setSpeed()`を呼び出してTTSエンジンに反映

- `setAIPoliteness(PolitenessLevel level)`: AI丁寧さレベルを変更
  - `AppSettings`の`aiPoliteness`フィールドを更新
  - SharedPreferencesに保存（キー: `'ai_politeness'`, 値: enum name）

#### 2.2. UI表示

**TTS速度選択UI**:
- 現在選択されている速度をハイライト表示（プライマリカラー背景 + 白テキスト）
- 非選択: 白背景 + プライマリカラーボーダー + プライマリカラーテキスト

**AI丁寧さレベル選択UI**:
- `SegmentedButton`の標準スタイル（Material 3デザイン）
- 選択状態を自動的にハイライト表示

### 入出力の関係性 🔵

```
[ユーザータップ]
  ↓
[TTSSpeedSettingsWidget / AIPolitenessSettingsWidget]
  ↓
[ref.read(settingsNotifierProvider.notifier).setTTSSpeed() / setAIPoliteness()]
  ↓
[SettingsNotifier] → 楽観的更新（state即座更新）
  ↓                ↓
[SharedPreferences保存] [TTSNotifier.setSpeed()呼び出し（TTS速度のみ）]
  ↓
[UI自動再レンダリング（Riverpod）]
```

### データフロー 🔵

**参照した設計文書**: dataflow.md（設定変更フロー）

1. **ユーザー操作**: ボタンタップ
2. **楽観的更新**: `SettingsNotifier`のstateを即座更新（REQ-2007, REQ-2008準拠）
3. **永続化**: SharedPreferencesに非同期保存
4. **TTS連携**: TTS速度の場合、`TTSNotifier.setSpeed()`を呼び出し
5. **UI反映**: Riverpodのwatch機構により自動的に全画面に反映

---

## 3. 制約条件（EARS非機能要件・アーキテクチャ設計ベース）

### パフォーマンス要件 🔵

**参照したEARS要件**: NFR-003, REQ-2007, REQ-2008

- **設定変更の即時反映**: 100ms以内
  - 楽観的更新により、SharedPreferences保存完了を待たずにUI状態を更新
  - Riverpodのstateが即座に更新され、UIが自動再レンダリング

- **SharedPreferences保存**: 非同期処理（UI応答性に影響なし）
  - 保存失敗時もUI状態は維持（再起動時のみ設定が戻る）

### セキュリティ要件 🔵

**参照したEARS要件**: NFR-101, REQ-5003

- **ローカルストレージのみ**: クラウド同期なし
  - SharedPreferencesによる端末内保存
  - アプリ専用領域、他アプリからアクセス不可

### アクセシビリティ要件 🔵

**参照したEARS要件**: REQ-5001, NFR-202

- **タップターゲットサイズ**: 44px × 44px以上（推奨: 60px × 60px）
  - TTS速度ボタン: 60px × 44px
  - AI丁寧さレベルボタン: SegmentedButtonのデフォルトサイズ（44px以上）

- **視認性**: 現在の選択状態を明確に表示
  - コントラスト比: 高コントラストモードで4.5:1以上（WCAG 2.1 AA準拠）

### アーキテクチャ制約 🔵

**参照した設計文書**: architecture.md

- **オフライン動作**: すべての設定機能はネットワーク不要
- **単一端末完結**: 複数端末間での設定同期なし
- **データ永続化**: アプリクラッシュ時も設定を保持

### データベース制約 🟡

- SharedPreferences使用（キー・バリュー型ストレージ）
- データ型制約:
  - TTS速度: String型（enum name: 'slow', 'normal', 'fast'）
  - AI丁寧さレベル: String型（enum name: 'casual', 'normal', 'polite'）

### API制約 🔵

- 外部APIへの依存なし（すべてローカル処理）

---

## 4. 想定される使用例（EARSEdgeケース・データフローベース）

### 基本的な使用パターン 🔵

**参照したEARS要件**: REQ-404, REQ-903

#### パターン1: TTS速度変更
```
1. ユーザーが設定画面を開く
2. 音声設定セクションの「読み上げ速度」を確認
3. 「遅い」「普通」「速い」のいずれかをタップ
4. 選択したボタンがハイライト表示される（即座反映）
5. 次回の読み上げから新しい速度が適用される
```

#### パターン2: AI丁寧さレベル変更
```
1. ユーザーが設定画面を開く
2. AI設定セクションの「丁寧さレベル」を確認
3. 「カジュアル」「普通」「丁寧」のいずれかをタップ
4. 選択したボタンがハイライト表示される（即座反映）
5. 次回のAI変換から新しい丁寧さレベルが適用される
```

#### パターン3: 設定の永続化確認
```
1. ユーザーがTTS速度を「速い」、AI丁寧さレベルを「丁寧」に変更
2. アプリを終了（バックグラウンド、または完全終了）
3. アプリを再起動
4. 設定画面を開く
5. 前回の設定（速い + 丁寧）が保持されている
```

### データフロー 🔵

**参照した設計文書**: dataflow.md

#### TTS速度変更フロー
```
[ユーザー] タップ「遅い」
  ↓
[TTSSpeedSettingsWidget._onSpeedChanged()]
  ↓
[SettingsNotifier.setTTSSpeed(TTSSpeed.slow)]
  ↓ 即座更新（楽観的更新）
[state = AppSettings(ttsSpeed: slow, ...)]
  ↓ 並行処理
  ├─ [SharedPreferences.setString('tts_speed', 'slow')]
  └─ [TTSNotifier.setSpeed(TTSSpeed.slow)]
       ↓
      [flutter_tts.setSpeechRate(0.7)]
  ↓
[UI自動再レンダリング] ← Riverpodのwatch
```

#### AI丁寧さレベル変更フロー
```
[ユーザー] タップ「丁寧」
  ↓
[AIPolitenessSettingsWidget.onSelectionChanged()]
  ↓
[SettingsNotifier.setAIPoliteness(PolitenessLevel.polite)]
  ↓ 即座更新（楽観的更新）
[state = AppSettings(aiPoliteness: polite, ...)]
  ↓
[SharedPreferences.setString('ai_politeness', 'polite')]
  ↓
[UI自動再レンダリング] ← Riverpodのwatch
```

### エッジケース 🟡

**参照したEARS要件**: EDGE-001（ネットワークエラー）、EDGE-003（ストレージ容量不足）

#### エッジケース1: SharedPreferences保存失敗
```
Given: デバイスのストレージ容量不足またはファイルシステムエラー
When: ユーザーが設定を変更
Then:
  - UI状態は即座に更新される（楽観的更新）
  - 保存エラーは内部でキャッチされ、ユーザーには通知されない
  - アプリ再起動時に設定が元に戻る（デフォルト値または前回保存成功時の値）
```

#### エッジケース2: 初回起動（設定未保存）
```
Given: アプリ初回起動、SharedPreferencesに設定が存在しない
When: 設定画面を開く
Then:
  - TTS速度: デフォルト「普通」(normal)が選択されている
  - AI丁寧さレベル: デフォルト「普通」(normal)が選択されている
```

#### エッジケース3: 不正な設定値の復元
```
Given: SharedPreferencesに不正な値が保存されている（例: 'tts_speed' = 'invalid'）
When: アプリ起動時に設定を復元
Then:
  - SettingsNotifier.build()内でエラーをキャッチ
  - デフォルト値（normal）にフォールバック
  - アプリがクラッシュせず正常動作
```

### エラーケース 🟡

**参照したEARS要件**: NFR-301（基本機能継続性）

#### エラーケース1: TTS速度設定エラー
```
Given: TTS速度を変更
When: TTSNotifier.setSpeed()がエラーを返す（OSレベルの問題）
Then:
  - UI設定は更新される（ユーザーの意図を尊重）
  - 内部でエラーをキャッチし、ログ記録（将来実装）
  - 基本機能（設定画面操作）は継続動作
```

#### エラーケース2: 設定読み込みエラー
```
Given: アプリ起動時
When: SharedPreferences初期化に失敗
Then:
  - SettingsNotifier.build()のcatchブロックが実行
  - デフォルト設定（AppSettings()）を返す
  - 設定画面は正常に表示され、設定変更も可能
```

---

## 5. EARS要件・設計文書との対応関係

### 参照したユーザストーリー 🔵
- **ストーリー2.2**: "読み上げ設定を調整したい" - TTS速度調整
- （AI丁寧さレベルについては明示的なストーリーなし、REQ-903から派生）

### 参照した機能要件 🔵
- **REQ-404**: 読み上げ速度を「遅い」「普通」「速い」の3段階から選択可能
- **REQ-903**: AI変換の丁寧さレベルを「カジュアル」「普通」「丁寧」の3段階から選択可能
- **REQ-2007**: フォントサイズ変更時に即座に反映（設定変更の即時反映パターンの参考）
- **REQ-2008**: テーマ変更時に即座に反映（設定変更の即時反映パターンの参考）
- **REQ-5001**: タップターゲットサイズ 44px × 44px以上
- **REQ-5003**: 設定の永続化（アプリクラッシュ時も保持）

### 参照した非機能要件 🔵
- **NFR-003**: 文字盤タップ応答 100ms以内（設定変更も同様に即時反映）
- **NFR-101**: ローカルストレージ優先（SharedPreferences使用）
- **NFR-202**: タップ領域の視認性とアクセシビリティ
- **NFR-301**: エラー時も基本機能継続

### 参照したEdgeケース 🟡
- **EDGE-001**: ネットワークエラー時の処理（本機能ではオフライン動作のため影響なし）
- **EDGE-003**: ストレージ容量不足時の処理（SharedPreferences保存失敗）

### 参照した受け入れ基準 🔵
- TTS速度を3段階から選択できる
- AI丁寧さレベルを3段階から選択できる
- 設定が即座に反映される
- 設定がアプリ再起動後も保持される

### 参照した設計文書 🔵

#### アーキテクチャ
- **architecture.md**:
  - オフラインファースト設計（1-29行目）
  - ローカルストレージ優先（125-141行目）
  - 設定の永続化（167-172行目）

#### データフロー
- **dataflow.md**: 設定変更フロー（推定）

#### 型定義
- **interfaces.dart**:
  - `TTSSpeed` enum（298-319行目）
  - `PolitenessLevel` enum（252-268行目）
  - `AppSettings`クラス（213-274行目）

#### データベース
- SharedPreferences使用（SQLではない）

#### API仕様
- 外部API不要（ローカル処理のみ）

---

## 品質判定

### ✅ 高品質

- **要件の曖昧さ**: なし（REQ-404, REQ-903が明確）
- **入出力定義**: 完全（enum型、SharedPreferencesキー、デフォルト値すべて定義済み）
- **制約条件**: 明確（パフォーマンス、アクセシビリティ、アーキテクチャ制約すべて定義済み）
- **実装可能性**: 確実（既存実装を統合するのみ、新規実装は最小限）

---

## 次のステップ

次のお勧めステップ: `/tsumiki:tdd-testcases` でテストケースの洗い出しを行います。

---

## 更新履歴

- **2025-11-29**: TDD要件定義書作成（TASK-0074）
  - 既存実装（TASK-0049, TASK-0071）を基にUI統合要件を整理
  - EARS要件定義書、interfaces.dart、architecture.mdから詳細仕様を抽出
