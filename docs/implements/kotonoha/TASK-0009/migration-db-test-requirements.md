# TDD要件定義書: 初回マイグレーション実行・DB接続テスト

**タスクID**: TASK-0009
**機能名**: 初回マイグレーション実行・DB接続テスト
**作成日**: 2025-11-20
**信頼性レベル**: 🔵 青信号（EARS要件定義書・設計文書・既存実装に基づく）

---

## 1. 機能の概要（EARS要件定義書・設計文書ベース）

### 🔵 何をする機能か
TASK-0008で実装したSQLAlchemyモデル（AIConversionHistory）に基づいて、Alembicを使用して初回データベースマイグレーションを実行し、PostgreSQLにテーブルを作成する。さらに、データベース接続が正常に動作することを確認するテストを実装・実行する。

### 🔵 どのような問題を解決するか
- データベーススキーマをコードから自動生成し、手動SQL実行の手間を削減
- マイグレーション履歴を管理し、将来的なスキーマ変更を追跡可能にする
- データベース接続の正常性を自動テストで検証し、環境構築の信頼性を向上
- マイグレーションのロールバック機能により、スキーマ変更の安全性を確保

### 🔵 想定されるユーザー
- **開発者**: 開発環境でのデータベースセットアップ、マイグレーション実行
- **CI/CDパイプライン**: 自動テストでのデータベース接続確認
- **運用担当者**: 本番環境でのデータベースマイグレーション適用

### 🔵 システム内での位置づけ
- **Phase 1 Week 2**: データベース設計・マイグレーションフェーズの最終タスク
- **依存タスク**: TASK-0008（SQLAlchemyモデル実装）が完了済み
- **次タスク**: TASK-0010（バックエンドヘルスチェック・基本APIエンドポイント実装）に接続

### 参照したEARS要件
- **NFR-304**: データベースエラー発生時に適切なエラーハンドリング
- **NFR-502**: ビジネスロジック・APIエンドポイントで90%以上のテストカバレッジ
- **REQ-5003**: アプリが強制終了しても定型文・設定・履歴を失わない永続化機構を実装

### 参照した設計文書
- **タスクファイル**: `docs/tasks/kotonoha-phase1.md` TASK-0009セクション（line 781-878）
- **データベーススキーマ**: `docs/design/kotonoha/database-schema.sql`（line 36-68 ai_conversion_history）
- **アーキテクチャ**: `docs/design/kotonoha/architecture.md` データベースレイヤー

---

## 2. 入力・出力の仕様（EARS機能要件・TypeScript型定義ベース）

### 🔵 マイグレーション生成（入力）
**コマンド**: `alembic revision --autogenerate -m "Create ai_conversion_history table"`

**入力要素**:
- **モデル定義**: `backend/app/models/ai_conversion_history.py` のAIConversionHistoryクラス
- **メタデータ**: `backend/app/db/base.py` のBase.metadata
- **マイグレーションメッセージ**: 文字列（例: "Create ai_conversion_history table"）

**期待される出力**:
- **マイグレーションファイル**: `backend/alembic/versions/{revision_id}_create_ai_conversion_history_table.py`
- **マイグレーション内容**:
  - `upgrade()`: テーブル作成SQL（CREATE TABLE ai_conversion_history）
  - `downgrade()`: テーブル削除SQL（DROP TABLE ai_conversion_history）

### 🔵 マイグレーション実行（入力）
**コマンド**: `alembic upgrade head`

**入力要素**:
- **マイグレーションファイル**: 上記で生成されたファイル
- **データベース接続情報**: 環境変数（POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_HOST, POSTGRES_PORT, POSTGRES_DB）

**期待される出力**:
- **PostgreSQLテーブル**: `ai_conversion_history`テーブルが作成される
- **Alembicバージョンテーブル**: `alembic_version`テーブルに現在のリビジョンが記録される
- **標準出力**: マイグレーション成功メッセージ

### 🔵 マイグレーションロールバック（入力）
**コマンド**: `alembic downgrade -1`

**入力要素**:
- **現在のリビジョン**: alembic_versionテーブルから取得

**期待される出力**:
- **PostgreSQLテーブル**: `ai_conversion_history`テーブルが削除される
- **Alembicバージョンテーブル**: リビジョンが1つ前に戻る

### 🔵 データベース接続テスト（入出力）

#### テスト1: 基本的なデータベース接続
**入力**: なし（セッション取得のみ）
**出力**: `SELECT 1` クエリの結果が `1` であること

#### テスト2: テーブル存在確認
**入力**: テーブル名 `"ai_conversion_history"`
**出力**: `information_schema.tables` からテーブルが検出されること（TRUE）

#### テスト3: CRUDテスト（レコード作成）
**入力**:
```python
AIConversionHistory(
    input_text="ありがとう",
    converted_text="ありがとうございます",
    politeness_level=PolitenessLevel.POLITE,
    conversion_time_ms=100,
    user_session_id=uuid4()
)
```

**出力**:
- `id`: 自動生成される整数（NOT NULL）
- `created_at`: 自動生成されるタイムスタンプ
- すべてのフィールドが正しく保存されること

### 参照したEARS要件
- **NFR-304**: データベースエラー発生時に適切なエラーハンドリング
- **NFR-502**: テストカバレッジ90%以上

### 参照した設計文書
- **データベーススキーマ**: `database-schema.sql`（line 36-68）
- **モデル実装**: `backend/app/models/ai_conversion_history.py`
- **セッション管理**: `backend/app/db/session.py`

---

## 3. 制約条件（EARS非機能要件・アーキテクチャ設計ベース）

### 🔵 データベース制約
- **NOT NULL制約**: `input_text`, `converted_text`, `politeness_level`, `created_at`
- **CHECK制約**: `politeness_level IN ('casual', 'normal', 'polite')`
- **PRIMARY KEY**: `id` (自動インクリメント)
- **インデックス**:
  - `created_at DESC` (時系列検索用)
  - `user_session_id` (セッション絞り込み用)

### 🔵 パフォーマンス要件
- **マイグレーション実行時間**: 初回マイグレーションは10秒以内に完了すること（単一テーブル作成）
- **テスト実行時間**: 全テストケースが5秒以内に完了すること
- **NFR-005**: 同時利用者数10人以下を想定した軽負荷環境で安定動作

### 🔵 セキュリティ要件
- **NFR-104**: HTTPS通信、API通信を暗号化
- **NFR-105**: 環境変数をアプリ内にハードコードせず、安全に管理
- **データベース接続情報**: 環境変数から読み込み（.envファイル、gitignore必須）

### 🔵 互換性要件
- **PostgreSQL 15以上**: database-schema.sqlで指定
- **SQLAlchemy 2.0.36**: 非同期対応
- **Alembic 1.17.1**: マイグレーション管理

### 🔵 テストカバレッジ要件
- **NFR-502**: ビジネスロジック・APIエンドポイントで90%以上のテストカバレッジ
- **カバレッジ対象**:
  - データベース接続確認
  - テーブル存在確認
  - CRUD操作（作成、読み取り）
  - エラーハンドリング

### 参照したEARS要件
- **NFR-304**: データベースエラー発生時に適切なエラーハンドリング
- **NFR-502**: テストカバレッジ90%以上
- **NFR-005**: 同時利用者数10人以下の要件
- **NFR-104, NFR-105**: セキュリティ要件

### 参照した設計文書
- **データベーススキーマ**: `database-schema.sql`（line 36-68）
- **技術スタック**: `docs/tech-stack.md`（SQLAlchemy 2.x, PostgreSQL 15+）

---

## 4. 想定される使用例（EARSEdgeケース・データフローベース）

### 🔵 基本的な使用パターン（通常要件）

#### パターン1: 初回マイグレーション実行
```bash
# 1. マイグレーション生成
cd backend
alembic revision --autogenerate -m "Create ai_conversion_history table"

# 2. 生成されたマイグレーションファイルを確認・修正

# 3. マイグレーション実行
alembic upgrade head

# 4. PostgreSQLで確認
docker exec -it kotonoha_postgres psql -U kotonoha_user -d kotonoha_db
\dt  # テーブル一覧表示
\d ai_conversion_history  # テーブル構造確認
```

**期待される結果**:
- `ai_conversion_history`テーブルが作成される
- `alembic_version`テーブルにリビジョンが記録される

#### パターン2: データベース接続テスト実行
```bash
cd backend
pytest tests/test_db_connection.py -v
```

**期待される結果**:
- `test_database_connection`: PASSED
- `test_ai_conversion_history_table_exists`: PASSED

#### パターン3: CRUDテスト実行
```bash
cd backend
pytest tests/test_models.py -v
```

**期待される結果**:
- `test_create_ai_conversion_history`: PASSED
- レコードが正常に作成され、`id`と`created_at`が自動生成される

### 🔵 データフロー

```
[開発者]
  ↓ (1) alembic revision --autogenerate
[Alembicマイグレーション生成]
  ↓ (2) upgrade()関数生成
[マイグレーションファイル]
  ↓ (3) alembic upgrade head
[PostgreSQLデータベース]
  ↓ (4) CREATE TABLE実行
[ai_conversion_historyテーブル作成]
  ↓ (5) pytest実行
[データベース接続テスト]
  ↓ (6) SELECT 1実行
[接続成功確認]
```

### 🟡 エッジケース（EDGE-XXX）

#### EDGE-001: マイグレーション生成時にモデル変更がない場合
**状況**: TASK-0008のモデル定義から変更がない状態で`alembic revision --autogenerate`を実行

**期待される動作**:
- Alembicが「変更なし」と判断
- 空のマイグレーションファイルが生成される
- 開発者に警告メッセージが表示される

**対処法**:
- マイグレーションファイルを削除
- モデル定義を確認

#### EDGE-002: データベース接続失敗時
**状況**: PostgreSQLコンテナが起動していない、または接続情報が誤っている

**期待される動作**:
- `alembic upgrade head`が接続エラーで失敗
- エラーメッセージに接続情報（ホスト、ポート、データベース名）が表示される
- テストケースが`asyncpg.exceptions.CannotConnectNowError`をキャッチ

**対処法**:
- `docker-compose up -d postgres`でPostgreSQL起動確認
- `.env`ファイルの接続情報を確認
- `docker logs kotonoha_postgres`でPostgreSQLログを確認

#### EDGE-003: テーブルがすでに存在する場合
**状況**: 手動でテーブルを作成済みの状態で`alembic upgrade head`を実行

**期待される動作**:
- Alembicが「テーブルが既に存在する」というエラーを返す
- マイグレーションが中断される

**対処法**:
- `alembic downgrade -1`でロールバック
- または手動でテーブルを削除してから再実行

### 🔵 エラーケース（EDGE-XXXエラー処理）

#### ERROR-001: NOT NULL制約違反
**状況**: `input_text`や`converted_text`にNULLを設定してレコード挿入

**期待される動作**:
- `asyncpg.exceptions.NotNullViolationError`が発生
- テストケースで適切にキャッチされる

**テスト例**:
```python
async def test_not_null_constraint():
    async with async_session_maker() as session:
        record = AIConversionHistory(
            input_text=None,  # NOT NULL制約違反
            converted_text="test",
            politeness_level=PolitenessLevel.NORMAL
        )
        session.add(record)
        with pytest.raises(IntegrityError):
            await session.commit()
```

#### ERROR-002: CHECK制約違反（不正なEnum値）
**状況**: データベースに直接不正な`politeness_level`値を挿入

**期待される動作**:
- `asyncpg.exceptions.CheckViolationError`が発生
- SQLAlchemy ORM経由では型チェックで事前に防止

**対処法**:
- アプリケーションレベルでPolitenessLevel Enumを使用
- バリデーション処理を実装

#### ERROR-003: マイグレーション適用済みの状態で再実行
**状況**: `alembic upgrade head`を複数回実行

**期待される動作**:
- Alembicが「すでに最新のリビジョン」と判断
- エラーなく終了（冪等性）

### 参照したEARS要件
- **NFR-304**: データベースエラー発生時に適切なエラーハンドリング
- **EDGE-001**: ネットワークタイムアウト時のエラーメッセージ表示と再試行オプション

### 参照した設計文書
- **タスクファイル**: `docs/tasks/kotonoha-phase1.md` TASK-0009（line 799-878）
- **データベーススキーマ**: `database-schema.sql`（line 36-68）

---

## 5. EARS要件・設計文書との対応関係

### 参照したユーザストーリー
- **開発者向けストーリー**: データベースマイグレーションの自動化により、環境構築を効率化

### 参照した機能要件
- **REQ-5003**: システムはアプリが強制終了しても定型文・設定・履歴を失わない永続化機構を実装しなければならない
  - → PostgreSQLによる永続化の基盤となるテーブル作成

### 参照した非機能要件
- **NFR-304**: データベースエラー発生時に適切なエラーハンドリング
  - → 接続エラー、制約違反などのエラーハンドリングテストを実装
- **NFR-502**: ビジネスロジック・APIエンドポイントで90%以上のテストカバレッジ
  - → データベース接続、テーブル存在確認、CRUD操作のテストを実装
- **NFR-005**: 同時利用者数10人以下を想定した軽負荷環境で安定動作
  - → 接続プール（サイズ10）の設定を確認
- **NFR-104**: HTTPS通信、API通信を暗号化
- **NFR-105**: 環境変数をアプリ内にハードコードせず、安全に管理

### 参照したEdgeケース
- **EDGE-001**: ネットワークタイムアウト時、システムはユーザーに分かりやすいエラーメッセージを表示し、再試行オプションを提供
  - → データベース接続エラー時のエラーハンドリング

### 参照した受け入れ基準
- マイグレーションが正常に実行される
- データベースにテーブルが作成されている
- ロールバック・再適用が正常に動作する
- データベース接続テストが全て成功する
- CRUDテストが全て成功する

### 参照した設計文書

#### アーキテクチャ
- **ファイル**: `docs/design/kotonoha/architecture.md`
- **該当セクション**: データベースレイヤー、SQLAlchemy ORM、Alembicマイグレーション

#### データフロー
- **ファイル**: `docs/design/kotonoha/dataflow.md`
- **該当フロー**: バックエンド内部データフロー（モデル → データベース）

#### 型定義
- **ファイル**: `backend/app/models/ai_conversion_history.py`
- **該当インターフェース**:
  - `AIConversionHistory` クラス
  - `PolitenessLevel` Enum

#### データベース
- **ファイル**: `docs/design/kotonoha/database-schema.sql`
- **該当テーブル**: `ai_conversion_history`（line 36-68）
- **該当インデックス**: `idx_ai_conversion_created_at`, `idx_ai_conversion_session`

#### API仕様
- **該当なし**: TASK-0009はデータベースマイグレーションのみで、API実装はTASK-0010以降

---

## 6. 実装ファイル構成

### 🔵 新規作成ファイル
```
backend/
├── alembic/
│   └── versions/
│       └── {revision_id}_create_ai_conversion_history_table.py  # マイグレーションファイル
├── tests/
│   ├── test_db_connection.py  # データベース接続テスト
│   └── test_models.py          # モデルCRUDテスト
```

### 🔵 更新ファイル
```
backend/
├── alembic/
│   └── env.py  # target_metadataをNoneからBase.metadataに更新
```

---

## 7. テストケース一覧（TDD Red/Green/Refactorサイクル用）

### カテゴリA: データベース接続テスト
- **A-1**: 基本的なデータベース接続（`SELECT 1`）
- **A-2**: テーブル存在確認（`information_schema.tables`）

### カテゴリB: CRUD操作テスト
- **B-1**: レコード作成（全フィールド指定）
- **B-2**: レコード作成後のID自動生成確認
- **B-3**: レコード作成後のcreated_at自動生成確認

### カテゴリC: 制約テスト
- **C-1**: NOT NULL制約違反（input_text = NULL）
- **C-2**: NOT NULL制約違反（converted_text = NULL）
- **C-3**: NOT NULL制約違反（politeness_level = NULL）

### カテゴリD: マイグレーション操作テスト
- **D-1**: マイグレーション実行（upgrade head）
- **D-2**: マイグレーションロールバック（downgrade -1）
- **D-3**: マイグレーション再適用（upgrade head再実行）

---

## 8. 品質判定

### ✅ 高品質
- **要件の曖昧さ**: なし（TASK-0008の実装を基に明確）
- **入出力定義**: 完全（マイグレーションコマンド、テストケース、データベーステーブル構造が明確）
- **制約条件**: 明確（データベース制約、パフォーマンス要件、セキュリティ要件が定義済み）
- **実装可能性**: 確実（既存の実装（モデル、セッション管理）を基に実行可能）

---

## 9. 次のステップ

✅ 要件定義完了

**次のお勧めステップ**: `/tsumiki:tdd-testcases` でテストケースの洗い出しを行います。

---

## 変更履歴

- **2025-11-20**: 初版作成（TDD要件定義フェーズ完了）
