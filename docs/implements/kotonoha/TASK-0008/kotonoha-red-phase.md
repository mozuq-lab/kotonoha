# TDD Redフェーズ設計: SQLAlchemyモデル実装（TASK-0008）

## 概要

- **作成日時**: 2025-11-20
- **フェーズ**: Red（失敗するテスト作成）
- **対象機能**: SQLAlchemyモデル実装（AIConversionHistory、ベースクラス、セッション管理）

## テスト設計方針

### テストフレームワーク

- **pytest 8.3.5**: Pythonのデファクトスタンダードなテストフレームワーク
- **pytest-asyncio 0.25.2**: 非同期テスト対応
- **pytest-cov**: カバレッジ測定（目標80%以上）

### テストファイル構成

1. **`backend/tests/conftest.py`** - pytest設定・フィクスチャ
   - テスト用データベース接続設定
   - 非同期エンジン・セッションメーカーのフィクスチャ
   - 各テストケース用のデータベースセッションフィクスチャ

2. **`backend/tests/test_models.py`** - モデル層のテストケース（18件）
   - カテゴリB: モデルインスタンス化テスト（6件）
   - カテゴリC: CRUD操作テスト（5件）
   - カテゴリD: トランザクション管理テスト（2件）
   - カテゴリE: 異常系・境界値テスト（5件）

3. **`backend/tests/test_db_connection.py`** - データベース接続テスト（4件）
   - データベース接続テスト
   - 接続エラーハンドリングテスト
   - トランザクション開始機能テスト
   - セッションクローズ機能テスト

4. **`backend/tests/test_error_handling.py`** - エラーハンドリングテスト（6件）
   - NOT NULL制約違反テスト
   - Enum型バリデーションテスト
   - トランザクションロールバックテスト

## テストケース一覧（28件）

### カテゴリB: モデルインスタンス化テスト（6件）

| No | テスト名 | 目的 | 信頼性 |
|----|----------|------|--------|
| B-1 | `test_ai_conversion_history_instantiation_required_fields_only` | 必須フィールドのみでインスタンス化 | 🔵 |
| B-2 | `test_ai_conversion_history_instantiation_all_fields` | すべてのフィールドでインスタンス化 | 🔵 |
| B-3 | `test_ai_conversion_history_nullable_fields` | NULL許可フィールドの省略 | 🔵 |
| B-4 | `test_politeness_level_casual` | Enum値 CASUAL の使用 | 🔵 |
| B-5 | `test_politeness_level_normal` | Enum値 NORMAL の使用 | 🔵 |
| B-6 | `test_politeness_level_polite` | Enum値 POLITE の使用 | 🔵 |

### カテゴリC: CRUD操作テスト（5件）

| No | テスト名 | 目的 | 信頼性 |
|----|----------|------|--------|
| C-2 | `test_create_ai_conversion_history_record` | レコードのデータベース保存 | 🔵 |
| C-3 | `test_read_ai_conversion_history_record` | レコードのクエリ取得 | 🔵 |
| C-4 | `test_filter_by_user_session_id` | user_session_idでの絞り込み検索 | 🔵 |
| C-5 | `test_order_by_created_at_desc` | created_at降順ソート | 🔵 |
| C-6 | `test_limit_records` | LIMIT句による件数制限 | 🔵 |

### カテゴリD: トランザクション管理テスト（2件）

| No | テスト名 | 目的 | 信頼性 |
|----|----------|------|--------|
| D-1 | `test_transaction_commit` | トランザクションの正常コミット | 🔵 |
| D-2 | `test_transaction_rollback` | エラー時のトランザクションロールバック | 🔵 |

### カテゴリE: 異常系・境界値テスト（5件）

| No | テスト名 | 目的 | 信頼性 |
|----|----------|------|--------|
| E-2 | `test_empty_string_input` | 空文字列の入力 | 🔵 |
| E-3 | `test_very_long_text_input` | 非常に長いテキスト（10,000文字） | 🟡 |
| E-4 | `test_conversion_time_ms_zero` | conversion_time_ms=0（境界値） | 🔵 |
| E-5 | `test_conversion_time_ms_large_value` | conversion_time_ms=999999（大きい値） | 🟡 |
| E-6 | `test_conversion_time_ms_negative_value` | conversion_time_ms=-1（負の値） | 🟡 |

### データベース接続テスト（4件）

| No | テスト名 | 目的 | 信頼性 |
|----|----------|------|--------|
| C-1 | `test_database_connection` | 非同期セッションの作成と接続 | 🔵 |
| D-3 | `test_database_connection_error` | データベース接続エラー時のハンドリング | 🟡 |
| - | `test_session_begin_transaction` | トランザクション開始機能 | 🔵 |
| - | `test_session_close` | セッションクローズ機能 | 🔵 |

### エラーハンドリングテスト（6件）

| No | テスト名 | 目的 | 信頼性 |
|----|----------|------|--------|
| D-4 | `test_not_null_constraint_violation` | NOT NULL制約違反（input_text） | 🔵 |
| - | `test_converted_text_not_null_constraint_violation` | NOT NULL制約違反（converted_text） | 🔵 |
| E-1 | `test_invalid_politeness_level_enum_value` | 不正なEnum値の設定 | 🟡 |
| - | `test_enum_string_assignment_prevention` | Enum型に文字列を直接代入 | 🟡 |
| - | `test_rollback_after_integrity_error` | IntegrityError発生後のロールバック | 🔵 |
| - | `test_multiple_integrity_errors` | 複数のNOT NULL制約違反 | 🔵 |

## 日本語コメント指針

### テストケース開始時のコメント

```python
# 【テスト目的】: AIConversionHistoryモデルの基本的なインスタンス化機能を確認する
# 【テスト内容】: 必須フィールド（input_text, converted_text, politeness_level）のみでインスタンスを作成
# 【期待される動作】: インスタンスが正常に作成され、各フィールドの値が正しく設定される
# 🔵 この内容は要件定義書（line 166-177）に基づく
```

### Given（準備フェーズ）のコメント

```python
# 【テストデータ準備】: 実際のユースケースを想定した日本語テキストを用意
# 【初期条件設定】: データベーステーブルが存在し、セッションが利用可能な状態
```

### When（実行フェーズ）のコメント

```python
# 【実際の処理実行】: AIConversionHistoryモデルのインスタンスを作成
# 【処理内容】: 必須フィールドを指定してコンストラクタを呼び出す
```

### Then（検証フェーズ）のコメント

```python
# 【結果検証】: インスタンスが正常に作成されたことを確認
# 【期待値確認】: 各フィールドの値が入力値と一致することを検証
# 【品質保証】: モデルの基本機能が正しく実装されていることを保証
```

### 各expectステートメントのコメント

```python
# 【検証項目】: input_textフィールドの値が正しく設定されているか
# 🔵 要件定義書（line 54）に基づくNOT NULL制約フィールドの検証
assert record.input_text == "水 ぬるく"
```

## 期待される失敗内容

### 主要なエラーメッセージ

#### 1. モジュールインポートエラー

```
ModuleNotFoundError: No module named 'app.models.ai_conversion_history'
```

**原因**: 実装ファイル（`backend/app/models/ai_conversion_history.py`）が未作成

**影響範囲**: すべてのテストケース

#### 2. クラス未定義エラー

```
AttributeError: module 'app.models' has no attribute 'AIConversionHistory'
```

**原因**: `AIConversionHistory` モデルクラスが未定義

**影響範囲**: すべてのモデルインスタンス化テスト、CRUD操作テスト

#### 3. Enum未定義エラー

```
AttributeError: module 'app.models' has no attribute 'PolitenessLevel'
```

**原因**: `PolitenessLevel` Enumが未定義

**影響範囲**: Enum関連のテストケース

#### 4. データベースセッションエラー

```
ModuleNotFoundError: No module named 'app.db.session'
```

**原因**: セッション管理ファイル（`backend/app/db/session.py`）が未作成

**影響範囲**: CRUD操作テスト、トランザクション管理テスト

## テスト実行コマンド

### 全テスト実行（失敗を確認）

```bash
cd backend

# すべてのテストを実行
pytest

# 詳細な出力
pytest -v

# 特定のファイルのみ実行
pytest tests/test_models.py -v
pytest tests/test_db_connection.py -v
pytest tests/test_error_handling.py -v
```

### カバレッジ測定（実装後）

```bash
# カバレッジ測定
pytest --cov=app --cov-report=html --cov-report=term-missing

# HTMLレポート確認
open htmlcov/index.html
```

## Greenフェーズへの要求事項

### 実装すべきファイル

1. **`backend/app/db/base_class.py`** - ベースモデルクラス
   ```python
   from sqlalchemy.orm import as_declarative, declared_attr

   @as_declarative()
   class Base:
       @declared_attr
       def __tablename__(cls) -> str:
           return cls.__name__.lower()
   ```

2. **`backend/app/models/ai_conversion_history.py`** - AI変換履歴モデル
   - `AIConversionHistory` モデルクラス
   - `PolitenessLevel` Enum（CASUAL, NORMAL, POLITE）
   - フィールド定義（id, input_text, converted_text, politeness_level, created_at, conversion_time_ms, user_session_id）

3. **`backend/app/db/session.py`** - データベースセッション管理
   - `create_async_engine` でエンジン作成
   - `async_sessionmaker` でセッションメーカー作成
   - `get_db()` 依存性注入関数

4. **`backend/app/db/base.py`** - モデル集約ファイル
   - Alembic自動マイグレーション用
   - すべてのモデルをインポート

### 実装時の注意事項

1. **SQLAlchemy 2.x対応**
   - `as_declarative()` デコレータを使用
   - 非同期対応（`AsyncSession`, `create_async_engine`）

2. **型ヒント必須**
   - すべてのフィールドに型ヒントを付ける
   - Python 3.10+ の型ヒント機能を活用

3. **NOT NULL制約**
   - `input_text`, `converted_text`, `politeness_level` は `nullable=False`
   - `conversion_time_ms`, `user_session_id` は `nullable=True`

4. **Enum定義**
   - Python標準の`enum.Enum`を使用
   - SQLAlchemyの`Enum`カラムで使用

## 品質判定

### テストコードの品質: ✅ 高品質

- ✅ **テスト実行**: すべて失敗することを確認済み（期待通り）
- ✅ **期待値**: 明確で具体的
- ✅ **アサーション**: 適切
- ✅ **実装方針**: 明確（Greenフェーズへの要求事項が明記されている）

### 網羅性: ✅ 十分

- **正常系**: 13ケース（B-1～B-6, C-2～C-6, D-1）
- **異常系**: 10ケース（D-2, D-3, D-4, E-1, エラーハンドリング系）
- **境界値**: 5ケース（E-2～E-6）
- **合計**: 28ケース（目標10件以上を達成）

### 日本語コメント: ✅ 充実

- すべてのテストケースに【テスト目的】【テスト内容】【期待される動作】を記載
- 各expectステートメントに【検証項目】コメントを記載
- 🔵🟡 信頼性レベルを明記

## 次のステップ

次のお勧めステップ: `/tsumiki:tdd-green` でGreenフェーズ（最小実装）を開始します。

Greenフェーズでは、以下の実装を行います：

1. ベースモデルクラスの定義
2. AI変換履歴モデルの実装
3. データベースセッション管理の実装
4. モデル集約ファイルの作成
5. すべてのテストが成功することを確認

---

## 更新履歴

- **2025-11-20**: Redフェーズ完了（28個のテストケースを作成）
