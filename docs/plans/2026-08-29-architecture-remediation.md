# アーキテクチャ是正計画

作成: 2026-08-29 ／ 状態: **Phase 0 未着手**

この文書は単独で読めるように書いてある。前提となる会話の文脈は不要。

> **数値は 2026-08-29 時点の実測値である。** 着手時に §2 を測り直すこと。
> 自分（または前のセッション）が書いた文書は、次に読むときには
> 「検証されていない主張」であって事実ではない。

---

## 1. この計画が生まれた理由

「設定値の秘密情報がログ・例外・DB に漏れる」問題で、修正 → AI レビュー → 再指摘を
**8周**繰り返したが収束しなかった。うち1周は前周の修正が作った穴だった。

原因を2系統（Claude / Codex CLI）で独立に調べた結果、**コードの問題ではなかった**。
決めていなかった2つの設計判断が問題を作り出していた。

このプロジェクトは 2025-10 に Claude 4 + Tsumiki で開始し、技術選定はしたが
**アーキテクチャを詰めていない**。全体方針に沿うことはあまり意識されず、
その時々の判断で実装されてきた。8周はその帰結である。

**インフラのデプロイもアプリのリリースも、まだ一度も行われていない。**
移行すべき実データが無いため、大きな構造変更のコストが例外的に低い。

---

## 2. 現状（2026-08-29 実測）

```
backend  app/    3,545 行 / 32 ファイル / 公開ルート 3本（AI変換2 + health 1）
         tests/  9,221 行
frontend lib/   19,358 行 / 157 ファイル / 8画面
         test/     177 ファイル
```

ブランチは `main` と `fix/backend-production-hardening` の2本。
`main` は `origin/main` と一致（2026-08-29 に push 済み）。

frontend 4本（アクセシビリティ・緊急ボタン・codegen撤去・docs整合）はマージ済み。
テストは frontend 1,943件・backend 334 passed / 4 skipped で全てグリーン。

---

## 3. 決定

### 決定1 — backend からデータベースを外す

**実測**: `app/db/` の外に SELECT 文が **0件**。`crud/` の関数は
`create_conversion_log` ただ1つ。`ai_conversion_logs` と `error_logs` は
**書き込み専用**で、何も読まない。

この DB が次のすべての原因である。

| 消えるもの | 内訳 |
|---|---|
| `%` / `@` を含むパスワードで DB に接続できないバグ | DSN が無くなる |
| alembic が DSN 全文を例外に載せる漏えい | alembic が無くなる |
| `core → db → core` のパッケージ循環 | `core/exceptions.py` が db を import するのは `error_logs` に書くためだけ |
| 「消えないシンク」 | `error_message=str(error)` の行き先が無くなる |
| プライバシーポリシー違反 | 入力のソルト無し SHA-256・文字数・セッションUUID の保存が無くなる |
| 恒常的に失敗している migration テスト2本 | |
| 本番コード **1,135行**（backend の 32%） | `db/` 183 + `models/` 254 + `crud/` 84 + `alembic/` 465 + `alembic.ini` 149 |
| 削除できるテスト 約1,700行 | `test_models_logs.py` 963 / `db/test_session.py` 341 ほか |
| docker-compose と CI の postgres、conftest の DB fixture 群 | |
| デプロイの複雑さ | VPC・RDS・DBパスワードのローテーションが不要。ステートレスなコンテナ1つになる |

**運用情報は捨てない。** レイテンシ・成功率・プロバイダ別エラー率は標準出力への
構造化ログ（JSON）で取る。**ユーザー由来の内容を一切含めない**——入力のハッシュも
文字数も要らない。

将来サーバー側の状態が要る機能が出たら、そのときステートレスなサービスに DB を足す。
逆（後から外す）が難しいことは、この4日間が証明した。

### 決定2 — レート制限を単一インスタンス前提にする

8周のうち**7周を占めた `redact_storage_uri`**（秘匿機構 約184行）は、Redis 接続URIの
パスワードを伏せるためだけの関数である。`memory://` には秘匿すべきものが
1文字もないので、関数ごと不要になる。

**この関数は `main` には存在しない**（`fix/backend-production-hardening` 上のみ。
main の `rate_limit.py` は198行で、秘匿処理を持たない）。つまり決定2は、
「既にあるものを消す」のではなく **「作りかけのものを引き取らない」** 判断である。

利用者ゼロ・単一端末完結・backend は AI 変換のみ。マルチワーカーが必要になる規模には
当分到達しない。必要になった日に、そのとき数値を見て Redis を足す。

### この2つで、8周が対象にしていたものが全部消える

| 8周で扱った問題 | 原因の秘密 | 決定後 |
|---|---|---|
| 秘匿7周（`redact_storage_uri`） | `RATE_LIMIT_STORAGE_URI` | 決定2で消滅 |
| `%`/`@` 接続バグ・alembic 漏えい・DBシンク | `POSTGRES_PASSWORD` | 決定1で消滅 |
| 端末APIキー認証 | `API_KEYS` | 残る |
| AI プロバイダ呼び出し | `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` | 残る — **サーバーが存在する唯一の理由** |

秘密は5つから2種類に減り、どちらもプロセス内で完結する。
秘匿は「漏らさないよう注意する」ではなく「渡す先が無い」になる。

---

## 4. backend と frontend は逆の扱いにする

| | backend | frontend |
|---|---|---|
| 規模 | 3,545行 / 3ルート / ドメインなし | 19,358行 / 8画面 / 17 feature |
| 正体 | ステートレスな AI 変換プロキシ | **プロダクトそのもの** |
| 存在理由 | AI プロバイダのキーを端末に置けない、それだけ | 利用者が触れるすべて |
| 方針 | **書き直す**（到達点 約1,000行） | **直す** |

**backend を書き直す理由**: 決定1・2で 1,135行が消え、`config.py` の半分と
`rate_limit.py` の184行も消える。残すのは `ai_client.py` のプロバイダ処理と
プロンプト、`schemas/` の入出力定義だけ。**リファクタリングより書き直しのほうが小さい。**
既存を段階的に直すと、消える予定のコードにテストを書くことになる。

**frontend を書き直さない理由**: アクセシビリティ対応（コントラスト AA 準拠、
タップターゲット、高コントラストテーマ、色以外の識別手段）、TTS、文字盤、定型文、
緊急ボタンが入っている。捨てると失われる実質的な作業がある。構造
（`features/*/{data,domain,providers,presentation}`）自体は妥当で、欠陥は
特定できる場所にある。

---

## 5. フェーズ

### Phase 0 — 決める（1〜2日）

**コードには触らない。** ADR を6本書く。1枚1決定、**決めたこと・却下した案・却下の理由**の
3つがあれば足りる。

```
ADR-001  backend はステートレス。サーバー側にユーザー状態を持たない
ADR-002  レート制限は単一インスタンス前提。memory:// を既定とする
ADR-003  エラーは型で表現する。自由文字列をログ・レスポンスに載せない
ADR-004  設定は不変。Application Factory で組み立て、グローバルに置かない
ADR-005  frontend は1概念1真実。永続化の失敗は利用者に伝える
ADR-006  レイヤ依存は import-linter で強制する
```

ADR が効くのは「その時々の判断で実装される」を止める唯一の手段だから。
ただし**文書は破れる**ので、ADR-003 / 004 / 006 は Phase 4 で型と lint に落とす。
文書と検査を対にして初めて機能する。

置き場所は `docs/adr/`。

### Phase 1 — `fix/backend-production-hardening` を処理する（1日）

15コミット・+2,317行。**大半は決定1・2で対象そのものが無くなる。**

方針は「必要な部分だけ拾う」。丸ごとマージすると、消す予定のコードが履歴に入るだけになる。

| 拾うもの | 理由 |
|---|---|
| 端末APIキー認証（`app/core/security.py` / `app/api/deps.py`） | DB と無関係。新 backend でもそのまま使う |
| 本番ゲートの考え方 | 対象フィールドは変わるが、起動時フェイルファストの設計は生きる |
| 発見されたバグ | 散文ではなく**テストとして**新 backend へ移す |

ブランチ自体は削除せず、証拠として残す。`docs/verification-principles.md` に
知見は抽出済み。

### Phase 2 — backend を書き直す（5〜8日）

新しい最小 backend を並行して作り、動いたら差し替えて旧を削除する。
**本番が無いので切り替えのリスクはゼロ。** frontend からは同じ URL・同じスキーマ。

```
app/
  main.py        create_app(config) — Application Factory。import だけでは資源を作らない
  config.py      RuntimeConfig(frozen=True)。secret は SecretStr、DSN は無い
  routes.py      POST /ai/convert, POST /ai/regenerate, GET /health
  ai/            プロバイダ client（lifespan で生成）+ プロンプト
  errors.py      ErrorCode(StrEnum) と SafeError。str(exc) を受け取る口を作らない
  logging.py     stdout への構造化ログ。ユーザー由来の内容を含めない
```

順序: 決定1（DB削除）→ 決定2（`memory://`）→ Application Factory → エラー型 → 設定の不変化。

**テストは捨てて書き直す。** 現在 9,221行のうち assert は7%で、誤った仕様を固定し
（存在しない `unix` スキームを正解として要求）、漏えいシンクを36箇所でモックしている。
書き直す backend に対しては負の資産である。到達点は約1,500行、層は3つ——
プロバイダ SDK を `respx` でモックした API テスト、設定組み立ての単体テスト、
記号入りキーを含む起動 smoke。

### Phase 3 — frontend の正しさを直す（5〜8日）

利用者に直接届く順に並べてある。

1. **永続化の状態を明示する。** いま Hive が開けないと `repository_providers.dart` が
   黙って `null` を返し、インメモリで動き続ける（`hive_init.dart` が意図した設計として明記）。
   **発話支援アプリで「保存できたように見えて消える」は、起動しないことより重い。**
   `sealed class PersistenceState { Ready / RecoverableFailure / Unavailable }` にして、
   保存されないことを利用者に伝える。
2. **「お気に入り」を1つの真実にする。** いま `HistoryItem.isFavorite`（書かれるが常に
   `false`、UI は読まない）、`features/favorite/`（ロジック）、`features/favorites/`（UI）の
   3箇所に散っている。UI が実際に使っているのは `favoriteProvider` なので、
   `HistoryItem.isFavorite` を Hive migration で削除する。キーは内容テキストではなく id にする。
3. **往復テストを feature ごとに1本。** UI → provider → repository → storage → 戻り。
   層を飛ばして下だけを叩くテストは、単体では合格にしない。
   （`isFavorite` のバグは Hive アダプタのテストが緑のまま生き残った。バグは
   その上の変換層にあった。）
4. **E2E 5本を書き直して CI に戻す**（Issue #84）。**戻すだけでは直らない**——
   `history_favorite_test.dart` は廃止済みの削除確認ダイアログを期待しており、
   戻した瞬間に赤くなる。

### Phase 4 — 逆戻りを防ぐ検査を入れる（2〜3日）

ADR-003 / 004 / 006 を実行可能にする工程。ここまでやって初めて決定が持続する。

- `import-linter` — レイヤ契約を CI で強制（`core → db → core` の再発を防ぐ）
- `pytest-randomly` — グローバル状態への依存を露出させる
- `mypy` strict / Dart analyzer ルール
- **保存列の許可リスト検査** — モデル定義を読み、ユーザー由来の自由文の列・
  入力のハッシュ列が許可リスト外に増えたら落ちる。プライバシーポリシーとの
  乖離は差分レビューでは永久に見つからないため、構造で検知する

### Phase 5 — docs を整理する（2〜3日）

**判断基準**: 「入力」か「実行可能」なものは残し、「工程の記録」は捨てる。

| | 対象 | 扱い |
|---|---|---|
| 残す | 要件（EARS）・受入基準 | Tsumiki の出力としてではなく**プロダクト仕様として引き取る** |
| 残す | アクセシビリティ基準（WCAG AA、44/60px、フォント3段階、テーマ3種） | このプロダクトの核。**テストとして実行可能にする** |
| 残す | privacy-policy.md | 実装に合わせて書き直す（決定1で自動的に整合する） |
| 捨てる | 【】記法コメント | frontend lib 約1,200行ほか |
| 捨てる | 🔵🟡🔴 信頼性レベル記号 | 生成時点の確信度であって、コードの性質ではない |
| 捨てる | tech-stack.md の実在しない構成記述 | `infra/` `services/` `core/database.py` `tests/test_services/` |

**正本を1つずつ決める**: API は OpenAPI、環境変数は `RuntimeConfig`、UI 仕様は Widget テスト、
データ保持は ADR + privacy-policy。

---

## 6. 完了条件

各フェーズはこれを満たしたら閉じる。判定は機械的に行えること。

| Phase | 完了条件 |
|---|---|
| 0 | `docs/adr/` に6本存在し、それぞれ「決定・却下案・理由」を含む |
| 1 | `fix/backend-production-hardening` から拾う対象が特定され、ブランチが閉じている |
| 2 | `app/models` `app/crud` `app/db` `alembic` が存在しない。`grep -rn "str(exc)\|str(e)\|format_exc" app/` が 0件。記号を含む API キー・プロバイダキーを設定した状態で起動し、`/health` が 200 を返し AI 変換が1往復する smoke が通る |
| 3 | Hive が開けないとき利用者に通知される。`isFavorite` が存在しない。往復テストが4 feature に存在。E2E 5本が CI で緑 |
| 4 | `import-linter` `pytest-randomly` `mypy --strict` が CI に入り緑。保存列の許可リスト検査が存在 |
| 5 | `docs/adr/` `docs/spec/` `docs/privacy-policy.md` 以外の現行文書が archive へ移動済み |

**「指摘ゼロ」を完了条件にしない。** それは成果物の性質ではなくレビュアーの出力の性質で、
十分な探索予算があるレビューは必ず何かを見つける。詳細は
`docs/verification-principles.md`。

---

## 7. 台帳へ送る既知の問題

Phase 0 で GitHub Issue に起票する。ラベルは `deferred` / `rejected`。

| クラス | 内容 | 場所 |
|---|---|---|
| P1 | 例外を f文字列で直接ログに出す箇所が16箇所 | `ai_client.py` 7 / `exceptions.py` 5 / `ai.py` 4 — Phase 2 で消える |
| P1 | E2E 5本が CI 対象外 | Issue #84 — Phase 3 で対応 |
| P1 | 高コントラスト利用者が起動のたびに白画面を1フレーム見る | `lib/core/themes/theme_provider.dart`。テスト TC-001 がこれを正しい挙動として固定している |
| P2 | 環境判定 `frozenset({"development","test"})` が3ファイルに独立して存在 | `config.py` / `api/deps.py` / `main.py` — Phase 2 で1箇所に寄せる |
| P2 | `AppException.status_code` が代入されるだけで読まれない | `app/utils/exceptions.py` |
| P2 | `ApiResponse` / `ErrorDetail` が定義のみで利用ゼロ | `app/schemas/common.py` |
| P2 | `lib/features/README.md` が例示するディレクトリがひとつも実在しない | |
| 判断 | コミット規約: 規約側を実態に合わせるか、履歴を整えるか | CLAUDE.md |
| 判断 | `SESSION_EXPIRE_MINUTES`: 消費者ゼロのまま残存 | Phase 2 で削除される見込み |
| 判断 | ブランチ運用ルール（同時に開ける本数の上限、マージの引き金） | 下記 |

**ブランチ運用**（Phase 0 で決めて CONTRIBUTING.md へ）: 同時に開くのは2本まで／
セキュリティ対応は同時1本／寿命は原則1営業日／CI が緑なら小さい独立差分は先にマージ／
`main` は日次で push して「正」を1つにする／**「指摘ゼロ」をマージ条件にしない**。

2026-08-24 に5本が同じ6分間に切られ、4日以上滞留した。本流が動かないと
ブランチ上で完璧を目指す圧力がかかり、それが8周の環境条件になった。

---

## 8. 参照

| 何 | どこ |
|---|---|
| 検証と完了判定の原則（8周から抽出） | `docs/verification-principles.md` |
| 秘匿処理が収束しなかった経緯の記事 | `docs/articles/why-redaction-fixes-dont-converge.md` |
| アーキテクチャ決定 | `docs/adr/`（Phase 0 で作成） |
| Tsumiki 生成物の歴史記録 | `docs/archive/` |

この計画は Phase 5 の完了時に破棄する。残すべき内容は ADR と実行可能な検査に
移されているはずで、移せていないものがあれば、それは移すべきものである。
