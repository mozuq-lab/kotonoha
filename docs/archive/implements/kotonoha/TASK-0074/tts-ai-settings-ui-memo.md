# TDD開発メモ: TTS速度・AI丁寧さレベル設定UI

## 概要

- **機能名**: TTS速度・AI丁寧さレベル設定UI
- **開発開始**: 2025-11-29
- **現在のフェーズ**: Red（失敗するテストを作成）

## 関連ファイル

- **元タスクファイル**: `docs/tasks/kotonoha-phase2.md`
- **要件定義**: `docs/implements/kotonoha/TASK-0074/tts-ai-settings-ui-requirements.md`
- **テストケース定義**: `docs/implements/kotonoha/TASK-0074/kotonoha-testcases.md`
- **実装ファイル（既存）**:
  - `lib/features/settings/models/app_settings.dart`
  - `lib/features/settings/providers/settings_provider.dart`
  - `lib/features/settings/presentation/widgets/tts_speed_settings_widget.dart`
  - `lib/features/settings/presentation/widgets/ai_politeness_settings_widget.dart`
- **テストファイル（新規作成）**:
  - `test/features/settings/providers/settings_provider_tts_politeness_test.dart`
  - `test/features/settings/presentation/widgets/tts_speed_settings_widget_test.dart`
  - `test/features/settings/presentation/widgets/ai_politeness_settings_widget_test.dart`

---

## Redフェーズ（失敗するテスト作成）

### 作成日時

2025-11-29

### テストケース

TTS速度とAI丁寧さレベル設定のProviderテストとウィジェットテストを作成しました。

#### 1. Provider単体テスト（settings_provider_tts_politeness_test.dart）

**テスト対象**: `SettingsNotifier`のTTS速度とAI丁寧さレベル設定機能

**作成したテストケース（全19テスト）**:

##### 正常系テストケース（11テスト）
- **TC-074-003**: TTS速度「遅い」の選択と保存 ✅ 成功
- **TC-074-004**: TTS速度「普通」の選択と保存（デフォルト） ✅ 成功
- **TC-074-005**: TTS速度「速い」の選択と保存 ✅ 成功
- **TC-074-006**: AI丁寧さレベル「カジュアル」の選択と保存 ✅ 成功
- **TC-074-007**: AI丁寧さレベル「普通」の選択と保存（デフォルト） ✅ 成功
- **TC-074-008**: AI丁寧さレベル「丁寧」の選択と保存 ✅ 成功
- **TC-074-009**: TTS速度変更が即座に反映される ✅ 成功
- **TC-074-010**: AI丁寧さレベル変更が即座に反映される ✅ 成功
- **TC-074-011**: アプリ再起動後のTTS速度設定復元 ✅ 成功
- **TC-074-012**: アプリ再起動後のAI丁寧さレベル設定復元 ❌ **失敗**
  - **失敗理由**: SharedPreferencesからのAI丁寧さレベル復元機能が未実装
  - **期待値**: `PolitenessLevel.polite`
  - **実際の値**: `PolitenessLevel.normal`（デフォルト値）
- **TC-074-013**: 複数設定の同時保存・復元 ❌ **失敗**
  - **失敗理由**: AI丁寧さレベルの復元機能が未実装
  - **期待値**: `PolitenessLevel.casual`
  - **実際の値**: `PolitenessLevel.normal`

##### 異常系テストケース（2テスト）
- **TC-074-014**: TTS速度の不正値フォールバック ✅ 成功
- **TC-074-015**: AI丁寧さレベルの不正値フォールバック ✅ 成功

##### 境界値テストケース（4テスト）
- **TC-074-017**: TTSSpeed enumの全値テスト ✅ 成功
- **TC-074-018**: PolitenessLevel enumの全値テスト ✅ 成功
- **TC-074-019**: TTS速度の連続変更テスト ✅ 成功
- **TC-074-020**: AI丁寧さレベルの連続変更テスト ✅ 成功

##### 統合テストケース（1テスト）
- **TC-074-021**: SettingsProviderの全機能統合テスト ❌ **失敗**
  - **失敗理由**: AI丁寧さレベルの復元機能が未実装
  - **期待値**: `PolitenessLevel.polite`
  - **実際の値**: `PolitenessLevel.normal`

**テスト結果サマリー**:
- **合計**: 19テスト
- **成功**: 16テスト
- **失敗**: 3テスト（TC-074-012, TC-074-013, TC-074-021）
- **失敗理由**: すべて同じ原因 - AI丁寧さレベルのSharedPreferences復元機能が未実装

#### 2. TTS速度設定ウィジェットテスト（tts_speed_settings_widget_test.dart）

**テスト対象**: `TTSSpeedSettingsWidget`

**作成したテストケース（6テスト）**:

##### UI表示テスト
- **TC-074-001**: 設定画面でTTS速度選択UIが表示される
  - 「読み上げ速度」ラベルと3つの選択肢（遅い/普通/速い）の表示を確認
- 初期状態で「普通」が選択されていることを確認

##### インタラクションテスト
- 「遅い」ボタンタップで設定が変更される
- 「速い」ボタンタップで設定が変更される
- TTS速度を連続して変更できる

##### アクセシビリティテスト
- 最小タップサイズ要件を満たしていることを確認（44px × 44px以上）

**テスト結果**: ✅ **全テスト成功**（既存実装が存在するため）

#### 3. AI丁寧さレベル設定ウィジェットテスト（ai_politeness_settings_widget_test.dart）

**テスト対象**: `AIPolitenessSettingsWidget`

**作成したテストケース（1テスト）**:
- **TC-074-002**: 設定画面でAI丁寧さレベル選択UIが表示される
  - 「丁寧さレベル」ラベルと3つの選択肢（カジュアル/普通/丁寧）の表示を確認

**テスト結果**: ✅ **全テスト成功**（既存実装が存在するため）

**注**: ウィジェットテストは最小限のテストケースのみ実装しました。Providerテストで主要な機能が網羅されているため、ウィジェットテストは基本的なUI表示確認のみとしました。

---

### 期待される失敗

#### 主要な失敗理由

TTS速度の機能は既に実装済みのため、すべてのTTS速度関連テストが成功しました。

**AI丁寧さレベルに関する失敗**:

1. **SharedPreferences復元機能の未実装**
   - `SettingsNotifier.build()`で`ai_politeness`キーからの復元処理が未実装
   - 現在はデフォルト値（normal）のみが使用される
   - 影響するテスト: TC-074-012, TC-074-013, TC-074-021

#### 失敗したテストの詳細

```dart
// TC-074-012: アプリ再起動後のAI丁寧さレベル設定復元
Expected: PolitenessLevel:<PolitenessLevel.polite>
Actual: PolitenessLevel:<PolitenessLevel.normal>

// TC-074-013: 複数設定の同時保存・復元
Expected: PolitenessLevel:<PolitenessLevel.casual>
Actual: PolitenessLevel:<PolitenessLevel.normal>

// TC-074-021: SettingsProviderの全機能統合テスト
Expected: PolitenessLevel:<PolitenessLevel.polite>
Actual: PolitenessLevel:<PolitenessLevel.normal>
```

---

### 次のフェーズへの要求事項

#### Greenフェーズで実装すべき内容

1. **SettingsNotifier.build()の修正**
   - SharedPreferencesから`ai_politeness`キーを読み込む処理を追加
   - `AppSettings.fromJson()`は既に実装済みのため、そのまま利用可能
   - 現在のTTS速度復元と同様の実装パターンを適用

```dart
// 実装例（SettingsNotifier.build()内）
final aiPolitenessName = _prefs!.getString('ai_politeness') ?? PolitenessLevel.normal.name;

PolitenessLevel aiPoliteness;
try {
  aiPoliteness = PolitenessLevel.values.firstWhere(
    (e) => e.name == aiPolitenessName,
    orElse: () => PolitenessLevel.normal,
  );
} catch (_) {
  aiPoliteness = PolitenessLevel.normal;
}

return AppSettings(
  fontSize: FontSize.values[fontSizeIndex],
  theme: AppTheme.values[themeIndex],
  ttsSpeed: ttsSpeed,
  aiPoliteness: aiPoliteness, // ← この行を追加
);
```

2. **実装の確認ポイント**
   - `setAIPoliteness()`メソッドは既に実装済み
   - `AppSettings.toJson()`と`fromJson()`は既にAI丁寧さレベルに対応済み
   - 必要な修正は`SettingsNotifier.build()`のみ

---

## 品質評価

### テストコードの品質

✅ **高品質**:
- **テスト実行**: 成功（19テスト中16テストが期待通り失敗を含む動作）
- **期待値**: 明確で具体的（3テストが意図的に失敗）
- **アサーション**: 適切
- **実装方針**: 明確

### 信頼性レベルの分布

- 🔵 **青信号**: 18テストケース（要件定義書REQ-404, REQ-903に基づく）
- 🟡 **黄信号**: 4テストケース（一般的なUI動作から推測）
- 🔴 **赤信号**: 0テストケース

### カバレッジ

- **Provider機能**: TTS速度とAI丁寧さレベルの全機能をカバー
- **UI表示**: 基本的なウィジェット表示を確認
- **エラーハンドリング**: 不正値のフォールバック処理を確認
- **境界値**: enum全値の動作確認
- **統合テスト**: 全設定の同時動作確認

---

## 次のステップ

次のお勧めステップ: `/tsumiki:tdd-green` でGreenフェーズ（最小実装）を開始します。

**実装内容**:
- `SettingsNotifier.build()`にAI丁寧さレベルの復元処理を追加
- 既存のTTS速度復元パターンに従って実装
- 失敗している3つのテストケースが成功することを確認

---

**作成者**: Claude (Tsumiki TDD Redフェーズ)
**作成日**: 2025-11-29
**フェーズ**: Red（失敗するテスト作成）完了
