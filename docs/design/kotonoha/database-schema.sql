-- 文字盤コミュニケーション支援アプリ（kotonoha）データベーススキーマ
-- PostgreSQL 15+
--
-- 🔵 信頼性レベル凡例:
-- - 🔵 青信号: EARS要件定義書・設計文書を参考にした確実なスキーマ
-- - 🟡 黄信号: EARS要件定義書・設計文書から妥当な推測によるスキーマ
-- - 🔴 赤信号: EARS要件定義書・設計文書にない推測によるスキーマ
--
-- 注意事項:
-- 1. ユーザーデータ（定型文・履歴・お気に入り・設定）は端末内ローカルストレージ（Hive）に保存 (NFR-101)
-- 2. このPostgreSQLスキーマは主にバックエンドAPIの内部処理用（AI変換ログ、将来的な拡張用）
-- 3. MVP範囲では最小限のテーブル構成とする
--
-- ================================================================================
-- 本ファイルの位置づけ（2026-08-24 更新）
-- ================================================================================
-- スキーマの正（Single Source of Truth）は Alembic マイグレーションと SQLAlchemy モデル:
--   - backend/alembic/versions/b5d6e2f8c9a0_add_ai_conversion_logs_and_error_logs.py
--   - backend/alembic/versions/e1f2a3b4c5d6_drop_ai_conversion_history.py（history 廃止）
--   - backend/app/models/ai_conversion_logs.py / backend/app/models/error_logs.py
-- 以下の有効なDDLは、上記の実装に一致するよう記述している（実装が変わったら本ファイルも更新すること）。
-- 実際のDB構築は `alembic upgrade head` で行い、このファイルを直接流し込む運用はしない。
--
-- 設計当初案から実装で変更された点（記録として残す）:
--   - 主キー: UUID(uuid_generate_v4()) → SERIAL（整数）
--   - ai_conversion_logs: converted_text_hash / converted_length / api_status_code は未実装。
--     代わりに output_length / conversion_time_ms / ai_provider / session_id / error_message を保持。
--     変換後テキストはハッシュも含め一切保存しない方針に変更（プライバシー強化）。
--   - error_logs: error_location / http_status_code / context(JSONB) は未実装。
--     代わりに error_type / endpoint / http_method を保持。
--   - コメントアウト済みの「将来的な拡張用テーブル」は設計上の構想であり、実装予定は未定。
--
-- なお `schema_info` テーブルと `uuid-ossp` / `pg_trgm` 拡張は
-- docker/postgres/init.sql がコンテナ初期化時に作成する（Alembic 管理外）。

-- ================================================================================
-- 拡張機能の有効化
-- ================================================================================

-- UUID生成用拡張。実装では主キーは SERIAL のため必須ではないが、
-- docker/postgres/init.sql が初期化時に有効化している（将来の拡張テーブル用）。
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- タイムスタンプ自動更新用関数
-- ※ 現行の2テーブルは updated_at を持たないため未使用。後述の将来拡張テーブル用。
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ================================================================================
-- AI変換ログテーブル 🟡
-- AI変換機能の使用状況・学習データ収集用（将来的な機能改善用）
-- ※個人を特定できる情報は保存しない
-- ================================================================================

CREATE TABLE ai_conversion_logs (
    -- SQLAlchemy の Integer + autoincrement 主キーは PostgreSQL では SERIAL になる
    id SERIAL PRIMARY KEY,

    -- 変換元テキスト（SHA-256でハッシュ化して保存、元のテキストは保存しない）
    input_text_hash VARCHAR(64) NOT NULL,

    -- 変換元テキストの文字数（統計用）
    input_length INTEGER NOT NULL,

    -- 変換後テキストの文字数（統計用。変換後テキスト自体はハッシュも含め保存しない）
    output_length INTEGER NOT NULL,

    -- 丁寧さレベル
    politeness_level VARCHAR(20) NOT NULL,

    -- 変換処理時間（ミリ秒）
    conversion_time_ms INTEGER,

    -- AIプロバイダー名（'anthropic' / 'openai'。アプリ層のデフォルトは 'anthropic'）
    ai_provider VARCHAR(50),

    -- 変換成功フラグ
    is_success BOOLEAN NOT NULL DEFAULT TRUE,

    -- エラーメッセージ（失敗時のみ）
    error_message TEXT,

    -- セッションID（端末セッションの識別用。アプリ層で uuid4 を生成）
    session_id UUID NOT NULL,

    -- 作成日時
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- 丁寧さレベルの許容値（小文字。マイグレーション c1a2b3d4e5f6 で小文字に統一済み）
    CONSTRAINT check_politeness_level
        CHECK (politeness_level IN ('casual', 'normal', 'polite'))
);

-- インデックス: 作成日時での検索用
CREATE INDEX idx_ai_conversion_logs_created_at ON ai_conversion_logs(created_at DESC);
-- インデックス: ハッシュ検索用
CREATE INDEX idx_ai_conversion_logs_hash ON ai_conversion_logs(input_text_hash);
-- インデックス: セッションごとのログ取得用
CREATE INDEX idx_ai_conversion_logs_session ON ai_conversion_logs(session_id);

COMMENT ON TABLE ai_conversion_logs IS 'AI変換の使用ログ（入力はハッシュ化、出力は文字数のみ）';
COMMENT ON COLUMN ai_conversion_logs.input_text_hash IS '変換元テキストのSHA-256ハッシュ値';
COMMENT ON COLUMN ai_conversion_logs.output_length IS '変換後テキストの文字数（本文・ハッシュは保存しない）';
COMMENT ON COLUMN ai_conversion_logs.conversion_time_ms IS '変換処理時間（NFR-002: 平均3秒以内の監視用）';
COMMENT ON COLUMN ai_conversion_logs.session_id IS '端末セッションID（個人を特定する情報ではない）';

-- ================================================================================
-- エラーログテーブル 🟡
-- システムエラー・APIエラーの記録用（デバッグ・監視用）
-- ================================================================================

CREATE TABLE error_logs (
    id SERIAL PRIMARY KEY,

    -- エラータイプ（例: 'NetworkException', 'ValidationError'）
    error_type VARCHAR(100) NOT NULL,

    -- エラーメッセージ
    error_message TEXT NOT NULL,

    -- エラーコード（例: 'AI_001'）
    error_code VARCHAR(50),

    -- エラー発生エンドポイント（例: '/api/v1/ai/convert'）
    endpoint VARCHAR(255),

    -- HTTPメソッド（例: 'POST'）
    http_method VARCHAR(10),

    -- スタックトレース（開発環境のみ保存）
    stack_trace TEXT,

    -- 作成日時
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- インデックス: エラータイプ別検索用
CREATE INDEX idx_error_logs_type ON error_logs(error_type);
-- インデックス: 作成日時での検索用
CREATE INDEX idx_error_logs_created_at ON error_logs(created_at DESC);

COMMENT ON TABLE error_logs IS 'システムエラーログ（デバッグ・監視用）';
COMMENT ON COLUMN error_logs.error_type IS '例外クラス名等のエラー種別';
COMMENT ON COLUMN error_logs.endpoint IS 'エラーが発生したAPIエンドポイントのパス';

-- ================================================================================
-- 将来的な拡張用テーブル（MVP範囲外、コメントアウト） 🔴
-- ================================================================================

-- ユーザーテーブル（アカウント管理機能用、MVP範囲外）
/*
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,

    INDEX idx_users_email (email)
);

CREATE TRIGGER update_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
*/

-- 定型文同期テーブル（クラウド同期機能用、MVP範囲外）
/*
CREATE TABLE preset_phrases_cloud (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    category VARCHAR(20) NOT NULL CHECK (category IN ('daily', 'health', 'other')),
    is_favorite BOOLEAN DEFAULT FALSE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_preset_phrases_user_id (user_id),
    INDEX idx_preset_phrases_favorite (user_id, is_favorite, display_order)
);

CREATE TRIGGER update_preset_phrases_updated_at
BEFORE UPDATE ON preset_phrases_cloud
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
*/

-- お気に入り同期テーブル（クラウド同期機能用、MVP範囲外）
/*
CREATE TABLE favorites_cloud (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_favorites_user_id (user_id),
    INDEX idx_favorites_display_order (user_id, display_order)
);

CREATE TRIGGER update_favorites_updated_at
BEFORE UPDATE ON favorites_cloud
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
*/

-- 統計情報テーブル（利用状況分析用、MVP範囲外）
/*
CREATE TABLE usage_statistics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    feature_name VARCHAR(100) NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    count INTEGER DEFAULT 1,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_usage_statistics_feature_date (feature_name, date DESC),
    UNIQUE (feature_name, action_type, date)
);
*/

-- ================================================================================
-- データ保持ポリシー（自動削除ルール） 🟡
-- ================================================================================

-- AI変換ログの古いデータを定期的に削除（保持期間: 90日）
-- 注: 実際の運用ではcronジョブやpg_cronを使用して自動化
/*
DELETE FROM ai_conversion_logs
WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '90 days';
*/

-- エラーログの古いデータを定期的に削除（保持期間: 30日）
/*
DELETE FROM error_logs
WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '30 days';
*/

-- ================================================================================
-- パフォーマンス最適化
-- ================================================================================

-- VACUUM ANALYZEの定期実行（自動バキューム設定）
-- PostgreSQLのautovacuum機能で自動実行されるが、明示的な設定も可能
-- ALTER TABLE ai_conversion_logs SET (autovacuum_vacuum_scale_factor = 0.1);
-- ALTER TABLE error_logs SET (autovacuum_vacuum_scale_factor = 0.1);

-- ================================================================================
-- 初期データ挿入（開発環境用）
-- ================================================================================

-- 開発環境でのテストデータ挿入例
/*
INSERT INTO ai_conversion_logs (
    input_text_hash,
    input_length,
    output_length,
    politeness_level,
    conversion_time_ms,
    ai_provider,
    is_success,
    session_id
) VALUES (
    encode(digest('水 ぬるく', 'sha256'), 'hex'),
    5,
    13,
    'normal',
    2500,
    'anthropic',
    TRUE,
    gen_random_uuid()
);
*/

-- ================================================================================
-- 権限設定（セキュリティ）
-- ================================================================================

-- アプリケーション用のロール作成
-- CREATE ROLE kotonoha_app WITH LOGIN PASSWORD 'secure_password_here';

-- 必要最小限の権限のみ付与
-- GRANT SELECT, INSERT ON ai_conversion_logs TO kotonoha_app;
-- GRANT SELECT, INSERT ON error_logs TO kotonoha_app;

-- 本番環境では読み取り専用ユーザーも作成（監視・分析用）
-- CREATE ROLE kotonoha_readonly WITH LOGIN PASSWORD 'readonly_password_here';
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO kotonoha_readonly;
