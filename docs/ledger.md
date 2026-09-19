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
- [x] L-73 入力欄の 1000 文字上限に警告表示が無く、超過分を黙って捨てる（EDGE-101 の未達） — frontend/kotonoha_app/lib/features/character_board/providers/input_buffer_provider.dart:65,89（PR #114 の突き合わせ）。解消（2026-09-16、#133: 入力欄の直下に告知。持ち越しは L-109）
- [x] L-74 フォントサイズ設定が home_screen 配下にしか届かず、定型文一覧が追従しない（REQ-802・REQ-2007 の未達） — frontend/kotonoha_app/lib/features/preset_phrase/presentation/widgets/phrase_list_item.dart:98、frontend/kotonoha_app/lib/app.dart:47-56（PR #114 の突き合わせ）。解消（2026-09-16、テーマの textTheme とボタンテーマに倍率を掛ける。PR は下記）
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
- [ ] L-102 作り直しと保存失敗が同時だと作り直しの告知が失敗の告知に置き換わる／退避→削除の後に再オープンが失敗すると削除の事実が伝わらない — frontend/kotonoha_app/lib/core/persistence/persistence_state.dart:119-130、lib/core/utils/hive_init.dart:159-182（#126 の独立監査）。前半（作り直し・救出の告知が失敗の告知に置き換わる）は解消（2026-09-19: 保存できない状態のとき、バナーが起動時の破損の結果を直接読んで並べる。#139 の独立監査と Codex がどちらも最重要と評価）。**残るのは後半**（退避 → 削除の後に再オープンが失敗すると、削除の事実が伝わらない）
- [x] L-103 常設バナーの文字はアプリ設定の 3 段階フォントに追随しない（`fontSize: 14` 固定。OS の文字拡大は効く） — frontend/kotonoha_app/lib/core/widgets/persistence_banner.dart（#126 の独立監査。L-74 と同系）。解消（2026-09-16、#134: バナーの文字 14px に設定の倍率を掛ける。中では 14px のまま。一度 bodyMedium にしたが、20px になり画面を圧迫するので撤回した）
- [x] L-104 下書き（`draft_text`）とチュートリアル完了フラグの SharedPreferences 書き込みは失敗しても報告されない（try も無く未処理の非同期エラーになる）。下書きは NFR-302 の対象で「最もコストの高い損失」とコード自身が書く — frontend/kotonoha_app/lib/features/app_state/providers/app_session_provider.dart:112-150、lib/features/help/providers/tutorial_provider.dart:60-71（#127 の独立監査）。解消（2026-09-16、#135: 設定と同じ報告経路に流しバナーに「入力中の文を保存できません」。再起動後に消失の理由を残せない限界は ADR-005 のとおり残る）
- [ ] L-106 ADR-005 が #125〜#127 で 55 行まで肥大化した（挙動の細部・日付・台帳番号を追記）。60 行上限も「改訂は追記せず書き直す」の規則も 2 系統レビューも捕まえず、利用者が adr-touch のコメントで気づいた。#128 で構造を変えた（ADR-010:34 の 1 句、規律 7 のレンズ）。10 月の棚卸し観点 6 で、以後の ADR 差分に細部が入らなかったかを見て、効かなければ数字（上限）を見直す — docs/adr/ADR-010-document-framework.md:34、AGENTS.md 規律 7
- [ ] L-107 ストア提出用の画像がゼロ（アイコン 1024/512、iPhone・iPad・スマートフォンのスクリーンショット、Play のフィーチャーグラフィック 1024×500）。`docs/store-assets-guide.md` のチェックリストは全項目が未着手 — frontend/kotonoha_app/fastlane/（画像 0 件、2026-09-16 実測）。ADR-007 条件 4
- [ ] L-109 入力上限の告知（#133）の持ち越し: (1) `setText` 経由（AI 変換結果）の 1000 文字超は切り詰められ、告知は「達した」と「切り詰めた」を区別しない（定型文は上限 500、候補は短文なので現実の経路は AI 変換結果だけ）(2) `substring` は UTF-16 単位で切るためサロゲートペアを壊しうる（文字盤から絵文字は入力できない）(3) 標準レイアウトで告知表示時のレイアウトテストが無い — frontend/kotonoha_app/lib/features/character_board/providers/input_buffer_provider.dart:84、#133 の 2 系統レビュー。告知文のフォント追従は #134 のテーマ倍率で解消を確認（大で bodyMedium×1.2）
- [ ] L-110 緊急ボタンの E2E（`large_emergency_buttons_test.dart` TC-E2E-084-021）が headless web で時々「はい」の直後に緊急画面を見つけられない（#133 の CI run 34997386337。main の直近 3 回は緑）。`startEmergency()` が音声再生の await の後に `alertActive` を書くため、再生が遅いと緊急表示が遅れる。視覚を先（state を先に書く）にして音声を後にすれば利用者にも E2E にも効くが、決定として出す — frontend/kotonoha_app/lib/features/emergency/presentation/providers/emergency_state_provider.dart:71-82
- [ ] L-111 フォント設定の追従はテーマの倍率がけで実装したが、これは「テーマに明示サイズがあるスタイル」（bodyLarge・bodyMedium・titleLarge とボタン）にしか効かない。サイズ無しのスタイル（ダイアログの見出し headlineSmall、bodySmall 等）は Theme.of の localize で既定サイズが後から入るため倍率の外で、REQ-2007「すべてのテキスト要素」は満たしていない。根治は MediaQuery の textScaler をアプリ根で掛け、文字盤等の 3 つの `switch (fontSize)` を撤去する方式（16/20/24 = 20×0.8/1.0/1.2 なので見た目は同じ。約 10 ファイル）。決定として出す — frontend/kotonoha_app/lib/core/themes/theme_provider.dart、Task 2 のレビュー

## 判断待ち
- [ ] L-58 の残り: backend 公開の 4 条件（支出上限・デプロイと proxy 段数・端末キー配布・実プロバイダでの往復） — ADR-002。Web 成果物に鍵を焼かない（#121 で外した）
- [ ] L-70 道具表の 4 目的（影響範囲・ADR の引き出し・状態遷移・仕様乖離の逆生成）が未割当になった。tsumiki を有効に戻すか、別の道具を割り当てるか — AGENTS.md 道具表（棚卸し 2026-09 で降ろした）
- [ ] L-80 `frontend/kotonoha_app/pubspec.lock` は Flutter 3.41.5 で解決したまま。`.fvmrc`／CI の 3.38.1 で `flutter pub get` すると `characters` が 1.4.1→1.4.0 に下がり `js` 0.7.2 が加わる。lock を 3.38.1 で作り直すか SDK を上げるか（依存の決定、規律 8） — Task 4 の実測（2026-09-06）
- [ ] L-81 `backend/tests/contract/openapi_baseline.json` は正規化ダンプで、単体では現行 API の形しか示さない（enum の値や説明文を含まない）。ADR-010:28 と AGENTS.md 文書節が「API の正本」と呼ぶ記述の限界。呼び方を変えるか、ダンプに補うか — ADR-010「限界」
- [ ] L-82 ADR-007 条件 1 の括弧書き 4 項目が定義か要約か（限界節に「まだ決めていない」と明記） — docs/adr/ADR-007-release-criteria.md:47
- [ ] L-86 プライバシーポリシーの公開先が GitHub の blob URL のまま（`frontend/kotonoha_app/fastlane/metadata/*/privacy_url.txt`。#91 で 200 を実測）。ストア提出の公開先としてこれでよいか — ADR-007 条件 4（旧 remaining-work.md から移記）
- [ ] L-87 dependabot の PR 15 本が滞留（actions #66〜#70、pip #55〜#59、pub #60・#62〜#65）。frontend の `flutter_riverpod` #62・`go_router` #60 はリリース前に上げるか決める。backend の 5 本は Phase 2 で requirements.txt が変わりずれており、`sqlalchemy` #57 は依存自体が無い。close して作り直させるか — .github/dependabot.yml（旧 remaining-work.md から移記）
- [ ] L-88 `fix/backend-production-hardening` はローカルにしか無い（#86 で「証拠として残す」と決定）。push して保全するか、ローカル限りとするか — Issue #86（旧 remaining-work.md から移記）
- [x] L-101 Hive 自身の自動復旧（本番既定 `crashRecovery: true`）は末尾の破損を黙って切り捨てて開くため、最も起きやすい形の破損では退避も告知も無い。`crashRecovery: false` に倒して全破損を自前経路（退避＋告知）に集約するか（部分救出を捨てる）、受け入れるか。決定（2026-09-19）: どちらでもなく第 3 案。まず `false` で開き、破損なら退避してから `true` で開き直して読める分を救い、「一部を読み込めませんでした」と伝える（救えなければ従来の作り直し） — frontend/kotonoha_app/lib/core/utils/hive_init.dart:91、hive 2.2.3 storage_backend_vm.dart:91-96（#126 の独立監査）。解消（2026-09-19、第 3 案を実装。`crashRecovery` 引数を消し、退避 → 救出 → 空なら作り直し。実 box で赤→緑、独立監査済み。持ち越しは L-102・L-113〜L-117）
- [x] L-105 `EmergencyStateNotifier.startEmergency()` / `resetEmergency()` が音声再生の await の後に state を書き、headless web の E2E（`large_emergency_buttons_test.dart` TC-E2E-084-013）がテスト完了後の UnmountedRefException で時々赤になる（2026-09-12 の #125 CI、同一コミットの再実行で緑）。await 後に `ref.mounted` を確かめる修正を、遅い FakeAudioService で赤を先に見る単体テスト付きで入れるか、フレークとして残すか — frontend/kotonoha_app/lib/features/emergency/presentation/providers/emergency_state_provider.dart:80。解消（2026-09-13、#131: await 後に `ref.mounted` を確かめる。遅い音声サービスで赤→緑）
- [ ] L-108 Google Play の個人アカウント（2023-11-13 以降に作成）は製品版の前にクローズドテスト（12 人以上が 14 日間連続で参加）が必須。ADR-007 は「β 配布」を却下し「オープンテスト段階は挟まない」と決めたが、これはストア側の必須要件で選べない。組織アカウント（D-U-N-S 番号）で登録して要件を外すか、クローズドテストを計画して ADR-007 を改訂するか。L-84 の登録前に決める — https://support.google.com/googleplay/android-developer/answer/14151465（2026-09-16 確認）、ADR-007 条件 4
- [ ] L-113 破損の告知（作り直し・救出）はプロセスの寿命にしか無い。バナーを読む前にアプリが終わると、次回起動ではファイルが正常なので二度と出ない。作り直しは空になるので気づけるが、救出は見た目で分からない。告知を次回起動へ持ち越すか（保存先が壊れていた直後に何へ書くか）は決定が要る — frontend/kotonoha_app/lib/main.dart:31-43、lib/core/persistence/recreated_areas_provider.dart（#139 の独立監査）
- [ ] L-114 破損ファイルの退避は 1 世代で、次の破損で上書きされる。しかも旧退避を消してから写すので、写しが失敗（ディスクフル等）すると新旧どちらの退避も残らない（そのとき元のファイルには手を付けない）。L-101 の実装で末尾破損でも退避が走るようになり、頻度が上がった。一時名へ写してから rename にするか、世代を持つか（容量とプライバシーとの兼ね合い） — frontend/kotonoha_app/lib/core/utils/hive_box_backup_io.dart:37-41（#139 の独立監査。上書きは実測、写しの失敗はコード読解）
- [x] L-115 履歴・お気に入りを全削除しても、退避ファイル `<box>.hive.corrupt.bak` は消えず（lib に消すコードが無い）、OS バックアップにも乗る（Android `allowBackup="true"`、iOS Documents）。過去の発話が残るので、プライバシーポリシーの「個別または全削除」と食い違う。全削除で退避も消すか、ポリシーに書くか。ADR-005 は退避を「支援者が端末を調べるときの保険」とする — docs/privacy-policy.md:69-74、frontend/kotonoha_app/lib/features/history/data/history_repository.dart:70-72（#139 の独立監査。元から。L-101 で頻度が上がった）。ストア提出の前（L-98）に決める。解消（2026-09-19、開発者の決定: 退避は消さず、プライバシーポリシーに書く。「データの保管」に壊れたデータの写しを、「データの削除」にアプリ内の削除では消えないこと・OS バックアップに乗った分はアンインストールでも残ることを日英で記載）
- [ ] L-116 長さ 0 の box ファイルは、退避も告知も無く空で開く（定型文は既定文に置き換わる）。Hive は初回にも 0 バイトのファイルを作るので区別できない。電源断でファイルが 0 バイトになるかは未確認。記録して受け入れる候補（規律 8） — hive 2.2.3 frame_helper.dart:18（#139 の独立監査、実測）
- [ ] L-117 `docs/user-guide/faq.md:190` の「クラウドには保存されません」は、OS のバックアップに乗る（NFR-106、privacy-policy.md:66、`allowBackup`）ことと食い違う 。同じ形がほかに 4 箇所: `frontend/kotonoha_app/fastlane/metadata/ja-JP/description.txt:47`「端末内にのみ保存」、`en-US/description.txt:47`、`review_information/notes.txt:16`、`docs/user-guide/troubleshooting.md:251`「自動バックアップ機能…は提供されていません」 — #139 の独立監査、#141 のレビュー（元から）。ストア掲載文を含むので L-85・L-98 と一緒に
- [ ] L-118 プライバシーポリシーの「ローカルに保存されるデータ」の一覧（入力履歴・定型文・お気に入り・アプリ設定）に、入力中の文の下書き（SharedPreferences の `draft_text`。#135 で保存失敗の告知を足した対象）が載っていない。足すかどうか — docs/privacy-policy.md:16-23、frontend/kotonoha_app/lib/core/persistence/settings_write_failure_provider.dart:32（2026-09-19、L-115 の修正中に気づいた。ストア提出の前の監査 L-98 の対象）
- [ ] L-119 履歴・お気に入りの個別削除は、Hive では印のフレームを足すだけで、元のフレームは compaction（削除 60 件超かつ全体の 15% 超）まで `.hive` ファイルに残る（全削除の `clear()` はファイルを 0 に切り詰めるので消える）。アプリからは見えないが、端末のファイルと OS バックアップ、破損時の写しには残る。履歴は上限 50 件のあふれも個別削除なので、最大で 60 件ほどの過去の発話が残りうる。受け入れてポリシーに書くか、個別削除のたびに `compact()` するか — hive 2.2.3 `box_impl.dart:71-79`・`default_compaction_strategy.dart`、frontend/kotonoha_app/lib/features/history/data/history_repository.dart:65,100（#141 のレビュー、2026-09-19 にソースで確認。写しについてはポリシーに記載済み）

## 計測（棚卸しの記録。最新の 1 回だけ残す）
| 日付 | 核 | 未卒業 ADR | 台帳 未対応/対応済/却下 | 出力ゼロの仕組み | 実在しないパス参照 | kill rate | 製品/全体（30 日） |
|---|---|---|---|---|---|---|---|
| 2026-09-06（Phase 5 完了・レビュー修正込み） | AGENTS.md 81 行（上限 120） | 5 本（上限 5）。60 行超 0 本 | 27 / 7 / 0 | release.yml（tag 契機で正常）、Stop フック痕跡なし（2026-08-30 設置、廃棄条件の 1 か月は未到達。2026-09-30 に到達、L-79） | 11 件（真に壊れた参照 0 件。ルート名・`.env` ひな形・pre-commit のフック・台帳の解決済み参照・不在の記述・OpenSpec の意図的不在） | 85.9%（158/184。2026-09-05 の測定を再利用、対象コードは無変更。test_sinks.py の差分は docstring のみ） | —（2026-10-01 の棚卸しから） |
