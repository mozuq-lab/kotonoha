# Connpass Event Notifier - Deployment Guide

## デプロイ手順の詳細ガイド

このドキュメントは、connpass Event Notifierを初めてデプロイする方向けの詳細な手順です。

## ステップ1: AWS CLIの設定

### 1.1 AWS CLIのインストール

```bash
# macOS
brew install awscli

# Linux
pip install awscli

# Windows
# https://aws.amazon.com/cli/ からインストーラーをダウンロード
```

### 1.2 AWS認証情報の設定

```bash
aws configure
```

以下の情報を入力します：
- **AWS Access Key ID**: AWSコンソールから発行したアクセスキー
- **AWS Secret Access Key**: シークレットアクセスキー
- **Default region name**: `ap-northeast-1` (東京リージョン)
- **Default output format**: `json`

## ステップ2: AWS SAM CLIのインストール

### macOS

```bash
brew tap aws/tap
brew install aws-sam-cli
```

### Linux

```bash
# Python 3.8以上が必要
pip install aws-sam-cli
```

### Windows

[SAM CLI インストールガイド](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html)を参照

### インストール確認

```bash
sam --version
# SAM CLI, version 1.x.x 以上
```

## ステップ3: Amazon SESの設定

### 3.1 送信元メールアドレスの検証

1. AWSコンソールにログイン
2. Amazon SESサービスを開く
3. 左メニューから「Verified identities」を選択
4. 「Create identity」をクリック
5. 「Email address」を選択し、送信元として使用したいメールアドレスを入力
6. 「Create identity」をクリック
7. 入力したメールアドレスに検証メールが届くので、リンクをクリック

### 3.2 受信先メールアドレスの検証（Sandboxモードの場合）

SESはデフォルトでSandboxモードです。本番利用前に受信先も検証が必要です：

```bash
aws ses verify-email-identity --email-address your-recipient@example.com
```

または、AWSコンソールから同様に検証してください。

### 3.3 Sandboxモードの解除（本番利用時）

本番環境で任意のメールアドレスに送信したい場合：

1. SESコンソールで「Account dashboard」を選択
2. 「Request production access」をクリック
3. フォームに必要事項を記入して申請
4. 通常24時間以内に承認されます

## ステップ4: connpassユーザーIDの確認

1. connpassにログイン
2. 自分のプロフィールページにアクセス
3. URLを確認: `https://connpass.com/user/YOUR_USERNAME/`
4. `YOUR_USERNAME` の部分があなたのユーザーIDです

## ステップ5: 設定ファイルの編集

### 5.1 samconfig.toml の編集

`connpass-notifier/samconfig.toml` を開き、パラメータを編集：

```toml
parameter_overrides = [
    "ConnpassUserId=\"YOUR_CONNPASS_USERNAME\"",        # ← connpassユーザーID
    "NotificationEmail=\"your-email@example.com\"",     # ← 通知を受け取るメール
    "SenderEmail=\"verified-sender@example.com\"",      # ← SES検証済み送信元メール
    "NotificationHoursBefore=\"24\""                    # ← 何時間前に通知するか
]
```

### 5.2 設定例

```toml
parameter_overrides = [
    "ConnpassUserId=\"taro-yamada\"",
    "NotificationEmail=\"taro@example.com\"",
    "SenderEmail=\"no-reply@example.com\"",
    "NotificationHoursBefore=\"24\""
]
```

## ステップ6: ビルドとデプロイ

### 6.1 プロジェクトディレクトリに移動

```bash
cd connpass-notifier
```

### 6.2 SAMアプリケーションをビルド

```bash
sam build
```

成功すると `.aws-sam/` ディレクトリが作成されます。

### 6.3 デプロイ（初回）

```bash
sam deploy --guided
```

対話式で以下の質問に答えます：

```
Stack Name [connpass-notifier]: connpass-notifier
AWS Region [ap-northeast-1]: ap-northeast-1
Parameter ConnpassUserId []: your-connpass-username
Parameter NotificationEmail []: your-email@example.com
Parameter SenderEmail []: verified-sender@example.com
Parameter NotificationHoursBefore [24]: 24
#Shows you resources changes to be deployed
Confirm changes before deploy [Y/n]: Y
#SAM needs permission to be able to create roles
Allow SAM CLI IAM role creation [Y/n]: Y
#Preserves the state of previously provisioned resources
Disable rollback [y/N]: N
Save arguments to configuration file [Y/n]: Y
SAM configuration file [samconfig.toml]: samconfig.toml
SAM configuration environment [default]: default
```

### 6.4 デプロイ（2回目以降）

設定を変更した場合：

```bash
sam build
sam deploy
```

## ステップ7: デプロイ確認

### 7.1 CloudFormationスタックの確認

```bash
aws cloudformation describe-stacks --stack-name connpass-notifier
```

### 7.2 Lambda関数の確認

```bash
aws lambda list-functions | grep connpass-notifier
```

### 7.3 DynamoDBテーブルの確認

```bash
aws dynamodb list-tables | grep connpass-events
```

## ステップ8: 動作テスト

### 8.1 Event Checker関数を手動実行

```bash
# 関数名を取得
aws lambda list-functions --query "Functions[?contains(FunctionName, 'EventChecker')].FunctionName" --output text

# 関数を実行（関数名は上記で取得したものに置き換え）
aws lambda invoke \
  --function-name connpass-notifier-EventCheckerFunction-XXXXXXXXXXXX \
  --payload '{}' \
  response.json

# レスポンスを確認
cat response.json
```

### 8.2 DynamoDBでイベントを確認

```bash
aws dynamodb scan --table-name connpass-events
```

参加予定のイベントが登録されていれば成功です！

### 8.3 Email Notifier関数をテスト

```bash
# 関数名を取得
aws lambda list-functions --query "Functions[?contains(FunctionName, 'EmailNotifier')].FunctionName" --output text

# 関数を実行
aws lambda invoke \
  --function-name connpass-notifier-EmailNotifierFunction-XXXXXXXXXXXX \
  --payload '{}' \
  response.json

cat response.json
```

24時間以内に開催されるイベントがある場合、メールが送信されます。

## ステップ9: ログの確認

### CloudWatch Logsでログを確認

```bash
# Event Checkerのログ
aws logs tail /aws/lambda/connpass-notifier-EventCheckerFunction-XXXXXXXXXXXX --follow

# Email Notifierのログ
aws logs tail /aws/lambda/connpass-notifier-EmailNotifierFunction-XXXXXXXXXXXX --follow
```

## トラブルシューティング

### デプロイエラー

#### エラー: "Unable to upload artifact"

S3バケットの作成に失敗している可能性があります：

```bash
sam deploy --guided --resolve-s3
```

#### エラー: "No changes to deploy"

パラメータが変更されていない場合、以下を試してください：

```bash
sam deploy --parameter-overrides "ConnpassUserId=your-id NotificationEmail=email@example.com"
```

### Lambda実行エラー

#### エラー: "You must specify a region"

環境変数が正しく設定されているか確認：

```bash
aws configure get region
```

#### エラー: "Access Denied (SES)"

SESのメールアドレスが検証されているか確認：

```bash
aws ses list-verified-email-addresses
```

### メールが届かない

1. **SES検証状態を確認**
   ```bash
   aws ses get-identity-verification-attributes \
     --identities your-sender@example.com your-recipient@example.com
   ```

2. **SES送信制限を確認**
   ```bash
   aws ses get-send-quota
   ```

3. **迷惑メールフォルダを確認**

4. **CloudWatch Logsでエラーを確認**

## 更新と削除

### アプリケーションの更新

コードやパラメータを変更した場合：

```bash
sam build
sam deploy
```

### アプリケーションの削除

```bash
sam delete
```

または：

```bash
aws cloudformation delete-stack --stack-name connpass-notifier
```

## 次のステップ

- 定期的にログを確認して正常動作を確認
- 必要に応じて通知タイミングを調整
- 複数のconnpassアカウントを監視する場合は、スタックを複数デプロイ

## サポート

問題が発生した場合：
1. CloudWatch Logsを確認
2. GitHubのIssuesに報告
3. AWSサポートに問い合わせ（AWS関連の問題の場合）
