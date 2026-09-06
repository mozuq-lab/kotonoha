# 変更履歴 (Changelog)

このプロジェクトの主要な変更履歴を記録します。

フォーマットは [Keep a Changelog](https://keepachangelog.com/ja/1.0.0/) に基づいています。
バージョニングは [Semantic Versioning](https://semver.org/lang/ja/) に従います。

## [未リリース (Unreleased)]

### 予定されている変更
- Phase 2: 文字盤入力・定型文機能の実装

---

## [0.1.0] - 2025-11-22

### Phase 1: 開発環境構築・基盤実装

Phase 1では、開発環境の構築とアプリケーションの基盤を実装しました。

#### 追加 (Added)

**プロジェクト初期設定 (TASK-0001)**
- Gitリポジトリの初期化
- プロジェクトディレクトリ構造の作成
- `.gitignore`、`.gitattributes`の設定
- 環境変数テンプレート（`.env.example`）の作成

**Docker環境構築 (TASK-0002, TASK-0003)**
- PostgreSQL 15 Dockerコンテナの設定
- FastAPI Dockerコンテナの設定
- `docker-compose.yml`による統合環境構築
- 初期化スクリプトの作成

**Python開発環境 (TASK-0004)**
- `pyproject.toml`によるプロジェクト設定
- Ruff（リンター）の設定
- Black（フォーマッター）の設定
- pytest設定とカバレッジ測定

**Flutter開発環境 (TASK-0005)**
- Flutterプロジェクトの作成（iOS/Android/Web対応）
- `analysis_options.yaml`によるLint設定
- VS Code推奨設定の追加

**データベース設計・実装 (TASK-0006, TASK-0007, TASK-0008, TASK-0009)**
- データベーススキーマの設計
- AI変換履歴テーブル（`ai_conversion_history`）の作成
- Alembicマイグレーション環境の構築
- SQLAlchemyモデルの実装
- 初回マイグレーションの実行と検証
- データベース接続テスト（21テストケース）

**バックエンドAPI (TASK-0010)**
- FastAPIアプリケーションの基盤構築
- ヘルスチェックエンドポイント（`/health`）
- ルートエンドポイント（`/`）
- CORS設定
- OpenAPI仕様（Swagger UI / ReDoc）
- APIテスト（17テストケース）

**Flutterプロジェクト構造 (TASK-0011, TASK-0012)**
- Feature-basedディレクトリ構造の実装
- 定数ファイル（`app_colors.dart`、`app_sizes.dart`、`app_text_styles.dart`）
- 依存パッケージの追加:
  - flutter_riverpod 2.6.1
  - go_router 14.6.2
  - hive 2.2.3 / hive_flutter 1.1.0
  - dio 5.7.0
  - flutter_tts 4.2.0
  - logger 2.5.0

**状態管理・ストレージ (TASK-0013, TASK-0014)**
- Riverpod状態管理のセットアップ
- 設定プロバイダー（フォントサイズ、テーマモード）の実装
- SharedPreferencesによる設定永続化
- Hiveローカルストレージのセットアップ
- データモデル（HistoryItem、PresetPhrase）の実装
- テスト（41テストケース）

**ナビゲーション (TASK-0015)**
- go_routerによるルーティング設定
- 画面スケルトン:
  - ホーム画面（HomeScreen）
  - 設定画面（SettingsScreen）
  - 履歴画面（HistoryScreen）
  - お気に入り画面（FavoritesScreen）
  - エラー画面（ErrorScreen）
- ナビゲーションテスト（34テストケース）

**テーマ実装 (TASK-0016)**
- ライトテーマの実装
- ダークテーマの実装
- 高コントラストテーマの実装（WCAG 2.1 AA準拠）
- テーマプロバイダーの実装
- テーマ切り替え機能

**共通UIコンポーネント (TASK-0017)**
- LargeButton（大型ボタン、60px x 60px推奨サイズ）
- TextInputField（テキスト入力フィールド、最大1000文字）
- EmergencyButton（緊急ボタン、赤色円形）
- アクセシビリティ対応（44px以上のタップターゲット）

**ユーティリティ関数 (TASK-0018)**
- AppLogger（ログ出力ユーティリティ）
- Validators（バリデーション関数）
  - 入力テキスト検証（1000文字以内）
  - 定型文検証（500文字以内）
  - AI変換可否判定（2文字以上）
- ErrorHandler（エラーハンドリング）
  - ネットワークエラー処理
  - タイムアウトエラー処理
  - 日本語エラーメッセージ
- カスタム例外クラス（NetworkException、TimeoutException等）
- テスト（75テストケース、カバレッジ94.5%）

**CI/CDパイプライン (TASK-0019)**
- GitHub Actions - Flutter CI
  - 依存関係インストール・コード生成
  - 静的解析（flutter analyze）
  - フォーマットチェック（dart format）
  - テスト実行・カバレッジ測定
  - Web/APKビルド・アーティファクト保存
- GitHub Actions - Python CI
  - Lintチェック（ruff check、black --check）
  - PostgreSQLサービスコンテナでテスト実行
  - マイグレーション実行
  - pytest・カバレッジ測定
  - セキュリティ監査（pip-audit）
- Dependabot設定（週次依存関係更新）

**ドキュメント整備 (TASK-0020)**
- README.mdの包括的更新
- CONTRIBUTING.md（コントリビューションガイド）の作成
- docs/SETUP.md（開発環境セットアップガイド）の作成
- CHANGELOG.md（変更履歴）の作成

#### 技術的な詳細

**テストカバレッジ**
- バックエンド: 38テストケース
- フロントエンド: 150+テストケース
- 全体カバレッジ: 80%以上達成

**アクセシビリティ対応**
- タップターゲット: 最小44px、推奨60px
- コントラスト比: 4.5:1以上（高コントラストモード）
- 3段階フォントサイズ（小/中/大）
- 3種類テーマ（ライト/ダーク/高コントラスト）

**パフォーマンス目標**
- 文字盤タップ応答: 100ms以内
- TTS読み上げ開始: 1秒以内
- AI変換応答: 平均3秒以内

---

## バージョン履歴

| バージョン | リリース日 | 主な変更 |
|-----------|-----------|---------|
| 0.1.0 | 2025-11-22 | Phase 1: 開発環境構築・基盤実装 |

---

## リンク

- [README](README.md)
- [コントリビューションガイド](CONTRIBUTING.md)
- [開発環境セットアップ](docs/SETUP.md)
- [技術スタック](docs/tech-stack.md)
