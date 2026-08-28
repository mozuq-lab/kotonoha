# TDD要件定義: TASK-0008 - SQLAlchemyモデル実装

## 生成情報
- **生成日時**: 2025-11-20
- **タスクID**: TASK-0008
- **タスク名**: SQLAlchemyモデル実装
- **タスクタイプ**: TDD
- **推定工数**: 8時間
- **関連フェーズ**: Phase 1 - Week 2 (データベース設計・マイグレーション)

## 1. 機能の概要

### 機能説明 🔵
**何をする機能か**:
SQLAlchemyを使用したORM（Object-Relational Mapping）モデルを実装し、データベーステーブルとPythonオブジェクト間のマッピングを実現する。

**どのような問題を解決するか**:
- データベースアクセスを抽象化し、SQLを直接書くことなく型安全なデータ操作を可能にする
- Alembicによる自動マイグレーション生成の基盤を提供する
- データベースエラーの適切なハンドリング機構を実装する

**想定されるユーザー**:
- バックエンド開発者（FastAPIアプリケーションからデータベースにアクセスする際に使用）
- 将来的なAI変換機能の実装者（変換履歴の保存・取得に使用）

**システム内での位置づけ**:
- データアクセス層（Data Access Layer）の中核コンポーネント
- FastAPI ↔ SQLAlchemy ↔ PostgreSQL の中間層
- バックエンドアーキテクチャのModel層に相当

### 参照した要件定義・設計文書 🔵
- **参照したEARS要件**:
  - REQ-901: AI変換機能（AI変換履歴の保存が必要）
  - NFR-304: データベースエラー発生時に適切なエラーハンドリング
  - NFR-502: ビジネスロジック・APIエンドポイントで90%以上のテストカバレッジ
- **参照した設計文書**:
  - `docs/design/kotonoha/database-schema.sql` (AI変換履歴テーブル定義)
  - `docs/design/kotonoha/architecture.md` (データアクセス層の設計)
  - `docs/tech-stack.md` (SQLAlchemy 2.x, Alembic 1.17+の技術選定理由)

## 2. 入力・出力の仕様

### 入力パラメータ 🔵

#### 2.1 ベースモデル作成 (`backend/app/db/base_class.py`)
- **入力**: なし（宣言的基底クラス定義）
- **型**: Pythonクラス定義
- **制約**:
  - SQLAlchemy 2.x の `as_declarative()` デコレータを使用
  - すべてのモデルクラスの基底クラスとなる

#### 2.2 AI変換履歴モデル (`backend/app/models/ai_conversion_history.py`)
- **入力フィールド**:
  - `id`: Integer (主キー、自動生成)
  - `input_text`: Text (変換元テキスト、NOT NULL)
  - `converted_text`: Text (変換後テキスト、NOT NULL)
  - `politeness_level`: Enum('casual', 'normal', 'polite') (NOT NULL)
  - `created_at`: DateTime with timezone (デフォルト: CURRENT_TIMESTAMP)
  - `conversion_time_ms`: Integer (変換処理時間、NULL許可)
  - `user_session_id`: UUID (セッションID、NULL許可)
- **型**: SQLAlchemyモデルクラス
- **制約**:
  - `politeness_level` は 'casual', 'normal', 'polite' のいずれか
  - テーブル名: `ai_conversion_history`
  - インデックス: `created_at DESC`, `user_session_id`

#### 2.3 データベースセッション管理 (`backend/app/db/session.py`)
- **入力**: 環境変数（DATABASE_URL）
- **型**: 非同期セッションファクトリ
- **制約**:
  - `postgresql+asyncpg://` プロトコルを使用
  - 環境変数から接続情報を読み込む
  - 接続プーリングを適切に設定

### 出力値 🔵

#### 2.1 ベースモデル
- **出力**: `Base` クラス（すべてのモデルの基底）
- **型**: SQLAlchemy DeclarativeBase
- **形式**: Pythonクラス

#### 2.2 AI変換履歴モデル
- **出力**: `AIConversionHistory` モデルクラス
- **型**: SQLAlchemyモデル（Baseを継承）
- **形式**: ORMマッピング済みクラス
- **例**:
```python
record = AIConversionHistory(
    input_text="ありがとう",
    converted_text="ありがとうございます",
    politeness_level=PolitenessLevel.POLITE,
    conversion_time_ms=100,
    user_session_id=uuid4()
)
```

#### 2.3 データベースセッション
- **出力**: 非同期セッションジェネレータ (`AsyncSession`)
- **型**: `async_session_maker` (sessionmaker)
- **形式**: FastAPI Depends で使用可能な依存性注入用関数

### データフロー 🔵
```
環境変数 (.env)
  ↓
app.core.config.Settings
  ↓
app.db.session (DATABASE_URL構築)
  ↓
SQLAlchemy AsyncEngine
  ↓
sessionmaker (AsyncSession)
  ↓
FastAPI Depends(get_db)
  ↓
APIエンドポイント
  ↓
AIConversionHistory.create() / .query()
  ↓
PostgreSQL (ai_conversion_history テーブル)
```

### 参照した設計文書 🔵
- **データベーススキーマ**: `docs/design/kotonoha/database-schema.sql` (line 36-68: ai_conversion_logs テーブル定義)
  - 注: 設計書では `ai_conversion_logs` だが、実装では `ai_conversion_history` に統一
- **アーキテクチャ**: `docs/design/kotonoha/architecture.md` (line 49-68: バックエンド構成)

## 3. 制約条件

### パフォーマンス要件 🔵
- **NFR-002**: AI変換の応答時間を平均3秒以内
  - データベース書き込みは非同期で実行し、API応答をブロックしない
  - インデックス (`created_at`, `user_session_id`) により検索速度を確保
- **NFR-005**: 同時利用者数10人以下の軽負荷環境で安定動作
  - 接続プーリングを適切に設定（最大接続数: 10-20程度）

### セキュリティ要件 🔵
- **NFR-104**: HTTPS通信、API通信を暗号化
  - データベース接続は SSL/TLS を使用（本番環境）
- **NFR-105**: 環境変数をアプリ内にハードコードせず、安全に管理
  - データベースパスワードは `.env` から読み込み
  - 本番環境では AWS Secrets Manager 等を使用

### データベース制約 🔵
- **外部キー制約**: 現時点ではなし（将来的なユーザーテーブル追加時に検討）
- **NOT NULL制約**: `input_text`, `converted_text`, `politeness_level` は必須
- **CHECK制約**: `politeness_level` は Enum で制約
- **インデックス**:
  - `idx_ai_conversion_created_at ON ai_conversion_history(created_at DESC)`
  - `idx_ai_conversion_session ON ai_conversion_history(user_session_id)`

### アーキテクチャ制約 🔵
- **SQLAlchemy 2.x**: 非同期対応必須（`asyncpg` ドライバ使用）
- **Alembic 1.17+**: マイグレーション管理必須
- **Python 3.10+**: 型ヒント必須、Pydantic統合

### 参照した設計文書 🔵
- **アーキテクチャ**: `docs/design/kotonoha/architecture.md` (line 144-152: パフォーマンス要件)
- **データベーススキーマ**: `docs/design/kotonoha/database-schema.sql` (line 70-76: インデックス定義)
- **技術スタック**: `docs/tech-stack.md` (line 56-87: バックエンド技術選定)

## 4. 想定される使用例

### 基本的な使用パターン 🔵

#### 4.1 モデルインスタンスの作成
```python
from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel
from uuid import uuid4

record = AIConversionHistory(
    input_text="水 ぬるく",
    converted_text="お水をぬるめでお願いします",
    politeness_level=PolitenessLevel.NORMAL,
    conversion_time_ms=2500,
    user_session_id=uuid4()
)
```

#### 4.2 データベースへの保存（非同期）
```python
from app.db.session import async_session_maker

async with async_session_maker() as session:
    session.add(record)
    await session.commit()
    await session.refresh(record)  # IDなど自動生成値を取得
```

#### 4.3 データベースからの取得
```python
from sqlalchemy import select

async with async_session_maker() as session:
    result = await session.execute(
        select(AIConversionHistory)
        .where(AIConversionHistory.user_session_id == session_id)
        .order_by(AIConversionHistory.created_at.desc())
        .limit(10)
    )
    records = result.scalars().all()
```

#### 4.4 FastAPIエンドポイントでの使用
```python
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db

@app.post("/api/v1/ai/convert")
async def convert_text(
    request: AIConversionRequest,
    db: AsyncSession = Depends(get_db)
):
    # AI変換処理
    converted = await ai_conversion_service.convert(request.input_text)

    # 履歴保存
    history = AIConversionHistory(
        input_text=request.input_text,
        converted_text=converted,
        politeness_level=request.politeness_level,
        conversion_time_ms=processing_time
    )
    db.add(history)
    await db.commit()

    return {"converted_text": converted}
```

### エッジケース 🔵

#### 4.5 データベース接続エラー時のハンドリング (EDGE-002相当)
```python
from sqlalchemy.exc import DBAPIError, OperationalError

async with async_session_maker() as session:
    try:
        session.add(record)
        await session.commit()
    except OperationalError as e:
        # 接続エラー: ログ記録、ユーザーにエラー通知
        logger.error(f"Database connection error: {e}")
        await session.rollback()
        raise HTTPException(status_code=503, detail="データベースに接続できません")
    except DBAPIError as e:
        # その他DBエラー
        logger.error(f"Database error: {e}")
        await session.rollback()
        raise HTTPException(status_code=500, detail="データベースエラーが発生しました")
```

#### 4.6 トランザクション管理
```python
async with async_session_maker() as session:
    async with session.begin():
        # 複数操作をトランザクション内で実行
        session.add(record1)
        session.add(record2)
        # commit は begin() のコンテキスト終了時に自動実行
        # エラー時は自動ロールバック
```

#### 4.7 NULL値の扱い（オプションフィールド）
```python
# conversion_time_ms, user_session_id は NULL 許可
record = AIConversionHistory(
    input_text="こんにちは",
    converted_text="こんにちは",
    politeness_level=PolitenessLevel.CASUAL,
    # conversion_time_ms は省略可能
    # user_session_id は省略可能
)
```

### エラーケース 🟡

#### 4.8 バリデーションエラー（Enum制約違反）
```python
# 存在しない politeness_level を指定
try:
    record = AIConversionHistory(
        input_text="test",
        converted_text="test",
        politeness_level="super_polite"  # エラー: Enum値ではない
    )
except ValueError as e:
    # Pythonレベルでバリデーションエラー
    logger.error(f"Invalid politeness level: {e}")
```

#### 4.9 データベース制約違反（NOT NULL制約）
```python
try:
    record = AIConversionHistory(
        input_text=None,  # NOT NULL制約違反
        converted_text="test",
        politeness_level=PolitenessLevel.NORMAL
    )
    async with async_session_maker() as session:
        session.add(record)
        await session.commit()
except IntegrityError as e:
    # データベース側で制約違反エラー
    logger.error(f"Database integrity error: {e}")
    await session.rollback()
```

### 参照した設計文書 🔵
- **EARS要件**: `docs/spec/kotonoha-requirements.md`
  - EDGE-002 (line 179): AI変換APIエラー時のフォールバック処理
  - NFR-304 (line 159): データベースエラー時の適切なエラーハンドリング
- **データフロー**: `docs/design/kotonoha/dataflow.md` (AI変換フロー)

## 5. EARS要件・設計文書との対応関係

### 参照したユーザストーリー 🔵
- **なし**: このタスクは技術基盤実装のため、直接的なユーザストーリーはない
- **間接的関連**: AI変換機能（REQ-901）の基盤として、将来的にユーザーストーリーをサポート

### 参照した機能要件 🔵
- **REQ-901**: システムは短い入力をより丁寧で自然な文章に変換する候補を生成しなければならない
  - AI変換履歴の保存により、将来的な学習データ収集・統計分析が可能
- **REQ-902**: システムはAI変換結果を自動的に表示し、ユーザーが採用・却下を選択できなければならない
  - 変換履歴により、採用率・却下率の分析が可能（将来拡張）

### 参照した非機能要件 🔵
- **NFR-002**: システムはAI変換の応答時間を平均3秒以内とすることを目標としなければならない
  - 非同期データベース書き込みによりAPI応答をブロックしない
  - `conversion_time_ms` フィールドでパフォーマンス監視が可能
- **NFR-304**: システムはデータベースエラー発生時に適切なエラーハンドリングを行い、データ損失を防がなければならない
  - トランザクション管理、ロールバック処理を実装
  - 例外ハンドリングにより適切なエラーメッセージを返却
- **NFR-501**: システムはコードカバレッジ80%以上のテストを維持しなければならない
  - モデルのCRUD操作、バリデーション、エラーハンドリングをテスト
- **NFR-502**: システムは重要なビジネスロジック・APIエンドポイントで90%以上のテストカバレッジを維持しなければならない
  - データアクセス層として重要度が高いため、高カバレッジを目指す

### 参照したEdgeケース 🔵
- **EDGE-002**: AI変換APIエラー時、システムは元の入力文をそのまま使用可能にするフォールバック処理を実行しなければならない
  - データベース書き込みエラー時も同様のフォールバック処理を実装
- **NFR-304関連**: データベースエラー時の適切なハンドリング
  - 接続エラー、制約違反エラー、トランザクションエラーなどを適切に処理

### 参照した設計文書 🔵
- **アーキテクチャ**: `docs/design/kotonoha/architecture.md`
  - line 49-68: バックエンド（FastAPI）構成
  - line 69-79: データベース（PostgreSQL）選択理由
  - line 144-152: パフォーマンス要件への対応
- **データベーススキーマ**: `docs/design/kotonoha/database-schema.sql`
  - line 36-68: `ai_conversion_logs` テーブル定義（実装では `ai_conversion_history` に名称変更）
  - line 70-76: インデックス定義
- **技術スタック**: `docs/tech-stack.md`
  - line 56-87: FastAPI、SQLAlchemy、Alembic の技術選定理由
  - line 89-114: PostgreSQL 15+ の選定理由
- **型定義（参考）**: `docs/design/kotonoha/interfaces.dart`
  - line 321-330: `PolitenessLevel` Enum定義（DartとPythonで対応）

## 6. 受け入れ基準（テスト要件）

### 単体テスト要件 🔵

#### 6.1 モデルインスタンス化テスト
- **テストケース**: `AIConversionHistory` モデルのインスタンス化が正常に行える
- **期待結果**: すべてのフィールドが正しく設定される
- **実装**: `backend/tests/test_models.py::test_ai_conversion_history_instantiation`

#### 6.2 モデルバリデーションテスト
- **テストケース**: `politeness_level` に不正な値を設定した場合、エラーが発生する
- **期待結果**: `ValueError` または `IntegrityError` が発生
- **実装**: `backend/tests/test_models.py::test_politeness_level_validation`

#### 6.3 データベース接続テスト
- **テストケース**: 非同期セッションが正常に作成・接続できる
- **期待結果**: `SELECT 1` クエリが成功する
- **実装**: `backend/tests/test_db_connection.py::test_database_connection`

#### 6.4 CRUD操作テスト（作成）
- **テストケース**: `AIConversionHistory` レコードをデータベースに保存できる
- **期待結果**: `id` が自動生成され、`created_at` が設定される
- **実装**: `backend/tests/test_models.py::test_create_ai_conversion_history`

#### 6.5 CRUD操作テスト（読み取り）
- **テストケース**: 保存したレコードをクエリで取得できる
- **期待結果**: 保存したデータと一致するレコードが取得できる
- **実装**: `backend/tests/test_models.py::test_read_ai_conversion_history`

#### 6.6 トランザクション管理テスト
- **テストケース**: エラー発生時にロールバックされる
- **期待結果**: コミット前にエラーが発生した場合、データは保存されない
- **実装**: `backend/tests/test_models.py::test_transaction_rollback`

#### 6.7 NULL値許可フィールドのテスト
- **テストケース**: `conversion_time_ms`, `user_session_id` を省略してもレコードが作成できる
- **期待結果**: NULL値として保存される
- **実装**: `backend/tests/test_models.py::test_nullable_fields`

#### 6.8 Enum値のテスト
- **テストケース**: `PolitenessLevel` の3つの値（casual, normal, polite）がすべて使用できる
- **期待結果**: 各Enum値でレコードが正常に作成できる
- **実装**: `backend/tests/test_models.py::test_politeness_level_enum_values`

### 統合テスト要件 🔵

#### 6.9 Alembic自動マイグレーション生成テスト
- **テストケース**: モデル定義から Alembic がマイグレーションファイルを生成できる
- **期待結果**: `alembic revision --autogenerate` が正常に実行される
- **実装**: 手動確認（TASK-0009で検証）

#### 6.10 テーブル作成テスト
- **テストケース**: `alembic upgrade head` でテーブルが作成される
- **期待結果**: PostgreSQLに `ai_conversion_history` テーブルが存在する
- **実装**: 手動確認（TASK-0009で検証）

### エラーハンドリングテスト要件 🔵

#### 6.11 データベース接続エラーテスト
- **テストケース**: データベースが利用不可の場合、適切な例外が発生する
- **期待結果**: `OperationalError` が発生し、ログに記録される
- **実装**: `backend/tests/test_error_handling.py::test_database_connection_error`

#### 6.12 制約違反エラーテスト
- **テストケース**: NOT NULL制約違反時、`IntegrityError` が発生する
- **期待結果**: エラーメッセージに制約違反の詳細が含まれる
- **実装**: `backend/tests/test_error_handling.py::test_integrity_error`

### カバレッジ目標 🔵
- **全体カバレッジ**: 80%以上（NFR-501）
- **モデル層カバレッジ**: 90%以上（NFR-502）
  - `backend/app/models/` 配下のすべてのファイル
  - `backend/app/db/` 配下のすべてのファイル

## 7. 実装ファイル一覧

### 実装対象ファイル 🔵
1. `backend/app/db/base_class.py` - ベースモデルクラス定義
2. `backend/app/models/ai_conversion_history.py` - AI変換履歴モデル
3. `backend/app/db/base.py` - モデル集約ファイル（Alembic用）
4. `backend/app/db/session.py` - データベースセッション管理
5. `backend/alembic/env.py` - Alembic環境設定更新（target_metadata設定）

### テストファイル一覧 🔵
1. `backend/tests/test_models.py` - モデル単体テスト
2. `backend/tests/test_db_connection.py` - データベース接続テスト
3. `backend/tests/test_error_handling.py` - エラーハンドリングテスト
4. `backend/tests/conftest.py` - pytest設定（テスト用DB設定）

## 8. 依存関係・前提条件

### 依存タスク 🔵
- **TASK-0007 (完了済み)**: Alembic初期設定・マイグレーション環境構築
  - `alembic/` ディレクトリが存在
  - `alembic.ini` が設定済み
  - `backend/app/core/config.py` が実装済み（環境変数読み込み）

### 技術的前提条件 🔵
- **Python 3.10+**: 型ヒント、Enum機能
- **SQLAlchemy 2.x**: 非同期対応、宣言的モデル定義
- **asyncpg**: 非同期PostgreSQLドライバ
- **Alembic 1.17+**: マイグレーション管理
- **PostgreSQL 15+**: データベース稼働中

### 環境設定前提 🔵
- `.env` ファイルが存在し、以下の環境変数が設定されている:
  - `POSTGRES_USER`
  - `POSTGRES_PASSWORD`
  - `POSTGRES_HOST`
  - `POSTGRES_PORT`
  - `POSTGRES_DB`
- Docker Compose で PostgreSQL が起動している

## 9. 次のステップ

### このタスク完了後の次のステップ 🔵
1. **TASK-0009**: 初回マイグレーション実行・DB接続テスト
   - `alembic revision --autogenerate` でマイグレーション生成
   - `alembic upgrade head` でテーブル作成
   - データベース接続テスト・CRUD操作テスト実行

### 推奨コマンド
次のお勧めステップ: `/tsumiki:tdd-testcases` でテストケースの洗い出しを行います。

## 10. 品質判定

### 要件の明確性 ✅
- 要件は明確で曖昧さがない
- EARS要件定義書、データベーススキーマ設計書を参照し、具体的な仕様を定義

### 入出力仕様の具体性 ✅
- 入出力仕様が具体的に定義されている
- SQLAlchemyモデルクラスの定義、フィールド型、制約が明確
- データベース接続情報、セッション管理の仕様が詳細

### 制約条件の明確性 ✅
- 制約条件が明確
- パフォーマンス要件（NFR-002）、セキュリティ要件（NFR-104, NFR-105）を考慮
- データベース制約（NOT NULL, Enum, Index）が明確

### 実装可能性 ✅
- 実装可能性が確実
- SQLAlchemy 2.x の標準的な実装パターンに従う
- 依存タスク（TASK-0007）が完了済み、技術基盤が整備済み

### 総合判定: ✅ 高品質
要件定義は高品質であり、TDD開発を開始する準備が整っています。

## 11. 信頼性レベルサマリー

### 🔵 青信号（確実な要件）
- AI変換履歴モデルのフィールド定義（database-schema.sql準拠）
- データベース制約（NOT NULL, Enum, Index）
- セッション管理の実装方針（SQLAlchemy 2.x標準）
- エラーハンドリング要件（NFR-304）
- テストカバレッジ目標（NFR-501, NFR-502）

### 🟡 黄信号（妥当な推測）
- Enum値のPython実装方法（設計書はSQL定義のみ）
- トランザクション管理の詳細実装方法
- エラーメッセージの具体的な文言

### 🔴 赤信号（推測）
- なし

**全体の信頼性レベル**: 🔵 青信号（ほぼ確実）

---

## 更新履歴
- **2025-11-20**: 初回作成（TDD要件定義フェーズ - TASK-0008）
