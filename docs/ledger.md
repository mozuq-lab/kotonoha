# 台帳 — 決めた予定と受け入れた限界

規則（ADR-010）: 置くのは、決めた予定（`[ ]`）と、利用者に見える受け入れた限界（`[~]`）だけ。直さない指摘は記録しない。1 問題 1 行＋出所で、経緯は書かない。
`[x]`（対応済み）と `[-]`（却下）は付けた PR で行ごと消す（履歴は git。消した行は `git log -p -G '\] L-NN ' -- docs/ledger.md` で引ける）。仕事の入口は `docs/now.md` の最短経路で、この台帳の予定は最短経路に入れるまで着手しない。
読むのは必要なときだけ（核には数えない）。#85（この台帳の PR のマージ後に閉鎖）から仕分けて作った。

## 予定
- [ ] L-25 `frontend/kotonoha_app/integration_test/device_test/`（実機QA手順、1,773行）が一度も実行されていない — ADR-007 条件 4（ストア提出前に必要）
- [ ] L-51 サポート連絡先が `support@kotonoha-app.example.com` のまま（RFC 2606 の予約ドメイン） — docs/support.md, docs/privacy-policy.md。ADR-007 条件 4
- [ ] L-52 Android のアップロード鍵が無い。無いと release ビルドは debug 鍵で署名される（`frontend/kotonoha_app/android/app/build.gradle.kts:67-73`） — .github/workflows/release.yml。ADR-007 条件 4。開発者登録（L-84）の後
- [ ] L-55 AI 変換の平均応答時間（3秒以内）が未測定 — ADR-002 のプロバイダ支出上限設定と同日に実測（backend 公開の前提）
- [ ] L-57 Android 12 以上と iOS の実機で、OS のバックアップから履歴・定型文・お気に入り・設定が復元されることを確認 — NFR-106（2026-09-12 に #99 の除外を撤回）
- [ ] L-58 backend 公開の 4 条件（支出上限・デプロイと proxy 段数・端末キー配布・実プロバイダでの往復）が未達 — ADR-002。決定（2026-09-26）: 初回リリースに AI 変換を含めるので、ストア提出の前に満たす。L-55 も同日に
- [ ] L-75 `docs/store-assets-guide.md` と `frontend/kotonoha_app/integration_test/device_test/README.md` は正本ではなく実行可能な手順として現在地に残す。ADR-007 条件 4（ストア提出）の充足で倉庫へ — Phase 5 A1
- [ ] L-84 開発者登録（Apple Developer Program / Google Play）。アプリが形になってから行う（2026-09-24 決定。`docs/now.md`） — ADR-007 条件 4（人が動かす。旧 remaining-work.md から移記）
- [ ] L-87 dependabot の PR 15 本が滞留 — .github/dependabot.yml。決定（2026-09-20）: actions 5 本（#66〜#70）はまとめてマージ、backend 5 本（#55〜#59）は close して作り直させる（requirements.txt とずれ、`sqlalchemy` は依存に無い）。frontend 5 本（#60・#62〜#65）は未決（前提の L-80 は #162 で済んだ）
- [ ] L-88 `fix/backend-production-hardening` がローカルにしか無い（#86 で証拠として残すと決定） — Issue #86。決定（2026-09-20）: push して保全する
- [ ] L-91 コードや CI が守っているのに ADR に無い決定（`/health` の無認証・無レート制限、環境名による認証省略と `/docs` 公開、CORS の形、`patch('app.` 禁止、lint の設定値） — backend/app/{routes,config,main}.py、backend/scripts/gates.sh、backend/pyproject.toml。決定（2026-09-20）: 次の監査で ADR にするか決める（未卒業 ADR は上限の 5 本）
- [ ] L-98 ストア提出の前に独立監査（ADR-010 の監査、監査スキルの付録）を 1 回行う（結果は PR の `<details>`。直すものは仕分けに通す）。条件 4 の充足判定の前 — ADR-010、ADR-007 条件 4
- [ ] L-106 ADR-005 が #125〜#127 で 55 行に肥大化し、#128 で構造を変えた（ADR-010「レビュー指摘に応えて ADR に文を足さない」）。次の監査で、以後の ADR 差分に細部が入っていないかを見て、効いていなければ上限を見直す — docs/adr/ADR-010-document-framework.md
- [ ] L-107 ストア提出用の画像が無い（アイコン 1024/512、iPhone・iPad・スマートフォンのスクリーンショット、Play のフィーチャーグラフィック 1024×500） — frontend/kotonoha_app/fastlane/、docs/store-assets-guide.md。ADR-007 条件 4
- [ ] L-145 Android のクローズドテスト（12 人以上 × 14 日連続。代行サービスで集める）と、その後の production access の申請が未実施。申請の回答は実際に起きたことで書く — ADR-007 条件 4。人が動かす。L-84 の後、Android 公開の直前
- [ ] L-146 Play Console のプライバシーポリシー URL は fastlane の metadata に無く、コンソールで設定する（iOS は `privacy_url.txt`）。同じ URL にする — ADR-007 条件 4。人が動かす。L-84 の後
- [ ] L-147 台帳の 1 行の字数に上限が無い（2026-09-24 の整理で長い行は縮めた） — ADR-010。決定（2026-09-20）: 次の監査で 200 字の上限を ADR-010 の改訂として置く
- [ ] L-152 CI の成功が main 更新の必須条件になっているか確認できない（classic protection は 404、ruleset 10494480 は `include=[]`、required contexts `Python CI`・`Flutter CI` が job 名と一致しない。実 push の拒否は未検証） — `gh api` で 2026-09-21 に確認、.github/workflows/{python,flutter}.yml
- [ ] L-173 OfflineBanner の読み上げ用ラベルが Web の semantics tree に出ない — offline_banner.dart。決定（2026-09-23）: iOS/Android の実機 QA（L-25）で読み上げに出るかを見て、出なければ直し、出れば閉じる
- [ ] L-178 常設バナー（保存失敗の告知）の文言が Web の DOM と semantics tree に出ない（L-173 と同型） — persistence_banner.dart。決定（2026-09-23）: L-173 と同じく実機 QA（L-25）で見る

## 受け入れた限界（直さないと決めた、利用者に見える限界）
利用者の声が届くか、守る約束を破る経路が見つかったら `[ ]` に戻す。
- [~] L-125 hive の compact が一度失敗すると、その box はセッションの間掃除されず（消した発話がファイルに残る）、rename で失敗すると保存もできなくなる（バナーで告げる）。hive 2.2.3 の挙動でこちらから戻せない — persisted_box.dart `_removeDeletedFromFile`。決定（2026-09-20）: 受け入れる。次の監査で hive の代替（hive_ce など）を評価する
- [~] L-126 hive は compact の rename の前に fsync しないので、直後に電源が落ちると box 全体を失い得る（未検証。削除のたびとセッションの最初の書き込みで窓が開く） — persisted_box.dart、hive 2.2.3 `buffered_file_writer.dart`。決定（2026-09-20）: 受け入れる。L-125 と同じく次の監査で代替を評価する
- [~] L-215 可視高さ 250 未満では縦積みでも文字盤と操作群に 44px の行が入らない（幅が足りなくても 2 ペインには戻さない。戻すとセル 25.12px。高さ境界 399/400・倍率 1.3 は未検査） — home_screen.dart `availableHeight` の下限（旧 L-172）
- [~] L-216 定型文由来のお気に入りの重複判定が `sourceId` だけで、同文のお気に入りが 2 件並び得る（お気に入り画面から消せる）。決定: 受け入れ。content でも判定する案は「同じ文の別の定型文」を持てなくするので採らない — favorite_provider.dart（旧 L-99）
- [~] L-217 フォント設定がサイズを持たないスタイル（ダイアログの見出し等）に効かず、REQ-2007「すべてのテキスト要素」は未達。決定: 根治（アプリ根の textScaler）は今はやらない。移るときはテーマの倍率がけ `_scaled` を同時に外す（残すと二重掛け） — theme_provider.dart（旧 L-111）
- [~] L-220 320×690・1000 文字で入力上限の告知の末尾が操作域の下端で切れて見える（未計測、screenshot のみ） — input_limit_notice.dart、home_screen.dart（旧 L-174）
- [~] L-221 2 ペインの左ペインでフォント大のプレースホルダが 2 行に折り返して 1 行目が切れる。上下ボタンが無く、AI ボタンと offline チップはスクロールで届く（BASE から） — home_screen.dart `_buildCompactLandscapeLayout`（旧 L-175）

## 計測（監査の記録。最新の 1 回だけ残す）
| 日付 | 核（字） | 未卒業 ADR | 台帳 予定/受け入れ | 全置き場の合計（字） | 製品/全体（前回から） |
|---|---|---|---|---|---|
| 2026-09-24（開発の仕組みの書き直し） | AGENTS.md 5,127 字 | 5 本 | 26 / 16 | 文書 109,681 字（書き直し前 167,996）＋メモリ 18,677 字（13 ファイル。整理前は 23 ファイル）。作業場 `.superpowers/` は別に片付ける | 96 / 275（直近 30 日） |
