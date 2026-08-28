# CI/CDパイプライン設定ガイド (TASK-0094)

## 🔵 信頼性レベル

このドキュメントは要件定義書のNFR-501, NFR-502, NFR-503に基づいて作成されています。

## 概要

kotonohaプロジェクトのCI/CDパイプラインは、GitHub Actionsを使用して以下を自動化します：

- コードの品質チェック（Lint、フォーマット）
- テスト実行とカバレッジ計測
- ビルド（Web、Android、iOS）
- デプロイ（Web: Vercel、バックエンド: クラウド環境）

## ワークフロー構成

### 1. Flutter CI/CD (`flutter.yml`)

| ジョブ名 | 説明 | トリガー |
|----------|------|----------|
| analyze | Lint、フォーマットチェック | PR/Push (frontend/) |
| test | 単体テスト、カバレッジ計測 | analyze完了後 |
| integration-test | 統合テスト（Chrome headless） | test完了後 |
| build-web | Webビルド | test完了後 |
| build-android | APKビルド | test完了後 |
| build-ios | iOSビルド | main/developのみ |
| deploy-web | Vercelデプロイ | mainのみ |

### 2. Python CI/CD (`python.yml`)

| ジョブ名 | 説明 | トリガー |
|----------|------|----------|
| lint | Ruff、Blackチェック | PR/Push (backend/) |
| test | pytest、カバレッジ計測 | lint完了後 |
| security | pip-auditセキュリティ監査 | PR/Push |
| build-docker | Dockerイメージビルド | main/developのみ |
| deploy-staging | ステージング環境デプロイ | developのみ |
| deploy-production | 本番環境デプロイ | mainのみ |

### 3. Release (`release.yml`)

タグ `v*` がプッシュされた時に実行：
- Web、Android、iOSのリリースビルド
- GitHub Releaseの作成
- Vercelへの本番デプロイ

## GitHub Secretsの設定

### 必須シークレット

リポジトリの Settings > Secrets and variables > Actions で以下を設定：

#### Codecov
```
CODECOV_TOKEN: Codecovのアップロードトークン
  - 取得先: https://app.codecov.io/gh/<org>/<repo>/settings
```

#### Vercel (Webデプロイ用)
```
VERCEL_TOKEN: Vercelのアクセストークン
  - 取得先: https://vercel.com/account/tokens

VERCEL_ORG_ID: Vercel組織ID
  - 取得先: プロジェクト設定 > General > Project ID の下部

VERCEL_PROJECT_ID: VercelプロジェクトID
  - 取得先: プロジェクト設定 > General > Project ID
```

#### Android署名 (リリースビルド用)
```
ANDROID_KEYSTORE_BASE64: Base64エンコードされたキーストア
  - 生成: base64 -i upload-keystore.jks -o keystore.txt

ANDROID_KEY_PASSWORD: キーパスワード
ANDROID_STORE_PASSWORD: ストアパスワード
ANDROID_KEY_ALIAS: キーエイリアス
```

#### iOS署名 (リリースビルド用)
```
APPLE_BUILD_CERTIFICATE_BASE64: Base64エンコードされた証明書
  - 生成: base64 -i certificate.p12 -o certificate.txt

APPLE_P12_PASSWORD: P12パスワード
APPLE_KEYCHAIN_PASSWORD: キーチェーンパスワード（任意の文字列）
```

## Environments設定

Settings > Environments で以下を作成：

### staging
- developブランチからのデプロイ用
- 保護ルール: なし（自動デプロイ）

### production
- mainブランチからのデプロイ用
- 保護ルール: 承認必須（推奨）

## カバレッジしきい値

| 対象 | しきい値 | 備考 |
|------|----------|------|
| Flutter全体 | 80% | 警告表示、失敗はしない |
| Python全体 | 90% | ビジネスロジック重視 |
| 新規コード（patch） | 80% | 新しいコードの品質維持 |

## ブランチ戦略

```
main ──────────────────────────────────→ 本番デプロイ
  │
  └── develop ─────────────────────────→ ステージングデプロイ
        │
        └── feature/* ─────────────────→ PRのみ（自動テスト）
```

## 使用しているGitHub Actions

| Action | バージョン | 用途 |
|--------|------------|------|
| actions/checkout | v4 | リポジトリチェックアウト |
| actions/setup-java | v4 | Java環境 (Android) |
| actions/setup-python | v5 | Python環境 |
| actions/upload-artifact | v4 | ビルド成果物アップロード |
| actions/download-artifact | v4 | ビルド成果物ダウンロード |
| subosito/flutter-action | v2 | Flutter環境 |
| codecov/codecov-action | v4 | カバレッジアップロード |
| docker/setup-buildx-action | v3 | Docker Buildx |
| docker/build-push-action | v5 | Dockerビルド・プッシュ |
| amondnet/vercel-action | v25 | Vercelデプロイ |
| softprops/action-gh-release | v1 | GitHub Release作成 |

## トラブルシューティング

### テストが失敗する場合
1. ローカルでテストを実行して確認
2. 環境変数が正しく設定されているか確認
3. 依存関係のバージョンを確認

### カバレッジがアップロードされない場合
1. CODECOV_TOKENが設定されているか確認
2. codecov.ymlのパス設定を確認

### デプロイが失敗する場合
1. 必要なシークレットが設定されているか確認
2. 環境の保護ルールを確認
3. Vercel/クラウドサービスの設定を確認

## 更新履歴

- 2025-12-02: 初版作成 (TASK-0094)
