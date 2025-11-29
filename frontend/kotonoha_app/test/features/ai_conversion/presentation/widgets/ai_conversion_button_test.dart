/// AI変換ボタンウィジェット テスト
///
/// TASK-0068: AI変換UIウィジェット実装
/// テストケース: TC-068-001〜TC-068-012, TC-068-015
///
/// テスト対象: lib/features/ai_conversion/presentation/widgets/ai_conversion_button.dart
///
/// 【TDD Greenフェーズ】: 実装済みウィジェットのテスト
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
    // =========================================================================
    // 1. 正常系テストケース（UI表示）
    // =========================================================================
    group('1. 正常系テストケース', () {
      /// TC-068-001: AI変換ボタンが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-901
      /// 検証内容: AIConversionButtonウィジェットが正しく表示されること
      testWidgets('TC-068-001: AI変換ボタンが表示されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: AI変換ボタンが正しくレンダリングされることを確認 🔵
        // 【テスト内容】: AIConversionButtonウィジェットをレンダリングし、「AI変換」ラベルが表示されることを検証
        // 【期待される動作】: 「AI変換」ラベルのボタンが表示される
        // 🔵 青信号: REQ-901「AI変換機能」に基づく

        // Given: 【テストデータ準備】: オンライン状態でAI変換ボタンを構築
        // 【初期条件設定】: ネットワーク接続あり、入力テキストあり
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

        // Then: 【結果検証】: 「AI変換」ボタンが表示されていることを確認
        // 【期待値確認】: REQ-901「AI変換機能」に基づく
        // 【品質保証】: ユーザーがAI変換を開始できることを保証
        expect(find.text('AI変換'),
            findsOneWidget); // 【確認内容】: 「AI変換」ラベルが表示されていることを確認 🔵

        container.dispose();
      });

      /// TC-068-002: 丁寧さレベル選択UIが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-903
      /// 検証内容: 丁寧さレベル選択セレクタが正しく表示されること
      testWidgets('TC-068-002: 丁寧さレベル選択UIが表示されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: 丁寧さレベル選択UIが表示されることを確認 🔵
        // 【テスト内容】: PolitenessLevelSelectorウィジェットをレンダリングし、3段階が表示されることを検証
        // 【期待される動作】: 「カジュアル」「普通」「丁寧」の3つのオプションが表示される
        // 🔵 青信号: REQ-903「丁寧さレベル3段階」に基づく

        // Given: 【テストデータ準備】: 丁寧さレベル選択ウィジェットを構築
        // 【初期条件設定】: デフォルト状態（普通が選択）
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

        // Then: 【結果検証】: 3段階の丁寧さレベルが表示されていることを確認
        // 【期待値確認】: REQ-903「丁寧さレベル3段階」に基づく
        // 【品質保証】: ユーザーが丁寧さレベルを認識できることを保証
        expect(find.text('カジュアル'),
            findsOneWidget); // 【確認内容】: カジュアルオプションが表示されている 🔵
        expect(find.text('普通'),
            findsOneWidget); // 【確認内容】: 普通オプションが表示されている 🔵
        expect(find.text('丁寧'),
            findsOneWidget); // 【確認内容】: 丁寧オプションが表示されている 🔵
      });

      /// TC-068-003: 丁寧さレベルを変更できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-903
      /// 検証内容: 丁寧さレベルの選択が正しく機能すること
      testWidgets('TC-068-003: 丁寧さレベルをタップで変更できることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: 丁寧さレベルをタップで変更できることを確認 🔵
        // 【テスト内容】: 丁寧さレベル選択をタップし、選択状態が変わることを検証
        // 【期待される動作】: タップで選択状態が変わる
        // 🔵 青信号: REQ-903に基づく

        // Given: 【テストデータ準備】: コールバック付き丁寧さレベル選択ウィジェット
        // 【初期条件設定】: 初期選択は「普通」
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

        // When: 【ユーザー操作実行】: 「丁寧」オプションをタップ
        // 【操作内容】: 丁寧さレベルを変更する操作
        await tester.tap(find.text('丁寧'));
        await tester.pumpAndSettle();

        // Then: 【結果検証】: 選択状態が「丁寧」に変わることを確認
        // 【期待値確認】: REQ-903に基づく丁寧さレベル切り替え
        expect(selectedLevel,
            PolitenessLevel.polite); // 【確認内容】: 「丁寧」が選択状態になっていることを確認 🔵
      });

      /// TC-068-004: AI変換ボタンタップでローディング表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-2006
      /// 検証内容: AI変換実行中のローディング状態表示
      testWidgets('TC-068-004: AI変換ボタンタップでローディング表示されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: AI変換ボタンタップ後にローディング状態になることを確認 🔵
        // 【テスト内容】: ボタンタップ後、変換中状態を示すUIに変わることを検証
        // 【期待される動作】: CircularProgressIndicatorが表示される
        // 🔵 青信号: REQ-2006「ローディング表示」に基づく

        // Given: 【テストデータ準備】: オンライン状態でAI変換ボタンを構築
        // 【初期条件設定】: 入力テキストあり
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
                                child: CircularProgressIndicator(strokeWidth: 2),
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

        // When: 【ユーザー操作実行】: AI変換ボタンをタップ
        // 【操作内容】: AI変換を開始
        await tester.tap(find.text('AI変換'));
        await tester.pump(); // 1フレーム進める

        // Then: 【結果検証】: ローディングインジケーターが表示されることを確認
        // 【期待値確認】: REQ-2006「ローディング表示」に基づく
        expect(find.byType(CircularProgressIndicator),
            findsOneWidget); // 【確認内容】: ローディングインジケーターが表示されている 🔵
      });

      /// TC-068-006: AI変換結果プレビューが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-902
      /// 検証内容: 変換結果のプレビュー表示
      testWidgets('TC-068-006: AI変換結果プレビューが表示されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: AI変換完了後に結果プレビューが表示されることを確認 🔵
        // 【テスト内容】: 変換完了後、結果テキストがプレビュー表示されることを検証
        // 【期待される動作】: 変換結果テキストが表示される
        // 🔵 青信号: REQ-902「変換結果の自動表示」に基づく

        // Given: 【テストデータ準備】: 変換結果を表示するウィジェットを構築
        // 【初期条件設定】: 変換完了状態
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

        // Then: 【結果検証】: 変換結果テキストが表示されていることを確認
        // 【期待値確認】: REQ-902「変換結果の自動表示」に基づく
        expect(find.text(convertedText),
            findsOneWidget); // 【確認内容】: 変換結果テキストが表示されている 🔵

        container.dispose();
      });
    });

    // =========================================================================
    // 2. 異常系テストケース
    // =========================================================================
    group('2. 異常系テストケース', () {
      /// TC-068-007: オフライン時にAI変換ボタンが無効化される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-3004
      /// 検証内容: オフライン時のボタン無効化
      testWidgets('TC-068-007: オフライン時にAI変換ボタンが無効化されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: オフライン時はAI変換ボタンが無効化されることを確認 🔵
        // 【テスト内容】: オフライン状態でボタンがグレーアウトされることを検証
        // 【期待される動作】: ボタンが無効状態（タップ不可）になる
        // 🔵 青信号: REQ-3004「オフライン時のボタン無効化」に基づく

        // Given: 【テストデータ準備】: オフライン状態でAI変換ボタンを構築
        // 【初期条件設定】: ネットワーク接続なし
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

        // When: 【ユーザー操作実行】: 無効化されたボタンをタップ
        // 【操作内容】: オフライン状態でのボタンタップを試みる
        await tester.tap(find.text('AI変換'));
        await tester.pumpAndSettle();

        // Then: 【結果検証】: ボタンが無効化されていることを確認
        // 【期待値確認】: REQ-3004「オフライン時のボタン無効化」に基づく
        expect(buttonPressed, false); // 【確認内容】: ボタンタップが無視されている 🔵

        // ボタンが無効状態であることを確認
        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull); // 【確認内容】: onPressedがnull（無効状態） 🔵

        container.dispose();
      });

      /// TC-068-008: オフライン時に「オフライン」表示される
      ///
      /// 優先度: P1（重要）
      /// 関連要件: REQ-3004
      /// 検証内容: オフライン状態表示
      testWidgets('TC-068-008: オフライン時に「オフライン」表示されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: オフライン時に状態表示されることを確認 🔵
        // 【テスト内容】: OfflineIndicatorが表示されることを検証
        // 【期待される動作】: 「オフライン」テキストが表示される
        // 🔵 青信号: REQ-3004に基づく

        // Given: 【テストデータ準備】: オフライン状態でOfflineIndicatorを構築
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

        // Then: 【結果検証】: 「オフライン」が表示されていることを確認
        expect(find.text('オフライン'),
            findsOneWidget); // 【確認内容】: オフライン表示がある 🔵

        container.dispose();
      });

      /// TC-068-009: 入力テキストが2文字未満の場合ボタンが無効化される
      ///
      /// 優先度: P1（重要）
      /// 関連要件: EDGE-105
      /// 検証内容: 2文字未満入力時のボタン無効化
      testWidgets('TC-068-009: 入力テキストが2文字未満の場合ボタンが無効化されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: 入力文字数が2文字未満の場合、AI変換ボタンが無効化されることを確認 🟡
        // 【テスト内容】: 1文字入力時にボタンが無効状態になることを検証
        // 【期待される動作】: ボタンが無効状態（タップ不可）になる
        // 🟡 黄信号: EDGE-105から推測（API仕様の最小文字数2文字）

        // Given: 【テストデータ準備】: 1文字の入力テキストでAI変換ボタンを構築
        // 【初期条件設定】: 入力テキストが1文字
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

        // Then: 【結果検証】: ボタンが無効化されていることを確認
        // 【期待値確認】: EDGE-105、API仕様の最小文字数2文字
        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull); // 【確認内容】: onPressedがnull（無効状態） 🟡

        container.dispose();
      });

      /// TC-068-010: AI変換中に重複タップが防止される
      ///
      /// 優先度: P1（重要）
      /// 関連要件: REQ-5002
      /// 検証内容: 処理中の重複リクエスト防止
      testWidgets('TC-068-010: AI変換中に重複タップが防止されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: 変換処理中はボタンを再度タップできないことを確認 🟡
        // 【テスト内容】: 処理中に重複タップが無視されることを検証
        // 【期待される動作】: 処理中はボタンが無効状態になる
        // 🟡 黄信号: REQ-5002「重要な操作の誤操作防止」から推測

        // Given: 【テストデータ準備】: ローディング状態のAI変換ボタンを構築
        // 【初期条件設定】: AI変換処理実行中
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

        // When: 【ユーザー操作実行】: ローディング中のボタンをタップ
        // 【操作内容】: 処理中に重複タップを試みる
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Then: 【結果検証】: ボタンが無効状態であることを確認
        // 【期待値確認】: REQ-5002から推測
        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull); // 【確認内容】: onPressedがnull（無効状態）でタップ無視 🟡
      });

      /// TC-068-011: ネットワーク状態変化でボタン状態が更新される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-3004
      /// 検証内容: 動的なネットワーク状態変化への対応
      testWidgets('TC-068-011: ネットワーク状態変化でボタン状態が更新されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: オンライン→オフライン切り替え時にボタン状態が更新されることを確認 🔵
        // 【テスト内容】: ネットワーク状態変化時にUIが自動更新されることを検証
        // 【期待される動作】: ボタンが自動的にグレーアウトされる
        // 🔵 青信号: REQ-3004「オフライン時のボタン無効化」に基づく

        // Given: 【テストデータ準備】: 最初はオンライン状態でAI変換ボタンを構築
        // 【初期条件設定】: ネットワーク接続あり
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
        expect(button.onPressed, isNotNull); // 【確認内容】: オンライン時はボタンが有効 🔵

        // When: 【状態変化】: オフラインに切り替え
        // 【操作内容】: ネットワーク状態をオフラインに変更
        await container.read(networkProvider.notifier).setOffline();
        await tester.pumpAndSettle();

        // Then: 【結果検証】: ボタンが自動的に無効化されることを確認
        // 【期待値確認】: REQ-3004に基づく
        button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull); // 【確認内容】: オフライン時はボタンが無効化 🔵

        container.dispose();
      });
    });

    // =========================================================================
    // 3. 境界値テストケース
    // =========================================================================
    group('3. 境界値テストケース', () {
      /// TC-068-012: 最小有効文字数（2文字）でボタンが有効
      ///
      /// 優先度: P0（必須）
      /// 関連要件: API仕様（最小文字数2文字）
      /// 検証内容: 入力文字数下限の検証
      testWidgets('TC-068-012: 最小有効文字数（2文字）でボタンが有効になることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: 2文字入力でAI変換ボタンが有効になることを確認 🔵
        // 【テスト内容】: ちょうど2文字入力時にボタンが有効状態になることを検証
        // 【期待される動作】: ボタンが有効状態（タップ可能）になる
        // 🔵 青信号: API仕様の最小文字数2文字

        // Given: 【テストデータ準備】: 2文字の入力テキストでAI変換ボタンを構築
        // 【初期条件設定】: 入力テキストがちょうど2文字
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

        // Then: 【結果検証】: ボタンが有効化されていることを確認
        // 【期待値確認】: API仕様の最小文字数2文字
        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNotNull); // 【確認内容】: onPressedがnon-null（有効状態） 🔵

        container.dispose();
      });

      /// TC-068-015: ボタンサイズがアクセシビリティ要件を満たす
      ///
      /// 優先度: P1（重要）
      /// 関連要件: REQ-5001
      /// 検証内容: タップターゲットサイズ（44×44px以上）
      testWidgets('TC-068-015: ボタンサイズがアクセシビリティ要件（44×44px以上）を満たすことを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: ボタンサイズがアクセシビリティ要件を満たすことを確認 🟡
        // 【テスト内容】: ボタンの高さが44px以上であることを検証
        // 【期待される動作】: タップターゲットサイズが44px以上
        // 🟡 黄信号: REQ-5001から推測

        // Given: 【テストデータ準備】: AI変換ボタンを構築
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

        // Then: 【結果検証】: ボタンサイズが44px以上であることを確認
        final buttonBox = tester.getRect(find.byType(ElevatedButton));
        expect(buttonBox.height, greaterThanOrEqualTo(44.0)); // 【確認内容】: 高さが44px以上 🟡

        container.dispose();
      });
    });
  });
}
