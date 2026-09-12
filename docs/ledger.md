# 台帳 — 後回しにした問題と判断待ち

規則: 1 問題 1 行＋出所。経緯は書かない。`[ ]` 未対応 ／ `[x]` 対応済み ／ `[-]` 却下。
フェーズ境界で見直し、`[x]` と `[-]` は次の境界で行ごと消す（履歴は git）。レビューに渡すのは `[ ]` だけ。
読むのは必要なときだけ（核には数えない）。#85（この台帳の PR のマージ後に閉鎖）から仕分けて作った。

## 未対応
- [x] L-04 `docs/design/kotonoha/api-endpoints.md:381` が NFR-101 をレート制限の根拠として誤引用 — 正本は ADR-002。正本でなくなった（倉庫へ移動、PR #114）
- [x] L-08 `lib/features/README.md` が例示するディレクトリが実在しない — 正本でなくなった（倉庫へ移動、PR #114）
- [ ] L-25 `frontend/kotonoha_app/integration_test/device_test/`（実機QA手順、1,773行）が一度も実行されていない — ADR-007 のストア提出前に必要
- [x] L-43 `docs/design/kotonoha/interfaces.dart`・`database-schema.sql` が `isFavorite`/`is_favorite` を残しコードと食い違う — 正本でなくなった（倉庫へ移動、PR #114）
- [ ] L-51 サポート連絡先が `support@kotonoha-app.example.com` のまま（RFC 2606 の予約ドメイン） — docs/support.md, docs/privacy-policy.md。ADR-007 条件 4
- [ ] L-52 Android のアップロード鍵が無い（AAB・mapping・シンボルは #97 で解決済み） — .github/workflows/release.yml。開発者登録後。Android の release ビルドは署名鍵が無いと debug 鍵で署名される（`frontend/kotonoha_app/android/app/build.gradle.kts:67-73`）
- [x] L-53 `docs/design/kotonoha/api-endpoints.md` の成功応答の形が実装（フラット形）と食い違う — 正本でなくなった（倉庫へ移動、PR #114。API の正本は backend/tests/contract/openapi_baseline.json）
- [ ] L-55 AI 変換の平均応答時間（3秒以内）が未測定 — ADR-002 のプロバイダ支出上限設定と同日に実測（backend 公開の前提）
- [ ] L-57 Android 12 以上と iOS の実機で、OS のバックアップから履歴・定型文・お気に入り・設定が復元されることを確認 — NFR-106（2026-09-12 に #99 の除外を撤回）
- [-] L-13 box が開いたまま書き込み失敗を検出しない（ディスクフル） — hive 2.2.3 `box_impl.dart:82`。ADR-005（永続化の失敗は利用者に伝える）の穴。EDGE-003（容量不足の警告）の未達（PR #114 の突き合わせ）。受け入れ（2026-09-13、ADR-005 限界節。再訪条件: 容量不足による消失の報告 1 件）
- [ ] L-59 `exc.errors(include_input=False, ...)` から `include_input=False` を落とす mutant が生存 — ValidationError の入力値が `ConfigError` へ漏れないことを検査するテストが無い（ADR-003） — backend/app/config.py:161（mutmut 生存。#106 の測定の残り）
- [ ] L-60 `SafeError.__init__` の `super().__init__(code.value)` を `None` にする mutant が生存 — 基底 `SafeError` の文字列表現が `ErrorCode` を保持することを検査するテストが無い — backend/app/errors.py:108（mutmut 生存。#106 の測定の残り）
- [ ] L-61 `RateLimiter.__init__` の `RateLimitItemPerSecond(times, seconds)` の `seconds` を `None` にする mutant が生存 — 設定した秒数がレート制限ウィンドウ長に反映されることを検査するテストが無い — backend/app/ratelimit.py:42（mutmut 生存。#106 の測定の残り）
- [ ] L-65 mutmut の対象テストは pyproject の 4 ファイル指定で固定されており、テストを増やしても走らない（kill rate が理由なく下がる）。`also_copy` で app/ 全体を写して指定を無くせるか試す — backend/pyproject.toml [tool.mutmut]
- [ ] L-66 `LogLevel` が lib 内で参照ゼロ（`logger_test.dart:248` が enum の値の並びだけを固定している） — frontend/kotonoha_app/lib/core/utils/logger.dart:10（棚卸し 2026-09、観点 1・4）
- [ ] L-67 お気に入りが `frontend/kotonoha_app/lib/features/favorite/`（ロジック）と `frontend/kotonoha_app/lib/features/favorites/`（UI）の 2 ディレクトリに分かれたまま — ADR-005（棚卸し 2026-09 で現存を確認、Phase 5（文書）の後）
- [ ] L-68 要件 ID 107 件のうち 14 件が、テストにも openspec にも 1 度も現れない（追跡性の穴。挙動は別 ID で試験済みのものを含む） — docs/spec/kotonoha-requirements.md（一覧は棚卸し 2026-09 の PR 本文）
- [ ] L-69 `expect(widget.runtimeType.toString(), equals('CharacterBoardWidget'))` はクラス名を固定するだけで挙動を検査しない — frontend/kotonoha_app/test/widgets/character_board_optimization_test.dart:389（棚卸し 2026-09、観点 4）
- [x] L-71 道具名 `openspec-apply` / `openspec-archive` が実在しない（実名は `openspec-apply-change` / `openspec-archive-change`） — AGENTS.md:52、docs/archive/plans/2026-08-29-architecture-remediation.md:316-317（棚卸し 2026-09、観点 3）。AGENTS.md の書き直しで解消（PR #116）。親計画は Task 8 で倉庫へ移動
- [x] L-72 `openspec/config.yaml` の context が実態と食い違う（backend が SQLAlchemy/PostgreSQL のまま＝同じファイルの ADR-001 要約と矛盾／Flutter 3.41.5＝CI は 3.38.1／ADR-009 が要約一覧に無い） — openspec/config.yaml:14,16,37（棚卸し 2026-09、観点 2）。直した（PR #114）
- [ ] L-73 入力欄の 1000 文字上限に警告表示が無く、超過分を黙って捨てる（EDGE-101 の未達） — frontend/kotonoha_app/lib/features/character_board/providers/input_buffer_provider.dart:65,89（PR #114 の突き合わせ）
- [ ] L-74 フォントサイズ設定が home_screen 配下にしか届かず、定型文一覧が追従しない（REQ-802・REQ-2007 の未達） — frontend/kotonoha_app/lib/features/preset_phrase/presentation/widgets/phrase_list_item.dart:98、frontend/kotonoha_app/lib/app.dart:47-56（PR #114 の突き合わせ）
- [ ] L-75 `docs/store-assets-guide.md` と `frontend/kotonoha_app/integration_test/device_test/README.md` は正本ではなく実行可能な手順として現在地に残す。ADR-007 条件 4（ストア提出）の充足で倉庫へ — Phase 5 A1
- [ ] L-76 NFR-502（backend の重要なビジネスロジック・API エンドポイントで 90% 以上のカバレッジ）が未測定。CI の `fail_under` は全体閾値（NFR-501） — docs/spec/kotonoha-requirements.md:166（L-55 と同形）。基準が 3 か所にある（pyproject の fail_under 80、flutter.yml の THRESHOLD 80、codecov.yml の python 90% と存在しないパスの除外）
- [ ] L-77 `showOfflineAIConversionDialog`（frontend/kotonoha_app/lib/features/network/presentation/widgets/network_aware_scaffold.dart:115）と `TextInputField`（frontend/kotonoha_app/lib/shared/widgets/text_input_field.dart:29）は lib からの呼び出しゼロで、テストだけが呼ぶ — PR #114 の突き合わせ（棚卸し観点 1）
- [ ] L-78 README.md:82 の `curl -s localhost:8000/api/v1/health` は、localhost が ::1 に解決される環境で timeout する（uvicorn は 127.0.0.1 で待つ）。127.0.0.1 に直すか注記する — Task 6 の実測（2026-09-06）
- [ ] L-84 開発者登録（Apple Developer Program / Google Play）が未着手。外部律速で、他の作業を待つ理由が無い — ADR-007 条件 4（人が動かす。旧 remaining-work.md から移記）
- [ ] L-85 ストア掲載文（`frontend/kotonoha_app/fastlane/metadata/ja-JP`・`en-US`）を「医療・治療効果を謳わない」観点で点検していない — ADR-007 条件 4（旧 remaining-work.md から移記）
- [ ] L-90 ADR-005 の改訂: L-39（却下理由と連鎖削除の矛盾）／Hive 破損時に退避して作り直すことを利用者に伝える経路が無い（`frontend/kotonoha_app/lib/core/utils/hive_init.dart:59-60,108`）／退避ファイル `<box>.hive.corrupt.bak` を戻す手段の有無 — ADR-005、2026-09-12 の監査（Q9・Q13）。L-39 は解消済み（2026-09-13）。残りは作り直しの通知・設定保存の失敗の通知（次の PR）
- [ ] L-91 コードや CI が守っているのに ADR に無い決定: `/health` の無認証・無レート制限（`backend/app/routes.py:68-75`、`backend/tests/contract/test_health_docs.py`）、環境名による認証省略と `/docs` 公開（`backend/app/config.py:106-117`）、CORS の形（`backend/app/main.py:187-193`）、`patch('app.` 禁止（`backend/scripts/gates.sh:15-16`）、lint の設定値（`backend/pyproject.toml`）。次の棚卸しで作成条件 3 つに照らして ADR にするか決める — 2026-09-12 の監査（第二線）
- [ ] L-92 GitHub Actions 12 種が可変メジャータグ（`@v2` 等）で固定され SHA ピン留めが無い。秘密（AI_API_KEY・VERCEL_TOKEN・ANDROID_*・APPLE_*）を扱う job で走る — .github/workflows/*.yml（2026-09-12 の監査）
- [x] L-93 Stop フックが直近 3 件のコミット件名と変更ファイル名を `claude -p` へ渡し（外部送信先）、`.git/` 配下に印ファイルを書く — .claude/hooks/activity-value-check.sh:49-52,87-88（2026-09-12 の監査。L-79 と一緒に判断）。フックの削除で消滅（2026-09-12）
- [ ] L-94 `release.yml` が署名鍵・証明書・p12 パスワードを workspace のファイルに書き出す（`:100-121`、`:181-186`）。層 2 の照合に workflow を足したのは 2026-09-12 — .github/workflows/release.yml
- [ ] L-95 Hive の box 名の正が `frontend/kotonoha_app/lib/core/persistence/persistence_state.dart:31-35` にあり、`hive_init.dart` を触らずに変えられる（層 2 の永続化の照合外） — 2026-09-12 の監査
- [ ] L-96 `frontend/kotonoha_app/web/.env.example` の設定（ENABLE_AI_CONVERSION 等）は lib から参照ゼロで、ビルド出力に複製される死んだ設定 — 2026-09-12 の監査
- [ ] L-97 pytest が third-party 由来の非推奨警告 2 件を出す（fastapi/starlette の TestClient、anyio の別名）。出力が静かでない — backend、#120
- [ ] L-98 ストア提出の前に独立監査（規律 9、棚卸しスキルの付録）を 1 回行い、結果を台帳へ書く。条件 4 の充足判定の前 — AGENTS.md 規律 9、ADR-007 条件 4
- [ ] L-83 SharedPreferences の設定保存の失敗を利用者へ伝える。方式は決定済み（2026-09-13、ADR-005: Hive と同じ書き込み失敗の報告に流す）。実装は L-90 と同じ PR — frontend/kotonoha_app/lib/features/settings/providers/settings_provider.dart:130
- [ ] L-99 定型文由来のお気に入りの重複判定が `sourceId` だけなので、★付きの定型文を削除して同文を作り直し★を押すと同文のお気に入りが 2 件並ぶ（#125 で連鎖削除を外して開いた経路）。content でも判定するかは判断待ち — frontend/kotonoha_app/lib/features/favorite/providers/favorite_provider.dart:242、ADR-005 限界
- [ ] L-100 `resetToDefaults()` は lib からの呼び出しゼロの死蔵コードで、呼ばれると定型文由来のお気に入りを全件 dangling にする — frontend/kotonoha_app/lib/features/preset_phrase/providers/preset_phrase_notifier.dart:292（#125 の独立監査、棚卸し観点 1）

## 判断待ち
- [x] L-39 ADR-005 の却下理由と連鎖削除の矛盾 — docs/adr/ADR-005。Phase 5 の後に扱う。解消（2026-09-13、ADR-005 改訂: 連鎖削除を外し TC-SYNC-202 を「残る」に）
- [ ] L-58 の残り: backend 公開の 4 条件（支出上限・デプロイと proxy 段数・端末キー配布・実プロバイダでの往復） — ADR-002。Web 成果物に鍵を焼かない（#121 で外した）
- [x] L-64 Phase 5 の完了条件「実在しないパス参照 0 件」は README の Swagger URL（/docs）や ADR-007 のアプリ route 名が数に入るため到達不能。核＋台帳に絞るか観測値扱いにする（除外規則は足さない） — Phase 5 計画書 A5（破棄済み）。観測値にすると決定（2026-09-06、ADR-010 の限界）
- [ ] L-70 道具表の 4 目的（影響範囲・ADR の引き出し・状態遷移・仕様乖離の逆生成）が未割当になった。tsumiki を有効に戻すか、別の道具を割り当てるか — AGENTS.md 道具表（棚卸し 2026-09 で降ろした）
- [x] L-79 Stop フック `.claude/hooks/activity-value-check.sh` は廃棄条件「発火ゼロで 1 か月」に 2026-09-30 で到達する（2026-08-30 設置、痕跡なし）。到達していれば削除するか、条件を書き直すか — AGENTS.md 規律 9。棚卸しの観点 6 が同じ問いを月 1 で立てるので廃棄候補。廃棄した（2026-09-12。役目は棚卸し観点 6 と規律 9 の独立監査へ）
- [ ] L-80 `frontend/kotonoha_app/pubspec.lock` は Flutter 3.41.5 で解決したまま。`.fvmrc`／CI の 3.38.1 で `flutter pub get` すると `characters` が 1.4.1→1.4.0 に下がり `js` 0.7.2 が加わる。lock を 3.38.1 で作り直すか SDK を上げるか（依存の決定、規律 8） — Task 4 の実測（2026-09-06）
- [ ] L-81 `backend/tests/contract/openapi_baseline.json` は正規化ダンプで、単体では現行 API の形しか示さない（enum の値や説明文を含まない）。ADR-010:28 と AGENTS.md 文書節が「API の正本」と呼ぶ記述の限界。呼び方を変えるか、ダンプに補うか — ADR-010「限界」
- [ ] L-82 ADR-007 条件 1 の括弧書き 4 項目が定義か要約か（限界節に「まだ決めていない」と明記） — docs/adr/ADR-007-release-criteria.md:47
- [ ] L-86 プライバシーポリシーの公開先が GitHub の blob URL のまま（`frontend/kotonoha_app/fastlane/metadata/*/privacy_url.txt`。#91 で 200 を実測）。ストア提出の公開先としてこれでよいか — ADR-007 条件 4（旧 remaining-work.md から移記）
- [ ] L-87 dependabot の PR 15 本が滞留（actions #66〜#70、pip #55〜#59、pub #60・#62〜#65）。frontend の `flutter_riverpod` #62・`go_router` #60 はリリース前に上げるか決める。backend の 5 本は Phase 2 で requirements.txt が変わりずれており、`sqlalchemy` #57 は依存自体が無い。close して作り直させるか — .github/dependabot.yml（旧 remaining-work.md から移記）
- [ ] L-88 `fix/backend-production-hardening` はローカルにしか無い（#86 で「証拠として残す」と決定）。push して保全するか、ローカル限りとするか — Issue #86（旧 remaining-work.md から移記）
- [x] L-89 AGENTS.md の索引は卒業済み ADR も 1 行残す規則のため、ADR が増えると増え続ける。5 行に抑えるか（層 2 が卒業済み ADR を引用しなくなる）、別の上限を置くか。2026-09-08 に保留 — ADR-010:33、scripts/adr-touch.sh:21。卒業済みの索引を `docs/adr/README.md` に分けると決定（2026-09-12）

## 計測（棚卸しの記録。最新の 1 回だけ残す）
| 日付 | 核 | 未卒業 ADR | 台帳 未対応/対応済/却下 | 出力ゼロの仕組み | 実在しないパス参照 | kill rate | 製品/全体（30 日） |
|---|---|---|---|---|---|---|---|
| 2026-09-06（Phase 5 完了・レビュー修正込み） | AGENTS.md 81 行（上限 120） | 5 本（上限 5）。60 行超 0 本 | 27 / 7 / 0 | release.yml（tag 契機で正常）、Stop フック痕跡なし（2026-08-30 設置、廃棄条件の 1 か月は未到達。2026-09-30 に到達、L-79） | 11 件（真に壊れた参照 0 件。ルート名・`.env` ひな形・pre-commit のフック・台帳の解決済み参照・不在の記述・OpenSpec の意図的不在） | 85.9%（158/184。2026-09-05 の測定を再利用、対象コードは無変更。test_sinks.py の差分は docstring のみ） | —（2026-10-01 の棚卸しから） |
