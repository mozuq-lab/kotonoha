# TASK-0084: 大ボタン・緊急ボタンE2Eテスト - 要件定義書

## タスク情報

- **タスクID**: TASK-0084
- **タスクタイプ**: TDD (E2Eテスト)
- **推定工数**: 8時間
- **完了日**: 2025-11-29

## 概要

大ボタン（クイック応答）、状態ボタン、緊急ボタン機能のE2Eテストを実装する。発話困難な方が最も頻繁に使用する機能であり、高い信頼性とパフォーマンスが求められる。

## 関連要件

### 大ボタン（クイック応答）

| 要件ID | 要件名 | 概要 |
|--------|--------|------|
| REQ-201 | クイック応答ボタン | 「はい」「いいえ」「わからない」の3つを常時表示 |
| REQ-202 | 状態ボタン | 痛い、トイレ、暑い、寒い、水、眠い、助けて、待っての8個を必須表示 |
| REQ-203 | 状態ボタン数 | 8-12個の範囲で表示 |
| REQ-204 | 即座読み上げ | ボタンタップで即座にTTS読み上げを開始 |

### 緊急ボタン

| 要件ID | 要件名 | 概要 |
|--------|--------|------|
| REQ-301 | 緊急ボタン常時表示 | すべての画面で常時表示 |
| REQ-302 | 2段階確認 | 誤操作防止のため確認ダイアログを表示 |
| REQ-303 | 緊急音再生 | 確認後に緊急音を再生 |
| REQ-304 | 緊急画面表示 | 赤い全画面の緊急画面に切り替え |

### 非機能要件

| 要件ID | 要件名 | 概要 |
|--------|--------|------|
| NFR-001 | TTS読み上げ開始 | 1秒以内に読み上げを開始 |
| REQ-5002 | 誤操作防止 | 重要操作には確認ダイアログを表示 |
| NFR-301 | 安定性 | アプリがクラッシュせず安定動作 |

## 機能要件詳細（EARS記法）

### FR-001: クイック応答ボタン表示

```
WHEN the application starts,
THE SYSTEM SHALL display three quick response buttons labeled "はい", "いいえ", and "わからない" at the top of the screen.
```

### FR-002: クイック応答ボタン読み上げ

```
WHEN the user taps a quick response button,
THE SYSTEM SHALL start TTS playback of the button label within 1 second.
```

### FR-003: 状態ボタン表示

```
WHEN the application starts,
THE SYSTEM SHALL display at least 8 state buttons: "痛い", "トイレ", "暑い", "寒い", "水", "眠い", "助けて", "待って".
```

### FR-004: 状態ボタン読み上げ

```
WHEN the user taps a state button,
THE SYSTEM SHALL start TTS playback of the button label within 1 second.
```

### FR-005: デバウンス機能

```
WHEN the user taps a button multiple times within 300ms,
THE SYSTEM SHALL process only the first tap to prevent accidental repeated playback.
```

### FR-006: 緊急ボタン表示

```
FOR ALL screens,
THE SYSTEM SHALL display the emergency button (notifications_active icon) at all times.
```

### FR-007: 緊急確認ダイアログ

```
WHEN the user taps the emergency button,
THE SYSTEM SHALL display a confirmation dialog with the message "緊急呼び出しを実行しますか？" and "はい"/"いいえ" options.
```

### FR-008: 緊急処理実行

```
WHEN the user selects "はい" in the confirmation dialog,
THE SYSTEM SHALL display a red full-screen emergency alert with "緊急呼び出し中" message and a "リセット" button.
```

### FR-009: 緊急処理キャンセル

```
WHEN the user selects "いいえ" in the confirmation dialog,
THE SYSTEM SHALL close the dialog and return to the normal screen without triggering the emergency alert.
```

### FR-010: 緊急状態リセット

```
WHEN the user taps the "リセット" button on the emergency screen,
THE SYSTEM SHALL dismiss the emergency alert and return to the home screen.
```

### FR-011: ダイアログ誤操作防止

```
WHEN the confirmation dialog is displayed,
THE SYSTEM SHALL NOT close the dialog when the user taps outside the dialog area (barrierDismissible: false).
```

## エッジケース

| ID | ケース | 期待動作 |
|----|--------|----------|
| EDGE-001 | 入力欄が空の状態で大ボタンタップ | 正常にTTS読み上げ開始（クラッシュしない） |
| EDGE-002 | 連続タップ（300ms以内） | デバウンスにより1回のみ処理 |
| EDGE-003 | 緊急ダイアログ外タップ | ダイアログが閉じない |

## 受け入れ基準

### AC-001: クイック応答ボタン

- [ ] 「はい」「いいえ」「わからない」の3つのボタンが表示される
- [ ] 各ボタンタップでTTS読み上げが開始される
- [ ] 停止ボタンが表示される

### AC-002: 状態ボタン

- [ ] 必須の8個のボタンが表示される
- [ ] 各ボタンタップでTTS読み上げが開始される
- [ ] 全ボタンで一貫した動作

### AC-003: 緊急ボタン

- [ ] 緊急ボタン（通知アイコン）が表示される
- [ ] タップで確認ダイアログが表示される
- [ ] 「はい」で緊急画面に遷移
- [ ] 「いいえ」でキャンセル
- [ ] リセットで通常画面に復帰

### AC-004: パフォーマンス

- [ ] ボタンタップから読み上げ開始まで1秒以内

### AC-005: 安全性

- [ ] 確認ダイアログは外タップで閉じない
- [ ] 空の入力状態でもクラッシュしない

## 信頼性レベル

🔵 青信号 - REQ-201〜REQ-204、REQ-301〜REQ-304、NFR-001に基づく明確な要件定義
