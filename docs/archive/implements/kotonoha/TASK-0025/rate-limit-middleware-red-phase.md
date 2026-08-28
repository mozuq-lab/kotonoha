# TASK-0025: レート制限ミドルウェア実装 - Redフェーズ設計書

## 1. 概要

### 1.1 フェーズ情報
- **タスクID**: TASK-0025
- **機能名**: レート制限ミドルウェア
- **フェーズ**: Red（失敗するテスト作成）
- **作成日**: 2025-11-22
- **ステータス**: 完了

### 1.2 目的
TDDのRedフェーズとして、レート制限ミドルウェアの動作を検証する失敗するテストを作成する。

## 2. テスト設計

### 2.1 テストファイル構成
```
backend/tests/test_api/
└── test_rate_limit.py    # レート制限テスト（17テストケース）
```

### 2.2 テストカテゴリ別構成

| カテゴリ | テスト数 | 信頼性 |
|---------|---------|--------|
| 正常系テスト | 5件 | 🔵×5 |
| 異常系テスト | 4件 | 🔵×3, 🟡×1 |
| 境界値テスト | 4件 | 🔵×2, 🟡×2 |
| エッジケーステスト | 4件 | 🔵×1, 🟡×3 |
| **合計** | **17件** | |

## 3. テストケース詳細

### 3.1 正常系テスト

#### TC-001: 正常リクエストテスト（制限内）
```python
# 目的: 制限内の最初のリクエストが正常に処理されることを確認
# 入力: POST /api/v1/ai/convert {"input_text": "水 ぬるく", "politeness_level": "normal"}
# 期待結果: HTTPステータスコード200
# 信頼性: 🔵（要件定義書 4.1 ユースケース1に基づく）
```

#### TC-002: X-RateLimitヘッダーテスト
```python
# 目的: レスポンスにレート制限情報ヘッダーが付与されることを確認
# 期待結果:
#   - X-RateLimit-Limit: 1
#   - X-RateLimit-Remaining: 0
#   - X-RateLimit-Reset: [UNIXタイムスタンプ]
# 信頼性: 🔵（要件定義書 2.2 出力値に基づく）
```

#### TC-003: 制限リセットテスト
```python
# 目的: 10秒経過後に制限がリセットされることを確認
# シナリオ: 1回目リクエスト → 10秒待機 → 2回目リクエスト
# 期待結果: 両方とも200 OK
# 信頼性: 🔵（要件定義書 4.2 エッジケース1に基づく）
```

#### TC-004: IP別制限テスト
```python
# 目的: IPアドレスごとに独立した制限が適用されることを確認
# シナリオ: IP A からリクエスト → IP B からリクエスト
# 期待結果: 両方とも200 OK
# 信頼性: 🔵（要件定義書 4.2 エッジケース2に基づく）
```

#### TC-005: 非AI系エンドポイント除外テスト
```python
# 目的: /healthなどのエンドポイントにレート制限が適用されないことを確認
# シナリオ: /healthに10回連続リクエスト
# 期待結果: 全て200 OK、X-RateLimitヘッダーなし
# 信頼性: 🔵（要件定義書 3.5 API制約に基づく）
```

### 3.2 異常系テスト

#### TC-101: レート制限超過テスト
```python
# 目的: 連続リクエストで429エラーが返されることを確認
# シナリオ: 1回目リクエスト → 即座に2回目リクエスト
# 期待結果: 1回目は200、2回目は429
# 信頼性: 🔵（要件定義書 4.1 ユースケース2に基づく）
```

#### TC-102: Retry-Afterヘッダーテスト
```python
# 目的: 429レスポンスにRetry-Afterヘッダーが含まれることを確認
# 期待結果: Retry-After: 1-10秒の範囲内
# 信頼性: 🔵（要件定義書 2.2 出力値に基づく）
```

#### TC-103: エラーレスポンス形式テスト
```python
# 目的: 429エラーのレスポンス形式が仕様に準拠していることを確認
# 期待結果:
#   {
#     "success": false,
#     "data": null,
#     "error": {
#       "code": "RATE_LIMIT_EXCEEDED",
#       "message": "リクエスト数が上限に達しました...",
#       "status_code": 429,
#       "retry_after": [残り秒数]
#     }
#   }
# 信頼性: 🔵（要件定義書 2.2 出力値、api-endpoints.mdに基づく）
```

#### TC-104: 複数エンドポイントでのレート制限テスト
```python
# 目的: /convertと/regenerateで共通の制限が適用されることを確認
# シナリオ: /convert → /regenerate
# 期待結果: /convertは200、/regenerateは429
# 信頼性: 🟡（要件定義書から妥当な推測）
```

### 3.3 境界値テスト

#### TC-201: 境界値テスト - ちょうど制限内
```python
# 目的: 制限ちょうどのリクエストが許可されることを確認
# 期待結果: 200 OK、X-RateLimit-Remaining: 0
# 信頼性: 🔵（要件定義書 2.1 レート制限設定に基づく）
```

#### TC-202: 境界値テスト - 制限超過
```python
# 目的: 制限を1つ超過すると拒否されることを確認
# 期待結果: 2回目のリクエストは429
# 信頼性: 🔵（要件定義書 4.1 ユースケース2に基づく）
```

#### TC-203: 境界値テスト - ウィンドウリセット境界
```python
# 目的: 正確に10秒でリセットされることを確認
# シナリオ: 9.9秒後 → 拒否、10.1秒後 → 許可
# 信頼性: 🟡（妥当な推測 - ウィンドウ方式の詳細動作）
```

#### TC-204: 境界値テスト - Retry-After値の範囲
```python
# 目的: Retry-After値が1-10秒の範囲内であることを確認
# 期待結果: 1 <= retry_after <= 10
# 信頼性: 🟡（妥当な推測）
```

### 3.4 エッジケーステスト

#### TC-301: X-Forwarded-Forヘッダーテスト
```python
# 目的: プロキシ経由のIPアドレス取得が正しいことを確認
# シナリオ: X-Forwarded-For: 192.168.1.100 で2回リクエスト
# 期待結果: 2回目は429（同じIPとして認識）
# 信頼性: 🔵（要件定義書 4.2 エッジケース3に基づく）
```

#### TC-302: 不正IPフォールバックテスト
```python
# 目的: IPが取得できない場合のフォールバック動作を確認
# シナリオ: X-Forwarded-For: "" でリクエスト
# 期待結果: システムはクラッシュせず応答
# 信頼性: 🟡（要件定義書 4.3 エラーケース1に基づく）
```

#### TC-303: 複数X-Forwarded-Forヘッダーテスト
```python
# 目的: 複数IPがX-Forwarded-Forに含まれる場合の処理を確認
# シナリオ: X-Forwarded-For: "192.168.1.100, 10.0.0.1" で1回目
#          X-Forwarded-For: "192.168.1.100" で2回目
# 期待結果: 2回目は429（最初のIPが同じ）
# 信頼性: 🟡（X-Forwarded-Forの標準仕様に基づく妥当な推測）
```

#### TC-304: 高頻度リクエストテスト
```python
# 目的: 大量の連続リクエストでシステムが安定動作することを確認
# シナリオ: 同一IPから100連続リクエスト
# 期待結果: 1回目は200、2-100回目は429、全リクエストに応答
# 信頼性: 🟡（要件定義書 7.3 エッジケーステスト TC-203に基づく）
```

## 4. テスト実行結果

### 4.1 実行コマンド
```bash
cd backend
pytest tests/test_api/test_rate_limit.py -v --tb=short
```

### 4.2 結果サマリー
```
=============================== test session starts ===============================
collected 17 items

tests/test_api/test_rate_limit.py::test_tc001_正常リクエストテスト_制限内 FAILED
tests/test_api/test_rate_limit.py::test_tc002_x_ratelimit_ヘッダーテスト FAILED
tests/test_api/test_rate_limit.py::test_tc003_制限リセットテスト FAILED
tests/test_api/test_rate_limit.py::test_tc004_ip別制限テスト FAILED
tests/test_api/test_rate_limit.py::test_tc005_非ai系エンドポイント除外テスト PASSED
tests/test_api/test_rate_limit.py::test_tc101_レート制限超過テスト FAILED
tests/test_api/test_rate_limit.py::test_tc102_retry_after_ヘッダーテスト FAILED
tests/test_api/test_rate_limit.py::test_tc103_エラーレスポンス形式テスト FAILED
tests/test_api/test_rate_limit.py::test_tc104_複数エンドポイントでのレート制限テスト FAILED
tests/test_api/test_rate_limit.py::test_tc201_境界値テスト_ちょうど制限内 FAILED
tests/test_api/test_rate_limit.py::test_tc202_境界値テスト_制限超過 FAILED
tests/test_api/test_rate_limit.py::test_tc203_境界値テスト_ウィンドウリセット境界 FAILED
tests/test_api/test_rate_limit.py::test_tc204_境界値テスト_retry_after値の範囲 FAILED
tests/test_api/test_rate_limit.py::test_tc301_x_forwarded_for_ヘッダーテスト FAILED
tests/test_api/test_rate_limit.py::test_tc302_不正ipフォールバックテスト FAILED
tests/test_api/test_rate_limit.py::test_tc303_複数x_forwarded_for_ヘッダーテスト FAILED
tests/test_api/test_rate_limit.py::test_tc304_高頻度リクエストテスト FAILED

========================= 16 failed, 1 passed =========================
```

### 4.3 失敗原因分析

| 失敗パターン | 件数 | 原因 |
|-------------|------|------|
| 404 Not Found | 16件 | AI変換エンドポイント未実装（/api/v1/ai/convert, /api/v1/ai/regenerate） |
| PASSED | 1件 | TC-005: /healthエンドポイントは既存のため成功 |

### 4.4 期待される失敗メッセージ
```
AssertionError: assert 404 == 200
 +  where 404 = <Response [404 Not Found]>.status_code
```

## 5. Greenフェーズへの要求事項

### 5.1 実装必須項目

1. **slowapiライブラリのインストール**
   - `requirements.txt` に `slowapi==0.1.9` を追加

2. **レート制限設定ファイル作成**
   - ファイルパス: `backend/app/core/rate_limit.py`
   - 内容:
     - Limiter初期化
     - get_client_ip関数（X-Forwarded-For対応）
     - AI_RATE_LIMIT定数（"1/10seconds"）

3. **カスタムエラーハンドラー実装**
   - RateLimitExceededエラーのハンドリング
   - 標準エラーレスポンス形式での429返却
   - Retry-Afterヘッダー設定

4. **main.pyへの統合**
   - Limiterのアプリケーション登録
   - カスタムエラーハンドラーの登録

5. **AI変換エンドポイント実装**
   - `/api/v1/ai/convert` エンドポイント（プレースホルダー）
   - `/api/v1/ai/regenerate` エンドポイント（プレースホルダー）
   - @limiter.limit() デコレーター適用

### 5.2 実装優先順位

1. slowapiインストール・基本設定
2. カスタムエラーハンドラー
3. AI変換エンドポイント（プレースホルダー）
4. レート制限デコレーター適用
5. X-Forwarded-For対応

## 6. 品質判定

### 6.1 判定結果: 高品質

```
テスト実行: 成功（失敗することを確認）
- 16件が期待通り失敗（実装がないため）
- 1件が成功（既存エンドポイント）

期待値: 明確で具体的
- 各テストケースでHTTPステータスコード、ヘッダー、レスポンス形式を明確に定義

アサーション: 適切
- Given-When-Thenパターンで構造化
- 日本語コメントで意図を明確化

実装方針: 明確
- slowapiライブラリを使用
- 既存のFastAPI構造との統合方法が定義済み
```

### 6.2 テストコード品質

| 項目 | 評価 |
|------|------|
| テストケース網羅性 | 高（正常系・異常系・境界値・エッジケースを網羅） |
| 信頼性レベル明記 | 全テストケースに🔵/🟡/🔴を付与 |
| 日本語コメント | 全テストに詳細な日本語コメントを記載 |
| 実行可能性 | 確認済み（pytest実行成功） |

## 7. 次のステップ

次のお勧めステップ: `/tsumiki:tdd-green` でGreenフェーズ（最小実装）を開始します。
