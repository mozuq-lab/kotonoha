# ADR-003: エラーは型で表現する。自由文字列をログ・レスポンスに載せない

状態: **承認済み（2026-08-29、署名: mozuq。2系統レビュー反映済み）** ／ 日付: 2026-08-29

## 背景と課題

8周の漏えいはすべて「**例外の自由文字列がシンクに到達する**」形だった。第三者ライブラリ
（limits・alembic）は生の URI / DSN を例外メッセージへ埋め込むため、`str(exc)` を
ログ・DB・HTTP ボディへ流す設計は、上流の実装詳細ひとつで漏えいに変わる。現行 main にも
例外を f文字列で直接ログへ出す箇所が16ある（`ai_client.py` 7 / `exceptions.py` 5 /
`ai.py` 4——台帳 P1）。

引き算の防御（redact 関数）は7周直して7周漏れ、最終版にも「netloc の無い URI の
クエリ資格情報が素通し」という分岐漏れが残った。**入力空間が無限な側を列挙する
防御は収束しない**（`docs/articles/why-redaction-fixes-dont-converge.md`）。

## 検討した選択肢

1. 漏えい経路ごとに redact 関数を書く（引き算の防御）
2. `SecretStr` で秘密をラップして流出を防ぐ
3. **エラーを `ErrorCode(StrEnum)` + `SafeError` の型で表現し、`str(exc)` を受け取る口を
   システムから無くす（足し算の防御）**（採用）

## 決定

案3。新 backend の `errors.py` は `ErrorCode` と `SafeError` しか受け取らない——
`str(exc)` を渡せる引数が存在しなくなる。補助として:

- grep ゲート: `str(exc)` / `str(e)` / `format_exc` に加え、**`print(` / `sys.stderr` /
  `traceback.print_exc` も `app/` に0件**（stdout / stderr へ書けるのは `app/logging.py`
  の出力実装だけ。再レビューの反例: `except … as exc: print(exc)` は当初の3語 grep・
  logging 制限・mypy をすべて通過する）。
  **grep は `logger.error(f"{exc}")` の形を捕まえられない**ため補助とし、主体は次の2つ:
- **ログの受け口も型付きにする**: 出力は構造化ログ関数（`app/logging.py`）経由のみ。
  stdlib `logging` の直接 import は `app/logging.py` 以外で0件（grep / import-linter）
- **canary 注入検査**: canary を仕込んだ例外を注入し、全シンク
  （stdout / stderr / HTTP ボディ）に現れないことを実測する（B-3「全シンク観測」）
- `mypy --strict`: `ErrorCode` / `SecretStr` の取り違えを型で検出
- 原因例外は型名のみを except の外で拾う（`__context__` を残さないパターンは
  `docs/verification-principles.md` §3 参照）
- `SecretStr` は設定層でのみ補助的に使う（単独では防御にならない）

## 決定理由（却下した案と理由）

- **案1を却下**: 列挙が終わらないことは7周＋独立レビューの再発見（8個目の穴）が実証した。
  防御は出力側の**有限な語彙**（ErrorCode の列挙）で構成する——有限な側を列挙し、
  無限な側を生成するのが正しい向き
- **案2を却下**: `SecretStr` は `==` が黙って False を返す・関数呼び出しでフレーム
  ローカルに乗る・下流で平文 `list[str]` に戻る経路に無力（いずれも実測、
  verification-principles §3）。単独では防御にならない

## 影響

- 診断の粒度は ErrorCode の列挙が上限になる。足りなければ**列挙を増やす**
  （自由文字列に戻さない）
- ログ・レスポンスの語彙が有限になるため、「秘密が含まれていないこと」が
  検査可能な命題になる

関連: [ADR-002](ADR-002-rate-limit-single-instance.md)／
[ADR-004](ADR-004-config-immutable.md)
