# 秘密情報の漏えい対策と、レビュー往復が収束しない問題への対応計画

作成: 2026-08-28 ／ 最終更新: 2026-08-28
状態: **未着手**（別セッションで実施予定）

この文書は単独で読めるように書いてある。前提となる会話の文脈は不要。

> **この文書の記述は 2026-08-28 時点の実測値である。着手時に §1 を再確認すること。**
> 作成の翌日には既に `main` のコミット数がずれていた。自分（または前のセッション）が
> 書いた文書は、次に読むときには「検証されていない主張」であって事実ではない。
> 数字・パス・行番号は、使う前に必ず現物で確かめること。

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

`main` は `origin/main` より **3 コミット先行**。**push 未実施**（`origin/main` の最終更新は 2026-08-23）。

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
触るブランチも**ゼロ**である。

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

### 2-2. コミット済みコードに生きた漏えいが3件

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

ただしチャネル3について注意: **このリポジトリに Sentry は無い**（grep 0件）。チャネル3は将来レポータを導入した場合の話。**現に実在する害はチャネル2で、`app/core/exceptions.py:88` の `traceback.format_exc()` が連鎖トレースバックを `error_logs` テーブルに永続化している。**

### 2-6. 第4層（境界）が必要

`alembic` の漏えい（2-3）と、8周で直した `rate_limit` の漏えいは**同じ形**である。どちらも「サードパーティが我々の秘密入り文字列を自分の例外メッセージに埋める」で、違いは catch する人がいたかどうかだけ。

「`except` を書く場所」を適用範囲にすると、catch されない側を原理的に取りこぼす。**範囲を反転させ、秘密を含む文字列をサードパーティへ渡す境界を列挙する**必要がある。境界は数えられる規模: `Limiter`、alembic の `set_main_option`、`create_engine`、AI SDK のクライアント生成。

### 2-7. DB が第4のシンク

3チャネルの議論は stderr / ログ / トレースバックを対象にしていたが、**一度漏れたら消えない唯一の面**が抜けていた。

- `app/core/exceptions.py:87-100` — `str(exc)` と `traceback.format_exc()` を `error_logs` テーブルへ
- `app/api/v1/endpoints/ai.py:251` — `error_message=str(error)` を `ai_conversion_logs` へ
- `app/core/logging_config.py:30-34` — `logs/app.log` への FileHandler

### 2-8. `SecretStr` の効果と限界

**効くもの**: `repr(settings)` / `str(field)` / f文字列 / `model_dump` / pytest のアサーション表示 / フレームローカル / `.get_secret_value()` 忘れの型検出。

**効かないもの**:

- `extra="forbid"` のタイポ（`ANTHROPIC_API_KEYS=...`）。未宣言キーには型が付かない。**正しい対策は `errors(include_input=False)`**。既存の `app/core/config.py` の `_describe_validation_error`（loc + msg のみ抽出）が実質同等のことをしており、**`SecretStr` を入れても恒久的に必要**
- `settings.DATABASE_URL` は `SecretStr` にしても平文の str のまま。**`URL` 化と補完関係**にある

**過去に実際に起きた13件の欠陥のうち、`SecretStr` で防げるものは 0 件。** 価値はあるが優先度は最上位ではない。

### 2-9. `SecretStr` は `==` を静かに壊す

```
SecretStr('x') == 'x'   → False   ← 例外を出さず常に False
SecretStr('x').strip()  → AttributeError（気づける）
```

`app/core/config.py:344` の `target.POSTGRES_PASSWORD == DEV_POSTGRES_PASSWORD` を直し忘れると、**「本番で開発用デフォルトパスワードのまま起動する」検査が黙って無効化される**。セキュリティ後退。

### 2-10. `SecretStr` は `validate_assignment=True` とセットでなければ既存テストを壊す

`tests/` に `monkeypatch.setattr(settings, ...)` が **24箇所**ある。`validate_assignment=True` があれば str → SecretStr に自動強制されて全部動く。無いと str のまま格納され `.get_secret_value()` が実行時に落ちる。

ただし `tests/conftest.py:67` の `object.__setattr__` は `__setattr__` 自体を迂回するので **`validate_assignment` では救えない**。ここは別途 1行修正が要る（後述）。

---

## 3. 実行計画

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

1. **P0（実証済みバグ）が0件。** 「実証済み」の定義は「その指摘を赤にする自動テストが実際に書けたもの」。書けないなら P0 ではない
2. **過去周に書いた再現テストが全部緑**
3. **既存 CI ゲートが緑**（`ruff check app tests` / `black --check app tests` / カバレッジ閾値）
4. **未対応の指摘が全件 ID 付きで台帳に載っている。** 0件である必要はない。「棚卸し済み」が条件
5. **2周連続で新規 P0 が0件**
6. **アプリを実際に起動し、変更した機能が動くことを確認した**（`scripts/smoke.sh` の通過）

到達目標は「指摘ゼロ」ではなく **「未分類の指摘ゼロ」**。

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

#### `scripts/smoke.sh` の最小仕様

単体テストが通らない層——**設定の組み立てから実接続まで**——だけを対象にする。

```
1. docker compose up -d
2. /api/v1/health が 200 かつ database: connected を返すまで待つ（タイムアウト付き）
3. 記号（% と @）を含むパスワードのロールを一時作成し、
   alembic upgrade head / downgrade base と非同期接続が通ることを確認
4. 後片付け（作成したロール・DBを削除）
```

**広げないこと。** AI変換の疎通や認証まで入れるとスモークテスト自体が肥大化し、
別の8周を生む。必要になってから足せばよい。

なお `backend` サービスには healthcheck が無い（`postgres` にはある）。
`docker compose up` が「起動した」と言うのに実際は死んでいる状態を検出できないが、
これは本計画の範囲外とし、別途対応する。

---

### ステップ2: `URL` 化 + alembic 脱 `set_main_option`（半日）

**最優先。** セキュリティ修正であると同時に 2-1 の接続バグの修正でもある。**テスト変更ゼロで 416 passed が実証済み**（`.env` の無い複製環境での計測。ワークツリーでは 418）。

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

`tests/conftest.py` は無影響。alembic を `command.upgrade/downgrade` で呼ぶだけで `get_main_option` にも `sqlalchemy.url` にも触れていない。

**検証**: ステップ1で作った `scripts/smoke.sh` を通す。これが**本計画で初めて
「アプリを実際に動かす」検証**になる。単体テストは 2-1 の接続バグを構造的に見逃すので、
ここを飛ばすと同じ穴が残る。

---

### ステップ3: 生きた漏えい3件（数時間）

2-2 の3件。ステップ2と同じ性質なので続けて実施する。

**引き算をやめ、組み立てにする。** 入力から危険部分を除去するのではなく、**出力に使ってよいトークンを閉じた集合に限定する**。

- 使ってよいのは (a) `limits.storage.SCHEMES` の要素、(b) 厳格な文法に完全一致したホスト/ポート、(c) 固定文字列 のみ
- path / query / fragment / userinfo は「有無」だけを出す
- 文法に1文字でも外れたら構造情報を出さない
- **`SCHEMES` を手書きで拡張しない**（`| {"unix"}` が今回の再発原因）
- **表示関数は全域関数にする**（絶対に例外を投げない）。`urlsplit('redis://[::1')` は `ValueError` を投げる

`app/core/rate_limit.py` の秘匿機構は約184行あるが、原因例外のメッセージを埋め込むのをやめれば `_scrub_credentials` / `_password_fragment` / `_contains_credential_shape` は不要になり、25行程度になる見込み。

**ただしステップ4の結果を見てから最終形を決めること。** 何を秘匿する必要が残るかは4で確定する。

---

### ステップ4: 不変条件テスト（半日〜1日）

**ここで「まだ漏れる面」が推測ではなく実測で確定する。**

不変条件:

> 設定した秘密のいかなる部分文字列も、観測可能な出力のいずれにも現れない

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
- ★ DB に書かれた行（error_logs.stack_trace, ai_conversion_logs.error_message）
- ★ logs/app.log
```

★ の2つは 2-7 の理由で必須。**消えない唯一の面。**

入力生成は `hypothesis` 不要。標準ライブラリで文法ベースに生成する。

```
SCHEMES_ = list(limits.storage.SCHEMES) + ["unix", "bogus", ""]   # ライブラリから取る
SEPS     = ["://", ":", ":/", ":///", "//"]                        # '//' の有無を必ず含める
HOSTS    = ["h:6379", "[::1]:6379", "h1:26379,h2:26379", "", "h:not-a-port"]
USERINFO = ["", f"{S}@", f"u:{S}@", f"u:{quote(S)}@", f"{S}@u:{S}@"]
QUERIES  = ["", "?a=b", f"?password={S}", f"?a=b&x={quote(S)}"]
FRAGS    = ["", "#f", f"#{S}"]
```

**判定は生成器が持つ既知のシークレットとの部分一致にする。** ヒューリスティック（「`password@` の形」「12文字以上」）を使うと、それ自体が9周目の議論の種になる。

**sentinel は生成された一意で長い文字列にする。** 短い辞書語（`pass`, `host`）だと `localhost` に `host` が含まれて偽陽性が出る。短い語のケースは「診断メッセージが壊れないこと」の別テストに分離する。

`random.Random(固定シード)` で決定的にし、失敗した入力は固定コーパスへ昇格させる。

**注意**: `redis+cluster://` は構築時に実 DNS を引く。生成コーパスから除外するかモックする。

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
tests/conftest.py:60         object.__setattr__ に SecretStr(...) を渡す   ← これ1行で 57 errors が消える
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

**規律**: `.get_secret_value()` の戻り値を**名前付きローカル変数に束縛しない**。束縛した瞬間にフレームローカル経由の漏えいが再開通する。

```
uri = SecretStr('**********')      → 漏れない
raw = uri.get_secret_value()       → 漏れる    ← 名前に束縛
sink(uri.get_secret_value())       → 漏れない  （無名の一時値）
```

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

| 内容 | 場所 |
|---|---|
| `core → db → core` のパッケージ循環。**8周のレビューで一度も指摘されていない**（レビューは差分を見るので既存の構造は視野の外） | `app/core/exceptions.py:20-21` |
| `AppException.status_code` が代入されるだけで一度も読まれない | `app/utils/exceptions.py` |
| `ApiResponse` / `ErrorDetail` が定義のみで app 内利用ゼロ | `app/schemas/common.py` |
| `crud/` がテストから参照ゼロ、実質パススルー | `app/crud/` |
| 環境判定 `frozenset({"development","test"})` が3ファイルに独立して存在 | `config.py:32` / `api/deps.py:42` / `main.py:63` |
| 例外を f文字列で直接ログに出す箇所が16箇所 | `ai_client.py` 7 / `exceptions.py` 5 / `ai.py` 4 |
| `docs/tech-stack.md:325-350` が存在しない `services/` `core/database.py` `tests/test_services/` を記載 | |
| **history の `isFavorite` が読み出しのたびに失われる**（Hive アダプタは保存も読み出しもしているのにハードコードで `false`） | `lib/features/history/providers/history_provider.dart:85` |
| 高コントラスト利用者が起動のたびに白画面を1フレーム見る。テスト TC-001 がこれを正しい挙動として固定している | `lib/core/themes/theme_provider.dart:48-51` |
| `lib/features/README.md` が例示するディレクトリがひとつも実在しない | |
| 13コミットすべてが CLAUDE.md のコミット規約（`(TASK-XXXX)`）に違反 | |
| E2E 5本が CI 対象外（Issue #84） | |

---

## 6. 判断が必要な事項

1. **コミット規約**: 規約側を実態に合わせるか、履歴を整えるか
2. **AWS CDK が生成するパスワードに `%` が含まれうるか。** ステップ2を入れるまでは `%` を除外する設定が入っているか確認する価値がある（`infra/` は未精査）
3. **`SESSION_EXPIRE_MINUTES`**: 「消費者ゼロ」と明記されたまま残存。`SECRET_KEY` と同じ規則を適用するか
4. **push のタイミング**: `main` は `origin/main` より 3 コミット先行、未 push。
   `origin/main` の最終更新は 2026-08-23
5. **本計画の着手前に済ませてよい作業**: main の push と、競合ゼロが確認済みの frontend 2本
   （`fix/contrast-accessibility-sweep` / `fix/emergency-button-overlap`）のマージ。
   backend を一切触らないので本計画と並行できる。先に済ませると滞留が5本→3本に減り、
   着手時の「今どのブランチが正か」という曖昧さが消える
6. **ブランチ運用ルール**（同時に開ける本数の上限、マージの引き金の明文化）は本計画に
   含めない。別途決めること

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
- **レビュアーもAIなので盲点が相関する。** 8周のレビューは `core → db → core` のパッケージ循環を一度も見つけなかった（差分の外にあるため）。誰もアプリを起動しなかった。脅威モデルを誤った（「SDK例外に `x-api-key` が載る」は再現できず）。複数エージェントは有効だが、**全員が同じ種類の検証しかしない**点では相関している
