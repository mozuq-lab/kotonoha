# TASK-0017: 共通UIコンポーネント実装（大ボタン・入力欄・緊急ボタン）要件定義書

## 概要

**タスクID**: TASK-0017
**タスク名**: 共通UIコンポーネント実装（大ボタン・入力欄・緊急ボタン）
**タスクタイプ**: TDD
**推定工数**: 8時間
**依存タスク**: TASK-0016（テーマ実装完了）
**作成日**: 2025-11-22

## 背景と目的

kotonohaアプリは、発話困難な方が「できるだけ少ない操作で、自分の言いたいことを、適切な丁寧さで、安全に伝えられる」ことを目的としています。

このタスクでは、アクセシビリティ要件（特にタップターゲットサイズ）を満たす共通UIコンポーネントを実装し、アプリ全体で再利用可能な基盤を構築します。

---

## 1. 機能要件

### 1.1 大ボタンウィジェット (LargeButton)

**配置場所**: `lib/shared/widgets/large_button.dart`

#### 1.1.1 パラメータ仕様

| パラメータ | 型 | 必須 | デフォルト値 | 説明 |
|-----------|-----|------|-------------|------|
| `label` | `String` | Yes | - | ボタンに表示するテキスト |
| `onPressed` | `VoidCallback?` | Yes | - | タップ時のコールバック（nullの場合は無効化） |
| `backgroundColor` | `Color?` | No | テーマのプライマリカラー | ボタンの背景色 |
| `textColor` | `Color?` | No | テーマの前景色 | テキストの色 |
| `width` | `double?` | No | 60.0 | ボタンの幅 |
| `height` | `double?` | No | 60.0 | ボタンの高さ |
| `enabled` | `bool` | No | true | ボタンの有効/無効状態 |

#### 1.1.2 機能要件

| 要件ID | 説明 | 関連要件 | 信頼性 |
|--------|------|----------|--------|
| LB-001 | デフォルトサイズは60px x 60px（推奨タップターゲット） | NFR-202 | 🔵 |
| LB-002 | 最小サイズは44px x 44px以上を保証 | REQ-5001 | 🔵 |
| LB-003 | タップ時に視覚的フィードバックを提供 | REQ-5005 | 🟡 |
| LB-004 | 無効状態（onPressed: null）でグレーアウト表示 | REQ-3004 | 🟡 |
| LB-005 | テーマ（ライト/ダーク/高コントラスト）に対応 | REQ-803 | 🔵 |
| LB-006 | フォントサイズ設定に追従（小/中/大） | REQ-802 | 🔵 |
| LB-007 | 角丸デザイン（borderRadius: 8.0） | - | 🟡 |

#### 1.1.3 アクセシビリティ要件

- **Semantics**: ボタンの役割とラベルを明示
- **タップ領域**: 指定サイズ全体がタップ可能領域
- **コントラスト比**: 高コントラストモードでWCAG 2.1 AA準拠（4.5:1以上）

---

### 1.2 入力欄ウィジェット (TextInputField)

**配置場所**: `lib/shared/widgets/text_input_field.dart`

#### 1.2.1 パラメータ仕様

| パラメータ | 型 | 必須 | デフォルト値 | 説明 |
|-----------|-----|------|-------------|------|
| `controller` | `TextEditingController` | Yes | - | テキスト入力を制御するコントローラー |
| `hintText` | `String?` | No | '文字を入力してください' | プレースホルダーテキスト |
| `maxLength` | `int?` | No | 1000 | 最大文字数 |
| `onClear` | `VoidCallback?` | No | null | クリアボタンタップ時のコールバック |
| `enabled` | `bool` | No | true | 入力欄の有効/無効状態 |
| `readOnly` | `bool` | No | false | 読み取り専用モード |

#### 1.2.2 機能要件

| 要件ID | 説明 | 関連要件 | 信頼性 |
|--------|------|----------|--------|
| TIF-001 | 最大文字数1000文字の制限 | EDGE-101 | 🟡 |
| TIF-002 | 文字数カウンター表示（現在/最大） | EDGE-101 | 🟡 |
| TIF-003 | クリアボタン付き（onClear指定時） | REQ-004 | 🔵 |
| TIF-004 | クリアボタンのタップターゲットは44px以上 | REQ-5001 | 🔵 |
| TIF-005 | フォントサイズはAppSizes.fontSizeLarge（24px）を使用 | REQ-801 | 🔵 |
| TIF-006 | テーマに対応した色設定 | REQ-803 | 🔵 |
| TIF-007 | 複数行入力対応（maxLines: null） | - | 🟡 |
| TIF-008 | 入力欄の最小高さは60px | NFR-202 | 🟡 |

#### 1.2.3 アクセシビリティ要件

- **Semantics**: テキストフィールドの役割を明示
- **ヒントテキスト**: 入力欄が空の場合のガイダンス表示
- **コントラスト比**: 高コントラストモードでWCAG 2.1 AA準拠

---

### 1.3 緊急ボタンウィジェット (EmergencyButton)

**配置場所**: `lib/shared/widgets/emergency_button.dart`

#### 1.3.1 パラメータ仕様

| パラメータ | 型 | 必須 | デフォルト値 | 説明 |
|-----------|-----|------|-------------|------|
| `onPressed` | `VoidCallback` | Yes | - | タップ時のコールバック |
| `size` | `double?` | No | 60.0 | ボタンのサイズ（幅・高さ） |

#### 1.3.2 機能要件

| 要件ID | 説明 | 関連要件 | 信頼性 |
|--------|------|----------|--------|
| EB-001 | 赤色（AppColors.emergency: #D32F2F）の目立つボタン | REQ-301 | 🔵 |
| EB-002 | 円形デザイン（CircleBorder） | REQ-301 | 🔵 |
| EB-003 | サイズは60px x 60px | NFR-202 | 🔵 |
| EB-004 | 常に表示される（すべての画面で利用可能） | REQ-301 | 🔵 |
| EB-005 | アイコン（notifications_active）を中央に配置 | REQ-301 | 🟡 |
| EB-006 | タップ時に視覚的フィードバックを提供 | REQ-5005 | 🟡 |
| EB-007 | 全テーマで視認性を確保 | REQ-803 | 🔵 |

#### 1.3.3 アクセシビリティ要件

- **Semantics**: 「緊急呼び出しボタン」として明示
- **タップ領域**: 60px以上の十分なタップ領域
- **視認性**: 赤色で他のボタンと明確に区別

---

## 2. 受け入れ基準

### 2.1 大ボタン (LargeButton)

| AC-ID | 受け入れ基準 | 優先度 |
|-------|-------------|--------|
| AC-LB-001 | デフォルトサイズが60px x 60pxであること | 必須 |
| AC-LB-002 | width/heightに44未満を指定しても44px以上が保証されること | 必須 |
| AC-LB-003 | labelテキストがボタン中央に表示されること | 必須 |
| AC-LB-004 | onPressedがnullの場合、ボタンがグレーアウトされ無効化されること | 必須 |
| AC-LB-005 | タップ時にElevatedButtonの標準フィードバック（リップル効果）が表示されること | 高 |
| AC-LB-006 | ライト/ダーク/高コントラストテーマで適切な色が適用されること | 高 |
| AC-LB-007 | backgroundColor/textColor指定時にカスタム色が適用されること | 高 |

### 2.2 入力欄 (TextInputField)

| AC-ID | 受け入れ基準 | 優先度 |
|-------|-------------|--------|
| AC-TIF-001 | 1000文字を超える入力が制限されること | 必須 |
| AC-TIF-002 | 入力中に文字数カウンターが表示されること | 高 |
| AC-TIF-003 | onClear指定時にクリアボタンが表示されること | 必須 |
| AC-TIF-004 | クリアボタンタップでonClearコールバックが呼ばれること | 必須 |
| AC-TIF-005 | フォントサイズが24px（fontSizeLarge）であること | 必須 |
| AC-TIF-006 | 複数行のテキスト入力が可能であること | 高 |
| AC-TIF-007 | プレースホルダー（hintText）が空の状態で表示されること | 高 |

### 2.3 緊急ボタン (EmergencyButton)

| AC-ID | 受け入れ基準 | 優先度 |
|-------|-------------|--------|
| AC-EB-001 | ボタンの背景色が赤色（#D32F2F）であること | 必須 |
| AC-EB-002 | ボタンが円形であること | 必須 |
| AC-EB-003 | デフォルトサイズが60px x 60pxであること | 必須 |
| AC-EB-004 | notifications_activeアイコンが中央に表示されること | 高 |
| AC-EB-005 | タップ時にonPressedコールバックが呼ばれること | 必須 |
| AC-EB-006 | アイコンの色が白色であること | 高 |

---

## 3. 技術的制約

### 3.1 Flutter/Dart制約

- **Flutter**: 3.38.1以上
- **Dart**: 3.10以上
- **パッケージ依存**: flutter_riverpod 2.x

### 3.2 既存コンポーネントとの整合性

| 参照先 | ファイル | 使用項目 |
|--------|---------|---------|
| サイズ定数 | `lib/core/constants/app_sizes.dart` | minTapTarget(44), recommendedTapTarget(60), fontSizeLarge(24) |
| 色定数 | `lib/core/constants/app_colors.dart` | emergency(#D32F2F), primary各テーマ |
| テーマ | `lib/core/themes/*.dart` | ライト/ダーク/高コントラストテーマ |

### 3.3 アクセシビリティ制約

- **WCAG 2.1 AA準拠**: 高コントラストモードでコントラスト比4.5:1以上
- **タップターゲット**: すべてのインタラクティブ要素は44px x 44px以上

---

## 4. テスト観点

### 4.1 大ボタン (LargeButton) テストケース

| TC-ID | カテゴリ | テストケース | 期待結果 |
|-------|---------|-------------|----------|
| TC-LB-001 | レンダリング | labelテキストが正しく表示される | 指定したlabelがボタン上に表示される |
| TC-LB-002 | レンダリング | デフォルトサイズが60x60pxである | SizedBoxのwidth/heightが60.0 |
| TC-LB-003 | サイズ | カスタムサイズが適用される | 指定したwidth/heightが適用される |
| TC-LB-004 | サイズ | 44px未満を指定しても44px以上が保証される | width/heightが44.0以上になる |
| TC-LB-005 | イベント | タップ時にonPressedが呼ばれる | コールバック関数が実行される |
| TC-LB-006 | 状態 | onPressed: nullで無効状態になる | ボタンがタップ不可になる |
| TC-LB-007 | スタイル | backgroundColorが適用される | 指定した背景色が表示される |
| TC-LB-008 | スタイル | textColorが適用される | 指定したテキスト色が表示される |
| TC-LB-009 | テーマ | ライトテーマで適切な色が使用される | テーマのプライマリカラーが適用される |
| TC-LB-010 | テーマ | ダークテーマで適切な色が使用される | テーマのプライマリカラーが適用される |
| TC-LB-011 | テーマ | 高コントラストテーマで適切な色が使用される | 高コントラストカラーが適用される |
| TC-LB-012 | アクセシビリティ | Semanticsラベルが設定される | ボタンの役割が明示される |

### 4.2 入力欄 (TextInputField) テストケース

| TC-ID | カテゴリ | テストケース | 期待結果 |
|-------|---------|-------------|----------|
| TC-TIF-001 | レンダリング | TextFieldが正しく表示される | 入力欄がレンダリングされる |
| TC-TIF-002 | レンダリング | hintTextが表示される | 空の状態でプレースホルダーが表示される |
| TC-TIF-003 | 入力 | テキスト入力ができる | controllerにテキストが反映される |
| TC-TIF-004 | 入力 | 1000文字まで入力できる | 1000文字入力が受け付けられる |
| TC-TIF-005 | 入力 | 1001文字以上は入力できない | 1000文字で入力が制限される |
| TC-TIF-006 | クリア | onClear指定時にクリアボタンが表示される | IconButton(clear)が表示される |
| TC-TIF-007 | クリア | クリアボタンタップでonClearが呼ばれる | コールバック関数が実行される |
| TC-TIF-008 | クリア | onClear未指定時はクリアボタンが非表示 | クリアボタンが表示されない |
| TC-TIF-009 | スタイル | フォントサイズが24pxである | textStyle.fontSizeが24.0 |
| TC-TIF-010 | スタイル | 複数行入力が可能である | maxLinesがnullで複数行入力可能 |
| TC-TIF-011 | 状態 | enabled: falseで無効化される | 入力が不可になる |
| TC-TIF-012 | 状態 | readOnly: trueで読み取り専用になる | 入力は不可だが選択は可能 |
| TC-TIF-013 | カウンター | 文字数カウンターが表示される | 現在文字数/最大文字数が表示される |

### 4.3 緊急ボタン (EmergencyButton) テストケース

| TC-ID | カテゴリ | テストケース | 期待結果 |
|-------|---------|-------------|----------|
| TC-EB-001 | レンダリング | ボタンが円形で表示される | CircleBorderのshapeが適用される |
| TC-EB-002 | レンダリング | 背景色が赤色である | backgroundColor = AppColors.emergency |
| TC-EB-003 | レンダリング | サイズが60x60pxである | SizedBoxのwidth/heightが60.0 |
| TC-EB-004 | レンダリング | アイコンが表示される | notifications_activeアイコンが表示される |
| TC-EB-005 | レンダリング | アイコンの色が白である | foregroundColorがColors.white |
| TC-EB-006 | イベント | タップ時にonPressedが呼ばれる | コールバック関数が実行される |
| TC-EB-007 | サイズ | カスタムサイズが適用される | 指定したsizeが適用される |
| TC-EB-008 | アクセシビリティ | Semanticsラベルが「緊急呼び出しボタン」である | 適切なラベルが設定される |

---

## 5. 実装ファイル一覧

### 5.1 ウィジェットファイル

| ファイルパス | 説明 |
|------------|------|
| `lib/shared/widgets/large_button.dart` | 大ボタンウィジェット |
| `lib/shared/widgets/text_input_field.dart` | 入力欄ウィジェット |
| `lib/shared/widgets/emergency_button.dart` | 緊急ボタンウィジェット |

### 5.2 テストファイル

| ファイルパス | 説明 |
|------------|------|
| `test/shared/widgets/large_button_test.dart` | 大ボタンテスト |
| `test/shared/widgets/text_input_field_test.dart` | 入力欄テスト |
| `test/shared/widgets/emergency_button_test.dart` | 緊急ボタンテスト |

---

## 6. 関連要件トレーサビリティ

| 実装項目 | 関連要件ID | 要件概要 |
|---------|-----------|---------|
| LargeButton | REQ-5001 | タップターゲット44px以上 |
| LargeButton | NFR-202 | ボタンサイズ60px推奨 |
| LargeButton | REQ-5005 | タップ主体の操作 |
| TextInputField | EDGE-101 | 入力欄1000文字制限 |
| TextInputField | REQ-004 | 全消去機能 |
| TextInputField | REQ-801 | フォントサイズ設定 |
| EmergencyButton | REQ-301 | 緊急ボタン常時表示 |
| EmergencyButton | REQ-304 | 緊急時の目立つ表示 |
| 全ウィジェット | REQ-803 | 3テーマ対応 |
| 全ウィジェット | REQ-5006 | WCAG 2.1 AA準拠 |

---

## 7. 完了条件

- [ ] 大ボタンウィジェット（LargeButton）が実装されている
- [ ] 入力欄ウィジェット（TextInputField）が実装されている
- [ ] 緊急ボタンウィジェット（EmergencyButton）が実装されている
- [ ] すべてのウィジェットでタップターゲットサイズ要件（44px以上）を満たしている
- [ ] すべてのウィジェットが3つのテーマ（ライト/ダーク/高コントラスト）に対応している
- [ ] 高コントラストモードでWCAG 2.1 AA準拠のコントラスト比が確保されている
- [ ] 全テストケースが成功している（TC-LB-*, TC-TIF-*, TC-EB-*）
- [ ] `flutter analyze`でエラーがない
- [ ] コードがflutter_lints準拠である

---

## 8. 参考資料

- [WCAG 2.1 達成基準 2.5.5: ターゲットサイズ](https://www.w3.org/WAI/WCAG21/Understanding/target-size.html)
- [Flutter アクセシビリティガイド](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [要件定義書](../../../spec/kotonoha-requirements.md)
- [受け入れ基準](../../../spec/kotonoha-acceptance-criteria.md)
- [技術設計書 - インターフェース](../../../design/kotonoha/interfaces.dart)
