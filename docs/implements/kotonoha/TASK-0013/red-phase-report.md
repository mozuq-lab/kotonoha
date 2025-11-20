# TDD Redフェーズレポート - TASK-0013

## タスク情報

- **タスクID**: TASK-0013
- **タスク名**: Riverpod状態管理セットアップ・プロバイダー基盤実装
- **フェーズ**: Red（失敗するテスト作成）
- **実施日**: 2025-11-20

## 作成したテストファイル

### テストファイルパス

```
frontend/kotonoha_app/test/features/settings/providers/settings_provider_test.dart
```

### テスト実行コマンド

```bash
cd frontend/kotonoha_app
flutter test test/features/settings/providers/settings_provider_test.dart
```

## 実装したテストケース一覧

### 正常系テストケース（9件）

| ID | テスト名 | 信頼性 | 優先度 |
|----|---------|--------|--------|
| TC-001 | 初期状態がデフォルト値（medium、light）であることを確認 | 🔵 | 高 |
| TC-002 | setFontSize(small)でフォントサイズが「小」に変更 | 🔵 | 高 |
| TC-004 | setFontSize(large)でフォントサイズが「大」に変更 | 🔵 | 高 |
| TC-005 | setTheme(light)でテーマが「ライトモード」に変更 | 🔵 | 高 |
| TC-006 | setTheme(dark)でテーマが「ダークモード」に変更 | 🔵 | 高 |
| TC-007 | setTheme(highContrast)でテーマが「高コントラストモード」に変更 | 🔵 | 高 |
| TC-008 | アプリ再起動後、フォントサイズ設定が復元される | 🔵 | 高 |
| TC-009 | アプリ再起動後、テーマモード設定が復元される | 🔵 | 高 |

### 異常系テストケース（3件）

| ID | テスト名 | 信頼性 | 優先度 |
|----|---------|--------|--------|
| TC-011 | SharedPreferences初期化失敗時のエラーハンドリング | 🟡 | 高 |
| TC-012 | SharedPreferences書き込み失敗時の楽観的更新 | 🟡 | 中 |
| TC-014 | SharedPreferencesがnullを返す場合のデフォルト値使用 | 🔵 | 高 |

### 境界値テストケース（2件）

| ID | テスト名 | 信頼性 | 優先度 |
|----|---------|--------|--------|
| TC-015 | FontSize enumの全値（small, medium, large）テスト | 🔵 | 高 |
| TC-016 | AppTheme enumの全値（light, dark, highContrast）テスト | 🔵 | 高 |

### 合計: 13件

- **正常系**: 8件
- **異常系**: 3件
- **境界値**: 2件
- **優先度 高**: 11件
- **優先度 中**: 1件
- **信頼性 🔵（青信号）**: 11件
- **信頼性 🟡（黄信号）**: 2件

## 期待される失敗メッセージ

### 初回実行時（実装前）

テスト実行時に以下のようなエラーが発生することを期待します：

```
Compiler message:
lib/features/settings/providers/settings_provider.dart:1:8: Error: Not found: 'package:kotonoha_app/features/settings/providers/settings_provider.dart'
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
       ^

lib/features/settings/models/app_settings.dart:1:8: Error: Not found: 'package:kotonoha_app/features/settings/models/app_settings.dart'
import 'package:kotonoha_app/features/settings/models/app_settings.dart';
       ^

lib/features/settings/models/font_size.dart:1:8: Error: Not found: 'package:kotonoha_app/features/settings/models/font_size.dart'
import 'package:kotonoha_app/features/settings/models/font_size.dart';
       ^

lib/features/settings/models/app_theme.dart:1:8: Error: Not found: 'package:kotonoha_app/features/settings/models/app_theme.dart'
import 'package:kotonoha_app/features/settings/models/app_theme.dart';
       ^
```

これは、以下のファイルが未実装であることを示しています：
- `lib/features/settings/providers/settings_provider.dart`
- `lib/features/settings/models/app_settings.dart`
- `lib/features/settings/models/font_size.dart`
- `lib/features/settings/models/app_theme.dart`

## テストコードの特徴

### 1. 日本語コメントの充実

すべてのテストケースに以下のコメントを付与：

- **【テスト目的】**: このテストで何を確認するか
- **【テスト内容】**: 具体的にどのような処理をテストするか
- **【期待される動作】**: 正常に動作した場合の結果
- **【テストデータ準備】**: なぜこのデータを用意するかの理由
- **【初期条件設定】**: テスト実行前の状態
- **【実際の処理実行】**: どの機能/メソッドを呼び出すか
- **【処理内容】**: 実行される処理の内容
- **【結果検証】**: 何を検証するか
- **【期待値確認】**: 期待される結果とその理由
- **【確認内容】**: 各expectステートメントの確認項目

### 2. Given-When-Then パターンの採用

すべてのテストケースで以下の構造を採用：

- **Given（準備フェーズ）**: テストデータ準備、初期条件設定
- **When（実行フェーズ）**: 実際の処理実行
- **Then（検証フェーズ）**: 結果検証、期待値確認

### 3. 信頼性レベルの明示

各テストケースに信頼性レベルを明記：

- 🔵 **青信号**: 要件定義書・テストケース定義書に基づく確実なテスト（11件）
- 🟡 **黄信号**: 要件定義書から妥当な推測によるテスト（2件）

### 4. SharedPreferencesのモック化

`SharedPreferences.setMockInitialValues({})`を使用して、各テストが独立して実行できるように設定。

### 5. ProviderContainerのライフサイクル管理

各テストケースで以下を実施：

- **setUp**: SharedPreferencesのモック初期化
- **tearDown**: ProviderContainerの破棄（メモリリーク防止）

## 次のステップ（Greenフェーズ）で実装すべき項目

### 1. モデルクラスの実装

- `lib/features/settings/models/font_size.dart`
  - `FontSize` enum（small, medium, large）
  - `displayName` プロパティ

- `lib/features/settings/models/app_theme.dart`
  - `AppTheme` enum（light, dark, highContrast）
  - `displayName` プロパティ

- `lib/features/settings/models/app_settings.dart`
  - `AppSettings` クラス
  - `fontSize`, `theme` プロパティ
  - `copyWith()` メソッド
  - `toJson()`, `fromJson()` メソッド

### 2. Providerの実装

- `lib/features/settings/providers/settings_provider.dart`
  - `SettingsNotifier` クラス（AsyncNotifier<AppSettings>を継承）
  - `build()` メソッド: SharedPreferencesから設定を読み込み
  - `setFontSize(FontSize)` メソッド: フォントサイズ変更・永続化
  - `setTheme(AppTheme)` メソッド: テーマ変更・永続化
  - `settingsNotifierProvider` の定義

### 3. コード生成

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Riverpod Generatorによる`.g.dart`ファイル生成が必要。

### 4. 最小実装の方針

- **SharedPreferences連携**: `SharedPreferences.getInstance()`を使用
- **デフォルト値**: `FontSize.medium`, `AppTheme.light`
- **永続化キー**: `'fontSize'`, `'theme'`
- **enum保存形式**: `.index`（整数値）で保存
- **エラーハンドリング**: try-catchでエラーをキャッチし、デフォルト値を返す

## テスト品質評価

### ✅ 高品質の条件

- [x] **テスト実行**: 実装されたテストコードはコンパイル可能（import先が未実装のみ）
- [x] **期待値**: すべてのテストケースで明確で具体的な期待値を定義
- [x] **アサーション**: 適切なexpectステートメントを使用
- [x] **実装方針**: Greenフェーズで実装すべき内容が明確
- [x] **日本語コメント**: すべてのテストに詳細な日本語コメントを付与
- [x] **信頼性レベル**: 各テストケースに信頼性レベルを明記
- [x] **Given-When-Then**: すべてのテストで構造化されたパターンを採用

### 品質判定: ✅ 高品質

すべての品質基準を満たしています。

## 注意事項

### モック化の制約

以下のエラーケースは、flutter_testのモック機能では直接シミュレートできないため、実装後に実際の挙動を確認する必要があります：

- **TC-011**: SharedPreferences初期化失敗
  - `SharedPreferences.getInstance()`の失敗をモック化できない
  - 実装後、実際のエラーハンドリング動作を手動テストで確認

- **TC-012**: SharedPreferences書き込み失敗
  - `setInt()`の失敗をモック化できない
  - 実装後、実際の楽観的更新動作を手動テストで確認

これらのテストケースは、実装フェーズで適切なエラーハンドリングを実装し、その後、実際の動作を確認する形で検証を行います。

## 更新履歴

- **2025-11-20**: TDD Redフェーズ完了
  - 13件のテストケースを実装（優先度高）
  - 正常系8件、異常系3件、境界値2件
  - すべてのテストに詳細な日本語コメントを付与
  - Given-When-Thenパターンを採用
  - 信頼性レベルを明記
