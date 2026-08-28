# TDD Green Phase メモ - TASK-0056

## 概要
- **タスク**: アプリ設定保存（shared_preferences）
- **フェーズ**: Green（テストを通す実装）
- **実行日時**: 2025-11-26

## 実装したファイル
- `lib/shared/models/app_settings.dart`
- `lib/features/settings/data/app_settings_repository.dart`

## 実装したクラス・列挙型

### 列挙型

```dart
enum FontSize { small, medium, large }
enum AppTheme { light, dark, highContrast }
enum TtsSpeed { slow, normal, fast }
enum PolitenessLevel { casual, normal, polite }
```

### AppSettings クラス

```dart
class AppSettings {
  final FontSize fontSize;
  final AppTheme theme;
  final TtsSpeed ttsSpeed;
  final PolitenessLevel politenessLevel;

  const AppSettings({...});
  factory AppSettings.defaults();
  AppSettings copyWith({...});
}
```

### AppSettingsRepository クラス

```dart
class AppSettingsRepository {
  final SharedPreferences _prefs;

  AppSettingsRepository({required SharedPreferences prefs});

  Future<AppSettings> load();
  Future<void> saveFontSize(FontSize fontSize);
  Future<void> saveTheme(AppTheme theme);
  Future<void> saveTtsSpeed(TtsSpeed ttsSpeed);
  Future<void> savePolitenessLevel(PolitenessLevel level);
  Future<void> saveAll(AppSettings settings);
}
```

### 各メソッドの実装詳細

| メソッド | 実装内容 | 対応要件 |
|---------|---------|---------|
| `load()` | shared_preferencesから全設定を読み込み | REQ-801, REQ-803, REQ-404, REQ-903 |
| `saveFontSize(fontSize)` | `_prefs.setString('fontSize', fontSize.name)` | REQ-801 |
| `saveTheme(theme)` | `_prefs.setString('theme', theme.name)` | REQ-803 |
| `saveTtsSpeed(speed)` | `_prefs.setString('ttsSpeed', speed.name)` | REQ-404 |
| `savePolitenessLevel(level)` | `_prefs.setString('politenessLevel', level.name)` | REQ-903 |
| `saveAll(settings)` | 全設定を一括保存 | FR-056-001〜004 |

## テスト結果

```
00:01 +19: All tests passed!
```

### 成功したテストケース（19件）

#### 正常系テスト（6件）
- TC-056-001: フォントサイズを保存できる ✅
- TC-056-002: テーマを保存できる ✅
- TC-056-003: TTS速度を保存できる ✅
- TC-056-004: AI丁寧さレベルを保存できる ✅
- TC-056-005: 全設定を一括保存できる ✅
- TC-056-006: アプリ再起動後も設定が保持される ✅

#### デフォルト値テスト（3件）
- TC-056-007: 初回起動時はデフォルト値が返される ✅
- TC-056-008: フォントサイズのデフォルト値はmedium ✅
- TC-056-009: テーマのデフォルト値はlight ✅

#### 境界値テスト（4件）
- TC-056-010: FontSizeの全値を保存・読み込みできる ✅
- TC-056-011: AppThemeの全値を保存・読み込みできる ✅
- TC-056-012: TtsSpeedの全値を保存・読み込みできる ✅
- TC-056-013: PolitenessLevelの全値を保存・読み込みできる ✅

#### 異常系テスト（4件）
- TC-056-014: 不正なフォントサイズ値でデフォルト値を返す ✅
- TC-056-015: 不正なテーマ値でデフォルト値を返す ✅
- TC-056-016: 不正なTTS速度値でデフォルト値を返す ✅
- TC-056-017: 不正な丁寧さレベル値でデフォルト値を返す ✅

#### 上書きテスト（2件）
- TC-056-018: 設定を上書き保存できる ✅
- TC-056-019: 個別設定の変更が他の設定に影響しない ✅

## 設計判断

1. **依存性注入（DI）パターン採用**
   - SharedPreferencesをコンストラクタで注入
   - テスト時にモックの注入が容易

2. **列挙型のname属性を使用**
   - `fontSize.name` で文字列に変換（"small", "medium", "large"）
   - 可読性が高く、将来の値追加にも対応しやすい

3. **エラーハンドリング**
   - 不正な値が保存されていた場合はデフォルト値にフォールバック
   - `firstWhere` の `orElse` で安全にデフォルト値を返す

4. **イミュータブル設計**
   - AppSettingsクラスは全フィールドがfinal
   - copyWithパターンで安全な更新を提供

## 次のステップ
リファクタリングフェーズでコード品質を向上させる。
