# TASK-0010: バックエンドヘルスチェック・基本APIエンドポイント実装 - TDD要件定義書

## 生成情報

- **生成日**: 2025-11-20
- **タスクID**: TASK-0010
- **タスク名**: バックエンドヘルスチェック・基本APIエンドポイント実装
- **タスクタイプ**: TDD
- **推定工数**: 8時間
- **関連要件**: NFR-504, NFR-502

## 1. 機能の概要（EARS要件定義書・設計文書ベース）

### 何をする機能か 🔵

- FastAPI main.pyを改善し、CORS設定と拡張されたヘルスチェックエンドポイントを実装する
- APIルーター構造（/api/v1/）を作成し、将来的なエンドポイント追加の基盤を構築する
- Pydanticスキーマ定義を作成し、API仕様の型安全性を確保する
- APIテストを実装し、90%以上のテストカバレッジを達成する
- Swagger UIでAPI仕様を確認可能にする

### どのような問題を解決するか 🔵

**現在の問題**:
- main.pyが最小限の実装（ルートエンドポイント、基本ヘルスチェックのみ）
- CORS設定がなく、Flutter Webアプリからのアクセスが制限される
- ヘルスチェックがデータベース接続を確認していない
- APIルーター構造がなく、将来的なエンドポイント追加が困難
- Pydanticスキーマが未定義で、型安全性が不足
- APIテストが存在せず、リグレッションリスクが高い

**解決策**:
- CORS middleware追加でFlutter Webアプリからの安全なアクセスを可能にする
- ヘルスチェックでデータベース接続を確認し、システム稼働状況を正確に把握する
- APIルーター構造で将来的なエンドポイント追加を容易にする
- Pydanticスキーマで型安全なAPI仕様を確保する
- APIテストでエンドポイントの動作を保証し、リグレッションを防ぐ

### 想定されるユーザー 🟡

- **Flutter開発者**: CORS設定されたAPIを呼び出し、AI変換機能等を実装
- **バックエンド開発者**: APIルーター構造を使用して新しいエンドポイントを追加
- **運用担当者**: ヘルスチェックエンドポイントでシステム稼働状況を監視
- **テスター**: Swagger UIでAPI仕様を確認し、手動テストを実施

### システム内での位置づけ 🔵

- **レイヤー**: APIエンドポイント層（FastAPIアプリケーション）
- **役割**: クライアント（Flutter）とバックエンドサービスの接点
- **依存関係**:
  - データベースセッション（app/db/session.py）
  - 設定管理（app/core/config.py）
  - SQLAlchemyモデル（TASK-0008で実装済み）

### 参照したEARS要件

- **NFR-504**: API仕様をOpenAPI (Swagger)形式で自動生成
- **NFR-502**: ビジネスロジック・APIエンドポイントで90%以上のテストカバレッジ
- **NFR-104**: HTTPS通信、API通信を暗号化
- **NFR-301**: 重大なエラーが発生しても基本機能を継続利用可能に保つ

### 参照した設計文書

- **アーキテクチャ**: architecture.md（line 49-67: バックエンド役割）
- **API仕様**: api-endpoints.md（line 280-322: ヘルスチェックエンドポイント）
- **技術スタック**: tech-stack.md（line 56-87: FastAPI設定）

---

## 2. 入力・出力の仕様（EARS機能要件・設計文書ベース）

### ルートエンドポイント（GET /） 🔵

**入力パラメータ**: なし

**出力値**:
```python
{
    "message": str,  # "kotonoha API is running"
    "version": str   # "1.0.0"
}
```

**データフロー**:
1. クライアントがGET /にアクセス
2. FastAPIがルートハンドラを実行
3. 固定メッセージとバージョンをJSONで返却

### ヘルスチェックエンドポイント（GET /health） 🔵

**入力パラメータ**: なし

**出力値（正常時）**:
```python
{
    "status": str,      # "ok"
    "database": str,    # "connected"
    "version": str,     # "1.0.0"
    "timestamp": str    # ISO 8601形式
}
```

**出力値（異常時）**:
```python
{
    "status": str,      # "error"
    "database": str,    # "disconnected"
    "error": str,       # エラーメッセージ
    "version": str,     # "1.0.0"
    "timestamp": str    # ISO 8601形式
}
```

**データフロー**:
1. クライアントがGET /healthにアクセス
2. FastAPIがヘルスチェックハンドラを実行
3. データベースセッションを依存性注入（Depends(get_db)）
4. SQLAlchemy経由でデータベース接続を確認（SELECT 1実行）
5. 接続成功/失敗に応じたJSONレスポンスを返却

### 参照したEARS要件

- **REQ-5003**: データ永続化機構を実装
- **NFR-304**: データベースエラー発生時に適切なエラーハンドリング

### 参照した設計文書

- **API仕様**: api-endpoints.md（line 280-322）
- **データベース設計**: database-schema.sql（TASK-0006で実装済み）

---

## 3. 制約条件（EARS非機能要件・アーキテクチャ設計ベース）

### パフォーマンス要件 🔵

- **NFR-002**: ヘルスチェックAPIは1秒以内に応答（軽量なSELECT 1クエリのみ）
- **NFR-003**: ルートエンドポイントは100ms以内に応答（データベースアクセスなし）

### セキュリティ要件 🔵

- **NFR-104**: HTTPS通信を使用（本番環境）
- **CORS設定**: Flutter Webアプリからのアクセスを許可
  - 開発環境: `http://localhost:3000`, `http://localhost:5173`
  - 本番環境: `https://kotonoha.example.com`
- **許可メソッド**: GET, POST, PUT, DELETE
- **許可ヘッダー**: すべて（*）

### アーキテクチャ制約 🔵

- **APIバージョニング**: 将来的に/api/v1/プレフィックスを使用
- **ルーター構造**: backend/app/api/v1/ディレクトリに整理
- **スキーマ定義**: backend/app/schemas/ディレクトリにPydanticモデルを配置
- **依存性注入**: FastAPIのDependsを使用してデータベースセッションを注入

### データベース制約 🔵

- **接続プール**: 最大10接続（NFR-005: 同時利用者数10人以下）
- **接続タイムアウト**: 10秒
- **ヘルスチェック**: pool_pre_ping=Trueで接続の有効性を確認

### API制約 🔵

- **NFR-504**: OpenAPI (Swagger)形式で自動生成
- **レスポンス形式**: JSON（Content-Type: application/json）
- **ステータスコード**:
  - 200 OK: 正常応答
  - 500 Internal Server Error: データベース接続失敗

### 参照したEARS要件

- **NFR-104**: HTTPS通信、API通信を暗号化
- **NFR-504**: API仕様をOpenAPI (Swagger)形式で自動生成
- **NFR-502**: ビジネスロジック・APIエンドポイントで90%以上のテストカバレッジ

### 参照した設計文書

- **アーキテクチャ**: architecture.md（line 131-140: 通信セキュリティ）
- **API仕様**: api-endpoints.md（line 401-426: セキュリティ）
- **技術スタック**: tech-stack.md（line 73-79: CORS設定）

---

## 4. 想定される使用例（EARSユースケース・データフローベース）

### 基本的な使用パターン 🔵

#### 使用例1: ルートエンドポイントへのアクセス

```python
# クライアント（Flutter/httpx）からのリクエスト
GET / HTTP/1.1
Host: localhost:8000
Accept: application/json

# レスポンス
HTTP/1.1 200 OK
Content-Type: application/json

{
    "message": "kotonoha API is running",
    "version": "1.0.0"
}
```

**データフロー**: architecture.md参照
1. クライアントがGET /にHTTPリクエスト
2. FastAPIがルートハンドラを実行
3. 固定メッセージをJSONで返却

#### 使用例2: ヘルスチェック（正常時）

```python
# クライアント（運用監視ツール）からのリクエスト
GET /health HTTP/1.1
Host: localhost:8000
Accept: application/json

# レスポンス
HTTP/1.1 200 OK
Content-Type: application/json

{
    "status": "ok",
    "database": "connected",
    "version": "1.0.0",
    "timestamp": "2025-11-20T12:34:56Z"
}
```

**データフロー**: api-endpoints.md（line 280-322）
1. クライアントがGET /healthにHTTPリクエスト
2. FastAPIがヘルスチェックハンドラを実行
3. データベースセッションを依存性注入
4. SELECT 1クエリでデータベース接続確認
5. 接続成功をJSONで返却

#### 使用例3: Swagger UIでのAPI仕様確認

```bash
# ブラウザでSwagger UIにアクセス
http://localhost:8000/docs

# 表示される情報:
# - GET / エンドポイント仕様
# - GET /health エンドポイント仕様
# - Pydanticスキーマ定義
# - 試験実行機能（Try it out）
```

**データフロー**: NFR-504要件
1. 開発者がブラウザで/docsにアクセス
2. FastAPIがOpenAPI仕様を自動生成
3. Swagger UIでインタラクティブなドキュメントを表示

### エッジケース 🟡

#### エッジケース1: データベース接続失敗時のヘルスチェック

```python
# リクエスト
GET /health HTTP/1.1

# レスポンス（データベース接続失敗）
HTTP/1.1 500 Internal Server Error
Content-Type: application/json

{
    "status": "error",
    "database": "disconnected",
    "error": "connection timeout",
    "version": "1.0.0",
    "timestamp": "2025-11-20T12:34:56Z"
}
```

**エラーハンドリング**: EDGE-001, NFR-304
- データベース接続エラーをキャッチ
- 500ステータスコードとエラーメッセージを返却
- アプリケーションはクラッシュせず継続動作

#### エッジケース2: CORS制約違反時のアクセス

```python
# 許可されていないオリジンからのリクエスト
GET / HTTP/1.1
Host: localhost:8000
Origin: http://malicious-site.com

# レスポンス
HTTP/1.1 403 Forbidden
Access-Control-Allow-Origin: (not set)
```

**セキュリティ**: NFR-104
- CORSミドルウェアが許可されていないオリジンを拒否
- 403 Forbiddenを返却

### エラーケース 🟡

#### エラーケース1: データベース接続タイムアウト

**シナリオ**: PostgreSQLが応答しない状態でヘルスチェック実行

**期待動作**:
- 10秒後にタイムアウト
- 500 Internal Server Errorを返却
- エラーメッセージ: "Database connection timeout"

**要件**: EDGE-001（ネットワークタイムアウト時の分かりやすいエラーメッセージ）

#### エラーケース2: データベース認証失敗

**シナリオ**: 環境変数の認証情報が誤っている

**期待動作**:
- データベース接続失敗
- 500 Internal Server Errorを返却
- エラーメッセージ: "Database authentication failed"

**要件**: NFR-304（データベースエラー発生時の適切なエラーハンドリング）

### 参照したEARS要件

- **EDGE-001**: ネットワークタイムアウト時、分かりやすいエラーメッセージ表示
- **NFR-301**: 重大なエラーが発生しても基本機能を継続利用可能に保つ
- **NFR-304**: データベースエラー発生時に適切なエラーハンドリング

### 参照した設計文書

- **データフロー**: dataflow.md（基本コミュニケーションフロー）
- **API仕様**: api-endpoints.md（line 280-322）

---

## 5. EARS要件・設計文書との対応関係

### 参照したユーザストーリー

- なし（インフラ機能のため、直接的なユーザストーリーなし）

### 参照した機能要件

- **REQ-5003**: データ永続化機構を実装（ヘルスチェックでデータベース接続確認）
- **NFR-301**: 重大なエラーが発生しても基本機能を継続利用可能に保つ

### 参照した非機能要件

- **NFR-104**: HTTPS通信、API通信を暗号化
- **NFR-304**: データベースエラー発生時に適切なエラーハンドリング
- **NFR-502**: ビジネスロジック・APIエンドポイントで90%以上のテストカバレッジ
- **NFR-504**: API仕様をOpenAPI (Swagger)形式で自動生成

### 参照したEdgeケース

- **EDGE-001**: ネットワークタイムアウト時、分かりやすいエラーメッセージ表示

### 参照した受け入れ基準

- ヘルスチェックAPIが実装されている
- Swagger UIでAPI仕様が確認できる
- APIテストが全て成功する（pytest実行）
- CORSが正しく設定されている（Flutter Webからアクセス可能）

### 参照した設計文書

#### アーキテクチャ

- **architecture.md（line 49-67）**: バックエンド役割
  - AI変換APIのプロキシ・ロジック処理
  - 将来的なクラウド連携機能の基盤
- **architecture.md（line 131-140）**: 通信セキュリティ
  - すべてのAPI通信をHTTPS/TLS 1.2+で暗号化

#### データフロー

- **dataflow.md**: 基本コミュニケーションフロー
  - クライアント → FastAPI → データベースの流れ

#### 型定義

- Pydanticスキーマ定義（本タスクで実装）:
  - HealthResponse: ヘルスチェックレスポンススキーマ
  - RootResponse: ルートエンドポイントレスポンススキーマ

#### データベース

- **database-schema.sql**: ai_conversion_history テーブル（TASK-0006で実装済み）
- **session.py**: データベースセッション管理（TASK-0008で実装済み）

#### API仕様

- **api-endpoints.md（line 280-322）**: ヘルスチェックエンドポイント
- **api-endpoints.md（line 401-426）**: セキュリティ（CORS設定）

---

## 信頼性レベル評価

### 各項目の信頼性レベル

- **機能の概要**: 🔵 青信号（EARS要件定義書、architecture.md、api-endpoints.mdに基づく）
- **入力・出力の仕様**: 🔵 青信号（api-endpoints.mdの仕様に基づく）
- **制約条件**: 🔵 青信号（NFR要件、tech-stack.mdに基づく）
- **想定される使用例**: 🔵 青信号（api-endpoints.md、dataflow.mdに基づく）
- **エッジケース**: 🟡 黄信号（EDGE要件から妥当な推測）

### 全体評価

✅ **高品質**: 要件の曖昧さなし、入出力定義完全、制約条件明確、実装可能性確実

---

## 次のステップ

次のお勧めステップ: `/tsumiki:tdd-testcases` でテストケースの洗い出しを行います。
