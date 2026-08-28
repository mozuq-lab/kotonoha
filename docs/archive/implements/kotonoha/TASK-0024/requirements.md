# TASK-0024: AI変換ログテーブル実装・プライバシー対応 要件定義書

## 概要

AI変換機能の使用状況を記録するログテーブルを実装する。プライバシー保護のため、入力テキストをSHA-256でハッシュ化して保存し、元のテキストが復元できない一方向ハッシュを使用する。

## 信頼性レベル凡例

- **青信号**: EARS要件定義書・設計文書を参考にした確実な要件
- **黄信号**: EARS要件定義書・設計文書から妥当な推測による要件
- **赤信号**: EARS要件定義書・設計文書にない推測による要件

---

## 1. 機能要件

### 1.1 AI変換ログモデル（AIConversionLog）

#### FR-001: ログテーブルの定義 - 青信号
**根拠**: database-schema.sql（line 36-77）

システムは以下のフィールドを持つAI変換ログテーブルを実装しなければならない:

| フィールド名 | 型 | 必須 | 説明 |
|------------|---|------|------|
| id | Integer | Y | プライマリキー（自動採番） |
| input_text_hash | String(64) | Y | 入力テキストのSHA-256ハッシュ値 |
| input_length | Integer | Y | 入力テキストの文字数（統計用） |
| output_length | Integer | Y | 出力テキストの文字数（統計用） |
| politeness_level | String(20) | Y | 丁寧さレベル（casual/normal/polite） |
| conversion_time_ms | Integer | N | 変換処理時間（ミリ秒） |
| ai_provider | String(50) | N | AIプロバイダー名（デフォルト: "anthropic"） |
| is_success | Boolean | Y | 成功・失敗フラグ（デフォルト: True） |
| error_message | Text | N | エラーメッセージ（失敗時のみ） |
| session_id | UUID | Y | セッションID（同一セッションのログをグループ化） |
| created_at | DateTime | Y | 作成日時（タイムゾーン付き） |

#### FR-002: テキストハッシュ化機能 - 青信号
**根拠**: NFR-102、database-schema.sql（line 39-40, 74-75）

システムは入力テキストをSHA-256アルゴリズムでハッシュ化する機能を提供しなければならない:

- ハッシュ関数はUTF-8エンコードされた文字列を入力として受け取る
- 出力は64文字の16進数文字列（SHA-256の固定長出力）
- 同一の入力に対して常に同一のハッシュ値を返す
- 異なる入力に対しては（実用上）異なるハッシュ値を返す

#### FR-003: ログエントリ作成メソッド - 黄信号
**根拠**: タスク詳細の実装例（kotonoha-phase2.md line 845-867）

システムは`create_log`クラスメソッドを通じてログエントリを作成しなければならない:

- 入力パラメータ:
  - `input_text`: 元の入力テキスト（ハッシュ化前）
  - `output_text`: 変換後テキスト
  - `politeness_level`: 丁寧さレベル
  - `conversion_time_ms`: 変換処理時間
  - `ai_provider`: AIプロバイダー（オプション）
  - `session_id`: セッションID（オプション）
  - `is_success`: 成功フラグ（オプション）
  - `error_message`: エラーメッセージ（オプション）
- ハッシュ化は自動的に適用される
- session_idが指定されない場合は新しいUUIDを生成する

### 1.2 エラーログモデル（ErrorLog）

#### FR-004: エラーログテーブルの定義 - 黄信号
**根拠**: database-schema.sql（line 79-112）、タスク詳細（kotonoha-phase2.md line 870-897）

システムは以下のフィールドを持つエラーログテーブルを実装しなければならない:

| フィールド名 | 型 | 必須 | 説明 |
|------------|---|------|------|
| id | Integer | Y | プライマリキー（自動採番） |
| error_type | String(100) | Y | エラータイプ（例: "NetworkException"） |
| error_message | Text | Y | エラーメッセージ |
| error_code | String(50) | N | エラーコード（例: "AI_001"） |
| endpoint | String(255) | N | エラー発生エンドポイント |
| http_method | String(10) | N | HTTPメソッド |
| stack_trace | Text | N | スタックトレース（開発環境のみ） |
| created_at | DateTime | Y | 作成日時（タイムゾーン付き） |

### 1.3 データベースマイグレーション

#### FR-005: Alembicマイグレーション - 青信号
**根拠**: タスク詳細（kotonoha-phase2.md line 899-904）

システムはAlembicを使用してマイグレーションファイルを作成し、実行しなければならない:

- マイグレーションは`alembic revision --autogenerate`で自動生成する
- マイグレーションメッセージ: "Add ai_conversion_logs and error_logs tables"
- マイグレーションは`alembic upgrade head`で適用可能であること

### 1.4 モデル登録

#### FR-006: Baseへのモデル登録 - 青信号
**根拠**: タスク詳細（kotonoha-phase2.md line 906-914）

システムは`app/db/base.py`にAIConversionLogとErrorLogモデルを登録しなければならない:

```python
from app.models.ai_conversion_logs import AIConversionLog
from app.models.error_logs import ErrorLog

__all__ = ["Base", "AIConversionHistory", "AIConversionLog", "ErrorLog"]
```

---

## 2. 非機能要件

### 2.1 プライバシー保護

#### NFR-001: 入力テキストのハッシュ化必須 - 青信号
**根拠**: NFR-102、api-endpoints.md（line 436-438）

- 平文の入力テキストをデータベースに保存してはならない
- すべての入力テキストはSHA-256でハッシュ化して保存する
- ハッシュ化されたテキストから元のテキストを復元できてはならない

#### NFR-002: 個人情報の非保存 - 青信号
**根拠**: NFR-103、database-schema.sql（line 32-34）

- ログにはユーザーを直接特定できる情報を保存しない
- session_idはランダム生成のUUIDであり、ユーザーアカウントと紐付けない

### 2.2 パフォーマンス

#### NFR-003: インデックス設定 - 黄信号
**根拠**: database-schema.sql（line 71）

以下のカラムにインデックスを設定する:
- `ai_conversion_logs.created_at`: 時系列検索用（降順）
- `ai_conversion_logs.input_text_hash`: ハッシュ検索用
- `ai_conversion_logs.session_id`: セッションごとのログ取得用
- `error_logs.error_type`: エラータイプ別検索用
- `error_logs.created_at`: 時系列検索用

#### NFR-004: 処理時間記録 - 青信号
**根拠**: NFR-002、database-schema.sql（line 76）

- AI変換の処理時間をミリ秒単位で記録する
- パフォーマンス監視（平均3秒以内の目標達成確認）に使用

### 2.3 データ保持

#### NFR-005: データ保持期間 - 黄信号
**根拠**: database-schema.sql（line 198-210）

- AI変換ログの保持期間: 90日
- エラーログの保持期間: 30日
- 注: 自動削除機能はMVP範囲外だが、手動削除は可能とする

### 2.4 セキュリティ

#### NFR-006: SQLインジェクション対策 - 青信号
**根拠**: api-endpoints.md（line 431）

- SQLAlchemy ORMを使用してSQLインジェクションを防止する

---

## 3. 受け入れ基準

### AC-001: AIConversionLogモデルの動作確認

**Given**: データベース接続が確立されている
**When**: AIConversionLog.create_logでログエントリを作成する
**Then**:
- ログがデータベースに正常に保存される
- input_text_hashが64文字の16進数文字列である
- input_lengthが元のテキストの文字数と一致する
- 元のテキストはデータベースに保存されない

### AC-002: ハッシュ化の一貫性確認

**Given**: 同一のテキスト文字列
**When**: 2回ハッシュ化を実行する
**Then**: 両方のハッシュ値が完全に一致する

### AC-003: ハッシュ化の一意性確認

**Given**: 異なる2つのテキスト文字列
**When**: それぞれハッシュ化を実行する
**Then**: 2つのハッシュ値は異なる

### AC-004: セッションIDによるグループ化

**Given**: 同一のsession_idを持つ複数のログエントリ
**When**: session_idでフィルタリングする
**Then**: 同一セッションのすべてのログが取得できる

### AC-005: ErrorLogモデルの動作確認

**Given**: データベース接続が確立されている
**When**: ErrorLogエントリを作成して保存する
**Then**:
- エラーログがデータベースに正常に保存される
- error_typeとerror_messageが正しく記録される

### AC-006: マイグレーションの実行確認

**Given**: マイグレーションファイルが存在する
**When**: `alembic upgrade head`を実行する
**Then**:
- ai_conversion_logsテーブルが作成される
- error_logsテーブルが作成される
- すべてのカラムとインデックスが正しく作成される

### AC-007: 丁寧さレベルの制約確認

**Given**: AIConversionLogを作成する
**When**: politeness_levelに"casual", "normal", "polite"以外の値を設定する
**Then**: バリデーションエラーまたは制約違反が発生する

---

## 4. データモデル設計

### 4.1 ER図（概念）

```
+------------------------+         +------------------+
|   ai_conversion_logs   |         |    error_logs    |
+------------------------+         +------------------+
| PK id                  |         | PK id            |
| input_text_hash        |         | error_type       |
| input_length           |         | error_message    |
| output_length          |         | error_code       |
| politeness_level       |         | endpoint         |
| conversion_time_ms     |         | http_method      |
| ai_provider            |         | stack_trace      |
| is_success             |         | created_at       |
| error_message          |         +------------------+
| session_id             |
| created_at             |
+------------------------+
```

### 4.2 SQLAlchemy モデル定義

#### AIConversionLog

```python
class AIConversionLog(Base):
    __tablename__ = "ai_conversion_logs"

    id = Column(Integer, primary_key=True, index=True)
    input_text_hash = Column(String(64), nullable=False, index=True)
    input_length = Column(Integer, nullable=False)
    output_length = Column(Integer, nullable=False)
    politeness_level = Column(String(20), nullable=False)
    conversion_time_ms = Column(Integer, nullable=True)
    ai_provider = Column(String(50), default="anthropic")
    is_success = Column(Boolean, default=True)
    error_message = Column(Text, nullable=True)
    session_id = Column(UUID(as_uuid=True), default=uuid.uuid4, index=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, index=True)
```

#### ErrorLog

```python
class ErrorLog(Base):
    __tablename__ = "error_logs"

    id = Column(Integer, primary_key=True, index=True)
    error_type = Column(String(100), nullable=False, index=True)
    error_message = Column(Text, nullable=False)
    error_code = Column(String(50), nullable=True)
    endpoint = Column(String(255), nullable=True)
    http_method = Column(String(10), nullable=True)
    stack_trace = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, index=True)
```

---

## 5. テスト要件

### 5.1 ユニットテスト

| テストケースID | テスト名 | 説明 | 優先度 |
|--------------|---------|------|-------|
| UT-001 | test_ai_conversion_log_create | AIConversionLogの正常作成 | 高 |
| UT-002 | test_ai_conversion_log_hash_consistency | ハッシュ化の一貫性 | 高 |
| UT-003 | test_ai_conversion_log_different_hash | 異なるテキストで異なるハッシュ | 高 |
| UT-004 | test_ai_conversion_log_with_session_id | セッションIDでのグループ化 | 中 |
| UT-005 | test_ai_conversion_log_with_error | エラー情報を含むログ作成 | 中 |
| UT-006 | test_error_log_create | ErrorLogの正常作成 | 高 |
| UT-007 | test_hash_text_empty_string | 空文字列のハッシュ化 | 低 |
| UT-008 | test_hash_text_unicode | Unicode文字列のハッシュ化 | 中 |

### 5.2 統合テスト

| テストケースID | テスト名 | 説明 | 優先度 |
|--------------|---------|------|-------|
| IT-001 | test_migration_creates_tables | マイグレーションでテーブル作成 | 高 |
| IT-002 | test_insert_and_query_log | ログ挿入と検索 | 高 |
| IT-003 | test_query_by_session_id | セッションIDでの検索 | 中 |
| IT-004 | test_query_by_date_range | 日付範囲での検索 | 中 |

---

## 6. 依存関係

### 6.1 前提タスク

| タスクID | タスク名 | 状態 |
|---------|---------|------|
| TASK-0023 | Pydanticスキーマ定義（AI変換リクエスト・レスポンス） | 完了 |
| TASK-0022 | データベース接続プール・セッション管理 | 完了 |
| TASK-0021 | FastAPIプロジェクト構造再構築・設定管理 | 完了 |

### 6.2 技術依存

| ライブラリ | バージョン | 用途 |
|-----------|----------|------|
| SQLAlchemy | 2.x | ORM、モデル定義 |
| Alembic | 1.x | データベースマイグレーション |
| PostgreSQL | 15+ | データベース |
| hashlib | 標準ライブラリ | SHA-256ハッシュ化 |

---

## 7. 実装ファイル一覧

| ファイルパス | 説明 | 優先度 |
|------------|------|-------|
| `backend/app/models/ai_conversion_logs.py` | AIConversionLogモデル | 高 |
| `backend/app/models/error_logs.py` | ErrorLogモデル | 高 |
| `backend/app/db/base.py` | モデル登録更新 | 高 |
| `backend/alembic/versions/xxxx_add_logs_tables.py` | マイグレーションファイル | 高 |
| `backend/tests/test_models_logs.py` | ログモデルテスト | 高 |

---

## 8. リスクと対策

### R-001: ハッシュ衝突

**リスク**: 異なるテキストが同一のハッシュ値を生成する可能性（理論上）
**影響度**: 低
**発生確率**: 極めて低（SHA-256の衝突耐性）
**対策**: 統計・分析用途のため、厳密な一意性は要求されない。必要であれば入力長との組み合わせで識別。

### R-002: ログデータの肥大化

**リスク**: 長期運用でログテーブルが肥大化しパフォーマンスに影響
**影響度**: 中
**発生確率**: 中
**対策**: インデックスの適切な設定、将来的なパーティショニングまたは古いデータの定期削除（90日保持）

### R-003: セッションID生成の重複

**リスク**: UUIDの重複生成
**影響度**: 低
**発生確率**: 極めて低（UUIDv4の衝突確率）
**対策**: 現状対策不要。問題発生時はユニーク制約を追加。

---

## 9. 完了条件

- [ ] AIConversionLogモデルが実装されている
- [ ] ErrorLogモデルが実装されている
- [ ] テキストハッシュ化機能が動作する（SHA-256、64文字出力）
- [ ] create_logメソッドでログエントリを作成できる
- [ ] Alembicマイグレーションが正常に実行される
- [ ] app/db/base.pyにモデルが登録されている
- [ ] ログモデルテストが全て成功する（カバレッジ90%以上）

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 担当者 |
|------|----------|---------|-------|
| 2025-11-22 | 1.0 | 初版作成 | TDD要件定義担当者 |
