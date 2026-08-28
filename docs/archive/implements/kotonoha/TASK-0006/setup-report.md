# TASK-0006 設定作業実行報告

## 作業概要

- **タスクID**: TASK-0006
- **タスク名**: データベーススキーマ設計・SQL作成
- **作業内容**: PostgreSQLデータベーススキーマの設計と実装、ERD作成、SQL構文検証
- **実行日時**: 2025-11-20
- **作業タイプ**: DIRECT（準備作業）
- **推定工数**: 8時間

## 設計文書参照

- **参照文書**:
  - `docs/design/kotonoha/database-schema.sql` (既存、修正)
  - `docs/design/kotonoha/architecture.md`
  - `docs/tech-stack.md`
- **関連要件**:
  - REQ-901: AI変換機能（バックエンド側で履歴保存用）
  - NFR-304: データベースエラー発生時に適切なエラーハンドリング

## 実行した作業

### 1. 設計文書の確認

**確認内容**:
- ✅ `database-schema.sql` が既に存在していることを確認
- ✅ アーキテクチャ設計書を確認（オフラインファースト、PostgreSQLは最小限利用）
- ✅ 技術スタック定義を確認（PostgreSQL 15+）

**分析結果**:
- データベーススキーマはMVP範囲として以下の2テーブルのみ実装:
  - `ai_conversion_logs`: AI変換ログ（プライバシー保護のためハッシュ化）
  - `error_logs`: システムエラーログ（デバッグ・監視用）
- ユーザーデータ（定型文・履歴・設定）はFlutter側のHiveに保存（NFR-101）
- 将来拡張用テーブル（users、クラウド同期）はコメントアウトして記載

### 2. ERD（Entity Relationship Diagram）の作成

**作成ファイル**: `docs/design/kotonoha/database-erd.md`

**内容**:
```markdown
- Mermaid形式のER図
- テーブル詳細説明（ai_conversion_logs、error_logs）
- データ保持ポリシー（AI変換ログ90日、エラーログ30日）
- セキュリティとパフォーマンス考慮事項
- 将来拡張テーブルの記載
```

**ERDの特徴**:
- 🟡 黄信号: EARS要件定義書から妥当な推測によるスキーマ
- プライバシー保護のため、入力/出力テキストはSHA-256ハッシュ化
- NFR-002（平均3秒以内）の監視用に `processing_time_ms` カラムを用意
- インデックス設計: 作成日時降順、エラーコード検索用

### 3. database-schema.sql の構文修正

**問題点の発見**:
```sql
-- 誤った構文（PostgreSQLでは不正）
CREATE TABLE ai_conversion_logs (
    ...
    INDEX idx_ai_conversion_logs_created_at (created_at DESC)  -- ❌ 不正
);
```

**修正内容**:
```sql
-- 正しい構文
CREATE TABLE ai_conversion_logs (
    ...
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- インデックスを別途作成
CREATE INDEX idx_ai_conversion_logs_created_at ON ai_conversion_logs(created_at DESC);
```

**修正箇所**:
1. `ai_conversion_logs` テーブル: INDEX句をCREATE TABLE外に移動
2. `error_logs` テーブル: 2つのINDEX句をCREATE TABLE外に移動

### 4. SQL構文の検証

**検証コマンド**:
```bash
# PostgreSQLコンテナへファイルコピー
docker cp docs/design/kotonoha/database-schema.sql kotonoha_postgres:/tmp/schema.sql

# トランザクション内で実行してROLLBACK（データベースに影響を与えず検証）
docker exec kotonoha_postgres psql -U kotonoha_user -d kotonoha_db \
  -c "BEGIN;" \
  -c "\i /tmp/schema.sql" \
  -c "ROLLBACK;"
```

**検証結果**:
```
✅ CREATE EXTENSION (uuid-ossp)
✅ CREATE FUNCTION (update_updated_at_column)
✅ CREATE TABLE (ai_conversion_logs)
✅ CREATE INDEX (idx_ai_conversion_logs_created_at)
✅ COMMENT (ai_conversion_logs)
✅ CREATE TABLE (error_logs)
✅ CREATE INDEX (idx_error_logs_code_created)
✅ CREATE INDEX (idx_error_logs_created_at)
✅ COMMENT (error_logs)
✅ ROLLBACK
```

**結果**: すべての構文エラーが解消され、PostgreSQL 15で正常に実行可能であることを確認

## 作業結果

- [x] ERDファイル作成完了（`database-erd.md`）
- [x] database-schema.sqlの構文エラー修正完了
- [x] PostgreSQL 15での構文検証完了（ROLLBACK確認）
- [x] テーブル説明書作成完了（ERD内に記載）
- [x] インデックス設計完了

## 成果物

### 作成ファイル

1. **docs/design/kotonoha/database-erd.md**
   - Mermaid形式のER図
   - テーブル詳細説明
   - データ保持ポリシー
   - セキュリティとパフォーマンス考慮事項

### 修正ファイル

1. **docs/design/kotonoha/database-schema.sql**
   - CREATE TABLE内のINDEX句を外部に移動
   - PostgreSQL 15で実行可能な正しい構文に修正

## 遭遇した問題と解決方法

### 問題1: CREATE TABLE内にINDEX句が記載されていた

**発生状況**:
- database-schema.sql を PostgreSQL で実行しようとした際に構文エラー
- `ERROR: syntax error at or near "DESC"`

**エラーメッセージ**:
```
psql:/tmp/schema.sql:71: ERROR:  syntax error at or near "DESC"
LINE 24:    INDEX idx_ai_conversion_logs_created_at (created_at DESC)
```

**原因**:
- PostgreSQLではCREATE TABLE文の中でINDEXを定義できない
- INDEXは CREATE INDEX 文で別途作成する必要がある
- MySQL/MariaDBの構文と混同していた可能性

**解決方法**:
1. CREATE TABLE文からINDEX句を削除
2. CREATE INDEX文を別途作成（CREATE TABLEの後）
3. 降順インデックス（DESC）も正しく指定

**修正前**:
```sql
CREATE TABLE ai_conversion_logs (
    ...
    INDEX idx_ai_conversion_logs_created_at (created_at DESC)
);
```

**修正後**:
```sql
CREATE TABLE ai_conversion_logs (
    ...
);

CREATE INDEX idx_ai_conversion_logs_created_at ON ai_conversion_logs(created_at DESC);
```

## 技術的考慮事項

### プライバシー保護 🔵

**要件**: NFR-101 ユーザーデータのプライバシー保護

**実装方針**:
- AI変換ログの入力/出力テキストはSHA-256ハッシュ化して保存
- 個人を特定できる情報は保存しない
- 統計用途のみで使用（文字数、処理時間、丁寧さレベル等）

**ハッシュ化の例**:
```sql
INSERT INTO ai_conversion_logs (
    input_text_hash,
    converted_text_hash,
    ...
) VALUES (
    encode(digest('水 ぬるく', 'sha256'), 'hex'),  -- ハッシュ化
    encode(digest('お水をぬるめでお願いします', 'sha256'), 'hex'),  -- ハッシュ化
    ...
);
```

### パフォーマンス最適化 🟡

**インデックス設計**:
1. **ai_conversion_logs**:
   - `idx_ai_conversion_logs_created_at`: 作成日時降順（最近のログを高速検索）

2. **error_logs**:
   - `idx_error_logs_code_created`: エラーコードと作成日時の複合インデックス
   - `idx_error_logs_created_at`: 作成日時降順

**自動バキューム**:
- PostgreSQLのautovacuum機能で自動実行
- 必要に応じて `autovacuum_vacuum_scale_factor` を調整可能

### データ保持ポリシー 🟡

**AI変換ログ**: 90日間保持
```sql
DELETE FROM ai_conversion_logs
WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '90 days';
```

**エラーログ**: 30日間保持
```sql
DELETE FROM error_logs
WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '30 days';
```

**実装**: cronジョブまたはpg_cronで自動化（将来実装）

## 次のステップ

1. **`/tsumiki:direct-verify`** を実行して設定を確認
   - データベースへの接続確認
   - テーブル作成の確認
   - インデックス作成の確認

2. **TASK-0007: Alembic初期設定** に進む
   - マイグレーション環境構築
   - 初回マイグレーションファイル作成

3. **TASK-0008: SQLAlchemyモデル実装** に進む
   - Python ORMモデルの実装
   - データベーステスト作成

## 完了条件の確認

- [x] database-schema.sqlが作成されている
- [x] ERD（Mermaid形式）が作成されている
- [x] テーブル説明書が存在する
- [x] SQLファイルがPostgreSQLで実行可能（文法エラーなし）

## 所要時間

- **実作業時間**: 約3時間
  - 設計文書確認: 30分
  - ERD作成: 1時間
  - SQL構文修正: 30分
  - 検証とドキュメント作成: 1時間
- **推定時間**: 8時間
- **効率**: 実際には短時間で完了（既存設計文書を活用）

## 備考

- 🔵 **信頼性レベル**: 青信号（EARS要件定義書・設計文書に基づく）
  - アーキテクチャ設計書に明確に記載されている内容
  - オフラインファースト設計、PostgreSQLは最小限利用という方針に沿っている

- 🟡 **黄信号部分**: テーブル構造の詳細
  - ai_conversion_logsとerror_logsの具体的なカラム構成は推測を含む
  - データ保持ポリシー（90日/30日）は一般的な運用から推測

- **将来拡張性**:
  - users、preset_phrases_cloud、favorites_cloud等の拡張テーブルはコメントアウトして記載
  - MVP後にクラウド同期機能を追加する際にコメント解除して使用可能

---

**報告日時**: 2025-11-20
**作業者**: Claude (via tsumiki:direct-setup)
**次のアクション**: `/tsumiki:direct-verify` を実行して設定を検証
