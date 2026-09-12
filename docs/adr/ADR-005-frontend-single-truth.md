# ADR-005: frontend は 1 概念 1 真実。永続化の失敗は利用者に伝える

状態: 承認済み（2026-08-29 決定、2026-09-06 書き直し、2026-09-13 改訂: お気に入りは定型文の寿命と独立／作り直しと設定の失敗も伝える。同日、挙動の細部をテストと対応箇所のコメントへ降ろした。署名: mozuq）／ 実装は PR #88、#125〜#127

## 背景と課題

お気に入りが 4 箇所に散っていた: `HistoryItem.isFavorite`（書かれるが常に false、UI は読まない）／`frontend/kotonoha_app/lib/features/favorite/`（ロジック）／`frontend/kotonoha_app/lib/features/favorites/`（UI）／`PresetPhrase.isFavorite`（Hive field 3 として**永続化**され、UI が読み、favoriteNotifier と双方向同期する——独立レビューが検出した 4 箇所目）。
`isFavorite` のバグは Hive アダプタのテストが緑のまま生き残った。欠陥は変換層にあり、テストは層を飛ばして下だけを叩いていた。
Hive が開けないと黙ってインメモリで動き続けた（`frontend/kotonoha_app/lib/shared/providers/repository_providers.dart` の null を返すフォールバックが「意図した設計」として実装されていた）。発話支援アプリで「保存できたように見えて消える」は起動しないことより重い——利用者は発話で確認・訂正できず、データは端末内にしか無い。

## 制約

- NFR-301（基本機能継続）: ストレージ障害でも文字盤・TTS は使えるべき（オフラインファースト）
- 利用者は複雑なエラー表示を操作できない。通知は簡潔に

## 検討した選択肢

お気に入りの真実: 1. 現状維持（4 箇所併存）／2. `HistoryItem.isFavorite` に一本化／3. **`favoriteProvider` に一本化し、`isFavorite` を削除**（採用）
永続化失敗の扱い: a. サイレント継続（現状）／b. 起動をブロックする／c. **状態を型で明示し、利用者に伝えて継続する**（採用）

## 決定

- お気に入りは案 3。`favoriteProvider` が真実。キーは内容テキストではなく id（同文の定型文で衝突しない）。**お気に入りは作った時点の写し**で、定型文の寿命と独立に生きる（削除で消えず、編集に追随しない）。`isFavorite` は `HistoryItem`・`PresetPhrase` から削除済み（Hive migration は実装後に撤回した。`f761afc`）
- **真実は 1 つ、射影は用途ごとに決めてよい。** 履歴画面の星は content 照合、候補スコアはテキスト射影のまま（id 照合にすると、定型文由来の同文や上限で消えた履歴に星が付かない。id が要る衝突は「同文の定型文どうし」だけで、`sourceId` の重複判定で解決済み）
- 永続化は案 c。保存されない状態（書き込み失敗・破損で空に作り直した・設定の保存失敗）を `PersistenceState` の型で持ち、利用者に伝えて継続する。退避したデータを戻す手段は持たない
- 1 概念 1 真実は**最も外側の境界**で確かめる。UI → provider → repository → 実 box → 再起動相当 → UI を通す往復テストを history / preset_phrase / favorite / settings の 4 feature に置く
- 挙動の細部（文言・閉じ方・失敗の注入）はこの文書に書かない。テスト名と対応箇所のコメントで指す（ADR-010）

## 決定理由と却下案

- お気に入り案 1 却下: 多重実装の温存。「タグ機能を追加して」の日に 5 つ目が生まれる
- お気に入り案 2 却下: 決め手は**概念の所有者とライフサイクル**——お気に入りは「項目に付くフラグ」ではなく「履歴・定型文をまたいで参照する独立のコレクション」で、項目の削除・保持上限と独立に生きるべきもの。フラグ方式は項目の寿命にお気に入りの寿命を結合してしまう。**定型文の削除でお気に入りも消す連鎖削除も同じ理由で却下**（2026-09-13 まで実装がこの却下理由と矛盾していた。TC-SYNC-202 が「残る」を固定する）
- 永続化案 a 却下: データ喪失を利用者が知る手段が無い
- 永続化案 b 却下: NFR-301 に反する。インメモリでも話せる方がよい——ただし**保存されないことは必ず伝える**

## 限界

永続フィールドを伴わない「UI ロジックだけの重複」は許可リストで捕まえられない。ロジックの `frontend/kotonoha_app/lib/features/favorite/` と UI の `frontend/kotonoha_app/lib/features/favorites/` の分裂は現存する（L-67）。
許可リスト検査が守るのは起動時の共有登録経路だけで、共有関数を経由しない直接の `Hive.registerAdapter` / `Hive.openBox` は守れない。Dart には「この API を他所で呼ばせない」構造が無い。**自作の検出器は作らない**（AGENTS.md 規律 8 ／ADR-008）。
「トップレベル可変変数の禁止」は analyzer では実現できない（該当する lint が Dart に無い。2026-08-31 実測）。記録して受け入れた。
Hive が報告しない書き込み失敗（box が開いたままのディスクフル。hive 2.2.3 `box_impl.dart:82`）は伝えられない。EDGE-003（容量不足の警告）は未達のまま受け入れる。設定の保存失敗は同じセッション内でしか伝えられず、報告経路に乗らない書き込みが残る（L-104）。同文のお気に入りが 2 件並び得る（L-99）。

## 検査

(i) 層 2 — 永続化（`scripts/adr-touch.sh` が `lib/shared/models/*_adapter.dart` と `frontend/kotonoha_app/lib/core/utils/hive_init.dart` を拾って索引行を貼る）。
(ii) `frontend/kotonoha_app/test/core/persistence/hive_schema_allowlist_test.dart`（`typeId`・永続フィールド。本番と同じ `registerPersistedTypeAdapters()` が登録した実体だけを見る。設計の経緯はファイル冒頭）／往復テスト 4 本（`frontend/kotonoha_app/test/features/*/*_round_trip_test.dart`。守る lint 4 つは `analysis_options.yaml` で warning に昇格）／`favorite_sync_test.dart` の TC-SYNC-202（削除しても残る）／破損と保存失敗の注入テスト（`test/core/utils/hive_init_*_test.dart`、`test/features/settings/providers/settings_write_failure_test.dart`）。
(iii) UI ロジックだけの重複は層 3（差分レビュー）と月 1 の棚卸しだけ。

## 再訪条件

利用者・支援者からの実フィードバックで通知の形が使えないと分かったとき（受付経路はストア掲載のサポート連絡先。ADR-007。非クラッシュ不具合はクラッシュ報告に映らない）。容量不足による消失の報告が 1 件出たとき。退避したデータを取り出したい場面が実際に出たとき。
