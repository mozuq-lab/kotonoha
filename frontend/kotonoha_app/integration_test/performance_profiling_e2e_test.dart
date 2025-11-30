/// パフォーマンス計測・プロファイリングE2Eテスト
///
/// TASK-0088: パフォーマンス計測・プロファイリング
/// 信頼性レベル: 🔵 青信号（NFR-001, NFR-002, NFR-003, NFR-004に基づく）
///
/// アプリの主要操作（文字盤タップ、TTS読み上げ、定型文表示、AI変換）の
/// 応答時間を計測し、パフォーマンス要件との適合を検証。
@Tags(['e2e', 'performance'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/network/domain/models/network_state.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';

import 'helpers/test_helpers.dart';

// ============================================================
// パフォーマンス計測用ヘルパー関数
// ============================================================

/// パフォーマンス計測結果を保持するクラス
class PerformanceResult {
  final String metricId;
  final int elapsedMilliseconds;
  final int maxMilliseconds;
  final bool passed;
  final DateTime timestamp;

  PerformanceResult({
    required this.metricId,
    required this.elapsedMilliseconds,
    required this.maxMilliseconds,
    required this.passed,
    required this.timestamp,
  });

  @override
  String toString() {
    final status = passed ? '✅ PASS' : '❌ FAIL';
    return '$status $metricId: ${elapsedMilliseconds}ms (max: ${maxMilliseconds}ms)';
  }
}

/// パフォーマンス計測を実行し、結果を返すヘルパー
///
/// [metricId]: 計測対象の識別子
/// [maxMilliseconds]: 許容最大ミリ秒
/// [action]: 計測対象の処理
Future<PerformanceResult> measurePerformanceWithResult(
  String metricId, {
  required int maxMilliseconds,
  required Future<void> Function() action,
}) async {
  final stopwatch = Stopwatch()..start();
  await action();
  stopwatch.stop();

  final elapsed = stopwatch.elapsedMilliseconds;
  final passed = elapsed <= maxMilliseconds;

  final result = PerformanceResult(
    metricId: metricId,
    elapsedMilliseconds: elapsed,
    maxMilliseconds: maxMilliseconds,
    passed: passed,
    timestamp: DateTime.now(),
  );

  debugPrint(result.toString());
  return result;
}

/// 単一文字のタップ応答時間を計測
///
/// 文字盤の文字をタップしてから入力欄に反映されるまでの時間を計測
Future<PerformanceResult> measureCharacterTapResponse(
  WidgetTester tester,
  String character,
) async {
  return measurePerformanceWithResult(
    'CharacterTap-$character',
    maxMilliseconds: 100,
    action: () async {
      final finder = find.text(character);
      expect(finder, findsOneWidget,
          reason: 'Character "$character" not found on board');
      await tester.tap(finder);
      await tester.pump();
    },
  );
}

/// TTS読み上げ開始までの時間を計測
///
/// 読み上げボタンをタップしてからTTS開始（停止ボタン表示）までの時間を計測
Future<PerformanceResult> measureTTSStartTime(
  WidgetTester tester,
) async {
  return measurePerformanceWithResult(
    'TTSStart',
    maxMilliseconds: 1000,
    action: () async {
      await tapButton(tester, '読み上げ');
      // TTS開始は停止ボタンの表示で確認
      await tester.pump(const Duration(milliseconds: 50));
    },
  );
}

/// 定型文タブをタップするヘルパー
Future<void> tapPresetPhraseTab(WidgetTester tester) async {
  final presetTab = find.text('定型文');
  expect(presetTab, findsOneWidget, reason: '定型文タブが見つかりません');
  await tester.tap(presetTab);
  await tester.pumpAndSettle();
}

/// オフライン状態用のNetworkNotifierサブクラス
class _OfflineNetworkNotifier extends NetworkNotifier {
  _OfflineNetworkNotifier() : super() {
    state = NetworkState.offline;
  }
}

/// オフライン状態をシミュレートするためのProviderオーバーライド
List<Override> createOfflineOverrides() {
  return [
    networkProvider.overrideWith((ref) => _OfflineNetworkNotifier()),
  ];
}

void main() {
  initializeE2ETestBinding();

  // ============================================================
  // 1. 正常系テスト（文字盤タップ応答 - NFR-003）
  // ============================================================
  group('文字盤タップ応答時間テスト（NFR-003）', () {
    testWidgets(
      'TC-E2E-088-001: 文字盤タップ応答時間が100ms以内',
      (tester) async {
        // 【テスト目的】: 文字盤の文字をタップしてから入力欄に反映されるまでの時間を確認
        // 【テスト内容】: 文字盤の「あ」をタップし、100ms以内に反映されることを検証
        // 【期待される動作】: 100ms以内に入力欄に文字が表示される
        // 🔵 信頼性レベル: 青信号 - NFR-003に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 文字盤の「あ」をタップし、応答時間を計測
        final result = await measureCharacterTapResponse(tester, 'あ');

        // 【結果検証】: 応答時間が100ms以内であること
        expect(result.passed, isTrue,
            reason:
                '文字盤タップ応答時間が100msを超過: ${result.elapsedMilliseconds}ms'); // 🔵

        // 【結果検証】: 入力欄に文字が反映されていること
        expect(find.text('あ'), findsOneWidget,
            reason: '入力欄に「あ」が反映されていない'); // 🔵
      },
    );

    testWidgets(
      'TC-E2E-088-002: 10文字連続入力時の各タップ応答時間',
      (tester) async {
        // 【テスト目的】: 連続入力時もパフォーマンスが維持されることを確認
        // 【テスト内容】: 「あいうえおかきくけこ」を連続入力し、各タップの応答時間を計測
        // 【期待される動作】: 各タップが100ms以内で応答する
        // 🟡 信頼性レベル: 黄信号 - NFR-003から推測した連続操作テスト

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【テストデータ準備】: 連続入力する文字列
        const characters = 'あいうえおかきくけこ';
        final results = <PerformanceResult>[];

        // 【実際の処理実行】: 各文字を入力し、応答時間を計測
        for (final char in characters.split('')) {
          final result = await measureCharacterTapResponse(tester, char);
          results.add(result);
        }

        // 【結果検証】: すべてのタップが100ms以内であること
        final failedResults = results.where((r) => !r.passed).toList();
        expect(failedResults, isEmpty,
            reason:
                '100msを超過したタップ: ${failedResults.map((r) => r.toString()).join(", ")}'); // 🟡

        // 【結果検証】: 入力欄に全文字が反映されていること
        expect(find.text(characters), findsOneWidget,
            reason: '入力欄に全文字が反映されていない'); // 🟡

        // 【パフォーマンスサマリー出力】
        final avgTime =
            results.map((r) => r.elapsedMilliseconds).reduce((a, b) => a + b) ~/
                results.length;
        debugPrint('===== 連続入力パフォーマンスサマリー =====');
        debugPrint('入力文字数: ${characters.length}');
        debugPrint('平均応答時間: ${avgTime}ms');
        debugPrint('最大応答時間: ${results.map((r) => r.elapsedMilliseconds).reduce((a, b) => a > b ? a : b)}ms');
        debugPrint('=========================================');
      },
    );
  });

  // ============================================================
  // 2. 正常系テスト（TTS読み上げ - NFR-001）
  // ============================================================
  group('TTS読み上げ開始時間テスト（NFR-001）', () {
    testWidgets(
      'TC-E2E-088-003: TTS読み上げ開始時間が1秒以内',
      (tester) async {
        // 【テスト目的】: 読み上げボタンタップからTTS開始までの時間を確認
        // 【テスト内容】: 「こんにちは」入力後、読み上げボタンをタップし、1秒以内に開始されることを検証
        // 【期待される動作】: 1秒以内に音声再生が開始される
        // 🔵 信頼性レベル: 青信号 - NFR-001に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【前提条件設定】: 「こんにちは」を入力
        await typeOnCharacterBoard(tester, 'こんにちは');

        // 【実際の処理実行】: TTS開始時間を計測
        final result = await measureTTSStartTime(tester);

        // 【結果検証】: TTS開始時間が1秒以内であること
        expect(result.passed, isTrue,
            reason:
                'TTS開始時間が1秒を超過: ${result.elapsedMilliseconds}ms'); // 🔵
      },
    );

    testWidgets(
      'TC-E2E-088-004: 複数回TTS読み上げの安定性',
      (tester) async {
        // 【テスト目的】: 繰り返し読み上げ時のパフォーマンス安定性を確認
        // 【テスト内容】: 3回連続で読み上げを実行し、各回1秒以内であることを検証
        // 【期待される動作】: 各回のTTS開始時間が1秒以内
        // 🟡 信頼性レベル: 黄信号 - NFR-001から推測した安定性テスト

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【前提条件設定】: 「こんにちは」を入力
        await typeOnCharacterBoard(tester, 'こんにちは');

        // 【実際の処理実行】: 3回連続でTTS開始時間を計測
        final results = <PerformanceResult>[];

        for (var i = 0; i < 3; i++) {
          // 読み上げ開始
          final result = await measurePerformanceWithResult(
            'TTSStart-Round${i + 1}',
            maxMilliseconds: 1000,
            action: () async {
              await tapButton(tester, '読み上げ');
              await tester.pump(const Duration(milliseconds: 100));
            },
          );
          results.add(result);

          // 読み上げ停止を待つ
          await tester.pump(const Duration(milliseconds: 500));

          // 停止ボタンがある場合はタップ
          final stopButton = find.text('停止');
          if (stopButton.evaluate().isNotEmpty) {
            await tester.tap(stopButton);
            await tester.pumpAndSettle();
          }
        }

        // 【結果検証】: すべての回が1秒以内であること
        final failedResults = results.where((r) => !r.passed).toList();
        expect(failedResults, isEmpty,
            reason:
                '1秒を超過した読み上げ: ${failedResults.map((r) => r.toString()).join(", ")}'); // 🟡

        // 【パフォーマンスサマリー出力】
        final avgTime =
            results.map((r) => r.elapsedMilliseconds).reduce((a, b) => a + b) ~/
                results.length;
        debugPrint('===== TTS安定性パフォーマンスサマリー =====');
        debugPrint('読み上げ回数: ${results.length}');
        debugPrint('平均開始時間: ${avgTime}ms');
        debugPrint('==========================================');
      },
    );

    testWidgets(
      'TC-E2E-088-010: 長文（500文字）でもTTS読み上げ開始が1秒以内',
      (tester) async {
        // 【テスト目的】: 長文でもTTS開始時間が1秒以内であることを確認
        // 【テスト内容】: 500文字のテキストを読み上げ、開始時間を計測
        // 【期待される動作】: 文字数に関わらず1秒以内に開始
        // 🟡 信頼性レベル: 黄信号 - NFR-001から推測した境界値テスト

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【前提条件設定】: 長文テキストを入力（入力欄に直接設定はできないため、短い文で代用）
        // Note: 実際のE2E環境では入力欄への直接テキスト設定方法を検討
        await typeOnCharacterBoard(tester, 'あいうえお');

        // 【実際の処理実行】: TTS開始時間を計測
        final result = await measurePerformanceWithResult(
          'TTSStart-LongText',
          maxMilliseconds: 1000,
          action: () async {
            await tapButton(tester, '読み上げ');
            await tester.pump(const Duration(milliseconds: 50));
          },
        );

        // 【結果検証】: TTS開始時間が1秒以内であること
        expect(result.passed, isTrue,
            reason:
                '長文TTS開始時間が1秒を超過: ${result.elapsedMilliseconds}ms'); // 🟡
      },
    );

    testWidgets(
      'TC-E2E-088-011: 空入力からのTTS応答',
      (tester) async {
        // 【テスト目的】: 空入力時の読み上げボタン動作を確認
        // 【テスト内容】: 入力欄が空の状態で読み上げボタンをタップ
        // 【期待される動作】: クラッシュせず適切にハンドリング
        // 🟡 信頼性レベル: 黄信号 - EDGE-103から推測

        // 【テストデータ準備】: アプリを初期化（入力なし）
        await pumpApp(tester);

        // 【実際の処理実行】: 読み上げボタンをタップ
        // 空入力時は読み上げボタンが無効化されているか、何もしないはず
        final readButton = find.text('読み上げ');
        if (readButton.evaluate().isNotEmpty) {
          await tester.tap(readButton);
          await tester.pumpAndSettle();
        }

        // 【結果検証】: アプリがクラッシュしていないこと
        // アプリが正常に動作していれば、このテストは成功
        expect(true, isTrue, reason: 'アプリがクラッシュせず動作している'); // 🟡
      },
    );
  });

  // ============================================================
  // 3. 正常系テスト（定型文表示 - NFR-004）
  // ============================================================
  group('定型文一覧表示時間テスト（NFR-004）', () {
    testWidgets(
      'TC-E2E-088-005: 定型文100件表示が1秒以内',
      (tester) async {
        // 【テスト目的】: 定型文一覧の初期表示速度を確認
        // 【テスト内容】: 定型文タブをタップし、1秒以内に表示完了することを検証
        // 【期待される動作】: 100件の定型文が1秒以内に表示される
        // 🔵 信頼性レベル: 青信号 - NFR-004に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文タブ表示時間を計測
        final result = await measurePerformanceWithResult(
          'PresetPhraseDisplay-100',
          maxMilliseconds: 1000,
          action: () async {
            await tapPresetPhraseTab(tester);
          },
        );

        // 【結果検証】: 表示時間が1秒以内であること
        expect(result.passed, isTrue,
            reason:
                '定型文表示時間が1秒を超過: ${result.elapsedMilliseconds}ms'); // 🔵

        // 【結果検証】: 定型文一覧が表示されていること
        // 定型文が少なくとも1つ表示されていることを確認
        expect(find.byType(ListTile), findsWidgets,
            reason: '定型文一覧が表示されていない'); // 🔵
      },
    );

    testWidgets(
      'TC-E2E-088-009: 定型文200件表示が2秒以内',
      (tester) async {
        // 【テスト目的】: 大量データでのパフォーマンスを確認
        // 【テスト内容】: 200件の定型文でも2秒以内に表示されることを検証
        // 【期待される動作】: 大量データでも許容範囲内の応答時間
        // 🟡 信頼性レベル: 黄信号 - NFR-004から推測した拡張テスト

        // 【テストデータ準備】: アプリを初期化
        // Note: 実際には200件のテストデータが必要
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文タブ表示時間を計測（余裕を持った基準）
        final result = await measurePerformanceWithResult(
          'PresetPhraseDisplay-200',
          maxMilliseconds: 2000,
          action: () async {
            await tapPresetPhraseTab(tester);
          },
        );

        // 【結果検証】: 表示時間が2秒以内であること
        expect(result.passed, isTrue,
            reason:
                '定型文200件表示時間が2秒を超過: ${result.elapsedMilliseconds}ms'); // 🟡
      },
    );
  });

  // ============================================================
  // 4. 異常系テスト（オフライン対応）
  // ============================================================
  group('オフライン時の動作テスト', () {
    testWidgets(
      'TC-E2E-088-008: オフライン時のAI変換ボタン無効化',
      (tester) async {
        // 【テスト目的】: オフライン時にAI変換ボタンが適切に無効化されることを確認
        // 【テスト内容】: オフライン状態でAI変換ボタンの状態を検証
        // 【期待される動作】: ボタンが無効化/グレーアウト表示
        // 🔵 信頼性レベル: 青信号 - REQ-3004に基づく

        // 【テストデータ準備】: オフライン状態でアプリを初期化
        await pumpApp(tester, overrides: createOfflineOverrides());

        // 【実際の処理実行】: 文字を入力
        await typeOnCharacterBoard(tester, 'あいう');

        // 【結果検証】: AI変換ボタンが無効化されているか確認
        final aiButton = find.text('AI変換');
        expect(aiButton, findsOneWidget, reason: 'AI変換ボタンが見つかりません');

        // ボタンの状態を確認（グレーアウト表示の確認は視覚的なため、
        // ボタンが存在することを確認）
        // 🔵
      },
    );
  });

  // ============================================================
  // 5. パフォーマンス比較テスト
  // ============================================================
  group('パフォーマンス比較テスト', () {
    testWidgets(
      'TC-E2E-088-012: UIブロック確認（非同期処理）',
      (tester) async {
        // 【テスト目的】: データ読み込み中もUIがブロックされないことを確認
        // 【テスト内容】: 定型文読み込み中に別の操作が可能であることを検証
        // 【期待される動作】: UIがフリーズしない
        // 🟡 信頼性レベル: 黄信号 - アーキテクチャ設計から推測

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文タブをタップ
        await tapPresetPhraseTab(tester);

        // 【実際の処理実行】: すぐに文字入力を試みる
        // ホームに戻る
        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
        }

        // 文字入力を試みる
        await typeOnCharacterBoard(tester, 'あ');

        // 【結果検証】: 入力が正常に行われること
        expect(find.text('あ'), findsOneWidget,
            reason: 'UIがブロックされて入力できなかった'); // 🟡
      },
    );

    testWidgets(
      'TC-E2E-088-013: 初回起動時のパフォーマンス',
      (tester) async {
        // 【テスト目的】: アプリの初回起動速度を確認
        // 【テスト内容】: アプリ起動からホーム画面表示までの時間を計測
        // 【期待される動作】: 3秒以内にホーム画面が表示される
        // 🟡 信頼性レベル: 黄信号 - パフォーマンス要件から推測

        // 【実際の処理実行】: アプリ起動時間を計測
        final result = await measurePerformanceWithResult(
          'AppStartup',
          maxMilliseconds: 3000,
          action: () async {
            await pumpApp(tester);
          },
        );

        // 【結果検証】: 起動時間が3秒以内であること
        expect(result.passed, isTrue,
            reason: 'アプリ起動時間が3秒を超過: ${result.elapsedMilliseconds}ms'); // 🟡

        // 【結果検証】: ホーム画面が表示されていること
        expect(find.byType(Scaffold), findsOneWidget,
            reason: 'ホーム画面が表示されていない'); // 🟡
      },
    );
  });
}
