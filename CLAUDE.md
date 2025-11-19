# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

**kotonoha（ことのは）** - 文字盤コミュニケーション支援アプリ

発話困難な方が「できるだけ少ない操作で、自分の言いたいことを、適切な丁寧さで、安全に伝えられる」ことを目的としたタブレット向けコミュニケーション支援アプリケーション。

対象ユーザー: 脳梗塞・ALS・筋疾患などで発話が困難だが、タブレットのタップ操作がある程度可能な方々

## 開発フレームワーク: Tsumiki

このプロジェクトは **Tsumiki** (https://github.com/classmethod/tsumiki) を使用して開発されています。

### Tsumikiとは

Tsumikiは、要件定義から設計、タスク管理、テスト駆動実装まで一貫したワークフローを提供するClaude Codeプラグインです。EARS記法による構造化要件定義、自動ドキュメント生成、依存関係を考慮したタスク管理を特徴とします。

### 主要なTsumikiコマンド

**Kairo（包括フロー）** - メイン開発フロー:
- `/tsumiki:init-tech-stack` - 技術スタック選定
- `/tsumiki:kairo-requirements` - EARS記法による要件定義書作成
- `/tsumiki:kairo-design` - 技術設計文書生成
- `/tsumiki:kairo-tasks` - 実装タスク分割（1日単位、1ヶ月フェーズ）
- `/tsumiki:kairo-implement` - タスク実装

**TDD開発サイクル**:
- `/tsumiki:tdd-requirements` - 機能要件整理
- `/tsumiki:tdd-testcases` - テストケース洗い出し
- `/tsumiki:tdd-red` - 失敗するテスト作成
- `/tsumiki:tdd-green` - テストを通す実装
- `/tsumiki:tdd-refactor` - リファクタリング
- `/tsumiki:tdd-verify-complete` - 完了検証

**リバースエンジニアリング**（既存コード分析用）:
- `/tsumiki:rev-tasks` - 実装済み機能からタスク抽出
- `/tsumiki:rev-design` - アーキテクチャ設計書逆生成
- `/tsumiki:rev-specs` - テストケース・仕様書逆生成
- `/tsumiki:rev-requirements` - 要件定義書逆生成

## 技術スタック

- **フロントエンド**: Flutter 3.38.1 + Riverpod 2.x
- **バックエンド**: FastAPI 0.121 + SQLAlchemy 2.x + PostgreSQL 15+
- **開発環境**: Docker + Docker Compose

詳細な技術スタック、セットアップ手順、推奨ディレクトリ構造については `docs/tech-stack.md` を参照してください。

## アーキテクチャの重要な設計判断

### オフラインファースト設計 🔵
- **基本機能はすべてオフラインで動作** (文字盤入力、定型文、履歴、TTS読み上げ)
- AI変換のみオンライン必須、オフライン時は無効化
- ユーザーデータは**端末内ローカル保存**（Hive使用）
- プライバシー重視: クラウド同期なし、単一端末完結

### パフォーマンス要件
- TTS読み上げ開始: **1秒以内** (OS標準TTS利用でローカル処理)
- 文字盤タップ応答: **100ms以内**
- AI変換応答: **平均3秒以内**

### アクセシビリティ要件
- タップターゲットサイズ: **最小44px × 44px、推奨60px × 60px**
- フォントサイズ: 小/中/大の3段階
- テーマ: ライト/ダーク/高コントラストの3種類
- 高コントラストモード: WCAG 2.1 AAレベル（コントラスト比4.5:1以上）
- タップ主体の操作（スワイプ等のジェスチャーに依存しない）

## ディレクトリ構造

### Tsumiki生成ドキュメント（docs/）

```
docs/
├── tech-stack.md              # 技術スタック定義・セットアップ手順
├── spec/                      # 要件定義（EARS記法）
│   ├── kotonoha-requirements.md
│   ├── kotonoha-user-stories.md
│   └── kotonoha-acceptance-criteria.md
├── design/kotonoha/           # 技術設計
│   ├── architecture.md
│   ├── dataflow.md
│   ├── api-endpoints.md
│   ├── database-schema.sql
│   └── interfaces.dart
└── tasks/                     # タスク管理（フェーズ分割）
    ├── kotonoha-overview.md
    ├── kotonoha-phase1.md ... phase5.md
```

backend/、frontend/、docker/などのコード構造については `docs/tech-stack.md` を参照してください。

## 開発コマンド

よく使うコマンド：

```bash
# Docker環境起動
docker-compose up -d

# バックエンドサーバー起動
cd backend
uvicorn app.main:app --reload

# Flutterアプリ起動
cd frontend/kotonoha_app
flutter run -d chrome

# テスト実行
pytest                    # Backend
flutter test              # Frontend

# コード生成（Riverpod, Hive等）
flutter pub run build_runner build --delete-conflicting-outputs

# DBマイグレーション
alembic upgrade head
```

詳細なコマンド、セットアップ手順については `docs/tech-stack.md` を参照してください。

## テスト戦略

### 品質基準
- 全体カバレッジ: **80%以上**
- ビジネスロジック・APIエンドポイント: **90%以上**
- コード品質: flutter_lints、Ruff + Black準拠

### TDD開発フロー（Tsumiki推奨）
1. `/tsumiki:tdd-requirements` - 機能要件を整理
2. `/tsumiki:tdd-testcases` - テストケースを洗い出し
3. `/tsumiki:tdd-red` - 失敗するテストを作成
4. `/tsumiki:tdd-green` - テストを通す最小限の実装
5. `/tsumiki:tdd-refactor` - リファクタリング
6. `/tsumiki:tdd-verify-complete` - 全テスト成功を検証

## API仕様

### ベースURL
- 開発環境: `http://localhost:8000`
- ドキュメント: `http://localhost:8000/docs` (Swagger UI)

### 主要エンドポイント
- `POST /api/v1/ai/convert` - AI変換（平均3秒以内）
  - 入力テキストを丁寧さレベルに応じて変換
  - politeness_level: "casual", "normal", "polite"
- `POST /api/v1/ai/regenerate` - AI変換再生成
- `GET /api/v1/health` - ヘルスチェック

### レート制限
- AI変換API: 1分間に10リクエスト

## セキュリティ・プライバシー

### データ保存ポリシー
- **ローカルストレージ優先**: 定型文、履歴、お気に入り、設定はすべて端末内（Hive）
- **AI変換時のプライバシー**: 初回利用時に明示的な同意取得、プライバシーポリシー表示
- **通信セキュリティ**: HTTPS/TLS 1.2+、JWT認証
- **データ削除**: ユーザーが任意に削除可能、アンインストール時全削除

### 環境変数管理
- 開発: `.env`ファイル（Gitignore必須）
- 本番: クラウド環境変数機能（AWS Secrets Manager等）
- `.env.example`を参照してセットアップ

## 重要な制約・前提条件

### MVP範囲外（実装しない）
- クラウド同期・アカウント管理・複数端末間のデータ共有
- 視線入力・外部スイッチ・スキャン入力などの特殊インターフェース
- 音声認識（音声入力）機能
- 画像・絵文字・スタンプ機能
- ビデオ通話連携

### プラットフォーム要件
- iOS: 14.0以上、Android: 10以上、Web: Chrome/Safari/Edge最新版
- 推奨デバイス: 9.7インチ以上のタブレット

詳細は `docs/design/kotonoha/architecture.md` を参照してください。

## 開発ワークフロー（Tsumiki推奨）

### 新機能開発の流れ
1. `/tsumiki:kairo-requirements` - 要件定義（EARS記法）
2. `/tsumiki:kairo-design` - 設計書生成
3. `/tsumiki:kairo-tasks` - タスク分割（1日単位）
4. `/tsumiki:kairo-implement` - TDDサイクルで実装
5. CI/CD自動テスト・デプロイ

Git ブランチ戦略等の詳細は `docs/tech-stack.md` を参照してください。

## 参考資料

### プロジェクト内ドキュメント
- **技術スタック・セットアップ**: `docs/tech-stack.md`
- **要件定義書**: `docs/spec/kotonoha-requirements.md`
- **アーキテクチャ設計**: `docs/design/kotonoha/architecture.md`
- **データフロー図**: `docs/design/kotonoha/dataflow.md`
- **API仕様**: `docs/design/kotonoha/api-endpoints.md`
- **タスク管理**: `docs/tasks/kotonoha-overview.md`
- **Tsumiki Manual**: https://github.com/classmethod/tsumiki/blob/main/MANUAL.md

## 注意事項

### Tsumiki生成コンテンツについて
- Tsumikiが生成したドキュメント（docs/配下）は**人間のレビューが必須**
- 特に非機能要件やエッジケースは推定を含むため、実装時に検証が必要
- 🔵（青信号）は要件定義書ベース、🟡（黄信号）は妥当な推測、🔴（赤信号）は完全な推測

### コーディング規約
- **Flutter**:
  - Null Safety有効
  - `const`コンストラクタを可能な限り使用
  - ウィジェットは`key`パラメータを持つ
- **Python**:
  - 型ヒント必須
  - 行長100文字以内
  - docstringはGoogle Styleで記述

### パフォーマンス最適化
- TTS読み上げはOS標準を使用（低遅延）
- 文字盤UIはネイティブFlutterウィジェット（100ms応答）
- AI変換は非同期処理、3秒超過時はローディング表示
