# TASK-0047: 緊急音・画面赤表示実装 - テストケース定義書

## 概要

緊急ボタンの2段階確認（TASK-0046）で「はい」をタップした後に実行される緊急処理のテストケース。緊急音の再生、画面全体の赤表示、リセット機能、マナーモード対応、状態管理などを包括的にテストする。

**タスクID**: TASK-0047
**関連要件**: REQ-303, REQ-304, EDGE-203
**テスト対象コンポーネント**:
- `EmergencyAlertScreen` - 緊急画面（赤背景オーバーレイ）
- `EmergencyAudioService` - 緊急音再生サービス
- `EmergencyStateNotifier` - 緊急状態管理（Riverpod）

## テストカテゴリ

1. [緊急音再生テスト（audioplayers連携）](#1-緊急音再生テストaudioplayers連携)
2. [緊急画面赤表示テスト](#2-緊急画面赤表示テスト)
3. [リセットボタン機能テスト](#3-リセットボタン機能テスト)
4. [マナーモード対応テスト](#4-マナーモード対応テスト)
5. [状態管理テスト（Riverpod）](#5-状態管理テストriverpod)
6. [パフォーマンステスト](#6-パフォーマンステスト)
7. [アクセシビリティテスト](#7-アクセシビリティテスト)
8. [既存コンポーネント連携テスト](#8-既存コンポーネント連携テスト)
9. [エッジケーステスト](#9-エッジケーステスト)
10. [統合テスト](#10-統合テスト)

---

## 1. 緊急音再生テスト（audioplayers連携）

### 1.1 基本再生テスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-001 | 緊急音が再生される | EmergencyAudioServiceがインスタンス化されている | `startEmergencySound()`を呼び出す | AudioPlayerの`play()`が呼び出され、緊急音が再生される | P0 |
| TC-047-002 | 緊急音がループ再生される | EmergencyAudioServiceがインスタンス化されている | `startEmergencySound()`を呼び出す | AudioPlayerの`setReleaseMode(ReleaseMode.loop)`が設定される | P0 |
| TC-047-003 | 緊急音が最大音量で再生される | EmergencyAudioServiceがインスタンス化されている | `startEmergencySound()`を呼び出す | AudioPlayerの`setVolume(1.0)`が呼び出される | P0 |
| TC-047-004 | 緊急音ファイルがアセットから読み込まれる | 緊急音ファイルがassets/audio/に存在 | `startEmergencySound()`を呼び出す | `AssetSource('audio/emergency_alarm.mp3')`が使用される | P0 |
| TC-047-005 | 緊急音が停止できる | 緊急音が再生中 | `stopEmergencySound()`を呼び出す | AudioPlayerの`stop()`が呼び出され、再生が停止する | P0 |

### 1.2 AudioPlayerモック検証テスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-006 | AudioPlayerがモック化できる | MockAudioPlayerを準備 | EmergencyAudioServiceにモックを注入 | モックのメソッドが呼び出される | P0 |
| TC-047-007 | 再生開始時にAudioPlayerが正しく初期化される | モックAudioPlayer使用 | `startEmergencySound()`を呼び出す | `setReleaseMode` → `setVolume` → `play`の順で呼び出される | P1 |
| TC-047-008 | 停止時にAudioPlayerのstopが呼ばれる | モックAudioPlayer使用、再生中 | `stopEmergencySound()`を呼び出す | モックの`stop()`が1回呼び出される | P0 |
| TC-047-009 | リソース解放時にAudioPlayerがdisposeされる | モックAudioPlayer使用 | `dispose()`を呼び出す | モックの`dispose()`が1回呼び出される | P1 |

### 1.3 エラーハンドリングテスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-010 | 音声ファイル読み込み失敗時に例外をキャッチ | モックがplay時に例外をスロー | `startEmergencySound()`を呼び出す | 例外がキャッチされ、エラーログが記録される | P1 |
| TC-047-011 | 音声ファイル読み込み失敗時にコールバックが呼ばれる | エラーコールバックを設定 | 音声ファイル読み込みが失敗 | `onError`コールバックが呼び出される | P2 |
| TC-047-012 | 再生中に停止失敗しても例外をスロー | モックがstop時に例外をスロー | `stopEmergencySound()`を呼び出す | 例外がキャッチされ、適切に処理される | P2 |

---

## 2. 緊急画面赤表示テスト

### 2.1 基本表示テスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-013 | 緊急画面が表示される | EmergencyAlertScreenを配置 | ウィジェットをレンダリング | EmergencyAlertScreenがウィジェットツリーに存在 | P0 |
| TC-047-014 | 画面全体が赤色で表示される | EmergencyAlertScreenを配置 | ウィジェットをレンダリング | Material/Containerの背景色がColors.redまたはAppColors.emergencyである | P0 |
| TC-047-015 | 緊急メッセージ「緊急呼び出し中」が表示される | EmergencyAlertScreenを配置 | ウィジェットをレンダリング | 「緊急呼び出し中」テキストが存在 | P0 |
| TC-047-016 | 警告アイコン（warning）が表示される | EmergencyAlertScreenを配置 | ウィジェットをレンダリング | Icons.warningまたはIcons.emergency_shareが存在 | P0 |
| TC-047-017 | 警告アイコンが白色で表示される | EmergencyAlertScreenを配置 | ウィジェットをレンダリング | Iconのcolorがwhiteである | P0 |
| TC-047-018 | 警告アイコンが大きく表示される（80px以上） | EmergencyAlertScreenを配置 | ウィジェットをレンダリング | Iconのsizeが80以上である | P1 |

### 2.2 オーバーレイ表示テスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-019 | 緊急画面が画面全体を覆う | EmergencyAlertScreenをスタックで配置 | ウィジェットをレンダリング | SizedBox.expand()またはPositioned.fillで全画面表示 | P0 |
| TC-047-020 | 緊急画面がSafeAreaを使用している | EmergencyAlertScreenを配置 | ウィジェットをレンダリング | SafeAreaウィジェットが存在 | P1 |
| TC-047-021 | 緊急画面がリセットボタンを含む | EmergencyAlertScreenを配置 | ウィジェットをレンダリング | 「リセット」テキストを含むボタンが存在 | P0 |

### 2.3 テーマ対応テスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-022 | 緊急画面の赤色が全テーマで統一 | lightThemeを適用 | ウィジェットをレンダリング | 背景色が#FF0000または統一された緊急色 | P1 |
| TC-047-023 | ダークモードでも赤色が維持される | darkThemeを適用 | ウィジェットをレンダリング | 背景色が変わらず赤色 | P1 |
| TC-047-024 | 高コントラストモードでも赤色が維持される | highContrastThemeを適用 | ウィジェットをレンダリング | 背景色が変わらず赤色 | P1 |

---

## 3. リセットボタン機能テスト

### 3.1 基本表示テスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-025 | リセットボタンが表示される | EmergencyAlertScreenを配置 | ウィジェットをレンダリング | 「リセット」テキストを含むボタンが存在 | P0 |
| TC-047-026 | リセットボタンが白背景で表示される | EmergencyAlertScreenを配置 | ウィジェットをレンダリング | ElevatedButtonの背景色がwhite | P0 |
| TC-047-027 | リセットボタンが黒文字で表示される | EmergencyAlertScreenを配置 | ウィジェットをレンダリング | ElevatedButtonの前景色がblack | P0 |
| TC-047-028 | リセットボタンの最小幅が80px以上 | EmergencyAlertScreenを配置 | ウィジェットをレンダリング | ボタン幅が80px以上 | P1 |
| TC-047-029 | リセットボタンの推奨サイズが120x56px | EmergencyAlertScreenを配置 | ウィジェットをレンダリング | minimumSizeが120x56以上 | P2 |

### 3.2 タップインタラクションテスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-030 | リセットボタンタップでonResetが呼ばれる | EmergencyAlertScreenにonResetコールバックを設定 | リセットボタンをタップ | onResetコールバックが1回呼び出される | P0 |
| TC-047-031 | リセットボタンタップで視覚的フィードバックが発生 | EmergencyAlertScreenを配置 | リセットボタンをタップ | InkWell/リップルエフェクトが発生 | P1 |
| TC-047-032 | リセットボタンがタップ操作のみで完結 | EmergencyAlertScreenを配置 | スワイプ/ロングプレスを試行 | タップのみで機能、他ジェスチャーは不要 | P0 |

---

## 4. マナーモード対応テスト

### 4.1 マナーモード検知テスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-033 | マナーモード状態を検知できる | volume_controllerまたは同等機能を使用 | マナーモード状態をチェック | マナーモードがtrue/falseで返される | P1 |
| TC-047-034 | マナーモード時に警告メッセージが表示される | マナーモードがON | 緊急呼び出しを実行 | 「マナーモードのため音が鳴りません」メッセージが表示 | P1 |
| TC-047-035 | マナーモード警告が緊急画面内に表示される | マナーモードがON | 緊急呼び出しを実行 | 警告がEmergencyAlertScreen内に統合表示 | P1 |

### 4.2 音量ゼロ対応テスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-036 | 音量ゼロ状態を検知できる | volume_controllerまたは同等機能を使用 | 音量状態をチェック | 音量が0.0で返される | P1 |
| TC-047-037 | 音量ゼロ時に警告メッセージが表示される | 端末音量が0 | 緊急呼び出しを実行 | 「音量が0です」メッセージが表示 | P1 |
| TC-047-038 | 警告メッセージが視覚的に目立つ | マナーモードまたは音量ゼロ | 緊急呼び出しを実行 | 警告が黄色背景または明確なスタイルで表示 | P2 |

### 4.3 モック対応テスト（volume_controller）

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-039 | VolumeControllerがモック化できる | MockVolumeControllerを準備 | モックを注入 | モックの戻り値が使用される | P1 |
| TC-047-040 | モックでマナーモードONを再現 | モックがミュート状態を返す | 緊急呼び出しを実行 | 警告メッセージが表示される | P1 |
| TC-047-041 | モックで音量ゼロを再現 | モックが音量0.0を返す | 緊急呼び出しを実行 | 「音量が0です」が表示される | P1 |

---

## 5. 状態管理テスト（Riverpod）

### 5.1 EmergencyStateNotifier基本テスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-042 | 初期状態がnormalである | EmergencyStateNotifierを生成 | stateを取得 | state == EmergencyStateEnum.normal | P0 |
| TC-047-043 | startEmergencyで状態がalertActiveになる | 初期状態がnormal | `startEmergency()`を呼び出す | state == EmergencyStateEnum.alertActive | P0 |
| TC-047-044 | resetEmergencyで状態がnormalに戻る | 状態がalertActive | `resetEmergency()`を呼び出す | state == EmergencyStateEnum.normal | P0 |
| TC-047-045 | startEmergencyで緊急音が再生される | 初期状態がnormal、モックAudioService使用 | `startEmergency()`を呼び出す | AudioServiceの`startEmergencySound()`が呼ばれる | P0 |
| TC-047-046 | resetEmergencyで緊急音が停止される | 状態がalertActive、モックAudioService使用 | `resetEmergency()`を呼び出す | AudioServiceの`stopEmergencySound()`が呼ばれる | P0 |

### 5.2 Riverpod連携テスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-047 | Providerから状態を取得できる | ProviderContainerを作成 | emergencyStateProviderを読み取る | 初期状態normalが取得できる | P0 |
| TC-047-048 | 状態変更がUIに反映される | ConsumerWidgetを使用 | 状態をalertActiveに変更 | ウィジェットが再ビルドされる | P0 |
| TC-047-049 | refを使用して状態を変更できる | ProviderContainerを作成 | notifier.startEmergency()を呼び出す | 状態がalertActiveに変更される | P0 |

### 5.3 状態遷移テスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-050 | normal → alertActive遷移が正常 | 状態がnormal | startEmergency()を呼び出す | 状態がalertActiveに遷移 | P0 |
| TC-047-051 | alertActive → normal遷移が正常 | 状態がalertActive | resetEmergency()を呼び出す | 状態がnormalに遷移 | P0 |
| TC-047-052 | 既にalertActiveの時にstartEmergencyしても問題ない | 状態がalertActive | startEmergency()を再度呼び出す | 状態がalertActiveのまま維持、エラーなし | P1 |
| TC-047-053 | 既にnormalの時にresetEmergencyしても問題ない | 状態がnormal | resetEmergency()を呼び出す | 状態がnormalのまま維持、エラーなし | P1 |

---

## 6. パフォーマンステスト

### 6.1 応答時間テスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-054 | 緊急音再生開始まで500ms以内 | EmergencyAudioServiceを準備 | startEmergencySound()を呼び出し、完了を計測 | 完了までの時間が500ms以内 | P0 |
| TC-047-055 | 赤画面表示まで300ms以内 | EmergencyStateNotifierを準備 | startEmergency()を呼び出し、UI更新を計測 | UIが300ms以内に更新される | P0 |
| TC-047-056 | リセットから音停止・画面復帰まで300ms以内 | alertActive状態 | resetEmergency()を呼び出し、完了を計測 | 完了までの時間が300ms以内 | P0 |
| TC-047-057 | 緊急音ループ間隔が100ms以下 | 緊急音が再生中 | ループ再生のギャップを計測 | ギャップ（無音部分）が100ms以下 | P1 |

### 6.2 メモリ・リソーステスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-058 | AudioPlayerがdisposeされる | 緊急呼び出し→リセット完了 | dispose()を呼び出す | リソースが解放される | P1 |
| TC-047-059 | 複数回の開始・停止でメモリリークなし | テスト環境 | startEmergency/resetEmergencyを10回繰り返す | メモリ使用量が大幅に増加しない | P2 |

---

## 7. アクセシビリティテスト

### 7.1 Semanticsテスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-060 | 緊急画面にSemantics「緊急呼び出し中」が設定 | EmergencyAlertScreenを配置 | Semanticsを取得 | label/hintに「緊急呼び出し中」が含まれる | P0 |
| TC-047-061 | リセットボタンにSemantics「緊急呼び出しを解除」が設定 | EmergencyAlertScreenを配置 | リセットボタンのSemanticsを取得 | labelに「緊急呼び出しを解除」または「リセット」が含まれる | P0 |
| TC-047-062 | 警告メッセージにSemantics情報が設定 | マナーモード警告が表示 | 警告メッセージのSemanticsを取得 | 警告内容がスクリーンリーダーで読み上げられる | P1 |

### 7.2 タップターゲットテスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-063 | リセットボタンが44x44px以上 | EmergencyAlertScreenを配置 | リセットボタンのサイズを取得 | width >= 44px, height >= 44px | P0 |
| TC-047-064 | リセットボタンが推奨サイズ80x48px以上 | EmergencyAlertScreenを配置 | リセットボタンのサイズを取得 | width >= 80px, height >= 48px | P1 |

### 7.3 マルチモーダル対応テスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-065 | 視覚的警告（赤画面）が提供される | 緊急呼び出しを実行 | 画面を確認 | 赤い背景が表示される | P0 |
| TC-047-066 | 聴覚的警告（緊急音）が提供される | 緊急呼び出しを実行 | 音声を確認（モック検証） | AudioPlayerのplay()が呼ばれる | P0 |

---

## 8. 既存コンポーネント連携テスト

### 8.1 EmergencyButtonWithConfirmation連携テスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-067 | 確認ダイアログで「はい」タップ後に緊急処理が開始される | EmergencyButtonWithConfirmationを配置 | ボタンタップ→「はい」タップ | EmergencyStateNotifier.startEmergency()が呼ばれる | P0 |
| TC-047-068 | onEmergencyConfirmedコールバックから緊急処理を呼び出せる | EmergencyButtonWithConfirmationにコールバック設定 | 「はい」タップ | コールバック内でstartEmergency()が実行される | P0 |

### 8.2 EmergencyState連携テスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-069 | EmergencyStateEnumが正しく使用される | interfaces.dartをインポート | EmergencyStateEnum.alertActiveを使用 | 正常に動作する | P0 |
| TC-047-070 | 状態がalertActiveの時に緊急画面が表示される | ConsumerWidgetで状態監視 | 状態をalertActiveに変更 | EmergencyAlertScreenが表示される | P0 |
| TC-047-071 | 状態がnormalの時に緊急画面が非表示 | ConsumerWidgetで状態監視 | 状態をnormalに変更 | EmergencyAlertScreenが非表示になる | P0 |

---

## 9. エッジケーステスト

### 9.1 連続タップ・重複処理防止テスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-072 | リセットボタン連続タップで1回だけ処理される | 緊急画面表示中 | リセットボタンを5回連続タップ | onResetコールバックが1回だけ呼ばれる | P0 |
| TC-047-073 | startEmergency連続呼び出しで音が重複しない | 状態がnormal | startEmergency()を3回連続呼び出す | AudioPlayerのplay()が1回だけ呼ばれる | P1 |
| TC-047-074 | resetEmergency連続呼び出しでエラーなし | 状態がalertActive | resetEmergency()を3回連続呼び出す | エラーが発生しない、stop()は1回のみ | P1 |

### 9.2 アプリライフサイクルテスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-075 | 緊急状態がアプリ再起動で永続化されない | 緊急状態でアプリ終了 | アプリを再起動 | 状態がnormalから開始 | P1 |
| TC-047-076 | バックグラウンド復帰で緊急状態が維持される | 緊急状態でバックグラウンド化 | アプリをフォアグラウンドに戻す | 状態がalertActiveのまま維持 | P1 |
| TC-047-077 | バックグラウンドで緊急音が継続される（可能な範囲で） | 緊急音再生中 | アプリをバックグラウンド化 | 音声再生が継続される（プラットフォーム依存） | P2 |

### 9.3 画面回転テスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-078 | 画面回転で緊急状態が維持される | 緊急画面表示中 | デバイスを回転 | 緊急画面が維持される | P1 |
| TC-047-079 | 画面回転でレイアウトが適切に調整される | 緊急画面表示中 | デバイスを回転 | レイアウトが縦・横両方で正しく表示 | P2 |
| TC-047-080 | 画面回転で緊急音が継続される | 緊急音再生中 | デバイスを回転 | 音声が途切れずに継続 | P1 |

### 9.4 エラーケーステスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-081 | 緊急音ファイル読み込み失敗時に赤画面は表示される | 音声ファイルが存在しない | startEmergency()を呼び出す | エラーが発生しても赤画面は表示される | P0 |
| TC-047-082 | 緊急音ファイル読み込み失敗時にエラーログが記録される | 音声ファイルが存在しない | startEmergency()を呼び出す | エラーがログに記録される | P1 |
| TC-047-083 | 緊急音ファイル読み込み失敗時に警告メッセージが表示される | 音声ファイルが存在しない | startEmergency()を呼び出す | 「音が再生できません」等の警告が表示される | P2 |

### 9.5 他アプリ割り込みテスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-084 | 電話着信時に緊急音が一時停止される | 緊急音再生中 | 電話着信が発生 | AudioPlayerのイベントが発火 | P2 |
| TC-047-085 | 電話終了後に緊急音が再開される | 電話着信で一時停止中 | 電話を終了 | 緊急音が自動再開される（可能な範囲で） | P2 |

---

## 10. 統合テスト

### 10.1 フル緊急呼び出しフローテスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-086 | 緊急音再生と画面赤表示が同時に開始される | EmergencyButtonWithConfirmationを配置 | ボタンタップ→「はい」タップ | 音と画面が同時に開始（300ms以内の差） | P0 |
| TC-047-087 | リセットで音停止と画面解除が同時に行われる | 緊急状態 | リセットボタンをタップ | 音が停止し、画面が解除される | P0 |
| TC-047-088 | 2段階確認→緊急処理→リセットの一連フローが正常動作 | 初期状態 | 緊急ボタン→「はい」→リセット | 全フローが正常に完了 | P0 |

### 10.2 UI統合テスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-089 | 緊急画面がオーバーレイとして表示される | メイン画面表示中 | 緊急呼び出しを実行 | 緊急画面が既存画面の上にオーバーレイ表示 | P0 |
| TC-047-090 | リセット後に元の画面に戻る | 緊急画面表示中 | リセットボタンをタップ | 緊急画面が消え、元の画面が表示 | P0 |
| TC-047-091 | 緊急画面表示中も緊急ボタンは非表示（重複防止） | 緊急画面表示中 | 緊急ボタンを探す | 緊急ボタンは非表示またはオーバーレイで隠れている | P1 |

### 10.3 状態整合性テスト

| テストケースID | テスト名 | 前提条件 | 操作 | 期待結果 | 優先度 |
|---|---|---|---|---|---|
| TC-047-092 | 状態とUIが常に同期している | ProviderContainerを準備 | 状態を変更しながらUIを確認 | 状態変更が即座にUIに反映 | P0 |
| TC-047-093 | 状態とAudioServiceが常に同期している | ProviderContainerを準備 | 状態を変更しながらAudioを確認 | alertActiveで再生、normalで停止 | P0 |
| TC-047-094 | エラー発生後も状態が一貫している | AudioServiceがエラーをスロー | startEmergency()を呼び出す | 状態がalertActiveになり、UIは表示される | P1 |

---

## テストケースサマリー

| カテゴリ | P0 | P1 | P2 | 合計 |
|---|---|---|---|---|
| 1. 緊急音再生テスト | 6 | 3 | 3 | 12 |
| 2. 緊急画面赤表示テスト | 6 | 6 | 0 | 12 |
| 3. リセットボタン機能テスト | 4 | 3 | 1 | 8 |
| 4. マナーモード対応テスト | 0 | 7 | 2 | 9 |
| 5. 状態管理テスト（Riverpod） | 8 | 4 | 0 | 12 |
| 6. パフォーマンステスト | 3 | 2 | 1 | 6 |
| 7. アクセシビリティテスト | 4 | 3 | 0 | 7 |
| 8. 既存コンポーネント連携テスト | 5 | 0 | 0 | 5 |
| 9. エッジケーステスト | 2 | 9 | 3 | 14 |
| 10. 統合テスト | 6 | 3 | 0 | 9 |
| **合計** | **44** | **40** | **10** | **94** |

---

## 実機テストが必要なケース

以下のテストケースは、シミュレーター/エミュレーターでは完全に検証できないため、実機テストが必要:

| テストケースID | 理由 |
|---|---|
| TC-047-033〜041 | マナーモード・音量検知はOSの実機依存 |
| TC-047-057 | 実際の音声ループギャップ計測は実機が必要 |
| TC-047-077 | バックグラウンド音声再生はプラットフォーム実機依存 |
| TC-047-084〜085 | 電話着信割り込みは実機でのみテスト可能 |

---

## モック戦略

### audioplayers モック

```dart
class MockAudioPlayer extends Mock implements AudioPlayer {}

// 使用例
final mockPlayer = MockAudioPlayer();
when(mockPlayer.play(any)).thenAnswer((_) async => {});
when(mockPlayer.stop()).thenAnswer((_) async => {});
when(mockPlayer.setVolume(any)).thenAnswer((_) async => {});
when(mockPlayer.setReleaseMode(any)).thenAnswer((_) async => {});
```

### volume_controller モック

```dart
class MockVolumeController extends Mock implements VolumeController {}

// 使用例
final mockVolumeController = MockVolumeController();
when(mockVolumeController.getVolume()).thenAnswer((_) async => 0.0);
```

### EmergencyAudioService モック

```dart
class MockEmergencyAudioService extends Mock implements EmergencyAudioService {}

// 使用例
final mockService = MockEmergencyAudioService();
when(mockService.startEmergencySound()).thenAnswer((_) async => {});
when(mockService.stopEmergencySound()).thenAnswer((_) async => {});
```

---

## 備考

- **信頼性レベル凡例**:
  - P0（必須）: 基本機能に関わる最重要テスト
  - P1（高優先度）: 品質保証に重要なテスト
  - P2（中優先度）: あれば望ましいテスト

- audioplayersパッケージのバージョンにより、モック方法が異なる場合がある。実装時に最新のドキュメントを参照

- マナーモード検知・音量制御の実装はOSにより制限がある。Flutterでの実現可能性を事前調査

- 緊急音ファイル（emergency_alarm.mp3）は著作権フリーまたは自作の音源を使用

---

**ドキュメント作成日**: 2025-11-24
**タスクID**: TASK-0047
**関連要件**: REQ-303, REQ-304, EDGE-203
