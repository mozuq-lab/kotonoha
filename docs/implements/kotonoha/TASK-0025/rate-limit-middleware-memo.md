# TDD開発メモ: rate-limit-middleware

## 概要

- 機能名: レート制限ミドルウェア
- 開発開始: 2025-11-22
- 現在のフェーズ: Red（失敗するテスト作成完了）

## 関連ファイル

- 元タスクファイル: `docs/tasks/kotonoha-phase1.md`（TASK-0025）
- 要件定義: `docs/implements/kotonoha/TASK-0025/rate-limit-middleware-requirements.md`
- テストケース定義: `docs/implements/kotonoha/TASK-0025/rate-limit-middleware-testcases.md`
- 実装ファイル: `backend/app/core/rate_limit.py`（未作成）
- テストファイル: `backend/tests/test_api/test_rate_limit.py`

## Redフェーズ（失敗するテスト作成）

### 作成日時

2025-11-22

### テストケース

作成したテストケース（17件）:

#### 正常系テスト（5件）
| ID | テスト名 | 信頼性 |
|----|---------|--------|
| TC-001 | 正常リクエストテスト（制限内） | 🔵 |
| TC-002 | X-RateLimitヘッダーテスト | 🔵 |
| TC-003 | 制限リセットテスト | 🔵 |
| TC-004 | IP別制限テスト | 🔵 |
| TC-005 | 非AI系エンドポイント除外テスト | 🔵 |

#### 異常系テスト（4件）
| ID | テスト名 | 信頼性 |
|----|---------|--------|
| TC-101 | レート制限超過テスト | 🔵 |
| TC-102 | Retry-Afterヘッダーテスト | 🔵 |
| TC-103 | エラーレスポンス形式テスト | 🔵 |
| TC-104 | 複数エンドポイントでのレート制限テスト | 🟡 |

#### 境界値テスト（4件）
| ID | テスト名 | 信頼性 |
|----|---------|--------|
| TC-201 | 境界値テスト - ちょうど制限内 | 🔵 |
| TC-202 | 境界値テスト - 制限超過 | 🔵 |
| TC-203 | 境界値テスト - ウィンドウリセット境界 | 🟡 |
| TC-204 | 境界値テスト - Retry-After値の範囲 | 🟡 |

#### エッジケーステスト（4件）
| ID | テスト名 | 信頼性 |
|----|---------|--------|
| TC-301 | X-Forwarded-Forヘッダーテスト | 🔵 |
| TC-302 | 不正IPフォールバックテスト | 🟡 |
| TC-303 | 複数X-Forwarded-Forヘッダーテスト | 🟡 |
| TC-304 | 高頻度リクエストテスト | 🟡 |

### テストコード

テストファイル: `backend/tests/test_api/test_rate_limit.py`

```python
# 主要なテストケースの概要

# TC-001: 正常リクエストテスト
# - AI変換エンドポイントへの最初のリクエストが成功することを確認
# - 期待: HTTPステータスコード200

# TC-101: レート制限超過テスト
# - 10秒以内に2回目のリクエストを送信した場合
# - 期待: 1回目は200、2回目は429

# TC-102: Retry-Afterヘッダーテスト
# - 429レスポンスにRetry-Afterヘッダーが含まれることを確認
# - 期待: 1-10秒の範囲内の値

# TC-103: エラーレスポンス形式テスト
# - 429エラーのレスポンス形式が仕様に準拠していることを確認
# - 期待: success=false, error.code="RATE_LIMIT_EXCEEDED"
```

### 期待される失敗

テスト実行結果（2025-11-22）:

```
17 tests collected
- 16 FAILED（AI変換エンドポイント未実装のため404エラー）
- 1 PASSED（TC-005: 非AI系エンドポイント除外テスト - /healthは既存）
```

失敗の理由:
1. **AI変換エンドポイント未実装**: `/api/v1/ai/convert` が404を返す
2. **レート制限ミドルウェア未実装**: X-RateLimit-* ヘッダーが付与されない
3. **カスタムエラーハンドラー未実装**: 429エラー時の標準レスポンス形式が未定義

### 次のフェーズへの要求事項

Greenフェーズで実装すべき内容:

#### 1. slowapiライブラリのインストール
```bash
pip install slowapi==0.1.9
```
`requirements.txt` に追加する

#### 2. レート制限設定ファイル作成
`backend/app/core/rate_limit.py`:
- Limiter初期化（key_func=get_client_ip）
- AI_RATE_LIMIT = "1/10seconds"
- get_client_ip関数（X-Forwarded-For対応）

#### 3. カスタムエラーハンドラー実装
- RateLimitExceededエラーをキャッチ
- 標準エラーレスポンス形式で429を返す
- Retry-Afterヘッダーを設定

#### 4. main.pyへの統合
- CORSミドルウェアの後にレート制限を追加
- エラーハンドラーを登録

#### 5. AI変換エンドポイントへのデコレーター適用
`backend/app/api/v1/endpoints/ai.py`:
- @limiter.limit(AI_RATE_LIMIT) デコレーターを追加
- /convert と /regenerate の両方に適用

## Greenフェーズ（最小実装）

### 実装日時

（未実施）

### 実装方針

（未定義）

### 実装コード

（未実装）

### テスト結果

（未実行）

### 課題・改善点

（未定義）

## Refactorフェーズ（品質改善）

### リファクタ日時

（未実施）

### 改善内容

（未定義）

### セキュリティレビュー

（未実施）

### パフォーマンスレビュー

（未実施）

### 最終コード

（未完成）

### 品質評価

（未評価）
