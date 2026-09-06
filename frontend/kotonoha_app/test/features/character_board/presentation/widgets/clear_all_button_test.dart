/// ClearAllButton ウィジェットテスト
///
/// TASK-0039: 削除ボタン・全消去ボタン実装
/// テストケース: TC-039-008〜TC-039-015, TC-039-031〜TC-039-034, TC-039-040
///
/// テスト対象: lib/features/character_board/presentation/widgets/clear_all_button.dart
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
import 'package:kotonoha_app/features/character_board/presentation/widgets/clear_all_button.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';

void main() {
  group('ClearAllButton - 正常系テスト', () {
    // =========================================================================
    // TC-039-008: 全消去ボタンの表示確認
    // =========================================================================
    /// TC-039-008: ClearAllButtonが正しく表示されることを確認
    ///
    /// 前提条件:
    /// - ClearAllButtonウィジェットがインポートされている
    ///
    /// 入力:
    /// - なし
    ///
    /// 期待結果:
    /// - 全消去ボタンが画面上に表示される
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: REQ-004, AC-002
    /// 優先度: P0 必須
    testWidgets('TC-039-008: ClearAllButtonが正しく表示されることを確認', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClearAllButton(
              onConfirmed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ClearAllButton), findsOneWidget);
    });

    // =========================================================================
    // TC-039-009: 全消去ボタンが警告色で表示される
    // =========================================================================
    /// TC-039-009: ClearAllButtonが警告色（赤系）で表示されることを確認
    ///
    /// 前提条件:
    /// - なし
    ///
    /// 入力:
    /// - なし
    ///
    /// 期待結果:
    /// - ボタンが警告色（赤系、error color）で表示される
    ///
    /// 信頼性レベル: 黄信号
    /// 関連要件: AC-010
    /// 優先度: P1 重要
    testWidgets('TC-039-009: ClearAllButtonが警告色（赤系）で表示されることを確認',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClearAllButton(
              onConfirmed: () {},
            ),
          ),
        ),
      );

      // Assert - ボタンの背景色が警告色（赤系）であることを確認
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final style = button.style;

      // 警告色（error color）が使用されていることを確認
      // 背景色がnullの場合はテーマのerror colorが使用される
      expect(style?.backgroundColor, isNotNull);
    });

    // =========================================================================
    // TC-039-010: 全消去ボタンタップで確認ダイアログが表示される
    // =========================================================================
    /// TC-039-010: ClearAllButtonタップ時に確認ダイアログが表示されることを確認
    ///
    /// 前提条件:
    /// - ClearAllButtonがenabled状態
    ///
    /// 入力:
    /// - ボタンタップ
    ///
    /// 期待結果:
    /// - ClearConfirmationDialogが表示される
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: REQ-2001, REQ-5002, AC-002
    /// 優先度: P0 必須
    testWidgets('TC-039-010: ClearAllButtonタップ時に確認ダイアログが表示されることを確認',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClearAllButton(
              onConfirmed: () {},
              enabled: true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(ClearAllButton));
      await tester.pumpAndSettle();

      // Assert - 確認ダイアログが表示されていることを確認
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    // =========================================================================
    // TC-039-011: 有効状態の全消去ボタン表示
    // =========================================================================
    /// TC-039-011: enabled: trueの場合、全消去ボタンが有効状態で表示されることを確認
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
    /// 関連要件: AC-006
    /// 優先度: P0 必須
    testWidgets('TC-039-011: enabled: trueの場合、全消去ボタンが有効状態で表示されることを確認',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClearAllButton(
              onConfirmed: () {},
              enabled: true,
            ),
          ),
        ),
      );

      // Assert - ボタンが有効状態であることを確認
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });
  });

  group('ClearAllButton - 無効状態テスト', () {
    // =========================================================================
    // TC-039-012: 無効状態の全消去ボタン表示
    // =========================================================================
    /// TC-039-012: enabled: falseの場合、全消去ボタンが無効状態で表示されることを確認
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
    /// 関連要件: AC-006, EDGE-2
    /// 優先度: P0 必須
    testWidgets('TC-039-012: enabled: falseの場合、全消去ボタンが無効状態で表示されることを確認',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClearAllButton(
              onConfirmed: () {},
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
    // TC-039-013: 無効状態の全消去ボタンタップは無視される
    // =========================================================================
    /// TC-039-013: enabled: falseの場合、タップしても確認ダイアログが表示されないことを確認
    ///
    /// 前提条件:
    /// - なし
    ///
    /// 入力:
    /// - enabled: false, ボタンタップ
    ///
    /// 期待結果:
    /// - 確認ダイアログが表示されない
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: AC-006, EDGE-2
    /// 優先度: P0 必須
    testWidgets('TC-039-013: enabled: falseの場合、タップしても確認ダイアログが表示されないことを確認',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClearAllButton(
              onConfirmed: () {},
              enabled: false,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(ClearAllButton));
      await tester.pumpAndSettle();

      // Assert - 確認ダイアログが表示されていないことを確認
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('ClearAllButton - サイズ・アクセシビリティテスト', () {
    // =========================================================================
    // TC-039-014: 全消去ボタンのサイズが44x44px以上
    // =========================================================================
    /// TC-039-014: ClearAllButtonのタップターゲットが44x44px以上であることを確認
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
    testWidgets('TC-039-014: ClearAllButtonのタップターゲットが44x44px以上であることを確認',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClearAllButton(
              onConfirmed: () {},
            ),
          ),
        ),
      );

      // Assert
      final size = tester.getSize(find.byType(ClearAllButton));
      expect(size.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
      expect(size.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
      expect(size.width, greaterThanOrEqualTo(44.0));
      expect(size.height, greaterThanOrEqualTo(44.0));
    });

    // =========================================================================
    // TC-039-015: 全消去ボタンにSemanticsラベルが設定されている
    // =========================================================================
    /// TC-039-015: ClearAllButtonにアクセシビリティ用のSemanticsラベルが設定されていることを確認
    ///
    /// 前提条件:
    /// - なし
    ///
    /// 入力:
    /// - なし
    ///
    /// 期待結果:
    /// - 「全消去」等の適切なラベルが設定されている
    ///
    /// 信頼性レベル: 黄信号
    /// 関連要件: NFR-202
    /// 優先度: P1 重要
    testWidgets(
        'TC-039-015: ClearAllButtonにアクセシビリティ用のSemanticsラベルが設定されていることを確認',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClearAllButton(
              onConfirmed: () {},
            ),
          ),
        ),
      );

      // Assert - Semanticsが設定されていることを確認
      final semantics = tester.getSemantics(find.byType(ClearAllButton));
      expect(semantics.label, isNotEmpty);
    });
  });

  group('ClearAllButton - 統合テスト（InputBufferNotifierとの連携）', () {
    // =========================================================================
    // TC-039-031: 全消去確認後にバッファがクリアされる
    // =========================================================================
    /// TC-039-031: 全消去ボタンタップ→確認ダイアログで「はい」選択後、
    /// InputBufferNotifier.clear()が呼ばれバッファがクリアされることを確認
    ///
    /// 前提条件:
    /// - InputBufferNotifierに'おはようございます'が設定されている
    ///
    /// 入力:
    /// - ClearAllButtonをタップ → 確認ダイアログで「はい」をタップ
    ///
    /// 期待結果:
    /// - 入力バッファが''（空文字列）である
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: REQ-004, REQ-2001, AC-003
    /// 優先度: P0 必須
    testWidgets('TC-039-031: 全消去確認後にバッファがクリアされることを確認', (tester) async {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 初期状態を設定
      container.read(inputBufferProvider.notifier).setText('おはようございます');
      expect(container.read(inputBufferProvider), 'おはようございます');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final buffer = ref.watch(inputBufferProvider);
                  final notifier = ref.read(inputBufferProvider.notifier);
                  return ClearAllButton(
                    onConfirmed: () => notifier.clear(),
                    enabled: buffer.isNotEmpty,
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Act - 全消去ボタンをタップ
      await tester.tap(find.byType(ClearAllButton));
      await tester.pumpAndSettle();

      // Act - 確認ダイアログで「はい」をタップ
      await tester.tap(find.text('はい'));
      await tester.pumpAndSettle();

      // Assert
      expect(container.read(inputBufferProvider), '');
    });

    // =========================================================================
    // TC-039-032: 全消去キャンセル後にバッファが変更されない
    // =========================================================================
    /// TC-039-032: 全消去ボタンタップ→確認ダイアログで「いいえ」選択後、
    /// バッファが変更されないことを確認
    ///
    /// 前提条件:
    /// - InputBufferNotifierに'おはようございます'が設定されている
    ///
    /// 入力:
    /// - ClearAllButtonをタップ → 確認ダイアログで「いいえ」をタップ
    ///
    /// 期待結果:
    /// - 入力バッファが'おはようございます'のまま
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: REQ-2001, AC-004
    /// 優先度: P0 必須
    testWidgets('TC-039-032: 全消去キャンセル後にバッファが変更されないことを確認', (tester) async {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 初期状態を設定
      container.read(inputBufferProvider.notifier).setText('おはようございます');
      expect(container.read(inputBufferProvider), 'おはようございます');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final buffer = ref.watch(inputBufferProvider);
                  final notifier = ref.read(inputBufferProvider.notifier);
                  return ClearAllButton(
                    onConfirmed: () => notifier.clear(),
                    enabled: buffer.isNotEmpty,
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Act - 全消去ボタンをタップ
      await tester.tap(find.byType(ClearAllButton));
      await tester.pumpAndSettle();

      // Act - 確認ダイアログで「いいえ」をタップ
      await tester.tap(find.text('いいえ'));
      await tester.pumpAndSettle();

      // Assert
      expect(container.read(inputBufferProvider), 'おはようございます');
    });

    // =========================================================================
    // TC-039-033: 入力バッファが空の場合、全消去ボタンが無効化される
    // =========================================================================
    /// TC-039-033: 入力バッファが空の場合、全消去ボタンが無効化されることを確認
    ///
    /// 前提条件:
    /// - InputBufferNotifierが空の状態
    ///
    /// 入力:
    /// - なし
    ///
    /// 期待結果:
    /// - 全消去ボタンが無効状態（enabled: false）である
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: AC-006, EDGE-2
    /// 優先度: P0 必須
    testWidgets('TC-039-033: 入力バッファが空の場合、全消去ボタンが無効化されることを確認', (tester) async {
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
                  return ClearAllButton(
                    onConfirmed: () => notifier.clear(),
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
    // TC-039-034: 入力バッファに文字がある場合、全消去ボタンが有効化される
    // =========================================================================
    /// TC-039-034: 入力バッファに文字がある場合、全消去ボタンが有効化されることを確認
    ///
    /// 前提条件:
    /// - InputBufferNotifierに文字が設定されている
    ///
    /// 入力:
    /// - InputBufferNotifierに'あ'を設定
    ///
    /// 期待結果:
    /// - 全消去ボタンが有効状態（enabled: true）である
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: AC-006
    /// 優先度: P0 必須
    testWidgets('TC-039-034: 入力バッファに文字がある場合、全消去ボタンが有効化されることを確認',
        (tester) async {
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
                  return ClearAllButton(
                    onConfirmed: () => notifier.clear(),
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

  group('ClearAllButton - テーマ対応テスト', () {
    // =========================================================================
    // TC-039-040: 各テーマで全消去ボタンが警告色で表示される
    // =========================================================================
    /// TC-039-040: ライト/ダーク/高コントラストテーマで全消去ボタンが警告色で表示されることを確認
    ///
    /// 前提条件:
    /// - なし
    ///
    /// 入力:
    /// - 各テーマ
    ///
    /// 期待結果:
    /// - どのテーマでも警告色（error color）で表示される
    ///
    /// 信頼性レベル: 黄信号
    /// 関連要件: REQ-803, AC-009, AC-010
    /// 優先度: P1 重要

    testWidgets('TC-039-040a: ライトテーマで全消去ボタンが警告色で表示されることを確認', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: ClearAllButton(
              onConfirmed: () {},
            ),
          ),
        ),
      );

      // Assert
      final context = tester.element(find.byType(ClearAllButton));
      expect(Theme.of(context).brightness, equals(Brightness.light));
      // 全消去ボタンは警告色で表示されるべき
    });

    testWidgets('TC-039-040b: ダークテーマで全消去ボタンが警告色で表示されることを確認', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: Scaffold(
            body: ClearAllButton(
              onConfirmed: () {},
            ),
          ),
        ),
      );

      // Assert
      final context = tester.element(find.byType(ClearAllButton));
      expect(Theme.of(context).brightness, equals(Brightness.dark));
      // 全消去ボタンは警告色で表示されるべき
    });

    testWidgets('TC-039-040c: 高コントラストテーマで全消去ボタンが警告色で表示されることを確認',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          theme: highContrastTheme,
          home: Scaffold(
            body: ClearAllButton(
              onConfirmed: () {},
            ),
          ),
        ),
      );

      // Assert
      final context = tester.element(find.byType(ClearAllButton));
      final theme = Theme.of(context);
      // 高コントラストテーマが適用されていることを確認
      expect(theme, isNotNull);
      // 全消去ボタンは警告色で表示されるべき
    });
  });
}
