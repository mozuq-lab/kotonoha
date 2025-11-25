# TASK-0049: TTS速度設定 - テストケース定義書

**タスクID**: TASK-0049
**タスク名**: TTS速度設定（遅い/普通/速い）
**要件名**: kotonoha
**関連要件**: REQ-404
**作成日**: 2025-11-25

---

## テストケースの分類と実装方針

本タスクでは、TTS速度設定機能に関する以下の3つのレイヤーのテストを実施します：

### 1. 単体テスト（Unit Test）
- **対象**: AppSettings、shared_preferences連携
- **ファイル**: `test/features/settings/models/app_settings_test.dart`（新規作成）
- **目的**: TTS速度の保存・読み込み・デフォルト値の動作確認

### 2. ウィジェットテスト（Widget Test）
- **対象**: TTS速度設定UIウィジェット
- **ファイル**: `test/features/settings/presentation/widgets/tts_speed_settings_widget_test.dart`（新規作成）
- **目的**: 速度選択UI、選択状態の表示、ユーザー操作の動作確認

### 3. 統合テスト（Integration Test）
- **対象**: 速度変更→TTSへの反映、永続化
- **ファイル**: `test/integration/tts_speed_integration_test.dart`（新規作成）
- **目的**: エンドツーエンドでの速度設定→読み上げ→再起動後の復元の確認

---

## プログラミング言語・テストフレームワーク

### プログラミング言語: Dart
**言語選択の理由**: 🔵
- Flutterアプリケーションの標準言語
- 既存のテストコード（TASK-0048のTTSテスト、TASK-0013の設定テスト）と同じ言語・パターンを踏襲
- Null Safety対応により、型安全なテストコードを記述可能

**テストに適した機能**:
- `async/await`による非同期テストの記述が容易
- Enum型のサポートにより、速度値（slow/normal/fast）の型安全な扱いが可能

### テストフレームワーク: flutter_test + Riverpod Testing + Mocktail
**フレームワーク選択の理由**: 🔵
- **flutter_test**: Flutterの標準テストフレームワーク（単体テスト、ウィジェットテスト）
- **Riverpod Testing**: Riverpod 2.xの状態管理テストに最適
- **Mocktail**: shared_preferencesのモック化に使用（既存テストと同じパターン）

**テスト実行環境**:
- 開発環境: `flutter test`コマンド
- CI/CD: GitHub Actionsでの自動テスト実行

---

## 1. 正常系テストケース（基本的な動作）

### TC-049-001: AppSettings.ttsSpeedのデフォルト値確認

**テスト名**: AppSettings初期化時にttsSpeedがデフォルト値（normal）であることを確認
**何をテストするか**: 🔵
- AppSettingsをデフォルトコンストラクタで初期化した場合、`ttsSpeed`フィールドが`TTSSpeed.normal`（1.0倍速）に設定されること
**期待される動作**: 🔵
- デフォルト値`TTSSpeed.normal`が設定される
- 他のフィールド（fontSize、themeなど）も正しくデフォルト値が設定される

**入力値**:
- なし（デフォルトコンストラクタ）

**入力データの意味**:
- アプリ初回起動時、ユーザーがまだTTS速度を設定していない状態を模擬

**期待される結果**:
- `appSettings.ttsSpeed == TTSSpeed.normal`
- デフォルト速度値: 1.0倍速

**期待結果の理由**: 🔵
- REQ-404で定義された「普通」（1.0倍速）がデフォルト値
- interfaces.dartのAppSettings定義（213-274行目）で`ttsSpeed: TTSSpeed.normal`がデフォルト

**テストの目的**:
- アプリ初回起動時に適切なデフォルト速度が設定されることを確認
- ユーザーが明示的に速度を選択するまで、標準的な速度（1.0倍速）で読み上げが行われることを保証

**確認ポイント**:
- `ttsSpeed`フィールドが正しく初期化される
- Null値ではなく、有効な`TTSSpeed`値が設定される

🔵 **信頼性レベル**: interfaces.dart（213-274行目）、requirements.md（79-84行目）に基づく

---

### TC-049-002: AppSettings.copyWith()でttsSpeedを更新

**テスト名**: copyWithメソッドでttsSpeedのみを変更し、他のフィールドが保持されることを確認
**何をテストするか**: 🔵
- `copyWith(ttsSpeed: TTSSpeed.slow)`を呼び出した場合、`ttsSpeed`のみが変更され、他のフィールド（fontSize、theme）は元の値を保持すること
**期待される動作**: 🔵
- 新しいAppSettingsインスタンスが生成される（不変オブジェクトパターン）
- `ttsSpeed`が指定した値（slow）に変更される
- `fontSize`、`theme`は元の値を保持

**入力値**:
```dart
final original = AppSettings(fontSize: FontSize.large, theme: AppTheme.dark, ttsSpeed: TTSSpeed.normal);
final updated = original.copyWith(ttsSpeed: TTSSpeed.slow);
```

**入力データの意味**:
- ユーザーが既に設定をカスタマイズしている状態（フォントサイズ「大」、ダークモード）で、TTS速度のみを変更する場合を模擬

**期待される結果**:
- `updated.ttsSpeed == TTSSpeed.slow`（変更後）
- `updated.fontSize == FontSize.large`（保持）
- `updated.theme == AppTheme.dark`（保持）
- `original`と`updated`は異なるインスタンス

**期待結果の理由**: 🔵
- Dartの不変オブジェクトパターン（copyWithパターン）の標準的な動作
- 既存のテスト（settings_provider_test.dart）と同じパターン

**テストの目的**:
- 設定の一部のみを変更する際に、他の設定が意図せず変更されないことを確認
- 不変オブジェクトパターンの正しい実装を保証

**確認ポイント**:
- 新しいインスタンスが生成される（元のインスタンスは変更されない）
- 変更対象のフィールドのみが更新される

🔵 **信頼性レベル**: 既存テスト（settings_provider_test.dart TC-002）と同じパターン、Dartの標準的な実装方法

---

### TC-049-003: AppSettings.toJson()でttsSpeedがシリアライズされる

**テスト名**: toJson()メソッドでttsSpeedが正しくJSON形式に変換されることを確認
**何をテストするか**: 🔵
- `toJson()`を呼び出した場合、`ttsSpeed`フィールドが文字列形式（'slow'/'normal'/'fast'）でJSONに含まれること
**期待される動作**: 🔵
- JSONオブジェクトに`'tts_speed'`キーが含まれる
- 値はenum名の文字列（'slow'/'normal'/'fast'）

**入力値**:
```dart
final settings = AppSettings(ttsSpeed: TTSSpeed.fast);
final json = settings.toJson();
```

**入力データの意味**:
- ユーザーが速度を「速い」に設定した状態を模擬
- shared_preferencesに保存する際のシリアライズ処理

**期待される結果**:
- `json['tts_speed'] == 'fast'`
- JSON形式: `{ "font_size": "medium", "theme": "light", "tts_speed": "fast" }`

**期待結果の理由**: 🔵
- requirements.md（82-84行目）で定義された保存形式（String型、'slow'/'normal'/'fast'）
- 既存のfontSize、themeと同じシリアライズパターン

**テストの目的**:
- shared_preferencesへの保存前に、AppSettingsが正しくJSON形式に変換されることを確認
- 永続化データの形式が仕様通りであることを保証

**確認ポイント**:
- キー名が正しい（`'tts_speed'`）
- 値がenum名の文字列形式

🔵 **信頼性レベル**: requirements.md（82-84行目）、既存のtoJson()実装パターンに基づく

---

### TC-049-004: AppSettings.fromJson()でttsSpeedがデシリアライズされる

**テスト名**: fromJson()メソッドでJSON形式からttsSpeedが正しく復元されることを確認
**何をテストするか**: 🔵
- `fromJson({'tts_speed': 'slow'})`を呼び出した場合、`ttsSpeed`フィールドが`TTSSpeed.slow`に正しく変換されること
**期待される動作**: 🔵
- JSON文字列からenum値への変換が正しく行われる
- 他のフィールド（fontSize、theme）も正しく復元される

**入力値**:
```dart
final json = {'tts_speed': 'slow', 'font_size': 'large', 'theme': 'dark'};
final settings = AppSettings.fromJson(json);
```

**入力データの意味**:
- shared_preferencesから読み込んだJSON形式のデータ
- アプリ再起動時の設定復元処理を模擬

**期待される結果**:
- `settings.ttsSpeed == TTSSpeed.slow`
- `settings.fontSize == FontSize.large`
- `settings.theme == AppTheme.dark`

**期待結果の理由**: 🔵
- REQ-5003（設定永続化）に基づく
- アプリ再起動後も設定が正しく復元される必要がある

**テストの目的**:
- アプリ再起動時に、保存されたTTS速度が正しく復元されることを確認
- データの永続化・復元サイクルが正しく機能することを保証

**確認ポイント**:
- JSON文字列からenum値への変換が正しい
- 不正な値の場合はデフォルト値にフォールバック（次のテストケース）

🔵 **信頼性レベル**: requirements.md（133-136行目）、REQ-5003に基づく

---

### TC-049-005: SettingsNotifier.setTTSSpeed()でshared_preferencesに保存される

**テスト名**: setTTSSpeed()メソッドを呼び出すと、shared_preferencesに速度設定が保存されることを確認
**何をテストするか**: 🔵
- `setTTSSpeed(TTSSpeed.fast)`を呼び出した場合、shared_preferencesに`'tts_speed': 'fast'`が保存されること
- AppSettings状態も即座に更新されること
**期待される動作**: 🔵
- shared_preferencesに`setString('tts_speed', 'fast')`が呼ばれる
- Riverpod stateが即座に更新される（楽観的更新）

**入力値**:
```dart
await notifier.setTTSSpeed(TTSSpeed.fast);
```

**入力データの意味**:
- ユーザーが設定画面で「速い」を選択した場合を模擬

**期待される結果**:
- `settings.ttsSpeed == TTSSpeed.fast`（状態更新）
- `prefs.getString('tts_speed') == 'fast'`（永続化）

**期待結果の理由**: 🔵
- REQ-5003（設定永続化）に基づく
- REQ-2007（即座反映）を参考にした楽観的更新

**テストの目的**:
- ユーザーの速度変更が確実に保存されることを確認
- アプリ再起動後も設定が失われないことを保証

**確認ポイント**:
- 保存前に状態が更新される（UI応答性）
- 保存処理が非同期で実行される

🔵 **信頼性レベル**: requirements.md（129-131行目）、REQ-5003、REQ-2007に基づく

---

### TC-049-006: SettingsNotifier.setTTSSpeed()でTTSNotifier.setSpeed()が呼ばれる

**テスト名**: setTTSSpeed()を呼び出すと、TTSNotifier.setSpeed()が呼ばれ、TTSエンジンに速度が反映されることを確認
**何をテストするか**: 🔵
- `setTTSSpeed(TTSSpeed.slow)`を呼び出した場合、`TTSNotifier.setSpeed(TTSSpeed.slow)`が呼ばれること
- TTSServiceに速度変更が伝達されること
**期待される動作**: 🔵
- `TTSNotifier.setSpeed()`が1回呼ばれる
- 引数は`TTSSpeed.slow`
- TTSエンジンに0.7倍速が設定される

**入力値**:
```dart
await settingsNotifier.setTTSSpeed(TTSSpeed.slow);
```

**入力データの意味**:
- ユーザーが設定画面で「遅い」を選択した場合を模擬
- 次回の読み上げから新しい速度が適用される

**期待される結果**:
- `TTSNotifier.setSpeed(TTSSpeed.slow)`が呼ばれる
- `ttsState.currentSpeed == TTSSpeed.slow`

**期待結果の理由**: 🔵
- requirements.md（122-127行目）のデータフローに基づく
- 設定変更が即座にTTSエンジンに反映される必要がある

**テストの目的**:
- 設定画面での速度変更が、TTSエンジンに正しく伝達されることを確認
- 次回の読み上げから新しい速度が適用されることを保証

**確認ポイント**:
- 設定変更とTTS速度変更が同期している
- モック化したTTSNotifierを使用して呼び出しを検証

🔵 **信頼性レベル**: requirements.md（122-127行目）、dataflow.md（設定変更時のデータフロー 250-266行目）に基づく

---

### TC-049-007: 速度を「遅い」に設定し、読み上げると0.7倍速で再生される

**テスト名**: 速度を「遅い」に設定後、テキストを読み上げると0.7倍速で再生されることを確認
**何をテストするか**: 🔵
- 速度設定→読み上げの一連のフローで、設定した速度が正しく適用されること
**期待される動作**: 🔵
- flutter_ttsの`setSpeechRate(0.7)`が呼ばれる
- `speak()`で読み上げが開始される

**入力値**:
```dart
await settingsNotifier.setTTSSpeed(TTSSpeed.slow);
await ttsNotifier.speak('こんにちは');
```

**入力データの意味**:
- ユーザーが速度を「遅い」に設定し、実際にテキストを読み上げる場合を模擬
- 高齢者に伝える際のユースケース

**期待される結果**:
- `mockFlutterTts.setSpeechRate(0.7)`が呼ばれる
- `mockFlutterTts.speak('こんにちは')`が呼ばれる

**期待結果の理由**: 🔵
- requirements.md（218-226行目）の使用例「4.2. 速度を「遅い」に変更」に基づく

**テストの目的**:
- エンドツーエンドで速度設定→読み上げが正しく機能することを確認
- ユースケースに基づいた統合テスト

**確認ポイント**:
- 速度設定後、次回の読み上げから新しい速度が適用される
- 既に読み上げ中の場合、現在の読み上げは元の速度で継続（EDGE-1参照）

🔵 **信頼性レベル**: requirements.md（218-226行目）、interfaces.dartのTTSSpeed定義に基づく

---

### TC-049-008: 速度を「普通」に設定し、読み上げると1.0倍速で再生される

**テスト名**: 速度を「普通」に設定後、テキストを読み上げると1.0倍速で再生されることを確認
**何をテストするか**: 🔵
- デフォルト速度（normal）が正しく動作すること
**期待される動作**: 🔵
- flutter_ttsの`setSpeechRate(1.0)`が呼ばれる
- 標準的な速度で読み上げが行われる

**入力値**:
```dart
await settingsNotifier.setTTSSpeed(TTSSpeed.normal);
await ttsNotifier.speak('こんにちは');
```

**入力データの意味**:
- ユーザーが標準速度で読み上げを行う場合を模擬
- 最も一般的なユースケース

**期待される結果**:
- `mockFlutterTts.setSpeechRate(1.0)`が呼ばれる
- `mockFlutterTts.speak('こんにちは')`が呼ばれる

**期待結果の理由**: 🔵
- TTSSpeed.normalの値が1.0であること（tts_speed.dart 67-69行目）

**テストの目的**:
- デフォルト速度が正しく動作することを確認
- 最も頻繁に使用される速度設定の動作保証

**確認ポイント**:
- 1.0倍速が標準的な読み上げ速度として機能する

🔵 **信頼性レベル**: tts_speed.dart（67-69行目）、interfaces.dartに基づく

---

### TC-049-009: 速度を「速い」に設定し、読み上げると1.3倍速で再生される

**テスト名**: 速度を「速い」に設定後、テキストを読み上げると1.3倍速で再生されることを確認
**何をテストするか**: 🔵
- 最大速度（fast）が正しく動作すること
**期待される動作**: 🔵
- flutter_ttsの`setSpeechRate(1.3)`が呼ばれる
- 効率的な速度で読み上げが行われる

**入力値**:
```dart
await settingsNotifier.setTTSSpeed(TTSSpeed.fast);
await ttsNotifier.speak('こんにちは');
```

**入力データの意味**:
- ユーザーが慣れた介護スタッフとの素早いコミュニケーションを行う場合を模擬
- requirements.md（228-236行目）の使用例に基づく

**期待される結果**:
- `mockFlutterTts.setSpeechRate(1.3)`が呼ばれる
- `mockFlutterTts.speak('こんにちは')`が呼ばれる

**期待結果の理由**: 🔵
- requirements.md（228-236行目）の使用例「4.3. 速度を「速い」に変更」に基づく

**テストの目的**:
- 最大速度が正しく動作することを確認
- 効率性を重視するユーザーの要求を満たすことを保証

**確認ポイント**:
- 1.3倍速でも聞き取れる範囲内の速度設定

🔵 **信頼性レベル**: requirements.md（228-236行目）、tts_speed.dart（70-72行目）に基づく

---

### TC-049-010: アプリ再起動後、保存されたTTS速度が復元される

**テスト名**: アプリを終了し再起動した後、前回設定したTTS速度が正しく復元されることを確認
**何をテストするか**: 🔵
- 永続化された速度設定が再起動後も保持されること
**期待される動作**: 🔵
- shared_preferencesから`'tts_speed': 'fast'`を読み込む
- AppSettings.ttsSpeedが`TTSSpeed.fast`に復元される
- TTSService.setSpeed()が呼ばれ、TTSエンジンに速度が設定される

**入力値**:
```dart
// 前回のセッション
await settingsNotifier.setTTSSpeed(TTSSpeed.fast);
// アプリ終了・再起動（新しいProviderContainer作成）
SharedPreferences.setMockInitialValues({'tts_speed': 'fast'});
container = ProviderContainer();
```

**入力データの意味**:
- ユーザーが前回のセッションで速度を「速い」に設定し、翌日アプリを再起動した場合を模擬
- requirements.md（238-245行目）の使用例に基づく

**期待される結果**:
- `settings.ttsSpeed == TTSSpeed.fast`（復元）
- `ttsState.currentSpeed == TTSSpeed.fast`（TTSエンジンに反映）

**期待結果の理由**: 🔵
- REQ-5003（設定永続化）に基づく
- ユーザー体験の一貫性維持のため

**テストの目的**:
- アプリ再起動後も設定が失われないことを確認
- 永続化・復元サイクルが正しく機能することを保証

**確認ポイント**:
- shared_preferencesからの読み込みが正しく行われる
- 起動時にTTSエンジンに速度が設定される

🔵 **信頼性レベル**: requirements.md（238-245行目）、REQ-5003に基づく

---

## 2. 異常系テストケース（エラーハンドリング）

### TC-049-011: 不正な速度値がshared_preferencesに保存されている場合、デフォルト値にフォールバック

**テスト名**: shared_preferencesに不正な値（'invalid'）が保存されている場合、デフォルト値（normal）にフォールバックすることを確認
**エラーケースの概要**: 🟡
- shared_preferencesのデータが破損している場合
- 古いバージョンのアプリとの互換性問題
**エラー処理の重要性**: 🟡
- アプリがクラッシュせず、デフォルト速度で動作継続する必要がある
- NFR-301（基本機能継続）に準拠

**入力値**:
```dart
SharedPreferences.setMockInitialValues({'tts_speed': 'invalid'});
container = ProviderContainer();
```

**不正な理由**:
- 'invalid'は`TTSSpeed`のenum名に存在しない
- `TTSSpeed.values.byName('invalid')`は例外をスローする

**実際の発生シナリオ**:
- ストレージデータが破損した場合
- アプリのバージョンアップで速度の種類が変更された場合（将来的な拡張）

**期待される結果**:
- `settings.ttsSpeed == TTSSpeed.normal`（デフォルト値にフォールバック）
- エラーログが出力される
- アプリは継続動作する

**エラーメッセージの内容**:
- 「不正なTTS速度値を検出しました。デフォルト値（normal）を使用します。」

**システムの安全性**:
- エラー発生でもアプリがクラッシュしない
- デフォルト速度で読み上げが継続できる

**テストの目的**:
- エラーハンドリングの堅牢性を確認
- 不正なデータに対する安全な動作を保証

**品質保証の観点**:
- NFR-301（基本機能継続）に準拠
- ユーザーに対する適切なエラー通知

🟡 **信頼性レベル**: requirements.md（310-319行目）のEDGE-3、NFR-301から類推

---

### TC-049-012: shared_preferences保存失敗時もUI状態は更新される（楽観的更新）

**テスト名**: shared_preferences.setString()が失敗した場合でも、AppSettingsの状態は更新されることを確認
**エラーケースの概要**: 🟡
- ストレージ容量不足
- ストレージアクセス権限エラー
**エラー処理の重要性**: 🟡
- UI応答性を維持（REQ-2007参考）
- ユーザーに即座にフィードバックを提供

**入力値**:
```dart
// モックでsetString()が例外をスローするように設定
await notifier.setTTSSpeed(TTSSpeed.fast);
```

**不正な理由**:
- ストレージへの書き込みが失敗
- OSレベルのエラー

**実際の発生シナリオ**:
- ストレージ容量不足
- ファイルシステムエラー
- OSアップデート中のストレージアクセス制限

**期待される結果**:
- `settings.ttsSpeed == TTSSpeed.fast`（状態更新は成功）
- エラーログが出力される
- 次回起動時は前回の保存済み設定が使われる

**エラーメッセージの内容**:
- 「TTS速度設定の保存に失敗しました。次回起動時に設定が戻る可能性があります。」

**システムの安全性**:
- 保存失敗でもUIは正常に動作
- ユーザーに適切な通知を表示

**テストの目的**:
- 楽観的更新パターンの動作確認
- エラー時のユーザー体験を保証

**品質保証の観点**:
- REQ-2007（即座反映）とNFR-304（エラーハンドリング）の両立
- requirements.md（298-308行目）のEDGE-2に準拠

🟡 **信頼性レベル**: requirements.md（298-308行目）のEDGE-2、既存テスト（settings_provider_test.dart TC-012）のパターンを踏襲

---

### TC-049-013: TTS初期化前に速度を設定してもエラーにならない

**テスト名**: TTSServiceが初期化される前にsetTTSSpeed()を呼んでも、エラーが発生しないことを確認
**エラーケースの概要**: 🟡
- アプリ起動時の初期化順序の問題
- TTS初期化が遅延している状態での速度設定
**エラー処理の重要性**: 🟡
- 初期化順序に依存しない堅牢な実装
- NFR-301（基本機能継続）に準拠

**入力値**:
```dart
// TTS初期化前
await settingsNotifier.setTTSSpeed(TTSSpeed.slow);
// TTS初期化
await ttsNotifier.initialize();
```

**不正な理由**:
- TTSServiceがまだ初期化されていない
- flutter_ttsインスタンスが準備できていない

**実際の発生シナリオ**:
- アプリ起動直後、ユーザーが即座に設定画面を開いた場合
- バックグラウンドからの復帰時

**期待される結果**:
- 速度値は保存される（`currentSpeed`フィールド）
- TTS初期化後に保存された速度が適用される
- エラーは発生しない

**エラーメッセージの内容**:
- なし（正常動作）

**システムの安全性**:
- 初期化順序に依存しない
- 速度設定は常に保持される

**テストの目的**:
- 初期化タイミングに関わらず安全に動作することを確認
- 競合状態に対する堅牢性を保証

**品質保証の観点**:
- requirements.md（323-331行目）のERROR-1に対応

🟡 **信頼性レベル**: requirements.md（323-331行目）のERROR-1、防御的プログラミングの原則に基づく

---

### TC-049-014: flutter_tts.setSpeechRate()失敗時もアプリは継続動作

**テスト名**: flutter_ttsの速度設定が失敗した場合でも、エラーログを出力してアプリは継続動作することを確認
**エラーケースの概要**: 🟡
- OS標準TTSエンジンが速度変更を受け付けない
- デバイス固有の制約
**エラー処理の重要性**: 🟡
- 読み上げ機能は継続動作する必要がある
- NFR-301（基本機能継続）に準拠

**入力値**:
```dart
// モックでsetSpeechRate()が例外をスローするように設定
when(() => mockFlutterTts.setSpeechRate(any())).thenThrow(Exception('速度設定失敗'));
await notifier.setSpeed(TTSSpeed.fast);
```

**不正な理由**:
- OS標準TTSエンジンのエラー
- デバイス固有の制約

**実際の発生シナリオ**:
- 古いOSバージョンでの互換性問題
- デバイス固有のTTSエンジンの制約
- 一時的なシステムリソース不足

**期待される結果**:
- エラーログが出力される
- 状態には反映される（`currentSpeed`フィールド）
- 次回の読み上げ時に再試行
- アプリは継続動作

**エラーメッセージの内容**:
- 「TTS速度の設定に失敗しました。デフォルト速度で読み上げを継続します。」

**システムの安全性**:
- TTSエンジンのエラーでもアプリはクラッシュしない
- 読み上げ機能は基本速度で継続動作

**テストの目的**:
- TTSエンジンエラーに対する堅牢性を確認
- 基本機能の継続動作を保証

**品質保証の観点**:
- requirements.md（333-342行目）のERROR-2に対応
- NFR-301（基本機能継続）に準拠

🟡 **信頼性レベル**: requirements.md（333-342行目）のERROR-2、既存テスト（tts_service_test.dart TC-048-011）のパターンを踏襲

---

## 3. 境界値テストケース（最小値、最大値、null等）

### TC-049-015: TTSSpeed enumの全値（slow/normal/fast）が正しく動作する

**テスト名**: TTSSpeed enumのすべての値（slow=0、normal=1、fast=2）が正しくshared_preferencesに保存・復元されることを確認
**境界値の意味**: 🔵
- enum indexの最小値（0）から最大値（2）まで
- REQ-404で定義された3段階すべて
**境界値での動作保証**: 🔵
- 3つの速度設定すべてが正常に動作することを確認

**入力値**:
```dart
final allSpeeds = [TTSSpeed.slow, TTSSpeed.normal, TTSSpeed.fast];
for (final speed in allSpeeds) {
  await notifier.setTTSSpeed(speed);
}
```

**境界値選択の根拠**: 🔵
- REQ-404で定義された3段階すべてをテスト
- enum indexの全範囲（0〜2）を網羅

**実際の使用場面**:
- ユーザーがすべての速度設定を試す場合
- 異なるコミュニケーション相手に応じて速度を切り替える場合

**期待される結果**:
- `slow`: `setSpeechRate(0.7)`が呼ばれる
- `normal`: `setSpeechRate(1.0)`が呼ばれる
- `fast`: `setSpeechRate(1.3)`が呼ばれる
- すべての値がshared_preferencesに正しく保存・復元される

**境界での正確性**:
- 最小速度（0.7）と最大速度（1.3）が正しく設定される
- flutter_ttsの速度範囲（0.5〜2.0）内に収まる

**一貫した動作**:
- 3つの速度設定すべてで同じ保存・復元ロジックが動作する

**テストの目的**:
- すべての速度設定が正常に動作することを確認
- enum境界値の安全性を保証

**堅牢性の確認**:
- 極端な速度値でもシステムが安定動作する

🔵 **信頼性レベル**: REQ-404、interfaces.dart（298-319行目）、既存テスト（settings_provider_test.dart TC-015、TC-016）のパターンに基づく

---

### TC-049-016: shared_preferencesに速度設定が存在しない場合、デフォルト値（normal）を使用

**テスト名**: shared_preferencesに'tts_speed'キーが存在しない場合、デフォルト値（normal）が使用されることを確認
**境界値の意味**: 🔵
- 未設定状態（null）からの初回設定
- アプリ初回起動時の状態
**境界値での動作保証**: 🔵
- データが存在しない場合の安全なフォールバック

**入力値**:
```dart
SharedPreferences.setMockInitialValues({}); // 'tts_speed'キーなし
container = ProviderContainer();
```

**境界値選択の根拠**: 🔵
- アプリ初回起動時の状態を模擬
- null安全性の確認

**実際の使用場面**:
- アプリ初回起動
- アンインストール後の再インストール
- ストレージクリア後

**期待される結果**:
- `settings.ttsSpeed == TTSSpeed.normal`
- エラーは発生しない

**境界での正確性**:
- nullチェックが正しく機能する
- Dart Null Safetyの`??`演算子による安全なフォールバック

**一貫した動作**:
- 未設定とnormalを明示的に設定した場合で、同じ動作となる

**テストの目的**:
- null安全性を確認
- 初回起動時の動作を保証

**堅牢性の確認**:
- データが存在しない極端な条件でも安定動作する

🔵 **信頼性レベル**: Dart Null Safetyの基本動作、既存テスト（settings_provider_test.dart TC-014）のパターンに基づく

---

### TC-049-017: 読み上げ中に速度を変更しても、現在の読み上げは元の速度で継続

**テスト名**: 読み上げ中に速度を変更した場合、現在の読み上げは元の速度で継続し、次回の読み上げから新しい速度が適用されることを確認
**境界値の意味**: 🟡
- 状態遷移の境界（speaking状態での速度変更）
- 並行処理のエッジケース
**境界値での動作保証**: 🟡
- 読み上げ中でも安全に速度変更できることを確認

**入力値**:
```dart
await ttsNotifier.speak('長いテキスト...');
await settingsNotifier.setTTSSpeed(TTSSpeed.fast); // 読み上げ中に変更
await ttsNotifier.speak('次のテキスト'); // 次回の読み上げ
```

**境界値選択の根拠**: 🟡
- requirements.md（286-296行目）のEDGE-1に基づく
- 並行処理の安全性を確認

**実際の使用場面**:
- ユーザーが読み上げ中に「速すぎる」と感じて速度を変更する場合
- 読み上げ途中で設定画面を開く場合

**期待される結果**:
- 現在の読み上げは元の速度で継続
- 次回の読み上げから新しい速度が適用される
- エラーは発生しない

**境界での正確性**:
- 読み上げ中の速度変更が安全に処理される
- 状態遷移が正しく管理される

**一貫した動作**:
- 速度変更タイミングに関わらず、一貫した動作を保つ

**テストの目的**:
- 並行処理の安全性を確認
- 状態遷移の境界での動作を保証

**堅牢性の確認**:
- 競合状態でもシステムが安定動作する

🟡 **信頼性レベル**: requirements.md（286-296行目）のEDGE-1、防御的プログラミングの原則に基づく

---

## 4. ウィジェットテストケース（UI）

### TC-049-018: TTS速度設定UIが表示される

**テスト名**: 設定画面にTTS速度設定セクションが表示されることを確認
**何をテストするか**: 🔵
- 設定画面にTTS速度設定のウィジェットが含まれる
- 3つの選択肢（遅い/普通/速い）がすべて表示される
**期待される動作**: 🔵
- 「読み上げ速度」というラベルが表示される
- 3つのラジオボタンまたはセグメントコントロールが表示される

**入力値**:
```dart
await tester.pumpWidget(ProviderScope(
  child: MaterialApp(home: SettingsScreen()),
));
```

**入力データの意味**:
- ユーザーが設定画面を開いた場合を模擬

**期待される結果**:
- `find.text('読み上げ速度')` が見つかる
- `find.text('遅い')` が見つかる
- `find.text('普通')` が見つかる
- `find.text('速い')` が見つかる

**期待結果の理由**: 🔵
- requirements.md（96-101行目）のUI表示仕様に基づく

**テストの目的**:
- 設定UIが正しく表示されることを確認
- ユーザーが速度を選択できることを保証

**確認ポイント**:
- すべての選択肢が表示される
- アクセシビリティを考慮した表示（最小タップサイズ44px以上）

🔵 **信頼性レベル**: requirements.md（96-101行目）、アクセシビリティ要件に基づく

---

### TC-049-019: 現在選択されている速度がハイライト表示される

**テスト名**: 現在のTTS速度設定がUIでハイライト表示されることを確認
**何をテストするか**: 🔵
- 現在の速度設定（fast）がUI上で選択状態として表示される
**期待される動作**: 🔵
- 選択中の速度ボタンが視覚的に区別される（背景色、ボーダー等）

**入力値**:
```dart
final container = ProviderContainer(
  overrides: [
    settingsNotifierProvider.overrideWith(
      (ref) => AsyncValue.data(AppSettings(ttsSpeed: TTSSpeed.fast)),
    ),
  ],
);
await tester.pumpWidget(UncontrolledProviderScope(
  container: container,
  child: MaterialApp(home: SettingsScreen()),
));
```

**入力データの意味**:
- ユーザーが既に速度を「速い」に設定している状態を模擬

**期待される結果**:
- 「速い」ボタンが選択状態で表示される
- ラジオボタンがチェックされている、またはセグメントコントロールがハイライトされている

**期待結果の理由**: 🔵
- ユーザーが現在の設定を視覚的に確認できる必要がある

**テストの目的**:
- 現在の設定が視覚的に明確であることを確認
- ユーザーが混乱しないUIを保証

**確認ポイント**:
- 選択状態が視覚的に明確
- アクセシビリティ（WCAG 2.1 AAレベル準拠）

🔵 **信頼性レベル**: 既存ウィジェットテスト（settings_screen_test.dart）のパターン、アクセシビリティ要件に基づく

---

### TC-049-020: 速度ボタンをタップすると速度が変更される

**テスト名**: ユーザーが「遅い」ボタンをタップすると、速度が変更されることを確認
**何をテストするか**: 🔵
- ユーザー操作（タップ）に対する応答
- AppSettings状態の更新
**期待される動作**: 🔵
- タップ後、AppSettings.ttsSpeedが`TTSSpeed.slow`に更新される

**入力値**:
```dart
await tester.tap(find.text('遅い'));
await tester.pumpAndSettle();
```

**入力データの意味**:
- ユーザーが設定画面で「遅い」を選択した場合を模擬

**期待される結果**:
- `container.read(settingsNotifierProvider).requireValue.ttsSpeed == TTSSpeed.slow`
- UIが更新され、「遅い」が選択状態になる

**期待結果の理由**: 🔵
- REQ-2007（即座反映）を参考にしたUI応答性

**テストの目的**:
- ユーザー操作が正しく処理されることを確認
- UI応答性を保証

**確認ポイント**:
- タップ応答が100ms以内（パフォーマンス要件）
- 状態更新がUIに即座に反映される

🔵 **信頼性レベル**: REQ-2007を参考、既存ウィジェットテスト（settings_screen_test.dart）のパターンに基づく

---

## テスト実装時の日本語コメント指針

### テストケース開始時のコメント

```dart
// 【テスト目的】: TTS速度設定がデフォルト値（normal）であることを確認
// 【テスト内容】: AppSettingsをデフォルトコンストラクタで初期化し、ttsSpeedフィールドを検証
// 【期待される動作】: ttsSpeed == TTSSpeed.normal（1.0倍速）
// 🔵 信頼性レベル: interfaces.dart（213-274行目）、requirements.md（79-84行目）に基づく
```

### Given（準備フェーズ）のコメント

```dart
// 【テストデータ準備】: アプリ初回起動時の状態を模擬（shared_preferencesが空）
// 【初期条件設定】: ProviderContainerを作成し、クリーンな状態から開始
// 【前提条件確認】: TTS速度が未設定であることを確認
```

### When（実行フェーズ）のコメント

```dart
// 【実際の処理実行】: setTTSSpeed(TTSSpeed.slow)を呼び出す
// 【処理内容】: ユーザーが設定画面で「遅い」を選択したときの処理を実行
// 【実行タイミング】: ユーザーが速度変更ボタンをタップしたとき
```

### Then（検証フェーズ）のコメント

```dart
// 【結果検証】: ttsSpeedがslowに変更されたことを確認
// 【期待値確認】: REQ-404の3段階選択要件を満たすため
// 【品質保証】: ユーザーの速度設定が正しく反映されることを保証
```

### 各expectステートメントのコメント

```dart
expect(settings.ttsSpeed, TTSSpeed.slow); // 【確認内容】: 速度が「遅い」に変更されたことを確認 🔵
expect(prefs.getString('tts_speed'), 'slow'); // 【確認内容】: shared_preferencesに正しく保存されたことを確認 🔵
expect(ttsState.currentSpeed, TTSSpeed.slow); // 【確認内容】: TTSエンジンに速度変更が反映されたことを確認 🔵
```

---

## テストカバレッジ目標

### 全体カバレッジ
- **目標**: 80%以上（NFR-501）
- **対象**: 新規作成コード（AppSettings.ttsSpeedフィールド、SettingsNotifier.setTTSSpeed()、UI）

### ビジネスロジックカバレッジ
- **目標**: 90%以上（NFR-502）
- **対象**: SettingsNotifier.setTTSSpeed()、AppSettings.toJson()/fromJson()

### UI層カバレッジ
- **目標**: 70%以上
- **対象**: TTS速度設定UIウィジェット

---

## テスト実施順序

### Phase 1: 単体テスト（Unit Test）
1. TC-049-001〜TC-049-005: AppSettingsの基本動作
2. TC-049-011、TC-049-016: エラーハンドリング、境界値

### Phase 2: 状態管理テスト
1. TC-049-006: SettingsNotifier→TTSNotifierの連携
2. TC-049-012〜TC-049-014: エラーハンドリング

### Phase 3: ウィジェットテスト
1. TC-049-018〜TC-049-020: UI表示、ユーザー操作

### Phase 4: 統合テスト
1. TC-049-007〜TC-049-010: エンドツーエンドのフロー
2. TC-049-015、TC-049-017: 境界値、エッジケース

---

## 品質判定

### ✅ 高品質

**テストケース分類**: ✅
- 正常系: 10ケース（TC-049-001〜010）
- 異常系: 4ケース（TC-049-011〜014）
- 境界値: 3ケース（TC-049-015〜017）
- UI: 3ケース（TC-049-018〜020）
- **合計**: 20テストケース

**期待値定義**: ✅
- 各テストケースで入力値、期待される結果、テストの目的を明確に定義
- 🔵（青信号）: 要件定義書ベース - 12ケース
- 🟡（黄信号）: 妥当な推測 - 8ケース

**技術選択**: ✅
- プログラミング言語: Dart（Flutterアプリケーションの標準言語）
- テストフレームワーク: flutter_test + Riverpod Testing + Mocktail
- 既存テスト（TASK-0048、TASK-0013）と同じパターンを踏襲

**実装可能性**: ✅
- TASK-0048で`TTSSpeed` enum、`TTSService.setSpeed()`は既に実装済み
- TASK-0013で`AppSettings`、`SettingsNotifier`のパターンは確立済み
- 新規実装は`AppSettings.ttsSpeed`フィールドとUIのみ

---

## 次のステップ

**次のお勧めステップ**: `/tsumiki:tdd-red` でRedフェーズ（失敗テスト作成）を開始します。

**実装順序**:
1. **Red**: 上記20テストケースを実装（すべて失敗するはず）
2. **Green**: 最小限の実装でテストを通す
3. **Refactor**: コード品質の改善

**参照資料**:
- requirements.md: TASK-0049の要件定義
- interfaces.dart: TTSSpeed enum、AppSettings定義
- 既存テスト: tts_service_test.dart（TASK-0048）、settings_provider_test.dart（TASK-0013）

---

## 更新履歴

- **2025-11-25**: 初版作成（/tsumiki:tdd-testcases コマンド実行）
  - 20テストケースを定義（正常系10、異常系4、境界値3、UI 3）
  - 既存実装（TASK-0048、TASK-0013）を参照
  - REQ-404、interfaces.dart、requirements.mdに基づく
