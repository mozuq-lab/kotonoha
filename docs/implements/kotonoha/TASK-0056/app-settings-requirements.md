# アプリ設定保存（shared_preferences）要件定義書 - TASK-0056

## 概要
- **タスクID**: TASK-0056
- **タスク名**: アプリ設定保存（shared_preferences）
- **フェーズ**: TDD要件定義
- **作成日**: 2025-11-26

## 関連要件

### EARS要件定義書からの抽出 🔵

| 要件ID | 要件内容 | 信頼性 |
|--------|---------|--------|
| REQ-801 | システムはフォントサイズを「小」「中」「大」の3段階から選択できなければならない | 🔵 |
| REQ-802 | システムは文字盤・定型文一覧・ボタンラベルのフォントサイズをフォントサイズ設定に追従させなければならない | 🔵 |
| REQ-803 | システムは「ライトモード」「ダークモード」「高コントラストモード」の3つのテーマを提供しなければならない | 🔵 |
| REQ-804 | システムは標準フォントサイズを高齢者にも見やすいサイズに設定しなければならない | 🟡 |
| NFR-101 | 定型文、履歴、お気に入り、設定はすべて端末内に保存 | 🔵 |

### 設計文書からの抽出 🔵

architecture.md より:
- **ローカルストレージ**: shared_preferences（設定）、Hive（定型文・履歴・お気に入り）
- **フォントサイズ**: 小/中/大の3段階 (REQ-801)
- **テーマ**: ライト/ダーク/高コントラストの3種類 (REQ-803)

### TTS関連要件 🔵

| 要件ID | 要件内容 | 信頼性 |
|--------|---------|--------|
| REQ-404 | システムは読み上げ速度を「遅い」「普通」「速い」の3段階から選択できなければならない | 🔵 |

### AI変換関連要件 🔵

| 要件ID | 要件内容 | 信頼性 |
|--------|---------|--------|
| REQ-903 | システムはAI変換の丁寧さレベルを「カジュアル」「普通」「丁寧」の3段階から選択できなければならない | 🔵 |

## 機能要件

### FR-056-001: フォントサイズ設定の永続化 🔵
- **概要**: フォントサイズ設定（小/中/大）をshared_preferencesに保存する
- **対応要件**: REQ-801, REQ-804
- **データ型**: String（"small", "medium", "large"）
- **デフォルト値**: "medium"（高齢者にも見やすい標準サイズ）

### FR-056-002: テーマ設定の永続化 🔵
- **概要**: テーマ設定（ライト/ダーク/高コントラスト）をshared_preferencesに保存する
- **対応要件**: REQ-803
- **データ型**: String（"light", "dark", "highContrast"）
- **デフォルト値**: "light"

### FR-056-003: TTS速度設定の永続化 🔵
- **概要**: TTS読み上げ速度（遅い/普通/速い）をshared_preferencesに保存する
- **対応要件**: REQ-404
- **データ型**: String（"slow", "normal", "fast"）
- **デフォルト値**: "normal"

### FR-056-004: AI丁寧さレベル設定の永続化 🔵
- **概要**: AI変換の丁寧さレベル（カジュアル/普通/丁寧）をshared_preferencesに保存する
- **対応要件**: REQ-903
- **データ型**: String（"casual", "normal", "polite"）
- **デフォルト値**: "normal"

### FR-056-005: 設定の読み込み 🔵
- **概要**: アプリ起動時にshared_preferencesから設定を読み込む
- **対応要件**: NFR-101（端末内保存）
- **動作**: 保存された設定がない場合はデフォルト値を使用

### FR-056-006: 設定変更の即時反映 🟡
- **概要**: 設定変更時に即座にUIに反映される
- **対応要件**: タスク完了条件「設定変更が即座に反映される」
- **実装方針**: Repositoryパターンで保存、Providerで状態管理（TASK-0057で統合）

## 非機能要件

### NFR-056-001: データ永続性 🔵
- アプリ再起動後も設定が保持される
- アプリクラッシュ後も設定が保持される

### NFR-056-002: パフォーマンス 🟡
- 設定の読み込みは100ms以内
- 設定の保存は非同期で実行（UIブロックなし）

### NFR-056-003: エラーハンドリング 🟡
- shared_preferencesへのアクセスエラー時はデフォルト値を使用
- 不正な値が保存されていた場合はデフォルト値にフォールバック

## データモデル設計

### AppSettings モデル 🔵

```dart
/// アプリ設定モデル
class AppSettings {
  /// フォントサイズ: small, medium, large
  final FontSize fontSize;

  /// テーマ: light, dark, highContrast
  final AppTheme theme;

  /// TTS速度: slow, normal, fast
  final TtsSpeed ttsSpeed;

  /// AI丁寧さレベル: casual, normal, polite
  final PolitenessLevel politenessLevel;
}

/// フォントサイズ列挙型
enum FontSize { small, medium, large }

/// テーマ列挙型
enum AppTheme { light, dark, highContrast }

/// TTS速度列挙型
enum TtsSpeed { slow, normal, fast }

/// 丁寧さレベル列挙型
enum PolitenessLevel { casual, normal, polite }
```

### shared_preferencesキー設計 🔵

| キー名 | 値の型 | 説明 |
|--------|--------|------|
| `fontSize` | String | フォントサイズ（small/medium/large） |
| `theme` | String | テーマ（light/dark/highContrast） |
| `ttsSpeed` | String | TTS速度（slow/normal/fast） |
| `politenessLevel` | String | 丁寧さレベル（casual/normal/polite） |

## Repository設計 🔵

### AppSettingsRepository

```dart
class AppSettingsRepository {
  final SharedPreferences _prefs;

  AppSettingsRepository({required SharedPreferences prefs});

  /// 設定を読み込む（デフォルト値付き）
  Future<AppSettings> load();

  /// フォントサイズを保存
  Future<void> saveFontSize(FontSize fontSize);

  /// テーマを保存
  Future<void> saveTheme(AppTheme theme);

  /// TTS速度を保存
  Future<void> saveTtsSpeed(TtsSpeed ttsSpeed);

  /// 丁寧さレベルを保存
  Future<void> savePolitenessLevel(PolitenessLevel level);

  /// 全設定を一括保存
  Future<void> saveAll(AppSettings settings);
}
```

## 完了条件

| 条件 | 検証方法 |
|------|---------|
| 設定がshared_preferencesに保存される | ユニットテストで各設定の保存を確認 |
| アプリ再起動後も設定が保持される | 永続化テストで再読み込みを確認 |
| 設定変更が即座に反映される | Repository経由の保存後、loadで値が取得できることを確認 |
| フォントサイズ設定（小/中/大）が保存される | FontSize列挙型の各値で保存・読み込みテスト |
| テーマ設定（ライト/ダーク/高コントラスト）が保存される | AppTheme列挙型の各値で保存・読み込みテスト |
| TTS速度設定（遅い/普通/速い）が保存される | TtsSpeed列挙型の各値で保存・読み込みテスト |
| AI丁寧さレベル設定（カジュアル/普通/丁寧）が保存される | PolitenessLevel列挙型の各値で保存・読み込みテスト |

## 依存関係

### 前提タスク
- **TASK-0054**: Hive データベース初期化実装 ✅（shared_preferencesの初期化パターンを参考）

### 後続タスク
- **TASK-0057**: Riverpod Provider 構造設計（SettingsProviderで本Repositoryを使用）

## 実装ファイル構成

```
lib/
├── shared/
│   └── models/
│       └── app_settings.dart          # AppSettings モデル + 列挙型
└── features/
    └── settings/
        └── data/
            └── app_settings_repository.dart  # Repository実装
```
