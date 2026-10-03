# 現在地（上書きする 1 枚。日誌にしない。古くなった行は消す）

更新: 2026-10-03

## 目的
アプリを「形」にして、iOS から公式ストアで届ける（ADR-007）。

## 「形」の定義（エージェントの案。違えば人が直す）
要件の MVP（文字盤・読み上げ・定型文・履歴・お気に入り・設定）を、初めて使う人が説明なしに一通り使え、その利用シナリオが iOS シミュレータ（iPad）と Android エミュレータで結合テスト（`integration_test/`）として通る状態。録画は人が見たいときに添える。AI 変換も初回に含める（2026-09-26 の人の決定。ADR-007 条件 5）。

## 今ある状態（2026-10-03 に現物で確認）
- backend は `https://kotonoha-backend.pepoq.workers.dev` で本番設定で動いている（`/api/v1/health` が `workers_ai` を返す、`/docs` は 404、キー無しの変換は 401）。本番の起動ガードを通っているので、端末キーと AI Gateway の ID は入っている
- リポジトリ変数 `API_BASE_URL` は公開先、シークレット `AI_API_KEY` は登録済み
- backend 公開の 4 条件（L-58）は満たしたとする。AI Gateway は支出上限 1 ドル／月・回数制限 200 リクエスト／5 分。支出上限が Workers AI に効くことは未確認のまま進める（2026-10-03 の人の決定。ADR-002）
- AI 変換の質は 24 件で確認済み（古風な「丁寧」は受け入れた限界 L-222）
- プライバシーポリシーは GitHub Pages で配信中。ストア用のスクリーンショット（iPhone 6.9・iPad 13・Android 電話）は 2026-10-03 に今の画面で撮り直し、`fastlane/screenshots/ja-JP/` にある
- `integration_test/mvp_scenario_test.dart`（7 本）は 2026-10-03 に今の画面で、iPad シミュレータ（iPad (A16)）・Android エミュレータ（`Medium_Phone_API_36.1`）・Chromium（main の CI）で通過（ADR-007 条件 2）

## 最短経路（上から順に。終わった行は消す）
1. AI 変換の利用シナリオを iOS シミュレータ・Android エミュレータ・実 Chromium で通す（ADR-007 条件 5。`ai_conversion_e2e_test.dart` はモックサーバー相手）
2. Play 用のアイコン 512 とフィーチャーグラフィック 1024×500（L-107。Android 公開の前まで）
3. ストア提出前の独立監査（L-98）。AI 変換の送信経路（端末 → backend → Cloudflare Workers AI）も対象にする。最後に行う

## 人待ち
- 開発者登録（L-84）: 審査と Play Console はここから始まる。コード作業と並行できる
- AI 変換の公開文: 送り先を Cloudflare（米国。日本国外で処理されることがある）と明記した同意ダイアログ・プライバシーポリシー・FAQ の承認と、個人情報保護法 28 条（外国にある第三者への提供）の確認。ストアのプライバシー表示とデータセーフティは開発者登録（L-84）の後
- サポート連絡先（L-51）: 公開文のアドレスが仮の `support@kotonoha-app.example.com` のまま（`docs/support.md`・`docs/privacy-policy.md`）
- 要件にあるのに入口が無いものを、作るか要件から外すか: REQ-4003（アプリの中から音量・音量設定に届く）、REQ-601 のうち「表示した文章」（対面表示は履歴に残らない）
- 物理実機での QA（L-25。ストア提出の前）: 手順は `integration_test/device_test/` にあるが未実行。L-173・L-178（読み上げ用ラベル）の判断もこれを待つ
- dependabot の PR のマージ（L-87）: actions と backend の 10 本（#238〜#247）。frontend の 5 本（#60・#62〜#65）は本公開の後

## iOS の後（Android）
Android のアップロード鍵（L-52）、Play Console のプライバシーポリシー URL（L-146）、クローズドテスト（12 人以上 × 14 日）と production access の申請（L-145）。いずれも開発者登録（L-84）の後で、人が動かす。

## 最短経路に無いもの
台帳 `docs/ledger.md` の予定（L-57 など）は、最短経路に入れるまで着手しない。
