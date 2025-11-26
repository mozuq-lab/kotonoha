# 180度画面回転機能 要件定義書

## TASK-0053: 180度画面回転機能実装

**作成日**: 2025-11-26
**タスクタイプ**: TDD
**推定工数**: 8時間
**関連要件**: REQ-502
**依存タスク**: TASK-0052 (対面表示モード) - 完了済み

---

## 1. 機能の概要（EARS要件定義書・設計文書ベース）

### 1.1 何をする機能か 🔵

180度画面回転機能は、発話困難な方が対面のコミュニケーション相手（家族・介護者・医療従事者）にメッセージを見せる際、タブレットを物理的に回転させることなく、ソフトウェア的に画面を180度回転させる機能。

**ユーザストーリー**:
- 発話困難なユーザーとして、タブレットを物理的に回転させずに、対面の相手に画面を正しい向きで見せたい
- 対面の相手が読みやすいように、画面全体を180度反転させたい
- 病院・介護施設等で、タブレットを固定したまま（マウントされている状態）でも対面表示したい

### 1.2 どのような問題を解決するか 🔵

- **物理的な回転が困難**: ユーザーが身体的制約により、タブレットを物理的に回転させることが難しい
- **タブレット固定時の対応**: 介護ベッドやスタンドに固定されたタブレットでは物理回転が不可能
- **安定性の確保**: 重いタブレット（9.7インチ以上）を持ち上げて回転させる動作は、ユーザーの負担になる
- **OSの自動回転の制限**: OS標準の画面回転（縦横切り替え）では180度回転ができない

### 1.3 想定されるユーザー 🔵

- **主利用者**: 発話困難な方（脳梗塞・ALS・筋疾患等）
  - 特に、上肢の運動機能に制約があり、タブレットを持ち上げて回転させることが困難な方
- **対面の相手**: 家族、介護施設スタッフ、病院の医師・看護師
- **利用環境**: タブレットがベッドサイドスタンドや車椅子マウントに固定されている場合

### 1.4 システム内での位置づけ 🔵

- InputScreenState内の`isRotated180`フラグで状態管理
- 対面表示モード（TASK-0052）と組み合わせて使用可能
- Transform.rotate()を使用してUI全体を回転
- 対面表示モードと独立して利用可能

**参照したEARS要件**:
- REQ-502: 画面を180度回転させて対面の相手から読みやすい表示に切り替える機能を提供しなければならない
- REQ-503: 通常モードと対面表示モードをシンプルな操作で切り替えられなければならない（回転にも適用）

**参照した設計文書**:
- `docs/design/kotonoha/interfaces.dart` - InputScreenState（isRotated180フラグ）
- `docs/design/kotonoha/dataflow.md` - 対面表示モード切り替えフロー
- `docs/design/kotonoha/architecture.md` - オフラインファースト設計

---

## 2. 入力・出力の仕様（EARS機能要件・TypeScript型定義ベース）

### 2.1 入力パラメータ 🔵

| パラメータ名 | 型 | 説明 | 制約 |
|------------|------|------|------|
| `isRotated180` | `bool` | 180度回転が有効かどうか | true/false |
| `currentScreenContent` | `Widget` | 現在表示している画面コンテンツ | すべてのウィジェット |

### 2.2 出力値 🔵

| 出力 | 型 | 説明 |
|------|------|------|
| 回転後の画面 | `Widget` | Transform.rotate()でラップされた画面 |
| 回転状態変更通知 | `StateNotifier` | UI更新用 |

### 2.3 データフロー 🔵

```mermaid
flowchart TD
    Start([通常モード])
    Start --> RotateBtn[180度回転ボタンタップ]
    RotateBtn --> ApplyTransform[Transform.rotate(π) 適用]

    ApplyTransform --> Rotated[画面180度回転状態]

    Rotated --> RotateAgain[再度回転ボタンタップ]
    RotateAgain --> RemoveTransform[Transform解除]
    RemoveTransform --> Start

    Rotated --> FaceBtn[対面表示ボタンタップ]
    FaceBtn --> FaceRotated[対面表示+回転状態]

    FaceRotated --> RotateInFace[回転ボタンタップ]
    RotateInFace --> FaceNormal[対面表示（回転なし）]
```

**参照したEARS要件**: REQ-502, REQ-503
**参照した設計文書**: `docs/design/kotonoha/dataflow.md` - 対面表示モード切り替え

---

## 3. 制約条件（EARS非機能要件・アーキテクチャ設計ベース）

### 3.1 パフォーマンス要件 🟡

| 項目 | 要件 | 根拠 |
|------|------|------|
| 回転応答時間 | 100ms以内 | NFR-003（文字盤タップ応答）から推測 |
| 回転アニメーション | スムーズな遷移 | ユーザビリティの観点 |
| メモリ使用量 | 追加メモリを最小限に | NFR-301（基本機能の継続性） |

### 3.2 アクセシビリティ要件 🔵

| 項目 | 要件 | 根拠 |
|------|------|------|
| 回転ボタンサイズ | 44px × 44px以上 | REQ-5001 |
| 高コントラスト対応 | WCAG 2.1 AA（4.5:1以上） | REQ-5006 |
| 明確なアイコン | 回転を示す視覚的に分かりやすいアイコン | NFR-202 |

### 3.3 UI/UX要件 🔵

| 項目 | 要件 | 根拠 |
|------|------|------|
| 回転の中心点 | 画面の中心 | 自然な回転動作 |
| ボタンの配置 | 回転後もアクセス可能な位置 | 回転後の操作性確保（完了条件） |
| 視覚的フィードバック | ボタン押下時の視覚的な変化 | NFR-202 |
| 状態表示 | 回転状態が分かるUI | ユーザー混乱防止 |

### 3.4 技術的制約 🔵

- **Flutterのみ対応**: ネイティブOS機能には依存しない
- **Transform.rotate()使用**: math.pi (180度) を使用
- **すべての画面で動作**: 入力画面、対面表示画面の両方で機能
- **オフライン動作**: ネットワーク接続不要

### 3.5 アーキテクチャ制約 🔵

- Riverpod StateNotifierパターンで状態管理
- InputScreenStateの`isRotated180`フラグを使用
- 既存のテーマシステム（ライト/ダーク/高コントラスト）に対応
- 対面表示モード（`isFaceToFaceMode`）と独立して動作

**参照したEARS要件**: REQ-5001, REQ-5006, NFR-003, NFR-202, NFR-301
**参照した設計文書**: `docs/design/kotonoha/architecture.md`

---

## 4. 想定される使用例（EARSエッジケース・データフローベース）

### 4.1 基本的な使用パターン 🔵

**ユースケース1: 通常モードで180度回転**
```
1. ユーザーが文字盤で「お水をください」と入力
2. 180度回転ボタンをタップ
3. 画面全体が180度回転し、対面の相手から正しく読める
4. 相手がメッセージを読む
5. 再度回転ボタンをタップして元に戻る
```

**ユースケース2: 対面表示モード + 180度回転**
```
1. ユーザーがテキストを入力
2. 対面表示ボタンをタップして拡大表示
3. さらに180度回転ボタンをタップ
4. 拡大表示されたテキストが180度回転
5. 相手が大きく読みやすい状態でメッセージを読む
```

**ユースケース3: タブレット固定時の使用**
```
1. タブレットがベッドサイドスタンドに固定されている
2. ユーザーがメッセージを入力
3. 180度回転ボタンをタップ
4. 物理的に回転させずに、ベッド側から見て正しい向きで表示
5. 看護師がメッセージを読む
```

### 4.2 エッジケース 🟡

| ケース | 動作 | 根拠 |
|--------|------|------|
| 回転中に新しい入力 | 回転状態を維持しつつ、入力を反映 | 推測 |
| 回転中に画面遷移 | 次の画面でも回転状態を維持 | 🔴 完全な推測 |
| 回転中にアプリがバックグラウンド | 復帰時に回転状態を復元 | EDGE-201から推測 |
| 高速連続タップ | 連打しても正常動作（デバウンス処理） | 推測 |
| OS画面回転ロック時 | 影響なく動作（独立した回転処理） | 推測 |

### 4.3 エラーケース 🟡

| ケース | 動作 |
|--------|------|
| メモリ不足時 | 通常モードにフォールバック |
| 描画エラー | 元の状態に復帰、エラーログ記録 |
| 回転アニメーション失敗 | 即座に回転後の状態を表示 |

**参照したEARS要件**: EDGE-201
**参照した設計文書**: `docs/design/kotonoha/dataflow.md`

---

## 5. 実装コンポーネント設計 🔵

### 5.1 ディレクトリ構造

```
lib/features/face_to_face/
├── domain/
│   └── models/
│       └── face_to_face_state.dart      # isRotated180フラグ追加
├── presentation/
│   └── widgets/
│       ├── rotation_toggle_button.dart  # 180度回転ボタン（新規）
│       └── rotated_wrapper.dart         # 回転Transformラッパー（新規）
└── providers/
    └── face_to_face_provider.dart       # 回転状態管理追加
```

### 5.2 主要クラス

#### FaceToFaceState（拡張） 🔵
```dart
/// 対面表示モードの状態
class FaceToFaceState {
  /// 対面表示モードが有効かどうか
  final bool isEnabled;

  /// 表示するテキスト
  final String displayText;

  /// 180度回転が有効かどうか（追加）
  final bool isRotated180;

  const FaceToFaceState({
    this.isEnabled = false,
    this.displayText = '',
    this.isRotated180 = false, // デフォルトは回転なし
  });
}
```

#### RotationToggleButton 🔵
- 44px × 44px以上のタップターゲット
- 回転アイコン（例: `Icons.rotate_90_degrees_ccw` または `Icons.screen_rotation`）
- タップで回転状態をトグル
- 回転状態に応じてアイコンの色や状態を変更

#### RotatedWrapper 🔵
```dart
/// 180度回転をラップするウィジェット
class RotatedWrapper extends StatelessWidget {
  final bool isRotated;
  final Widget child;

  const RotatedWrapper({
    required this.isRotated,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isRotated) {
      return child;
    }

    return Transform.rotate(
      angle: math.pi, // 180度回転
      child: child,
    );
  }
}
```

### 5.3 Riverpodプロバイダー設計（拡張） 🔵

```dart
/// 対面表示状態管理（拡張）
class FaceToFaceNotifier extends StateNotifier<FaceToFaceState> {
  FaceToFaceNotifier() : super(const FaceToFaceState());

  /// 対面表示モードを有効化
  void enableFaceToFace(String text);

  /// 対面表示モードを無効化
  void disableFaceToFace();

  /// 表示テキストを更新
  void updateText(String text);

  /// 180度回転をトグル（新規）
  void toggleRotation() {
    state = state.copyWith(
      isRotated180: !state.isRotated180,
    );
  }

  /// 180度回転を有効化（新規）
  void enableRotation() {
    state = state.copyWith(isRotated180: true);
  }

  /// 180度回転を無効化（新規）
  void disableRotation() {
    state = state.copyWith(isRotated180: false);
  }
}
```

### 5.4 技術的実装詳細 🔵

#### Transform.rotate()の使用方法
```dart
Transform.rotate(
  angle: math.pi, // 180度（ラジアン）
  alignment: Alignment.center, // 中心を軸に回転
  child: child,
)
```

#### 回転アニメーション（オプション）🟡
```dart
AnimatedRotation(
  turns: isRotated180 ? 0.5 : 0.0, // 0.5 = 180度
  duration: const Duration(milliseconds: 300),
  child: child,
)
```
**注**: パフォーマンス要件（100ms以内）を考慮し、アニメーションは短時間またはオプションとする

---

## 6. EARS要件・設計文書との対応関係

### 参照したユーザストーリー 🔵
- コミュニケーションを行うユーザーとして、タブレットを物理的に回転させずに、対面の相手に画面を正しい向きで見せたい
- タブレットが固定されている状態でも、対面表示機能を使いたい

### 参照した機能要件 🔵
- **REQ-502**: 画面を180度回転させて対面の相手から読みやすい表示に切り替える機能を提供しなければならない
- **REQ-503**: 通常モードと対面表示モードをシンプルな操作で切り替えられなければならない（回転にも適用）
- **REQ-5005**: タップ主体の操作で完結し、スワイプ等のジェスチャーへの依存を避けなければならない

### 参照した非機能要件 🔵
- **NFR-003**: 文字盤タップから入力欄への文字反映までの遅延を100ms以内（回転にも適用）
- **NFR-202**: ボタン・タップ領域を視認性が高く押しやすいサイズ（推奨60px × 60px以上）
- **NFR-301**: 重大なエラーが発生しても、基本機能（文字盤+読み上げ）を継続して利用可能に保たなければならない

### 参照したEdgeケース 🟡
- **EDGE-201**: アプリがバックグラウンドから復帰した場合、前回の画面状態・入力内容を復元しなければならない（回転状態も含む）

### 参照した受け入れ基準 🔵
- 画面が180度回転する
- 回転後も文字が読みやすい
- 再度タップで元に戻る
- 対面表示モードと組み合わせて使用可能
- 回転後も操作性が確保される

### 参照した設計文書 🔵
- **アーキテクチャ**: `docs/design/kotonoha/architecture.md`
- **データフロー**: `docs/design/kotonoha/dataflow.md` - 対面表示モード切り替えフロー
- **型定義**: `docs/design/kotonoha/interfaces.dart` - InputScreenState（isRotated180）

---

## 7. 既存実装との関連性（TASK-0052対面表示モード）

### 7.1 TASK-0052との関係 🔵

TASK-0053（180度回転）は、TASK-0052（対面表示モード）の**拡張機能**として実装します。

#### 共通の状態管理
- 同じ`FaceToFaceState`内で管理
- 同じ`FaceToFaceNotifier`で状態更新
- 対面表示と回転は独立して動作可能

#### 組み合わせパターン

| 対面表示 | 180度回転 | 結果 |
|---------|----------|------|
| OFF | OFF | 通常モード |
| ON | OFF | 対面表示（拡大）のみ |
| OFF | ON | 通常画面の180度回転 |
| ON | ON | 対面表示（拡大）+ 180度回転 |

### 7.2 既存コンポーネントの再利用 🔵

- `FaceToFaceState`: `isRotated180`フラグを追加
- `FaceToFaceNotifier`: 回転メソッドを追加
- `FaceToFaceScreen`: `RotatedWrapper`でラップ
- `FaceToFaceToggleButton`: 参考にして`RotationToggleButton`を実装

### 7.3 実装の影響範囲 🟡

#### 変更が必要なファイル
1. `lib/features/face_to_face/domain/models/face_to_face_state.dart` - フラグ追加
2. `lib/features/face_to_face/providers/face_to_face_provider.dart` - メソッド追加

#### 新規作成するファイル
1. `lib/features/face_to_face/presentation/widgets/rotation_toggle_button.dart`
2. `lib/features/face_to_face/presentation/widgets/rotated_wrapper.dart`

#### 影響を受けるファイル
1. `lib/features/face_to_face/presentation/screens/face_to_face_screen.dart` - ラップ追加
2. メイン画面 - 回転ボタン追加

---

## 8. 品質判定

### 判定結果: ✅ 高品質

| 基準 | 状態 |
|------|------|
| 要件の曖昧さ | なし - REQ-502で明確に定義 |
| 入出力定義 | 完全 - interfaces.dartにフラグ定義済み |
| 制約条件 | 明確 - アクセシビリティ要件定義済み |
| 実装可能性 | 確実 - Transform.rotate()で実現可能 |
| 既存実装との統合 | スムーズ - TASK-0052の拡張として実装 |

### 信頼性レベルサマリー

- 🔵 青信号（確実）: 80%
  - 機能概要、入出力仕様、アクセシビリティ要件、UI/UX要件
  - EARS要件REQ-502で明確に定義されている
  - 既存のTASK-0052実装パターンを参考にできる
- 🟡 黄信号（妥当な推測）: 18%
  - パフォーマンス要件（NFR-003から推測）
  - 一部のエッジケース（画面遷移時の挙動等）
  - 回転アニメーションの詳細
- 🔴 赤信号（推測）: 2%
  - 画面遷移時の回転状態維持の詳細挙動

---

## 9. 実装の優先順位と段階的アプローチ

### Phase 1: 基本機能（必須） 🔵
1. `FaceToFaceState`に`isRotated180`フラグ追加
2. `FaceToFaceNotifier`に回転メソッド追加
3. `RotatedWrapper`実装（Transform.rotate()使用）
4. `RotationToggleButton`実装
5. 基本的な回転動作の実装

### Phase 2: 統合（必須） 🔵
1. 対面表示画面に回転機能統合
2. メイン画面に回転ボタン追加
3. 回転状態の永続化（オプション）

### Phase 3: UX改善（推奨） 🟡
1. 回転アニメーション追加（短時間）
2. 視覚的フィードバック改善
3. 回転状態表示の追加

### Phase 4: エッジケース対応（推奨） 🟡
1. 高速連続タップ対応（デバウンス）
2. 画面遷移時の状態維持
3. エラーハンドリング強化

---

## 10. 受け入れ基準（TASK-0053完了条件の詳細化）

### 必須条件 🔵

- [ ] 画面が180度回転する（Transform.rotate()による）
- [ ] 回転ボタンのサイズが44px × 44px以上
- [ ] 回転後も文字が読みやすい（視認性確保）
- [ ] 再度タップで元に戻る（トグル動作）
- [ ] 回転応答時間が100ms以内
- [ ] 対面表示モードと組み合わせて使用可能
- [ ] 回転後も全ての操作（文字入力、読み上げ等）が正常動作
- [ ] すべてのテーマ（ライト/ダーク/高コントラスト）で正常表示

### 推奨条件 🟡

- [ ] 回転アニメーションがスムーズ
- [ ] 回転状態が視覚的に分かる
- [ ] アプリ復帰時に回転状態を復元
- [ ] デバウンス処理による連打対策

### オプション条件 🟡

- [ ] 回転状態の永続化（アプリ再起動後も維持）
- [ ] 画面遷移時の回転状態維持

---

## 11. テスト戦略

### 11.1 テストレベル 🔵

#### ユニットテスト（必須）
- FaceToFaceStateの回転フラグテスト
- FaceToFaceNotifierの回転メソッドテスト
- RotatedWrapperのTransform適用テスト

#### ウィジェットテスト（必須）
- RotationToggleButtonの表示・動作テスト
- 回転後のUI表示テスト
- ボタンサイズのアクセシビリティテスト

#### 統合テスト（推奨）
- 対面表示 + 回転の組み合わせテスト
- 画面遷移時の回転状態維持テスト

### 11.2 テストカバレッジ目標 🔵

- **全体カバレッジ**: 80%以上（NFR-501）
- **ビジネスロジック**: 90%以上（NFR-502）
- **新規追加コード**: 90%以上

---

## 次のステップ

`/tsumiki:tdd-testcases` でテストケースの洗い出しを行います。
