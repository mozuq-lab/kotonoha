/// FaceToFaceProvider テスト
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/face_to_face/providers/face_to_face_provider.dart';

void main() {
  group('FaceToFaceProviderテスト', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('初期状態テスト', () {
      /// プロバイダーの初期状態でisEnabledがfalse
      test('TC-052-005: プロバイダーの初期状態でisEnabledがfalseであることを確認', () {
        // Given: テストデータ準備: ProviderContainerでプロバイダーを取得
        // 初期条件設定: 何も操作していない状態

        // When: 実際の処理実行: プロバイダーから状態を取得
        // 処理内容: faceToFaceProviderを読み込む
        final state = container.read(faceToFaceProvider);

        // Then: 結果検証: isEnabledがfalseであることを確認
        // に基づき、デフォルトは通常モード
        // 品質保証: アプリ起動時に対面表示モードが自動的に有効にならないこと
        expect(
          state.isEnabled,
          isFalse,
        );
        expect(
          state.displayText,
          isEmpty,
        );
      });
    });

    group('Notifierメソッドテスト', () {
      /// enableFaceToFaceでモードが有効化される
      test('TC-052-006: enableFaceToFaceでモードが有効化されることを確認', () {
        // Given: テストデータ準備: 初期状態のnotifierを取得
        // 初期条件設定: 対面表示モードが無効の状態
        final notifier = container.read(faceToFaceProvider.notifier);
        const testText = 'お水をください';

        // When: 実際の処理実行: enableFaceToFaceを呼び出す
        // 処理内容: 対面表示モードを有効化し、表示テキストを設定
        notifier.enableFaceToFace(testText);

        // Then: 結果検証: モードが有効化されていることを確認
        // 「テキストを画面中央に大きく表示」に基づく
        // 品質保証: ユーザー操作により対面表示モードが有効になること
        final state = container.read(faceToFaceProvider);
        expect(
          state.isEnabled,
          isTrue,
        );
        expect(
          state.displayText,
          equals(testText),
        );
      });

      /// disableFaceToFaceでモードが無効化される
      test('TC-052-007: disableFaceToFaceでモードが無効化されることを確認', () {
        // Given: テストデータ準備: 対面表示モードを有効にする
        // 初期条件設定: 対面表示モードが有効の状態
        final notifier = container.read(faceToFaceProvider.notifier);
        notifier.enableFaceToFace('テストテキスト');

        // When: 実際の処理実行: disableFaceToFaceを呼び出す
        // 処理内容: 対面表示モードを無効化
        notifier.disableFaceToFace();

        // Then: 結果検証: モードが無効化されていることを確認
        // 通常モードに戻ること
        // 品質保証: ユーザー操作により通常モードに戻れること
        final state = container.read(faceToFaceProvider);
        expect(
          state.isEnabled,
          isFalse,
        );
      });

      /// updateTextでテキストを更新できる
      test('TC-052-008: updateTextでテキストを更新できることを確認', () {
        // Given: テストデータ準備: 対面表示モードを有効にする
        // 初期条件設定: 対面表示モードが有効で、初期テキストが設定されている
        final notifier = container.read(faceToFaceProvider.notifier);
        notifier.enableFaceToFace('初期テキスト');

        // When: 実際の処理実行: updateTextを呼び出す
        // 処理内容: 表示テキストを更新
        const newText = '新しいテキスト';
        notifier.updateText(newText);

        // Then: 結果検証: テキストが更新されていることを確認
        // 新しいテキストが表示される
        // 品質保証: 対面表示中にテキストを変更できること
        final state = container.read(faceToFaceProvider);
        expect(
          state.displayText,
          equals(newText),
        );
        expect(
          state.isEnabled,
          isTrue,
        );
      });

      /// toggleFaceToFaceでモードを切り替えられる
      test('TC-052-009: toggleFaceToFaceでモードを切り替えられることを確認', () {
        // Given: テストデータ準備: 初期状態のnotifierを取得
        // 初期条件設定: 対面表示モードが無効の状態
        final notifier = container.read(faceToFaceProvider.notifier);
        const testText = 'トグルテスト';

        // When: 実際の処理実行: toggleFaceToFaceを呼び出す（1回目）
        // 処理内容: 対面表示モードをトグル（false → true）
        notifier.toggleFaceToFace(testText);

        // Then: 結果検証: モードが有効化されていることを確認
        var state = container.read(faceToFaceProvider);
        expect(
          state.isEnabled,
          isTrue,
        );

        // When: 実際の処理実行: toggleFaceToFaceを呼び出す（2回目）
        // 処理内容: 対面表示モードをトグル（true → false）
        notifier.toggleFaceToFace(testText);

        // Then: 結果検証: モードが無効化されていることを確認
        state = container.read(faceToFaceProvider);
        expect(
          state.isEnabled,
          isFalse,
        );
      });
    });

    group('180度回転機能テスト (TASK-0053)', () {
      /// toggleRotationで回転状態がトグルされる
      test('TC-053-004: toggleRotationで回転状態がトグルされる', () {
        // Given: テストデータ準備: 初期状態のnotifierを取得
        // 初期条件設定: 回転なし（isRotated180 = false）の状態
        final notifier = container.read(faceToFaceProvider.notifier);

        // 初期状態の確認
        var state = container.read(faceToFaceProvider);
        expect(
          state.isRotated180,
          isFalse,
          reason: '初期状態では回転なし',
        );

        // When: 実際の処理実行: toggleRotationを呼び出す（1回目）
        // 処理内容: 回転をトグル（false → true）
        notifier.toggleRotation();

        // Then: 結果検証: 回転が有効になることを確認
        // 1回目のトグルで有効になる
        // 品質保証: ユーザーが回転ボタンをタップして回転できること
        state = container.read(faceToFaceProvider);
        expect(
          state.isRotated180,
          isTrue,
          reason: '1回目のトグルで回転が有効になる',
        );

        // When: 実際の処理実行: toggleRotationを呼び出す（2回目）
        // 処理内容: 回転をトグル（true → false）
        notifier.toggleRotation();

        // Then: 結果検証: 回転が無効になることを確認
        // 2回目のトグルで無効になる
        // 品質保証: ユーザーが回転ボタンをタップして元に戻せること
        state = container.read(faceToFaceProvider);
        expect(
          state.isRotated180,
          isFalse,
          reason: '2回目のトグルで回転が無効になる',
        );
      });

      /// enableRotationで回転が有効化される
      test('TC-053-005: enableRotationで回転が有効化される', () {
        // Given: テストデータ準備: 初期状態のnotifierを取得
        // 初期条件設定: 回転なし（isRotated180 = false）の状態
        final notifier = container.read(faceToFaceProvider.notifier);

        // When: 実際の処理実行: enableRotationを呼び出す
        // 処理内容: 回転を明示的に有効化
        notifier.enableRotation();

        // Then: 結果検証: 回転が有効になることを確認
        // isRotated180がtrueになる
        // 品質保証: 明示的に回転を有効化できること
        final state = container.read(faceToFaceProvider);
        expect(
          state.isRotated180,
          isTrue,
          reason: 'enableRotation呼び出しで回転が有効になる',
        );
      });

      /// disableRotationで回転が無効化される
      test('TC-053-006: disableRotationで回転が無効化される', () {
        // Given: テストデータ準備: 回転を有効にする
        // 初期条件設定: 回転が有効（isRotated180 = true）の状態
        final notifier = container.read(faceToFaceProvider.notifier);
        notifier.enableRotation();

        // When: 実際の処理実行: disableRotationを呼び出す
        // 処理内容: 回転を明示的に無効化
        notifier.disableRotation();

        // Then: 結果検証: 回転が無効になることを確認
        // isRotated180がfalseになる
        // 品質保証: 明示的に回転を無効化できること
        final state = container.read(faceToFaceProvider);
        expect(
          state.isRotated180,
          isFalse,
          reason: 'disableRotation呼び出しで回転が無効になる',
        );
      });

      /// 回転とテキスト更新が正しく共存する
      test('TC-053-007: 回転とテキスト更新が正しく共存する', () {
        // Given: テストデータ準備: 回転を有効化し、初期テキストを設定
        // 初期条件設定: 回転が有効で、テキストが設定されている状態
        final notifier = container.read(faceToFaceProvider.notifier);
        notifier.enableRotation();
        notifier.updateText('初期テキスト');

        // When: 実際の処理実行: テキストを更新
        // 処理内容: 回転状態を維持しつつ、表示テキストを変更
        const newText = '新しいテキスト';
        notifier.updateText(newText);

        // Then: 結果検証: 回転状態が維持され、テキストが更新されていることを確認
        // 回転とテキスト更新が共存できる
        // 品質保証: 回転中にテキスト変更してもクラッシュしないこと
        final state = container.read(faceToFaceProvider);
        expect(
          state.isRotated180,
          isTrue,
          reason: 'テキスト更新後も回転状態が維持される',
        );

        expect(
          state.displayText,
          equals(newText),
          reason: 'テキストが更新される',
        );
      });

      /// 回転状態で対面表示を切り替えても回転維持
      test('TC-053-021: 回転状態で対面表示を切り替えても回転維持', () {
        // Given: テストデータ準備: 回転を有効化
        // 初期条件設定: 回転が有効な状態
        final notifier = container.read(faceToFaceProvider.notifier);
        notifier.enableRotation();

        // When & Then: 実際の処理実行: 対面表示を切り替え
        // 処理内容: 対面表示を複数回切り替える

        // 対面表示をONにする
        notifier.enableFaceToFace('テスト');
        var state = container.read(faceToFaceProvider);
        expect(
          state.isRotated180,
          isTrue,
          reason: '対面表示ON後も回転状態が維持される',
        );
        expect(
          state.isEnabled,
          isTrue,
          reason: '対面表示がONになる',
        );

        // 対面表示をOFFにする
        notifier.disableFaceToFace();
        state = container.read(faceToFaceProvider);
        expect(
          state.isRotated180,
          isTrue,
          reason: '対面表示OFF後も回転状態が維持される',
        );
        expect(
          state.isEnabled,
          isFalse,
          reason: '対面表示がOFFになる',
        );

        // 対面表示を再度ONにする
        notifier.enableFaceToFace('テスト2');
        state = container.read(faceToFaceProvider);
        expect(
          state.isRotated180,
          isTrue,
          reason: '対面表示再ON後も回転状態が維持される',
        );
      });

      /// 対面表示状態で回転を切り替えても対面表示維持
      test('TC-053-022: 対面表示状態で回転を切り替えても対面表示維持', () {
        // Given: テストデータ準備: 対面表示を有効化
        // 初期条件設定: 対面表示が有効な状態
        final notifier = container.read(faceToFaceProvider.notifier);
        notifier.enableFaceToFace('テスト');

        // When & Then: 実際の処理実行: 回転を切り替え
        // 処理内容: 回転を複数回切り替える

        // 回転をONにする
        notifier.enableRotation();
        var state = container.read(faceToFaceProvider);
        expect(
          state.isEnabled,
          isTrue,
          reason: '回転ON後も対面表示状態が維持される',
        );
        expect(
          state.isRotated180,
          isTrue,
          reason: '回転がONになる',
        );

        // 回転をOFFにする
        notifier.disableRotation();
        state = container.read(faceToFaceProvider);
        expect(
          state.isEnabled,
          isTrue,
          reason: '回転OFF後も対面表示状態が維持される',
        );
        expect(
          state.isRotated180,
          isFalse,
          reason: '回転がOFFになる',
        );

        // 回転を再度ONにする
        notifier.enableRotation();
        state = container.read(faceToFaceProvider);
        expect(
          state.isEnabled,
          isTrue,
          reason: '回転再ON後も対面表示状態が維持される',
        );
      });
    });
  });
}
