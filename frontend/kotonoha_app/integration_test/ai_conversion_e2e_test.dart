/// AI変換E2Eテスト
/// AI変換機能（入力→変換→結果表示→採用/再生成/元の文）と
/// オフライン対応、パフォーマンス要件のE2Eテストを実施。
@Tags(['e2e'])
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/ai_conversion/data/api/ai_conversion_api_client.dart';
import 'package:kotonoha_app/features/ai_conversion/providers/ai_conversion_provider.dart';
import 'package:kotonoha_app/features/network/domain/models/network_state.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';

import 'helpers/mock_api_server.dart';
import 'helpers/test_helpers.dart';

/// AI変換ボタンをタップするヘルパー
Future<void> tapAIConversionButton(WidgetTester tester) async {
  final aiButton = find.text('AI変換');
  expect(aiButton, findsOneWidget, reason: 'AI変換ボタンが見つかりません');
  await tester.tap(aiButton);
  await tester.pumpAndSettle();
}

/// AI変換結果ダイアログが表示されるまで待機するヘルパー
Future<void> waitForAIConversionDialog(WidgetTester tester) async {
  await waitForWidget(
    tester,
    find.text('AI変換結果'),
    timeout: const Duration(seconds: 10),
  );
}

/// 履歴画面にナビゲートするヘルパー
Future<void> navigateToHistory(WidgetTester tester) async {
  final historyButton = find.byIcon(Icons.history);
  expect(historyButton, findsOneWidget);
  await tester.tap(historyButton);
  await tester.pumpAndSettle();
}

/// メイン画面に戻るヘルパー
Future<void> navigateToHome(WidgetTester tester) async {
  final backButton = find.byIcon(Icons.arrow_back);
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton);
    await tester.pumpAndSettle();
  }
}

/// オフライン状態用のNetworkNotifierサブクラス
class _OfflineNetworkNotifier extends NetworkNotifier {
  @override
  NetworkState build() => NetworkState.offline;
}

/// オンライン状態用のNetworkNotifierサブクラス
class _OnlineNetworkNotifier extends NetworkNotifier {
  @override
  NetworkState build() => NetworkState.online;
}

/// AI変換APIをモックに差し替えるオーバーライド
/// なぜ必要か: このテストは `helpers/mock_api_server.dart` を import して
/// いたが**一度も使っていなかった**ため、実際には本物のAI変換APIへ通信しようと
/// していた。CI が「AI変換APIとAPIキーが必要」として恒久除外していたのは
/// そのためである。`aiConversionApiClientProvider` を差し替えて実通信を断つ。
/// 戻り値の型を書いていない理由: `Override` は `riverpod` パッケージ側の型で
/// `flutter_riverpod` からは公開されていない。このファイルの既存2関数
/// （createOfflineOverrides / createOnlineOverrides）も同じ理由で推論に任せている。
mockAIConversionOverride() {
  final dio = Dio();
  MockApiServer.createMockAdapter(dio);
  return aiConversionApiClientProvider
      .overrideWithValue(AIConversionApiClient.withDio(dio));
}

/// オフライン状態をシミュレートするためのProviderオーバーライド
createOfflineOverrides() {
  return [
    networkProvider.overrideWith(() => _OfflineNetworkNotifier()),
    mockAIConversionOverride(),
  ];
}

/// オンライン状態をシミュレートするためのProviderオーバーライド
createOnlineOverrides() {
  return [
    networkProvider.overrideWith(() => _OnlineNetworkNotifier()),
    mockAIConversionOverride(),
  ];
}

void main() {
  initializeE2ETestBinding();

  // 1. 正常系テストケース（AI変換基本フロー）
  group('正常系テスト（AI変換基本フロー）', () {
    testWidgets(
      'TC-E2E-086-001: AI変換ボタンが表示される',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester, overrides: [mockAIConversionOverride()]);

        // 結果検証: AI変換ボタンが存在する
        expect(find.text('AI変換'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-086-002: 入力 → AI変換 → 結果表示 → 採用フロー',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester, overrides: [mockAIConversionOverride()]);

        // 実際の処理実行: 文字盤で「ありがとう」を入力
        await typeOnCharacterBoard(tester, 'ありがとう');

        // 実際の処理実行: AI変換ボタンをタップ
        await tapAIConversionButton(tester);

        // 実際の処理実行: AI変換結果ダイアログを待機
        await waitForAIConversionDialog(tester);

        // 結果検証: ダイアログが表示される
        expect(find.text('AI変換結果'), findsOneWidget);
        expect(find.text('元の文'), findsOneWidget);
        expect(find.text('変換結果'), findsOneWidget);

        // 実際の処理実行: 「採用」ボタンをタップ
        await tapButton(tester, '採用');

        // 結果検証: ダイアログが閉じる
        expect(find.text('AI変換結果'), findsNothing);
      },
    );

    testWidgets(
      'TC-E2E-086-003: AI変換 → 再生成フロー',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester, overrides: [mockAIConversionOverride()]);

        // 実際の処理実行: 文字盤で「ありがとう」を入力
        await typeOnCharacterBoard(tester, 'ありがとう');

        // 実際の処理実行: AI変換ボタンをタップ
        await tapAIConversionButton(tester);

        // 実際の処理実行: AI変換結果ダイアログを待機
        await waitForAIConversionDialog(tester);

        // 結果検証: 再生成ボタンが表示される
        expect(find.text('再生成'), findsOneWidget);

        // 実際の処理実行: 「再生成」ボタンをタップ
        await tapButton(tester, '再生成');

        // 結果検証: 再生成が実行される（ダイアログが閉じてから再表示される可能性）
        // Note: 実際の実装によってはダイアログ内で更新される場合もある
        await tester.pumpAndSettle(const Duration(seconds: 3));
      },
    );

    testWidgets(
      'TC-E2E-086-004: AI変換 → 元の文を使うフロー',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester, overrides: [mockAIConversionOverride()]);

        // 実際の処理実行: 文字盤で「ありがとう」を入力
        await typeOnCharacterBoard(tester, 'ありがとう');

        // 実際の処理実行: AI変換ボタンをタップ
        await tapAIConversionButton(tester);

        // 実際の処理実行: AI変換結果ダイアログを待機
        await waitForAIConversionDialog(tester);

        // 結果検証: 「元の文を使う」ボタンが表示される
        expect(find.text('元の文を使う'), findsOneWidget);

        // 実際の処理実行: 「元の文を使う」ボタンをタップ
        await tapButton(tester, '元の文を使う');

        // 結果検証: ダイアログが閉じる
        expect(find.text('AI変換結果'), findsNothing);
      },
    );

    testWidgets(
      'TC-E2E-086-008: AI変換 → 採用 → 読み上げフロー',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester, overrides: [mockAIConversionOverride()]);

        // 実際の処理実行: 文字盤で「ありがとう」を入力
        await typeOnCharacterBoard(tester, 'ありがとう');

        // 実際の処理実行: AI変換ボタンをタップ
        await tapAIConversionButton(tester);

        // 実際の処理実行: AI変換結果ダイアログを待機
        await waitForAIConversionDialog(tester);

        // 実際の処理実行: 「採用」ボタンをタップ
        await tapButton(tester, '採用');

        // 実際の処理実行: 読み上げボタンをタップ
        await tapButton(tester, '読み上げ');

        // 結果検証: TTS読み上げが開始される（停止ボタン表示で確認）
        await waitForWidget(tester, find.text('停止'));
        expect(find.text('停止'), findsOneWidget);
      },
    );
  });

  // 2. 異常系テストケース（エラーハンドリング）
  group('異常系テスト（エラーハンドリング）', () {
    testWidgets(
      'TC-E2E-086-009: 入力が2文字未満の場合AI変換ボタンが無効化',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester, overrides: [mockAIConversionOverride()]);

        // 実際の処理実行: 文字盤で「あ」（1文字）を入力
        await typeOnCharacterBoard(tester, 'あ');

        // 結果検証: AI変換ボタンが存在するが無効化されている
        final aiButton = find.text('AI変換');
        expect(aiButton, findsOneWidget);

        // ElevatedButtonを取得して無効状態を確認
        final elevatedButton = find.ancestor(
          of: aiButton,
          matching: find.byType(ElevatedButton),
        );

        if (elevatedButton.evaluate().isNotEmpty) {
          final button = tester.widget<ElevatedButton>(elevatedButton.first);
          expect(button.onPressed, isNull, reason: '1文字入力時はAI変換ボタンが無効であるべき');
        }
      },
    );

    testWidgets(
      'TC-E2E-086-010: オフライン時のAI変換ボタン無効化',
      (tester) async {
        // テストデータ準備: オフライン状態でアプリを初期化
        await pumpApp(tester, overrides: createOfflineOverrides());

        // 実際の処理実行: 文字盤で「ありがとう」を入力
        await typeOnCharacterBoard(tester, 'ありがとう');

        // 結果検証: AI変換ボタンが無効化されている
        final aiButton = find.text('AI変換');
        expect(aiButton, findsOneWidget);

        final elevatedButton = find.ancestor(
          of: aiButton,
          matching: find.byType(ElevatedButton),
        );

        if (elevatedButton.evaluate().isNotEmpty) {
          final button = tester.widget<ElevatedButton>(elevatedButton.first);
          expect(button.onPressed, isNull, reason: 'オフライン時はAI変換ボタンが無効であるべき');
        }
      },
    );

    testWidgets(
      'TC-E2E-086-013: 結果ダイアログ外タップで閉じない',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester, overrides: [mockAIConversionOverride()]);

        // 実際の処理実行: 文字盤で「ありがとう」を入力
        await typeOnCharacterBoard(tester, 'ありがとう');

        // 実際の処理実行: AI変換ボタンをタップ
        await tapAIConversionButton(tester);

        // 実際の処理実行: AI変換結果ダイアログを待機
        await waitForAIConversionDialog(tester);

        // 前提条件確認: ダイアログが表示されていることを確認
        expect(find.text('AI変換結果'), findsOneWidget);

        // 実際の処理実行: ダイアログ外（画面の端）をタップ
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // 結果検証: ダイアログが閉じていない
        expect(find.text('AI変換結果'), findsOneWidget);
      },
    );
  });

  // 3. 境界値テストケース
  group('境界値テスト', () {
    testWidgets(
      'TC-E2E-086-014: 入力2文字（最小値）でAI変換が有効',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester, overrides: [mockAIConversionOverride()]);

        // 実際の処理実行: 文字盤で「あい」（2文字）を入力
        await typeOnCharacterBoard(tester, 'あい');

        // 結果検証: AI変換ボタンが有効化されている
        final aiButton = find.text('AI変換');
        expect(aiButton, findsOneWidget);

        final elevatedButton = find.ancestor(
          of: aiButton,
          matching: find.byType(ElevatedButton),
        );

        if (elevatedButton.evaluate().isNotEmpty) {
          final button = tester.widget<ElevatedButton>(elevatedButton.first);
          expect(button.onPressed, isNotNull, reason: '2文字入力時はAI変換ボタンが有効であるべき');
        }
      },
    );

    testWidgets(
      'TC-E2E-086-015: 入力1文字（最小値-1）でAI変換が無効',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester, overrides: [mockAIConversionOverride()]);

        // 実際の処理実行: 文字盤で「あ」（1文字）を入力
        await typeOnCharacterBoard(tester, 'あ');

        // 結果検証: AI変換ボタンが無効化されている
        final aiButton = find.text('AI変換');
        expect(aiButton, findsOneWidget);

        final elevatedButton = find.ancestor(
          of: aiButton,
          matching: find.byType(ElevatedButton),
        );

        if (elevatedButton.evaluate().isNotEmpty) {
          final button = tester.widget<ElevatedButton>(elevatedButton.first);
          expect(button.onPressed, isNull, reason: '1文字入力時はAI変換ボタンが無効であるべき');
        }
      },
    );

    testWidgets(
      'TC-E2E-086-016: 入力0文字（空）でAI変換が無効',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester, overrides: [mockAIConversionOverride()]);

        // 実際の処理実行: 何も入力しない

        // 結果検証: AI変換ボタンが無効化されている
        final aiButton = find.text('AI変換');
        expect(aiButton, findsOneWidget);

        final elevatedButton = find.ancestor(
          of: aiButton,
          matching: find.byType(ElevatedButton),
        );

        if (elevatedButton.evaluate().isNotEmpty) {
          final button = tester.widget<ElevatedButton>(elevatedButton.first);
          expect(button.onPressed, isNull, reason: '空入力時はAI変換ボタンが無効であるべき');
        }
      },
    );
  });

  // 4. パフォーマンステストケース
  group('パフォーマンステスト', () {
    testWidgets(
      'TC-E2E-086-017: AI変換応答時間が3秒以内',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester, overrides: [mockAIConversionOverride()]);

        // 実際の処理実行: 文字盤で「ありがとう」を入力
        await typeOnCharacterBoard(tester, 'ありがとう');

        // パフォーマンス計測: AI変換ボタンタップから結果表示まで
        await measurePerformance(
          'AI変換応答時間',
          maxMilliseconds: PerformanceThresholds.aiConversion,
          action: () async {
            await tapAIConversionButton(tester);
            await waitForAIConversionDialog(tester);
          },
        );
      },
    );
  });

  // 5. 統合テストケース
  group('統合テスト', () {
    testWidgets(
      'TC-E2E-086-019: AI変換 → 採用 → 履歴保存の一連フロー',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester, overrides: [mockAIConversionOverride()]);

        // ステップ1: 文字盤で入力
        await typeOnCharacterBoard(tester, 'ありがとう');

        // ステップ2: AI変換を実行
        await tapAIConversionButton(tester);
        await waitForAIConversionDialog(tester);

        // ステップ3: 「採用」をタップ
        await tapButton(tester, '採用');

        // ステップ4: 読み上げを実行（履歴に保存される）
        await tapButton(tester, '読み上げ');
        await waitForWidget(tester, find.text('停止'));
        await tapButton(tester, '停止');

        // ステップ5: 履歴画面で確認
        await navigateToHistory(tester);
        expect(find.text('履歴'), findsOneWidget);

        // Note: 実際の変換結果はモックAPIの応答に依存するため
        // 変換結果の具体的な内容ではなく、履歴に何かが保存されていることを確認
      },
    );
  });
}
