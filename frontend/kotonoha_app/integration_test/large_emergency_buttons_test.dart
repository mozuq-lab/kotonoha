/// 大ボタン・緊急ボタンE2Eテスト
///
/// TASK-0084: 大ボタン・緊急ボタンE2Eテスト
/// 信頼性レベル: 🔵 青信号（REQ-201〜REQ-204, REQ-301〜REQ-304に基づく）
///
/// 大ボタン（クイック応答）、状態ボタン、緊急ボタン機能のE2Eテストを実施。
@Tags(['e2e'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/emergency/presentation/screens/emergency_alert_screen.dart';

import 'helpers/test_helpers.dart';

void main() {
  initializeE2ETestBinding();

  // ============================================================
  // 1. 正常系テストケース（大ボタン・クイック応答ボタン）
  // ============================================================
  group('正常系テスト（大ボタン）', () {
    testWidgets(
      'TC-E2E-084-001: 「はい」「いいえ」「わからない」ボタンが表示される',
      (tester) async {
        // 【テスト目的】: アプリ起動時に3つの大ボタンが画面上部に常時表示されること
        // 【テスト内容】: 「はい」「いいえ」「わからない」のラベルを持つボタンが表示される
        // 【期待される動作】: 3つのボタンがすべて表示される
        // 🔵 信頼性レベル: 青信号 - REQ-201に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【結果検証】: 3つのボタンがすべて表示されること
        // 【検証項目】: 「はい」ボタンの存在確認
        expect(find.text('はい'), findsOneWidget);
        // 【検証項目】: 「いいえ」ボタンの存在確認
        expect(find.text('いいえ'), findsOneWidget);
        // 【検証項目】: 「わからない」ボタンの存在確認
        expect(find.text('わからない'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-084-002: 「はい」ボタンタップで即座に読み上げが開始される',
      (tester) async {
        // 【テスト目的】: 「はい」ボタンタップでTTS読み上げが開始されること
        // 【テスト内容】: タップから1秒以内にTTS読み上げが開始される
        // 【期待される動作】: 停止ボタンが表示される（読み上げ中の証拠）
        // 🔵 信頼性レベル: 青信号 - REQ-204、NFR-001に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 「はい」ボタンをタップ
        await tapButton(tester, 'はい');

        // 【結果検証】: TTS読み上げが開始される（停止ボタン表示で確認）
        expect(find.text('停止'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-084-003: 「いいえ」ボタンタップで即座に読み上げが開始される',
      (tester) async {
        // 【テスト目的】: 「いいえ」ボタンタップでTTS読み上げが開始されること
        // 【テスト内容】: タップから1秒以内にTTS読み上げが開始される
        // 【期待される動作】: 停止ボタンが表示される
        // 🔵 信頼性レベル: 青信号 - REQ-204に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 「いいえ」ボタンをタップ
        await tapButton(tester, 'いいえ');

        // 【結果検証】: TTS読み上げが開始される
        expect(find.text('停止'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-084-004: 「わからない」ボタンタップで即座に読み上げが開始される',
      (tester) async {
        // 【テスト目的】: 「わからない」ボタンタップでTTS読み上げが開始されること
        // 【テスト内容】: タップから1秒以内にTTS読み上げが開始される
        // 【期待される動作】: 停止ボタンが表示される
        // 🔵 信頼性レベル: 青信号 - REQ-204に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 「わからない」ボタンをタップ
        await tapButton(tester, 'わからない');

        // 【結果検証】: TTS読み上げが開始される
        expect(find.text('停止'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-084-005: 大ボタン連続タップがデバウンスされる',
      (tester) async {
        // 【テスト目的】: 連続タップが適切に処理されること（デバウンス機能）
        // 【テスト内容】: 300ms以内の連続タップは1回として処理される
        // 【期待される動作】: 1回目のタップのみ処理される
        // 🟡 信頼性レベル: 黄信号 - 実装（DebounceMixin）から推測

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 「はい」ボタンを見つける
        final yesButton = find.text('はい');
        expect(yesButton, findsOneWidget);

        // 【実際の処理実行】: 連続タップ（100ms間隔で2回）
        await tester.tap(yesButton);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(yesButton);
        await tester.pumpAndSettle();

        // 【結果検証】: アプリがクラッシュせず正常動作していること
        // デバウンス機能により、2回目のタップは無視される
        expect(find.text('停止'), findsOneWidget);
      },
    );
  });

  // ============================================================
  // 2. 正常系テストケース（状態ボタン）
  // ============================================================
  group('正常系テスト（状態ボタン）', () {
    testWidgets(
      'TC-E2E-084-006: 状態ボタンが8-12個表示される',
      (tester) async {
        // 【テスト目的】: 画面に8-12個の状態ボタンが表示されること
        // 【テスト内容】: 必須8個が表示される
        // 【期待される動作】: 少なくとも8個の状態ボタンが表示される
        // 🔵 信頼性レベル: 青信号 - REQ-202、REQ-203に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【結果検証】: 必須の状態ボタンが表示される
        // 【検証項目】: 「痛い」ボタンの存在確認
        expect(find.text('痛い'), findsOneWidget);
        // 【検証項目】: 「トイレ」ボタンの存在確認
        expect(find.text('トイレ'), findsOneWidget);
        // 【検証項目】: 「暑い」ボタンの存在確認
        expect(find.text('暑い'), findsOneWidget);
        // 【検証項目】: 「寒い」ボタンの存在確認
        expect(find.text('寒い'), findsOneWidget);
        // 【検証項目】: 「水」ボタンの存在確認
        expect(find.text('水'), findsOneWidget);
        // 【検証項目】: 「眠い」ボタンの存在確認
        expect(find.text('眠い'), findsOneWidget);
        // 【検証項目】: 「助けて」ボタンの存在確認
        expect(find.text('助けて'), findsOneWidget);
        // 【検証項目】: 「待って」ボタンの存在確認
        expect(find.text('待って'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-084-007: 「痛い」ボタンタップで即座に読み上げが開始される',
      (tester) async {
        // 【テスト目的】: 状態ボタンタップでTTS読み上げが開始されること
        // 【テスト内容】: タップから1秒以内にTTS読み上げが開始される
        // 【期待される動作】: 停止ボタンが表示される
        // 🔵 信頼性レベル: 青信号 - REQ-204に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 「痛い」ボタンをタップ
        await tapButton(tester, '痛い');

        // 【結果検証】: TTS読み上げが開始される
        expect(find.text('停止'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-084-008: 「トイレ」ボタンタップで即座に読み上げが開始される',
      (tester) async {
        // 【テスト目的】: 「トイレ」ボタンタップでTTS読み上げが開始されること
        // 【テスト内容】: タップから1秒以内にTTS読み上げが開始される
        // 【期待される動作】: 停止ボタンが表示される
        // 🔵 信頼性レベル: 青信号 - REQ-204に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 「トイレ」ボタンをタップ
        await tapButton(tester, 'トイレ');

        // 【結果検証】: TTS読み上げが開始される
        expect(find.text('停止'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-084-009: すべての必須状態ボタンが正しくタップできる',
      (tester) async {
        // 【テスト目的】: 必須の8個すべてが正常に動作すること
        // 【テスト内容】: すべてのボタンでTTS読み上げが開始される
        // 【期待される動作】: 各ボタンタップでTTS読み上げが正常に開始される
        // 🔵 信頼性レベル: 青信号 - REQ-202、REQ-204に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 必須状態ボタンを順番にテスト
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
          await tapButton(tester, buttonLabel);

          // 【結果検証】: TTS読み上げが開始される
          expect(find.text('停止'), findsOneWidget,
              reason: '$buttonLabel ボタンで読み上げが開始されること');

          // 読み上げを停止して次のテストに備える
          await tapButton(tester, '停止');
        }
      },
    );
  });

  // ============================================================
  // 3. 正常系テストケース（緊急ボタン）
  // ============================================================
  group('正常系テスト（緊急ボタン）', () {
    testWidgets(
      'TC-E2E-084-010: 緊急ボタンが常時表示される',
      (tester) async {
        // 【テスト目的】: すべての画面で緊急ボタンが表示されること
        // 【テスト内容】: ホーム画面で緊急ボタンが表示される
        // 【期待される動作】: 緊急ボタン（通知アイコン）が表示される
        // 🔵 信頼性レベル: 青信号 - REQ-301に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【結果検証】: 緊急ボタンが表示される（通知アイコン）
        expect(find.byIcon(Icons.notifications_active), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-084-011: 緊急ボタンタップで確認ダイアログが表示される',
      (tester) async {
        // 【テスト目的】: 緊急ボタンタップで確認ダイアログが表示されること
        // 【テスト内容】: 「緊急呼び出しを実行しますか？」ダイアログが表示される
        // 【期待される動作】: 確認ダイアログが表示される
        // 🔵 信頼性レベル: 青信号 - REQ-302に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 緊急ボタン（通知アイコン）をタップ
        await tapIconButton(tester, Icons.notifications_active);

        // 【結果検証】: 確認ダイアログが表示される
        expect(find.text('緊急呼び出しを実行しますか？'), findsOneWidget);

        // 【結果検証】: 「はい」「いいえ」ボタンが表示される
        expect(find.text('はい'), findsWidgets); // 大ボタンにも「はい」があるのでfindsWidgets
        // ダイアログ内に「いいえ」が表示される
      },
    );

    testWidgets(
      'TC-E2E-084-012: 確認ダイアログで「いいえ」選択でキャンセル',
      (tester) async {
        // 【テスト目的】: 確認ダイアログで「いいえ」選択すると緊急処理がキャンセルされること
        // 【テスト内容】: ダイアログが閉じ、通常画面が維持される
        // 【期待される動作】: 緊急画面は表示されない
        // 🔵 信頼性レベル: 青信号 - REQ-302、REQ-5002に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 緊急ボタンをタップ
        await tapIconButton(tester, Icons.notifications_active);

        // 【前提条件確認】: 確認ダイアログが表示されている
        expect(find.text('緊急呼び出しを実行しますか？'), findsOneWidget);

        // 【実際の処理実行】: 「いいえ」ボタンをタップ
        // ダイアログ内の「いいえ」ボタンを見つける
        final noButtonInDialog = find.widgetWithText(TextButton, 'いいえ');
        expect(noButtonInDialog, findsOneWidget);
        await tester.tap(noButtonInDialog);
        await tester.pumpAndSettle();

        // 【結果検証】: ダイアログが閉じ、通常画面が維持される
        expect(find.text('緊急呼び出しを実行しますか？'), findsNothing);
        // 緊急画面は表示されない
        expect(find.byType(EmergencyAlertScreen), findsNothing);
      },
    );

    testWidgets(
      'TC-E2E-084-013: 確認ダイアログで「はい」選択で緊急処理実行',
      (tester) async {
        // 【テスト目的】: 確認ダイアログで「はい」選択すると緊急処理が実行されること
        // 【テスト内容】: 緊急音が再生され、画面が赤色の緊急画面に切り替わる
        // 【期待される動作】: 緊急画面が表示される
        // 🔵 信頼性レベル: 青信号 - REQ-303、REQ-304に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 緊急ボタンをタップ
        await tapIconButton(tester, Icons.notifications_active);

        // 【前提条件確認】: 確認ダイアログが表示されている
        expect(find.text('緊急呼び出しを実行しますか？'), findsOneWidget);

        // 【実際の処理実行】: ダイアログ内の「はい」ボタンをタップ
        final yesButtonInDialog = find.widgetWithText(TextButton, 'はい');
        expect(yesButtonInDialog, findsOneWidget);
        await tester.tap(yesButtonInDialog);
        await tester.pumpAndSettle();

        // 【結果検証】: 緊急画面が表示される
        expect(find.text('緊急呼び出し中'), findsOneWidget);
        // 【結果検証】: リセットボタンが表示される
        expect(find.text('リセット'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-084-014: 緊急画面でリセットボタンタップで通常画面に戻る',
      (tester) async {
        // 【テスト目的】: リセットボタンタップで緊急状態が解除されること
        // 【テスト内容】: 通常画面（ホーム画面）に戻る
        // 【期待される動作】: 緊急画面が消える
        // 🔵 信頼性レベル: 青信号 - 実装（EmergencyAlertScreen）に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【前提条件設定】: 緊急状態にする
        await tapIconButton(tester, Icons.notifications_active);
        final yesButtonInDialog = find.widgetWithText(TextButton, 'はい');
        await tester.tap(yesButtonInDialog);
        await tester.pumpAndSettle();

        // 【前提条件確認】: 緊急画面が表示されている
        expect(find.text('緊急呼び出し中'), findsOneWidget);

        // 【実際の処理実行】: リセットボタンをタップ
        await tapButton(tester, 'リセット');

        // 【結果検証】: 緊急画面が消える
        expect(find.text('緊急呼び出し中'), findsNothing);
        // 【結果検証】: 通常画面に戻る（kotonohaロゴが表示される）
        expect(find.text('kotonoha'), findsOneWidget);
      },
    );
  });

  // ============================================================
  // 4. 異常系テストケース
  // ============================================================
  group('異常系テスト', () {
    testWidgets(
      'TC-E2E-084-015: 大ボタンを空の入力欄状態でタップしても安全に処理される',
      (tester) async {
        // 【テスト目的】: 入力欄が空の状態での大ボタンタップ
        // 【テスト内容】: アプリのクラッシュ防止
        // 【期待される動作】: アプリがクラッシュせず、TTS読み上げが正常に開始される
        // 🟡 信頼性レベル: 黄信号 - NFR-301（安定性）から推測

        // 【テストデータ準備】: アプリを初期化（入力欄は空）
        await pumpApp(tester);

        // 【実際の処理実行】: 「はい」ボタンをタップ
        await tapButton(tester, 'はい');

        // 【結果検証】: アプリがクラッシュせず正常動作
        expect(find.text('停止'), findsOneWidget);

        // 【結果検証】: ホーム画面が引き続き表示されること
        await tapButton(tester, '停止');
        expect(find.text('kotonoha'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-084-016: 緊急ボタン誤操作防止（2段階確認）が正しく機能する',
      (tester) async {
        // 【テスト目的】: 誤って緊急ボタンをタップした場合のキャンセル
        // 【テスト内容】: 誤アラートの防止
        // 【期待される動作】: 緊急処理が実行されず、通常画面が維持される
        // 🔵 信頼性レベル: 青信号 - REQ-302、REQ-5002に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 緊急ボタンをタップ
        await tapIconButton(tester, Icons.notifications_active);

        // 【前提条件確認】: 確認ダイアログが表示される
        expect(find.text('緊急呼び出しを実行しますか？'), findsOneWidget);

        // 【実際の処理実行】: 「いいえ」を選択
        final noButtonInDialog = find.widgetWithText(TextButton, 'いいえ');
        await tester.tap(noButtonInDialog);
        await tester.pumpAndSettle();

        // 【結果検証】: 緊急処理が実行されず、通常画面が維持される
        expect(find.byType(EmergencyAlertScreen), findsNothing);
        expect(find.text('kotonoha'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-084-017: 確認ダイアログ外タップで閉じない',
      (tester) async {
        // 【テスト目的】: 確認ダイアログ外をタップしても閉じないこと
        // 【テスト内容】: 意図しないダイアログ閉鎖の防止
        // 【期待される動作】: ダイアログが閉じない（barrierDismissible: false）
        // 🔵 信頼性レベル: 青信号 - 実装（barrierDismissible: false）に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 緊急ボタンをタップ
        await tapIconButton(tester, Icons.notifications_active);

        // 【前提条件確認】: 確認ダイアログが表示される
        expect(find.text('緊急呼び出しを実行しますか？'), findsOneWidget);

        // 【実際の処理実行】: ダイアログ外（バリア）をタップ
        // ダイアログの外側をタップするためにスクリーンの端をタップ
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // 【結果検証】: ダイアログが閉じない
        expect(find.text('緊急呼び出しを実行しますか？'), findsOneWidget);

        // クリーンアップ: 「いいえ」でダイアログを閉じる
        final noButtonInDialog = find.widgetWithText(TextButton, 'いいえ');
        await tester.tap(noButtonInDialog);
        await tester.pumpAndSettle();
      },
    );
  });

  // ============================================================
  // 5. パフォーマンステストケース
  // ============================================================
  group('パフォーマンステスト', () {
    testWidgets(
      'TC-E2E-084-018: 大ボタンタップから読み上げ開始まで1秒以内',
      (tester) async {
        // 【テスト目的】: NFR-001で規定された1秒以内の要件
        // 【テスト内容】: TTS読み上げ開始が1000ms以内
        // 【期待される動作】: 停止ボタン表示まで1000ms以内
        // 🔵 信頼性レベル: 青信号 - NFR-001に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: パフォーマンス計測
        await measurePerformance(
          '大ボタン読み上げ開始',
          maxMilliseconds: 1000,
          action: () async {
            await tapButton(tester, 'はい');
            // 停止ボタン表示でTTS開始を確認
            await waitForWidget(tester, find.text('停止'));
          },
        );
      },
    );

    testWidgets(
      'TC-E2E-084-019: 状態ボタンタップから読み上げ開始まで1秒以内',
      (tester) async {
        // 【テスト目的】: NFR-001で規定された1秒以内の要件
        // 【テスト内容】: TTS読み上げ開始が1000ms以内
        // 【期待される動作】: 停止ボタン表示まで1000ms以内
        // 🔵 信頼性レベル: 青信号 - NFR-001に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: パフォーマンス計測
        await measurePerformance(
          '状態ボタン読み上げ開始',
          maxMilliseconds: 1000,
          action: () async {
            await tapButton(tester, '痛い');
            // 停止ボタン表示でTTS開始を確認
            await waitForWidget(tester, find.text('停止'));
          },
        );
      },
    );
  });

  // ============================================================
  // 6. 統合テストケース
  // ============================================================
  group('統合テスト', () {
    testWidgets(
      'TC-E2E-084-020: 大ボタンタップ→読み上げ→履歴保存の一連フロー',
      (tester) async {
        // 【テスト目的】: 大ボタンからの読み上げが履歴に保存されること
        // 【テスト内容】: 「はい」ボタンタップ→読み上げ→履歴に保存
        // 【期待される動作】: 履歴画面に「はい」が保存されている
        // 🟡 信頼性レベル: 黄信号 - 履歴保存機能との連携から推測

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 「はい」ボタンをタップして読み上げ
        await tapButton(tester, 'はい');

        // 【結果検証】: TTS読み上げが開始される
        expect(find.text('停止'), findsOneWidget);

        // 【実際の処理実行】: 停止して履歴画面に遷移
        await tapButton(tester, '停止');
        await navigateTo(tester, '履歴');

        // 【結果検証】: 履歴に「はい」が保存されている
        expect(find.text('はい'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-084-021: 緊急ボタン→確認→緊急画面→リセットの一連フロー',
      (tester) async {
        // 【テスト目的】: 緊急呼び出しからリセットまでの完全フロー
        // 【テスト内容】: 緊急ボタン→確認→緊急画面→リセット→通常画面
        // 【期待される動作】: 各段階が正常に動作する
        // 🔵 信頼性レベル: 青信号 - REQ-302〜REQ-304に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // ステップ1: 緊急ボタンをタップ
        await tapIconButton(tester, Icons.notifications_active);

        // 【結果検証】: 確認ダイアログが表示される
        expect(find.text('緊急呼び出しを実行しますか？'), findsOneWidget);

        // ステップ2: 「はい」をタップ
        final yesButtonInDialog = find.widgetWithText(TextButton, 'はい');
        await tester.tap(yesButtonInDialog);
        await tester.pumpAndSettle();

        // 【結果検証】: 緊急画面が表示される
        expect(find.text('緊急呼び出し中'), findsOneWidget);
        expect(find.text('リセット'), findsOneWidget);

        // ステップ3: リセットボタンをタップ
        await tapButton(tester, 'リセット');

        // 【結果検証】: 通常画面に戻る
        expect(find.text('緊急呼び出し中'), findsNothing);
        expect(find.text('kotonoha'), findsOneWidget);
      },
    );
  });
}
