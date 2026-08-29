# 秘密情報の漏えい対策と、レビュー往復が収束しない問題への対応計画

作成: 2026-08-28 ／ 最終更新: 2026-08-29
状態: **未着手**（別セッションで実施予定）

この文書は単独で読めるように書いてある。前提となる会話の文脈は不要。

> **この文書の記述は 2026-08-28 時点の実測値である。着手時に §1 を再確認すること。**
> 作成の翌日には既に `main` のコミット数がずれていた。自分（または前のセッション）が
> 書いた文書は、次に読むときには「検証されていない主張」であって事実ではない。
> 数字・パス・行番号は、使う前に必ず現物で確かめること。

> **本文中の行番号は、断りのない限り `fix/backend-production-hardening` 基準である。**
> `main` とは一致しない。ブランチで `config.py` は +342 行されており、たとえば
> `DATABASE_URL` は main では 113-127 行、ブランチでは 242-256 行にある。
> 着手時に `git rev-parse fix/backend-production-hardening` を記録し、
> ずれていたら行番号を取り直すこと。

### 改訂履歴

| 日付 | 内容 |
|---|---|
| 2026-08-28 | 初版。7体のサブエージェントによる検証を反映（ステップ1の順序を訂正） |
| 2026-08-29 | 独立レビュー2系統（Claude / Codex CLI）の指摘30件を反映。**ステップ6の「規律」の記述が誤りだったため訂正（§3 ステップ6）**。実行順を組み替え（§3 冒頭）。完了条件に差分面積の上限とレビュー仕様を追加 |

---

## 0. この計画が生まれた経緯

`fix/backend-production-hardening` ブランチに対して「修正 → コードレビュー（別エージェント）→ 再指摘」を **8周**繰り返したが収束しなかった。8周のうち7周を「設定値の秘密情報がログや例外に漏れる」問題が占め、毎周ちがう入力の形で再発した。うち1回は**前周の修正が作った穴**だった。

7体のサブエージェントで原因分析と計画の検証を行った結果、**当初の計画には順序の誤りと前提の誤りがあった**ことが判明している。この文書は検証後の版である。

### 収束しなかった構造的な理由

1. **停止条件が測定器の側にあった。** 「指摘ゼロ」は成果物の性質ではなくレビュアーの出力の性質で、十分な探索予算があるレビューは必ず何かを見つける。しかも指摘の約8割を占める設計・保守性の指摘は反証不能。
2. **毎周の指摘数は残存欠陥ではなく直前の差分の面積を測っていた。** 1周で10〜15件をまとめて直す → 変更範囲が広がる → それが新しい指摘を生む、というループ利得が1を超える系だった。
3. **修正が不変条件ではなく「事例」に対して行われていた。** 秘匿は「入力を受け取って危険な部分を取り除く」引き算の設計で、入力空間が無限なので事例の列挙は原理的に終わらない。
4. **先送りの判断が状態として残らなかった。** 同じ指摘が4周連続で出たのは、系が「却下」という状態を表現できないため。
5. **バグと設計意見が同じ配管を流れていた。** 完了判定の方法がまったく違うのに、同じ「指摘」として同じ周回で処理されていた。

---

## 1. 現状（2026-08-28 時点、実測）

### ブランチ

`main` は `origin/main` より先行し、**push 未実施**（`origin/main` の最終更新は 2026-08-23）。
先行コミット数は 2026-08-28 に 3、翌 2026-08-29 に 4 で、着手時には必ずずれている。
**固定値を信じず、`git rev-list --left-right --count origin/main...main` で取り直すこと。**

| ブランチ | main比 | 状態 |
|---|---|---|
| `fix/backend-production-hardening` | 15 | この計画の主対象。P0 3件は解消済み |
| `fix/contrast-accessibility-sweep` | 17 | frontend。**他ブランチとの重複ゼロ・競合なしを実測確認済み** |
| `chore/flutter-cleanup` | 4 | frontend。codegen 撤去済み |
| `fix/emergency-button-overlap` | 2 | frontend。**同上、競合なし** |
| `docs/consistency-fixes` | 13 | 最後にマージ（README / tech-stack.md で他2本と重複） |

`fix/precommit-worktree-hook` は**マージ済み**。未マージは **5本**。

### ブランチ間の重複（実測）

```
docs/consistency-fixes × chore/flutter-cleanup            : 8 ファイル
docs/consistency-fixes × fix/backend-production-hardening : 6 ファイル
frontend 3本の相互重複                                     : すべて 0 ファイル
```

`fix/contrast-accessibility-sweep` と `fix/emergency-button-overlap` は**今すぐマージしても競合しない**。
本計画の作業対象（`config.py` / `rate_limit.py` / `conftest.py` / `alembic/env.py` / `alembic.ini`）を
触るブランチも、**作業ブランチ `fix/backend-production-hardening` 自身を除けばゼロ**である
（`docs/consistency-fixes` はこの5ファイルに差分を持たない）。

### main に入っている直近の変更

Tsumiki のプロセス成果物を `docs/archive/` へ隔離済み（`docs/implements/` 299ファイル、
`development-history.md`）。`docs/tasks/` は `docs/consistency-fixes` が全6ファイルを編集中のため
**未移動**（判断を後回しにした。`docs/archive/README.md` に未了として記録）。

### ローカル環境

- Postgres コンテナ `kotonoha_postgres` は healthy。`ENVIRONMENT=test pytest` で **418 passed / 4 skipped**
- **ローカルでは `TEST_DATABASE_URL` を渡さないこと。** `tests/conftest.py:24` の既定値がローカル構成（`kotonoha_user@kotonoha_test`）を指す。CI 用の値（`test_user@test_db`）を渡すとロールが存在せず 56 errors になる

---

## 2. 検証済みの事実

以下はすべて実際にコードを実行して確認した。推測ではない。

### 2-1. 【最重要】`%` / `@` を含むパスワードで DB に接続できない

```
生='p%25ss$word'  → SQLAlchemy の解釈 'p%ss$word'   ← 不一致
生='ab@cd'        → SQLAlchemy の解釈 'ab'          ← @ 以降が切り捨て
URL.create        → いずれも往復一致
```

`app/core/config.py:246,254` が f文字列で DSN を組み立てているため。パスワードマネージャが生成する記号入りパスワードを本番で使うと踏む。**秘匿の話ではなく現存する接続バグ。**

### 2-2. `fix/backend-production-hardening` に生きた漏えいが3件

**`main` は未汚染である。** main の `app/core/rate_limit.py` には `"@" not in storage_uri` も
`_KNOWN_STORAGE_SCHEMES` も存在しない（grep 0件）。以下の3件はすべて作業ブランチ側で
作り込まれたもので、だからこそ「先にマージしてはいけない」（§3 ステップ1 の訂正を参照）。

```
redact_storage_uri('redis://?password=SECRET')     → 'redis://?password=SECRET'      ← 平文
redact_storage_uri('unix:SUPERSECRET')             → 'unix:SUPERSECRET'              ← 平文
redact_storage_uri('redis:///0?password=SECRET')   → 'redis:///0?password=SECRET'    ← 平文
```

原因は2つ。

- `app/core/rate_limit.py` の `if "@" not in storage_uri: return storage_uri`。`unix:///` を救うために足したが、クエリ文字列の資格情報を素通りさせる。クエリ秘匿は netloc 側の分岐にしかない
- `_KNOWN_STORAGE_SCHEMES = frozenset(SCHEMES) | {"unix"}` の `"unix"` は **limits に存在しないスキーム**（実在は `redis+unix` / `valkey+unix`）

### 2-3. `alembic/env.py:37` が DSN 全文を漏らす

```
ValueError: invalid interpolation syntax in 'postgresql://u:pa%ssw0rd@h/db' at position 17
→ パスワード込みの DSN 全文が例外メッセージにもトレースバックにも載る
```

`config.set_main_option("sqlalchemy.url", ...)` は ConfigParser の補間を通る。**モジュールトップレベルで送出され誰も catch しない**ので、`alembic upgrade head` のたびに stderr / コンテナログ / CI ログに出る。

- 壊れるのは `%` のみ。`$` `(` `:` `{` は無害
- `%(x)s` 形は**例外すら出さず**パスワードを別物に静かに置換する

### 2-4. `set_main_option` を消すだけでは壊れる

`alembic.ini:89` に `sqlalchemy.url = postgresql://user:pass@localhost/dbname` というダミーが残っており、`engine_from_config(config.get_section(...))` がこれを拾う。症状は "connection refused" で原因追跡が難しい。

### 2-5. 漏えいは3つの独立したチャネルで起きる

| チャネル | 内容 | 塞ぐ手段 |
|---|---|---|
| 1. 値の materialize | `str` / `repr` / f文字列 / `model_dump` | `SecretStr` |
| 2. 例外の連鎖 | `__cause__` / `__context__` / 連鎖トレースバック | `except` の外で投げる |
| 3. フレームローカル | `TracebackException(capture_locals=True)` | `SecretStr` / `URL` |

**8周の修正はすべてチャネル1だけを叩いていた。**

ただしチャネル3について注意: **このリポジトリに Sentry は無い**（grep 0件）。チャネル3は将来レポータを導入した場合の話。

**現に実在する害の所在は §2-7 で訂正した。** 初版はここに「`app/core/exceptions.py:88` の
`traceback.format_exc()` が連鎖トレースバックを `error_logs` テーブルに永続化している」と
書いていたが、実測すると `exceptions.py:62` に
`stack_trace=stack_trace if settings.ENVIRONMENT == "development" else None` の環境ガードがあり、
**本番では `stack_trace` は DB に保存されない**。本番で残るのは環境ガードの無い経路のほうである。

### 2-6. 第4層（境界）が必要

`alembic` の漏えい（2-3）と、8周で直した `rate_limit` の漏えいは**同じ形**である。どちらも「サードパーティが我々の秘密入り文字列を自分の例外メッセージに埋める」で、違いは catch する人がいたかどうかだけ。

「`except` を書く場所」を適用範囲にすると、catch されない側を原理的に取りこぼす。**範囲を反転させ、秘密を含む文字列をサードパーティへ渡す境界を列挙する**必要がある。境界は数えられる規模: `Limiter`、alembic の `set_main_option`、`create_engine`、AI SDK のクライアント生成。

### 2-7. DB と HTTP レスポンスがシンクとして抜けていた

3チャネルの議論は stderr / ログ / トレースバックを対象にしていたが、**一度漏れたら消えない面**と
**アプリが外部へ能動的に返す面**が抜けていた。環境ガードの有無で扱いが変わるので分けて書く。

**全環境で書かれる（＝本番で残る害）**

| 場所 | 内容 | 行き先 |
|---|---|---|
| `app/core/exceptions.py:56,87` | `error_message=str(exc)` | `error_logs` テーブル（**消えない**） |
| `app/api/v1/endpoints/ai.py:251` | `error_message=str(error)` | `ai_conversion_logs` テーブル（**消えない**） |
| `app/core/exceptions.py:90` | `logger.error(f"... {stack_trace}")` | ログ |
| `app/api/v1/endpoints/health.py:118-121` | `logger.error(..., str(e), ...)` | ログ |
| `app/core/logging_config.py:30-34` | FileHandler | **`LOG_FILE_PATH` で変更可能**。`logs/app.log` 固定ではない |

**開発環境のみ**

| 場所 | 内容 |
|---|---|
| `app/core/exceptions.py:62` | `stack_trace`（`ENVIRONMENT == "development"` のときだけ DB へ） |
| `app/api/v1/endpoints/health.py:124-125` | `str(e)` を **HTTP レスポンスボディ**に載せる。本番は `"Database connection failed"` に置換 |

`health.py` は**未認証で到達できる唯一のエンドポイント**で、DB 接続失敗時の経路である。
§2-3 が示したとおり、この文脈の例外メッセージには DSN 全文が載りうる。本番のガードは
存在するが、**そのガードの正しさを検証するテストが無い**。さらに `health.py:135` は
`raise HTTPException(...) from e` で連鎖しており、最終的な着地点は未確認。

**運用面（Wave A の範囲外。台帳へ）**: `docker-compose.yml:32,38` はパスワードを
単体の環境変数としてだけでなく 2 本の DSN として再 materialize する。
`docker compose config` の出力・コンテナメタデータ・プロセス environ はいずれも
秘密が読める面だが、本計画の観測面はアプリケーション内部で閉じている。

### 2-8. `SecretStr` の効果と限界

**効くもの**: `repr(settings)` / `str(field)` / f文字列 / `model_dump` / pytest のアサーション表示 / フレームローカル / `.get_secret_value()` 忘れの型検出。

**効かないもの**:

- `extra="forbid"` のタイポ（`ANTHROPIC_API_KEYS=...`）。未宣言キーには型が付かない。**正しい対策は `errors(include_input=False)`**。既存の `app/core/config.py` の `_describe_validation_error`（loc + msg のみ抽出）が実質同等のことをしており、**`SecretStr` を入れても恒久的に必要**
- `settings.DATABASE_URL` は `SecretStr` にしても平文の str のまま。**`URL` 化と補完関係**にある
- **下流で平文に戻る経路。** `config.py:264` の `API_KEYS_LIST` は平文の `list[str]` を生成し、
  `app/core/security.py:37` の認証処理はさらに平文 bytes をローカルに保持する。`SecretStr` 化の
  効果はこの 2 箇所で終端する。真偽値評価としては「変更不要」だが、フレームローカル対策としては
  未完である（分類の軸が違う。§3 ステップ6 の表を参照）

**過去に実際に起きた13件の欠陥のうち、`SecretStr` で防げるものは 0 件。** 価値はあるが優先度は最上位ではない。

### 2-9. `SecretStr` は `==` を静かに壊す

```
SecretStr('x') == 'x'   → False   ← 例外を出さず常に False
SecretStr('x').strip()  → AttributeError（気づける）
```

`app/core/config.py:344` の `target.POSTGRES_PASSWORD == DEV_POSTGRES_PASSWORD` を直し忘れると、**「本番で開発用デフォルトパスワードのまま起動する」検査が黙って無効化される**。セキュリティ後退。

ただし実際の該当行は
`if not target.POSTGRES_PASSWORD.strip() or target.POSTGRES_PASSWORD == DEV_POSTGRES_PASSWORD`
であり、**`or` の左辺の `.strip()` が先に `AttributeError` を出す**ので、直し忘れには気づける。
過剰に身構える必要はない——ただし左辺だけ直して右辺を残すと、そこから先は静かに壊れる。

### 2-10. `SecretStr` は `validate_assignment=True` とセットでなければ既存テストを壊す

`tests/` に `monkeypatch.setattr(settings, ...)` が **22箇所**ある
（`grep -rn "monkeypatch.setattr(settings" tests/` で実測。初版は24箇所としていた。着手時に数え直すこと）。
内訳は `test_security.py` 7 / `test_api_key_auth.py` 11 / `test_rate_limit.py` 4 で、
対象フィールドは `API_KEYS` / `ENVIRONMENT` / `TRUSTED_PROXY_COUNT` / `RATE_LIMIT_STORAGE_URI`。
このうち `API_KEYS` と `RATE_LIMIT_STORAGE_URI` が `SecretStr` 化の対象と重なる。

`validate_assignment=True` があれば str → SecretStr に自動強制されて全部動く。無いと str のまま格納され `.get_secret_value()` が実行時に落ちる。

ただし `tests/conftest.py:67` の `object.__setattr__` は `__setattr__` 自体を迂回するので **`validate_assignment` では救えない**。ここは別途 1行修正が要る（後述）。

**`object.__setattr__` は 67 行目と 82 行目の 2 箇所ある。** 直すのは 67（パッチ適用側）だけ。
82 は復元側で、`_originals = {key: getattr(settings, key)}` が取得した時点で既に `SecretStr` に
なっているため変換不要。**2箇所とも触ると復元を壊す。**

**`validate_assignment=True` の副作用は小さいことを実測確認した。** `model_validator(mode="after")` は
使われておらず（本番検査は `Settings()` の外の関数に出してある）、代入のたびにモデル全体の検証が
走る事故は起きない。`test_api_key_auth.py` が `ENVIRONMENT` に `"production"` / `"staging"` を
代入しているので、ここは実際に危なかった箇所である。

---

## 3. 実行計画

### 実行順（ステップ番号は初版のまま。順序だけ組み替えた）

```
0 → 1 → 4a → 2 → 3 → 4b → 5 → 6 → 7
```

初版はステップ2・3（修正）をステップ4（不変条件テスト）より前に置いていたが、これは
共通ルール「テストを先に書き、赤を確認してから直す」に反していた。しかもステップ3自身が
「ステップ4の結果を見てから最終形を決めること」と書いており、依存が循環していた。

- **4a** = `observe()` の骨格を実装し、§2-2 の漏えい3件と §2-3 の alembic 漏えいを**赤にする**
- **2 / 3** = 修正して緑にする
- **4b** = 入力生成を広げ、まだ漏れる面を探索する

ステップ2を先に済ませると、alembic の漏えいに対する赤テストを書く前に原因が消える。
「修正が効く観測点を無意識に選ぶ」（§7）ための条件が揃うので、4a を必ず先に置くこと。

### 進め方のルール（全ステップ共通）

- **1件 = 1テスト = 1コミット。** 複数の修正を同じコミットに混ぜない
- **テストを先に書き、赤を確認してから直す。** 「修正後にテストを書く」と、修正が効く観測点を無意識に選んでしまう
- **検証は最も外側の境界で行う。** 戻り値ではなく、プロセスの stdout/stderr、実際の DB 行、描画されたウィジェット
- **1周の差分上限: 400行 / 12ファイル。** 超えたら周を分割する
- **同じクラスの箇所を grep してから閉じる。** 1件直したら、そのパターンで全体を検索する

---

### ステップ0: プロセスの完了条件を決める（2時間）

**この計画自身を最初の適用対象にする。** 最後に置くと、この計画が旧いプロセスで走る。

完了条件を「指摘ゼロ」から次に置き換える。すべて機械判定可能。

1. **P0（実証済みバグ）が0件。** 「実証済み」の定義は
   **「その指摘を赤にする自動テストが存在し、修正前のコミットで実際に赤になることを CI で示せる」**。
   示せないなら P0 ではない
   （初版は「15分以内にテストを書けるか」としていたが、これは書く人の技量と時間に依存し、
   成果物から機械判定できない。上の定義なら判定は機械的で、しかも「修正の後にテストを書く」罠（§7）
   も同時に塞ぐ）
2. **過去周に書いた再現テストが全部緑**
3. **既存 CI ゲートが緑**（`ruff check app tests` / `black --check app tests` / カバレッジ閾値
   `fail_under = 80`。いずれも `.github/workflows/python.yml` と `pyproject.toml` に実在する）
4. **未対応の指摘が全件 ID 付きで台帳に載っている。** 0件である必要はない。「棚卸し済み」が条件
5. **2周連続で新規 P0 が0件**（「周」の定義は下の「レビューの仕様」を参照）
6. **アプリを実際に起動し、変更した機能が動くことを確認した**（`scripts/smoke.sh` の通過）
7. **そのステップの差分が 400行 / 12ファイル以内**（`git diff --stat` で判定）。
   超えたステップは着手前に分割する

到達目標は「指摘ゼロ」ではなく **「未分類の指摘ゼロ」**。

**7 を入れる理由**: §0-2 は「毎周の指摘数は残存欠陥ではなく直前の差分の面積を測っていた／
ループ利得が1を超える系だった」を収束しなかった主因として特定している。**主因として特定した
変数が、機械判定される停止条件に入っていなければ制御されていない。** 初版はこれを共通ルールの
努力目標に置いていたが、実際の計画はステップ2もステップ6もこの上限を超える。
ステップ6は「アプリ側」「テスト側」「規律チェック」の3周に割るのが自然。

**6 を入れる理由**: 8周のレビューと418件のテストを通じて、**誰一人アプリを起動しなかった**。
2-1 の接続バグ（`%` を含むパスワードで DB に繋がらない）は全テスト緑のまま生き残り、
サブエージェントが実際に記号入りパスワードのロールを作って接続を試したときに初めて出た。
単体テストは「設定の組み立てから接続まで」を通らないので、この層を構造的に見逃す。
`pytest` は10秒で終わるので何十回も回してしまうが、**安い検証が高い検証を締め出す**。

トリアージ基準（重要度ではなく「受け入れ条件が書けるか」で切る）:

| クラス | 判定 | 扱い |
|---|---|---|
| P0 | 赤にする自動テストを15分以内に書けるか → Yes | その周で直す。テスト先行 |
| P1 | テストは書けないが不変条件の形に言い換えられるか → Yes | 不変条件テストだけ書いて台帳へ |
| P2 | 上2つが No、動作が変わらない | 一切触らない。ID を振って台帳へ |
| P3 | linter が判定できる | linter 設定に落とすか却下 |

**却下ルール**: 同じ指摘が2周続けて P2 判定になったら「却下」としてクローズし、次周以降のレビュー入力に「却下済み一覧（ID＋理由）」として渡す。

台帳は GitHub Issue 1本＋ラベル（`deferred` / `rejected`）で足りる。
**着手時に §6 の判断事項6件と §5 の既知の問題11件を、この台帳の最初の登録対象として起票する。**
計画書という「状態を持たない場所」に判断を置いたままにすると、§0-4 の失敗をこの計画自身が再演する。

#### レビューの仕様

完了条件5は「2周連続で新規 P0 が0件」だが、**初版には「周」の定義が無かった**。
§0-1 が特定した第一の失敗原因は「停止条件が測定器の側にあった」ことである。停止条件は
成果物側へ移したが、**測定器そのものを調整しなければ、同じレビュアーに同じ入力を与えて
同じ出力（設計・保守性の指摘が8割）が返るだけ**で、毎周のトリアージ工数だけが残る。

| 項目 | 仕様 |
|---|---|
| 1周の単位 | **1ステップ = 1周 = 1レビュー**。ステップをまたいでレビューしない |
| レビュー入力 | **そのステップの差分のみ**（`git diff`）＋ 却下済み一覧（ID＋理由）＋ 台帳の `deferred` 一覧 |
| レビュー観点 | **P0 基準に限定する**——「この指摘を赤にする自動テストを書けるか」。書けない指摘は、レビュアーの側で最初から台帳へ直行させる |
| 範囲外の明示 | 差分の外にある既存構造（§5）はレビュー対象外。台帳で管理する |
| レビュアー | 種類の違う2系統を当てる。8周のレビューは全員が同じ検証しかせず、`core → db → core` の循環を一度も見つけなかった（§7 最終項） |

**レビュアーを2系統にする根拠**: 2026-08-29 のレビューでは、プロセス設計側の指摘（レビュー仕様・
差分面積・判断の状態管理）と実装精度側の指摘（canary による反証・パラメータ未定義）が
系統ごとにきれいに分かれ、**独立に到達した指摘は6件だった**。同じ結論に別経路で着いた指摘は
確度が高く、片方しか見つけなかったものは盲点の非相関の証拠になる。

---

### ステップ1: 作業ブランチの確認とスモークスクリプトの用意（半日）

**作業は `fix/backend-production-hardening` 上で行う。マージは最後（ステップ6の後）。**

> **訂正**: 本計画の初版は「先にマージしてから main で作業する」としていた。理由は
> 「作業対象ファイルを二重に触らないため」だったが、**実測すると作業対象5ファイルを
> 触るブランチはゼロ**だった。前提が誤っていた。加えて、コミット済みコードには
> 2-2 の漏えいが3件生きているので、**先にマージすると既知の漏えいを本流に入れる**ことになる。

このステップでやること。

1. **`scripts/smoke.sh` を作る。** ステップ2以降の検証手段になる。最小構成に留めること
2. **メモリを更新する。** `~/.claude/projects/-Volumes-external-dev-kotonoha/memory/branches-awaiting-merge-2026-08.md`
3. **`infra/` の CDK が生成する DB パスワードの文字集合を確認し、`%` / `@` の有無を記録する。**
   §2-1 は「秘匿の話ではなく現存する接続バグ」である以上、既にデプロイ済みの環境では
   **現に接続できていない可能性がある**。初版はこれを §6 の判断事項（「確認する価値がある」）に
   置いていたが、判断ではなく作業項目である。ここを飛ばすと「コードは直ったが本番のパスワードは
   踏んだまま」に着地する
4. **台帳（GitHub Issue）を作り、§6 と §5 を起票する**（ステップ0 の「却下ルール」を参照）

#### `scripts/smoke.sh` の最小仕様

単体テストが通らない層——**設定の組み立てから実接続まで**——だけを対象にする。

```
1. docker compose up -d
2. RATE_LIMIT_STORAGE_URI を設定した状態で起動し、
   /api/v1/health が 200 かつ database: connected を返すまで待つ（タイムアウト付き）
3. 記号（% と @）を含むパスワードのロールを一時作成し、
   alembic upgrade head / downgrade base と非同期接続が通ることを確認
4. 後片付け（作成したロール・DBを削除）
```

**手順2で `RATE_LIMIT_STORAGE_URI` を設定する理由**: 初版の仕様は health + alembic + 接続だけで、
**この計画で最も触る場所——`rate_limit.py` の `Limiter` 構築——を一度も通らなかった**。
ステップ5が列挙する「第4層（境界）」の筆頭が Limiter であるにもかかわらず、である。
「アプリを一度も動かさない」罠を塞ぐために置いた検証が、今回いちばん動かすべき箇所を
素通りしていた。環境変数を1つ足すだけで塞げる。

**広げないこと。** AI変換の疎通や認証まで入れるとスモークテスト自体が肥大化し、
別の8周を生む。必要になってから足せばよい。

なお `backend` サービスには healthcheck が無い（`postgres` にはある）。
`docker compose up` が「起動した」と言うのに実際は死んでいる状態を検出できないが、
これは本計画の範囲外とし、別途対応する。

---

### ステップ2: `URL` 化 + alembic 脱 `set_main_option`（半日）

**ステップ4a（`observe()` の骨格と赤テスト）を済ませてから着手すること。** 初版はここを
「テスト変更ゼロ」で実施するとしており、検証も接続成功の smoke だけだった。それでは
**§2-3 の alembic 漏えいに対する赤テストを書く前に原因が消える**。共通ルールに反する。

セキュリティ修正であると同時に 2-1 の接続バグの修正でもある。**アプリ側の変更は
テスト変更ゼロで 416 passed が実証済み**（`.env` の無い複製環境での計測。ワークツリーでは 418）。

**A と B は不可分。** B なしの A は漏えいも `%` 破綻も残す。A なしの B は `%` パスワードで認証失敗する。

| ファイル:行 | 変更 |
|---|---|
| `app/core/config.py:242-256` | `DATABASE_URL` / `DATABASE_URL_SYNC` を `sqlalchemy.engine.URL.create(...)` を返す形へ |
| `app/db/session.py:67` | **変更不要**（`create_async_engine` が `URL` を受理することを実測確認） |
| `alembic/env.py:11` | `engine_from_config` → `create_engine` |
| `alembic/env.py:36-37` | `set_main_option` の2行を削除 |
| `alembic/env.py:55` | `config.get_main_option("sqlalchemy.url")` → `settings.DATABASE_URL_SYNC` |
| `alembic/env.py:75-79` | `engine_from_config(...)` → `create_engine(url, poolclass=pool.NullPool)` |
| `alembic.ini:89` | ダミー `sqlalchemy.url` をコメントアウト（**必須**。2-4 参照） |
| `tests/conftest.py:57` | `urlparse` → `sqlalchemy.engine.make_url`（下記） |

**訂正: `tests/conftest.py` は「無影響」ではない。** alembic を `command.upgrade/downgrade` で
呼ぶだけなので `get_main_option` にも `sqlalchemy.url` にも触れない、という点は正しい。
だが `conftest.py:57` は `TEST_DATABASE_URL` を `urllib.parse.urlparse` で分解して
`POSTGRES_*` にパッチしており、**`urlparse` は percent-decode しない**。記号入りパスワードでは
誤った値が入る。

これは §7 の罠リストに載っている当の失敗——「`urlsplit` はパスワードを percent-decode しないので
DSN の往復一致の確認には使えない。`sqlalchemy.engine.make_url` を使うこと」——が、
**テストハーネス側に同じ形で残っている**ということ。§2-1 が本番の接続バグとして指摘した問題の
裏返しである。**ステップ6で `SecretStr` を被せる前に直すこと**（誤った値を `SecretStr` で包むと
以後デバッグが難しくなる）。

なお `DATABASE_URL` / `DATABASE_URL_SYNC` は素の `@property`（`cached_property` でも
`computed_field` でもない）ため、conftest が `object.__setattr__` でパッチした結果は
`URL.create` 化後もそのまま反映される。ここは実測確認済み。

**検証**: ステップ1で作った `scripts/smoke.sh` を通す。これが**本計画で初めて
「アプリを実際に動かす」検証**になる。単体テストは 2-1 の接続バグを構造的に見逃すので、
ここを飛ばすと同じ穴が残る。

**ロールバック**: 失敗したときは `alembic/env.py` 側だけを戻し、**`alembic.ini:89` の
コメントアウトは戻さない**。ダミー `sqlalchemy.url` を復活させると漏えい経路も復活するうえ、
症状が "connection refused" で原因追跡が難しい（§2-4）。1件＝1コミットにしてあれば
`env.py` のコミットだけ `git revert` できる。

---

### ステップ3: 生きた漏えい3件（数時間）

2-2 の3件。ステップ2と同じ性質なので続けて実施する。
**ステップ4a で赤にしてから着手すること**（§3 冒頭の実行順）。

**引き算をやめ、組み立てにする。** 入力から危険部分を除去するのではなく、**出力に使ってよいトークンを閉じた集合に限定する**。

- 使ってよいのは (a) `limits.storage.SCHEMES` の要素、(b) 固定文字列 のみ
- **host / port / path / query / fragment / userinfo はすべて「有無」だけを出す**
- 文法に1文字でも外れたら構造情報を出さない
- **`SCHEMES` を手書きで拡張しない**（`| {"unix"}` が今回の再発原因）
- **表示関数は全域関数にする**（絶対に例外を投げない）。`urlsplit('redis://[::1')` は `ValueError` を投げる

**訂正: 初版は許可集合に「厳格な文法に完全一致したホスト/ポート」を含めていたが、これは
閉じた集合ではない。** 秘密値が DNS 名として合法な英数字列であれば、あるいは合法な数値ポート
であれば、そのまま出力される。実際に canary を host / port の位置に置いて現行関数
（`rate_limit.py:172`）に通すと残った。**ホスト名という無限集合を「安全なトークン」に含めた
時点で、引き算に戻っている。**

加えて、許可するホスト文法自体が未定義だった（IPv6・複数ホスト・不正ポートのどこまでを許すか）。
現行コードがこの分解で例外や破損を起こすため文字列のまま扱っている、という経緯もある
（`rate_limit.py:166`）。**文法を決めないまま「厳格な文法」と書くと、それ自体が9周目の議論の種になる。**

診断に必要な情報はスキームと「資格情報の有無」でほぼ足りる。host / port も有無だけにすること。

`app/core/rate_limit.py` の秘匿機構は約184行あるが、原因例外のメッセージを埋め込むのをやめれば `_scrub_credentials` / `_password_fragment` / `_contains_credential_shape` は不要になり、25行程度になる見込み。

**最終形はステップ4b の探索結果で確定する。** ここでは 4a が赤にした3件を緑にするところまでを行い、
「まだ漏れる面が他にあるか」は 4b に委ねる。初版はこれを「ステップ4の結果を見てから決める」と
書いており、3 が 4 に依存する一方で 3 が 4 より前に置かれていた（依存の循環）。

---

### ステップ4: 不変条件テスト（半日〜1日）

**4a（`observe()` の骨格と赤テスト）をステップ2・3の前に、4b（入力生成と探索）をあとに実施する。**
§3 冒頭の実行順を参照。

**ここで「まだ漏れる面」が推測ではなく実測で確定する。**

不変条件:

> 設定した秘密の**全体**（およびその percent-encode 表現）が、観測可能な出力のいずれにも現れない

初版は「いかなる部分文字列も」と書いていたが、文字どおり取ると1文字の部分列まで禁止することに
なり、通常のログとの偶然一致で成立不能になる。一方で後段の実装方針は秘密値全体の substring 検索を
想定しており、判定規則が一致していなかった。

**観測面は有限なので列挙し、入力は無限なので生成する。** 私は8周これを逆にやっていた。

観測面を1つの `observe()` 関数に集約する。新しい出口が心配になったらここに1行足すだけで、既存の全テストが自動的にその面を検査する。

```
- 戻り値 str
- 例外の str / args / repr
- __cause__ / __context__ を無条件に辿った全要素
- 既定 traceback
- capture_locals=True の traceback
- ログ出力全体（root ハンドラ捕捉）
- オブジェクトグラフの有界BFS（args / __dict__ / response / request / headers / orig / params / statement）
- ★ DB に書かれた行（error_logs.error_message, ai_conversion_logs.error_message）
- ★ 開発環境では error_logs.stack_trace も
- ★ root logger に付いた全 FileHandler の baseFilename（logs/app.log 固定にしない）
- ★ プロセスの stdout / stderr 全体（subprocess で起動して捕捉）
- ★ HTTP レスポンスボディ（TestClient でエンドポイントを叩いた結果）
```

★ は 2-7 の理由で必須。**追加した4つの理由:**

- **`error_logs.error_message`**: 初版は `stack_trace` を「消えない唯一の面」としていたが、
  そちらは開発環境でしか DB に書かれない。全環境で書かれるのは `error_message` のほう（§2-7）
- **全 FileHandler の `baseFilename`**: 出力先は `LOG_FILE_PATH` で変更できる。
  `logs/app.log` を固定パスで見ると、別パスに設定された環境の漏えいを丸ごと見逃す
- **プロセスの stdout / stderr**: §7 の罠リストに「1周目に `python -c "import app.main"` の
  出力全体を grep した修正だけは今も破れていない」とある。**8周で唯一破られなかった観測手段が、
  初版の `observe()` から漏れていた。** 全部プロセス内観測で、罠リストの
  「戻り値で検証してプロセス出力で検証しない」を `observe()` の設計自体が踏んでいた。
  `tests/test_main_startup.py:64,145` に既存の起動テストがあり、subprocess の両出力を
  直接検査している。この境界を共通 `observe()` に残すこと
- **HTTP レスポンスボディ**: `health.py` は未認証で到達できる唯一のエンドポイントで、
  development では `str(e)` をそのまま返す（§2-7）。**アプリが外部へ能動的に返す面**が
  観測対象から漏れていた。本番のガードそのものを検証するテスト
  （`ENVIRONMENT=production` で `str(e)` がボディに出ないこと）も書くこと

#### 観測面 × 発火経路（trigger matrix）

**観測面を列挙しても、そこに何かを書き込ませる経路が無ければ検査は空振りする。**
出力先が空のまま「秘密が含まれていない」と判定され、テストは緑になる。これは
「対処済みと証明したが生きていた漏えい」（§7）の一段深い版で、**正しい面を見ているが
何も起きていない**という失敗である。

発火経路は次の6つ。**「観測面 × 発火経路」の表を作り、各セルが少なくとも1つのテストで
埋まっていることを完了条件にする。** 空セルは「その経路ではその面に何も出ない」ことを
テストで示すか、未検証として台帳へ送る。

```
1. 設定読込失敗（_load_settings の except）
2. app import（python -c "import app.main"）
3. Limiter 構築失敗（_build_limiter の except）
4. Alembic 実行（upgrade head / downgrade base）
5. DB 接続失敗（health エンドポイント経由を含む）
6. AI 呼出失敗（_map_provider_exception 経由）
```

入力生成は `hypothesis` 不要。標準ライブラリで文法ベースに生成する。

```
SCHEMES_ = list(limits.storage.SCHEMES) + ["unix", "bogus", ""]   # ライブラリから取る
SEPS     = ["://", ":", ":/", ":///", "//"]                        # '//' の有無を必ず含める
HOSTS    = ["h:6379", "[::1]:6379", "h1:26379,h2:26379", "", "h:not-a-port"]
USERINFO = ["", f"{S}@", f"u:{S}@", f"u:{quote(S)}@", f"{S}@u:{S}@"]
QUERIES  = ["", "?a=b", f"?password={S}", f"?a=b&x={quote(S)}"]
FRAGS    = ["", "#f", f"#{S}"]
```

**判定は生成器が持つ既知のシークレットとの一致にする。** ヒューリスティック（「`password@` の形」「12文字以上」）を使うと、それ自体が9周目の議論の種になる。

**判定は raw sentinel だけでは足りない。** 秘密が percent-encode（あるいは二重 encode）された形で
出力された場合、raw との一致では検出できない。現行の `rate_limit.py:230` には `unquote` 後を
別途検査する処理が既にあり、この問題が実在することを示している。判定は次の集合のいずれかが
出力に含まれるか、とする。

```
raw sentinel ∪ quote(sentinel) ∪ quote(quote(sentinel))
```

生成器側で変換表を持てば、判定規則はヒューリスティックにならずに済む。

**sentinel は生成された一意で長い文字列にする。** 短い辞書語（`pass`, `host`）だと `localhost` に `host` が含まれて偽陽性が出る。短い語のケースは「診断メッセージが壊れないこと」の別テストに分離する。

`random.Random(固定シード)` で決定的にし、失敗した入力は固定コーパスへ昇格させる。

**注意**: `redis+cluster://` は構築時に実 DNS を引く。生成コーパスから除外するかモックする。

#### 探索パラメータを定数として決めておく

初版は「有界BFS」の深さ・最大ノード数・循環参照の扱い、生成する入力の個数を書いていなかった。
実装者ごとに探索量が変わり、「同じテストを回した」ことが保証されない。次の値を計画に固定する。

```
BFS の深さ上限     : 6
BFS のノード上限   : 2000
循環参照           : id() の visited セットで打ち切る
生成する入力の個数 : 5000（固定シード）
```

#### 秘密フィールドごとの生成規則が要る

上の生成規則（`SCHEMES_` / `SEPS` / `HOSTS` / `USERINFO` / `QUERIES` / `FRAGS`）はすべて
storage URI の文法で、**`RATE_LIMIT_STORAGE_URI` 専用になっている**。不変条件は「設定した秘密」
全般を対象にしているのに、生成器が1フィールドしか揺らさない。

`POSTGRES_PASSWORD`（記号入り・percent-encode 要）、`API_KEYS`（カンマ区切り・空要素・日本語）、
`OPENAI_API_KEY` / `ANTHROPIC_API_KEY` にも生成規則が要る。**「秘密フィールド × 生成規則 ×
到達する境界」の対応表を、上の trigger matrix と同じ表に統合すること。**

---

### ステップ5: ステップ4が指した箇所だけ対処（数時間）

**推測で直さない。** 4 の実測で漏れが確認された箇所だけを直す。

第3層（例外連鎖）の適用が必要な箇所:

```
app/core/rate_limit.py    _build_limiter の except
app/core/config.py        _load_settings の except
```

`raise X() from None` ではなく **`except` の外で投げる**。`from None` は `__suppress_context__` を立てるだけで `__context__` は残る。except の外で投げると `__context__` が最初から存在せず、ライブラリのフレームも traceback に載らない。

```python
cause_name = None
try:
    return Limiter(...)
except Exception as exc:
    cause_name = type(exc).__name__
    del exc
raise RateLimitStorageError(message)   # ← except の外
```

第4層（境界）として列挙する箇所:

```
limits/slowapi の Limiter 構築
alembic の set_main_option          → ステップ2で解消
SQLAlchemy の create_engine
anthropic / openai のクライアント生成と呼び出し
```

**各境界に「失敗の注入方法」と「完了条件」を書くこと。** 初版は境界を列挙するだけだったので、
ステップ4で漏えいが出たときに「どの変更を同じ周に含めるか」が再び判断待ちになる。
注入方法はステップ4の trigger matrix と1対1で対応する（3 = Limiter、4 = alembic、
5 = create_engine、6 = AI SDK）。完了条件は「その境界を失敗させたとき `observe()` が
sentinel を1つも拾わない」。

**`app/utils/ai_client.py:364,442,584` の `from e` は別クラスの問題。** `str(error)` が既に `_map_provider_exception` で新例外メッセージにコピー済みなので、連鎖を切っても秘匿効果はほぼゼロ。失うのは診断情報だけ。同じステップに束ねないこと。

**未検証の脅威モデル**: 「AI SDK の例外に `x-api-key` が載る」は再現できなかった。`str(AuthenticationError)` は `Error code: 401` のみ。到達経路は `repr(e.request.headers)` だけで、httpx は `authorization` は伏せるが **`x-api-key` は伏せない**。ステップ4のオブジェクトグラフ観測で実測すること。

---

### ステップ6: `SecretStr`（1〜1.5日）

**必ずテストを先に直して赤を確認してからアプリを直す。** 2-9 の `==` が静かに壊れるため。

アプリ側（14箇所）:

```
app/core/config.py:12        from pydantic import ... SecretStr ...
app/core/config.py:153       POSTGRES_PASSWORD: SecretStr
app/core/config.py:170       API_KEYS: SecretStr
app/core/config.py:194       RATE_LIMIT_STORAGE_URI: SecretStr
app/core/config.py:210       OPENAI_API_KEY: SecretStr | None
app/core/config.py:214       ANTHROPIC_API_KEY: SecretStr | None
app/core/config.py:236-240   model_config に validate_assignment=True   ← 必須（2-10）
app/core/config.py:246,254   DSN の f文字列 → .get_secret_value()（ステップ2で URL 化済みなら URL.create の引数）
app/core/config.py:266       API_KEYS_LIST の split
app/core/config.py:344       .strip() と ==                             ← 静かに壊れる箇所（2-9）
app/core/rate_limit.py:83    return settings.RATE_LIMIT_STORAGE_URI or None
app/utils/ai_client.py:242   api_key=
app/utils/ai_client.py:257   api_key=
```

**変更不要と実測確認済み**（真偽値評価が保たれる）:

```
app/core/config.py:354       if not target.RATE_LIMIT_STORAGE_URI:
app/core/config.py:394       if not (target.ANTHROPIC_API_KEY or target.OPENAI_API_KEY):
app/utils/ai_client.py:233,252   if settings.ANTHROPIC_API_KEY:
app/core/security.py:37      API_KEYS_LIST 経由
app/api/deps.py:125          同上
```

テスト側:

```
tests/conftest.py:67         object.__setattr__ に SecretStr(...) を渡す   ← これ1行で 57 errors が消える
                             （初版は :60 としていたが誤り。60 はコメント行。
                              82 行目にも object.__setattr__ があるが、そちらは復元側で
                              元値が既に SecretStr のため変更不要。2箇所とも触ると復元が壊れる）
tests/core/test_config.py:105,110,144,299,350   == 比較 → .get_secret_value()
tests/core/test_config.py:333                   not in message → TypeError になる
tests/core/test_config.py:360                   == DEV_POSTGRES_PASSWORD
```

段階別の実測結果:

```
アプリ側のみ変更          → 9 failed + 57 errors
+ conftest.py 修正        → 9 failed
+ test_config.py 修正     → 416 passed / 0 failed
```

**`validate_assignment=True` の副作用**: 代入が全フィールドで検証対象になる。既存テストが代入している値はすべて正当なので現時点で壊れるものは無いが、挙動変更ではある。また代入時の `ValidationError` は `_describe_validation_error` を通らないため、リスト等を代入すると値がメッセージに載る（str を代入する限り実害なし）。

**完了条件のチェックに入れること**:

```
grep -rn "settings\.\(POSTGRES_PASSWORD\|API_KEYS\b\|RATE_LIMIT_STORAGE_URI\|OPENAI_API_KEY\|ANTHROPIC_API_KEY\)" app/
```

**【2026-08-29 訂正】この節の初版には誤りがあった。** 次のように書いていた。

```
uri = SecretStr('**********')      → 漏れない
raw = uri.get_secret_value()       → 漏れる    ← 名前に束縛
sink(uri.get_secret_value())       → 漏れない  （無名の一時値）   ← ★誤り
```

**3行目は成立しない。** 呼び出し先の引数がそのフレームのローカル変数になるため、
`capture_locals=True` の traceback に平文が載る。実測:

```
sink(s.get_secret_value())        → traceback に平文が出るか: True
                                     該当行: uri = 'CANARY-9f3a7b21ee'
raw = s.get_secret_value(); sink(raw) → 出現回数: 5
```

**差は出現回数（1 対 5）であって、漏れるか漏れないかではない。** 正しくはこう:

```
uri = SecretStr('**********')      → 漏れない
raw = uri.get_secret_value()       → 漏れる（呼び出し側と呼び出し先の両方のフレームに載る）
sink(uri.get_secret_value())       → 漏れる（呼び出し先のフレームローカルに載る）。減るのは出現箇所の数だけ
```

**この誤りが危険なのは、「この書き方を守れば安全」という誤った安心を与えるから。**
チャネル3（フレームローカル）対策の中核に置かれた規律だったので、これを信じて書くと
「対処済み」と誤認した経路が残る。§7 の罠「修正の後にテストを書くと、修正が効く観測点を
無意識に選んでしまう」と同じ形の誤りが、計画書の中にあった。

**結論: フレームローカル対策は呼び出し方の規律ではなく、境界の側（ステップ5の第4層）で扱う。**
なお §2-5 のとおりこのリポジトリに Sentry は無いので、チャネル3は現時点で仮想の脅威である。
それでも誤った記述は残さない。

同じ理由で、**`API_KEYS_LIST` と `security.py:37` を「変更不要」に分類したのは軸の混同**だった。
真偽値評価としては変更不要だが、`API_KEYS_LIST` は平文の `list[str]` を生成し、認証処理は
さらに平文 bytes をローカルに保持する（§2-8）。フレームローカル対策としては未完であり、
台帳へ送る。

---

### ステップ7: main へマージし、push して観察する

Wave A はここまで。ここで初めて `fix/backend-production-hardening` を main へマージする
（ステップ1の訂正を参照。既知の漏えいを直してからマージする）。

**マージの引き金**: 完了条件6項目を満たしたらマージする。**設計・保守性の指摘が
残っていても待たない。** 残りは台帳（Issue）へ送る。「指摘ゼロまで待つ」を続けた結果が
5本4日の滞留であり、その滞留自体が「現在の状態が曖昧」という別の問題を生んでいた。

**push する。** `origin/main` は 2026-08-23 で止まっている。push しない限りどこにも
「正」が無く、レビューも判断も古い基底の上で行われる。

frontend は別案件（§4）。

---

## 4. Wave B（別途起票。この計画には含めない）

backend の秘匿と frontend のテーマには**共通の失敗原因も共通のテストも無い**。同じ計画に入れると、8周繰り返した「1周10〜15件」の再演になる。

- frontend 3本（`chore/flutter-cleanup` / `fix/contrast-accessibility-sweep` / `fix/emergency-button-overlap`）をマージ
- `ThemeExtension`（塗りと前景色を対にする `RolePair`）導入。テーマ分岐6箇所と高コントラスト判定2箇所を消す
- 構造検査テスト（backend のレイヤ依存、frontend のテーマ分岐禁止）
- `docs/consistency-fixes` を最後にマージ

**緊急度の訂正**: `colorScheme.error` の「塗りと文字の2役」問題は `fix/contrast-accessibility-sweep` で**既に解決済み**（両役で 4.5:1 を満たす色を選び直し済み）。残るのは視覚的優先度・状態識別性の設計論であって AA 違反ではない。**「今壊れているものを直す」ではなく「将来の再発を構造で防ぐ」作業。**

---

## 5. Wave A に含めないが、記録しておく既知の問題

**ステップ1で台帳（GitHub Issue）に起票する。** クラス列を付けたのは、初版がユーザー影響のある
バグと未使用コードと docs の誤記を同列に並べており、起票時に優先度の情報が失われるため。

| クラス | 内容 | 場所 |
|---|---|---|
| **P0** | **history の `isFavorite` が読み出しのたびに失われる**（Hive アダプタは保存も読み出しもしているのに `_toItem()` がハードコードで `false`）。**ユーザーのデータが壊れる。** 実在を確認済み | `lib/features/history/providers/history_provider.dart:85` |
| **P0** | 高コントラスト利用者が起動のたびに白画面を1フレーム見る。テスト TC-001 がこれを正しい挙動として固定している | `lib/core/themes/theme_provider.dart:48-51` |
| P1 | `core → db → core` のパッケージ循環。**8周のレビューで一度も指摘されていない**（レビューは差分を見るので既存の構造は視野の外） | `app/core/exceptions.py:20-21` |
| P1 | 例外を f文字列で直接ログに出す箇所が16箇所 | `ai_client.py` 7 / `exceptions.py` 5 / `ai.py` 4 |
| P1 | E2E 5本が CI 対象外（Issue #84） | |
| P2 | 環境判定 `frozenset({"development","test"})` が3ファイルに独立して存在 | `config.py:32` / `api/deps.py:42` / `main.py:63` |
| P2 | `AppException.status_code` が代入されるだけで一度も読まれない | `app/utils/exceptions.py` |
| P2 | `ApiResponse` / `ErrorDetail` が定義のみで app 内利用ゼロ | `app/schemas/common.py` |
| P2 | `crud/` がテストから参照ゼロ、実質パススルー | `app/crud/` |
| P2 | `docs/tech-stack.md:325-350` が存在しない `services/` `core/database.py` `tests/test_services/` を記載 | |
| P2 | `lib/features/README.md` が例示するディレクトリがひとつも実在しない | |
| P2 | 13コミットすべてが CLAUDE.md のコミット規約（`(TASK-XXXX)`）に違反 | |

---

## 6. 判断が必要な事項

**ステップ1で全件を台帳（GitHub Issue）へ起票し、ID・期限・判定基準を付ける。**
§0-4 は「先送りの判断が状態として残らなかった」を失敗原因に挙げ、§7 は「判断が要る項目を
先送りすると、それが次周の入力になる」と書いている。それにもかかわらず初版はこの6件を、
期限も担当も判定基準もない形で計画書という「状態を持たない場所」に置いていた。
**このままだと計画自身が §0-4 の失敗を再演する。**

| # | 内容 | 判定基準 |
|---|---|---|
| 1 | **コミット規約**: 規約側を実態に合わせるか、履歴を整えるか | どちらかを選んで CLAUDE.md に反映したら閉じる |
| 2 | **`SESSION_EXPIRE_MINUTES`**: 「消費者ゼロ」と明記されたまま残存。`SECRET_KEY` と同じ規則を適用するか | 適用する／削除する のどちらかを実施したら閉じる |
| 3 | **push のタイミング**: `main` が `origin/main` より先行し未 push。`origin/main` の最終更新は 2026-08-23 | push したら閉じる |
| 4 | **本計画の着手前に済ませてよい作業**: main の push と、競合ゼロが確認済みの frontend 2本（`fix/contrast-accessibility-sweep` / `fix/emergency-button-overlap`）のマージ。backend を一切触らないので本計画と並行できる。先に済ませると滞留が5本→3本に減り、着手時の「今どのブランチが正か」という曖昧さが消える | マージしたら閉じる |
| 5 | **ブランチ運用ルール**（同時に開ける本数の上限、マージの引き金の明文化） | 本計画には含めない。別 Issue で決める |

**初版の2（AWS CDK のパスワードに `%` が含まれうるか）は判断事項から外し、
ステップ1の作業項目に移した。** §2-1 が現存する接続バグである以上、確認するかどうかを
迷う対象ではない。

---

## 7. 進めるときに踏まないでほしい罠

この8周で実際に踏んだもの。

- **報告された経路だけを塞いで、クラスを数えない。** 秘匿を7周直したが、毎回「指摘された1つ」だけを塞いだ。修正前に「この値が外へ出る経路を全部挙げよ」と自問すること
- **修正の後にテストを書く。** 無意識に「修正が効く観測点」を選んでしまう。実際、`str(exc)` だけを見るテストを書いて、生きている漏えいを「対処済み」と証明した
- **戻り値で検証してプロセス出力で検証しない。** 1周目に `python -c "import app.main"` の出力全体を grep した修正だけは今も破れていない
- **検証環境の変数を確認しない。** `.env` が無い作業ツリーでテストを通し、`.env` が実在する本体で落ちるテストを書いた
- **手書きの許可リストを足す。** `SCHEMES` を参照しておきながら `| {"unix"}` で手書きを足し戻し、limits に存在しないスキームを信頼した
- **正しい境界で検証しない。** `urlsplit` はパスワードを percent-decode しないので、DSN の往復一致の確認には使えない。`sqlalchemy.engine.make_url` を使うこと
- **制約が過剰決定に見えたら前提を疑う。** 「エラー色と緊急色を 3:1 離すのは数学的に不可能」は、1トークンが2役を兼ねる前提でのみ真だった
- **スコープ外で先送りする。** staging ゲートの漏れは4周連続で指摘され、毎回別の話に寄せて対処しなかった。判断が要る項目を先送りすると、それが次周の入力になる
- **アプリを一度も動かさない。** 8周・418テスト・7体のサブエージェント分析を通じて、誰もアプリを起動しなかった。2-1 の接続バグは全テスト緑のまま生き残った。`pytest` が10秒で終わるので回数だけは稼げてしまい、**安い検証が高い検証を締め出す**。完了条件の6項目目はこのために置いてある
- **自分が書いた文書・コメント・メモリを「事実」として扱う。** 本計画は作成の翌日に `main` のコミット数がずれ、ステップ1の前提も誤りだった。メモリは「未マージ6本」「マージ不可」のまま数日生き延びた。どれも自分が書き、自分が古くしたもの。**外部から指摘されるまで誰も疑わない**
- **レビュアーもAIなので盲点が相関する。** 8周のレビューは `core → db → core` のパッケージ循環を一度も見つけなかった（差分の外にあるため）。誰もアプリを起動しなかった。脅威モデルを誤った（「SDK例外に `x-api-key` が載る」は再現できず）。複数エージェントは有効だが、**全員が同じ種類の検証しかしない**点では相関している。
  **2026-08-29 の対処**: 種類の違う2系統（Claude / Codex CLI）を当てたところ、プロセス設計側の
  指摘と実装精度側の指摘が系統ごとにきれいに分かれ、独立に到達した指摘は6件だった。
  **系統を分けると盲点の相関が下がる**（ステップ0の「レビューの仕様」に反映済み）
- **観測面を増やして満足し、そこに何かを流す経路を用意しない。** 出力先が空のままなら秘密検査は
  必ず緑になる。**正しい面を見ているが何も起きていない**という失敗は、「対処済みと証明したが
  生きていた漏えい」と見分けがつかない。観測面を足したら、それを発火させる経路を同時に書くこと
  （ステップ4の trigger matrix）
- **「安全なトークンだけで組み立てる」と言いながら、無限集合を安全側に入れる。** ホスト名を
  「厳格な文法に一致すれば安全」と分類した時点で、それは引き算に戻っている。**許可集合が
  有限であることを、集合を書き下して確認すること**
- **自分が「実測確認済み」と書いた記述を、次に読むとき検証しない。** ステップ6の規律
  （`sink(get_secret_value())` なら漏れない）は誤りで、別系統のレビューで canary を通されるまで
  1日生き延びた。**「実測」というラベルは、その実測を再現できる形（コード片・出力）を
  併記して初めて意味を持つ**
