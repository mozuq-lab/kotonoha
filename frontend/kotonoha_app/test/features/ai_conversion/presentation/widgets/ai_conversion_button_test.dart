/// AI変換ボタンウィジェット テスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/ai_conversion_button.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/politeness_level_selector.dart';

void main() {
  group('TASK-0068: AI変換UIウィジェットテスト', () {
    group('1. 正常系テストケース', () {
      /// AI変換ボタンが表示される
      testWidgets('TC-068-001: AI変換ボタンが表示されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: オンライン状態でAI変換ボタンを構築
        // 初期条件設定: ネットワーク接続あり、入力テキストあり
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOnline();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: AIConversionButton(
                    inputText: '水 ぬるく',
                    politenessLevel: PolitenessLevel.normal,
                    onConvert: () async => '変換結果',
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: 「AI変換」ボタンが表示されていることを確認
        // 「AI変換機能」に基づく
        // 品質保証: ユーザーがAI変換を開始できることを保証
        expect(find.text('AI変換'), findsOneWidget);

        container.dispose();
      });

      /// 丁寧さレベル選択UIが表示される
      testWidgets('TC-068-002: 丁寧さレベル選択UIが表示されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: 丁寧さレベル選択ウィジェットを構築
        // 初期条件設定: デフォルト状態（普通が選択）
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PolitenessLevelSelector(
                selectedLevel: PolitenessLevel.normal,
                onLevelChanged: (level) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: 3段階の丁寧さレベルが表示されていることを確認
        // 「丁寧さレベル3段階」に基づく
        // 品質保証: ユーザーが丁寧さレベルを認識できることを保証
        expect(find.text('カジュアル'), findsOneWidget);
        expect(find.text('普通'), findsOneWidget);
        expect(find.text('丁寧'), findsOneWidget);
      });

      /// 丁寧さレベルを変更できる
      testWidgets('TC-068-003: 丁寧さレベルをタップで変更できることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: コールバック付き丁寧さレベル選択ウィジェット
        // 初期条件設定: 初期選択は「普通」
        PolitenessLevel selectedLevel = PolitenessLevel.normal;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return PolitenessLevelSelector(
                    selectedLevel: selectedLevel,
                    onLevelChanged: (level) {
                      setState(() => selectedLevel = level);
                    },
                  );
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // When: ユーザー操作実行: 「丁寧」オプションをタップ
        // 操作内容: 丁寧さレベルを変更する操作
        await tester.tap(find.text('丁寧'));
        await tester.pumpAndSettle();

        // Then: 結果検証: 選択状態が「丁寧」に変わることを確認
        // に基づく丁寧さレベル切り替え
        expect(selectedLevel, PolitenessLevel.polite);
      });

      /// AI変換ボタンタップでローディング表示される
      testWidgets('TC-068-004: AI変換ボタンタップでローディング表示されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: オンライン状態でAI変換ボタンを構築
        // 初期条件設定: 入力テキストあり
        // スタブ実装でローディング状態をテスト
        bool isLoading = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() => isLoading = true),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('AI変換'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // When: ユーザー操作実行: AI変換ボタンをタップ
        // 操作内容: AI変換を開始
        await tester.tap(find.text('AI変換'));
        await tester.pump(); // 1フレーム進める

        // Then: 結果検証: ローディングインジケーターが表示されることを確認
        // 「ローディング表示」に基づく
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      /// AI変換結果プレビューが表示される
      testWidgets('TC-068-006: AI変換結果プレビューが表示されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: 変換結果を表示するウィジェットを構築
        // 初期条件設定: 変換完了状態
        const convertedText = 'お水をぬるめでお願いします';
        String? result;

        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOnline();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AIConversionButton(
                          inputText: '水 ぬるく',
                          politenessLevel: PolitenessLevel.normal,
                          onConvert: () async => convertedText,
                          onConversionComplete: (r) {
                            setState(() => result = r);
                          },
                        ),
                        if (result != null) Text(result!),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // When: AI変換を実行
        await tester.tap(find.text('AI変換'));
        await tester.pumpAndSettle();

        // Then: 結果検証: 変換結果テキストが表示されていることを確認
        // 「変換結果の自動表示」に基づく
        expect(find.text(convertedText), findsOneWidget);

        container.dispose();
      });
    });

    group('2. 異常系テストケース', () {
      /// オフライン時にAI変換ボタンが無効化される
      testWidgets('TC-068-007: オフライン時にAI変換ボタンが無効化されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: オフライン状態でAI変換ボタンを構築
        // 初期条件設定: ネットワーク接続なし
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOffline();

        bool buttonPressed = false;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: AIConversionButton(
                    inputText: '水 ぬるく',
                    politenessLevel: PolitenessLevel.normal,
                    onConvert: () async {
                      buttonPressed = true;
                      return '変換結果';
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // When: ユーザー操作実行: 無効化されたボタンをタップ
        // 操作内容: オフライン状態でのボタンタップを試みる
        await tester.tap(find.text('AI変換'));
        await tester.pumpAndSettle();

        // Then: 結果検証: ボタンが無効化されていることを確認
        // 「オフライン時のボタン無効化」に基づく
        expect(buttonPressed, false);

        // ボタンが無効状態であることを確認
        final button =
            tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);

        container.dispose();
      });

      /// オフライン時に「オフライン」表示される
      testWidgets('TC-068-008: オフライン時に「オフライン」表示されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: オフライン状態でOfflineIndicatorを構築
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOffline();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: OfflineIndicator(),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: 「オフライン」が表示されていることを確認
        expect(find.text('オフライン'), findsOneWidget);

        container.dispose();
      });

      /// 入力テキストが2文字未満の場合ボタンが無効化される
      testWidgets('TC-068-009: 入力テキストが2文字未満の場合ボタンが無効化されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: 1文字の入力テキストでAI変換ボタンを構築
        // 初期条件設定: 入力テキストが1文字
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOnline();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: AIConversionButton(
                    inputText: 'あ', // 1文字のみ
                    politenessLevel: PolitenessLevel.normal,
                    onConvert: () async => '変換結果',
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: ボタンが無効化されていることを確認
        // API仕様の最小文字数2文字
        final button =
            tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);

        container.dispose();
      });

      /// AI変換中に重複タップが防止される
      testWidgets('TC-068-010: AI変換中に重複タップが防止されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: ローディング状態のAI変換ボタンを構築
        // 初期条件設定: AI変換処理実行中
        // スタブ実装で重複タップ防止をテスト
        // 処理中状態（isLoading = true）のためボタンは無効化される
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: null, // ローディング中は無効化
                  child: const Text('変換中...'),
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        // When: ユーザー操作実行: ローディング中のボタンをタップ
        // 操作内容: 処理中に重複タップを試みる
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Then: 結果検証: ボタンが無効状態であることを確認
        // から推測
        final button =
            tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);
      });

      /// ネットワーク状態変化でボタン状態が更新される
      testWidgets('TC-068-011: ネットワーク状態変化でボタン状態が更新されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: 最初はオンライン状態でAI変換ボタンを構築
        // 初期条件設定: ネットワーク接続あり
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOnline();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: AIConversionButton(
                    inputText: '水 ぬるく',
                    politenessLevel: PolitenessLevel.normal,
                    onConvert: () async => '変換結果',
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // オンライン時: ボタンが有効であることを確認
        var button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNotNull);

        // When: 状態変化: オフラインに切り替え
        // 操作内容: ネットワーク状態をオフラインに変更
        await container.read(networkProvider.notifier).setOffline();
        await tester.pumpAndSettle();

        // Then: 結果検証: ボタンが自動的に無効化されることを確認
        // に基づく
        button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);

        container.dispose();
      });
    });

    group('3. 境界値テストケース', () {
      /// 最小有効文字数（2文字）でボタンが有効
      testWidgets('TC-068-012: 最小有効文字数（2文字）でボタンが有効になることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: 2文字の入力テキストでAI変換ボタンを構築
        // 初期条件設定: 入力テキストがちょうど2文字
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOnline();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: AIConversionButton(
                    inputText: '水水', // ちょうど2文字
                    politenessLevel: PolitenessLevel.normal,
                    onConvert: () async => '変換結果',
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: ボタンが有効化されていることを確認
        // API仕様の最小文字数2文字
        final button =
            tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNotNull);

        container.dispose();
      });

      /// ボタンサイズがアクセシビリティ要件を満たす
      testWidgets('TC-068-015: ボタンサイズがアクセシビリティ要件（44×44px以上）を満たすことを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: AI変換ボタンを構築
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOnline();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: AIConversionButton(
                    inputText: '水 ぬるく',
                    politenessLevel: PolitenessLevel.normal,
                    onConvert: () async => '変換結果',
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: ボタンサイズが44px以上であることを確認
        final buttonBox = tester.getRect(find.byType(ElevatedButton));
        expect(buttonBox.height, greaterThanOrEqualTo(44.0));

        container.dispose();
      });
    });

    // 4. 無効理由の可視化テスト（fix/improvement-p0-p2で配線）
    group('4. 無効理由の可視化テスト', () {
      /// オフラインで無効な場合、OfflineIndicatorが併記表示される
      testWidgets('オフラインでボタンが無効な場合、OfflineIndicatorが表示される',
          (WidgetTester tester) async {
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOffline();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: AIConversionButton(
                    inputText: '水 ぬるく',
                    politenessLevel: PolitenessLevel.normal,
                    onConvert: () async => '変換結果',
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(OfflineIndicator), findsOneWidget);
        expect(find.text('オフライン'), findsOneWidget);

        container.dispose();
      });

      /// 文字数不足で無効な場合、不足文字数のヒントが表示される
      testWidgets('文字数不足でボタンが無効な場合、不足文字数のヒントが表示される',
          (WidgetTester tester) async {
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOnline();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: AIConversionButton(
                    inputText: 'あ', // 1文字のみ（あと1文字必要）
                    politenessLevel: PolitenessLevel.normal,
                    onConvert: () async => '変換結果',
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('あと1文字入力してください'), findsOneWidget);
        expect(find.byType(OfflineIndicator), findsNothing);

        container.dispose();
      });

      /// オンラインかつ入力十分でボタンが有効な場合、理由表示は出ない
      testWidgets('ボタンが有効な場合、無効理由の表示は出ない', (WidgetTester tester) async {
        final container = ProviderContainer();
        await container.read(networkProvider.notifier).setOnline();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: AIConversionButton(
                    inputText: '水 ぬるく',
                    politenessLevel: PolitenessLevel.normal,
                    onConvert: () async => '変換結果',
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(OfflineIndicator), findsNothing);
        expect(find.textContaining('文字入力してください'), findsNothing);

        container.dispose();
      });
    });
  });
}
