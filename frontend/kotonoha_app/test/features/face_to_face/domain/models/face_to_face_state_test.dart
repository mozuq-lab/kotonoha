/// FaceToFaceState モデル テスト
///
/// TASK-0052: 対面表示モード（拡大表示）実装
/// TASK-0053: 180度画面回転機能実装
/// テストケース: TC-052-001〜TC-052-004, TC-053-001〜TC-053-003
///
/// テスト対象: lib/features/face_to_face/domain/models/face_to_face_state.dart
///
/// 【TDD Redフェーズ】: isRotated180プロパティが未実装、新しいテストが失敗するはず
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/face_to_face/domain/models/face_to_face_state.dart';

void main() {
  group('FaceToFaceStateテスト', () {
    // =========================================================================
    // 1. 正常系テストケース（初期状態）
    // =========================================================================
    group('初期状態テスト', () {
      /// TC-052-001: 初期状態でisEnabledがfalse
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-503
      /// 検証内容: デフォルトコンストラクタで対面表示モードが無効であること
      test('TC-052-001: 初期状態でisEnabledがfalseであることを確認', () {
        // 【テスト目的】: FaceToFaceStateの初期状態でisEnabledがfalseであることを確認 🔵
        // 【テスト内容】: デフォルトコンストラクタで作成した状態を検証
        // 【期待される動作】: アプリ起動時は対面表示モードが無効（通常モード）
        // 🔵 青信号: REQ-503「シンプルな操作で切り替え」から、デフォルトは通常モード

        // Given: 【テストデータ準備】: デフォルトコンストラクタでFaceToFaceStateを作成
        // 【初期条件設定】: 何も指定しない場合の初期状態

        // When: 【実際の処理実行】: FaceToFaceStateのインスタンスを作成
        // 【処理内容】: デフォルトコンストラクタの呼び出し
        const state = FaceToFaceState();

        // Then: 【結果検証】: isEnabledがfalseであることを確認
        // 【期待値確認】: REQ-503に基づき、デフォルトは通常モード
        // 【品質保証】: アプリ起動時に対面表示モードが自動的に有効にならないこと
        expect(
          state.isEnabled,
          isFalse,
        ); // 【確認内容】: 初期状態でisEnabledがfalseであることを確認 🔵
      });

      /// TC-052-002: 初期状態でdisplayTextが空文字列
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-501
      /// 検証内容: デフォルトコンストラクタで表示テキストが空であること
      test('TC-052-002: 初期状態でdisplayTextが空文字列であることを確認', () {
        // 【テスト目的】: FaceToFaceStateの初期状態でdisplayTextが空文字列であることを確認 🔵
        // 【テスト内容】: デフォルトコンストラクタで作成した状態を検証
        // 【期待される動作】: 初期状態では表示するテキストがない
        // 🔵 青信号: REQ-501「テキストを画面中央に大きく表示」から、テキストは後から設定

        // Given: 【テストデータ準備】: デフォルトコンストラクタでFaceToFaceStateを作成
        // 【初期条件設定】: 何も指定しない場合の初期状態

        // When: 【実際の処理実行】: FaceToFaceStateのインスタンスを作成
        // 【処理内容】: デフォルトコンストラクタの呼び出し
        const state = FaceToFaceState();

        // Then: 【結果検証】: displayTextが空文字列であることを確認
        // 【期待値確認】: 初期状態ではテキストが設定されていない
        // 【品質保証】: 意図しないテキストが表示されないこと
        expect(
          state.displayText,
          isEmpty,
        ); // 【確認内容】: 初期状態でdisplayTextが空文字列であることを確認 🔵
      });
    });

    // =========================================================================
    // 2. 正常系テストケース（copyWith）
    // =========================================================================
    group('copyWithテスト', () {
      /// TC-052-003: copyWithでisEnabledを更新できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-503
      /// 検証内容: copyWithでisEnabledのみを更新できること
      test('TC-052-003: copyWithでisEnabledを更新できることを確認', () {
        // 【テスト目的】: copyWithでisEnabledのみを更新できることを確認 🔵
        // 【テスト内容】: copyWithでisEnabledをtrueに更新
        // 【期待される動作】: isEnabledのみが更新され、他のプロパティは維持される
        // 🔵 青信号: Riverpod StateNotifierパターンの標準的なcopyWith実装

        // Given: 【テストデータ準備】: 初期状態のFaceToFaceStateを作成
        // 【初期条件設定】: isEnabled=false, displayText=''の状態
        const initialState = FaceToFaceState();

        // When: 【実際の処理実行】: copyWithでisEnabledをtrueに更新
        // 【処理内容】: 不変オブジェクトのコピーを作成し、isEnabledのみ変更
        final updatedState = initialState.copyWith(isEnabled: true);

        // Then: 【結果検証】: isEnabledがtrueに更新されていることを確認
        // 【期待値確認】: copyWithが正しく動作している
        // 【品質保証】: 状態の一部のみを更新できること
        expect(
          updatedState.isEnabled,
          isTrue,
        ); // 【確認内容】: isEnabledがtrueに更新されたことを確認 🔵
        expect(
          updatedState.displayText,
          isEmpty,
        ); // 【確認内容】: displayTextが変更されていないことを確認 🔵
      });

      /// TC-052-004: copyWithでdisplayTextを更新できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-501
      /// 検証内容: copyWithでdisplayTextのみを更新できること
      test('TC-052-004: copyWithでdisplayTextを更新できることを確認', () {
        // 【テスト目的】: copyWithでdisplayTextのみを更新できることを確認 🔵
        // 【テスト内容】: copyWithでdisplayTextを更新
        // 【期待される動作】: displayTextのみが更新され、他のプロパティは維持される
        // 🔵 青信号: Riverpod StateNotifierパターンの標準的なcopyWith実装

        // Given: 【テストデータ準備】: 初期状態のFaceToFaceStateを作成
        // 【初期条件設定】: isEnabled=false, displayText=''の状態
        const initialState = FaceToFaceState();
        const testText = 'お水をください';

        // When: 【実際の処理実行】: copyWithでdisplayTextを更新
        // 【処理内容】: 不変オブジェクトのコピーを作成し、displayTextのみ変更
        final updatedState = initialState.copyWith(displayText: testText);

        // Then: 【結果検証】: displayTextが更新されていることを確認
        // 【期待値確認】: copyWithが正しく動作している
        // 【品質保証】: 状態の一部のみを更新できること
        expect(
          updatedState.displayText,
          equals(testText),
        ); // 【確認内容】: displayTextが更新されたことを確認 🔵
        expect(
          updatedState.isEnabled,
          isFalse,
        ); // 【確認内容】: isEnabledが変更されていないことを確認 🔵
      });
    });

    // =========================================================================
    // 3. TASK-0053: 180度回転機能テスト
    // =========================================================================
    group('180度回転機能テスト (TASK-0053)', () {
      /// TC-053-001: 初期状態でisRotated180がfalse
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-502, REQ-503
      /// 検証内容: デフォルトコンストラクタで回転フラグが無効であること
      test('TC-053-001: 初期状態でisRotated180がfalse', () {
        // 【テスト目的】: FaceToFaceStateの初期状態で、回転フラグisRotated180がfalseであることを確認 🔵
        // 【テスト内容】: デフォルトコンストラクタで作成されたFaceToFaceStateのisRotated180プロパティを検証
        // 【期待される動作】: アプリ起動時は通常表示（回転なし）がデフォルト
        // 🔵 青信号: REQ-502, REQ-503に基づく

        // Given: 【テストデータ準備】: デフォルトコンストラクタでFaceToFaceStateを作成
        // 【初期条件設定】: 何も指定しない場合の初期状態

        // When: 【実際の処理実行】: FaceToFaceStateのインスタンスを作成
        // 【処理内容】: デフォルトコンストラクタの呼び出し
        const state = FaceToFaceState();

        // Then: 【結果検証】: isRotated180がfalseであることを確認
        // 【期待値確認】: REQ-502「画面を180度回転できる機能」で、デフォルトは通常表示
        // 【品質保証】: アプリ起動時に画面が回転しないこと
        expect(
          state.isRotated180,
          isFalse,
          reason: '初期状態では回転なし（通常表示）',
        ); // 【確認内容】: 初期状態でisRotated180がfalseであることを確認 🔵
      });

      /// TC-053-002: copyWithでisRotated180を更新できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-502
      /// 検証内容: copyWithでisRotated180のみを更新できること
      test('TC-053-002: copyWithでisRotated180を更新できる', () {
        // 【テスト目的】: 状態モデルの不変性（immutability）を確認し、
        //               copyWithメソッドでisRotated180を更新した新しい状態オブジェクトが生成されることを検証 🔵
        // 【テスト内容】:
        //   1. 初期状態を作成（isRotated180 = false）
        //   2. copyWithでisRotated180をtrueに更新
        //   3. 新しい状態と元の状態が異なることを確認
        //   4. 新しい状態のisRotated180がtrueであることを確認
        // 【期待される動作】: Riverpod StateNotifierパターンに従い、copyWithで新しいインスタンスが作成される
        // 🔵 青信号: 設計文書のFaceToFaceState定義に基づく

        // Given: 【テストデータ準備】: 初期状態のFaceToFaceStateを作成
        // 【初期条件設定】: isRotated180=false, isEnabled=false, displayText='テスト'の状態
        const initialState = FaceToFaceState(
          isEnabled: false,
          displayText: 'テスト',
        );

        // When: 【実際の処理実行】: copyWithでisRotated180をtrueに更新
        // 【処理内容】: 不変オブジェクトのコピーを作成し、isRotated180のみ変更
        final updatedState = initialState.copyWith(isRotated180: true);

        // Then: 【結果検証】: 元の状態は変更されず、新しい状態でisRotated180がtrueであることを確認
        // 【期待値確認】: 不変性が保たれ、copyWithが正しく動作している
        // 【品質保証】: 状態の一部のみを更新できること
        expect(
          initialState.isRotated180,
          isFalse,
          reason: '元の状態は変更されない（不変性）',
        ); // 【確認内容】: 元の状態は変更されないことを確認 🔵

        expect(
          updatedState.isRotated180,
          isTrue,
          reason: '新しい状態でisRotated180がtrueに更新される',
        ); // 【確認内容】: 新しい状態でisRotated180がtrueに更新されることを確認 🔵

        expect(
          updatedState.isEnabled,
          equals(initialState.isEnabled),
          reason: '他のプロパティ（isEnabled）は変更されない',
        ); // 【確認内容】: 他のプロパティが変更されないことを確認 🔵

        expect(
          updatedState.displayText,
          equals(initialState.displayText),
          reason: '他のプロパティ（displayText）は変更されない',
        ); // 【確認内容】: 他のプロパティが変更されないことを確認 🔵
      });

      /// TC-053-003: isRotated180とisEnabledが独立して動作
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-502「対面表示モードと独立して利用可能」
      /// 検証内容: 回転フラグと対面表示フラグが独立して動作すること
      test('TC-053-003: isRotated180とisEnabledが独立して動作', () {
        // 【テスト目的】: 回転フラグ（isRotated180）と対面表示フラグ（isEnabled）が独立して動作することを確認 🔵
        // 【テスト内容】: 4つの組み合わせパターンをテスト
        //   1. isRotated180=false, isEnabled=false（通常モード、回転なし）
        //   2. isRotated180=true, isEnabled=false（通常モード、回転あり）
        //   3. isRotated180=false, isEnabled=true（対面表示、回転なし）
        //   4. isRotated180=true, isEnabled=true（対面表示、回転あり）
        // 【期待される動作】: REQ-502「対面表示モードと独立して利用可能」に基づき、
        //                    2つのフラグが互いに影響せず、すべての組み合わせが可能
        // 🔵 青信号: 要件定義書「対面表示モードと独立して動作」

        // Given & When: 【テストデータ準備】: 4つの組み合わせパターンのFaceToFaceStateを作成
        // 【初期条件設定】: すべての組み合わせパターンを準備

        // パターン1: 通常モード + 回転なし
        const pattern1 = FaceToFaceState(
          isRotated180: false,
          isEnabled: false,
        );

        // パターン2: 通常モード + 回転あり
        const pattern2 = FaceToFaceState(
          isRotated180: true,
          isEnabled: false,
        );

        // パターン3: 対面表示 + 回転なし
        const pattern3 = FaceToFaceState(
          isRotated180: false,
          isEnabled: true,
        );

        // パターン4: 対面表示 + 回転あり
        const pattern4 = FaceToFaceState(
          isRotated180: true,
          isEnabled: true,
        );

        // Then: 【結果検証】: すべての組み合わせが正しく設定されていることを確認
        // 【期待値確認】: 2つのフラグが独立して動作すること
        // 【品質保証】: すべての組み合わせが可能であること

        // パターン1の検証
        expect(pattern1.isRotated180, isFalse, reason: 'パターン1: 回転なし'); // 🔵
        expect(pattern1.isEnabled, isFalse, reason: 'パターン1: 対面表示なし'); // 🔵

        // パターン2の検証
        expect(pattern2.isRotated180, isTrue, reason: 'パターン2: 回転あり'); // 🔵
        expect(pattern2.isEnabled, isFalse, reason: 'パターン2: 対面表示なし'); // 🔵

        // パターン3の検証
        expect(pattern3.isRotated180, isFalse, reason: 'パターン3: 回転なし'); // 🔵
        expect(pattern3.isEnabled, isTrue, reason: 'パターン3: 対面表示あり'); // 🔵

        // パターン4の検証
        expect(pattern4.isRotated180, isTrue, reason: 'パターン4: 回転あり'); // 🔵
        expect(pattern4.isEnabled, isTrue, reason: 'パターン4: 対面表示あり'); // 🔵
      });

      /// TC-053-003-1: equals演算子でisRotated180が正しく比較される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-502
      /// 検証内容: equals演算子がisRotated180を正しく考慮すること
      test('TC-053-003-1: equals演算子でisRotated180が正しく比較される', () {
        // 【テスト目的】: FaceToFaceStateのequals演算子がisRotated180を正しく考慮することを確認 🔵
        // 【テスト内容】: 同じプロパティ値の状態が等しく、isRotated180のみ異なる状態が等しくないことを検証
        // 【期待される動作】: equals演算子が正しく実装されている
        // 🔵 青信号: 設計文書のFaceToFaceState定義に基づく

        // Given: 【テストデータ準備】: 3つの状態を作成
        // 【初期条件設定】: state1とstate2は同じ、state3はisRotated180のみ異なる
        const state1 = FaceToFaceState(
          isRotated180: true,
          isEnabled: true,
          displayText: 'テスト',
        );

        const state2 = FaceToFaceState(
          isRotated180: true,
          isEnabled: true,
          displayText: 'テスト',
        );

        const state3 = FaceToFaceState(
          isRotated180: false, // 回転フラグのみ異なる
          isEnabled: true,
          displayText: 'テスト',
        );

        // Then: 【結果検証】: equals演算子が正しく動作することを確認
        // 【期待値確認】: 同じプロパティ値の状態は等しく、異なる状態は等しくない
        // 【品質保証】: equals演算子がisRotated180を正しく考慮すること
        expect(state1, equals(state2), reason: '同じプロパティ値の状態は等しい'); // 🔵

        expect(state1, isNot(equals(state3)),
            reason: 'isRotated180が異なる状態は等しくない'); // 🔵
      });

      /// TC-053-003-2: hashCodeでisRotated180が正しく考慮される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-502
      /// 検証内容: hashCodeがisRotated180を正しく考慮すること
      test('TC-053-003-2: hashCodeでisRotated180が正しく考慮される', () {
        // 【テスト目的】: FaceToFaceStateのhashCodeがisRotated180を正しく考慮することを確認 🔵
        // 【テスト内容】: 同じプロパティ値の状態が同じhashCode、異なる状態が異なるhashCodeを持つことを検証
        // 【期待される動作】: hashCodeが正しく実装されている
        // 🔵 青信号: 設計文書のFaceToFaceState定義に基づく

        // Given: 【テストデータ準備】: 3つの状態を作成
        // 【初期条件設定】: state1とstate2は同じ、state3はisRotated180のみ異なる
        const state1 = FaceToFaceState(
          isRotated180: true,
          isEnabled: true,
          displayText: 'テスト',
        );

        const state2 = FaceToFaceState(
          isRotated180: true,
          isEnabled: true,
          displayText: 'テスト',
        );

        const state3 = FaceToFaceState(
          isRotated180: false,
          isEnabled: true,
          displayText: 'テスト',
        );

        // Then: 【結果検証】: hashCodeが正しく動作することを確認
        // 【期待値確認】: 同じプロパティ値の状態は同じhashCode、異なる状態は異なるhashCode
        // 【品質保証】: hashCodeがisRotated180を正しく考慮すること
        expect(state1.hashCode, equals(state2.hashCode),
            reason: '同じプロパティ値の状態は同じhashCode'); // 🔵

        expect(state1.hashCode, isNot(equals(state3.hashCode)),
            reason: 'isRotated180が異なる状態は異なるhashCode'); // 🔵
      });

      /// TC-053-003-3: toStringでisRotated180が正しく表示される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-502
      /// 検証内容: toStringがisRotated180を含むこと
      test('TC-053-003-3: toStringでisRotated180が正しく表示される', () {
        // 【テスト目的】: FaceToFaceStateのtoStringがisRotated180を含むことを確認 🔵
        // 【テスト内容】: toStringの出力にisRotated180フィールドと値が含まれることを検証
        // 【期待される動作】: toStringが正しく実装されている
        // 🔵 青信号: 設計文書のFaceToFaceState定義に基づく

        // Given: 【テストデータ準備】: isRotated180=trueの状態を作成
        // 【初期条件設定】: 回転が有効な状態
        const state = FaceToFaceState(
          isRotated180: true,
          isEnabled: false,
          displayText: 'テスト',
        );

        // When: 【実際の処理実行】: toStringを呼び出す
        // 【処理内容】: 状態を文字列表現に変換
        final stringRepresentation = state.toString();

        // Then: 【結果検証】: toStringの出力にisRotated180が含まれることを確認
        // 【期待値確認】: toStringにisRotated180フィールドと値が含まれる
        // 【品質保証】: デバッグ時に回転状態を確認できること
        expect(stringRepresentation, contains('isRotated180'),
            reason: 'toStringにisRotated180フィールドが含まれる'); // 🔵

        expect(stringRepresentation, contains('true'),
            reason: 'isRotated180の値が表示される'); // 🔵
      });
    });
  });
}
