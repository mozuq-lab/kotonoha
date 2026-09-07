/// FaceToFaceState モデル テスト
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/face_to_face/domain/models/face_to_face_state.dart';

void main() {
  group('FaceToFaceStateテスト', () {
    group('初期状態テスト', () {
      /// 初期状態でisEnabledがfalse
      test('TC-052-001: 初期状態でisEnabledがfalseであることを確認', () {
        // Given: テストデータ準備: デフォルトコンストラクタでFaceToFaceStateを作成
        // 初期条件設定: 何も指定しない場合の初期状態

        // When: 実際の処理実行: FaceToFaceStateのインスタンスを作成
        // 処理内容: デフォルトコンストラクタの呼び出し
        const state = FaceToFaceState();

        // Then: 結果検証: isEnabledがfalseであることを確認
        // に基づき、デフォルトは通常モード
        // 品質保証: アプリ起動時に対面表示モードが自動的に有効にならないこと
        expect(
          state.isEnabled,
          isFalse,
        );
      });

      /// 初期状態でdisplayTextが空文字列
      test('TC-052-002: 初期状態でdisplayTextが空文字列であることを確認', () {
        // Given: テストデータ準備: デフォルトコンストラクタでFaceToFaceStateを作成
        // 初期条件設定: 何も指定しない場合の初期状態

        // When: 実際の処理実行: FaceToFaceStateのインスタンスを作成
        // 処理内容: デフォルトコンストラクタの呼び出し
        const state = FaceToFaceState();

        // Then: 結果検証: displayTextが空文字列であることを確認
        // 初期状態ではテキストが設定されていない
        // 品質保証: 意図しないテキストが表示されないこと
        expect(
          state.displayText,
          isEmpty,
        );
      });
    });

    group('copyWithテスト', () {
      /// copyWithでisEnabledを更新できる
      test('TC-052-003: copyWithでisEnabledを更新できることを確認', () {
        // Given: テストデータ準備: 初期状態のFaceToFaceStateを作成
        // 初期条件設定: isEnabled=false, displayText=''の状態
        const initialState = FaceToFaceState();

        // When: 実際の処理実行: copyWithでisEnabledをtrueに更新
        // 処理内容: 不変オブジェクトのコピーを作成し、isEnabledのみ変更
        final updatedState = initialState.copyWith(isEnabled: true);

        // Then: 結果検証: isEnabledがtrueに更新されていることを確認
        // copyWithが正しく動作している
        // 品質保証: 状態の一部のみを更新できること
        expect(
          updatedState.isEnabled,
          isTrue,
        );
        expect(
          updatedState.displayText,
          isEmpty,
        );
      });

      /// copyWithでdisplayTextを更新できる
      test('TC-052-004: copyWithでdisplayTextを更新できることを確認', () {
        // Given: テストデータ準備: 初期状態のFaceToFaceStateを作成
        // 初期条件設定: isEnabled=false, displayText=''の状態
        const initialState = FaceToFaceState();
        const testText = 'お水をください';

        // When: 実際の処理実行: copyWithでdisplayTextを更新
        // 処理内容: 不変オブジェクトのコピーを作成し、displayTextのみ変更
        final updatedState = initialState.copyWith(displayText: testText);

        // Then: 結果検証: displayTextが更新されていることを確認
        // copyWithが正しく動作している
        // 品質保証: 状態の一部のみを更新できること
        expect(
          updatedState.displayText,
          equals(testText),
        );
        expect(
          updatedState.isEnabled,
          isFalse,
        );
      });
    });

    group('180度回転機能テスト (TASK-0053)', () {
      /// 初期状態でisRotated180がfalse
      test('TC-053-001: 初期状態でisRotated180がfalse', () {
        // Given: テストデータ準備: デフォルトコンストラクタでFaceToFaceStateを作成
        // 初期条件設定: 何も指定しない場合の初期状態

        // When: 実際の処理実行: FaceToFaceStateのインスタンスを作成
        // 処理内容: デフォルトコンストラクタの呼び出し
        const state = FaceToFaceState();

        // Then: 結果検証: isRotated180がfalseであることを確認
        // 「画面を180度回転できる機能」で、デフォルトは通常表示
        // 品質保証: アプリ起動時に画面が回転しないこと
        expect(
          state.isRotated180,
          isFalse,
          reason: '初期状態では回転なし（通常表示）',
        );
      });

      /// copyWithでisRotated180を更新できる
      test('TC-053-002: copyWithでisRotated180を更新できる', () {
        // Given: テストデータ準備: 初期状態のFaceToFaceStateを作成
        // 初期条件設定: isRotated180=false, isEnabled=false, displayText='テスト'の状態
        const initialState = FaceToFaceState(
          isEnabled: false,
          displayText: 'テスト',
        );

        // When: 実際の処理実行: copyWithでisRotated180をtrueに更新
        // 処理内容: 不変オブジェクトのコピーを作成し、isRotated180のみ変更
        final updatedState = initialState.copyWith(isRotated180: true);

        // Then: 結果検証: 元の状態は変更されず、新しい状態でisRotated180がtrueであることを確認
        // 不変性が保たれ、copyWithが正しく動作している
        // 品質保証: 状態の一部のみを更新できること
        expect(
          initialState.isRotated180,
          isFalse,
          reason: '元の状態は変更されない（不変性）',
        );

        expect(
          updatedState.isRotated180,
          isTrue,
          reason: '新しい状態でisRotated180がtrueに更新される',
        );

        expect(
          updatedState.isEnabled,
          equals(initialState.isEnabled),
          reason: '他のプロパティ（isEnabled）は変更されない',
        );

        expect(
          updatedState.displayText,
          equals(initialState.displayText),
          reason: '他のプロパティ（displayText）は変更されない',
        );
      });

      /// isRotated180とisEnabledが独立して動作
      test('TC-053-003: isRotated180とisEnabledが独立して動作', () {
        // Given & When: テストデータ準備: 4つの組み合わせパターンのFaceToFaceStateを作成
        // 初期条件設定: すべての組み合わせパターンを準備

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

        // Then: 結果検証: すべての組み合わせが正しく設定されていることを確認
        // 2つのフラグが独立して動作すること
        // 品質保証: すべての組み合わせが可能であること

        // パターン1の検証
        expect(pattern1.isRotated180, isFalse, reason: 'パターン1: 回転なし');
        expect(pattern1.isEnabled, isFalse, reason: 'パターン1: 対面表示なし');

        // パターン2の検証
        expect(pattern2.isRotated180, isTrue, reason: 'パターン2: 回転あり');
        expect(pattern2.isEnabled, isFalse, reason: 'パターン2: 対面表示なし');

        // パターン3の検証
        expect(pattern3.isRotated180, isFalse, reason: 'パターン3: 回転なし');
        expect(pattern3.isEnabled, isTrue, reason: 'パターン3: 対面表示あり');

        // パターン4の検証
        expect(pattern4.isRotated180, isTrue, reason: 'パターン4: 回転あり');
        expect(pattern4.isEnabled, isTrue, reason: 'パターン4: 対面表示あり');
      });

      /// equals演算子でisRotated180が正しく比較される
      test('TC-053-003-1: equals演算子でisRotated180が正しく比較される', () {
        // Given: テストデータ準備: 3つの状態を作成
        // 初期条件設定: state1とstate2は同じ、state3はisRotated180のみ異なる
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

        // Then: 結果検証: equals演算子が正しく動作することを確認
        // 同じプロパティ値の状態は等しく、異なる状態は等しくない
        // 品質保証: equals演算子がisRotated180を正しく考慮すること
        expect(state1, equals(state2), reason: '同じプロパティ値の状態は等しい');

        expect(state1, isNot(equals(state3)),
            reason: 'isRotated180が異なる状態は等しくない');
      });

      /// hashCodeでisRotated180が正しく考慮される
      test('TC-053-003-2: hashCodeでisRotated180が正しく考慮される', () {
        // Given: テストデータ準備: 3つの状態を作成
        // 初期条件設定: state1とstate2は同じ、state3はisRotated180のみ異なる
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

        // Then: 結果検証: hashCodeが正しく動作することを確認
        // 同じプロパティ値の状態は同じhashCode、異なる状態は異なるhashCode
        // 品質保証: hashCodeがisRotated180を正しく考慮すること
        expect(state1.hashCode, equals(state2.hashCode),
            reason: '同じプロパティ値の状態は同じhashCode');

        expect(state1.hashCode, isNot(equals(state3.hashCode)),
            reason: 'isRotated180が異なる状態は異なるhashCode');
      });

      /// toStringでisRotated180が正しく表示される
      test('TC-053-003-3: toStringでisRotated180が正しく表示される', () {
        // Given: テストデータ準備: isRotated180=trueの状態を作成
        // 初期条件設定: 回転が有効な状態
        const state = FaceToFaceState(
          isRotated180: true,
          isEnabled: false,
          displayText: 'テスト',
        );

        // When: 実際の処理実行: toStringを呼び出す
        // 処理内容: 状態を文字列表現に変換
        final stringRepresentation = state.toString();

        // Then: 結果検証: toStringの出力にisRotated180が含まれることを確認
        // toStringにisRotated180フィールドと値が含まれる
        // 品質保証: デバッグ時に回転状態を確認できること
        expect(stringRepresentation, contains('isRotated180'),
            reason: 'toStringにisRotated180フィールドが含まれる');

        expect(stringRepresentation, contains('true'),
            reason: 'isRotated180の値が表示される');
      });
    });
  });
}
