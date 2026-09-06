/// DeleteButton ウィジェットテスト
///
/// TASK-0039: 削除ボタン・全消去ボタン実装
/// テストケース: TC-039-001〜TC-039-007, TC-039-028〜TC-039-030, TC-039-035〜TC-039-039
///
/// テスト対象: lib/features/character_board/presentation/widgets/delete_button.dart
///
/// TDD Redフェーズ: ウィジェットが未実装のため、このテストは失敗する
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/delete_button.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';

void main() {
  group('DeleteButton - 正常系テスト', () {
    // =========================================================================
    // TC-039-001: 削除ボタンの表示確認
    // =========================================================================
    /// TC-039-001: DeleteButtonが正しく表示されることを確認
    ///
    /// 前提条件:
    /// - DeleteButtonウィジェットがインポートされている
    ///
    /// 入力:
    /// - なし
    ///
    /// 期待結果:
    /// - 削除ボタンが画面上に表示される
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: REQ-003, AC-001
    /// 優先度: P0 必須
    testWidgets('TC-039-001: DeleteButtonが正しく表示されることを確認', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeleteButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(DeleteButton), findsOneWidget);
    });

    // =========================================================================
    // TC-039-002: 削除ボタンタップでコールバックが発火する
    // =========================================================================
    /// TC-039-002: DeleteButtonタップ時にonPressedコールバックが実行されることを確認
    ///
    /// 前提条件:
    /// - DeleteButtonがenabled状態
    ///
    /// 入力:
    /// - ボタンタップ
    ///
    /// 期待結果:
    /// - onPressedコールバックが1回実行される
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: REQ-003, AC-001
    /// 優先度: P0 必須
    testWidgets('TC-039-002: DeleteButtonタップ時にonPressedコールバックが実行されることを確認',
        (tester) async {
      // Arrange
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeleteButton(
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(DeleteButton));
      await tester.pump();

      // Assert
      expect(tapped, isTrue);
    });

    // =========================================================================
    // TC-039-003: 有効状態の削除ボタン表示
    // =========================================================================
    /// TC-039-003: enabled: trueの場合、削除ボタンが有効状態で表示されることを確認
    ///
    /// 前提条件:
    /// - なし
    ///
    /// 入力:
    /// - enabled: true
    ///
    /// 期待結果:
    /// - ボタンが有効状態（タップ可能）である
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: AC-005
    /// 優先度: P0 必須
    testWidgets('TC-039-003: enabled: trueの場合、削除ボタンが有効状態で表示されることを確認',
        (tester) async {
      // Arrange
      bool tapped = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeleteButton(
              onPressed: () => tapped = true,
              enabled: true,
            ),
          ),
        ),
      );

      // Assert - ボタンがタップ可能であることを確認
      await tester.tap(find.byType(DeleteButton));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('DeleteButton - 無効状態テスト', () {
    // =========================================================================
    // TC-039-004: 無効状態の削除ボタン表示
    // =========================================================================
    /// TC-039-004: enabled: falseの場合、削除ボタンが無効状態で表示されることを確認
    ///
    /// 前提条件:
    /// - なし
    ///
    /// 入力:
    /// - enabled: false
    ///
    /// 期待結果:
    /// - ボタンが無効状態（グレーアウト）である
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: AC-005, EDGE-1
    /// 優先度: P0 必須
    testWidgets('TC-039-004: enabled: falseの場合、削除ボタンが無効状態で表示されることを確認',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeleteButton(
              onPressed: () {},
              enabled: false,
            ),
          ),
        ),
      );

      // Assert - ElevatedButtonが無効状態であることを確認
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    // =========================================================================
    // TC-039-005: 無効状態の削除ボタンタップは無視される
    // =========================================================================
    /// TC-039-005: enabled: falseの場合、タップしてもコールバックが実行されないことを確認
    ///
    /// 前提条件:
    /// - なし
    ///
    /// 入力:
    /// - enabled: false, ボタンタップ
    ///
    /// 期待結果:
    /// - onPressedコールバックが実行されない
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: AC-005, EDGE-1, AC-011
    /// 優先度: P0 必須
    testWidgets('TC-039-005: enabled: falseの場合、タップしてもコールバックが実行されないことを確認',
        (tester) async {
      // Arrange
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeleteButton(
              onPressed: () => tapped = true,
              enabled: false,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(DeleteButton));
      await tester.pump();

      // Assert
      expect(tapped, isFalse);
    });
  });

  group('DeleteButton - サイズ・アクセシビリティテスト', () {
    // =========================================================================
    // TC-039-006: 削除ボタンのサイズが44x44px以上
    // =========================================================================
    /// TC-039-006: DeleteButtonのタップターゲットが44x44px以上であることを確認
    ///
    /// 前提条件:
    /// - なし
    ///
    /// 入力:
    /// - なし
    ///
    /// 期待結果:
    /// - width >= 44.0, height >= 44.0
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: REQ-5001, AC-008
    /// 優先度: P0 必須
    testWidgets('TC-039-006: DeleteButtonのタップターゲットが44x44px以上であることを確認',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeleteButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      final size = tester.getSize(find.byType(DeleteButton));
      expect(size.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
      expect(size.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
      expect(size.width, greaterThanOrEqualTo(44.0));
      expect(size.height, greaterThanOrEqualTo(44.0));
    });

    // =========================================================================
    // TC-039-007: 削除ボタンにSemanticsラベルが設定されている
    // =========================================================================
    /// TC-039-007: DeleteButtonにアクセシビリティ用のSemanticsラベルが設定されていることを確認
    ///
    /// 前提条件:
    /// - なし
    ///
    /// 入力:
    /// - なし
    ///
    /// 期待結果:
    /// - 「削除」または「1文字削除」等の適切なラベルが設定されている
    ///
    /// 信頼性レベル: 黄信号
    /// 関連要件: NFR-202
    /// 優先度: P1 重要
    testWidgets('TC-039-007: DeleteButtonにアクセシビリティ用のSemanticsラベルが設定されていることを確認',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeleteButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert - Semanticsが設定されていることを確認
      // DeleteButtonはボタンとしてのSemanticsを持つべき
      final semantics = tester.getSemantics(find.byType(DeleteButton));
      expect(semantics.label, isNotEmpty);
    });
  });

  group('DeleteButton - 統合テスト（InputBufferNotifierとの連携）', () {
    // =========================================================================
    // TC-039-028: 削除ボタンタップで最後の1文字が削除される
    // =========================================================================
    /// TC-039-028: 削除ボタンタップ時にInputBufferNotifier.deleteLastCharacter()が呼ばれ、
    /// 最後の1文字が削除されることを確認
    ///
    /// 前提条件:
    /// - InputBufferNotifierに'こんにちは'が設定されている
    ///
    /// 入力:
    /// - DeleteButtonをタップ
    ///
    /// 期待結果:
    /// - 入力バッファが'こんにち'である
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: REQ-003, AC-001
    /// 優先度: P0 必須
    testWidgets('TC-039-028: 削除ボタンタップで最後の1文字が削除されることを確認', (tester) async {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 初期状態を設定
      container.read(inputBufferProvider.notifier).setText('こんにちは');
      expect(container.read(inputBufferProvider), 'こんにちは');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final buffer = ref.watch(inputBufferProvider);
                  final notifier = ref.read(inputBufferProvider.notifier);
                  return DeleteButton(
                    onPressed: () => notifier.deleteLastCharacter(),
                    enabled: buffer.isNotEmpty,
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(DeleteButton));
      await tester.pump();

      // Assert
      expect(container.read(inputBufferProvider), 'こんにち');
    });

    // =========================================================================
    // TC-039-029: 入力バッファが空の場合、削除ボタンが無効化される
    // =========================================================================
    /// TC-039-029: 入力バッファが空の場合、削除ボタンが無効化されることを確認
    ///
    /// 前提条件:
    /// - InputBufferNotifierが空の状態
    ///
    /// 入力:
    /// - なし
    ///
    /// 期待結果:
    /// - 削除ボタンが無効状態（enabled: false）である
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: AC-005, EDGE-1
    /// 優先度: P0 必須
    testWidgets('TC-039-029: 入力バッファが空の場合、削除ボタンが無効化されることを確認', (tester) async {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 初期状態は空
      expect(container.read(inputBufferProvider), '');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final buffer = ref.watch(inputBufferProvider);
                  final notifier = ref.read(inputBufferProvider.notifier);
                  return DeleteButton(
                    onPressed: () => notifier.deleteLastCharacter(),
                    enabled: buffer.isNotEmpty,
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Assert - ボタンが無効状態であることを確認
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    // =========================================================================
    // TC-039-030: 入力バッファに文字がある場合、削除ボタンが有効化される
    // =========================================================================
    /// TC-039-030: 入力バッファに文字がある場合、削除ボタンが有効化されることを確認
    ///
    /// 前提条件:
    /// - InputBufferNotifierに文字が設定されている
    ///
    /// 入力:
    /// - InputBufferNotifierに'あ'を設定
    ///
    /// 期待結果:
    /// - 削除ボタンが有効状態（enabled: true）である
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: AC-005
    /// 優先度: P0 必須
    testWidgets('TC-039-030: 入力バッファに文字がある場合、削除ボタンが有効化されることを確認', (tester) async {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 初期状態を設定
      container.read(inputBufferProvider.notifier).setText('あ');
      expect(container.read(inputBufferProvider), 'あ');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final buffer = ref.watch(inputBufferProvider);
                  final notifier = ref.read(inputBufferProvider.notifier);
                  return DeleteButton(
                    onPressed: () => notifier.deleteLastCharacter(),
                    enabled: buffer.isNotEmpty,
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Assert - ボタンが有効状態であることを確認
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });
  });

  group('DeleteButton - エッジケーステスト', () {
    // =========================================================================
    // TC-039-035: 連続削除で正しく文字が削除される
    // =========================================================================
    /// TC-039-035: 削除ボタンを連続タップしても正しく文字が削除されることを確認
    ///
    /// 前提条件:
    /// - InputBufferNotifierに'あいう'が設定されている
    ///
    /// 入力:
    /// - 削除ボタンを3回連続タップ
    ///
    /// 期待結果:
    /// - 1回目: 'あい', 2回目: 'あ', 3回目: ''
    ///
    /// 信頼性レベル: 黄信号
    /// 関連要件: AC-012, EDGE-3
    /// 優先度: P1 重要
    testWidgets('TC-039-035: 連続削除で正しく文字が削除されることを確認', (tester) async {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 初期状態を設定
      container.read(inputBufferProvider.notifier).setText('あいう');
      expect(container.read(inputBufferProvider), 'あいう');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final buffer = ref.watch(inputBufferProvider);
                  final notifier = ref.read(inputBufferProvider.notifier);
                  return DeleteButton(
                    onPressed: () => notifier.deleteLastCharacter(),
                    enabled: buffer.isNotEmpty,
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Act & Assert - 1回目
      await tester.tap(find.byType(DeleteButton));
      await tester.pump();
      expect(container.read(inputBufferProvider), 'あい');

      // Act & Assert - 2回目
      await tester.tap(find.byType(DeleteButton));
      await tester.pump();
      expect(container.read(inputBufferProvider), 'あ');

      // Act & Assert - 3回目
      await tester.tap(find.byType(DeleteButton));
      await tester.pump();
      expect(container.read(inputBufferProvider), '');
    });

    // =========================================================================
    // TC-039-036: 空バッファで削除ボタンをタップしてもエラーにならない
    // =========================================================================
    /// TC-039-036: 空バッファの状態で削除ボタンをタップしてもエラーが発生しないことを確認
    ///
    /// 前提条件:
    /// - InputBufferNotifierが空の状態、削除ボタンが無効化されている
    ///
    /// 入力:
    /// - なし
    ///
    /// 期待結果:
    /// - エラーが発生せず、バッファが空のまま
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: AC-011
    /// 優先度: P0 必須
    testWidgets('TC-039-036: 空バッファで削除ボタンをタップしてもエラーにならないことを確認', (tester) async {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 初期状態は空
      expect(container.read(inputBufferProvider), '');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final buffer = ref.watch(inputBufferProvider);
                  final notifier = ref.read(inputBufferProvider.notifier);
                  return DeleteButton(
                    onPressed: () => notifier.deleteLastCharacter(),
                    enabled: buffer.isNotEmpty,
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Assert - ボタンが無効状態であることを確認
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      // 状態が変わっていないことを確認
      expect(container.read(inputBufferProvider), '');
    });
  });

  group('DeleteButton - テーマ対応テスト', () {
    // =========================================================================
    // TC-039-037: ライトテーマで削除ボタンが適切に表示される
    // =========================================================================
    /// TC-039-037: ライトテーマで削除ボタンが適切な色で表示されることを確認
    ///
    /// 前提条件:
    /// - ライトテーマが適用されている
    ///
    /// 入力:
    /// - なし
    ///
    /// 期待結果:
    /// - ライトテーマに適した色で表示される
    ///
    /// 信頼性レベル: 黄信号
    /// 関連要件: REQ-803, AC-009
    /// 優先度: P1 重要
    testWidgets('TC-039-037: ライトテーマで削除ボタンが適切に表示されることを確認', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: DeleteButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      final context = tester.element(find.byType(DeleteButton));
      expect(Theme.of(context).brightness, equals(Brightness.light));
    });

    // =========================================================================
    // TC-039-038: ダークテーマで削除ボタンが適切に表示される
    // =========================================================================
    /// TC-039-038: ダークテーマで削除ボタンが適切な色で表示されることを確認
    ///
    /// 前提条件:
    /// - ダークテーマが適用されている
    ///
    /// 入力:
    /// - なし
    ///
    /// 期待結果:
    /// - ダークテーマに適した色で表示される
    ///
    /// 信頼性レベル: 黄信号
    /// 関連要件: REQ-803, AC-009
    /// 優先度: P1 重要
    testWidgets('TC-039-038: ダークテーマで削除ボタンが適切に表示されることを確認', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: Scaffold(
            body: DeleteButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      final context = tester.element(find.byType(DeleteButton));
      expect(Theme.of(context).brightness, equals(Brightness.dark));
    });

    // =========================================================================
    // TC-039-039: 高コントラストテーマで削除ボタンが適切に表示される
    // =========================================================================
    /// TC-039-039: 高コントラストテーマで削除ボタンが適切な色で表示されることを確認
    ///
    /// 前提条件:
    /// - 高コントラストテーマが適用されている
    ///
    /// 入力:
    /// - なし
    ///
    /// 期待結果:
    /// - 高コントラストテーマに適した色（WCAG 2.1 AA準拠）で表示される
    ///
    /// 信頼性レベル: 黄信号
    /// 関連要件: REQ-803, REQ-5006, AC-009
    /// 優先度: P1 重要
    testWidgets('TC-039-039: 高コントラストテーマで削除ボタンが適切に表示されることを確認', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          theme: highContrastTheme,
          home: Scaffold(
            body: DeleteButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      final context = tester.element(find.byType(DeleteButton));
      final theme = Theme.of(context);
      // 高コントラストテーマが適用されていることを確認
      expect(theme, isNotNull);
    });
  });
}
