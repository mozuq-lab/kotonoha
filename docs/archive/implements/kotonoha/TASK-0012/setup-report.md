# TASK-0012 Flutter依存パッケージ追加・pubspec.yaml設定 - 設定作業実行

## 作業概要

- **タスクID**: TASK-0012
- **作業内容**: Flutter依存パッケージ追加とpubspec.yaml設定
- **実行日時**: 2025-11-20
- **タスクタイプ**: DIRECT
- **前提タスク**: TASK-0011（Flutterプロジェクトディレクトリ構造設計）完了

## 設計文書参照

- **参照文書**:
  - `docs/tech-stack.md` - 技術スタック定義書
  - `docs/design/kotonoha/architecture.md` - アーキテクチャ設計書
  - `docs/tasks/kotonoha-phase1.md` - Phase 1タスク定義

## 実行した作業

### 1. pubspec.yaml編集

**作業内容**: Flutter依存パッケージを追加し、プロジェクト設定を更新

**編集ファイル**: `frontend/kotonoha_app/pubspec.yaml`

**追加した依存パッケージ**:

#### 本番依存関係 (dependencies)

1. **状態管理**:
   - `flutter_riverpod: ^2.6.1` - Riverpod状態管理ライブラリ
   - `riverpod_annotation: ^2.6.1` - Riverpodコード生成用アノテーション

2. **ルーティング**:
   - `go_router: ^14.6.2` - 宣言的ルーティング、ディープリンク対応

3. **ローカルストレージ**:
   - `shared_preferences: ^2.3.4` - シンプルなkey-value保存（設定用）
   - `hive: ^2.2.3` - 高速NoSQLローカルデータベース（定型文・履歴用）
   - `hive_flutter: ^1.1.0` - Hive Flutter統合

4. **HTTP通信**:
   - `dio: ^5.7.0` - 強力なHTTPクライアント
   - `retrofit: ^4.4.1` - 型安全なAPI呼び出し

5. **JSON処理**:
   - `json_annotation: ^4.9.0` - JSON シリアライゼーション用アノテーション

6. **TTS（音声読み上げ）**:
   - `flutter_tts: ^4.2.0` - OS標準TTSを利用した音声読み上げ（REQ-401対応）

7. **ロギング**:
   - `logger: ^2.5.0` - ログ出力ユーティリティ

8. **多言語化**:
   - `intl: ^0.20.1` - 国際化・ローカリゼーション
   - `flutter_localizations: sdk: flutter` - Flutter公式ローカリゼーション

#### 開発依存関係 (dev_dependencies)

1. **コード生成**:
   - `build_runner: ^2.4.14` - Dartコード生成ツール
   - `riverpod_generator: ^2.6.1` - Riverpodコード生成
   - `json_serializable: ^6.9.2` - JSONシリアライゼーションコード生成
   - `retrofit_generator: ^9.1.4` - Retrofit APIクライアント生成

2. **テスト**:
   - `mocktail: ^1.0.4` - モック・スタブライブラリ

3. **コード品質**:
   - `flutter_lints: ^5.0.0` - Flutter公式リントルール

**環境設定**:
- SDK制約: `sdk: '>=3.5.0 <4.0.0'` (Dart 3.5以上、Flutter 3.38.1対応)
- `flutter.generate: true` - l10nコード生成を有効化

### 2. build.yaml設定ファイル作成

**作成ファイル**: `frontend/kotonoha_app/build.yaml`

```yaml
targets:
  $default:
    builders:
      riverpod_generator:
        options:
          riverpod_generator:
            generate_riverpod_annotation: true
```

**目的**: Riverpodコード生成の設定を定義

### 3. 依存関係インストール

**実行コマンド**:
```bash
cd frontend/kotonoha_app
flutter pub get
```

**結果**: 依存関係の解決と全パッケージのダウンロードが成功

**インストールされた主要パッケージ**:
- flutter_riverpod 2.6.1
- go_router 14.8.1
- hive 2.2.3
- hive_flutter 1.1.0
- dio 5.7.0
- retrofit 4.4.1
- flutter_tts 4.2.0
- logger 2.5.0
- build_runner 2.5.4
- riverpod_generator 2.6.5
- json_serializable 6.9.5
- retrofit_generator 9.7.0
- mocktail 1.0.4

### 4. 依存関係の確認

**実行コマンド**:
```bash
flutter pub outdated
```

**結果**: 27パッケージに新しいメジャーバージョンがあるが、現在の制約では全て互換性のあるバージョンが解決済み

### 5. 静的解析実行

**実行コマンド**:
```bash
flutter analyze
```

**結果**: No issues found! (1.1秒で完了)

## 遭遇した問題と解決方法

### 問題1: hive_generatorとriverpod_generatorの依存関係競合

**発生状況**: `flutter pub get` 実行時、analyzerパッケージのバージョン競合が発生

**エラーメッセージ**:
```
Because analyzer >=6.6.0 <6.9.0 depends on macros >=0.1.2-main.3 <0.1.3
and riverpod_generator >=2.6.1 <2.6.4 depends on analyzer ^6.7.0,
riverpod_generator is incompatible with hive_generator >=2.0.1
```

**原因**:
- hive_generator 2.0.1+がanalyzer 4.x-6.xを要求
- riverpod_generator 2.6.1+がanalyzer 6.7.0+を要求
- Flutter SDK 3.35.7に含まれるDart SDK 3.9.2には`_macros`パッケージが存在しない
- 新しいanalyzer 6.9.0+は`_macros`パッケージを必要とする

**解決方法**:
1. **hive_generatorを依存関係から除外**
   - Hiveアダプターは手動で実装する方針に変更
   - 将来的にコード生成が必要な場合は、freezedやbuilt_valueなど別の方法を検討

2. **最終的な依存関係構成**:
   - riverpod_generator 2.6.1 (analyzer 7.6.0を使用)
   - json_serializable 6.9.2 (互換性あり)
   - retrofit_generator 9.1.4 (互換性あり)
   - hive 2.2.3 (コード生成なしで使用)

**備考**: この問題は以下の理由により将来的には解決される見込み:
- Flutter SDKのアップデートで新しいDart SDKに`_macros`パッケージが追加される
- hive_generatorが新しいanalyzerに対応するアップデートをリリースする

## 作業結果

- [x] pubspec.yamlに必要な依存パッケージが追加されている
- [x] build.yaml設定ファイルが作成されている
- [x] `flutter pub get`でエラーがない
- [x] `flutter analyze`でエラーがない
- [x] 各パッケージが最新安定版または互換性のあるバージョンである

## 次のステップ

1. `/tsumiki:direct-verify` を実行して設定を確認
2. TASK-0013: Riverpod状態管理セットアップ・プロバイダー基盤実装に進む
3. 必要に応じて、Hiveアダプターの手動実装方法を確認

## 参考情報

### コード生成コマンド（今後の開発で使用）

```bash
# 一度だけコード生成を実行
flutter pub run build_runner build --delete-conflicting-outputs

# ファイル変更を監視して自動生成
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 主要パッケージのドキュメント

- [Riverpod](https://riverpod.dev/)
- [go_router](https://pub.dev/packages/go_router)
- [Hive](https://docs.hivedb.dev/)
- [Dio](https://pub.dev/packages/dio)
- [flutter_tts](https://pub.dev/packages/flutter_tts)

## 確認事項

- [x] `docs/implements/kotonoha/TASK-0012/setup-report.md` ファイルが作成されている
- [x] 依存関係が正しくインストールされている
- [x] 静的解析でエラーがない
- [x] 次のタスク（TASK-0013）の準備が整っている

---

**実装記録作成日**: 2025-11-20
**実装者**: Claude (tsumiki:direct-setup)
