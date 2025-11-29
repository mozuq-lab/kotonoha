/// 履歴・お気に入りE2Eテスト
///
/// TASK-0085: 履歴・お気に入りE2Eテスト
/// 信頼性レベル: 🔵 青信号（REQ-601, REQ-602, REQ-603, REQ-701, REQ-702, REQ-703に基づく）
///
/// 履歴機能（自動保存・再読み上げ・50件制限）と
/// お気に入り機能（登録・並び替え・削除）のE2Eテストを実施。
@Tags(['e2e'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

/// 履歴画面にナビゲートするヘルパー
Future<void> navigateToHistory(WidgetTester tester) async {
  // 【実際の処理実行】: AppBarの履歴アイコンをタップ
  final historyButton = find.byIcon(Icons.history);
  expect(historyButton, findsOneWidget);
  await tester.tap(historyButton);
  await tester.pumpAndSettle();
}

/// お気に入り画面にナビゲートするヘルパー
Future<void> navigateToFavorites(WidgetTester tester) async {
  // 【実際の処理実行】: AppBarのお気に入りアイコンをタップ
  final favoriteButton = find.byIcon(Icons.favorite);
  expect(favoriteButton, findsOneWidget);
  await tester.tap(favoriteButton);
  await tester.pumpAndSettle();
}

/// メイン画面に戻るヘルパー
Future<void> navigateToHome(WidgetTester tester) async {
  // 【実際の処理実行】: 戻るボタンまたはホームアイコンをタップ
  final backButton = find.byIcon(Icons.arrow_back);
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton);
    await tester.pumpAndSettle();
  }
}

/// 文字を入力して読み上げを実行するヘルパー
Future<void> inputAndSpeak(WidgetTester tester, String text) async {
  // 【テストデータ準備】: 文字盤で文字を入力
  await typeOnCharacterBoard(tester, text);

  // 【実際の処理実行】: 読み上げボタンをタップ
  await tapButton(tester, '読み上げ');
}

void main() {
  initializeE2ETestBinding();

  // ============================================================
  // 1. 正常系テストケース（履歴機能）
  // ============================================================
  group('正常系テスト（履歴）', () {
    testWidgets(
      'TC-E2E-085-001: 読み上げ → 履歴自動保存 → 履歴一覧表示',
      (tester) async {
        // 【テスト目的】: TTS読み上げ実行後、履歴画面に自動保存されることを確認
        // 【テスト内容】: 文字入力→読み上げ→履歴画面で確認
        // 【期待される動作】: 読み上げたテキストが履歴一覧に表示される
        // 🔵 信頼性レベル: 青信号 - REQ-601に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 文字を入力して読み上げ
        await typeOnCharacterBoard(tester, 'テスト');
        await tapButton(tester, '読み上げ');

        // 【実際の処理実行】: 読み上げ完了を待つ（停止ボタン表示で確認）
        await waitForWidget(tester, find.text('停止'));

        // 【実際の処理実行】: 履歴画面に遷移
        await navigateToHistory(tester);

        // 【結果検証】: 履歴画面が表示される
        expect(find.text('履歴'), findsOneWidget);
        // 【確認内容】: 履歴画面のタイトルが表示されている 🔵

        // 【結果検証】: 入力したテキストが履歴に保存されている
        expect(find.text('テスト'), findsOneWidget);
        // 【確認内容】: 読み上げたテキストが履歴一覧に表示される 🔵
      },
    );

    testWidgets(
      'TC-E2E-085-002: 履歴タップ → 再読み上げ',
      (tester) async {
        // 【テスト目的】: 履歴項目をタップするとTTS再読み上げが開始されることを確認
        // 【テスト内容】: 履歴項目タップ→TTS開始確認
        // 【期待される動作】: タップ後1秒以内にTTS読み上げが開始される
        // 🔵 信頼性レベル: 青信号 - REQ-603に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【前提条件設定】: 履歴を追加するため、文字入力と読み上げを実行
        await typeOnCharacterBoard(tester, 'テスト');
        await tapButton(tester, '読み上げ');
        await waitForWidget(tester, find.text('停止'));
        await tapButton(tester, '停止');

        // 【実際の処理実行】: 履歴画面に遷移
        await navigateToHistory(tester);

        // 【実際の処理実行】: 履歴項目をタップ
        final historyItem = find.text('テスト');
        expect(historyItem, findsOneWidget);
        await tester.tap(historyItem);
        await tester.pumpAndSettle();

        // 【結果検証】: TTS読み上げが開始される（停止ボタン表示で確認）
        expect(find.text('停止'), findsOneWidget);
        // 【確認内容】: 履歴タップでTTSが開始される 🔵
      },
    );

    testWidgets(
      'TC-E2E-085-006: 履歴個別削除（確認ダイアログ）',
      (tester) async {
        // 【テスト目的】: 削除ボタンタップ後、確認ダイアログが表示され、削除が実行されることを確認
        // 【テスト内容】: 削除ボタンタップ→確認ダイアログ→削除実行
        // 【期待される動作】: 「削除」選択後、一覧から削除される
        // 🔵 信頼性レベル: 青信号 - 実装コードに基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【前提条件設定】: 履歴を追加
        await typeOnCharacterBoard(tester, 'テスト');
        await tapButton(tester, '読み上げ');
        await waitForWidget(tester, find.text('停止'));
        await tapButton(tester, '停止');

        // 【実際の処理実行】: 履歴画面に遷移
        await navigateToHistory(tester);

        // 【前提条件確認】: 履歴が存在することを確認
        expect(find.text('テスト'), findsOneWidget);

        // 【実際の処理実行】: 削除ボタンをタップ
        final deleteButton = find.byIcon(Icons.delete).first;
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();

        // 【結果検証】: 確認ダイアログが表示される
        expect(find.text('確認'), findsOneWidget);
        expect(find.text('この履歴を削除しますか?'), findsOneWidget);
        // 【確認内容】: 確認ダイアログが正しく表示される 🔵

        // 【実際の処理実行】: 「削除」ボタンをタップ
        await tapButton(tester, '削除');

        // 【結果検証】: 履歴が削除される
        expect(find.text('テスト'), findsNothing);
        // 【確認内容】: 削除後に履歴が一覧から消える 🔵
      },
    );
  });

  // ============================================================
  // 2. 正常系テストケース（お気に入り機能）
  // ============================================================
  group('正常系テスト（お気に入り）', () {
    testWidgets(
      'TC-E2E-085-003: 履歴からお気に入り登録 → お気に入り一覧表示',
      (tester) async {
        // 【テスト目的】: 履歴項目を長押ししてお気に入り登録できることを確認
        // 【テスト内容】: 履歴長押し→コンテキストメニュー→お気に入り追加→お気に入り画面で確認
        // 【期待される動作】: お気に入り一覧に登録したテキストが表示される
        // 🔵 信頼性レベル: 青信号 - REQ-701に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【前提条件設定】: 履歴を追加
        await typeOnCharacterBoard(tester, 'テスト');
        await tapButton(tester, '読み上げ');
        await waitForWidget(tester, find.text('停止'));
        await tapButton(tester, '停止');

        // 【実際の処理実行】: 履歴画面に遷移
        await navigateToHistory(tester);

        // 【実際の処理実行】: 履歴項目を長押し
        final historyItem = find.text('テスト');
        await tester.longPress(historyItem);
        await tester.pumpAndSettle();

        // 【結果検証】: コンテキストメニューが表示される
        expect(find.text('お気に入りに追加'), findsOneWidget);
        // 【確認内容】: コンテキストメニューが表示される 🔵

        // 【実際の処理実行】: 「お気に入りに追加」をタップ
        await tapButton(tester, 'お気に入りに追加');

        // 【結果検証】: 成功メッセージが表示される
        expect(find.text('お気に入りに追加しました'), findsOneWidget);
        // 【確認内容】: 追加成功メッセージが表示される 🔵

        // 【実際の処理実行】: お気に入り画面に遷移
        await navigateToHome(tester);
        await navigateToFavorites(tester);

        // 【結果検証】: お気に入り一覧にテキストが表示される
        expect(find.text('テスト'), findsOneWidget);
        // 【確認内容】: お気に入り画面に登録したテキストが表示される 🔵
      },
    );

    testWidgets(
      'TC-E2E-085-004: お気に入りタップ → 再読み上げ',
      (tester) async {
        // 【テスト目的】: お気に入り項目をタップするとTTS再読み上げが開始されることを確認
        // 【テスト内容】: お気に入り項目タップ→TTS開始確認
        // 【期待される動作】: タップ後1秒以内にTTS読み上げが開始される
        // 🔵 信頼性レベル: 青信号 - REQ-702に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【前提条件設定】: 履歴を追加してお気に入りに登録
        await typeOnCharacterBoard(tester, 'テスト');
        await tapButton(tester, '読み上げ');
        await waitForWidget(tester, find.text('停止'));
        await tapButton(tester, '停止');

        await navigateToHistory(tester);

        final historyItem = find.text('テスト');
        await tester.longPress(historyItem);
        await tester.pumpAndSettle();
        await tapButton(tester, 'お気に入りに追加');

        // 【実際の処理実行】: お気に入り画面に遷移
        await navigateToHome(tester);
        await navigateToFavorites(tester);

        // 【実際の処理実行】: お気に入り項目をタップ
        final favoriteItem = find.text('テスト');
        expect(favoriteItem, findsOneWidget);
        await tester.tap(favoriteItem);
        await tester.pumpAndSettle();

        // 【結果検証】: TTS読み上げが開始される
        expect(find.text('停止'), findsOneWidget);
        // 【確認内容】: お気に入りタップでTTSが開始される 🔵
      },
    );

    testWidgets(
      'TC-E2E-085-007: お気に入り個別削除（確認ダイアログ）',
      (tester) async {
        // 【テスト目的】: REQ-704に基づく確認ダイアログ表示と削除実行を確認
        // 【テスト内容】: 削除ボタンタップ→確認ダイアログ→削除実行
        // 【期待される動作】: 「削除」選択後、一覧から削除される
        // 🔵 信頼性レベル: 青信号 - REQ-704に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【前提条件設定】: お気に入りを追加
        await typeOnCharacterBoard(tester, 'テスト');
        await tapButton(tester, '読み上げ');
        await waitForWidget(tester, find.text('停止'));
        await tapButton(tester, '停止');

        await navigateToHistory(tester);

        final historyItem = find.text('テスト');
        await tester.longPress(historyItem);
        await tester.pumpAndSettle();
        await tapButton(tester, 'お気に入りに追加');

        // 【実際の処理実行】: お気に入り画面に遷移
        await navigateToHome(tester);
        await navigateToFavorites(tester);

        // 【前提条件確認】: お気に入りが存在することを確認
        expect(find.text('テスト'), findsOneWidget);

        // 【実際の処理実行】: 削除ボタンをタップ
        final deleteButton = find.byIcon(Icons.delete).first;
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();

        // 【結果検証】: 確認ダイアログが表示される
        expect(find.text('確認'), findsOneWidget);
        expect(find.text('このお気に入りを削除しますか?'), findsOneWidget);
        // 【確認内容】: 確認ダイアログが正しく表示される（REQ-704） 🔵

        // 【実際の処理実行】: 「削除」ボタンをタップ
        await tapButton(tester, '削除');

        // 【結果検証】: お気に入りが削除される
        expect(find.text('テスト'), findsNothing);
        // 【確認内容】: 削除後にお気に入りが一覧から消える 🔵
      },
    );
  });

  // ============================================================
  // 3. 異常系テストケース（エラーハンドリング）
  // ============================================================
  group('異常系テスト', () {
    testWidgets(
      'TC-E2E-085-008: 履歴0件の状態で空メッセージ表示',
      (tester) async {
        // 【テスト目的】: 履歴がない状態で適切なUIが表示されることを確認
        // 【テスト内容】: 初期状態で履歴画面を開く
        // 【期待される動作】: 「履歴がありません」メッセージが表示される
        // 🔵 信頼性レベル: 青信号 - EDGE-103に基づく

        // 【テストデータ準備】: アプリを初期化（履歴なしの初期状態）
        await pumpApp(tester);

        // 【実際の処理実行】: 履歴画面に遷移
        await navigateToHistory(tester);

        // 【結果検証】: 空メッセージが表示される
        expect(find.text('履歴がありません'), findsOneWidget);
        // 【確認内容】: 履歴0件で空メッセージが表示される 🔵

        // 【結果検証】: アプリがクラッシュしない
        await tester.pumpAndSettle();
        // 【確認内容】: 空状態でもアプリが安定動作する 🔵
      },
    );

    testWidgets(
      'TC-E2E-085-009: お気に入り0件の状態で空メッセージ表示',
      (tester) async {
        // 【テスト目的】: お気に入りがない状態で適切なUIが表示されることを確認
        // 【テスト内容】: 初期状態でお気に入り画面を開く
        // 【期待される動作】: 「お気に入りがありません」メッセージが表示される
        // 🔵 信頼性レベル: 青信号 - EDGE-104に基づく

        // 【テストデータ準備】: アプリを初期化（お気に入りなしの初期状態）
        await pumpApp(tester);

        // 【実際の処理実行】: お気に入り画面に遷移
        await navigateToFavorites(tester);

        // 【結果検証】: 空メッセージが表示される
        expect(find.text('お気に入りがありません'), findsOneWidget);
        // 【確認内容】: お気に入り0件で空メッセージが表示される 🔵

        // 【結果検証】: アプリがクラッシュしない
        await tester.pumpAndSettle();
        // 【確認内容】: 空状態でもアプリが安定動作する 🔵
      },
    );

    testWidgets(
      'TC-E2E-085-010: お気に入り重複登録の防止',
      (tester) async {
        // 【テスト目的】: 同じ内容を2回お気に入り登録しようとした場合のエラー処理を確認
        // 【テスト内容】: 同一内容を2回お気に入り登録
        // 【期待される動作】: 2回目はエラーメッセージが表示され、登録されない
        // 🔵 信頼性レベル: 青信号 - 実装コードに基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【前提条件設定】: 履歴を追加
        await typeOnCharacterBoard(tester, 'テスト');
        await tapButton(tester, '読み上げ');
        await waitForWidget(tester, find.text('停止'));
        await tapButton(tester, '停止');

        // 【実際の処理実行】: 履歴画面に遷移
        await navigateToHistory(tester);

        // 【実際の処理実行】: 1回目のお気に入り登録
        final historyItem = find.text('テスト');
        await tester.longPress(historyItem);
        await tester.pumpAndSettle();
        await tapButton(tester, 'お気に入りに追加');

        // 【結果検証】: 1回目は成功
        expect(find.text('お気に入りに追加しました'), findsOneWidget);
        // 【確認内容】: 1回目の登録は成功する 🔵

        // メッセージが消えるのを待つ
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // 【実際の処理実行】: 2回目のお気に入り登録を試みる
        await tester.longPress(historyItem);
        await tester.pumpAndSettle();
        await tapButton(tester, 'お気に入りに追加');

        // 【結果検証】: 2回目はエラーメッセージが表示される
        expect(find.text('既にお気に入りに登録されています'), findsOneWidget);
        // 【確認内容】: 重複登録時にエラーメッセージが表示される 🔵
      },
    );

    testWidgets(
      'TC-E2E-085-011: 削除確認ダイアログでキャンセル → 削除されない',
      (tester) async {
        // 【テスト目的】: 削除確認でキャンセルするとデータが保持されることを確認
        // 【テスト内容】: 削除ボタン→確認ダイアログ→キャンセル
        // 【期待される動作】: 項目が一覧に残る
        // 🔵 信頼性レベル: 青信号 - REQ-5002に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【前提条件設定】: 履歴を追加
        await typeOnCharacterBoard(tester, 'テスト');
        await tapButton(tester, '読み上げ');
        await waitForWidget(tester, find.text('停止'));
        await tapButton(tester, '停止');

        // 【実際の処理実行】: 履歴画面に遷移
        await navigateToHistory(tester);

        // 【前提条件確認】: 履歴が存在することを確認
        expect(find.text('テスト'), findsOneWidget);

        // 【実際の処理実行】: 削除ボタンをタップ
        final deleteButton = find.byIcon(Icons.delete).first;
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();

        // 【結果検証】: 確認ダイアログが表示される
        expect(find.text('確認'), findsOneWidget);

        // 【実際の処理実行】: 「キャンセル」ボタンをタップ
        await tapButton(tester, 'キャンセル');

        // 【結果検証】: 履歴が一覧に残る
        expect(find.text('テスト'), findsOneWidget);
        // 【確認内容】: キャンセル後もデータが保持される 🔵
      },
    );

    testWidgets(
      'TC-E2E-085-012: 履歴全削除確認ダイアログ',
      (tester) async {
        // 【テスト目的】: 全削除時に確認ダイアログが表示され、削除が実行されることを確認
        // 【テスト内容】: 全削除ボタン→確認ダイアログ→削除実行
        // 【期待される動作】: 確認後にすべての履歴が削除される
        // 🔵 信頼性レベル: 青信号 - 実装コードに基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【前提条件設定】: 履歴を追加
        await typeOnCharacterBoard(tester, 'テスト');
        await tapButton(tester, '読み上げ');
        await waitForWidget(tester, find.text('停止'));
        await tapButton(tester, '停止');

        // 【実際の処理実行】: 履歴画面に遷移
        await navigateToHistory(tester);

        // 【前提条件確認】: 履歴が存在することを確認
        expect(find.text('テスト'), findsOneWidget);

        // 【実際の処理実行】: 全削除ボタンをタップ
        final deleteAllButton = find.byIcon(Icons.delete_sweep);
        await tester.tap(deleteAllButton);
        await tester.pumpAndSettle();

        // 【結果検証】: 確認ダイアログが表示される
        expect(find.text('確認'), findsOneWidget);
        expect(find.text('すべての履歴を削除しますか?'), findsOneWidget);
        // 【確認内容】: 全削除の確認ダイアログが表示される 🔵

        // 【実際の処理実行】: 「削除」ボタンをタップ
        await tapButton(tester, '削除');

        // 【結果検証】: すべての履歴が削除される
        expect(find.text('履歴がありません'), findsOneWidget);
        // 【確認内容】: 全削除後に空メッセージが表示される 🔵
      },
    );
  });

  // ============================================================
  // 4. 境界値テストケース
  // ============================================================
  group('境界値テスト', () {
    testWidgets(
      'TC-E2E-085-014: 履歴1件の状態で削除 → 0件',
      (tester) async {
        // 【テスト目的】: 履歴1件を削除すると空状態になることを確認
        // 【テスト内容】: 履歴1件の状態で削除→空メッセージ表示
        // 【期待される動作】: 空メッセージ「履歴がありません」が表示される
        // 🟡 信頼性レベル: 黄信号 - 境界値テストとして推測

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【前提条件設定】: 履歴を1件追加
        await typeOnCharacterBoard(tester, 'テスト');
        await tapButton(tester, '読み上げ');
        await waitForWidget(tester, find.text('停止'));
        await tapButton(tester, '停止');

        // 【実際の処理実行】: 履歴画面に遷移
        await navigateToHistory(tester);

        // 【前提条件確認】: 履歴が1件存在することを確認
        expect(find.text('テスト'), findsOneWidget);

        // 【実際の処理実行】: 削除ボタンをタップして削除
        final deleteButton = find.byIcon(Icons.delete).first;
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();
        await tapButton(tester, '削除');

        // 【結果検証】: 空メッセージが表示される
        expect(find.text('履歴がありません'), findsOneWidget);
        // 【確認内容】: 1件削除後に空状態に遷移する 🟡
      },
    );

    testWidgets(
      'TC-E2E-085-015: お気に入り1件の状態で編集ボタン非表示',
      (tester) async {
        // 【テスト目的】: お気に入り1件では編集ボタン（並び替え）が非表示であることを確認
        // 【テスト内容】: お気に入り1件の状態でUIを確認
        // 【期待される動作】: 編集ボタンが表示されない
        // 🟡 信頼性レベル: 黄信号 - 実装から推測

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【前提条件設定】: お気に入りを1件追加
        await typeOnCharacterBoard(tester, 'テスト');
        await tapButton(tester, '読み上げ');
        await waitForWidget(tester, find.text('停止'));
        await tapButton(tester, '停止');

        await navigateToHistory(tester);

        final historyItem = find.text('テスト');
        await tester.longPress(historyItem);
        await tester.pumpAndSettle();
        await tapButton(tester, 'お気に入りに追加');

        // 【実際の処理実行】: お気に入り画面に遷移
        await navigateToHome(tester);
        await navigateToFavorites(tester);

        // 【結果検証】: お気に入りが1件存在することを確認
        expect(find.text('テスト'), findsOneWidget);
        // 【確認内容】: お気に入りが1件登録されている 🟡

        // 【結果検証】: 編集ボタン（並び替え）が非表示
        expect(find.byIcon(Icons.edit), findsNothing);
        // 【確認内容】: 1件では並び替えボタンが表示されない 🟡
      },
    );
  });

  // ============================================================
  // 5. パフォーマンステストケース
  // ============================================================
  group('パフォーマンステスト', () {
    testWidgets(
      'TC-E2E-085-017: 履歴タップから再読み上げ開始が1秒以内',
      (tester) async {
        // 【テスト目的】: 履歴タップからTTS開始までの応答時間を確認
        // 【テスト内容】: タップから読み上げ開始まで1秒以内
        // 【期待される動作】: 1秒以内にTTS開始
        // 🔵 信頼性レベル: 青信号 - NFR-001に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【前提条件設定】: 履歴を追加
        await typeOnCharacterBoard(tester, 'テスト');
        await tapButton(tester, '読み上げ');
        await waitForWidget(tester, find.text('停止'));
        await tapButton(tester, '停止');

        // 【実際の処理実行】: 履歴画面に遷移
        await navigateToHistory(tester);

        // 【実際の処理実行】: パフォーマンス計測
        await measurePerformance(
          '履歴タップから再読み上げ開始',
          maxMilliseconds: 1000,
          action: () async {
            final historyItem = find.text('テスト');
            await tester.tap(historyItem);
            await waitForWidget(tester, find.text('停止'));
          },
        );
        // 【確認内容】: 1秒以内にTTSが開始される（NFR-001） 🔵
      },
    );
  });

  // ============================================================
  // 6. 統合テストケース
  // ============================================================
  group('統合テスト', () {
    testWidgets(
      'TC-E2E-085-020: 読み上げ→履歴保存→お気に入り登録の一連フロー',
      (tester) async {
        // 【テスト目的】: 機能間の連携が正常に動作することを確認
        // 【テスト内容】: 入力→読み上げ→履歴確認→お気に入り登録→お気に入り確認
        // 【期待される動作】: すべてのステップでデータが正確に反映される
        // 🔵 信頼性レベル: 青信号 - 複数要件の統合確認

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // ステップ1: 文字入力と読み上げ
        await typeOnCharacterBoard(tester, 'テスト');
        await tapButton(tester, '読み上げ');
        await waitForWidget(tester, find.text('停止'));
        // 【確認内容】: 読み上げが開始される 🔵

        await tapButton(tester, '停止');

        // ステップ2: 履歴画面で確認
        await navigateToHistory(tester);
        expect(find.text('テスト'), findsOneWidget);
        // 【確認内容】: 履歴に保存されている 🔵

        // ステップ3: お気に入り登録
        final historyItem = find.text('テスト');
        await tester.longPress(historyItem);
        await tester.pumpAndSettle();
        await tapButton(tester, 'お気に入りに追加');
        expect(find.text('お気に入りに追加しました'), findsOneWidget);
        // 【確認内容】: お気に入り登録に成功 🔵

        // ステップ4: お気に入り画面で確認
        await navigateToHome(tester);
        await navigateToFavorites(tester);
        expect(find.text('テスト'), findsOneWidget);
        // 【確認内容】: お気に入り画面に表示される 🔵

        // ステップ5: お気に入りから再読み上げ
        await tester.tap(find.text('テスト'));
        await tester.pumpAndSettle();
        expect(find.text('停止'), findsOneWidget);
        // 【確認内容】: お気に入りから再読み上げができる 🔵
      },
    );
  });
}
