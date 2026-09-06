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
- [ ] L-52 Android のアップロード鍵が無い（AAB・mapping・シンボルは #97 で解決済み） — .github/workflows/release.yml。開発者登録後
- [x] L-53 `docs/design/kotonoha/api-endpoints.md` の成功応答の形が実装（フラット形）と食い違う — 正本でなくなった（倉庫へ移動、PR #114。API の正本は backend/tests/contract/openapi_baseline.json）
- [ ] L-55 AI 変換の平均応答時間（3秒以内）が未測定 — ADR-002 のプロバイダ支出上限設定と同日に実測（backend 公開の前提）
- [x] L-56 誤仕様固定テスト検出スキルと mutmut 導入・kill rate 記録 — Phase 4 の完了条件（mutmut 3.7.0 で kill rate 85.9%、#106。検出は棚卸しスキルの観点 4 に吸収）
- [ ] L-57 Android 12 以上の実機で、自動バックアップにアプリデータが載らないことを確認 — #99
- [ ] L-13 box が開いたまま書き込み失敗を検出しない（ディスクフル） — hive 2.2.3 `box_impl.dart:82`。ADR-005（永続化の失敗は利用者に伝える）の穴
- [ ] L-59 `exc.errors(include_input=False, ...)` から `include_input=False` を落とす mutant が生存 — ValidationError の入力値が `ConfigError` へ漏れないことを検査するテストが無い（ADR-003） — backend/app/config.py:161（mutmut 生存。L-56 の続き）
- [ ] L-60 `SafeError.__init__` の `super().__init__(code.value)` を `None` にする mutant が生存 — 基底 `SafeError` の文字列表現が `ErrorCode` を保持することを検査するテストが無い — backend/app/errors.py:108（mutmut 生存。L-56 の続き）
- [ ] L-61 `RateLimiter.__init__` の `RateLimitItemPerSecond(times, seconds)` の `seconds` を `None` にする mutant が生存 — 設定した秒数がレート制限ウィンドウ長に反映されることを検査するテストが無い — backend/app/ratelimit.py:42（mutmut 生存。L-56 の続き）
- [ ] L-65 mutmut の対象テストは pyproject の 4 ファイル指定で固定されており、テストを増やしても走らない（kill rate が理由なく下がる）。`also_copy` で app/ 全体を写して指定を無くせるか試す — backend/pyproject.toml [tool.mutmut]
- [ ] L-66 `LogLevel` が lib 内で参照ゼロ（`logger_test.dart:248` が enum の値の並びだけを固定している） — frontend/kotonoha_app/lib/core/utils/logger.dart:10（棚卸し 2026-09、観点 1・4）
- [ ] L-67 お気に入りが `frontend/kotonoha_app/lib/features/favorite/`（ロジック）と `frontend/kotonoha_app/lib/features/favorites/`（UI）の 2 ディレクトリに分かれたまま — ADR-005（L-46 で棚卸しへ送付。棚卸し 2026-09 で現存を確認、Phase 5 で統合）
- [ ] L-68 要件 ID 107 件のうち 14 件が、テストにも openspec にも 1 度も現れない（追跡性の穴。挙動は別 ID で試験済みのものを含む） — docs/spec/kotonoha-requirements.md（一覧は棚卸し 2026-09 の PR 本文）
- [ ] L-69 `expect(widget.runtimeType.toString(), equals('CharacterBoardWidget'))` はクラス名を固定するだけで挙動を検査しない — frontend/kotonoha_app/test/widgets/character_board_optimization_test.dart:389（棚卸し 2026-09、観点 4）
- [ ] L-71 道具名 `openspec-apply` / `openspec-archive` が実在しない（実名は `openspec-apply-change` / `openspec-archive-change`） — AGENTS.md:52、docs/plans/2026-08-29-architecture-remediation.md:316-317（棚卸し 2026-09、観点 3）
- [x] L-72 `openspec/config.yaml` の context が実態と食い違う（backend が SQLAlchemy/PostgreSQL のまま＝同じファイルの ADR-001 要約と矛盾／Flutter 3.41.5＝CI は 3.38.1／ADR-009 が要約一覧に無い） — openspec/config.yaml:14,16,37（棚卸し 2026-09、観点 2）。直した（PR #114）
- [ ] L-73 入力欄の 1000 文字上限に警告表示が無く、超過分を黙って捨てる（EDGE-101 の未達） — frontend/kotonoha_app/lib/features/character_board/providers/input_buffer_provider.dart:65,89（PR #114 の突き合わせ）
- [ ] L-74 フォントサイズ設定が home_screen 配下にしか届かず、定型文一覧が追従しない（REQ-802・REQ-2007 の未達） — frontend/kotonoha_app/lib/features/preset_phrase/presentation/widgets/phrase_list_item.dart:98、frontend/kotonoha_app/lib/app.dart:47-56（PR #114 の突き合わせ）

## 判断待ち
- [ ] L-39 ADR-005 の却下理由と連鎖削除の矛盾 — docs/adr/ADR-005。Phase 5 の後に扱う
- [ ] L-58 の残り: backend 公開の 4 条件（支出上限・デプロイと proxy 段数・端末キー配布・実プロバイダでの往復） — ADR-002, AGENTS.md「レート制限」
- [ ] L-64 Phase 5 の完了条件「実在しないパス参照 0 件」は README の Swagger URL（/docs）や ADR-007 のアプリ route 名が数に入るため到達不能。核＋台帳に絞るか観測値扱いにする（除外規則は足さない） — docs/plans/2026-09-05-docs-framework-and-inventory.md A5
- [ ] L-70 道具表の 4 目的（影響範囲・ADR の引き出し・状態遷移・仕様乖離の逆生成）が未割当になった。tsumiki を有効に戻すか、別の道具を割り当てるか — AGENTS.md「作業の進め方」（棚卸し 2026-09 で降ろした）

## 却下（次のフェーズ境界で削除）
- [-] L-02 E2E 5本が CI 対象外 — #84（クローズ済み。環境／テストの問題でアプリ不具合ではないと切り分け済み）
- [-] L-03 高コントラスト利用者が起動時に白画面を1フレーム見る — `frontend/kotonoha_app/lib/core/themes/theme_provider.dart`（TC-001 が正しい挙動として固定）
- [-] L-09 コミット規約: AGENTS.md の記載（`TASK-XXXX`）と実態（`docs:` 形式）の乖離 — AGENTS.md「コミット戦略」
- [-] L-12 `persistenceStateProvider` が box の状態変化に追随しない — 根本原因を修正済み（`repository_providers` 経由化、`59035413f2e`）
- [-] L-14 `PersistedArea` は「保存領域」ではなく実質「Hive box」 — #85
- [-] L-15 `Semantics(label:)` の重複読み上げが33箇所 — `empty_history_widget.dart:30`
- [-] L-16 `Recoverable`/`Unavailable` は原因ではなく件数で決まる — #85
- [-] L-17 `PersistedArea.boxName` の一意性テストが大文字小文字を区別しない — hive 2.2.3 `hive_impl.dart:74`
- [-] L-18 `PersistenceRecoverableFailure.failedAreas` が可変 Set をそのまま公開し `==`/`hashCode` 未定義 — #85
- [-] L-19 警告バナーが `liveRegion: false` — `emergency_alert_screen.dart:233` に前例あり
- [-] L-20 テスト環境（Hive未初期化）の既定が `Unavailable` — `emergency_button_overlap_test.dart`
- [-] L-21 `extension` 内 receiver 無し `close()` を文字列照合では追えない — 対象ファイル削除済み（L-32 決定、`52410e2`）
- [-] L-22 `main.dart` の await 検査が制御フローを見ていない — 対象ファイル削除済み（L-32 決定、`52410e2`）
- [-] L-23 `.close()` 検査が正当なコードを誤検出しうる — 対象ファイル削除済み（L-32 決定、`52410e2`）
- [-] L-24 バナーのラベル重複検査は1ノード内の重複しか見えない — 対象ファイル削除済み（L-32 決定、`52410e2`）
- [-] L-26 `ai_conversion_e2e_test.dart` のヘッドレスWeb実行可否が未確認 — ai_conversion_e2e_test.dart
- [-] L-27 E2Eから性能閾値検証を除去 — 検証は L-25（実機）に統合済みと説明
- [-] L-28 E2EからTTS実発話検証を除去 — frontend/kotonoha_app/test/features/tts/ と実機テストが担うと説明
- [-] L-29 定型文画面から履歴への導線が無くE2E被覆から外れた — #85
- [-] L-30 `initializeDefaultPhrases()`（初回起動のデータ投入経路）が widget 層で未検証 — docs/verification-principles.md §3
- [-] L-31 本番 Hive 初期化経路を通るテストが1本のみ — frontend/kotonoha_app/lib/core/utils/hive_init.dart:184
- [-] L-33 差分面積（400行/12ファイル）のCI機械化 — 棄却済み（逆方向に発火しすぎるゲートと判定）
- [-] L-34 `ruff check .` が `alembic/` に既存4件の import 未整列を出す — alembic/env.py
- [-] L-35 ローカルで `flutter drive` が実行できない（ChromeDriver/Chrome版不一致） — #85
- [-] L-36 実行中の Hive box 開閉を検査しない — L-32 決定（`persistence_truth_invariant_test.dart` 削除）で受け入れたリスク
- [-] L-38 Stage 3b が完了条件（400行/12ファイル）を超過 — 超過を承認済み（人の判断）
- [-] L-38 の残り: `PresetPhrase` の残るフィールド番号を詰め直さないこと — frontend/kotonoha_app/lib/core/utils/hive_init.dart:48（Stage 3b 完了済み、恒久注意）
- [-] L-38 の残り: 移行（Stage 2）配布順序の制約 — `f761afc`（Stage 2 は撤回済みで対象消失）
- [-] L-40 「定型文がお気に入りか」の判定述語が2箇所に別の形で存在 — preset_phrase_screen.dart:63
- [-] L-41 `FavoriteNotifier.addFavorite()` が呼び出し元ゼロで残存 — favorite_provider.dart（削除は撤回済み、UIから到達不能）
- [-] L-42 履歴由来お気に入りの `sourceType`/`sourceId` を誰も読んでいない — ADR-005
- [-] L-44 `TC-040-029` の題と中身が乖離 — TC-040-029
- [-] L-45 `PhraseCategorySection` の星判定はアプリ内では常に false — #85
- [-] L-46 `frontend/kotonoha_app/lib/features/favorite/`（ロジック）と `frontend/kotonoha_app/lib/features/favorites/`（UI）のディレクトリ分裂 — ADR-005（月1棚卸しへ送付済み）
- [-] L-47 許可リスト検査は起動時の共有登録経路しか守らない — 記録して受け入れ済み
- [-] L-48 「トップレベル可変変数の禁止」は Dart の analyzer では実現できない — 再訪条件: 同等の lint が Dart に入ったとき
- [-] L-49 許可リスト検査Bの fixture が nullable フィールドに非 null しか流さない — TC-065-001（実害は別テストが押さえ済み）
- [-] L-50 `hive_schema_allowlist_test.dart` に実 box 書き込みテストを足すと落ちる — hive_schema_allowlist_test.dart（現状無害）
- [-] L-54 `tsumiki:ipa-security-check` を回していない — 2026-09-05 に使わないと決定（AGENTS.md 道具表「検証」行）

## 計測（棚卸しの記録。最新の 1 回だけ残す）
| 日付 | 核 | 未卒業 ADR | 台帳 未対応/対応済/却下 | 出力ゼロの仕組み | 実在しないパス参照 | kill rate |
|---|---|---|---|---|---|---|
| 2026-09-06 | AGENTS.md 390 行（上限 120） | 9 本（上限 5）。うち 60 行超 6 本 | 24 / 1 / 39 | release.yml（tag 契機で正常）、Stop フック痕跡なし（2026-08-30 設置、廃棄条件の 1 か月は未到達） | 27 件（真に壊れた参照 0 件。相対表記・意図的不在・URL/route 名） | 85.9%（158/184。2026-09-05 の測定を再利用、対象コードは無変更） |
