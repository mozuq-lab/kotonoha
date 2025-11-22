# TASK-0024: AI変換ログテーブル実装・プライバシー対応 テストケース仕様書

## 概要

TASK-0024で実装するAI変換ログテーブル（AIConversionLog、ErrorLog）およびハッシュ化ユーティリティに対するテストケースを定義する。

## テスト実行環境

| 項目 | 値 |
|------|-----|
| フレームワーク | pytest / pytest-asyncio |
| データベース | PostgreSQL 15+ (テスト用DBインスタンス) |
| ORM | SQLAlchemy 2.x (async対応) |
| Python | 3.10+ |

## テストファイル構成

```
backend/tests/
├── test_models_logs.py          # ログモデルユニットテスト
├── test_hash_utils.py           # ハッシュ化ユーティリティテスト
└── test_logs_integration.py     # 統合テスト（マイグレーション含む）
```

---

## 1. ユニットテスト

### 1.1 AIConversionLogモデルのテスト

#### UT-001: AIConversionLogの正常作成（create_logメソッド）

| 項目 | 内容 |
|------|------|
| テストケースID | UT-001 |
| テスト名 | test_ai_conversion_log_create |
| 優先度 | 高 |
| 関連要件ID | FR-001, FR-003, AC-001 |

**前提条件**:
- データベース接続が確立されている
- db_sessionフィクスチャが利用可能

**テスト手順**:
1. AIConversionLog.create_logメソッドを呼び出す
   - input_text: "ありがとう"
   - output_text: "ありがとうございます"
   - politeness_level: "polite"
   - conversion_time_ms: 1500
   - ai_provider: "anthropic"
2. 作成されたインスタンスをdb_sessionに追加しcommit
3. db_session.refreshでデータベースから最新状態を取得

**期待結果**:
- log.id が自動生成されている（整数値）
- log.input_text_hash が64文字の16進数文字列である
- log.input_length が5（"ありがとう"の文字数）である
- log.output_length が11（"ありがとうございます"の文字数）である
- log.politeness_level が"polite"である
- log.conversion_time_ms が1500である
- log.is_success がTrueである
- log.session_id がUUID形式である
- log.created_at がdatetime型である

---

#### UT-002: ハッシュ化の一貫性

| 項目 | 内容 |
|------|------|
| テストケースID | UT-002 |
| テスト名 | test_ai_conversion_log_hash_consistency |
| 優先度 | 高 |
| 関連要件ID | FR-002, AC-002 |

**前提条件**:
- AIConversionLogクラスがインポート可能

**テスト手順**:
1. 同一テキスト"ありがとう"に対してhash_textを2回実行
2. 2つのハッシュ値を比較

**期待結果**:
- hash1 == hash2（同一のハッシュ値が返される）
- len(hash1) == 64（SHA-256の出力長）

---

#### UT-003: 異なるテキストで異なるハッシュ

| 項目 | 内容 |
|------|------|
| テストケースID | UT-003 |
| テスト名 | test_ai_conversion_log_different_hash |
| 優先度 | 高 |
| 関連要件ID | FR-002, AC-003 |

**前提条件**:
- AIConversionLogクラスがインポート可能

**テスト手順**:
1. "ありがとう"に対してhash_textを実行
2. "こんにちは"に対してhash_textを実行
3. 2つのハッシュ値を比較

**期待結果**:
- hash1 != hash2（異なるハッシュ値が返される）

---

#### UT-004: セッションIDでのグループ化

| 項目 | 内容 |
|------|------|
| テストケースID | UT-004 |
| テスト名 | test_ai_conversion_log_with_session_id |
| 優先度 | 中 |
| 関連要件ID | FR-003, AC-004 |

**前提条件**:
- データベース接続が確立されている
- db_sessionフィクスチャが利用可能

**テスト手順**:
1. 固定のsession_id（uuid4()）を生成
2. 同一session_idで2つのログエントリを作成
3. 両方のエントリをデータベースに保存

**期待結果**:
- log1.session_id == log2.session_id
- 両方のログが正常に保存される

---

#### UT-005: エラー情報を含むログ作成

| 項目 | 内容 |
|------|------|
| テストケースID | UT-005 |
| テスト名 | test_ai_conversion_log_with_error |
| 優先度 | 中 |
| 関連要件ID | FR-003 |

**前提条件**:
- データベース接続が確立されている
- db_sessionフィクスチャが利用可能

**テスト手順**:
1. AIConversionLog.create_logを呼び出す
   - is_success: False
   - error_message: "AI API timeout"
2. データベースに保存

**期待結果**:
- log.is_success がFalseである
- log.error_message が"AI API timeout"である
- ログが正常に保存される

---

#### UT-006: セッションID自動生成

| 項目 | 内容 |
|------|------|
| テストケースID | UT-006 |
| テスト名 | test_ai_conversion_log_auto_session_id |
| 優先度 | 中 |
| 関連要件ID | FR-003 |

**前提条件**:
- AIConversionLogクラスがインポート可能

**テスト手順**:
1. session_idを指定せずにcreate_logを呼び出す
2. 生成されたsession_idを確認

**期待結果**:
- log.session_id がNoneではない
- log.session_id がUUID形式である

---

#### UT-007: インスタンス直接作成（create_logを使用しない場合）

| 項目 | 内容 |
|------|------|
| テストケースID | UT-007 |
| テスト名 | test_ai_conversion_log_direct_instantiation |
| 優先度 | 低 |
| 関連要件ID | FR-001 |

**前提条件**:
- AIConversionLogクラスがインポート可能

**テスト手順**:
1. AIConversionLogコンストラクタを直接呼び出す
   - 全必須フィールドを指定
2. インスタンスの各フィールドを確認

**期待結果**:
- 指定した値がすべて正しく設定されている
- idとcreated_atはDB保存前はNone

---

### 1.2 ErrorLogモデルのテスト

#### UT-008: ErrorLogの正常作成

| 項目 | 内容 |
|------|------|
| テストケースID | UT-008 |
| テスト名 | test_error_log_create |
| 優先度 | 高 |
| 関連要件ID | FR-004, AC-005 |

**前提条件**:
- データベース接続が確立されている
- db_sessionフィクスチャが利用可能

**テスト手順**:
1. ErrorLogインスタンスを作成
   - error_type: "NetworkException"
   - error_message: "AI API接続エラー"
   - error_code: "AI_001"
   - endpoint: "/api/v1/ai/convert"
   - http_method: "POST"
2. データベースに保存しrefresh

**期待結果**:
- error_log.id が自動生成されている
- error_log.error_type が"NetworkException"である
- error_log.error_message が"AI API接続エラー"である
- error_log.created_at がdatetime型である

---

#### UT-009: ErrorLogの必須フィールドのみで作成

| 項目 | 内容 |
|------|------|
| テストケースID | UT-009 |
| テスト名 | test_error_log_required_fields_only |
| 優先度 | 中 |
| 関連要件ID | FR-004 |

**前提条件**:
- データベース接続が確立されている
- db_sessionフィクスチャが利用可能

**テスト手順**:
1. ErrorLogインスタンスを作成（必須フィールドのみ）
   - error_type: "ValidationError"
   - error_message: "Invalid input"
2. データベースに保存

**期待結果**:
- ログが正常に保存される
- オプションフィールド（error_code, endpoint, http_method, stack_trace）がNullである

---

#### UT-010: ErrorLogのスタックトレース保存

| 項目 | 内容 |
|------|------|
| テストケースID | UT-010 |
| テスト名 | test_error_log_with_stack_trace |
| 優先度 | 低 |
| 関連要件ID | FR-004 |

**前提条件**:
- データベース接続が確立されている
- db_sessionフィクスチャが利用可能

**テスト手順**:
1. ErrorLogインスタンスを作成（stack_trace含む）
   - stack_trace: "Traceback (most recent call last):\n  File..."
2. データベースに保存

**期待結果**:
- stack_traceが切り捨てられずに保存される

---

### 1.3 ハッシュ化ユーティリティのテスト

#### UT-011: 空文字列のハッシュ化

| 項目 | 内容 |
|------|------|
| テストケースID | UT-011 |
| テスト名 | test_hash_text_empty_string |
| 優先度 | 低 |
| 関連要件ID | FR-002 |

**前提条件**:
- AIConversionLogクラスがインポート可能

**テスト手順**:
1. 空文字列""に対してhash_textを実行

**期待結果**:
- 64文字のハッシュ値が返される
- 例外が発生しない

---

#### UT-012: Unicode文字列のハッシュ化

| 項目 | 内容 |
|------|------|
| テストケースID | UT-012 |
| テスト名 | test_hash_text_unicode |
| 優先度 | 中 |
| 関連要件ID | FR-002 |

**前提条件**:
- AIConversionLogクラスがインポート可能

**テスト手順**:
1. 日本語文字列"お水をください"に対してhash_textを実行
2. 絵文字を含む文字列に対してhash_textを実行

**期待結果**:
- 両方とも64文字のハッシュ値が返される
- 例外が発生しない

---

#### UT-013: 長い文字列のハッシュ化

| 項目 | 内容 |
|------|------|
| テストケースID | UT-013 |
| テスト名 | test_hash_text_long_string |
| 優先度 | 低 |
| 関連要件ID | FR-002 |

**前提条件**:
- AIConversionLogクラスがインポート可能

**テスト手順**:
1. 10,000文字の文字列に対してhash_textを実行

**期待結果**:
- 64文字のハッシュ値が返される（入力長に依存しない）
- 処理時間が許容範囲内（1秒以内）

---

#### UT-014: ハッシュ値のフォーマット検証

| 項目 | 内容 |
|------|------|
| テストケースID | UT-014 |
| テスト名 | test_hash_text_format |
| 優先度 | 中 |
| 関連要件ID | FR-002, NFR-001 |

**前提条件**:
- AIConversionLogクラスがインポート可能

**テスト手順**:
1. 任意のテキストに対してhash_textを実行
2. 結果のフォーマットを検証

**期待結果**:
- 結果が64文字である
- 結果が16進数文字列である（0-9, a-f のみ）
- 結果が小文字である

---

### 1.4 バリデーションテスト

#### UT-015: 丁寧さレベルの有効値テスト（casual）

| 項目 | 内容 |
|------|------|
| テストケースID | UT-015 |
| テスト名 | test_politeness_level_casual |
| 優先度 | 中 |
| 関連要件ID | FR-001, AC-007 |

**前提条件**:
- データベース接続が確立されている

**テスト手順**:
1. politeness_level="casual"でログを作成
2. データベースに保存

**期待結果**:
- ログが正常に保存される

---

#### UT-016: 丁寧さレベルの有効値テスト（normal）

| 項目 | 内容 |
|------|------|
| テストケースID | UT-016 |
| テスト名 | test_politeness_level_normal |
| 優先度 | 中 |
| 関連要件ID | FR-001, AC-007 |

**前提条件**:
- データベース接続が確立されている

**テスト手順**:
1. politeness_level="normal"でログを作成
2. データベースに保存

**期待結果**:
- ログが正常に保存される

---

#### UT-017: 丁寧さレベルの有効値テスト（polite）

| 項目 | 内容 |
|------|------|
| テストケースID | UT-017 |
| テスト名 | test_politeness_level_polite |
| 優先度 | 中 |
| 関連要件ID | FR-001, AC-007 |

**前提条件**:
- データベース接続が確立されている

**テスト手順**:
1. politeness_level="polite"でログを作成
2. データベースに保存

**期待結果**:
- ログが正常に保存される

---

#### UT-018: 丁寧さレベルの不正値テスト

| 項目 | 内容 |
|------|------|
| テストケースID | UT-018 |
| テスト名 | test_politeness_level_invalid |
| 優先度 | 高 |
| 関連要件ID | FR-001, AC-007 |

**前提条件**:
- データベース接続が確立されている

**テスト手順**:
1. politeness_level="invalid_level"でログを作成
2. データベースに保存を試みる

**期待結果**:
- IntegrityError（CHECK制約違反）またはValidationErrorが発生する

---

#### UT-019: 必須フィールド欠落テスト（input_text_hash）

| 項目 | 内容 |
|------|------|
| テストケースID | UT-019 |
| テスト名 | test_missing_input_text_hash |
| 優先度 | 高 |
| 関連要件ID | FR-001 |

**前提条件**:
- データベース接続が確立されている

**テスト手順**:
1. input_text_hashを指定せずにAIConversionLogを作成（直接インスタンス化）
2. データベースに保存を試みる

**期待結果**:
- IntegrityError（NOT NULL制約違反）が発生する

---

#### UT-020: 必須フィールド欠落テスト（error_type）

| 項目 | 内容 |
|------|------|
| テストケースID | UT-020 |
| テスト名 | test_missing_error_type |
| 優先度 | 高 |
| 関連要件ID | FR-004 |

**前提条件**:
- データベース接続が確立されている

**テスト手順**:
1. error_typeを指定せずにErrorLogを作成
2. データベースに保存を試みる

**期待結果**:
- IntegrityError（NOT NULL制約違反）が発生する

---

#### UT-021: input_lengthの境界値テスト（0）

| 項目 | 内容 |
|------|------|
| テストケースID | UT-021 |
| テスト名 | test_input_length_zero |
| 優先度 | 低 |
| 関連要件ID | FR-001 |

**前提条件**:
- AIConversionLogクラスがインポート可能

**テスト手順**:
1. 空文字列でcreate_logを呼び出す

**期待結果**:
- input_lengthが0である

---

#### UT-022: conversion_time_msの境界値テスト（0）

| 項目 | 内容 |
|------|------|
| テストケースID | UT-022 |
| テスト名 | test_conversion_time_ms_zero |
| 優先度 | 低 |
| 関連要件ID | FR-001, NFR-004 |

**前提条件**:
- データベース接続が確立されている

**テスト手順**:
1. conversion_time_ms=0でログを作成
2. データベースに保存

**期待結果**:
- ログが正常に保存される
- conversion_time_msが0である（Noneではない）

---

#### UT-023: conversion_time_msの境界値テスト（大きい値）

| 項目 | 内容 |
|------|------|
| テストケースID | UT-023 |
| テスト名 | test_conversion_time_ms_large |
| 優先度 | 低 |
| 関連要件ID | FR-001, NFR-004 |

**前提条件**:
- データベース接続が確立されている

**テスト手順**:
1. conversion_time_ms=999999でログを作成
2. データベースに保存

**期待結果**:
- ログが正常に保存される
- conversion_time_msが999999である

---

#### UT-024: プライバシー保護確認テスト

| 項目 | 内容 |
|------|------|
| テストケースID | UT-024 |
| テスト名 | test_privacy_no_plaintext_stored |
| 優先度 | 高 |
| 関連要件ID | NFR-001, NFR-002 |

**前提条件**:
- データベース接続が確立されている

**テスト手順**:
1. 特定のテキスト"秘密のメッセージ"でログを作成
2. データベースに保存
3. 保存されたログを取得
4. モデルの全属性を調査

**期待結果**:
- input_text_hashには元のテキストが含まれていない
- モデルにinput_text属性が存在しない（またはNone）
- ハッシュ値から元のテキストを復元できない

---

### 1.5 デフォルト値テスト

#### UT-025: ai_providerデフォルト値テスト

| 項目 | 内容 |
|------|------|
| テストケースID | UT-025 |
| テスト名 | test_ai_provider_default |
| 優先度 | 低 |
| 関連要件ID | FR-001 |

**前提条件**:
- データベース接続が確立されている

**テスト手順**:
1. ai_providerを指定せずにログを作成
2. データベースに保存

**期待結果**:
- ai_providerが"anthropic"である（デフォルト値）

---

#### UT-026: is_successデフォルト値テスト

| 項目 | 内容 |
|------|------|
| テストケースID | UT-026 |
| テスト名 | test_is_success_default |
| 優先度 | 低 |
| 関連要件ID | FR-001 |

**前提条件**:
- データベース接続が確立されている

**テスト手順**:
1. is_successを指定せずにログを作成
2. データベースに保存

**期待結果**:
- is_successがTrueである（デフォルト値）

---

## 2. 統合テスト

### 2.1 マイグレーションテスト

#### IT-001: マイグレーションでテーブル作成

| 項目 | 内容 |
|------|------|
| テストケースID | IT-001 |
| テスト名 | test_migration_creates_tables |
| 優先度 | 高 |
| 関連要件ID | FR-005, AC-006 |

**前提条件**:
- テスト用データベースが利用可能
- Alembicマイグレーションファイルが存在する

**テスト手順**:
1. `alembic upgrade head`を実行
2. テーブルの存在を確認

**期待結果**:
- ai_conversion_logsテーブルが存在する
- error_logsテーブルが存在する

---

#### IT-002: ai_conversion_logsテーブルカラム確認

| 項目 | 内容 |
|------|------|
| テストケースID | IT-002 |
| テスト名 | test_ai_conversion_logs_columns |
| 優先度 | 高 |
| 関連要件ID | FR-001, AC-006 |

**前提条件**:
- マイグレーションが適用済み

**テスト手順**:
1. ai_conversion_logsテーブルのカラム情報を取得
2. 各カラムの型と制約を確認

**期待結果**:
- すべてのカラムが正しい型で存在する
- NOT NULL制約が正しく設定されている
- CHECK制約（politeness_level）が存在する

---

#### IT-003: error_logsテーブルカラム確認

| 項目 | 内容 |
|------|------|
| テストケースID | IT-003 |
| テスト名 | test_error_logs_columns |
| 優先度 | 高 |
| 関連要件ID | FR-004, AC-006 |

**前提条件**:
- マイグレーションが適用済み

**テスト手順**:
1. error_logsテーブルのカラム情報を取得
2. 各カラムの型と制約を確認

**期待結果**:
- すべてのカラムが正しい型で存在する
- NOT NULL制約が正しく設定されている

---

#### IT-004: インデックス存在確認

| 項目 | 内容 |
|------|------|
| テストケースID | IT-004 |
| テスト名 | test_indexes_exist |
| 優先度 | 中 |
| 関連要件ID | NFR-003, AC-006 |

**前提条件**:
- マイグレーションが適用済み

**テスト手順**:
1. ai_conversion_logsテーブルのインデックスを取得
2. error_logsテーブルのインデックスを取得

**期待結果**:
- ai_conversion_logs.created_atにインデックスが存在
- ai_conversion_logs.input_text_hashにインデックスが存在
- ai_conversion_logs.session_idにインデックスが存在
- error_logs.error_typeにインデックスが存在
- error_logs.created_atにインデックスが存在

---

#### IT-005: マイグレーションロールバックテスト

| 項目 | 内容 |
|------|------|
| テストケースID | IT-005 |
| テスト名 | test_migration_rollback |
| 優先度 | 低 |
| 関連要件ID | FR-005 |

**前提条件**:
- マイグレーションが適用済み

**テスト手順**:
1. `alembic downgrade -1`を実行
2. テーブルの削除を確認
3. `alembic upgrade head`で再適用

**期待結果**:
- ダウングレードでテーブルが削除される
- アップグレードでテーブルが再作成される

---

### 2.2 CRUD操作テスト

#### IT-006: ログ挿入と検索

| 項目 | 内容 |
|------|------|
| テストケースID | IT-006 |
| テスト名 | test_insert_and_query_log |
| 優先度 | 高 |
| 関連要件ID | FR-001, FR-003 |

**前提条件**:
- データベース接続が確立されている
- テーブルが存在する

**テスト手順**:
1. AIConversionLog.create_logでログを作成
2. データベースに保存
3. IDで検索して取得

**期待結果**:
- 保存したログが正しく取得できる
- すべてのフィールド値が一致する

---

#### IT-007: セッションIDでの検索

| 項目 | 内容 |
|------|------|
| テストケースID | IT-007 |
| テスト名 | test_query_by_session_id |
| 優先度 | 中 |
| 関連要件ID | AC-004, NFR-003 |

**前提条件**:
- データベース接続が確立されている
- 複数のログが保存済み

**テスト手順**:
1. 同一session_idで3つのログを作成・保存
2. 異なるsession_idで1つのログを作成・保存
3. 最初のsession_idで検索

**期待結果**:
- 3件のログが取得される
- すべてのログが指定したsession_idを持つ

---

#### IT-008: 日付範囲での検索

| 項目 | 内容 |
|------|------|
| テストケースID | IT-008 |
| テスト名 | test_query_by_date_range |
| 優先度 | 中 |
| 関連要件ID | NFR-003 |

**前提条件**:
- データベース接続が確立されている
- 複数のログが保存済み

**テスト手順**:
1. 複数のログを作成・保存
2. 現在時刻を含む日付範囲で検索

**期待結果**:
- 指定した日付範囲のログのみが取得される

---

#### IT-009: created_at降順での取得

| 項目 | 内容 |
|------|------|
| テストケースID | IT-009 |
| テスト名 | test_query_order_by_created_at_desc |
| 優先度 | 中 |
| 関連要件ID | NFR-003 |

**前提条件**:
- データベース接続が確立されている

**テスト手順**:
1. 3つのログを順番に作成・保存
2. created_at DESCでソートして取得

**期待結果**:
- 最新のログが先頭に来る

---

#### IT-010: LIMIT句でのレコード数制限

| 項目 | 内容 |
|------|------|
| テストケースID | IT-010 |
| テスト名 | test_query_with_limit |
| 優先度 | 低 |
| 関連要件ID | NFR-003 |

**前提条件**:
- データベース接続が確立されている

**テスト手順**:
1. 15件のログを作成・保存
2. LIMIT 10で取得

**期待結果**:
- 10件のログが取得される

---

### 2.3 インデックス動作テスト

#### IT-011: input_text_hashインデックス利用確認

| 項目 | 内容 |
|------|------|
| テストケースID | IT-011 |
| テスト名 | test_index_used_for_hash_search |
| 優先度 | 低 |
| 関連要件ID | NFR-003 |

**前提条件**:
- データベース接続が確立されている
- 大量のログが保存済み（100件以上）

**テスト手順**:
1. 100件のログを作成・保存
2. 特定のinput_text_hashで検索
3. EXPLAIN ANALYZEで実行計画を確認

**期待結果**:
- インデックススキャンが使用される

---

#### IT-012: session_idインデックス利用確認

| 項目 | 内容 |
|------|------|
| テストケースID | IT-012 |
| テスト名 | test_index_used_for_session_search |
| 優先度 | 低 |
| 関連要件ID | NFR-003 |

**前提条件**:
- データベース接続が確立されている
- 大量のログが保存済み（100件以上）

**テスト手順**:
1. 100件のログを作成・保存
2. 特定のsession_idで検索
3. EXPLAIN ANALYZEで実行計画を確認

**期待結果**:
- インデックススキャンが使用される

---

### 2.4 トランザクションテスト

#### IT-013: トランザクション内での複数ログ保存

| 項目 | 内容 |
|------|------|
| テストケースID | IT-013 |
| テスト名 | test_transaction_multiple_logs |
| 優先度 | 中 |
| 関連要件ID | FR-001 |

**前提条件**:
- データベース接続が確立されている

**テスト手順**:
1. トランザクションを開始
2. 複数のログを追加
3. コミット

**期待結果**:
- すべてのログが保存される

---

#### IT-014: トランザクションロールバック

| 項目 | 内容 |
|------|------|
| テストケースID | IT-014 |
| テスト名 | test_transaction_rollback |
| 優先度 | 中 |
| 関連要件ID | NFR-006 |

**前提条件**:
- データベース接続が確立されている

**テスト手順**:
1. トランザクションを開始
2. 有効なログを追加
3. 無効なログを追加（制約違反）
4. エラーを捕捉

**期待結果**:
- トランザクション内のすべての変更がロールバックされる
- 有効なログも保存されない

---

### 2.5 モデル登録テスト

#### IT-015: app/db/base.pyへのモデル登録確認

| 項目 | 内容 |
|------|------|
| テストケースID | IT-015 |
| テスト名 | test_models_registered_in_base |
| 優先度 | 高 |
| 関連要件ID | FR-006 |

**前提条件**:
- app/db/base.pyが存在する

**テスト手順**:
1. app.db.baseからインポートを試みる
2. __all__の内容を確認

**期待結果**:
- AIConversionLogがインポート可能
- ErrorLogがインポート可能
- __all__に両モデルが含まれている

---

## 3. テストケースマトリクス

### 要件カバレッジ

| 要件ID | テストケースID |
|--------|---------------|
| FR-001 | UT-001, UT-007, UT-015, UT-016, UT-017, UT-018, UT-019, UT-021, UT-022, UT-023, UT-025, UT-026, IT-002, IT-006, IT-013 |
| FR-002 | UT-002, UT-003, UT-011, UT-012, UT-013, UT-014 |
| FR-003 | UT-001, UT-004, UT-005, UT-006, IT-006 |
| FR-004 | UT-008, UT-009, UT-010, UT-020, IT-003 |
| FR-005 | IT-001, IT-005 |
| FR-006 | IT-015 |
| NFR-001 | UT-014, UT-024 |
| NFR-002 | UT-024 |
| NFR-003 | IT-004, IT-007, IT-008, IT-009, IT-010, IT-011, IT-012 |
| NFR-004 | UT-022, UT-023 |
| NFR-006 | IT-014 |
| AC-001 | UT-001 |
| AC-002 | UT-002 |
| AC-003 | UT-003 |
| AC-004 | UT-004, IT-007 |
| AC-005 | UT-008 |
| AC-006 | IT-001, IT-002, IT-003, IT-004 |
| AC-007 | UT-015, UT-016, UT-017, UT-018 |

### 優先度別テストケース数

| 優先度 | テストケース数 |
|--------|---------------|
| 高 | 12 |
| 中 | 15 |
| 低 | 12 |

---

## 4. テスト実行ガイド

### 4.1 前提条件

1. PostgreSQLテストデータベースが起動している
2. 環境変数 `TEST_DATABASE_URL` が設定されている
3. `pytest-asyncio` がインストールされている

### 4.2 実行コマンド

```bash
# 全テスト実行
cd backend
pytest tests/test_models_logs.py tests/test_hash_utils.py tests/test_logs_integration.py -v

# ユニットテストのみ
pytest tests/test_models_logs.py tests/test_hash_utils.py -v

# 統合テストのみ
pytest tests/test_logs_integration.py -v

# 優先度高のテストのみ（マーカー使用時）
pytest -m "priority_high" -v

# カバレッジレポート付き
pytest tests/test_models_logs.py tests/test_hash_utils.py tests/test_logs_integration.py --cov=app/models --cov-report=html
```

### 4.3 期待されるカバレッジ

| ファイル | 目標カバレッジ |
|---------|---------------|
| app/models/ai_conversion_logs.py | 90%以上 |
| app/models/error_logs.py | 90%以上 |
| ハッシュ化ユーティリティ | 95%以上 |

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 担当者 |
|------|----------|---------|-------|
| 2025-11-22 | 1.0 | 初版作成 | TDDテストケース設計担当者 |
