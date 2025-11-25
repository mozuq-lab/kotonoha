# TASK-0049: TTS速度設定 - 要件定義書

## TDD要件定義・機能仕様

**タスクID**: TASK-0049
**タスク名**: TTS速度設定（遅い/普通/速い）
**要件名**: kotonoha
**関連要件**: REQ-404
**依存タスク**: TASK-0048 (OS標準TTS連携 - 完了)
**作成日**: 2025-11-25

---

## 1. 機能の概要（EARS要件定義書・設計文書ベース）

### 機能概要 🔵
**REQ-404**: システムは読み上げ速度を「遅い」「普通」「速い」の3段階から選択できなければならない

本機能は、TASK-0048で実装したOS標準TTS連携機能に対して、ユーザーが読み上げ速度を調整できる設定機能を追加するものである。発話困難な方が相手に伝える際、相手の理解度や状況に応じて読み上げ速度を調整できることで、より効果的なコミュニケーションを実現する。

### 何をする機能か 🔵
- TTS読み上げ速度を3段階（遅い/普通/速い）から選択する
- 選択した速度を即座にTTSエンジンに反映する
- 設定した速度をローカルストレージ（shared_preferences）に保存し、アプリ再起動後も保持する

### どのような問題を解決するか 🔵
**ユーザストーリー**: "ユーザーストーリーUS-005: 読み上げ設定を調整したい"より
- **As a** 発話困難なユーザー
- **I want to** 読み上げ速度を調整したい
- **So that** 相手が聞き取りやすい速度でコミュニケーションできる

**解決する問題**:
1. 高齢者や聴覚に配慮が必要な相手には、ゆっくりとした速度（0.7倍速）で伝える
2. 標準的な速度（1.0倍速）で自然な会話を実現する
3. アプリに慣れたユーザーは効率的な速度（1.3倍速）で素早く伝える

### 想定されるユーザー 🔵
- 脳梗塞・ALS・筋疾患などで発話が困難だが、タブレットのタップ操作がある程度可能な方
- コミュニケーションの相手（家族、介護スタッフ、医師、看護師）の状況に応じて速度調整が必要な方

### システム内での位置づけ 🔵
- **アーキテクチャ**: オフラインファーストクライアント（architecture.md）
- **レイヤー**: フロントエンド（Flutter） > TTS機能 > 設定管理
- **既存実装との関係**:
  - TASK-0048で実装した`TTSService`に速度設定機能は既に実装済み（`setSpeed()`メソッド）
  - TASK-0048で実装した`TTSSpeed` enum（slow: 0.7, normal: 1.0, fast: 1.3）を使用
  - 本タスクでは**UIと永続化**を実装する

### 参照したEARS要件 🔵
- **REQ-404**: システムは読み上げ速度を「遅い」「普通」「速い」の3段階から選択できなければならない
- **REQ-2007**: ユーザーがフォントサイズを変更した場合、システムは即座にすべてのテキスト要素のサイズを変更しなければならない（即座反映の参考）

### 参照した設計文書 🔵
- **architecture.md**: オフラインファースト設計、ローカルストレージ優先
- **interfaces.dart**:
  - `TTSSpeed` enum（298-319行目）- slow(0.7), normal(1.0), fast(1.3)
  - `AppSettings`クラス（213-274行目）- `ttsSpeed`フィールド
- **tts_speed.dart**: 既存実装（TASK-0048で作成済み）
- **tts_service.dart**: `setSpeed(TTSSpeed speed)`メソッド（既存実装）

---

## 2. 入力・出力の仕様（EARS機能要件・TypeScript型定義ベース）

### 入力パラメータ 🔵

#### 2.1. ユーザー入力
**型**: `TTSSpeed` enum
```dart
enum TTSSpeed {
  slow,   // 遅い（0.7倍速）
  normal, // 普通（1.0倍速）
  fast,   // 速い（1.3倍速）
}
```

**選択方法**: 設定画面のラジオボタンまたはセグメントコントロール
- タップ操作で3つの選択肢から1つを選択
- 初期値: `TTSSpeed.normal`（1.0倍速）

#### 2.2. 保存形式（shared_preferences）
**キー**: `'tts_speed'`（String）
**値**: `'slow'` | `'normal'` | `'fast'`（String）
**デフォルト値**: `'normal'`

### 出力値 🔵

#### 2.1. TTS速度反映
**対象**: `TTSService.setSpeed(TTSSpeed speed)`メソッド
- 速度値（double）がflutter_ttsの`setSpeechRate()`に渡される
  - `slow`: 0.7
  - `normal`: 1.0
  - `fast`: 1.3

#### 2.2. UI表示
**対象**: 設定画面の速度選択UI
- 現在選択されている速度がハイライト表示される
- 各選択肢の表示名:
  - `slow`: "遅い"
  - `normal`: "普通"
  - `fast`: "速い"

### 入出力の関係性 🔵

```
[ユーザー] → [速度選択UI] → [TTSSpeed enum]
                              ↓
    ┌────────────────────────┼────────────────────────┐
    ↓                        ↓                        ↓
[TTSService.setSpeed()]  [AppSettings更新]   [shared_preferences保存]
    ↓                        ↓                        ↓
[flutter_tts.setSpeechRate()] [Riverpod状態管理]  [永続化]
    ↓                        ↓                        ↓
[次回読み上げから反映]    [UIに反映]            [再起動後も保持]
```

### データフロー 🔵

1. **設定画面での速度選択**
   - ユーザーが設定画面で速度ボタンをタップ
   - `TTSSpeed` enumの値が選択される

2. **即座反映**（REQ-2007の参考）
   - `TTSNotifier.setSpeed(speed)`を呼び出し
   - `TTSService.setSpeed(speed)`が実行される
   - flutter_ttsの`setSpeechRate(speed.value)`が呼ばれる
   - 次回の読み上げから新しい速度が適用される

3. **永続化**
   - `AppSettings`の`ttsSpeed`フィールドを更新
   - shared_preferencesに保存（`'tts_speed'`: `'slow'/'normal'/'fast'`）

4. **アプリ起動時の復元**
   - shared_preferencesから`'tts_speed'`を読み込み
   - `AppSettings`を初期化
   - `TTSService.setSpeed()`で速度を設定

### 参照したEARS要件 🔵
- **REQ-404**: 読み上げ速度を「遅い」「普通」「速い」の3段階から選択

### 参照した設計文書 🔵
- **interfaces.dart**: `TTSSpeed` enum（298-319行目）、`AppSettings`（213-274行目）
- **tts_speed.dart**: `TTSSpeedExtension.value`ゲッター（既存実装）

---

## 3. 制約条件（EARS非機能要件・アーキテクチャ設計ベース）

### パフォーマンス要件 🔵

#### 3.1. 設定反映速度（REQ-2007参考）
- **設定変更から反映までの時間**: 100ms以内（目標）
- **次回読み上げからの適用**: 即座（遅延なし）
- **shared_preferences保存**: 非同期で実行、UIブロックなし

#### 3.2. メモリ使用量 🟡
- **AppSettings**: 軽量な設定クラス（数バイト）
- **shared_preferences**: システム提供のキャッシュを使用
- **追加メモリ**: 無視できるレベル

### セキュリティ要件 🔵

#### 3.1. データ保存ポリシー（NFR-101）
- **保存先**: 端末内ローカルストレージ（shared_preferences）
- **アクセス制御**: アプリ専用領域、他アプリからアクセス不可
- **機密性**: TTS速度設定は個人情報ではないが、端末内に閉じる

### 互換性要件 🔵

#### 3.1. プラットフォーム対応（NFR-401）
- **iOS**: 14.0以上
- **Android**: 10以上
- **Web**: Chrome/Safari/Edge最新版
- **shared_preferences**: 全プラットフォームで動作

#### 3.2. flutter_tts対応 🔵
- **速度範囲**: 0.5〜2.0（flutter_tts仕様）
- **実装範囲**: 0.7〜1.3（アクセシビリティを考慮した安全な範囲）

### アーキテクチャ制約 🔵

#### 3.1. オフライン動作（REQ-1001）
- TTS速度設定はオフライン環境で完全に動作
- ネットワーク接続不要

#### 3.2. データ永続化（REQ-5003）
- アプリ強制終了時も設定を失わない
- shared_preferencesによる永続化

#### 3.3. 状態管理（architecture.md）
- Riverpod 2.xによる状態管理
- `AppSettings` Providerで一元管理

### 参照したEARS要件 🔵
- **NFR-101**: 利用者の会話内容を原則として端末内にのみ保存
- **NFR-401**: iOS 14.0以上、Android 10以上で動作
- **REQ-1001**: 文字盤入力・定型文・履歴・TTSをオフライン環境で利用可能
- **REQ-5003**: アプリが強制終了しても定型文・設定・履歴を失わない永続化機構

### 参照した設計文書 🔵
- **architecture.md**: オフラインファースト設計（20-29行目）、ローカルストレージ（40行目）
- **tech-stack.md**: shared_preferences（45行目）

---

## 4. 想定される使用例（EARSEdgeケース・データフローベース）

### 基本的な使用パターン 🔵

#### 4.1. 初回起動時（デフォルト速度）
**フロー**:
1. ユーザーがアプリを初回起動
2. shared_preferencesに`'tts_speed'`が存在しない
3. デフォルト値`TTSSpeed.normal`（1.0倍速）が設定される
4. ユーザーが読み上げボタンをタップ
5. 標準速度（1.0倍速）で読み上げられる

#### 4.2. 速度を「遅い」に変更
**ユースケース**: 高齢の家族に伝える場合
**フロー**:
1. ユーザーが設定画面を開く
2. TTS速度設定セクションで「遅い」をタップ
3. `TTSNotifier.setSpeed(TTSSpeed.slow)`が呼ばれる
4. `TTSService.setSpeed()`でflutter_ttsに0.7が設定される
5. shared_preferencesに`'tts_speed': 'slow'`が保存される
6. 次回の読み上げから0.7倍速で読み上げられる

#### 4.3. 速度を「速い」に変更
**ユースケース**: 慣れた介護スタッフとの素早いコミュニケーション
**フロー**:
1. ユーザーが設定画面を開く
2. TTS速度設定セクションで「速い」をタップ
3. `TTSNotifier.setSpeed(TTSSpeed.fast)`が呼ばれる
4. `TTSService.setSpeed()`でflutter_ttsに1.3が設定される
5. shared_preferencesに`'tts_speed': 'fast'`が保存される
6. 次回の読み上げから1.3倍速で読み上げられる

#### 4.4. アプリ再起動後の設定復元
**フロー**:
1. ユーザーが速度を「速い」に設定（前回のセッション）
2. アプリを終了
3. アプリを再起動
4. アプリ起動時にshared_preferencesから`'tts_speed': 'fast'`を読み込み
5. `TTSService.setSpeed(TTSSpeed.fast)`で1.3倍速を設定
6. 前回と同じ速度（1.3倍速）で読み上げられる

### データフロー 🔵

#### 設定変更時のデータフロー
```
[設定画面UI]
    ↓ タップ（slow/normal/fast）
[TTSSpeedSettingsWidget]
    ↓ onChanged(TTSSpeed speed)
[SettingsProvider.setTTSSpeed(speed)]
    ↓
    ├─→ [TTSNotifier.setSpeed(speed)]
    │       ↓
    │   [TTSService.setSpeed(speed)]
    │       ↓
    │   [flutter_tts.setSpeechRate(speed.value)]
    │
    └─→ [AppSettings更新（copyWith）]
            ↓
        [shared_preferences.setString('tts_speed', speed.name)]
```

#### アプリ起動時のデータフロー
```
[main.dart / アプリ起動]
    ↓
[SettingsProvider初期化]
    ↓
[shared_preferences.getString('tts_speed')]
    ↓
[AppSettings.fromJson() / デフォルト値: normal]
    ↓
[TTSNotifier.setSpeed(settings.ttsSpeed)]
    ↓
[TTSService.setSpeed(speed)]
    ↓
[flutter_tts.setSpeechRate(speed.value)]
```

### エッジケース 🟡

#### EDGE-1: 読み上げ中に速度を変更
**シナリオ**: ユーザーが読み上げ中に設定画面で速度を変更
**期待動作**:
- 現在の読み上げは元の速度で継続
- 次回の読み上げから新しい速度が適用される
- エラーは発生しない

**実装上の考慮**:
- `TTSService.setSpeed()`は読み上げ中でも安全に呼び出せる
- flutter_ttsの`setSpeechRate()`は非同期で処理される

#### EDGE-2: shared_preferences保存失敗
**シナリオ**: ストレージ容量不足などでshared_preferences保存が失敗
**期待動作**:
- エラーログを出力
- UIには変更が反映される（メモリ上の状態は更新）
- 次回起動時は前回の保存済み設定が使われる
- アプリは継続動作（NFR-301準拠）

**実装上の考慮**:
- shared_preferencesの保存は非同期で実行
- 保存失敗時もアプリはクラッシュしない

#### EDGE-3: 不正な速度値の読み込み 🟡
**シナリオ**: shared_preferencesに不正な値（例: `'invalid'`）が保存されている
**期待動作**:
- デフォルト値`TTSSpeed.normal`にフォールバック
- エラーログを出力
- アプリは継続動作

**実装上の考慮**:
- `AppSettings.fromJson()`でエラーハンドリング
- `TTSSpeed.values.byName()`が例外をスローする場合はcatch

### エラーケース 🟡

#### ERROR-1: TTS初期化前の速度設定
**シナリオ**: TTSServiceが初期化される前に`setSpeed()`が呼ばれる
**期待動作**:
- 速度値は保存される（`currentSpeed`フィールド）
- TTS初期化後に保存された速度が適用される
- エラーは発生しない

**実装上の考慮**:
- `TTSService.setSpeed()`は`_isInitialized`をチェックしない（速度設定は初期化前でも可能）

#### ERROR-2: flutter_tts.setSpeechRate()の失敗 🟡
**シナリオ**: OS標準TTSエンジンが速度変更を受け付けない
**期待動作**:
- エラーログを出力
- 状態には反映される（`currentSpeed`フィールド）
- 次回の読み上げ時に再試行
- アプリは継続動作（NFR-301準拠）

**実装上の考慮**:
- `TTSService.setSpeed()`でtry-catchによるエラーハンドリング

### 参照したEARS要件 🔵
- **REQ-404**: 読み上げ速度を「遅い」「普通」「速い」の3段階から選択
- **REQ-2007**: 設定変更時の即座反映（参考）
- **NFR-301**: 重大なエラーでも基本機能は継続動作

### 参照した設計文書 🔵
- **dataflow.md**: データフロー図（基本コミュニケーションフロー参考）

---

## 5. EARS要件・設計文書との対応関係

### 参照したユーザストーリー 🔵
- **US-005**: "読み上げ設定を調整したい"（kotonoha-user-stories.md）

### 参照した機能要件 🔵
- **REQ-404**: システムは読み上げ速度を「遅い」「普通」「速い」の3段階から選択できなければならない

### 参照した非機能要件 🔵
- **NFR-101**: システムは利用者の会話内容（定型文・履歴）を原則として端末内にのみ保存しなければならない
- **NFR-301**: システムは重大なエラーが発生しても、基本機能（文字盤+読み上げ）を継続して利用可能に保たなければならない
- **NFR-401**: システムはiOS 14.0以上、Android 10以上、主要モダンブラウザ（Chrome、Safari、Edge）で動作しなければならない

### 参照したEdgeケース 🟡
- **EDGE-202**: OSの音量が0（ミュート）の状態で読み上げを実行した場合、システムは「音量が0です」という視覚的警告を表示しなければならない（速度設定の参考）

### 参照した受け入れ基準 🔵
- **AC-005-001**: TTS速度を「遅い」「普通」「速い」の3段階から選択できること
- **AC-005-002**: 速度変更が次回の読み上げから反映されること
- **AC-005-003**: 速度設定がアプリ再起動後も保持されること

### 参照した設計文書 🔵

#### アーキテクチャ（architecture.md）
- **オフラインファースト設計**（20-29行目）: TTS速度設定はオフラインで動作
- **ローカルストレージ優先**（40行目）: shared_preferencesで設定保存

#### データフロー（dataflow.md）
- **基本コミュニケーションフロー**（87-95行目）: TTS読み上げフロー参考

#### 型定義（interfaces.dart）
- **TTSSpeed enum**（298-319行目）: slow(0.7), normal(1.0), fast(1.3)
- **AppSettings**（213-274行目）: `ttsSpeed`フィールド、`toJson()/fromJson()`

#### データベース（database-schema.sql）
- 該当なし（ローカルストレージのみ使用）

#### API仕様（api-endpoints.md）
- 該当なし（オフライン機能）

### 既存コード参照 🔵

#### TASK-0048で実装済みのコード
1. **lib/features/tts/domain/models/tts_speed.dart**
   - `TTSSpeed` enum定義
   - `TTSSpeedExtension.value`ゲッター（speed値取得）

2. **lib/features/tts/domain/services/tts_service.dart**
   - `setSpeed(TTSSpeed speed)`メソッド（既に実装済み）
   - `currentSpeed`フィールド（現在の速度を保持）

3. **lib/features/tts/providers/tts_provider.dart**
   - `TTSServiceState`に`currentSpeed`フィールド（既に実装済み）
   - `TTSNotifier.setSpeed(TTSSpeed speed)`メソッド（既に実装済み）

---

## 6. 実装スコープ（本タスクで実装する内容）

### 6.1. 実装する機能 🔵

本タスクでは以下を実装する:

1. **TTS速度設定UI**
   - 設定画面に速度選択セクションを追加
   - 3つの選択肢（遅い/普通/速い）をラジオボタンまたはセグメントコントロールで表示
   - 現在選択されている速度をハイライト表示

2. **AppSettings統合**
   - `AppSettings`クラスの`ttsSpeed`フィールドを使用
   - Riverpod ProviderでAppSettingsを管理

3. **shared_preferences永続化**
   - 速度変更時にshared_preferencesに保存
   - アプリ起動時にshared_preferencesから読み込み

4. **既存TTSService連携**
   - TASK-0048で実装済みの`TTSNotifier.setSpeed()`を呼び出し
   - 速度変更を即座に反映

### 6.2. 既に実装済みの機能（TASK-0048） 🔵

以下はTASK-0048で既に実装済みのため、本タスクでは**実装不要**:

1. **TTSSpeed enum**（tts_speed.dart）
   - `slow`, `normal`, `fast`の定義
   - `value`ゲッター（0.7, 1.0, 1.3）

2. **TTSService.setSpeed()メソッド**（tts_service.dart）
   - flutter_ttsの`setSpeechRate()`を呼び出し
   - `currentSpeed`フィールドを更新

3. **TTSNotifier.setSpeed()メソッド**（tts_provider.dart）
   - `TTSService.setSpeed()`を呼び出し
   - `TTSServiceState`の`currentSpeed`を更新

### 6.3. 実装しない機能（MVP範囲外）🔴

以下は本タスクおよびMVPの範囲外:

1. **リアルタイム速度変更**（読み上げ中に速度を変更して即座に反映）
2. **速度のカスタム設定**（0.5〜2.0の範囲で任意の速度を設定）
3. **音声プレビュー機能**（速度変更前にサンプル読み上げで確認）

---

## 7. テスト戦略

### 7.1. 単体テスト（Unit Test）🔵

#### テスト対象
- `AppSettings.copyWith(ttsSpeed: ...)`
- `AppSettings.toJson()` / `fromJson()`（ttsSpeedフィールド）
- shared_preferences保存・読み込み処理

#### テストケース
```dart
test('AppSettings.copyWithでttsSpeedを更新できる', () {
  final settings = AppSettings(ttsSpeed: TTSSpeed.normal);
  final updated = settings.copyWith(ttsSpeed: TTSSpeed.fast);
  expect(updated.ttsSpeed, TTSSpeed.fast);
});

test('AppSettings.toJson()でttsSpeedがシリアライズされる', () {
  final settings = AppSettings(ttsSpeed: TTSSpeed.slow);
  final json = settings.toJson();
  expect(json['tts_speed'], 'slow');
});

test('AppSettings.fromJson()でttsSpeedがデシリアライズされる', () {
  final json = {'tts_speed': 'fast'};
  final settings = AppSettings.fromJson(json);
  expect(settings.ttsSpeed, TTSSpeed.fast);
});

test('不正な速度値はデフォルト値にフォールバック', () {
  final json = {'tts_speed': 'invalid'};
  final settings = AppSettings.fromJson(json);
  expect(settings.ttsSpeed, TTSSpeed.normal); // デフォルト
});
```

### 7.2. ウィジェットテスト（Widget Test）🔵

#### テスト対象
- TTS速度設定UI
- ラジオボタン/セグメントコントロールの選択状態
- 速度変更時のProviderへの通知

#### テストケース
```dart
testWidgets('TTS速度設定UIが表示される', (tester) async {
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(home: TTSSpeedSettingsWidget()),
  ));

  expect(find.text('読み上げ速度'), findsOneWidget);
  expect(find.text('遅い'), findsOneWidget);
  expect(find.text('普通'), findsOneWidget);
  expect(find.text('速い'), findsOneWidget);
});

testWidgets('速度を「遅い」に変更できる', (tester) async {
  final container = ProviderContainer();

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: TTSSpeedSettingsWidget()),
  ));

  // 「遅い」をタップ
  await tester.tap(find.text('遅い'));
  await tester.pumpAndSettle();

  // AppSettingsが更新されたことを確認
  final settings = container.read(appSettingsProvider);
  expect(settings.ttsSpeed, TTSSpeed.slow);

  // TTSNotifier.setSpeed()が呼ばれたことを確認
  final ttsState = container.read(ttsProvider);
  expect(ttsState.currentSpeed, TTSSpeed.slow);
});

testWidgets('現在の速度がハイライト表示される', (tester) async {
  final container = ProviderContainer(
    overrides: [
      appSettingsProvider.overrideWith(
        (ref) => AppSettings(ttsSpeed: TTSSpeed.fast),
      ),
    ],
  );

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: TTSSpeedSettingsWidget()),
  ));

  // 「速い」が選択されていることを確認
  // （実装詳細に依存するため、実装時に具体的なチェックを追加）
});
```

### 7.3. 統合テスト（Integration Test）🔵

#### テストシナリオ
1. **速度変更→読み上げ→確認**
   - 速度を「遅い」に変更
   - テキストを読み上げ
   - 0.7倍速で読み上げられることを確認（手動確認または音声分析）

2. **速度変更→アプリ再起動→確認**
   - 速度を「速い」に変更
   - アプリを再起動
   - 速度が「速い」に保持されていることを確認

3. **オフライン環境での動作確認**
   - ネットワークを切断
   - 速度を変更
   - 正常に動作することを確認

### 7.4. カバレッジ目標 🔵
- **全体カバレッジ**: 80%以上（NFR-501）
- **ビジネスロジック**: 90%以上（NFR-502）
- **UI層**: 70%以上（ウィジェットテスト）

---

## 8. 品質判定

### 品質基準チェック ✅

#### ✅ 高品質
- **要件の曖昧さ**: なし
  - REQ-404で明確に3段階（遅い/普通/速い）を定義
  - TASK-0048で既に速度値（0.7/1.0/1.3）を実装済み

- **入出力定義**: 完全
  - 入力: `TTSSpeed` enum（既存定義）
  - 出力: flutter_ttsへの速度値、shared_preferencesへの保存、UI表示

- **制約条件**: 明確
  - オフライン動作、端末内保存、アプリ再起動後も保持

- **実装可能性**: 確実
  - TASK-0048で`setSpeed()`メソッドは既に実装済み
  - shared_preferencesは標準的なFlutterパッケージ
  - AppSettings統合は既存パターンを踏襲

---

## 9. 次のステップ

**次のお勧めステップ**: `/tsumiki:tdd-testcases` でテストケースの洗い出しを行います。

---

## 10. 更新履歴

- **2025-11-25**: 初版作成（/tsumiki:tdd-requirements コマンド実行）
  - TASK-0049（TTS速度設定）の要件定義を作成
  - TASK-0048で実装済みの機能を明確化
  - REQ-404、interfaces.dart、既存実装（tts_speed.dart、tts_service.dart、tts_provider.dart）を参照
