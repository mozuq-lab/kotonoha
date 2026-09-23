**破棄条件: この作業の PR がマージされたら、このファイルを消す（同じ PR で消してよい）。**

# 依頼: 定型文フォームの下書き機能を消す（A 級）

worktree `/Volumes/external/dev/kotonoha/.claude/worktrees/fix-remove-phrase-drafts`、branch `fix/remove-phrase-drafts`（PR #202 `docs/requirements-trim` の上に積んでいる）。先に `AGENTS.md` と `docs/now.md` を読むこと（開発の手順はそこが正）。

## なぜ
開発者の決定（2026-09-24）: 要件 NFR-302 を原典に戻した（「強制終了しても定型文・設定・履歴を失わず、文字盤の入力中の文を復元する」。PR #202 の `docs/spec/kotonoha-requirements.md`）。定型文の追加・編集フォームの下書きは要件から外れたので、機能ごと消す。

## 消すもの
- 定型文フォームの下書き: `lib/features/preset_phrase/providers/phrase_draft_provider.dart`（ファイルごと）と、それを使う所すべて — 追加フォームの復元・400ms 保存・消去・読込失敗の告知と「再読み込み」、編集フォームの復元と古い下書きの告知、元の定型文が消えた下書き（孤立）の閲覧・コピー・「下書きを破棄」、定型文画面の「下書き」ボタンと一覧、paused 時の下書きの flush（`app_lifecycle_observer.dart` の定型文の下書きの分）、常設バナーの下書きの告知と識別子（`persistence_banner.dart`・`settings_write_failure_provider.dart` の `phraseDraft*`）
- テスト: `test/features/preset_phrase/phrase_draft_round_trip_test.dart`（ファイルごと）、`preset_phrase_round_trip_test.dart` などにある下書き向けのケース
- 公開文: `docs/support.md`（日英）と `docs/privacy-policy.md`（日英）の定型文の下書きの記述、`docs/user-guide/faq.md` の該当箇所
- 台帳 `docs/ledger.md`: 下書きだけに関わる受け入れた限界（L-198・L-199・L-200・L-206・L-207・L-208・L-209・L-218）を消し、L-197 を下書きの消去を除いた形に書き直す（定型文の保存の待機に上限が無い点は残る）
- `docs/now.md` の最短経路 1 番の行を消す

## 残すもの（下書きと一緒に入ったが、下書きが無くても要る）
- **文字盤の入力中の文の保存と復元**（`app_session_provider.dart` の `draft_text`、その保存失敗の告知）。これは NFR-302 に残っている
- 追加フォームの**保存先 ID の固定**（1 つのダイアログにつき 1 つの ID。一次の保存が届いた後に失敗しても、再試行で 2 件にならない。台帳 L-143 の経緯）。ただし下書きとの所有権の照合（`ownsId`・`PhraseDraftOwnership`）は、下書きが無ければ要らないはずなので、コードを読んで判断する
- 編集で元の定型文が消えていたとき（missing）の告知と、入力を残すこと（下書きが無いので、孤立の閲覧には移らない）
- 保存の待機中の凍結と、包みの型を替えないこと（`DiscardInputGuard(busy:)`・`ExcludeFocus`・`AbsorbPointer`）、入力があるときの戻る操作の確認
- Hive の保存失敗の告知（ADR-005）

## 端末に残る古いデータ
消した後も、開発者の端末や、Web で一度でも開いたブラウザには `preset_phrase_drafts`（SharedPreferences、Web の実キーは `flutter.preset_phrase_drafts`）が残る。公開文から下書きの記述を消す以上、残したままだと公開文と食い違う。**起動時に 1 回このキーを消すコードを入れる**（数行。コメントに理由を書く）。

## 手順（AGENTS.md の A 級）
1. テストを先に書いて赤を見る: 例として「追加フォームと編集フォームで打っても `preset_phrase_drafts` に何も書かれない」「起動すると古い `preset_phrase_drafts` が消える」「定型文画面に『下書き』が無い」。消す前のコードで赤になることを確かめる（ログを残す）
2. 消す。残すものは、既存のテストが緑のままであることで確かめる（下書き向けのケースだけを消し、保存・編集・削除・missing・ID の固定・凍結のケースは残す）
3. `fvm flutter test --no-pub`、`fvm flutter analyze --no-pub --no-fatal-infos`、`fvm dart format --output=none --set-exit-if-changed .` を個別の exit で。`pubspec.lock` の SHA256 は `d8db532cc659576817c9bab85c91437e8737ab7736d882f1a27549e60f5dcf81` のまま（動いたら `git checkout HEAD -- pubspec.lock`）。依存は `fvm flutter pub get --enforce-lockfile` で入る
4. 実物での確認: 定型文の追加・編集・削除の結合テスト（`integration_test/` にあるものを使う。無ければ最小のシナリオを足す）を、iOS シミュレータ（iPad）と Android エミュレータ（`Medium_Phone_API_36.1`）で走らせる。画像を読むのは失敗したときだけ
5. commit は `fix:`（コード＋テスト）と `docs:`（公開文・台帳・現在地）に分ける。日本語 1 行、末尾に `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`

## 制約
- 自分の関数・provider・widget をモックしない。モックは SDK 境界（SharedPreferences の store、Clipboard）だけ
- A 級なので、実装の後に Codex のレビュー 1 系統と、文脈を持たない担当による独立監査（コードから `docs/privacy-policy.md`・`docs/support.md` へデータの流れを追う）を通す
- PR は PR #202（`docs/requirements-trim`）のマージ後に main へ rebase して出す。本文は `.github/pull_request_template.md` の形
