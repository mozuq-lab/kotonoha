/// ヘルプ画面ウィジェットテスト
///
/// TASK-0075: ヘルプ画面・初回チュートリアル実装
/// 信頼性レベル: 🔵 青信号（要件定義書ベース REQ-3001, NFR-205）
///
/// 【変更履歴】: fix/improvement-p0-p2にてHelpScreenをConsumerWidget化し
/// 「チュートリアルをもう一度見る」導線を追加したため、全テストで
/// ProviderScopeを配線するよう更新した（tutorialProviderの参照に必要）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kotonoha_app/features/help/presentation/screens/help_screen.dart';
import 'package:kotonoha_app/features/help/providers/tutorial_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HelpScreen', () {
    testWidgets('ヘルプ画面が表示される', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpScreen(),
          ),
        ),
      );

      // ヘルプ画面のタイトルが表示される
      expect(find.text('使い方'), findsOneWidget);
    });

    testWidgets('AppBarにタイトルが表示される', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpScreen(),
          ),
        ),
      );

      expect(find.text('使い方'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('基本操作セクションが表示される', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpScreen(),
          ),
        ),
      );

      expect(find.text('基本操作'), findsOneWidget);
    });

    testWidgets('文字盤の説明が表示される', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpScreen(),
          ),
        ),
      );

      expect(find.textContaining('文字盤'), findsAtLeastNWidgets(1));
    });

    testWidgets('定型文の説明が表示される', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpScreen(),
          ),
        ),
      );

      expect(find.textContaining('定型文'), findsAtLeastNWidgets(1));
    });

    testWidgets('TTS読み上げの説明が表示される', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpScreen(),
          ),
        ),
      );

      expect(find.textContaining('読み上げ'), findsAtLeastNWidgets(1));
    });

    testWidgets('緊急ボタンの説明が表示される', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpScreen(),
          ),
        ),
      );

      expect(find.textContaining('緊急'), findsAtLeastNWidgets(1));
    });

    testWidgets('対面表示モードの説明が実挙動（画面右上のアイコン・180度回転）と一致する', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpScreen(),
          ),
        ),
      );

      expect(find.textContaining('対面表示モード'), findsAtLeastNWidgets(1));
      expect(find.textContaining('180度回転'), findsAtLeastNWidgets(1));
    });

    testWidgets('誤操作防止設定セクションが表示される NFR-205', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpScreen(),
          ),
        ),
      );

      expect(find.text('誤操作防止の設定'), findsOneWidget);
    });

    testWidgets('iOSガイド付きアクセスの説明が表示される NFR-205', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpScreen(),
          ),
        ),
      );

      expect(find.textContaining('ガイド付きアクセス'), findsAtLeastNWidgets(1));
    });

    testWidgets('Android画面ピン留めの説明が表示される NFR-205', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpScreen(),
          ),
        ),
      );

      expect(find.textContaining('画面ピン留め'), findsAtLeastNWidgets(1));
    });

    testWidgets('スクロール可能なコンテンツ', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpScreen(),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('アクセシビリティ対応 - Semanticsが設定されている', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpScreen(),
          ),
        ),
      );

      // Semanticsノードが存在することを確認
      final semantics = tester.getSemantics(find.byType(HelpScreen));
      expect(semantics, isNotNull);
    });
  });

  group('HelpScreen チュートリアル再表示導線 (REQ-3001)', () {
    testWidgets('「チュートリアルをもう一度見る」ボタンが表示される', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpScreen(),
          ),
        ),
      );

      expect(find.text('チュートリアルをもう一度見る'), findsOneWidget);
    });

    testWidgets('ボタンをタップするとチュートリアルが未完了状態にリセットされる', (tester) async {
      SharedPreferences.setMockInitialValues({'tutorial_completed': true});

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(tutorialProvider.notifier).initialize();
      expect(container.read(tutorialProvider).isCompleted, isTrue);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HelpScreen(),
                    ),
                  );
                },
                child: const Text('Go to Help'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go to Help'));
      await tester.pumpAndSettle();

      // ボタンはページ末尾のセクションにあり画面外の可能性があるためスクロールする
      await tester.ensureVisible(find.text('チュートリアルをもう一度見る'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('チュートリアルをもう一度見る'));
      await tester.pumpAndSettle();

      expect(
        container.read(tutorialProvider).isCompleted,
        isFalse,
        reason: 'チュートリアルをもう一度見るボタンでisCompletedがfalseに戻る必要がある',
      );
    });

    testWidgets('ボタンをタップすると前の画面に戻る', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HelpScreen(),
                    ),
                  );
                },
                child: const Text('Go to Help'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go to Help'));
      await tester.pumpAndSettle();
      expect(find.text('使い方'), findsOneWidget);

      await tester.ensureVisible(find.text('チュートリアルをもう一度見る'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('チュートリアルをもう一度見る'));
      await tester.pumpAndSettle();

      expect(find.text('Go to Help'), findsOneWidget);
    });
  });

  group('HelpScreen navigation', () {
    testWidgets('戻るボタンで前の画面に戻れる', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HelpScreen(),
                    ),
                  );
                },
                child: const Text('Go to Help'),
              ),
            ),
          ),
        ),
      );

      // ヘルプ画面に遷移
      await tester.tap(find.text('Go to Help'));
      await tester.pumpAndSettle();

      expect(find.text('使い方'), findsOneWidget);

      // 戻るボタンをタップ
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // 元の画面に戻る
      expect(find.text('Go to Help'), findsOneWidget);
    });
  });
}
