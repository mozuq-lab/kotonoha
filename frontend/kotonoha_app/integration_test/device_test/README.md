# 実機テスト（Device Test）

TASK-0095: 実機テスト（iOS/Android/タブレット）。台帳 L-25。

## 概要

このディレクトリには、iOS/Android実機での動作確認用のE2Eテストが含まれています。
2026-10-17 に iPad シミュレータ（iPad (A16)、iOS 26.5）で 4 ファイルとも通ることを確認済みです
（実機ではまだ走らせていません）。

## テストファイル

| ファイル名 | テスト内容 | テストケースID |
|-----------|----------|--------------|
| `device_basic_test.dart` | 基本動作テスト | RT-001〜RT-007、RT-009・RT-010、RT-012〜RT-016 |
| `orientation_test.dart` | 画面方向対応テスト | RT-101〜RT-103（＋回転時のレイアウト・定型文の 3 件） |
| `tablet_layout_test.dart` | タブレット表示テスト | RT-104〜RT-107（＋文字盤・定型文・大ボタン配置の 3 件） |
| `tts_device_test.dart` | TTS実機動作テスト | RT-201〜RT-206、RT-301、RT-303〜RT-307 |

## 実行方法

### 前提条件

1. iOS/Android実機がUSB接続されている
2. デバイスが開発者モードになっている
3. コマンドは `frontend/kotonoha_app` で実行する（別の場所で `flutter test` を実行すると、端末ではなく Mac の上で走る）

### 接続されているデバイスの確認

```bash
fvm flutter devices
```

### すべてのデバイステストを実行

```bash
fvm flutter test integration_test/device_test/ -d <DEVICE_ID>
```

Android では `--flavor production` も付けます（付けないと「Gradle build failed to produce an .apk file」で止まります）。

4 ファイルを 1 つずつ順に走らせ、失敗したファイルの数を最後に出すスクリプトもあります（Android なら flavor を自動で付けます）。

```bash
scripts/run_device_tests.sh -d <DEVICE_ID> -a
```

### 個別のテストファイルを実行

```bash
# 基本動作テスト
fvm flutter test integration_test/device_test/device_basic_test.dart -d <DEVICE_ID>

# 画面方向対応テスト（RT-101〜RT-103）
fvm flutter test integration_test/device_test/orientation_test.dart -d <DEVICE_ID>

# タブレット表示テスト（RT-104〜RT-107）
fvm flutter test integration_test/device_test/tablet_layout_test.dart -d <DEVICE_ID>

# TTS実機動作テスト（RT-201〜RT-206、RT-301〜RT-307。約 4 分）
fvm flutter test integration_test/device_test/tts_device_test.dart -d <DEVICE_ID>
```

### iOS実機での実行例

```bash
fvm flutter devices
# 出力例:
# iPad (mobile) • 00008110-XXXXXXXXXXXX • ios • iOS 18.0

fvm flutter test integration_test/device_test/device_basic_test.dart -d 00008110-XXXXXXXXXXXX
```

### Android実機での実行例

```bash
fvm flutter devices
# 出力例:
# Pixel 5 (mobile) • ABCD1234EFGH5678 • android-arm64 • Android 13 (API 33)

fvm flutter test integration_test/device_test/device_basic_test.dart -d ABCD1234EFGH5678 --flavor production
```

## テストケース一覧

### 基本動作テストケース

- RT-001: アプリ起動
- RT-002: 文字盤タップ入力（100ms以内）
- RT-003: TTS読み上げ（1秒以内）
- RT-004: TTS速度変更
- RT-005: TTS停止
- RT-006: 定型文選択
- RT-007: 大ボタンタップ
- RT-009: 履歴保存・再生
- RT-010: お気に入り登録
- RT-012: オフライン動作
- RT-013: フォントサイズ変更
- RT-014: テーマ変更
- RT-015: 高コントラストモード
- RT-016: 対面表示モード

### 画面方向対応テストケース（RT-101〜RT-103）

- RT-101: 縦向き表示
- RT-102: 横向き表示
- RT-103: 画面回転時の状態保持

テストでは端末を回さず、描画する面の大きさ（`setSurfaceSize`）を縦長・横長に変えて確かめます。
`MediaQuery` の大きさは端末のままなので、実機を物理的に回したときの見え方は手動で確認します。

### タブレット表示テストケース（RT-104〜RT-107）

- RT-104: タブレット表示（9.7インチ以上）
- RT-105: スマートフォン表示
- RT-106: タップターゲットサイズ（44px × 44px以上）
- RT-107: 大ボタンサイズ（60px × 60px以上推奨）

### TTS実機動作テストケース（RT-201〜RT-206）

**iOS固有**（iOS だけで走り、Android ではスキップ）:
- RT-201: iOS TTS（AVSpeechSynthesizer）
- RT-202: iOS SafeArea対応
- RT-203: iOSガイド付きアクセス

**Android固有**（Android だけで走り、iOS ではスキップ）:
- RT-204: Android TTS（TextToSpeech）
- RT-205: Android Navigation Bar対応
- RT-206: Android画面ピン留め

### エッジケーステストケース

- RT-301: OS音量0での読み上げ
- RT-303: TTS音声エンジン未インストール
- RT-304: バックグラウンド復帰
- RT-305: 長文読み上げ（500文字以上）
- RT-306: 連続読み上げ（10回）
- RT-307: ストレージ容量不足（テストで確かめるのは履歴の 50 件上限）

## スクリーンショット

テストは `takeScreenshot` を呼びますが、`flutter test` で走らせたときは画像はどこにも保存されません
（iOS は撮れるが受け取る先が無い。Android は先に `convertFlutterSurfaceToImage` を呼ばないと
撮れない——integration_test のソースから読んだことで、実測はしていない）。撮れなくてもテストは止まりません。
画像を残したいときは、1 ファイルずつ `flutter drive` で走らせます。画像は `build/screenshots/` に書かれます
（2026-10-17 に iPad シミュレータで `orientation_test.dart` の 13 枚が保存されることを確認）。

```bash
fvm flutter drive -d <DEVICE_ID> \
  --driver=test_driver/screenshot_driver.dart \
  --target=integration_test/device_test/device_basic_test.dart
```

## 注意事項

### プラットフォーム固有テスト

- iOS固有テスト（RT-201〜RT-203）は iOS でのみ実行され、Android ではスキップされます
- Android固有テスト（RT-204〜RT-206）は Android でのみ実行され、iOS ではスキップされます

### 手動確認が必要なテスト

テストが確かめるのは、画面の操作が通ること・読み上げの状態が「読み上げ中」になること・
数値（時間・大きさ）までです。音が聞こえるか、端末の設定を変えたときの動きは人が見ます。
詳しい手順は各テストのコメント（`Note:`）にあります。

`device_basic_test.dart`:
- RT-002: ログの「文字盤タップ応答時間」は debug ビルドの参考値で、テストは閾値では落ちない。100ms を超えていたら、触って遅れを感じるかを見る
- RT-003・RT-006・RT-007・RT-009: 実際に音声が聞こえる（RT-005 は停止で音が止まる）
- RT-004: 読み上げの速さが実際に変わる
- RT-012: 機内モードにして、文字盤・読み上げ・定型文が動く
- RT-013〜RT-015: 文字が大きくなる・ダークテーマになる・高コントラストでコントラスト比 4.5:1 以上
- RT-016: 対面表示で相手側から文が読める

`orientation_test.dart`:
- RT-101・RT-102: 端末を物理的に縦・横に回して、文字盤・定型文の配置が崩れない
- 横向きのタブレットで定型文が見やすく並ぶ

`tablet_layout_test.dart`:
- RT-104: タブレットで定型文が多数表示される
- RT-105: スマートフォンでレイアウトが崩れず、主要ボタンが押せる
- 大ボタンの間の余白が適切で、誤タップしにくい

`tts_device_test.dart`:
- RT-201・RT-204: 日本語の声で、聞き取りやすく読み上げられる
- RT-202: ノッチ・ホームインジケーターと重ならない（iPhone 実機）
- RT-203: ガイド付きアクセス（設定変更が必要）で基本機能が動き、アプリから出られない
- RT-205: 3 ボタン／ジェスチャーナビゲーションで重ならない（Android 実機）
- RT-206: 画面ピン留め（設定変更が必要）で基本機能が動き、解除できる
- RT-301: OS 音量 0 で読み上げると「音量が0です」の帯が出る（音量調整が必要）
- iOS の消音スイッチをオンにしても読み上げが聞こえる（物理 iPad で確認。シミュレータでは再現できない）
- RT-303: 日本語の声を消すと、読み上げ失敗の帯が出てクラッシュしない（音声エンジンの削除が必要）
- RT-304: 実際にホームへ戻り、他のアプリを開いてから戻っても入力が残る（アプリ切り替えが必要）
- RT-305・RT-306: 500 文字・10 回続けて読み上げても途中で止まらず、クラッシュしない
- RT-307: ストレージ容量不足のときの警告（ストレージを満杯にする必要）

読み上げ用ラベル（VoiceOver／TalkBack をオンにして）:
- ボタン（「はい」・文字盤の文字・AppBar のボタン）が日本語の声で読まれる
- 音量 0 の帯（音量 0 で読み上げると出る）に触れると「警告: 音量が0です」と読まれ、右端の × は「閉じる、ボタン」と読まれる
- オフラインの帯（機内モードで出る）・読み上げ失敗の帯に触れると文言が読まれる（保存失敗の帯は実機では出せないので、Dart のテスト `app_shell_banner_semantics_test.dart` で見る）

## 受け入れ基準

### 必須項目

- [ ] iOS実機で上記の基本動作テストケースがすべて完了
- [ ] Android実機で上記の基本動作テストケースがすべて完了
- [ ] 画面方向対応テストケース（RT-101〜RT-103）がすべて完了
- [ ] タブレット表示テストケース（RT-104〜RT-107）がすべて完了
- [ ] TTS読み上げが1秒以内に開始される
- [ ] 文字盤タップが100ms以内に反応する
- [ ] タップターゲットサイズが44px × 44px以上

## 関連ドキュメント

- [旧テストケース定義書（履歴）](../../../../docs/archive/implements/kotonoha/TASK-0095/kotonoha-testcases.md)
- [旧要件定義書（履歴）](../../../../docs/archive/implements/kotonoha/TASK-0095/kotonoha-requirements.md)
- [Phase 5 タスク（歴史記録）](../../../../docs/archive/tasks/kotonoha-phase5.md)
