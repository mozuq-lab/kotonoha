# TASK-0070: AI変換Provider・状態管理 テストケース

## テストケース一覧

### カテゴリ1: 初期状態・基本動作

#### TC-070-001: 初期状態がidleである
- **前提条件**: AIConversionNotifierが初期化される
- **入力**: なし
- **期待結果**:
  - status == AIConversionStatus.idle
  - originalText == null
  - convertedText == null
  - politenessLevel == null
  - error == null
  - isConverting == false
  - hasResult == false
  - hasError == false

#### TC-070-002: 状態がAIConversionState.initialと等しい
- **前提条件**: AIConversionNotifierが初期化される
- **入力**: なし
- **期待結果**: state == AIConversionState.initial

### カテゴリ2: 変換処理（convert）

#### TC-070-003: convert呼び出しで状態がconvertingになる
- **前提条件**:
  - AIConversionNotifierが初期化されている
  - ネットワークがオンライン
- **入力**: convert(inputText: 'テスト', politenessLevel: PolitenessLevel.polite)
- **期待結果**:
  - status == AIConversionStatus.converting
  - isConverting == true
  - originalText == 'テスト'
  - politenessLevel == PolitenessLevel.polite

#### TC-070-004: convert成功で状態がsuccessになり結果が設定される
- **前提条件**:
  - AIConversionNotifierが初期化されている
  - ネットワークがオンライン
  - APIクライアントが成功レスポンスを返す
- **入力**: convert(inputText: '水 ぬるく', politenessLevel: PolitenessLevel.polite)
- **期待結果**:
  - status == AIConversionStatus.success
  - hasResult == true
  - originalText == '水 ぬるく'
  - convertedText == 'お水をぬるめでお願いします'（モック値）
  - politenessLevel == PolitenessLevel.polite
  - error == null

#### TC-070-005: convert失敗で状態がerrorになり例外が設定される
- **前提条件**:
  - AIConversionNotifierが初期化されている
  - ネットワークがオンライン
  - APIクライアントがAIConversionExceptionをスロー
- **入力**: convert(inputText: 'エラーテスト', politenessLevel: PolitenessLevel.normal)
- **期待結果**:
  - status == AIConversionStatus.error
  - hasError == true
  - error != null
  - error.code == 'AI_API_ERROR'
  - convertedText == null

#### TC-070-006: オフライン時のconvertでエラー状態になる
- **前提条件**:
  - AIConversionNotifierが初期化されている
  - ネットワークがオフライン
- **入力**: convert(inputText: 'テスト', politenessLevel: PolitenessLevel.casual)
- **期待結果**:
  - status == AIConversionStatus.error
  - hasError == true
  - error != null
  - error.code == 'NETWORK_ERROR'

#### TC-070-007: 丁寧さレベルcasualでの変換
- **前提条件**:
  - ネットワークがオンライン
  - APIクライアントが成功レスポンスを返す
- **入力**: convert(inputText: 'ありがとう', politenessLevel: PolitenessLevel.casual)
- **期待結果**:
  - status == AIConversionStatus.success
  - politenessLevel == PolitenessLevel.casual

#### TC-070-008: 丁寧さレベルnormalでの変換
- **前提条件**:
  - ネットワークがオンライン
  - APIクライアントが成功レスポンスを返す
- **入力**: convert(inputText: 'ありがとう', politenessLevel: PolitenessLevel.normal)
- **期待結果**:
  - status == AIConversionStatus.success
  - politenessLevel == PolitenessLevel.normal

#### TC-070-009: 丁寧さレベルpoliteでの変換
- **前提条件**:
  - ネットワークがオンライン
  - APIクライアントが成功レスポンスを返す
- **入力**: convert(inputText: 'ありがとう', politenessLevel: PolitenessLevel.polite)
- **期待結果**:
  - status == AIConversionStatus.success
  - politenessLevel == PolitenessLevel.polite

### カテゴリ3: 再生成処理（regenerate）

#### TC-070-010: regenerateで前回の情報を使用して再変換が実行される
- **前提条件**:
  - 前回のconvertが成功し、状態がsuccessである
  - originalText = '水 ぬるく'
  - convertedText = 'お水をぬるめでお願いします'
  - politenessLevel = PolitenessLevel.polite
- **入力**: regenerate()
- **期待結果**:
  - APIクライアントのregenerate()が呼ばれる
  - 前回のoriginalText, politenessLevel, convertedTextが引数として渡される
  - 成功時: status == AIConversionStatus.success
  - 新しいconvertedTextが設定される

#### TC-070-011: regenerate成功で新しい変換結果が設定される
- **前提条件**:
  - 前回のconvertが成功している
  - APIクライアントが新しい結果を返す
- **入力**: regenerate()
- **期待結果**:
  - status == AIConversionStatus.success
  - convertedTextが新しい値に更新される
  - originalTextは変わらない
  - politenessLevelは変わらない

#### TC-070-012: 結果がない状態でregenerateを呼び出した場合
- **前提条件**:
  - 状態がidle（前回の変換結果がない）
- **入力**: regenerate()
- **期待結果**:
  - 何も実行されない（状態が変わらない）
  - または適切なエラー状態になる

### カテゴリ4: 状態クリア（clear）

#### TC-070-013: clearで状態がidleに戻る
- **前提条件**:
  - 状態がsuccess（変換結果がある）
- **入力**: clear()
- **期待結果**:
  - status == AIConversionStatus.idle
  - originalText == null
  - convertedText == null
  - politenessLevel == null
  - error == null

#### TC-070-014: エラー状態からclearでidleに戻る
- **前提条件**:
  - 状態がerror
- **入力**: clear()
- **期待結果**:
  - status == AIConversionStatus.idle
  - error == null

#### TC-070-015: 変換中にclearを呼び出した場合
- **前提条件**:
  - 状態がconverting
- **入力**: clear()
- **期待結果**:
  - status == AIConversionStatus.idle
  - （進行中の変換は完了してもstateが更新されない）

### カテゴリ5: 状態遷移

#### TC-070-016: idle → converting → success → idle (clear)
- **前提条件**: AIConversionNotifierが初期化されている
- **入力**:
  1. convert(inputText: 'テスト', politenessLevel: PolitenessLevel.polite)
  2. （API成功）
  3. clear()
- **期待結果**: 各ステップで正しい状態遷移が行われる

#### TC-070-017: idle → converting → error → idle (clear)
- **前提条件**: AIConversionNotifierが初期化されている、APIがエラーを返す
- **入力**:
  1. convert(inputText: 'エラー', politenessLevel: PolitenessLevel.normal)
  2. （APIエラー）
  3. clear()
- **期待結果**: 各ステップで正しい状態遷移が行われる

#### TC-070-018: success → converting → success (regenerate)
- **前提条件**: 前回のconvertが成功している
- **入力**:
  1. regenerate()
  2. （API成功）
- **期待結果**:
  - regenerate中: status == AIConversionStatus.converting
  - 完了後: status == AIConversionStatus.success

### カテゴリ6: エラーハンドリング

#### TC-070-019: タイムアウトエラー時の状態
- **前提条件**: APIクライアントがAI_API_TIMEOUTエラーをスロー
- **入力**: convert(inputText: 'テスト', politenessLevel: PolitenessLevel.polite)
- **期待結果**:
  - status == AIConversionStatus.error
  - error.code == 'AI_API_TIMEOUT'

#### TC-070-020: レート制限エラー時の状態
- **前提条件**: APIクライアントがRATE_LIMIT_EXCEEDEDエラーをスロー
- **入力**: convert(inputText: 'テスト', politenessLevel: PolitenessLevel.polite)
- **期待結果**:
  - status == AIConversionStatus.error
  - error.code == 'RATE_LIMIT_EXCEEDED'

#### TC-070-021: バリデーションエラー時の状態
- **前提条件**: APIクライアントがVALIDATION_ERRORをスロー
- **入力**: convert(inputText: 'テスト', politenessLevel: PolitenessLevel.polite)
- **期待結果**:
  - status == AIConversionStatus.error
  - error.code == 'VALIDATION_ERROR'

### カテゴリ7: AIConversionState ヘルパープロパティ

#### TC-070-022: isConvertingプロパティ
- **前提条件**: 様々な状態
- **入力**: 各状態でのisConverting確認
- **期待結果**:
  - idle: isConverting == false
  - converting: isConverting == true
  - success: isConverting == false
  - error: isConverting == false

#### TC-070-023: hasResultプロパティ
- **前提条件**: 様々な状態
- **入力**: 各状態でのhasResult確認
- **期待結果**:
  - idle: hasResult == false
  - converting: hasResult == false
  - success: hasResult == true
  - error: hasResult == false

#### TC-070-024: hasErrorプロパティ
- **前提条件**: 様々な状態
- **入力**: 各状態でのhasError確認
- **期待結果**:
  - idle: hasError == false
  - converting: hasError == false
  - success: hasError == false
  - error: hasError == true

### カテゴリ8: Provider連携

#### TC-070-025: aiConversionProviderが正しく初期化される
- **前提条件**: ProviderContainerが作成される
- **入力**: container.read(aiConversionProvider)
- **期待結果**:
  - AIConversionStateが返される
  - status == AIConversionStatus.idle

#### TC-070-026: aiConversionProvider.notifierがNotifierを返す
- **前提条件**: ProviderContainerが作成される
- **入力**: container.read(aiConversionProvider.notifier)
- **期待結果**: AIConversionNotifierが返される

#### TC-070-027: NetworkNotifierとの連携確認
- **前提条件**:
  - NetworkNotifierがoffline状態
  - aiConversionProviderが初期化されている
- **入力**: convert(inputText: 'テスト', politenessLevel: PolitenessLevel.polite)
- **期待結果**:
  - ネットワークエラーが発生
  - APIクライアントは呼ばれない

### カテゴリ9: 境界値・エッジケース

#### TC-070-028: 最小文字数（2文字）での変換
- **前提条件**: ネットワークがオンライン
- **入力**: convert(inputText: 'はい', politenessLevel: PolitenessLevel.normal)
- **期待結果**: 正常に変換が実行される

#### TC-070-029: 空文字列での変換試行
- **前提条件**: ネットワークがオンライン
- **入力**: convert(inputText: '', politenessLevel: PolitenessLevel.normal)
- **期待結果**:
  - バリデーションエラーまたは早期リターン
  - APIが呼ばれない

#### TC-070-030: 1文字での変換試行
- **前提条件**: ネットワークがオンライン
- **入力**: convert(inputText: 'あ', politenessLevel: PolitenessLevel.normal)
- **期待結果**:
  - バリデーションエラーまたはAPIに委譲
  - （API側で2文字未満はエラー）

---

## テスト実装ファイル

```
test/features/ai_conversion/providers/
├── ai_conversion_provider_test.dart     # Provider・Notifierテスト
└── ai_conversion_state_test.dart        # 状態クラステスト
```

---

## 次のステップ

次のお勧めステップ: `/tsumiki:tdd-red` で失敗するテストを実装します。
