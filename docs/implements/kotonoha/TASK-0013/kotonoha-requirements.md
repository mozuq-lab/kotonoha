# TDD要件定義・機能仕様 - TASK-0013: Riverpod状態管理セットアップ・プロバイダー基盤実装

## タスク情報

- **タスクID**: TASK-0013
- **タスク名**: Riverpod状態管理セットアップ・プロバイダー基盤実装
- **タスクタイプ**: TDD
- **推定工数**: 8時間
- **フェーズ**: Phase 1 - Week 3, Day 13
- **依存タスク**: TASK-0012 (Flutter依存パッケージ追加・pubspec.yaml設定)

## 関連文書

- **EARS要件定義書**: [docs/spec/kotonoha-requirements.md](../../spec/kotonoha-requirements.md)
- **アーキテクチャ設計**: [docs/design/kotonoha/architecture.md](../../design/kotonoha/architecture.md)
- **データフロー図**: [docs/design/kotonoha/dataflow.md](../../design/kotonoha/dataflow.md)
- **TypeScript型定義**: [docs/design/kotonoha/interfaces.dart](../../design/kotonoha/interfaces.dart)
- **Phase 1タスク**: [docs/tasks/kotonoha-phase1.md](../../tasks/kotonoha-phase1.md)

---

## 1. 機能の概要（EARS要件定義書・設計文書ベース）

### 🔵 機能概要
この機能は、Flutterアプリケーションの状態管理基盤としてRiverpodをセットアップし、アプリケーション全体で使用する基本的なプロバイダー（設定プロバイダー）を実装します。

### 何をする機能か
- Riverpodの`ProviderScope`をアプリケーションルートに設定
- MaterialApp.routerとRiverpodを統合
- フォントサイズ設定プロバイダーを実装（小/中/大の3段階）
- テーマモード設定プロバイダーを実装（ライト/ダーク/高コントラスト）
- SharedPreferencesを使用した設定の永続化
- Riverpod Generatorによるコード生成の基盤構築

### どのような問題を解決するか
**🔵 アクセシビリティ対応の必要性**:
- REQ-801, REQ-803により、ユーザーはフォントサイズとテーマを変更できる必要がある
- これらの設定はアプリ全体で一貫して適用される必要がある
- 設定はアプリ再起動後も保持される必要がある（REQ-5003: データ永続化）

**🔵 状態管理の一元化**:
- architecture.mdで定義されたRiverpod 2.x状態管理パターンの実装
- テスタビリティの高い、型安全な状態管理基盤の構築
- 非同期処理との親和性が高い状態管理の実現

### 想定されるユーザー
- 発話が困難で視力に配慮が必要なユーザー（高齢者、視覚障害者など）
- 明るい環境・暗い環境でアプリを使用するユーザー
- 支援者（介護スタッフ、家族）がユーザーに代わって設定を調整

### システム内での位置づけ
**🔵 アーキテクチャ上の位置**:
- **アプリケーション基盤層**: 全機能の状態管理を支えるコア機能
- **dataflow.md「状態管理フロー（Riverpod）」セクション参照**:
  - SettingsProviderが全UIコンポーネントにフォントサイズ・テーマ情報を提供
  - SharedPreferencesを通じてローカルストレージに永続化
- **Phase 1の基盤構築タスク**: 後続のすべての機能実装がこの基盤に依存

### 参照したEARS要件
- **REQ-801**: システムはフォントサイズを「小」「中」「大」の3段階から選択できなければならない 🔵
- **REQ-803**: システムは「ライトモード」「ダークモード」「高コントラストモード」の3つのテーマを提供しなければならない 🔵
- **REQ-5003**: システムはアプリが強制終了しても定型文・設定・履歴を失わない永続化機構を実装しなければならない 🔵

### 参照した設計文書
- **architecture.md**: 「フロントエンド（Flutter）」セクション - Riverpod 2.x状態管理
- **dataflow.md**: 「状態管理フロー（Riverpod）」セクション - SettingsProviderの設計
- **interfaces.dart**: `AppSettings`, `FontSize`, `AppTheme` エンティティ定義（214-296行目）

---

## 2. 入力・出力の仕様（EARS機能要件・TypeScript型定義ベース）

### 🔵 入力パラメータ

#### SettingsNotifier.setFontSize(FontSize)
- **型**: `FontSize` enum（`small`, `medium`, `large`）
- **制約**:
  - REQ-801で定義された3段階のみ
  - `null`は許可しない
- **interfaces.dartから抽出**（276-285行目）:
  ```dart
  enum FontSize {
    small('小'),
    medium('中'),
    large('大');
    final String displayName;
  }
  ```

#### SettingsNotifier.setThemeMode(AppTheme)
- **型**: `AppTheme` enum（`light`, `dark`, `highContrast`）
- **制約**:
  - REQ-803で定義された3種類のみ
  - `null`は許可しない
- **interfaces.dartから抽出**（287-296行目）:
  ```dart
  enum AppTheme {
    light('ライトモード'),
    dark('ダークモード'),
    highContrast('高コントラストモード');
    final String displayName;
  }
  ```

### 🔵 出力値

#### SettingsNotifier state
- **型**: `AsyncValue<AppSettings>`
- **初期値**:
  - `fontSize`: `FontSize.medium`（デフォルト中サイズ）
  - `themeMode`: `AppTheme.light`（デフォルトライトモード）
- **interfaces.dartから抽出**（214-274行目）:
  ```dart
  class AppSettings {
    final FontSize fontSize;
    final AppTheme theme;
    final TTSSpeed ttsSpeed;
    final PolitenessLevel aiPoliteness;
    final bool aiConversionEnabled;

    const AppSettings({
      this.fontSize = FontSize.medium,
      this.theme = AppTheme.light,
      // ...
    });
  }
  ```

### 🔵 入出力の関係性
1. **設定変更フロー**:
   - ユーザーが設定画面でフォントサイズ/テーマを選択
   - `setFontSize()` / `setThemeMode()` メソッド呼び出し
   - SharedPreferencesに永続化（非同期）
   - Riverpod stateを更新
   - すべてのウィジェットに変更を通知
   - UIが自動的に再描画

2. **アプリ起動時の復元フロー**:
   - `build()` メソッドでSharedPreferencesから設定を読み込み
   - 保存された値がない場合はデフォルト値を使用
   - AsyncValue.dataとして状態を返す

### 🔵 データフロー
**dataflow.md「状態管理フロー（Riverpod）」セクションから抽出**（362-405行目）:

```
[UI Components (Settings画面)]
  ↓ ユーザー操作
[SettingsProvider (StateNotifier)]
  ↓ 永続化
[SharedPrefs (ローカルストレージ)]
  ↓ 読み込み
[SettingsProvider]
  ↓ 状態通知
[UI Components (全画面)]
```

### 参照したEARS要件
- **REQ-801**: フォントサイズ3段階選択
- **REQ-803**: テーマ3種類提供
- **REQ-5003**: 設定の永続化

### 参照した設計文書
- **interfaces.dart**: 214-296行目（AppSettings, FontSize, AppTheme定義）
- **dataflow.md**: 362-405行目（状態管理フロー図）

---

## 3. 制約条件（EARS非機能要件・アーキテクチャ設計ベース）

### 🔵 パフォーマンス要件

#### 設定変更の応答速度
- **REQ-2007**: ユーザーがフォントサイズを変更した場合、システムは即座にすべてのテキスト要素のサイズを変更しなければならない 🟡
- **REQ-2008**: ユーザーがテーマを変更した場合、システムは即座にすべての画面の配色を変更しなければならない 🟡
- **目標**: 設定変更から画面反映まで100ms以内（NFR-003: 文字盤タップ応答時間を参考）

#### 永続化処理
- **非同期処理**: SharedPreferencesへの書き込みは非同期で実行
- **ブロッキング禁止**: UI操作をブロックしない
- **エラーハンドリング**: 書き込み失敗時もアプリは継続動作

### 🔵 セキュリティ要件
- **NFR-105**: 環境変数をアプリ内にハードコードしない
  - SharedPreferencesのキー名は定数化
  - センシティブな情報は含めない（フォントサイズ・テーマのみ）

### 🔵 互換性要件
- **NFR-401**: iOS 14.0以上、Android 10以上で動作
  - SharedPreferencesは両プラットフォームで動作保証済み
  - Riverpod 2.xのサポート範囲内

### 🟡 アーキテクチャ制約
**architecture.md「フロントエンド（Flutter）」セクションから抽出**（26-41行目）:
- **状態管理**: Riverpod 2.x必須
  - コンパイル時の安全性を確保
  - テスタビリティを高める
  - 非同期処理との親和性を活用
- **ローカルストレージ**: shared_preferences使用（設定用）、Hive使用（データ用）

### 🔵 データベース制約
- **SharedPreferencesの制約**:
  - key-value形式のみ
  - int, String, bool型のみサポート
  - enum値はindexまたはnameで保存

### 参照したEARS要件
- **REQ-2007**: フォントサイズ即座反映 🟡
- **REQ-2008**: テーマ即座反映 🟡
- **NFR-003**: 文字盤タップ応答100ms以内 🟡
- **NFR-105**: 環境変数の安全管理 🔵
- **NFR-401**: iOS/Android互換性 🟡

### 参照した設計文書
- **architecture.md**: 26-41行目（状態管理・ローカルストレージ設計）

---

## 4. 想定される使用例（EARSEdgeケース・データフローベース）

### 🔵 基本的な使用パターン

#### パターン1: アプリ初回起動
**REQ-801, REQ-803の通常動作**:
```dart
// 1. main.dartでProviderScopeを初期化
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const ProviderScope(child: KotonohaApp()));
}

// 2. SettingsNotifierがbuild()で初期値を設定
// SharedPreferencesに保存データがない場合
// → fontSize: FontSize.medium, themeMode: AppTheme.light

// 3. UIが初期設定でレンダリング
```

#### パターン2: 設定画面でフォントサイズ変更
**REQ-801, REQ-2007の動作**:
```dart
// ユーザーが「大」を選択
await ref.read(settingsNotifierProvider.notifier).setFontSize(FontSize.large);

// 1. SharedPreferencesに保存（非同期）
// 2. state更新 → AsyncValue.data(AppSettings(fontSize: large))
// 3. 全UIウィジェットが再ビルド
// 4. フォントサイズが即座に変更（100ms以内目標）
```

#### パターン3: アプリ再起動後の設定復元
**REQ-5003の永続化動作**:
```dart
// アプリ再起動時
// 1. SettingsNotifier.build()が実行
// 2. SharedPreferencesから前回の設定を読み込み
//    await _prefs.getInt('fontSize') → 2 (large)
//    await _prefs.getInt('themeMode') → 1 (dark)
// 3. 前回の設定が復元される
```

### 🟡 データフロー
**dataflow.md「TTS読み上げ処理」セクションから類推**（224-254行目）:
```
[ユーザー] 設定画面でフォントサイズ「大」選択
  ↓
[UI] setFontSize(FontSize.large)呼び出し
  ↓
[SettingsNotifier]
  ├→ [SharedPreferences] 永続化: 'fontSize' = 2
  └→ [state更新] AsyncValue.data(AppSettings(fontSize: large))
  ↓
[Riverpod] 依存ウィジェットに変更通知
  ↓
[全UIウィジェット] 再ビルド（フォントサイズ反映）
```

### 🟡 エッジケース

#### EDGE-1: SharedPreferences書き込み失敗
**NFR-304: データベースエラー時のエラーハンドリングから類推**:
```dart
// 書き込み失敗時もUI状態は更新される（楽観的更新）
// ただし、次回起動時は古い設定が読み込まれる
// → ユーザーには警告表示、再試行オプション提供
```

#### EDGE-2: 不正なenum値が保存されている
```dart
// SharedPreferencesに範囲外のint値（例: 99）が保存
// → デフォルト値（medium, light）にフォールバック
// → AppLogger.warning()でログ記録
```

#### EDGE-3: 設定変更中にアプリがバックグラウンド移行
**EDGE-201: バックグラウンド復帰時の状態復元から類推**:
```dart
// バックグラウンド移行前に変更した設定はSharedPreferencesに保存済み
// → 復帰時にそのまま設定が維持される
// → 追加の復元処理は不要
```

### 🟡 エラーケース

#### エラー1: SharedPreferencesの初期化失敗
```dart
// build()メソッドでgetInstance()が失敗
// → AsyncValue.errorを返す
// → UIはエラー表示（「設定の読み込みに失敗しました」）
// → デフォルト設定で継続動作（NFR-301: 基本機能継続）
```

#### エラー2: 型変換エラー
```dart
// getInt('fontSize')がnullでない非int値
// → try-catchでキャッチ、デフォルト値使用
// → AppLogger.error()でログ記録
```

### 参照したEARS要件
- **REQ-801**: フォントサイズ3段階選択 🔵
- **REQ-803**: テーマ3種類 🔵
- **REQ-2007**: フォントサイズ即座反映 🟡
- **REQ-5003**: 設定永続化 🔵
- **NFR-301**: 基本機能継続 🔵
- **NFR-304**: エラーハンドリング 🟡
- **EDGE-201**: バックグラウンド復帰 🟡

### 参照した設計文書
- **dataflow.md**: 224-254行目（TTS読み上げ処理フロー）、362-405行目（状態管理フロー）

---

## 5. EARS要件・設計文書との対応関係

### 🔵 参照したユーザストーリー
- **ストーリー名**: 「アクセシビリティ機能」
- **As a**: 視力に配慮が必要なユーザー
- **I want to**: フォントサイズとテーマを変更したい
- **So that**: 快適にアプリを使用できる

### 🔵 参照した機能要件
- **REQ-801**: システムはフォントサイズを「小」「中」「大」の3段階から選択できなければならない
- **REQ-802**: システムは文字盤・定型文一覧・ボタンラベルのフォントサイズをフォントサイズ設定に追従させなければならない
- **REQ-803**: システムは「ライトモード」「ダークモード」「高コントラストモード」の3つのテーマを提供しなければならない
- **REQ-5003**: システムはアプリが強制終了しても定型文・設定・履歴を失わない永続化機構を実装しなければならない

### 🟡 参照した非機能要件
- **NFR-003**: システムは文字盤タップから入力欄への文字反映までの遅延を100ms以内としなければならない（応答速度の参考値）
- **NFR-105**: システムは環境変数をアプリ内にハードコードせず、安全に管理しなければならない
- **NFR-301**: システムは重大なエラーが発生しても、基本機能（文字盤+読み上げ）を継続して利用可能に保たなければならない
- **NFR-304**: システムはデータベースエラー発生時に適切なエラーハンドリングを行い、データ損失を防がなければならない
- **NFR-401**: システムはiOS 14.0以上、Android 10以上、主要モダンブラウザ（Chrome、Safari、Edge）で動作しなければならない

### 🟡 参照したEdgeケース
- **EDGE-201**: アプリがバックグラウンドから復帰した場合、システムは前回の画面状態・入力内容を復元しなければならない
- **REQ-2007**: ユーザーがフォントサイズを変更した場合、システムは即座にすべてのテキスト要素のサイズを変更しなければならない
- **REQ-2008**: ユーザーがテーマを変更した場合、システムは即座にすべての画面の配色を変更しなければならない

### 🔵 参照した設計文書

#### アーキテクチャ
- **architecture.md**:
  - 26-41行目: フロントエンド（Flutter）- Riverpod 2.x状態管理設計
  - 48-67行目: ローカルストレージ（shared_preferences、Hive）設計

#### データフロー
- **dataflow.md**:
  - 362-405行目: 状態管理フロー（Riverpod） - SettingsProviderの位置づけ
  - 224-254行目: TTS読み上げ処理（参考フロー）

#### 型定義
- **interfaces.dart**:
  - 214-274行目: `AppSettings`クラス定義
  - 276-285行目: `FontSize` enum定義
  - 287-296行目: `AppTheme` enum定義

#### データベース
- 該当なし（SharedPreferencesはスキーマレス）

#### API仕様
- 該当なし（ローカル状態管理のみ）

---

## 6. 実装範囲の定義

### 🔵 実装対象

#### Phase 1（本タスク）で実装する機能
1. **main.dartセットアップ**:
   - ProviderScope設定
   - Hive初期化統合

2. **app.dart実装**:
   - ConsumerWidgetに変更
   - MaterialApp.routerとRiverpod統合
   - テーマプロバイダーの監視

3. **設定プロバイダー実装**:
   - `SettingsNotifier`クラス（Riverpod Generator使用）
   - `FontSize` enum
   - `ThemeMode` enum（AppTheme）
   - `Settings`データクラス

4. **SharedPreferences連携**:
   - 初期化処理
   - 読み込み処理（build()）
   - 書き込み処理（setFontSize, setThemeMode）

5. **コード生成**:
   - `flutter pub run build_runner build --delete-conflicting-outputs`
   - `.g.dart`ファイル生成

6. **テスト実装**:
   - SettingsNotifierの初期状態テスト
   - フォントサイズ変更テスト
   - テーマモード変更テスト
   - SharedPreferences連携テスト
   - エラーハンドリングテスト

### 🟡 実装範囲外（後続タスクで実装）

#### TASK-0014（Hiveローカルストレージ）で実装
- 履歴データのHive保存
- 定型文データのHive保存

#### TASK-0015（go_router設定）で実装
- ルーティングプロバイダー
- 画面遷移ロジック

#### TASK-0016（テーマ実装）で実装
- light_theme.dart、dark_theme.dart、high_contrast_theme.dartの詳細設定
- WCAG 2.1 AA準拠のコントラスト比調整

#### Phase 2以降で実装
- AI変換設定（REQ-903: 丁寧さレベル）
- TTS速度設定（REQ-404: 読み上げ速度）
- 他の設定項目の追加

---

## 7. 品質判定基準

### ✅ 高品質の条件

#### 要件の明確さ
- [x] フォントサイズ・テーマの選択肢が明確（3段階、3種類）
- [x] 永続化の仕組みが具体的（SharedPreferences使用）
- [x] 状態管理のパターンが明確（Riverpod Generator使用）

#### 入出力定義の完全性
- [x] `AppSettings`型が完全に定義されている（interfaces.dart参照）
- [x] `FontSize`, `AppTheme` enumが明確
- [x] 初期値・デフォルト値が明確（medium, light）

#### 制約条件の明確さ
- [x] パフォーマンス要件: 即座反映（100ms以内目標）
- [x] 永続化要件: SharedPreferences使用、アプリ再起動後も保持
- [x] エラーハンドリング: 失敗時もアプリ継続動作

#### 実装可能性
- [x] Riverpod 2.xのベストプラクティスに準拠
- [x] SharedPreferencesの使用方法が標準的
- [x] テストが実装可能（ProviderContainerを使用）

### ⚠️ 改善が必要な点

#### 非機能要件の詳細
- テーマ即座反映の具体的な実装方法（後続タスクで詳細化）
- 大量の設定変更時のパフォーマンス（現時点では2項目のみのため問題なし）

#### エッジケースの網羅性
- マルチスレッド環境での設定変更（Flutterはシングルスレッドだが、念のため確認）

---

## 8. 次のステップ

### 推奨コマンド
次は `/tsumiki:tdd-testcases` でテストケースの洗い出しを行います。

### テストケースで確認すべき項目
1. **初期状態テスト**: デフォルト値（medium, light）の確認
2. **フォントサイズ変更テスト**: 3段階すべての変更を確認
3. **テーマモード変更テスト**: 3種類すべての変更を確認
4. **SharedPreferences連携テスト**: 永続化・復元の確認
5. **エラーハンドリングテスト**: SharedPreferences失敗時の動作確認
6. **状態通知テスト**: Riverpod stateが正しく更新されることを確認

---

## 更新履歴

- **2025-11-20**: TDD要件定義書作成（/tsumiki:tdd-requirementsにより生成）
  - EARS要件定義書（REQ-801, REQ-803, REQ-5003）を参照
  - architecture.md、dataflow.md、interfaces.dartから設計情報を抽出
  - Phase 1タスク（TASK-0013）の実装詳細を反映
  - 信頼性レベル（🔵🟡🔴）を各セクションに明記
