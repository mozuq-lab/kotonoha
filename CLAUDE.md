# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

**kotonoha（ことのは）** - 文字盤コミュニケーション支援アプリ

発話困難な方が「できるだけ少ない操作で、自分の言いたいことを、適切な丁寧さで、安全に伝えられる」ことを目的としたタブレット向けコミュニケーション支援アプリケーション。

対象ユーザー: 脳梗塞・ALS・筋疾患などで発話が困難だが、タブレットのタップ操作がある程度可能な方々

## 作業の進め方 — 目的と道具

**原則: 目的は固定、道具は差し替え可能。** 下の表の「目的」列が守るべきもので、
「道具」列はいま最も適したものを割り当てているだけ。より良いものが出たら**道具列だけ**を
書き換える。**道具の名前を目的だと思わないこと。**

このプロジェクトは 2025-10 に Tsumiki のワークフロー（kairo-* / dev-*）で開始したが、
**工程記録が恒久成果物になる**問題があったため、ワークフローとしては使っていない。
単発の分析・壁打ち道具としては採用している（下表）。経緯は
`docs/plans/2026-08-29-architecture-remediation.md`、判断の原則は
`docs/verification-principles.md`。

### いつでも守ること

| 目的 | いま使う道具 |
|---|---|
| **完了と言う前に、実物を動かして確認する** | `superpowers:verification-before-completion` / `run` |
| **改修に着手する前に、影響範囲を出す** | `tsumiki:dcs:impact-analysis` |
| 負債を作る行為をその場で検出する | `PostToolUse` フック（設定は `update-config`） |

上2つは、8周のレビュー往復が収束しなかった直接の原因に対応する
（誰もアプリを起動しなかった／触る範囲を数えなかった）。

### 段階ごと

| 段階 | 目的 | いま使う道具 |
|---|---|---|
| 決める | 決定を引き出し、**却下案と理由ごと**記録する | `tsumiki:adr-rubber-duck`（出力先 `docs/adr/`） |
| 決める | 決定を叩いて弱いものを落とす | `mattpocock-skills:grilling` / `openspec-explore` |
| 設計 | 境界（seam）の位置とモックの置き場を決める | `mattpocock-skills:codebase-design` |
| 設計 | データの状態遷移を洗い出す | `tsumiki:dcs:state-transition-analysis` |
| 設計 | ドメイン語彙を整理する | `mattpocock-skills:domain-modeling` |
| 実装 | 仕様を delta で積む | OpenSpec（`openspec/specs/` のみ恒久） |
| 検証 | セキュリティを**反証可能な形で**検査する | `tsumiki:ipa-security-check`（IPA 原典の出典が付く） |
| 検証 | 仕様と実装の乖離を出す | `tsumiki:rev-requirements` / `rev-specs`（**逆生成物を正本にしない**） |
| 棚卸し | 全体を見て概念の重複を検出する | **未整備。プロジェクト固有スキルとして作る** |

**採らないもの**: `kairo-*` フロー、`dev-plan` → `dev-impl` → `dev-run` → `dev-verify`、
`task-breakdown`。いずれも成果物を積み上げる設計で、恒久成果物が工程記録になる。

**現在のフェーズと、フェーズごとの割り当ては
`docs/plans/2026-08-29-architecture-remediation.md` の §5 を見ること。**

## 技術スタック

- **フロントエンド**: Flutter 3.38.1 + Riverpod 3.x（`flutter_riverpod: ^3.1.0`）
- **バックエンド**: FastAPI 0.124 + SQLAlchemy 2.x + PostgreSQL 15+
- **IaC**: AWS CDK 2.x (TypeScript)
- **開発環境**: Docker + Docker Compose

詳細な技術スタック、セットアップ手順、ディレクトリ構造については `docs/tech-stack.md` を参照してください。

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

### ドキュメント（docs/）

```
docs/
├── tech-stack.md              # 技術スタック定義・セットアップ手順
├── verification-principles.md # 検証と完了判定の原則（8周の失敗から抽出）
├── plans/                     # これから何をするか（完了したら破棄する）
├── adr/                       # アーキテクチャ決定（Phase 0 で作成）
├── spec/                      # 要件定義（EARS記法）
├── design/kotonoha/           # 技術設計
├── articles/                  # 経緯の記事
└── archive/                   # 歴史記録。更新しない。現在の仕様として読まないこと
    ├── implements/            # Tsumiki の TDD 実行記録 299ファイル
    └── tasks/                 # フェーズ計画 6ファイル
```

**コードと文書が食い違っていたら、コードが正である。** 文書側を直すか、
直せないなら `docs/archive/` へ移すこと。

backend/、frontend/、docker/などのコード構造については `docs/tech-stack.md` を参照してください。

## 開発コマンド

よく使うコマンド：

```bash
# Docker環境起動
docker-compose up -d

# バックエンドサーバー起動（リポジトリルートから）
(cd backend && uvicorn app.main:app --reload)

# Flutterアプリ起動（ローカルのdocker-compose構成ならデフォルトのままでよい）
# 以降はリポジトリルートから frontend/kotonoha_app に移動した状態で実行する
cd frontend/kotonoha_app
flutter run -d chrome

# 接続先・端末APIキーを差し替える場合はルート .env から --dart-define で渡す。
# 空文字を渡すと String.fromEnvironment の defaultValue が打ち消されるため、
# 未設定キーは必ずフォールバックで補うこと。
# ルート .env が未作成だと source が失敗する（set -e 環境では中断する）
set -a; source ../../.env; set +a
DEFINES=(--dart-define=API_BASE_URL="${API_BASE_URL:-http://localhost:8000}")
if [ -n "${AI_API_KEY:-}" ]; then
  DEFINES+=(--dart-define=AI_API_KEY="$AI_API_KEY")
fi
flutter run -d chrome "${DEFINES[@]}"

# テスト実行
pytest                    # Backend
flutter test              # Frontend

# DBマイグレーション
alembic upgrade head
```

詳細なコマンド、セットアップ手順については `docs/tech-stack.md` を参照してください。

## テスト戦略

### 品質基準
- 全体カバレッジ: **80%以上**
- ビジネスロジック・APIエンドポイント: **90%以上**
- コード品質: flutter_lints、Ruff + Black準拠

### テストを書くときの規律

- **修正の前にテストを書き、赤を確認してから直す。** 後に書くと、修正が効く観測点を
  無意識に選んでしまう
- **モックは外部 SDK / ネットワーク境界にのみ置く。自分の関数を patch しない。**
  漏えいシンクを36箇所でモックしていた前例がある
- **完全一致アサーションを書かない。** 「このアサーションは、実装を安全側に変えたときに
  落ちるか」を自問する。落ちるならそれは仕様ではなく実装のスナップショット
- **検証は最も外側の境界で行う。** 戻り値ではなく、プロセスの stdout/stderr、
  実際の DB 行、HTTP レスポンス、描画されたウィジェット

理由と実例は `docs/verification-principles.md`。

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
- AI変換API: 1リクエスト/10秒/IP（デフォルト。NFR-101準拠）
  - `RATE_LIMIT_TIMES`（回数）・`RATE_LIMIT_SECONDS`（秒数）環境変数で変更可能
  - マルチワーカー/マルチインスタンス構成では `RATE_LIMIT_STORAGE_URI` にRedis等の共有ストレージURIを指定すること（未指定時はプロセス内メモリのため各プロセスで独立したカウンタになる）
  - **`TRUSTED_PROXY_COUNT`（デフォルト0）**: レート制限のクライアント識別に信頼する自前プロキシ（ALB/CDN等）の段数。ALB配下など本番でリバースプロキシを経由する構成では**必須設定**
    - `0` の場合は `X-Forwarded-For` を一切信頼せず接続元IPを使用する
    - `1` 以上の場合は XFF の右からN番目（＝信頼プロキシが観測したクライアントIP）を採用する
    - XFFのチェーンが設定段数に満たない場合は、偽装を避けるためヘッダーを採用せず接続元IPへフォールバックする（フェイルクローズ）
    - **過大設定に注意**: 実構成より大きい値（例: ALB1段なのに2）を設定すると、XFFが常に不採用となり全リクエストがプロキシの接続元IPに収束する。結果としてレート制限が全ユーザーで共有され、実質的なサービス停止になる。本番投入時は実際のプロキシ段数を確認し、投入直後に429の発生率を監視すること

## セキュリティ・プライバシー

### データ保存ポリシー
- **ローカルストレージ優先**: 定型文、履歴、お気に入り、設定はすべて端末内（Hive）
- **AI変換時のプライバシー**: 初回利用時に明示的な同意取得、プライバシーポリシー表示
- **通信セキュリティ**: HTTPS/TLS 1.2+。AI変換エンドポイントは端末APIキー認証（`X-API-Key`ヘッダー、複数キー対応。開発/テスト環境では認証スキップ、本番では必須）
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

## 開発ワークフロー

### 改修に着手する前に

1. **触る領域の ADR を読む**（`docs/adr/`）。該当する ADR が無ければ、
   **その領域の決定が存在しない**ということなので、実装前に確認すること
2. **影響範囲を出す**（`tsumiki:dcs:impact-analysis`）。「そもそも必要か」を
   ここで問う。8周のレビュー往復は、この工程が無かったために起きた
3. 大きな決定を伴うなら、実装の前に ADR を1本作る（`tsumiki:adr-rubber-duck`）

### 負債を作る行為には理由が要る

次に触れる変更は、該当する ADR を引用すること（無ければ決定から始める）。

- 依存の追加（`requirements.txt` / `pubspec.yaml`）
- 永続化面の追加（Hive の TypeAdapter・フィールド、DB テーブル、ファイル出力先）
- 秘密を持つ設定キーの追加
- モジュールレベルの可変グローバルの追加

### コミット戦略
- **1タスク完了ごとにコミット**: タスク（TASK-XXXX）が完了したら、必ずその時点でGitコミットを作成すること
- コミットメッセージ形式: `タスク内容 (TASK-XXXX)`
- 例: `Add Docker environment setup (TASK-0002)`
- 変更履歴を細かく記録し、問題発生時のロールバックを容易にする

Git ブランチ戦略等の詳細は `docs/tech-stack.md` を参照してください。

## 参考資料

### プロジェクト内ドキュメント
- **技術スタック・セットアップ**: `docs/tech-stack.md`
- **要件定義書**: `docs/spec/kotonoha-requirements.md`
- **アーキテクチャ設計**: `docs/design/kotonoha/architecture.md`
- **データフロー図**: `docs/design/kotonoha/dataflow.md`
- **API仕様**: `docs/design/kotonoha/api-endpoints.md`
- **今後の対応計画**: `docs/plans/2026-08-29-architecture-remediation.md`
- **検証と完了判定の原則**: `docs/verification-principles.md`
- **Tsumiki Manual**（個別スキルの仕様）: https://github.com/classmethod/tsumiki/blob/main/MANUAL.md

## 注意事項

### 過去に生成されたコンテンツについて
- `docs/archive/` は歴史記録である。**更新しない。現在の仕様として読まないこと**
- コード中に残る `【】` 記法のコメントと `🔵🟡🔴` の信頼性レベル記号は、
  **生成時点の確信度であってコードの性質ではない**。整理対象（Phase 5）
- **自分（や前のセッション）が書いた文書を「事実」として扱わない。**
  数字・パス・行番号は、使う前に必ず現物で確かめること

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
