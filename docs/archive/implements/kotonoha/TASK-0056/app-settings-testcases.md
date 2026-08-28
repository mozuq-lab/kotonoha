# アプリ設定保存（shared_preferences）テストケース一覧 - TASK-0056

## 概要
- **タスクID**: TASK-0056
- **タスク名**: アプリ設定保存（shared_preferences）
- **フェーズ**: TDDテストケース作成
- **作成日**: 2025-11-26

## テストケース分類

### 1. 正常系テスト（Normal Cases）

#### TC-056-001: フォントサイズを保存できる 🔵
- **対応要件**: REQ-801, FR-056-001
- **前提条件**: AppSettingsRepositoryが初期化されている
- **テスト手順**:
  1. FontSize.largeを保存する
  2. 設定を読み込む
- **期待結果**: fontSizeがFontSize.largeである

#### TC-056-002: テーマを保存できる 🔵
- **対応要件**: REQ-803, FR-056-002
- **前提条件**: AppSettingsRepositoryが初期化されている
- **テスト手順**:
  1. AppTheme.darkを保存する
  2. 設定を読み込む
- **期待結果**: themeがAppTheme.darkである

#### TC-056-003: TTS速度を保存できる 🔵
- **対応要件**: REQ-404, FR-056-003
- **前提条件**: AppSettingsRepositoryが初期化されている
- **テスト手順**:
  1. TtsSpeed.slowを保存する
  2. 設定を読み込む
- **期待結果**: ttsSpeedがTtsSpeed.slowである

#### TC-056-004: AI丁寧さレベルを保存できる 🔵
- **対応要件**: REQ-903, FR-056-004
- **前提条件**: AppSettingsRepositoryが初期化されている
- **テスト手順**:
  1. PolitenessLevel.politeを保存する
  2. 設定を読み込む
- **期待結果**: politenessLevelがPolitenessLevel.politeである

#### TC-056-005: 全設定を一括保存できる 🔵
- **対応要件**: FR-056-001〜004
- **前提条件**: AppSettingsRepositoryが初期化されている
- **テスト手順**:
  1. AppSettingsオブジェクトを作成（全フィールドを非デフォルト値に設定）
  2. saveAll()で一括保存
  3. load()で読み込み
- **期待結果**: 保存した全設定が正しく読み込まれる

#### TC-056-006: アプリ再起動後も設定が保持される（永続化テスト）🔵
- **対応要件**: NFR-056-001, NFR-101
- **前提条件**: AppSettingsRepositoryが初期化されている
- **テスト手順**:
  1. 各設定を保存
  2. 新しいSharedPreferencesインスタンスを作成
  3. 新しいRepositoryで設定を読み込み
- **期待結果**: 元の設定が保持されている

### 2. デフォルト値テスト（Default Value Cases）

#### TC-056-007: 初回起動時はデフォルト値が返される 🔵
- **対応要件**: FR-056-005, REQ-804
- **前提条件**: 空のSharedPreferences
- **テスト手順**:
  1. load()を呼び出す
- **期待結果**:
  - fontSize: FontSize.medium（高齢者向けデフォルト）
  - theme: AppTheme.light
  - ttsSpeed: TtsSpeed.normal
  - politenessLevel: PolitenessLevel.normal

#### TC-056-008: フォントサイズのデフォルト値はmedium 🔵
- **対応要件**: REQ-804
- **前提条件**: fontSizeキーが存在しない
- **テスト手順**:
  1. load()でfontSizeを取得
- **期待結果**: FontSize.medium

#### TC-056-009: テーマのデフォルト値はlight 🔵
- **対応要件**: REQ-803
- **前提条件**: themeキーが存在しない
- **テスト手順**:
  1. load()でthemeを取得
- **期待結果**: AppTheme.light

### 3. 境界値テスト（Boundary Cases）

#### TC-056-010: FontSizeの全値を保存・読み込みできる 🔵
- **対応要件**: REQ-801
- **前提条件**: AppSettingsRepositoryが初期化されている
- **テスト手順**:
  1. FontSize.small, medium, largeを順に保存・読み込み
- **期待結果**: 各値が正しく保存・読み込みされる

#### TC-056-011: AppThemeの全値を保存・読み込みできる 🔵
- **対応要件**: REQ-803
- **前提条件**: AppSettingsRepositoryが初期化されている
- **テスト手順**:
  1. AppTheme.light, dark, highContrastを順に保存・読み込み
- **期待結果**: 各値が正しく保存・読み込みされる

#### TC-056-012: TtsSpeedの全値を保存・読み込みできる 🔵
- **対応要件**: REQ-404
- **前提条件**: AppSettingsRepositoryが初期化されている
- **テスト手順**:
  1. TtsSpeed.slow, normal, fastを順に保存・読み込み
- **期待結果**: 各値が正しく保存・読み込みされる

#### TC-056-013: PolitenessLevelの全値を保存・読み込みできる 🔵
- **対応要件**: REQ-903
- **前提条件**: AppSettingsRepositoryが初期化されている
- **テスト手順**:
  1. PolitenessLevel.casual, normal, politeを順に保存・読み込み
- **期待結果**: 各値が正しく保存・読み込みされる

### 4. エラーハンドリング・異常系テスト（Error Cases）

#### TC-056-014: 不正なフォントサイズ値が保存されていた場合デフォルト値を返す 🟡
- **対応要件**: NFR-056-003
- **前提条件**: shared_preferencesに不正な値が保存されている
- **テスト手順**:
  1. "invalid_size"をfontSizeキーに直接保存
  2. load()を呼び出す
- **期待結果**: FontSize.medium（デフォルト値）が返される

#### TC-056-015: 不正なテーマ値が保存されていた場合デフォルト値を返す 🟡
- **対応要件**: NFR-056-003
- **前提条件**: shared_preferencesに不正な値が保存されている
- **テスト手順**:
  1. "invalid_theme"をthemeキーに直接保存
  2. load()を呼び出す
- **期待結果**: AppTheme.light（デフォルト値）が返される

#### TC-056-016: 不正なTTS速度値が保存されていた場合デフォルト値を返す 🟡
- **対応要件**: NFR-056-003
- **前提条件**: shared_preferencesに不正な値が保存されている
- **テスト手順**:
  1. "invalid_speed"をttsSpeedキーに直接保存
  2. load()を呼び出す
- **期待結果**: TtsSpeed.normal（デフォルト値）が返される

#### TC-056-017: 不正な丁寧さレベル値が保存されていた場合デフォルト値を返す 🟡
- **対応要件**: NFR-056-003
- **前提条件**: shared_preferencesに不正な値が保存されている
- **テスト手順**:
  1. "invalid_level"をpolitenessLevelキーに直接保存
  2. load()を呼び出す
- **期待結果**: PolitenessLevel.normal（デフォルト値）が返される

### 5. 上書きテスト（Overwrite Cases）

#### TC-056-018: 設定を上書き保存できる 🔵
- **対応要件**: FR-056-006
- **前提条件**: 既に設定が保存されている
- **テスト手順**:
  1. FontSize.smallを保存
  2. FontSize.largeで上書き保存
  3. load()で読み込み
- **期待結果**: FontSize.large（新しい値）が返される

#### TC-056-019: 個別設定の変更が他の設定に影響しない 🔵
- **対応要件**: FR-056-001〜004
- **前提条件**: 全設定が保存されている
- **テスト手順**:
  1. 全設定を非デフォルト値で保存
  2. fontSizeのみを変更
  3. load()で全設定を読み込み
- **期待結果**: fontSizeのみ変更され、他の設定は元のまま

## テストケースサマリー

| カテゴリ | テスト数 | 信頼性 |
|---------|---------|--------|
| 正常系 | 6件 | 🔵 |
| デフォルト値 | 3件 | 🔵 |
| 境界値 | 4件 | 🔵 |
| 異常系 | 4件 | 🟡 |
| 上書き | 2件 | 🔵 |
| **合計** | **19件** | |

## テスト実装ファイル

```
test/
├── shared/
│   └── models/
│       └── app_settings_test.dart       # モデルの単体テスト
└── features/
    └── settings/
        └── data/
            └── app_settings_repository_test.dart  # Repositoryテスト
```
