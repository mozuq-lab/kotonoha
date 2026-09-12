# 台帳 — 後回しにした問題と判断待ち

規則: 1 問題 1 行＋出所。経緯は書かない。`[ ]` 未対応 ／ `[x]` 対応済み ／ `[-]` 却下。
毎月の棚卸しで見直し、`[x]` と `[-]` は行ごと消す（履歴は git。消した行は `git log -p -S 'L-NN' -- docs/ledger.md` で引ける）。レビューに渡すのは `[ ]` だけ。
読むのは必要なときだけ（核には数えない）。#85（この台帳の PR のマージ後に閉鎖）から仕分けて作った。

## 未対応
- [ ] L-25 `frontend/kotonoha_app/integration_test/device_test/`（実機QA手順、1,773行）が一度も実行されていない — ADR-007 のストア提出前に必要
- [ ] L-51 サポート連絡先が `support@kotonoha-app.example.com` のまま（RFC 2606 の予約ドメイン） — docs/support.md, docs/privacy-policy.md。ADR-007 条件 4
- [ ] L-52 Android のアップロード鍵が無い（AAB・mapping・シンボルは #97 で解決済み） — .github/workflows/release.yml。開発者登録後。Android の release ビルドは署名鍵が無いと debug 鍵で署名される（`frontend/kotonoha_app/android/app/build.gradle.kts:67-73`）
- [ ] L-55 AI 変換の平均応答時間（3秒以内）が未測定 — ADR-002 のプロバイダ支出上限設定と同日に実測（backend 公開の前提）
- [ ] L-57 Android 12 以上と iOS の実機で、OS のバックアップから履歴・定型文・お気に入り・設定が復元されることを確認 — NFR-106（2026-09-12 に #99 の除外を撤回）
- [ ] L-59 `exc.errors(include_input=False, ...)` から `include_input=False` を落とす mutant が生存 — ValidationError の入力値が `ConfigError` へ漏れないことを検査するテストが無い（ADR-003） — backend/app/config.py:161（mutmut 生存。#106 の測定の残り）
- [ ] L-60 `SafeError.__init__` の `super().__init__(code.value)` を `None` にする mutant が生存 — 基底 `SafeError` の文字列表現が `ErrorCode` を保持することを検査するテストが無い — backend/app/errors.py:108（mutmut 生存。#106 の測定の残り）
- [ ] L-61 `RateLimiter.__init__` の `RateLimitItemPerSecond(times, seconds)` の `seconds` を `None` にする mutant が生存 — 設定した秒数がレート制限ウィンドウ長に反映されることを検査するテストが無い — backend/app/ratelimit.py:42（mutmut 生存。#106 の測定の残り）
- [ ] L-65 mutmut の対象テストは pyproject の 4 ファイル指定で固定されており、テストを増やしても走らない（kill rate が理由なく下がる）。`also_copy` で app/ 全体を写して指定を無くせるか試す — backend/pyproject.toml [tool.mutmut]
- [ ] L-66 `LogLevel` が lib 内で参照ゼロ（`logger_test.dart:248` が enum の値の並びだけを固定している） — frontend/kotonoha_app/lib/core/utils/logger.dart:10（棚卸し 2026-09、観点 1・4）
- [ ] L-67 お気に入りが `frontend/kotonoha_app/lib/features/favorite/`（ロジック）と `frontend/kotonoha_app/lib/features/favorites/`（UI）の 2 ディレクトリに分かれたまま — ADR-005（棚卸し 2026-09 で現存を確認、Phase 5（文書）の後）
- [ ] L-68 要件 ID 107 件のうち 14 件が、テストにも openspec にも 1 度も現れない（追跡性の穴。挙動は別 ID で試験済みのものを含む） — docs/spec/kotonoha-requirements.md（一覧は棚卸し 2026-09 の PR 本文）
- [ ] L-69 `expect(widget.runtimeType.toString(), equals('CharacterBoardWidget'))` はクラス名を固定するだけで挙動を検査しない — frontend/kotonoha_app/test/widgets/character_board_optimization_test.dart:389（棚卸し 2026-09、観点 4）
- [ ] L-73 入力欄の 1000 文字上限に警告表示が無く、超過分を黙って捨てる（EDGE-101 の未達） — frontend/kotonoha_app/lib/features/character_board/providers/input_buffer_provider.dart:65,89（PR #114 の突き合わせ）
- [ ] L-74 フォントサイズ設定が home_screen 配下にしか届かず、定型文一覧が追従しない（REQ-802・REQ-2007 の未達） — frontend/kotonoha_app/lib/features/preset_phrase/presentation/widgets/phrase_list_item.dart:98、frontend/kotonoha_app/lib/app.dart:47-56（PR #114 の突き合わせ）
- [ ] L-75 `docs/store-assets-guide.md` と `frontend/kotonoha_app/integration_test/device_test/README.md` は正本ではなく実行可能な手順として現在地に残す。ADR-007 条件 4（ストア提出）の充足で倉庫へ — Phase 5 A1
- [ ] L-76 NFR-502（backend の重要なビジネスロジック・API エンドポイントで 90% 以上のカバレッジ）が未測定。CI の `fail_under` は全体閾値（NFR-501） — docs/spec/kotonoha-requirements.md:166（L-55 と同形）。基準が 3 か所にある（pyproject の fail_under 80、flutter.yml の THRESHOLD 80、codecov.yml の python 90% と存在しないパスの除外）
- [ ] L-77 `showOfflineAIConversionDialog`（frontend/kotonoha_app/lib/features/network/presentation/widgets/network_aware_scaffold.dart:115）と `TextInputField`（frontend/kotonoha_app/lib/shared/widgets/text_input_field.dart:29）は lib からの呼び出しゼロで、テストだけが呼ぶ — PR #114 の突き合わせ（棚卸し観点 1）
- [ ] L-78 README.md:82 の `curl -s localhost:8000/api/v1/health` は、localhost が ::1 に解決される環境で timeout する（uvicorn は 127.0.0.1 で待つ）。127.0.0.1 に直すか注記する — Task 6 の実測（2026-09-06）
- [ ] L-84 開発者登録（Apple Developer Program / Google Play）が未着手。外部律速で、他の作業を待つ理由が無い — ADR-007 条件 4（人が動かす。旧 remaining-work.md から移記）
- [ ] L-85 ストア掲載文（`frontend/kotonoha_app/fastlane/metadata/ja-JP`・`en-US`）を「医療・治療効果を謳わない」観点で点検していない — ADR-007 条件 4（旧 remaining-work.md から移記）
- [ ] L-91 コードや CI が守っているのに ADR に無い決定: `/health` の無認証・無レート制限（`backend/app/routes.py:68-75`、`backend/tests/contract/test_health_docs.py`）、環境名による認証省略と `/docs` 公開（`backend/app/config.py:106-117`）、CORS の形（`backend/app/main.py:187-193`）、`patch('app.` 禁止（`backend/scripts/gates.sh:15-16`）、lint の設定値（`backend/pyproject.toml`）。次の棚卸しで作成条件 3 つに照らして ADR にするか決める — 2026-09-12 の監査（第二線）
- [ ] L-92 GitHub Actions 12 種が可変メジャータグ（`@v2` 等）で固定され SHA ピン留めが無い。秘密（AI_API_KEY・VERCEL_TOKEN・ANDROID_*・APPLE_*）を扱う job で走る — .github/workflows/*.yml（2026-09-12 の監査）
- [ ] L-94 `release.yml` が署名鍵・証明書・p12 パスワードを workspace のファイルに書き出す（`:100-121`、`:181-186`）。層 2 の照合に workflow を足したのは 2026-09-12 — .github/workflows/release.yml
- [ ] L-95 Hive の box 名の正が `frontend/kotonoha_app/lib/core/persistence/persistence_state.dart:31-35` にあり、`hive_init.dart` を触らずに変えられる（層 2 の永続化の照合外） — 2026-09-12 の監査
- [ ] L-96 `frontend/kotonoha_app/web/.env.example` の設定（ENABLE_AI_CONVERSION 等）は lib から参照ゼロで、ビルド出力に複製される死んだ設定 — 2026-09-12 の監査
- [ ] L-97 pytest が third-party 由来の非推奨警告 2 件を出す（fastapi/starlette の TestClient、anyio の別名）。出力が静かでない — backend、#120
- [ ] L-98 ストア提出の前に独立監査（規律 9、棚卸しスキルの付録）を 1 回行い、結果を台帳へ書く。条件 4 の充足判定の前 — AGENTS.md 規律 9、ADR-007 条件 4
- [ ] L-99 定型文由来のお気に入りの重複判定が `sourceId` だけなので、★付きの定型文を削除して同文を作り直し★を押すと同文のお気に入りが 2 件並ぶ（#125 で連鎖削除を外して開いた経路。お気に入り画面から消せる）。content でも判定するかは判断待ち — frontend/kotonoha_app/lib/features/favorite/providers/favorite_provider.dart:242、ADR-005 限界
- [ ] L-100 `resetToDefaults()` は lib からの呼び出しゼロの死蔵コードで、呼ばれると定型文由来のお気に入りを全件 dangling にする — frontend/kotonoha_app/lib/features/preset_phrase/providers/preset_phrase_notifier.dart:292（#125 の独立監査、棚卸し観点 1）
- [ ] L-102 作り直しと保存失敗が同時だと作り直しの告知が失敗の告知に置き換わる／退避→削除の後に再オープンが失敗すると削除の事実が伝わらない — frontend/kotonoha_app/lib/core/persistence/persistence_state.dart:101-111、lib/core/utils/hive_init.dart:150-157（#126 の独立監査）
- [ ] L-103 常設バナーの文字はアプリ設定の 3 段階フォントに追随しない（`fontSize: 14` 固定。OS の文字拡大は効く） — frontend/kotonoha_app/lib/core/widgets/persistence_banner.dart（#126 の独立監査。L-74 と同系）
- [ ] L-104 下書き（`draft_text`）とチュートリアル完了フラグの SharedPreferences 書き込みは失敗しても報告されない（try も無く未処理の非同期エラーになる）。下書きは NFR-302 の対象で「最もコストの高い損失」とコード自身が書く — frontend/kotonoha_app/lib/features/app_state/providers/app_session_provider.dart:112-150、lib/features/help/providers/tutorial_provider.dart:60-71（#127 の独立監査）

## 判断待ち
- [ ] L-58 の残り: backend 公開の 4 条件（支出上限・デプロイと proxy 段数・端末キー配布・実プロバイダでの往復） — ADR-002。Web 成果物に鍵を焼かない（#121 で外した）
- [ ] L-70 道具表の 4 目的（影響範囲・ADR の引き出し・状態遷移・仕様乖離の逆生成）が未割当になった。tsumiki を有効に戻すか、別の道具を割り当てるか — AGENTS.md 道具表（棚卸し 2026-09 で降ろした）
- [ ] L-80 `frontend/kotonoha_app/pubspec.lock` は Flutter 3.41.5 で解決したまま。`.fvmrc`／CI の 3.38.1 で `flutter pub get` すると `characters` が 1.4.1→1.4.0 に下がり `js` 0.7.2 が加わる。lock を 3.38.1 で作り直すか SDK を上げるか（依存の決定、規律 8） — Task 4 の実測（2026-09-06）
- [ ] L-81 `backend/tests/contract/openapi_baseline.json` は正規化ダンプで、単体では現行 API の形しか示さない（enum の値や説明文を含まない）。ADR-010:28 と AGENTS.md 文書節が「API の正本」と呼ぶ記述の限界。呼び方を変えるか、ダンプに補うか — ADR-010「限界」
- [ ] L-82 ADR-007 条件 1 の括弧書き 4 項目が定義か要約か（限界節に「まだ決めていない」と明記） — docs/adr/ADR-007-release-criteria.md:47
- [ ] L-86 プライバシーポリシーの公開先が GitHub の blob URL のまま（`frontend/kotonoha_app/fastlane/metadata/*/privacy_url.txt`。#91 で 200 を実測）。ストア提出の公開先としてこれでよいか — ADR-007 条件 4（旧 remaining-work.md から移記）
- [ ] L-87 dependabot の PR 15 本が滞留（actions #66〜#70、pip #55〜#59、pub #60・#62〜#65）。frontend の `flutter_riverpod` #62・`go_router` #60 はリリース前に上げるか決める。backend の 5 本は Phase 2 で requirements.txt が変わりずれており、`sqlalchemy` #57 は依存自体が無い。close して作り直させるか — .github/dependabot.yml（旧 remaining-work.md から移記）
- [ ] L-88 `fix/backend-production-hardening` はローカルにしか無い（#86 で「証拠として残す」と決定）。push して保全するか、ローカル限りとするか — Issue #86（旧 remaining-work.md から移記）
- [ ] L-101 Hive 自身の自動復旧（本番既定 `crashRecovery: true`）は末尾の破損を黙って切り捨てて開くため、最も起きやすい形の破損では退避も告知も無い。`crashRecovery: false` に倒して全破損を自前経路（退避＋告知）に集約するか（部分救出を捨てる）、受け入れるか — frontend/kotonoha_app/lib/core/utils/hive_init.dart:86、hive 2.2.3 storage_backend_vm.dart:91-96（#126 の独立監査）
- [ ] L-105 `EmergencyStateNotifier.startEmergency()` / `resetEmergency()` が音声再生の await の後に state を書き、headless web の E2E（`large_emergency_buttons_test.dart` TC-E2E-084-013）がテスト完了後の UnmountedRefException で時々赤になる（2026-09-12 の #125 CI、同一コミットの再実行で緑）。await 後に `ref.mounted` を確かめる修正を、遅い FakeAudioService で赤を先に見る単体テスト付きで入れるか、フレークとして残すか — frontend/kotonoha_app/lib/features/emergency/presentation/providers/emergency_state_provider.dart:80

## 計測（棚卸しの記録。最新の 1 回だけ残す）
| 日付 | 核 | 未卒業 ADR | 台帳 未対応/対応済/却下 | 出力ゼロの仕組み | 実在しないパス参照 | kill rate | 製品/全体（30 日） |
|---|---|---|---|---|---|---|---|
| 2026-09-06（Phase 5 完了・レビュー修正込み） | AGENTS.md 81 行（上限 120） | 5 本（上限 5）。60 行超 0 本 | 27 / 7 / 0 | release.yml（tag 契機で正常）、Stop フック痕跡なし（2026-08-30 設置、廃棄条件の 1 か月は未到達。2026-09-30 に到達、L-79） | 11 件（真に壊れた参照 0 件。ルート名・`.env` ひな形・pre-commit のフック・台帳の解決済み参照・不在の記述・OpenSpec の意図的不在） | 85.9%（158/184。2026-09-05 の測定を再利用、対象コードは無変更。test_sinks.py の差分は docstring のみ） | —（2026-10-01 の棚卸しから） |
