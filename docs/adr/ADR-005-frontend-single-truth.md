# ADR-005: frontend は 1 概念 1 真実。永続化の失敗は利用者に伝える

状態: 承認済み（2026-08-29 決定、2026-08-30/31 の Phase 3 実装で確定、2026-09-06 書き直し。署名: mozuq）／ 実装は PR #88（main へマージ済み）

## 背景と課題

お気に入りが 4 箇所に散っていた: `HistoryItem.isFavorite`（書かれるが常に false、UI は読まない）／`frontend/kotonoha_app/lib/features/favorite/`（ロジック）／`frontend/kotonoha_app/lib/features/favorites/`（UI）／`PresetPhrase.isFavorite`（Hive field 3 として**永続化**され、UI が読み、favoriteNotifier と双方向同期する——独立レビューが検出した 4 箇所目）。
`isFavorite` のバグは Hive アダプタのテストが緑のまま生き残った。欠陥は変換層にあり、テストは層を飛ばして下だけを叩いていた。
Hive が開けないと黙ってインメモリで動き続けた（`frontend/kotonoha_app/lib/shared/providers/repository_providers.dart` の null を返すフォールバックが「意図した設計」として実装されていた）。発話支援アプリで「保存できたように見えて消える」は起動しないことより重い——利用者は発話で確認・訂正できず、データは端末内にしか無い（B-2 の最悪ケース「データ喪失」）。

## 制約

- NFR-301（基本機能継続）: ストレージ障害でも文字盤・TTS は使えるべき（オフラインファースト）
- 利用者は複雑なエラー表示を操作できない。通知は簡潔に

## 検討した選択肢

お気に入りの真実: 1. 現状維持（4 箇所併存）／2. `HistoryItem.isFavorite` に一本化／3. **`favoriteProvider` に一本化し、`isFavorite` を削除**（採用）
永続化失敗の扱い: a. サイレント継続（現状）／b. 起動をブロックする／c. **状態を型で明示し、利用者に伝えて継続する**（採用）

## 決定

- お気に入りは案 3。UI が実際に使っている `favoriteProvider` が真実。キーは内容テキストではなく id で、`FavoriteItem` のレコード同一性と、定型文連動の同期キー `sourceId` に適用する
- **真実は 1 つ、射影は用途ごとに決めてよい。** 履歴画面の星は content 照合のまま（sourceId 照合にすると、定型文由来の同文に星が付かない／同じ文言を再発話すると付かない／履歴 50 件上限でアンカーの履歴が消えると二度と付かなくなる。案 2 の却下理由が名指しした衝突は「同文の**定型文どうし**」で、`addFavoriteFromPresetPhrase` の sourceId 重複判定で解決済み）。`input_candidate_scorer` はテキスト射影のまま（`computeCandidates` は `List<String>` しか受けず、集計は候補テキストがキー、出力は `InputCandidate(text:, score:)` で、id を持てる場所が型の上に存在しない）
- `isFavorite` は `HistoryItem`・`PresetPhrase` の両方から削除済み。Hive migration は実装してレビューまで通したうえで撤回した（`f761afc`）。守る価値のあるデータが検証端末に無く、残すと (1) お気に入り画面から削除したものが再起動で復活する（UI から到達可能）(2) 移行は `PresetPhrase.isFavorite` を読むのでそのフィールドを消すビルドと共存できない、の 2 つが避けられなかった
- 永続化は案 c。`sealed class PersistenceState { Ready / RecoverableFailure / Unavailable }` とし、保存されない状態を利用者に通知する
- 1 概念 1 真実は**最も外側の境界**で確かめる。UI → provider → repository → 実 box → 再起動相当 → UI を通す往復テストを history / preset_phrase / favorite / settings の 4 feature に置く（定型文の往復は presetPhrases box と favorites box の 2 つをまたぐので、定型文側にフラグが残っていたら通らない）

## 決定理由と却下案

- お気に入り案 1 却下: 多重実装の温存。「タグ機能を追加して」の日に 5 つ目が生まれる
- お気に入り案 2 却下: 決め手は**概念の所有者とライフサイクル**——お気に入りは「項目に付くフラグ」ではなく「履歴・定型文をまたいで参照する独立のコレクション」で、項目の削除・保持上限と独立に生きるべきもの。フラグ方式は項目の寿命にお気に入りの寿命を結合してしまう（当初の却下理由「UI が読んでいない・往復テストが無い」は現状の欠陥であって案の本質的欠陥ではない、という独立レビューの指摘を受けて書き直した。UI 更新とテスト追加を同条件で仮定しても、所有者の理由で案 3 が優る）
- 永続化案 a 却下: データ喪失を利用者が知る手段が無い
- 永続化案 b 却下: NFR-301 に反する。インメモリでも話せる方がよい——ただし**保存されないことは必ず伝える**

## 限界

永続フィールドを伴わない「UI ロジックだけの重複」は許可リストで捕まえられない。ロジックの `frontend/kotonoha_app/lib/features/favorite/` と UI の `frontend/kotonoha_app/lib/features/favorites/` の分裂は現存する（L-67、Phase 5 で統合）。
許可リスト検査が守るのは起動時の共有登録経路だけで、共有関数を経由しない直接の `Hive.registerAdapter` / `Hive.openBox` は守れない。Dart には「この API を他所で呼ばせない」構造が無く、開かれている box を列挙する公開 API も Hive に無い。**自作の検出器は作らない**（AGENTS.md 規律 8 ／ADR-008）。受け皿は AGENTS.md 規律 8 と層 1・3・5。
「トップレベル可変変数の禁止」は analyzer では実現できない（`avoid_top_level_mutable_variables` も `avoid_global_state` も Dart に存在しない。`undefined_lint`、2026-08-31 実測）。記録して受け入れた。
**却下理由と実装が矛盾している（未解決）**: 案 2 の却下理由は「項目の削除・保持上限と独立に生きるべき」だが、`deletePhrase()` は `deleteFavoriteBySourceId()` を呼び、定型文を消すとお気に入りも消える。`TC-SYNC-202`（要件定義 3.2「孤立データ防止」由来）が**それを正解として固定している**ため、全テスト緑はこの不適合を反証しない（L-39）。2026-08-30 の対応は振る舞いを変えず、削除確認ダイアログに「お気に入りからも削除されます」を出すだけ（登録済みのときだけ）。解くには本 ADR か要件定義 3.2 の改訂が要る。

## 検査

(i) 層 2 — 永続化（`scripts/adr-touch.sh` が `*_adapter.dart` と `frontend/kotonoha_app/lib/core/utils/hive_init.dart` を拾って索引行を貼る）。
(ii) `frontend/kotonoha_app/test/core/persistence/hive_schema_allowlist_test.dart`（`typeId`・永続フィールド）。検査は `initHive()` が呼ぶのと同じ `registerPersistedTypeAdapters()` を呼び、**その関数が登録した実体だけ**を見る（検査側が一覧を書き写すと、本番にだけ足された永続化面を見逃す。L-31）。当初の実装は「typeId が増えたら赤」だが、赤いメッセージが許可リストの更新を指示するため、指示どおり足すとそのアダプタのフィールド番号・型を以後どの検査も見ない状態で緑に戻った（2026-08-31 の 2 系統レビュー）。検査を足すのではなく、登録の観測点を 1 つにする**構造の変更**で塞いだ。
(ii) 往復テスト 4 本（`frontend/kotonoha_app/test/features/*/*_round_trip_test.dart`）。守る対象が文書に名指しされている 4 つの lint（`unawaited_futures` / `avoid_dynamic_calls` / `cancel_subscriptions` / `close_sinks`）を、CI で実際に落ちる強さ（warning）まで昇格してある——既定の info は `flutter analyze --no-fatal-infos` を通過して一度も発火しない。
(iii) UI ロジックだけの重複は層 3（差分レビュー）と月 1 の棚卸しだけ。

## 再訪条件

利用者・支援者からの実フィードバックで通知の形が使えないと分かったとき。判定手段は月 1 の巡回でストアレビューとサポート窓口への報告を確認すること（非クラッシュ不具合はクラッシュ報告に映らない——独立レビューの指摘。受付経路はストア掲載のサポート連絡先。ADR-007）。L-39 を解くとき。
