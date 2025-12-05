# connpass Event Notifier

AWS SAM (Serverless Application Model)を使用した、connpassイベント通知システムです。

## 概要

このアプリケーションは、指定したconnpassアカウントのページを定期的にチェックし、参加予定のイベントが近づいたら指定したメールアドレスに通知を送信します。

### 主な機能

- **イベント自動チェック**: 6時間ごとにconnpassユーザーページをチェック
- **イベント情報の保存**: DynamoDBに参加予定イベントを保存
- **メール通知**: イベント開始前（デフォルト24時間前）にメール通知
- **重複通知の防止**: 一度通知したイベントは再通知しない
- **自動クリーンアップ**: イベント終了30日後に自動削除（DynamoDB TTL）

## アーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Cloud                                 │
│                                                              │
│  ┌──────────────┐      ┌──────────────────────┐            │
│  │ EventBridge  │      │   Lambda Function    │            │
│  │  (6時間毎)   │─────>│  Event Checker       │            │
│  └──────────────┘      │  - connpassスクレイピング │            │
│                        │  - イベント情報取得      │            │
│                        └──────────┬───────────┘            │
│                                   │                         │
│                                   ▼                         │
│                        ┌──────────────────────┐            │
│                        │    DynamoDB Table    │            │
│                        │  - イベント情報保存     │            │
│                        │  - 通知状態管理        │            │
│                        └──────────┬───────────┘            │
│                                   │                         │
│  ┌──────────────┐                 │                         │
│  │ EventBridge  │      ┌──────────▼───────────┐            │
│  │  (1時間毎)   │─────>│   Lambda Function    │            │
│  └──────────────┘      │  Email Notifier      │            │
│                        │  - 通知判定            │            │
│                        │  - メール送信          │            │
│                        └──────────┬───────────┘            │
│                                   │                         │
│                                   ▼                         │
│                        ┌──────────────────────┐            │
│                        │    Amazon SES        │            │
│                        │  - メール配信         │            │
│                        └──────────────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

## 前提条件

1. **AWS CLI** がインストールされ、設定されていること
   ```bash
   aws configure
   ```

2. **AWS SAM CLI** がインストールされていること
   ```bash
   # macOS
   brew install aws-sam-cli
   
   # Windows
   # https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
   ```

3. **Python 3.11** がインストールされていること

4. **Amazon SES** で送信元メールアドレスが検証済みであること
   - SESコンソールで送信元メールアドレスを検証
   - Sandboxモードの場合、受信先メールアドレスも検証が必要

## セットアップ

### 1. Amazon SESのメールアドレス検証

```bash
# 送信元メールアドレスを検証
aws ses verify-email-identity --email-address your-sender@example.com

# 受信先メールアドレスを検証（Sandboxモードの場合）
aws ses verify-email-identity --email-address your-recipient@example.com
```

検証メールが届くので、リンクをクリックして検証を完了してください。

### 2. 設定ファイルの編集

`samconfig.toml` を編集して、以下のパラメータを設定：

```toml
parameter_overrides = [
    "ConnpassUserId=\"your-connpass-username\"",
    "NotificationEmail=\"your-email@example.com\"",
    "SenderEmail=\"verified-sender@example.com\"",
    "NotificationHoursBefore=\"24\""
]
```

- **ConnpassUserId**: あなたのconnpassユーザー名（URLの `/user/USERNAME/` 部分）
- **NotificationEmail**: 通知を受け取るメールアドレス
- **SenderEmail**: SESで検証済みの送信元メールアドレス
- **NotificationHoursBefore**: イベント何時間前に通知するか（デフォルト: 24時間）

### 3. ビルドとデプロイ

```bash
# アプリケーションをビルド
sam build

# デプロイ（初回は--guided オプションで対話式設定）
sam deploy --guided

# 2回目以降はシンプルにデプロイ可能
sam deploy
```

`--guided` オプションを使用すると、以下の項目を対話的に設定できます：
- Stack名
- AWSリージョン
- パラメータの確認
- IAM権限の確認

## 使い方

### デプロイ後の動作確認

#### 1. Lambda関数を手動実行

```bash
# Event Checkerを手動実行
aws lambda invoke \
  --function-name connpass-notifier-EventCheckerFunction-XXXXX \
  --payload '{}' \
  response.json

# レスポンスを確認
cat response.json
```

#### 2. DynamoDBテーブルを確認

```bash
# イベント一覧を確認
aws dynamodb scan --table-name connpass-events
```

#### 3. CloudWatch Logsを確認

```bash
# Event Checkerのログ
aws logs tail /aws/lambda/connpass-notifier-EventCheckerFunction-XXXXX --follow

# Email Notifierのログ
aws logs tail /aws/lambda/connpass-notifier-EmailNotifierFunction-XXXXX --follow
```

### ローカルテスト

```bash
# テストを実行
cd connpass-notifier
pip install -r tests/requirements-test.txt

# 各テストファイルを個別に実行（モジュール名の競合を避けるため）
pytest tests/test_event_checker.py -v
pytest tests/test_email_notifier.py -v

# または、まとめて実行
pytest tests/test_event_checker.py && pytest tests/test_email_notifier.py
```

### ローカルでLambda関数を実行

```bash
# Event Checker関数をローカルで実行
sam local invoke EventCheckerFunction --env-vars env.json

# Email Notifier関数をローカルで実行
sam local invoke EmailNotifierFunction --env-vars env.json
```

`env.json` の例：
```json
{
  "EventCheckerFunction": {
    "EVENTS_TABLE_NAME": "connpass-events",
    "CONNPASS_USER_ID": "your-username"
  },
  "EmailNotifierFunction": {
    "EVENTS_TABLE_NAME": "connpass-events",
    "SENDER_EMAIL": "sender@example.com",
    "NOTIFICATION_EMAIL": "recipient@example.com",
    "NOTIFICATION_HOURS_BEFORE": "24"
  }
}
```

## カスタマイズ

### 通知タイミングの変更

`samconfig.toml` の `NotificationHoursBefore` パラメータを変更して再デプロイ：

```toml
"NotificationHoursBefore=\"48\""  # 48時間前に通知
```

### チェック頻度の変更

`template.yaml` の Schedule を変更：

```yaml
Events:
  ScheduledCheck:
    Type: Schedule
    Properties:
      Schedule: rate(3 hours)  # 3時間ごとにチェック
```

変更後、再デプロイが必要です：
```bash
sam build && sam deploy
```

## トラブルシューティング

### メールが届かない

1. **SESの検証状態を確認**
   ```bash
   aws ses get-identity-verification-attributes \
     --identities your-sender@example.com
   ```

2. **SESのSandboxモードを確認**
   - Sandboxモードの場合、受信先メールアドレスも検証が必要
   - 本番利用には Sandbox からの解除申請が必要

3. **CloudWatch Logsでエラーを確認**
   ```bash
   aws logs tail /aws/lambda/connpass-notifier-EmailNotifierFunction-XXXXX --follow
   ```

### connpassからイベントが取得できない

1. **connpassユーザーIDを確認**
   - ブラウザで `https://connpass.com/user/YOUR_USERNAME/` にアクセスできるか確認

2. **Lambda関数のログを確認**
   ```bash
   aws logs tail /aws/lambda/connpass-notifier-EventCheckerFunction-XXXXX --follow
   ```

3. **DynamoDBテーブルを確認**
   ```bash
   aws dynamodb scan --table-name connpass-events --max-items 5
   ```

### Lambda関数のタイムアウト

connpassのページが大きい場合、タイムアウトが発生する可能性があります。
`template.yaml` でタイムアウト値を増やしてください：

```yaml
Globals:
  Function:
    Timeout: 60  # 60秒に延長
```

## コスト

このアプリケーションは以下のAWSサービスを使用します：

- **Lambda**: 月間約720回実行（無料枠: 100万リクエスト/月）
- **DynamoDB**: On-Demand課金（無料枠あり）
- **SES**: メール送信（無料枠: 62,000通/月（EC2から送信時））
- **CloudWatch Logs**: ログ保存（無料枠: 5GB/月）
- **EventBridge**: スケジュール実行（無料）

通常の使用では、AWSの無料枠内で運用可能です。

## アンインストール

```bash
# CloudFormationスタックを削除
sam delete

# または
aws cloudformation delete-stack --stack-name connpass-notifier
```

注意: DynamoDBテーブルのデータは削除されます。

## セキュリティ

- Lambda関数は最小権限の原則に従ったIAMロールを使用
- SES送信は検証済みのメールアドレスのみ使用
- DynamoDB TTLにより、古いデータは自動削除
- 環境変数は暗号化して保存

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 参考資料

- [AWS SAM Documentation](https://docs.aws.amazon.com/serverless-application-model/)
- [Amazon SES Documentation](https://docs.aws.amazon.com/ses/)
- [connpass API](https://connpass.com/about/api/)
- [DynamoDB Time To Live](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/TTL.html)
