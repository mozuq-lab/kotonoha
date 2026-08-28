# TASK-0073: テーマ切り替えUI・適用 要件整理書

## タスク概要

- **タスクID**: TASK-0073
- **タスク名**: テーマ切り替えUI・適用
- **推定工数**: 8時間
- **タスクタイプ**: TDD
- **依存タスク**: TASK-0071（設定画面UI実装）, TASK-0016（テーマ実装）

## 関連要件

### 主要要件
| 要件ID | 要件内容 | 信頼性 |
|--------|----------|--------|
| REQ-803 | システムは「ライトモード」「ダークモード」「高コントラストモード」の3つのテーマを提供しなければならない | 🔵 |
| REQ-2008 | ユーザーがテーマを変更した場合、システムは即座にすべての画面の配色を変更しなければならない | 🟡 |
| REQ-5006 | システムは高コントラストモードでWCAG 2.1 AAレベルのコントラスト比（4.5:1以上）を確保しなければならない | 🟡 |
| REQ-5003 | システムはアプリが強制終了しても設定を失わない永続化機構を実装しなければならない | 🔵 |

### 関連要件（既に実装済み・TASK-0016, TASK-0071）
- テーマ選択UI（SegmentedButton）
- ThemeData定義（lightTheme, darkTheme, highContrastTheme）
- currentThemeProvider（設定に応じたテーマ提供）
- settingsNotifierProvider.setTheme()メソッド

## 実装詳細

### 1. テーマ選択UI（TASK-0071で実装済み）
- ThemeSettingsWidget: ライト/ダーク/高コントラストの3つのセグメントボタン
- 設定画面（SettingsScreen）に統合済み

### 2. テーマ変更時の即時反映（REQ-2008）
- settingsNotifierProvider.setTheme()で楽観的更新
- currentThemeProviderがsettingsNotifierProviderをwatch
- KotonohaApp（MaterialApp.router）がcurrentThemeProviderをwatch
- テーマ変更→Provider状態更新→UI再構築の流れ

### 3. 高コントラストモードのWCAG準拠（REQ-5006）
- コントラスト比4.5:1以上の確保
- 背景: #FFFFFF、テキスト: #000000（最大コントラスト21:1）
- 太い境界線（2px以上）
- フォントウェイト: w600以上

### 4. 設定の永続化（REQ-5003）
- SharedPreferencesに'theme'キーでindex値を保存
- アプリ再起動後に復元

## TASK-0073の検証スコープ

TASK-0073では主にTASK-0016、TASK-0071で実装された機能の「アプリ全体への適用検証」を行う:

1. **テーマ変更がアプリ全体に即座に反映されること**
2. **各テーマでHomeScreenが正しく表示されること**
3. **高コントラストモードのコントラスト比検証**
4. **テーマ設定の永続化検証**
5. **設定画面UIの動作確認**

## 完了条件

- [ ] テーマを3種類から選択できる
- [ ] 変更が即座に全画面に反映される
- [ ] 高コントラストモードでコントラスト比4.5:1以上
- [ ] 設定がアプリ再起動後も保持される
- [ ] すべてのテストケースがパス

## 技術スタック

- **言語**: Dart
- **フレームワーク**: Flutter 3.38.1 + Riverpod 2.x
- **テストフレームワーク**: flutter_test
- **永続化**: SharedPreferences

## 参考ファイル

- `lib/features/settings/presentation/widgets/theme_settings_widget.dart`
- `lib/features/settings/providers/settings_provider.dart`
- `lib/core/themes/theme_provider.dart`
- `lib/core/themes/high_contrast_theme.dart`
- `lib/app.dart`
