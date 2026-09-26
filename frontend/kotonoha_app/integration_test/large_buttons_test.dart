/// 大ボタン・状態ボタンE2Eテスト
/// 大ボタン（クイック応答）と状態ボタンのE2Eテストを実施。
@Tags(['e2e'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  initializeE2ETestBinding();

  // 1. 正常系テストケース（大ボタン・クイック応答ボタン）
  group('正常系テスト（大ボタン）', () {
    testWidgets(
      'TC-E2E-084-001: 「はい」「いいえ」「わからない」ボタンが表示される',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester);

        // 結果検証: 3つのボタンがすべて表示されること
        // 検証項目: 「はい」ボタンの存在確認
        expect(find.text('はい'), findsOneWidget);
        // 検証項目: 「いいえ」ボタンの存在確認
        expect(find.text('いいえ'), findsOneWidget);
        // 検証項目: 「わからない」ボタンの存在確認
        expect(find.text('わからない'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-084-002: 「はい」ボタンタップで即座に読み上げが開始される',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester);

        // 実際の処理実行: 「はい」ボタンをタップ
        await tapAndExpectSpeech(tester, find.text('はい'));
      },
    );

    testWidgets(
      'TC-E2E-084-003: 「いいえ」ボタンタップで即座に読み上げが開始される',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester);

        // 実際の処理実行: 「いいえ」ボタンをタップ
        await tapAndExpectSpeech(tester, find.text('いいえ'));
      },
    );

    testWidgets(
      'TC-E2E-084-004: 「わからない」ボタンタップで即座に読み上げが開始される',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester);

        // 実際の処理実行: 「わからない」ボタンをタップ
        await tapAndExpectSpeech(tester, find.text('わからない'));
      },
    );

    testWidgets(
      'TC-E2E-084-005: 大ボタン連続タップがデバウンスされる',
      // Web では走らせない: デバウンスは壁時計で 300ms を見るが、CI のヘッドレス
      // Chrome（デバッグ版）は遅く、100ms 間隔のタップの間に 300ms を超える。
      // Web は保証の対象外（NFR-401）。iOS シミュレータと Android エミュレータで確かめる。
      skip: kIsWeb,
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester);

        // 実際の処理実行: 「はい」ボタンを見つける
        final yesButton = find.text('はい');
        expect(yesButton, findsOneWidget);

        // 実際の処理実行: 連続タップ（100ms間隔で2回）
        await tester.tap(yesButton);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(yesButton);
        await tester.pumpAndSettle();

        // 結果検証: デバウンス機能により、2回目のタップは無視される。
        // 受け付けた押下は 1 回ごとに履歴へ残るので、履歴の件数で確かめる
        // （「停止」ボタンは読み上げが終わると消えるので、無視されたかの証拠にならない）
        await navigateTo(tester, '履歴');
        expect(find.text('はい'), findsOneWidget, reason: '2回目のタップが無視されていない');
      },
    );
  });

  // 2. 正常系テストケース（状態ボタン）
  group('正常系テスト（状態ボタン）', () {
    testWidgets(
      'TC-E2E-084-006: 状態ボタンが8-12個表示される',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester);

        // 結果検証: 必須の状態ボタンが表示される
        // 検証項目: 「痛い」ボタンの存在確認
        await revealStatusButton(tester, '痛い');
        // 検証項目: 「トイレ」ボタンの存在確認
        await revealStatusButton(tester, 'トイレ');
        // 検証項目: 「暑い」ボタンの存在確認
        await revealStatusButton(tester, '暑い');
        // 検証項目: 「寒い」ボタンの存在確認
        await revealStatusButton(tester, '寒い');
        // 検証項目: 「水」ボタンの存在確認
        await revealStatusButton(tester, '水');
        // 検証項目: 「眠い」ボタンの存在確認
        await revealStatusButton(tester, '眠い');
        // 検証項目: 「助けて」ボタンの存在確認
        await revealStatusButton(tester, '助けて');
        // 検証項目: 「待って」ボタンの存在確認
        await revealStatusButton(tester, '待って');
      },
    );

    testWidgets(
      'TC-E2E-084-007: 「痛い」ボタンタップで即座に読み上げが開始される',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester);

        // 実際の処理実行: 「痛い」ボタンをタップ
        await tapAndExpectSpeech(tester, find.text('痛い'));
      },
    );

    testWidgets(
      'TC-E2E-084-008: 「トイレ」ボタンタップで即座に読み上げが開始される',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester);

        // 実際の処理実行: 「トイレ」ボタンをタップ
        await tapAndExpectSpeech(tester, find.text('トイレ'));
      },
    );

    testWidgets(
      'TC-E2E-084-009: すべての必須状態ボタンが正しくタップできる',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester);

        // 実際の処理実行: 必須状態ボタンを順番にテスト
        final requiredButtons = [
          '痛い',
          'トイレ',
          '暑い',
          '寒い',
          '水',
          '眠い',
          '助けて',
          '待って',
        ];

        for (final buttonLabel in requiredButtons) {
          // ボタンをタップ
          await revealStatusButton(tester, buttonLabel);
          await tapAndExpectSpeech(tester, find.text(buttonLabel));

          // 読み上げを停止して次のテストに備える（短い語は既に終わっていることがある）
          await stopSpeechIfSpeaking(tester);
        }
      },
    );
  });

  // 4. 異常系テストケース
  group('異常系テスト', () {
    testWidgets(
      'TC-E2E-084-015: 大ボタンを空の入力欄状態でタップしても安全に処理される',
      (tester) async {
        // テストデータ準備: アプリを初期化（入力欄は空）
        await pumpApp(tester);

        // 実際の処理実行: 「はい」ボタンをタップ
        await tapAndExpectSpeech(tester, find.text('はい'));

        // 結果検証: ホーム画面が引き続き表示されること
        await stopSpeechIfSpeaking(tester);
        expect(find.text('kotonoha'), findsOneWidget);
      },
    );
  });

  // 5. パフォーマンステストケース
  group('パフォーマンステスト', () {
    testWidgets(
      'TC-E2E-084-018: 大ボタンタップから読み上げ開始まで1秒以内',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester);

        // 実際の処理実行: パフォーマンス計測
        await measurePerformance(
          '大ボタン読み上げ開始',
          maxMilliseconds: 1000,
          action: () async {
            await tapAndExpectSpeech(tester, find.text('はい'));
          },
        );
      },
    );

    testWidgets(
      'TC-E2E-084-019: 状態ボタンタップから読み上げ開始まで1秒以内',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester);

        // 実際の処理実行: パフォーマンス計測
        await measurePerformance(
          '状態ボタン読み上げ開始',
          maxMilliseconds: 1000,
          action: () async {
            await tapAndExpectSpeech(tester, find.text('痛い'));
          },
        );
      },
    );
  });

  // 6. 統合テストケース
  group('統合テスト', () {
    testWidgets(
      'TC-E2E-084-020: 大ボタンタップ→読み上げ→履歴保存の一連フロー',
      (tester) async {
        // テストデータ準備: アプリを初期化
        await pumpApp(tester);

        // 実際の処理実行: 「はい」ボタンをタップして読み上げ
        await tapAndExpectSpeech(tester, find.text('はい'));

        // 実際の処理実行: 停止して履歴画面に遷移
        await stopSpeechIfSpeaking(tester);
        await navigateTo(tester, '履歴');

        // 結果検証: 履歴に「はい」が保存されている
        expect(find.text('はい'), findsOneWidget);
      },
    );
  });
}
