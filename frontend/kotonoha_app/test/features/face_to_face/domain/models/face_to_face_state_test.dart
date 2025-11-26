/// FaceToFaceState モデル テスト
///
/// TASK-0052: 対面表示モード（拡大表示）実装
/// テストケース: TC-052-001〜TC-052-004
///
/// テスト対象: lib/features/face_to_face/domain/models/face_to_face_state.dart
///
/// 【TDD Redフェーズ】: FaceToFaceStateが未実装、テストが失敗するはず
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
  });
}
