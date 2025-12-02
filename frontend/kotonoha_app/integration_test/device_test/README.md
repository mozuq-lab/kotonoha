# 実機テスト（Device Test）

TASK-0095: 実機テスト（iOS/Android/タブレット）

## 概要

このディレクトリには、iOS/Android実機での動作確認用のE2Eテストが含まれています。

## テストファイル

| ファイル名 | テスト内容 | テストケースID |
|-----------|----------|--------------|
| `device_basic_test.dart` | 基本動作テスト | RT-001〜RT-016 |
| `orientation_test.dart` | 画面方向対応テスト | RT-101〜RT-103 |
| `tablet_layout_test.dart` | タブレット表示テスト | RT-104〜RT-107 |
| `tts_device_test.dart` | TTS実機動作テスト | RT-201〜RT-206、RT-301〜RT-307 |

## 実行方法

### 前提条件

1. iOS/Android実機がUSB接続されている
2. デバイスが開発者モードになっている

### 接続されているデバイスの確認

```bash
flutter devices
```

### すべてのデバイステストを実行

```bash
# すべてのデバイステストを実行
flutter test integration_test/device_test/ -d <DEVICE_ID>
```

### 個別のテストファイルを実行

```bash
# 基本動作テスト（RT-001〜RT-016）
flutter test integration_test/device_test/device_basic_test.dart -d <DEVICE_ID>

# 画面方向対応テスト（RT-101〜RT-103）
flutter test integration_test/device_test/orientation_test.dart -d <DEVICE_ID>

# タブレット表示テスト（RT-104〜RT-107）
flutter test integration_test/device_test/tablet_layout_test.dart -d <DEVICE_ID>

# TTS実機動作テスト（RT-201〜RT-206、RT-301〜RT-307）
flutter test integration_test/device_test/tts_device_test.dart -d <DEVICE_ID>
```

### iOS実機での実行例

```bash
# 接続されているiOS実機を確認
flutter devices

# 出力例:
# iPhone 14 (mobile) • 00008110-XXXXXXXXXXXX • ios • iOS 16.0

# 基本動作テストを実行
flutter test integration_test/device_test/device_basic_test.dart -d 00008110-XXXXXXXXXXXX
```

### Android実機での実行例

```bash
# 接続されているAndroid実機を確認
flutter devices

# 出力例:
# Pixel 5 (mobile) • ABCD1234EFGH5678 • android-arm64 • Android 13 (API 33)

# 基本動作テストを実行
flutter test integration_test/device_test/device_basic_test.dart -d ABCD1234EFGH5678
```

## テストケース一覧

### 基本動作テストケース（RT-001〜RT-016）

- RT-001: アプリ起動
- RT-002: 文字盤タップ入力（100ms以内）
- RT-003: TTS読み上げ（1秒以内）
- RT-004: TTS速度変更
- RT-005: TTS停止
- RT-006: 定型文選択
- RT-007: 大ボタンタップ
- RT-008: 緊急ボタン
- RT-009: 履歴保存・再生
- RT-010: お気に入り登録
- RT-011: AI変換（3秒以内）
- RT-012: オフライン動作
- RT-013: フォントサイズ変更
- RT-014: テーマ変更
- RT-015: 高コントラストモード
- RT-016: 対面表示モード

### 画面方向対応テストケース（RT-101〜RT-103）

- RT-101: 縦向き表示
- RT-102: 横向き表示
- RT-103: 画面回転時の状態保持

### タブレット表示テストケース（RT-104〜RT-107）

- RT-104: タブレット表示（9.7インチ以上）
- RT-105: スマートフォン表示
- RT-106: タップターゲットサイズ（44px × 44px以上）
- RT-107: 大ボタンサイズ（60px × 60px以上推奨）

### TTS実機動作テストケース（RT-201〜RT-206）

**iOS固有**:
- RT-201: iOS TTS（AVSpeechSynthesizer）
- RT-202: iOS SafeArea対応
- RT-203: iOSガイド付きアクセス

**Android固有**:
- RT-204: Android TTS（TextToSpeech）
- RT-205: Android Navigation Bar対応
- RT-206: Android画面ピン留め

### エッジケーステストケース（RT-301〜RT-307）

- RT-301: OS音量0での読み上げ
- RT-302: マナーモード時の緊急ボタン
- RT-303: TTS音声エンジン未インストール
- RT-304: バックグラウンド復帰
- RT-305: 長文読み上げ（500文字以上）
- RT-306: 連続読み上げ（10回）
- RT-307: ストレージ容量不足

## スクリーンショット

テスト実行時にスクリーンショットが自動的に取得されます。

保存先: `build/app/outputs/integration_test_screenshots/`

## 注意事項

### プラットフォーム固有テスト

- iOS固有テスト（RT-201〜RT-203）はiOS実機でのみ実行可能
- Android固有テスト（RT-204〜RT-206）はAndroid実機でのみ実行可能
- 該当しないプラットフォームではテストがスキップされます

### 手動確認が必要なテスト

以下のテストは実機で手動確認が必要です:

- RT-201: iOS TTS（実機で音声確認）
- RT-203: iOSガイド付きアクセス（設定変更が必要）
- RT-204: Android TTS（実機で音声確認）
- RT-206: Android画面ピン留め（設定変更が必要）
- RT-301: OS音量0（音量調整が必要）
- RT-302: マナーモード（マナーモード設定が必要）
- RT-303: TTS音声エンジン未インストール（音声エンジン削除が必要）
- RT-304: バックグラウンド復帰（アプリ切り替えが必要）
- RT-307: ストレージ容量不足（ストレージを満杯にする必要）

## 受け入れ基準

詳細は `/docs/implements/kotonoha/TASK-0095/kotonoha-testcases.md` を参照してください。

### 必須項目

- [ ] iOS実機で基本動作テストケース（RT-001〜RT-016）がすべて完了
- [ ] Android実機で基本動作テストケース（RT-001〜RT-016）がすべて完了
- [ ] 画面方向対応テストケース（RT-101〜RT-103）がすべて完了
- [ ] タブレット表示テストケース（RT-104〜RT-107）がすべて完了
- [ ] TTS読み上げが1秒以内に開始される（NFR-001）
- [ ] 文字盤タップが100ms以内に反応する（NFR-003）
- [ ] タップターゲットサイズが44px × 44px以上（REQ-5001）

## 関連ドキュメント

- [テストケース定義書](../../../../docs/implements/kotonoha/TASK-0095/kotonoha-testcases.md)
- [要件定義書](../../../../docs/implements/kotonoha/TASK-0095/kotonoha-requirements.md)
- [Phase 5 タスク](../../../../docs/tasks/kotonoha-phase5.md)
