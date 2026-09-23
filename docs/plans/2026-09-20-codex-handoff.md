# Codex 引き継ぎ（2026-09-20）

**破棄条件: 下の束がすべてマージされ、台帳の該当行が `[x]` になったら、この文書を削除する PR を出す。**

読む順: `AGENTS.md`（核。規律と規約はそこが正本。ここには繰り返さない）→ `docs/ledger.md` の該当行 → この文書。
**この文書は仕様の正本ではない。** 決定の正本は台帳の各行、規律の正本は AGENTS.md。食い違ったらそちらが正。

---

## 0. 最初に読むべき「非自明な罠」

**ここだけは、コードからもコミット履歴からも読み取れない。**すべて実際に踏んで機序を特定したもの。

### テストが嘘の緑になる 4 つの形

1. **`testWidgets` の中で実処理を `await` するとハングする。**
   機序は `FakeAsync`。Hive のファイル I/O もプラットフォームプラグインも同じ。
   脱出は `tester.runAsync()`。既存の 7 ファイルが使っているので形を真似る。

2. **同じ木で override を変えて連続 `pump` すると偽の緑になる。**
   override は更新されるが、**生成済みの Notifier と値が残る**。
   状態ごとに独立した `pump` にする（`pumpWidget` からやり直す）。

3. **固定の箱の中の `Text` は `size` や矩形で測ると常に緑になる。**
   折り返しは `getMaxIntrinsicWidth` で見る。
   **OS の文字拡大（1.3 倍）も掛ける**こと。掛けずに測って「いいえ」が「いい」に切れたのを見逃した実績がある。
   あふれは幅 320 / 360、合成倍率 2.4 まで見る（既存のテストがその値を使っている）。

4. **変異の後片付けを `git checkout` にすると偽の緑になる。**
   2 回目以降の変異が no-op になり、作業中の実装も消える。
   **バックアップを取り、`diff` で置換が入ったことを確かめてから**テストを走らせる。

### 観測点がすり替わる形

- **`length($0)` と `wc -c` はバイトを返す。**日本語は 1 文字 3 バイトなので約 3 倍に見える。文字数は `wc -m`。
- **パイプの終了コードを見ない。**`flutter drive … | tail` の終了コードで「E2E 緑」と言った事故がある。
- 主張の直前に「この観測点は、壊れていたら赤くなるか」を問う。答えられなければ**意図的に壊して赤を見る**（規律 2）。

### 環境

- Flutter は `fvm` 経由の **3.38.1**（`.fvmrc`）。`fvm flutter …` で呼ぶ。
- `pubspec.lock` の drift は **#162 で解消済み**。`pub get` や `test` の後に lock が動いたら、それ自体が異常なので報告する。
- backend は `backend/.venv`。`export PATH="$PWD/.venv/bin:$PATH"` してから使う。
- `pre-commit` が入っている。コミット出力は全部読む（黙って止まることがある）。
- **`git worktree` を使う場合**、`GIT_DIR` の影響で flutter が SDK 版を誤認することがある。使わないのが無難。

### Hive を触るとき

- `delete` は印を置くだけで、元データは `compaction` まで `.hive` に残る。
- `compact` は上書き `put` と重なると項目を落としうる。**書き込みは直列化する**（`PersistedBox` がその形）。
- hive は `.hivec` の rename 前に `fsync` しない。この窓は上流の挙動で塞げない（L-126 で受け入れ済み）。
- `Hive.openBox` が失敗すると、hive は失敗した box の `close()` を await せずに呼び、その後始末が `.lock` を消す。
  テストの後片付けは `closeHiveIgnoringMissingLock` を使う（`test/core/utils/hive_open_leak_guard.dart`）。

---

## 1. 毎回の手順

### 着手前（規律 4）

触るファイルを列挙して数え、**未卒業 ADR 5 本それぞれに yes/no を PR 本文へ書く**。

| ADR | 主題 |
|---|---|
| ADR-002 | レート制限（プロセス内メモリ、XFF は 1 箇所） |
| ADR-005 | frontend は 1 概念 1 真実／永続化の失敗は利用者に伝える |
| ADR-007 | リリース基準（条件 4 つで閉じる） |
| ADR-009 | クラッシュ報告は送らない |
| ADR-010 | 文書は 5 種類（核 120 行、ADR 60 行、台帳 1 本） |

yes の行だけ本文を読む。あわせて**規律 8 の 8 行為**（依存の追加・永続化面・秘密を持つ設定キー・可変グローバルと公開ルート・外部送信先・モバイル権限・検査/フック/workflow/スクリプトの自作）に当たるかを見て、当たるなら根拠 ADR か台帳の決定を引用する。

### 検証（規律 1・2）

```bash
# frontend
(cd frontend/kotonoha_app && fvm flutter analyze --no-fatal-infos \
  && fvm flutter test \
  && fvm dart format --output=none --set-exit-if-changed .)

# backend
(cd backend && export PATH="$PWD/.venv/bin:$PATH" && pytest && make check)
(cd backend && export PATH="$PWD/.venv/bin:$PATH" && make mutation)   # kill rate は台帳へ
```

`analyze` は **info だけなら緑**（`--no-fatal-infos`）。error / warning が 0 であることを内訳で示す。
UI を変えたら**ブラウザで実際に動かして確かめる**（`fvm flutter run -d chrome`）。

### 制約

- **1 変更は 400 行 / 12 ファイルまで。**超えるなら束を割る（決定を分けるのではなく PR を分ける）。
- **`docs/ledger.md` は必ず触る**（該当行を `[x]` にする、または持ち越しを足す）。
  **複数の PR が近い行を触ると必ず衝突する。**マージは 1 本ずつ。衝突したら両側の行を残して L 番号順に並べ直す。
- 台帳の行は「1 問題 1 行＋出所。**経緯は書かない**」。長い説明は PR 本文へ。
- コミットは `docs:` / `feat:` / `fix:` / `ci:` / `chore:` ＋ 日本語 1 行。エージェントが書いたら末尾に `Co-Authored-By`。

### 止まって報告する条件

- 決定が要ると気づいたとき。**その場で 1 件だけ聞かず、まとめて出す**（決定シートの形。#152・#160・#161 が手本）。
- P0（到達経路を示せて、かつ実際に赤を見せた）を見つけたとき。**格下げ・繰り延べを実装者が単独で決めない。**
- 「指摘ゼロ」を完了条件にしない。マージの引き金は完了条件であって指摘ゼロではない。

---

## 2. 束の一覧

依存と衝突:

```
PR1 (3-a) ──┐  テーマを取り合う
            ├──→ PR3 (3-b②)
PR2 (3-b①) ─┘  ※ PR2 は削除のみでテーマを触らないので PR1 と同時に出せる

PR4 (B) / PR5 (Hive) / PR6 (文書) / PR7 (L-109) / C1〜C4 ── 互いに独立
C2 は C1 のマージ後（kill rate の分母が動くため）
```

### PR1 — 束 3-a: 枠線をテーマへ寄せる（L-141・L-140・L-142）

決定（台帳より）: 常に枠線を引く／枠線はテーマ側に寄せて 1 箇所に／2.87:1 はテーマ側で解く。

- `lib/shared/widgets/confirmation_dialog.dart:190` の**閾値の分岐を撤去**し、`side` はテーマが決める形にする
- `lib/core/themes/{light,dark,high_contrast}_theme.dart` に `elevatedButtonTheme.side` を置く
- 枠線の色は**面の輝度だけでなく塗りとの比でも**選ぶ（面と塗りが同系の中間輝度のとき黒枠が埋もれる）
- L-142: 同じ 2.87:1 が `ConfirmationDialog` の外（チュートリアルの「次へ」）にも残っている。テーマ側で解けば届く

完了条件: 3 テーマ × `normal`/`destructive` で非テキストコントラスト 3:1 以上を**テストで実測**。チュートリアルの「次へ」もブラウザで確認。
注意: `test/shared/widgets/confirmation_dialog_contract.dart` は**本番の呼び出し元から**当てること（L-135 で直した形を崩さない）。

### PR2 — 束 3-b①: 到達経路 0 の削除（L-139・L-77・L-66・L-96）

決定: `lib/` からの呼び出し・参照が 0 のものは消す。

| 対象 | 実測 |
|---|---|
| `lib/core/widgets/error_dialog.dart`（398 行） | `showErrorDialog` / `showNetworkErrorDialog` / `showAIConversionErrorDialog` / `showTTSErrorDialog` / `showErrorSnackBar` はすべて `lib/` からの呼び出し 0 |
| `lib/shared/widgets/text_input_field.dart`（84 行） | 同上 |
| `network_aware_scaffold.dart:115` の `showOfflineAIConversionDialog` | 同上 |
| `lib/core/utils/logger.dart:10` の `LogLevel` | `lib` 内で参照 0 |
| `frontend/kotonoha_app/web/.env.example`（51 行） | `lib` から参照 0。ビルド出力に複製される死んだ設定 |

**`.env.example` は規律 8 の「秘密を持つ設定キー」に当たる。**PR 本文に yes と根拠（台帳 L-96 の決定）を書く。
参照していたテスト（`error_dialog` 4 本、`logger` 1 本、`text_input_field` 1 本、`showOffline…` 1 本）も一緒に消す。
完了条件: 削除後に `grep` で参照 0 を再確認し、analyze と全テストが緑。

### PR3 — 束 3-b②: 死蔵コードとタップ領域（L-100・L-134）— PR1 の後

- L-100 `preset_phrase_notifier.dart:292` の `resetToDefaults()` を消す（呼び出し 0。呼ばれると定型文由来のお気に入りを全件 dangling にする）。参照テスト 3 本も
- L-134 テーマに `visualDensity: VisualDensity.standard` と `materialTapTargetSize: padded` を固定する
  （デスクトップのブラウザでは既定が `shrinkWrap` + `VisualDensity(-2,-2)` になり、`TextButton` が 44px → **36px** に落ちる。REQ-3001 違反）

**決定に「デスクトップで縦に伸びるので全画面の再確認が要る」と明記されている。**
完了条件: 契約テストが**テストの既定プラットフォーム以外でも**見張れる形になっていること（いまは Android 相当でしか回らず、この穴を見逃した）。デスクトップ幅でブラウザから全画面を確認。

### PR4 — 束 B: 下書きの保存・復元を定型文フォームへ（L-144・L-143）

決定: 定型文フォームにも下書きの保存・復元を載せる（規律 8 の①「構造を変えて危険を表現不可能にする」）。

既存の仕組みを再利用する: `app_session_provider.dart:114` の `saveDraftText` と `lib/features/app_state/providers/app_lifecycle_observer.dart` の 400ms デバウンス。
これで **システムバック・ブラウザの戻る・OS kill・タブを閉じる**が全部無害になり、**L-143 も消える**。

L-143 の再現（ブラウザで確かめること）: 定型文ダイアログを入力中に `history.back()` すると、**ダイアログは残ったまま背後の画面だけホームに戻り**、その状態で「保存」を押しても何も起きない（`preset_phrase_screen.dart:159` の `onSave` が掴む `ref` が unmounted）。出口は「キャンセル」だけで、結局打った文が消える。
完了条件: この経路で打った文が失われないことを**ブラウザで実際に確かめる**。`DiscardInputGuard`（#154）が塞ぐのはシステムバックだけなので、そこと重複しないこと。

### PR5 — Hive（L-122・L-127・L-128）

- L-122 `history_repository.dart:49-57` の `addHistory` を直列化する（`PersistedBox` と同じ形）。
  いま上限 50 件のとき `await` されずに 2 回重なると 51 件になりその後も 51 件のまま
- L-127 テストの後片付けが「`.lock` が消えた box」と「box を閉じ損ねたまま一時ディレクトリを消した」を区別できない。**一時ディレクトリの有無で区別する**
- L-128 `Hive.openBox` の失敗が、誰も await しない Future のエラーを 1 つ漏らす（`hive_impl.dart:117-118`）。
  アプリは `PlatformDispatcher.onError` も zone のハンドラも置いていない。**まず実機（ブラウザ含む）で確認してから**、置くかどうかを決定として出す

### PR6 — 文書（L-81・L-82）

- L-81 `backend/tests/contract/openapi_baseline.json` を「API の正本」と呼ぶのをやめる。実体は契約テストの基準で、単体では enum の値や説明文を含まない。
  直す場所は 2 つ: `docs/adr/ADR-010-document-framework.md:29` と `AGENTS.md:42`（どちらも「API は `backend/tests/contract/openapi_baseline.json`」と書いている）
- L-82 `ADR-007` 限界節の「括弧書き 4 項目が定義か要約か、まだ決めていない」を**定義とする**と書き直す

**ADR は追記せず書き直す**（ADR-010）。ADR-005 が 3 PR で 55 行まで膨らんで誰も気づかなかった前例がある。60 行上限。

### PR7 — 入力上限の告知（L-109）

決定: (1) 告知で「達した」と「切り詰めた」を区別する／(3) 標準レイアウトで告知表示のレイアウトテストを足す／**(2) サロゲートペアは記録して受け入れる**（文字盤から絵文字を入力できず到達経路が無い）。
対象: `input_buffer_provider.dart:84`。現実の経路は AI 変換結果だけ（定型文は上限 500、候補は短文）。

### C1 — backend の生存 mutant 3 件（L-59・L-60・L-61）

| 行 | 対象 | 殺すべき変異 |
|---|---|---|
| L-59 | `backend/app/config.py:161` | `exc.errors(include_input=False, …)` の `include_input=False` を落とす。ValidationError の入力値が `ConfigError` へ漏れないこと（ADR-003） |
| L-60 | `backend/app/errors.py:108` | `super().__init__(code.value)` を `None` にする。`SafeError` の文字列表現が `ErrorCode` を保持すること |
| L-61 | `backend/app/ratelimit.py:42` | `RateLimitItemPerSecond(times, seconds)` の `seconds` を `None` にする。設定した秒数がウィンドウ長に反映されること |

**規律 5: テストを先に書いて赤を見てから進める。**完全一致アサーションを書かない。
`patch('app.` は `backend/scripts/gates.sh:15-16` が禁止している（自分の関数を patch しない）。
完了条件: `make mutation` で 3 つが kill されたことを出力で示し、kill rate を台帳へ。

### C2 — mutmut の対象固定を外す（L-65）— C1 のマージ後

`backend/pyproject.toml` の `[tool.mutmut]` は `source_paths` が 4 ファイル固定で、テストを増やしても走らず kill rate が理由なく下がる。`also_copy` で `app/` 全体を写して指定を無くせるか試す。
**できなければ「できなかった理由」を台帳に書いて `[ ]` のまま残す**（無理に通さない）。（2026-09-23: 実施済み・不採用で、台帳の受け入れた限界 L-211 へ移した）変更の前後で kill rate を両方測り、分母が変わったことを明示する。

### C3 — Actions を SHA にピン留め（L-92）

実測 **16 種・58 箇所**。`uses: owner/repo@vN` → `uses: owner/repo@<sha>  # vN`。
SHA は `gh api repos/<owner>/<repo>/git/ref/tags/<tag>` で解決する。
**自作の検査スクリプトは作らない**（決定のとおり、更新は dependabot に運ばせる。規律 8 の②）。
規律 8 の「workflow」に yes。400 行 / 12 ファイルを超えるなら workflow 単位で割る。

### C4 — 小物 2 件（L-69・L-78）

- L-69 `test/widgets/character_board_optimization_test.dart:389` の `expect(widget.runtimeType.toString(), equals('CharacterBoardWidget'))` はクラス名を固定するだけ。挙動を検査する形に書き換え、**実装を壊したときに赤くなることを変異で確かめる**
- L-78 `README.md:82` の `curl -s localhost:8000/api/v1/health` を `127.0.0.1` に直す（`localhost` が `::1` に解決される環境で timeout する。uvicorn は 127.0.0.1 で待つ）

### 追加（決定済み、順不同）

- **L-94** `.github/workflows/release.yml` が署名鍵・証明書・p12 パスワードを workspace に書き出す（`:100-121`、`:181-186`）。
  実測で**後始末が 1 つも無い**（`rm -f` も `if: always()` も存在しない）。ランナーの一時ディレクトリに置き `if: always()` で消す。L-52 と同じ束で
- **L-76** カバレッジ基準が 3 か所にある。仕様が値を決めている（`docs/spec/kotonoha-requirements.md:167-168`。NFR-501 = 80%、NFR-502 = 90%）ので、
  `pyproject fail_under 80` と `flutter.yml THRESHOLD 80` が NFR-501、`codecov.yml python target 90%` が NFR-502 に対応するよう 1 箇所ずつに整理する。
  NFR-502 の「重要なビジネスロジック・API エンドポイント」の範囲は**提案して台帳に記録する**（`codecov.yml` の存在しないパスの除外も直す）
- **L-67** お気に入りが `lib/features/favorite/`（ロジック 3 ファイル）と `lib/features/favorites/`（UI 4 ファイル）に分かれたまま。
  ADR-005 が「お気に入りの正は `favoriteProvider`」と決めており、それは `favorite/` にあるので**`favorites/` を `favorite/` へ寄せる**。
  参照は **lib 8 + test 19 = 27 ファイル**あり、移動分と合わせて 34 で **12 ファイルの上限を超える**。PR を割ること
- **L-97**（2026-09-23 に台帳の受け入れた限界 L-212 へ移した。backend の依存更新の後に再測定する）pytest の非推奨警告 2 件（fastapi/starlette の `TestClient`、anyio の別名）。
  **いま `filterwarnings` を書かない。**L-87 で pip の dependabot PR は作り直されるので、fastapi の更新で消えるかを先に見る。
  消えなければ、その 2 件だけを狙った `filterwarnings` を足す（先に書くと上流が直った後も残り「効かない仕組み」になる）

---

## 3. 渡していないもの

| | 理由 |
|---|---|
| **2 系統レビューの片方** | 規律 7 は「種類の違う 2 系統」を要求し、理由を「AI レビュアーの盲点は相関する」と書いている。Codex が実装して Codex がレビューすると 1 系統。もう片方は Claude か利用者が持つ |
| **マージ** | 各 PR のマージ判断 |
| **L-87 / L-88** | dependabot 15 本の close / merge（actions #66〜#70 はマージ、pip #55〜#59 は close して作り直させる、pub #60・#62〜#65 は #162 マージ後に作り直し）と `fix/backend-production-hardening` の push |
| **人が動かす 11 件** | L-84 開発者登録 → L-145 クローズドテスト（12 人 × 14 日）→ L-52 → L-146。ほか L-51・L-107・L-85・L-25・L-57・L-98・L-75。**ここが全体の律速** |
| **10 月の棚卸し送り** | L-70・L-91・L-106・L-125・L-126・L-147 |
