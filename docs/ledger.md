# 台帳 — 後回しにした問題と判断待ち

規則（ADR-010）: 置くのは、決めた予定（`[ ]`）と、利用者に見える受け入れた限界（`[~]`）だけ。直さない指摘は記録しない。1 問題 1 行＋出所で、経緯は書かない。
`[x]`（対応済み）と `[-]`（却下）は付けた PR で行ごと消す（履歴は git。消した行は `git log -p -G '\] L-NN ' -- docs/ledger.md` で引ける）。仕事の入口は `docs/now.md` の最短経路で、この台帳の予定は最短経路に入れるまで着手しない。
読むのは必要なときだけ（核には数えない）。#85（この台帳の PR のマージ後に閉鎖）から仕分けて作った。

## 未対応
- [ ] L-25 `frontend/kotonoha_app/integration_test/device_test/`（実機QA手順、1,773行）が一度も実行されていない — ADR-007 条件 4（ストア提出前に必要）
- [ ] L-51 サポート連絡先が `support@kotonoha-app.example.com` のまま（RFC 2606 の予約ドメイン） — docs/support.md, docs/privacy-policy.md。ADR-007 条件 4
- [ ] L-52 Android のアップロード鍵が無い（AAB・mapping・シンボルは #97 で解決済み） — .github/workflows/release.yml。ADR-007 条件 4。開発者登録後。Android の release ビルドは署名鍵が無いと debug 鍵で署名される（`frontend/kotonoha_app/android/app/build.gradle.kts:67-73`）
- [ ] L-55 AI 変換の平均応答時間（3秒以内）が未測定 — ADR-002 のプロバイダ支出上限設定と同日に実測（backend 公開の前提）
- [ ] L-57 Android 12 以上と iOS の実機で、OS のバックアップから履歴・定型文・お気に入り・設定が復元されることを確認 — NFR-106（2026-09-12 に #99 の除外を撤回）
- [ ] L-68 要件 ID 107 件のうち 14 件が、テストにも openspec にも 1 度も現れない（追跡性の穴。挙動は別 ID で試験済みのものを含む） — docs/spec/kotonoha-requirements.md（一覧は棚卸し 2026-09 の PR 本文）
- [ ] L-75 `docs/store-assets-guide.md` と `frontend/kotonoha_app/integration_test/device_test/README.md` は正本ではなく実行可能な手順として現在地に残す。ADR-007 条件 4（ストア提出）の充足で倉庫へ — Phase 5 A1
- [ ] L-84 開発者登録（Apple Developer Program / Google Play）。アプリが形になってから行う（2026-09-24 決定。`docs/now.md`） — ADR-007 条件 4（人が動かす。旧 remaining-work.md から移記）
- [ ] L-85 ストア掲載文（`frontend/kotonoha_app/fastlane/metadata/ja-JP`・`en-US`）を「医療・治療効果を謳わない」観点で点検していない — ADR-007 条件 4（旧 remaining-work.md から移記）
- [ ] L-91 コードや CI が守っているのに ADR に無い決定: `/health` の無認証・無レート制限（`backend/app/routes.py:68-75`、`backend/tests/contract/test_health_docs.py`）、環境名による認証省略と `/docs` 公開（`backend/app/config.py:106-117`）、CORS の形（`backend/app/main.py:187-193`）、`patch('app.` 禁止（`backend/scripts/gates.sh:15-16`）、lint の設定値（`backend/pyproject.toml`）。次の監査で、製品の約束か却下した案に当たるかを見て ADR にするか決める — 2026-09-12 の監査（第二線）。決定（2026-09-20 第 2 回、決定シート）: 現状維持（A）。次の監査で見る。未卒業 ADR は 5 本の上限に達しており、足すなら何かを卒業させる判断が先
- [ ] L-94 `release.yml` が署名鍵・証明書・p12 パスワードを workspace のファイルに書き出す（`:100-121`、`:181-186`）。層 2 の照合に workflow を足したのは 2026-09-12 — .github/workflows/release.yml。決定（2026-09-20 第 3 回、決定シート）: 直す（A）。ランナーの一時ディレクトリに置き `if: always()` で消す。**後始末が 1 つも無いことを実測した**（`rm -f` も `if: always()` も `release.yml` に存在しない。2026-09-20）。tag でしか走らないので現状の被害は小さいが、仕組みが無い状態。L-52（アップロード鍵の配置）と同じ束で
- [ ] L-98 ストア提出の前に独立監査（ADR-010 の監査、監査スキルの付録）を 1 回行う（結果は PR の `<details>`。直すものは仕分けに通す）。条件 4 の充足判定の前 — ADR-010、ADR-007 条件 4
- [ ] L-106 ADR-005 が #125〜#127 で 55 行まで肥大化した（挙動の細部・日付・台帳番号を追記）。60 行上限も「改訂は追記せず書き直す」の規則も 2 系統レビューも捕まえず、利用者が adr-touch のコメントで気づいた。#128 で構造を変えた（ADR-010「決定」の「レビュー指摘に応えて ADR に文を足さない」）。次の監査で、以後の ADR 差分に細部が入らなかったかを見て、効かなければ数字（上限）を見直す — docs/adr/ADR-010-document-framework.md「決定」
- [ ] L-107 ストア提出用の画像がゼロ（アイコン 1024/512、iPhone・iPad・スマートフォンのスクリーンショット、Play のフィーチャーグラフィック 1024×500）。`docs/store-assets-guide.md` のチェックリストは全項目が未着手 — frontend/kotonoha_app/fastlane/（画像 0 件、2026-09-16 実測）。ADR-007 条件 4






- [ ] L-145 Android のクローズドテストが未実行（代行サービスの選定、12 人以上 × 14 日連続のオプトイン、その後 production access を申請）。申請フォームはテスターの募集のしやすさ・全機能を使ったか・本番利用者の使い方と一致したか・集めたフィードバックの要約と収集方法を問う（2026-09-20 に公式ページで確認）。代行で計数要件は満たせるが、回答は実際に起きたことで書く — ADR-007 条件 4（L-108 の決定。人が動かす。L-84 の開発者登録の後、Android 公開の直前の律速）
- [ ] L-146 Play Console のプライバシーポリシー URL（「アプリのコンテンツ」）は fastlane の metadata に無く、コンソールで設定する（iOS は `privacy_url.txt` が正）。L-86 の差し替えと同じ URL にする — ADR-007 条件 4（人が動かす。開発者登録 L-84 の後）
- [ ] L-147 「経緯は書かない」（本文書 3 行目）に反して伸びた行が裾にある。未対応 55 行のうち 200 字以下は 27 行だが、401 字超が 10 行（最長 839 字の L-125）。上限の数字を置くか決める（`scripts/inventory.sh` は台帳の 4 状態を既に数えている） — ADR-010、L-106 と同形。次の監査。決定（2026-09-20 第 2 回、決定シート）: 次の監査で 200 字の上限を ADR-010 の改訂として置く（A）

- [ ] L-152 main の classic protection は 404、適用ルールは `[]`。active ruleset 10494480 も `include=[]` で、required contexts `Python CI` / `Flutter CI` は workflow の job 名と一致しないため、CI 成功を main 更新の必須条件にできているとは確認できない。実 push の拒否は未検証 — `gh api repos/mozuq-lab/kotonoha/{branches/main/protection,rules/branches/main,rulesets/10494480}`（2026-09-21T05:25:32Z live API 再確認）、.github/workflows/{python,flutter}.yml
- [ ] L-173 OfflineBanner の Semantics label（「基本機能…」）が Web の semantics tree に出ない（全条件0件）。読み上げ利用者に offline が伝わらない可能性 — offline_banner.dart、fix/home-overflow QA F-2（2026-09-22）。決定（2026-09-23、仕分け）: iOS/Android の実機 QA（L-25）で読み上げに出るかを見て、出なければ直し、出れば閉じる
- [ ] L-178 常設バナー（persistence_banner.dart）の文言が Web の DOM/semantics ツリーに一切出ない（debug/release とも。同じ検出器はダイアログ告知と `aria-label="日常"` を拾う）。`Semantics(label:)` を根 1 ノードに置いているが Web の semantics には現れず、読み上げ利用者に保存失敗が伝わらない可能性。L-173（OfflineBanner）と同型 — persistence_banner.dart:156-157、fix/phrase-draft-small-fixes QA Q-4（2026-09-23）。決定（2026-09-23、仕分け）: iOS/Android の実機 QA（L-25）で読み上げに出るかを見て、出なければ直し、出れば閉じる
- [ ] L-197 定型文の保存と下書きの消去の待機には上限が無い。SharedPreferences や Hive の書込が返らないと、ダイアログは凍結したまま緊急ボタンの上に残り、閉じる・戻るも止まる（コピーには 5 秒の上限がある）。BASE から — phrase_add_dialog.dart・phrase_edit_dialog.dart の `_saving`（Task 2b 最終レビュー、監査 1 の未確認事項）。決定（2026-09-23、仕分け）: 直す（AGENTS.md の最悪の結果に当たる。上限の値と、上限の後に遅れて成功した保存の扱いは実装時に決める）

## 判断待ち
- [ ] L-58 の残り: backend 公開の 4 条件（支出上限・デプロイと proxy 段数・端末キー配布・実プロバイダでの往復） — ADR-002。通常 CI の Web 成果物には鍵を焼かない（#121 で外した。release は L-149）。決定（2026-09-20 第 2 回、決定シート）: ストア提出後に回す（A）。ADR-007 が「初回は AI 変換抜き可、リリースは backend に依存しない」と決めている。L-55（応答時間の実測）も同日に
- [ ] L-87 dependabot の PR 15 本が滞留（actions #66〜#70、pip #55〜#59、pub #60・#62〜#65）。frontend の `flutter_riverpod` #62・`go_router` #60 はリリース前に上げるか決める。backend の 5 本は Phase 2 で requirements.txt が変わりずれており、`sqlalchemy` #57 は依存自体が無い。close して作り直させるか — .github/dependabot.yml（旧 remaining-work.md から移記）。決定（2026-09-20、決定シート）: actions 5 本（#66〜#70）はまとめてマージ／backend 5 本（#55〜#59）は close して作り直させる（Phase 2 で requirements.txt が変わってずれており、`sqlalchemy` は依存自体が無い）／frontend 4 本は L-80 を決めた後（A）。別セッション（dependabot）で実施
- [ ] L-88 `fix/backend-production-hardening` はローカルにしか無い（#86 で「証拠として残す」と決定）。push して保全するか、ローカル限りとするか — Issue #86（旧 remaining-work.md から移記）。決定（2026-09-20、決定シート）: push して保全する（A）。#86 の「証拠として残す」に沿う
- [ ] L-125 compact が一度失敗すると、その box はそのセッションの間ずっと掃除されない（hive 2.2.3 `storage_backend_vm.dart:147-148` の `_compactionScheduled` が成功時にしか戻らない）。さらに `.hivec` へ書いた後の rename で失敗した場合は閉じた `writeRaf` を持ったままになり、そのセッションは保存もできなくなる（保存を試みた時点で `PersistedBox` がバナーに出す）。失敗した `.hivec` の断片は次に box を開くまで残る。hive 側の挙動で、こちらから旗は戻せない（box を開き直せば戻るが、満杯時は再オープンに失敗して領域ごと失う） — frontend/kotonoha_app/lib/core/persistence/persisted_box.dart の `_removeDeletedFromFile`（#142・#143 の独立監査と Codex。元から）。2026-09-20 追記: この形は `PersistedBox` がセッションの最初の書き込みでも掃除するようになって**到達しやすくなった**（直前の版では delete と clear だけが compact を呼んでいた。put しかしないセッションでも 1 回呼ぶ）。失われるのは「一度失敗した後に空きが戻ったセッションの削除の掃除」で、害はプライバシー（消した発話がファイルに残る）でありデータ喪失ではない。受け入れた理由: 削除しない利用者のセッションは、これが無いと一度も掃除されない（#143 の 2 系統レビューが実測）。決定（2026-09-20、決定シート）: 受け入れて記録する（A）。L-126 と同じく上流の挙動。次の監査で代替評価に含める。開き直しての復帰は、満杯時に再オープンが失敗して領域ごと失うため採らない
- [ ] L-126 掃除（compact）は `.hivec` に書いて rename するが、hive は rename の前に fsync しない（`buffered_file_writer.dart:26-32`）。rename 後・こちらの `flush()` 完了前に電源が落ちると box 全体を失いうる（端末のファイルシステム次第。未検証）。削除のたびと、セッションの最初の書き込みで 1 回、この窓が開く。L-120 で「上書きのたびには掃除しない」と決めた理由と同じ窓 — frontend/kotonoha_app/lib/core/persistence/persisted_box.dart、hive 2.2.3 `storage_backend_vm.dart:181-188`（#143 の独立監査と Codex。#142 から）。決定（2026-09-20、決定シート）: 受け入れて記録する（A）。上流（hive 2.2.3）の挙動でこちらから塞げない。**次の監査で hive の代替（hive_ce など）を評価する**。別セッション（Hive）で扱う

## 受け入れた限界（直さないと決めた、利用者に見える限界）
利用者の声が届くか、守る約束を破る経路が見つかったら `[ ]` に戻す。
- [~] L-198 下書きの書込が失敗しているときの告知の出し分け: 消せなかった下書きが後の書込で保存され「消せません」が消える／開き直した本文は入力に数えないので、その後の書込が失敗しても「消えます」と告げない（打ち直せば数える）／「保存できません…消えます」と「消せません…残ります」が並ぶ／書込失敗のまま missing になると孤立の閲覧が「残っています」と告げるが最新版が store に無いことがある（常設バナーは保存失敗を告げている）／復元のまま保存して書込失敗だと store に同じ内容があっても「消えます」（安全側） — phrase_draft_provider.dart・persistence_banner.dart・phrase_edit_dialog.dart（旧 L-187・L-193・L-194・L-195）
- [~] L-199 下書きの破損の告知はセッション中閉じられず、文字盤の上に残る（Hive の喪失の告知は「閉じる」で消せる） — persistence_banner.dart、`phraseDraftCorruptKey`（旧 L-189）
- [~] L-200 Android の `commit()` は失敗しても値をプロセス内に残すので、store に無いとみなして消去済みにした下書きが、別キーの commit の成否の順序次第で次回戻り得る（告知なし。support.md:21「消去できなかったときはその旨をお知らせします」と食い違う向き。失われるものは無い。未確認） — phrase_draft_provider.dart `_stored`（旧 L-196）
- [~] L-201 Web の複数タブで、下書きの 1 キーの map を古い cache から書き戻して他のタブの下書きが消える。同 ID・同内容を他タブが書くと自分のレコードと判定し得る。公開文と NFR-302 で開示。決定: 単一 map のまま受け入れ、編集の下書きも同じ map に載せる（R1） — phrase_draft_provider.dart `_write`、preset_phrase_screen.dart `ownsId`（旧 L-158）
- [~] L-202 Web でストレージが無効（getItem が throw）だと設定（フォント）が既定に戻り、未処理例外（pageerror）が出る。#193 より前から — app_session_provider.dart か tutorial_provider.dart（旧 L-183）
- [~] L-206 追加フォームの読込失敗中に別カテゴリ → 既定へ戻すと、「再読み込み」が下書きのカテゴリで黙って置き換える（触ったかの旗で消えるが状態が 1 つ増える） — phrase_add_dialog.dart `_untouched`（旧 L-179）
- [~] L-207 元と同じ内容に戻した編集下書きが一覧に残る（「キャンセル」で消える。元を削除すると孤立として残る）。決定: 記録のみ — phrase_edit_dialog.dart（旧 L-180）
- [~] L-208 編集の下書きは base を持たないので、保存済みより古い下書きが出ることがある（開いた時点で告げ、「キャンセル」で戻る）。決定: 告知のみ。base を持つ案は採らず、実フィードバックで再訪 — phrase_edit_dialog.dart `_load`（旧 L-181）
- [~] L-209 iOS は下書きの書込失敗を検出できない（`UserDefaults.set` は結果を返さない）。基準は満たすが直す手段が無い。読み戻し検証は cache が返り偽の緑になるので採らない。公開文は Web/Android 限定と明記 — shared_preferences_foundation（旧 L-165）
- [~] L-215 可視高さ 250 未満では縦積みでも文字盤と操作群に 44px の行が入らない（幅が足りなくても 2 ペインには戻さない。戻すとセル 25.12px。高さ境界 399/400・倍率 1.3 は未検査） — home_screen.dart `availableHeight` の下限（旧 L-172）
- [~] L-216 定型文由来のお気に入りの重複判定が `sourceId` だけで、同文のお気に入りが 2 件並び得る（お気に入り画面から消せる）。決定: 受け入れ。content でも判定する案は「同じ文の別の定型文」を持てなくするので採らない — favorite_provider.dart（旧 L-99）
- [~] L-217 フォント設定がサイズを持たないスタイル（ダイアログの見出し等）に効かず、REQ-2007「すべてのテキスト要素」は未達。決定: 根治（アプリ根の textScaler）は今はやらない。移るときはテーマの倍率がけ `_scaled` を同時に外す（残すと二重掛け） — theme_provider.dart（旧 L-111）
- [~] L-218 公開 FAQ に下書きの 3 つの告知（消せない・読めない・壊れていた）の項が無い。近い「…の一部を読み込めませんでした」の項は退避と「閉じる」を案内するが、下書きの破損の告知は閉じられず退避の写しも無い — docs/user-guide/faq.md（旧 L-188）
- [~] L-219 Web の複数タブで、別タブの編集の保存（自タブの state だけを見る）が、このタブで削除した定型文を IndexedDB へ書き戻し得る。BASE から。公開文と NFR-302 で開示 — preset_phrase_notifier.dart `updatePhrase`、hive `storage_backend_js.dart`（旧 L-184）
- [~] L-220 320×690・1000 文字で入力上限の告知の末尾が操作域の下端で切れて見える（未計測、screenshot のみ） — input_limit_notice.dart、home_screen.dart（旧 L-174）
- [~] L-221 2 ペインの左ペインでフォント大のプレースホルダが 2 行に折り返して 1 行目が切れる。上下ボタンが無く、AI ボタンと offline チップはスクロールで届く（BASE から） — home_screen.dart `_buildCompactLandscapeLayout`（旧 L-175）

## 計測（監査の記録。最新の 1 回だけ残す）
| 日付 | 核（字） | 未卒業 ADR | 台帳 予定/受け入れ | 全置き場の合計（字） | 製品/全体（前回から） |
|---|---|---|---|---|---|
| 2026-09-24（開発の仕組みの書き直し） | AGENTS.md 5,127 字 | 5 本 | 26 / 16 | 文書 109,681 字（書き直し前 167,996）＋メモリ 18,677 字（13 ファイル。整理前は 23 ファイル）。作業場 `.superpowers/` は別に片付ける | 96 / 275（直近 30 日） |
