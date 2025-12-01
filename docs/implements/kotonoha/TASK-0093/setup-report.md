# TASK-0093 Webビルド設定 - 設定作業実行

## 作業概要

- **タスクID**: TASK-0093
- **作業内容**: Flutter Webビルド設定・PWA設定・Vercel/Netlifyデプロイ設定
- **実行日時**: 2025-12-02
- **信頼性レベル**: 🔵 青信号（NFR-401の要件に基づく設定）

## 設計文書参照

- **参照文書**:
  - `docs/design/kotonoha/architecture.md` - デプロイ戦略
  - `docs/spec/kotonoha-requirements.md` - NFR-401
  - `docs/tech-stack.md` - 技術スタック定義
- **関連要件**: NFR-401（Chrome、Safari、Edge最新版対応）

## 実行した作業

### 1. index.html の更新

**変更ファイル**: `frontend/kotonoha_app/web/index.html`

**変更内容**:
| 設定項目 | 変更前 | 変更後 |
|---------|--------|--------|
| lang属性 | なし | ja |
| viewport | 基本設定 | 拡大縮小無効化追加 |
| description | Flutter default | kotonoha向け説明文 |
| OGP設定 | なし | 完全対応 |
| PWA設定 | 基本 | iOS/Android完全対応 |
| ローディング画面 | なし | カスタム実装 |
| Service Worker | 手動登録 | Flutter自動登録に変更 |

**追加設定**:
- SEOメタタグ（description、keywords、author、robots）
- Open Graph / Twitterカードメタタグ
- iOS PWA対応（apple-mobile-web-app-*）
- テーマカラー（ライト/ダークモード対応）
- アクセシビリティ対応ローディング画面
- noscriptフォールバック

### 2. manifest.json の更新

**変更ファイル**: `frontend/kotonoha_app/web/manifest.json`

**変更内容**:
| 設定項目 | 変更前 | 変更後 |
|---------|--------|--------|
| name | kotonoha_app | kotonoha - 文字盤コミュニケーション支援アプリ |
| short_name | kotonoha_app | ことのは |
| description | A new Flutter project | 日本語説明文 |
| background_color | #0175C2 | #F5F5F5 |
| theme_color | #0175C2 | #4A90A4 |
| orientation | portrait-primary | any |
| lang | なし | ja |
| categories | なし | accessibility, communication, health |
| shortcuts | なし | 文字盤・定型文ショートカット |

### 3. Vercel設定ファイルの作成

**作成ファイル**: `frontend/kotonoha_app/vercel.json`

**設定内容**:
- セキュリティヘッダー（X-Content-Type-Options、X-Frame-Options等）
- Service Worker専用ヘッダー
- 静的アセットキャッシュ設定（1年）
- JavaScriptファイルのContent-Type設定
- WASMファイルのContent-Type設定
- SPAルーティング用リダイレクト設定

### 4. Netlify設定ファイルの作成

**作成ファイル**: `frontend/kotonoha_app/netlify.toml`

**設定内容**:
- SPAルーティング用リダイレクト設定
- 静的ファイル除外ルール
- セキュリティヘッダー設定
- Service Worker専用ヘッダー
- 静的アセットキャッシュ設定
- 環境別設定（production、deploy-preview、branch-deploy）

### 5. ビルドスクリプトの作成

**作成ファイル**: `scripts/build-web.sh`

**機能**:
```bash
./scripts/build-web.sh debug      # デバッグビルド
./scripts/build-web.sh release    # リリースビルド
./scripts/build-web.sh profile    # プロファイルビルド
./scripts/build-web.sh serve      # ローカルサーバー起動
./scripts/build-web.sh clean      # クリーン
```

**オプション**:
- `--base-href [path]` - デプロイパス設定
- `--pwa` / `--no-pwa` - PWA有効/無効
- `--tree-shake-icons` / `--no-tree-shake-icons` - アイコン最適化
- `--wasm` - WebAssemblyビルド（実験的）
- `--port [number]` - サーバーポート設定

### 6. 環境設定テンプレートの作成

**作成ファイル**: `frontend/kotonoha_app/web/.env.example`

**設定内容**:
- API設定（API_BASE_URL、API_VERSION）
- 機能フラグ（ENABLE_AI_CONVERSION、DEBUG_MODE）
- PWA設定（PWA_UPDATE_STRATEGY、CACHE_VERSION）
- デプロイ設定（BASE_HREF、PUBLIC_URL）

## 作業結果

- [x] index.html のkotonoha向け最適化完了
- [x] manifest.json のPWA設定更新完了
- [x] Vercel設定ファイル（vercel.json）作成完了
- [x] Netlify設定ファイル（netlify.toml）作成完了
- [x] ビルドスクリプト（build-web.sh）作成完了
- [x] 環境設定テンプレート作成完了
- [x] Flutterリリースビルド成功

## ビルドテスト結果

### リリースビルド

```bash
flutter build web --release
# 結果: ✓ Built build/web
```

**ビルド出力**:
- 出力サイズ: 30MB
- main.dart.js: 2.8MB
- Font tree-shaking: MaterialIcons 99.3%削減、CupertinoIcons 99.4%削減

### ファイル構成

```
build/web/
├── index.html              # カスタマイズ済み
├── manifest.json           # PWA設定
├── flutter_bootstrap.js    # Flutter起動スクリプト
├── flutter_service_worker.js # Service Worker
├── main.dart.js           # アプリケーションコード
├── favicon.png            # ファビコン
├── version.json           # バージョン情報
├── assets/                # アセットファイル
├── canvaskit/             # CanvasKitレンダラー
└── icons/                 # PWAアイコン
```

## 環境依存事項

### 必要な開発環境

| ツール | 要件 | 用途 |
|--------|------|------|
| Flutter SDK | 3.38+ | ビルド |
| Chrome | 最新版 | 開発・テスト |

### デプロイ先要件

**Vercel**:
- Vercel CLI インストール済み
- アカウント設定済み

**Netlify**:
- Netlify CLI インストール済み
- アカウント設定済み

## 遭遇した問題と解決方法

### 問題1: Service Worker手動登録の警告

- **発生状況**: Flutter Webビルド時
- **警告メッセージ**: `Manual service worker registration deprecated`
- **解決方法**: index.htmlから手動のService Worker登録を削除し、flutter.jsの自動登録に変更
- **影響**: 解決済み、警告なしでビルド成功

### 問題2: --web-renderer オプション廃止

- **発生状況**: ビルドスクリプト作成時
- **エラーメッセージ**: `Could not find an option named "--web-renderer"`
- **解決方法**: Flutter 3.38では`--web-renderer`オプションが廃止。スクリプトから削除
- **影響**: スクリプト修正済み

## 次のステップ

1. `/tsumiki:direct-verify` を実行して設定を確認
2. TASK-0094（CI/CDパイプライン構築）でWebビルドジョブを設定
3. TASK-0095（実機テスト）でブラウザ動作確認

## ファイル変更一覧

| ファイル | 変更種別 |
|----------|----------|
| `frontend/kotonoha_app/web/index.html` | 更新 |
| `frontend/kotonoha_app/web/manifest.json` | 更新 |
| `frontend/kotonoha_app/vercel.json` | 新規作成 |
| `frontend/kotonoha_app/netlify.toml` | 新規作成 |
| `frontend/kotonoha_app/web/.env.example` | 新規作成 |
| `scripts/build-web.sh` | 新規作成 |

## 備考

- PWA対応により、ユーザーはブラウザからアプリをインストール可能
- オフラインキャッシュ戦略は`offline-first`（NFR-301対応）
- 静的アセットは1年間キャッシュで配信効率化
- WebAssembly対応は`--wasm`フラグで実験的に利用可能
