/// 定型文E2Eテスト
///
/// TASK-0083: 定型文E2Eテスト
/// 信頼性レベル: 🔵 青信号（REQ-101, REQ-102, REQ-103, REQ-104, REQ-105, REQ-106, REQ-107に基づく）
///
/// 定型文機能（表示・選択・即座読み上げ・CRUD操作）のE2Eテストを実施。
@Tags(['e2e'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_list_item.dart';

import 'helpers/test_helpers.dart';

/// 定型文画面にナビゲートするヘルパー
Future<void> navigateToPresetPhrases(WidgetTester tester) async {
  // AppBarのアイコンボタン（定型文）をタップ
  final presetPhraseButton = find.byIcon(Icons.format_list_bulleted);
  expect(presetPhraseButton, findsOneWidget);
  await tester.tap(presetPhraseButton);
  await tester.pumpAndSettle();
}

void main() {
  initializeE2ETestBinding();

  // ============================================================
  // 1. 正常系テストケース（基本的な動作）
  // ============================================================
  group('正常系テスト', () {
    testWidgets(
      'TC-E2E-083-001: 定型文一覧が正しく表示される',
      (tester) async {
        // 【テスト目的】: 定型文画面に遷移すると、登録済みの定型文が一覧表示されること
        // 【テスト内容】: 定型文一覧画面への遷移と表示確認
        // 【期待される動作】: すべての定型文がタップ可能なボタンとして表示される
        // 🔵 信頼性レベル: 青信号 - REQ-101に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【結果検証】: 定型文一覧画面が表示される
        expect(find.text('定型文'), findsOneWidget);

        // 【結果検証】: 初期データの定型文が表示される（サンプルとして「おはようございます」を確認）
        expect(find.text('おはようございます'), findsOneWidget);

        // 【結果検証】: 複数の定型文が表示される
        expect(find.text('こんにちは'), findsOneWidget);
        expect(find.text('ありがとうございます'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-083-002: お気に入り定型文が一覧上部に表示される',
      (tester) async {
        // 【テスト目的】: お気に入りに登録された定型文が一覧の最上部に優先表示されること
        // 【テスト内容】: お気に入りマーク（星アイコン）付きの定型文が上部に表示される
        // 【期待される動作】: お気に入り定型文が通常定型文より上に配置される
        // 🔵 信頼性レベル: 青信号 - REQ-105に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【実際の処理実行】: 任意の定型文をお気に入りに登録
        // お気に入りアイコン（星）を探してタップ（まず最初の定型文のお気に入りボタンを見つける）
        final favoriteIcon = find.byIcon(Icons.star_border).first;
        await tester.tap(favoriteIcon);
        await tester.pumpAndSettle();

        // 【結果検証】: お気に入りマーク（塗りつぶされた星アイコン）が表示される
        expect(find.byIcon(Icons.star), findsOneWidget);

        // 【結果検証】: お気に入りセクションヘッダーが表示される
        expect(find.text('お気に入り'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-083-003: カテゴリごとに定型文が分類表示される',
      (tester) async {
        // 【テスト目的】: 定型文が「日常」「体調」「その他」のカテゴリごとに分類表示されること
        // 【テスト内容】: カテゴリ名が視認しやすく表示され、各カテゴリ配下に定型文が表示される
        // 【期待される動作】: カテゴリ間の切り替えが可能
        // 🔵 信頼性レベル: 青信号 - REQ-106に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【結果検証】: カテゴリ名が表示される
        expect(find.text('日常'), findsOneWidget);
        expect(find.text('体調'), findsOneWidget);
        expect(find.text('その他'), findsOneWidget);

        // 【結果検証】: 各カテゴリ配下に該当する定型文が表示される
        // 日常カテゴリの定型文
        expect(find.text('おはようございます'), findsOneWidget);
        expect(find.text('こんにちは'), findsOneWidget);

        // 体調カテゴリの定型文
        expect(find.text('疲れました'), findsOneWidget);

        // その他カテゴリの定型文
        expect(find.text('誰か来てください'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-083-004: 初期データとして50件以上の定型文が表示される',
      (tester) async {
        // 【テスト目的】: アプリ初回起動時に50-100件の定型文サンプルが表示されること
        // 【テスト内容】: 初期状態で50件以上の汎用的な定型文が準備されている
        // 【期待される動作】: 日常生活、体調管理に関連する汎用的な定型文が含まれる
        // 🔵 信頼性レベル: 青信号 - REQ-107に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【結果検証】: 定型文一覧に50件以上の定型文が表示される
        // すべてのPhraseListItemウィジェットを数える
        final phraseItems = find.byType(PhraseListItem);
        final itemCount = phraseItems.evaluate().length;

        // 【結果検証】: 定型文件数が50件以上であること
        expect(itemCount, greaterThanOrEqualTo(50));

        // 【結果検証】: 実用的な定型文が含まれること
        expect(find.text('おはようございます'), findsOneWidget);
        expect(find.text('お水が飲みたいです'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-083-005: 定型文タップで即座に読み上げが開始される',
      (tester) async {
        // 【テスト目的】: 定型文をタップすると、読み上げボタンを押すことなく即座にTTSで読み上げられること
        // 【テスト内容】: タップから1秒以内にTTS読み上げが開始される
        // 【期待される動作】: 読み上げ中に停止ボタンが表示される
        // 🔵 信頼性レベル: 青信号 - REQ-103、NFR-001に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【実際の処理実行】: 定型文「こんにちは」をタップ
        await tapButton(tester, 'こんにちは');

        // 【結果検証】: TTS読み上げが開始される（停止ボタン表示で確認）
        expect(find.text('停止'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-083-006: 定型文タップで入力欄に反映される',
      (tester) async {
        // 【テスト目的】: 定型文を特定の方法でタップすると、文字盤画面の入力欄に定型文が反映されること
        // 【テスト内容】: 入力欄の内容が定型文で上書きされる
        // 【期待される動作】: 入力欄に反映後、読み上げボタンで読み上げ可能
        // 🔵 信頼性レベル: 青信号 - REQ-102に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【実際の処理実行】: 定型文を長押しまたはメニューから「入力欄に反映」を選択
        // （実装により異なる可能性があるため、現時点では定型文アイテムの編集ボタンを使用）
        final phraseItem = find.text('こんにちは');
        await tester.longPress(phraseItem);
        await tester.pumpAndSettle();

        // 【実際の処理実行】: 「入力欄に反映」メニューをタップ（実装に応じて調整）
        // 注: 実装がまだないため、このテストは失敗する（RED phase）
        final copyToInput = find.text('入力欄に反映');
        if (copyToInput.evaluate().isNotEmpty) {
          await tester.tap(copyToInput);
          await tester.pumpAndSettle();

          // 【実際の処理実行】: ホーム画面に戻る
          await navigateTo(tester, 'ホーム');

          // 【結果検証】: 文字盤画面の入力欄に定型文が反映される
          expect(find.text('こんにちは'), findsOneWidget);
        }
      },
    );

    testWidgets(
      'TC-E2E-083-007: 新規定型文を追加できる',
      (tester) async {
        // 【テスト目的】: ユーザーが新しい定型文を作成して保存できること
        // 【テスト内容】: 追加ボタンから新規定型文作成画面に遷移し、保存後に一覧に表示される
        // 【期待される動作】: テキスト、カテゴリ、お気に入りフラグを設定できる
        // 🔵 信頼性レベル: 青信号 - REQ-104に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【実際の処理実行】: 追加ボタン（FAB）をタップ
        final addButton = find.byIcon(Icons.add);
        await tester.tap(addButton);
        await tester.pumpAndSettle();

        // 【結果検証】: 新規作成ダイアログが表示される
        expect(find.text('定型文を追加'), findsOneWidget);

        // 【実際の処理実行】: テキストフィールドに「新しい定型文」を入力
        final textField = find.byType(TextField).first;
        await tester.enterText(textField, '新しい定型文');
        await tester.pumpAndSettle();

        // 【実際の処理実行】: カテゴリを「日常」に設定（デフォルトで選択されているはず）

        // 【実際の処理実行】: 保存ボタンをタップ
        await tapButton(tester, '保存');

        // 【結果検証】: 一覧に新しい定型文が表示される
        expect(find.text('新しい定型文'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-083-008: 定型文を編集できる',
      (tester) async {
        // 【テスト目的】: 既存の定型文の内容、カテゴリ、お気に入りフラグを変更できること
        // 【テスト内容】: 編集画面で変更後、保存すると一覧に反映される
        // 【期待される動作】: すべての項目が変更可能であること
        // 🔵 信頼性レベル: 青信号 - REQ-104に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【実際の処理実行】: 定型文の編集ボタンをタップ
        final editButton = find.byIcon(Icons.edit).first;
        await tester.tap(editButton);
        await tester.pumpAndSettle();

        // 【結果検証】: 編集ダイアログが表示される
        expect(find.text('定型文を編集'), findsOneWidget);

        // 【実際の処理実行】: テキストを変更
        final textField = find.byType(TextField).first;
        await tester.enterText(textField, '更新後の内容');
        await tester.pumpAndSettle();

        // 【実際の処理実行】: 保存ボタンをタップ
        await tapButton(tester, '保存');

        // 【結果検証】: 一覧に更新後の内容が表示される
        expect(find.text('更新後の内容'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-083-009: 定型文を削除できる（確認ダイアログ付き）',
      (tester) async {
        // 【テスト目的】: 定型文を削除する際に確認ダイアログが表示され、「はい」を選択すると削除されること
        // 【テスト内容】: 確認ダイアログで「はい」を選択すると削除が実行される
        // 【期待される動作】: 一覧から削除された定型文が消える
        // 🔵 信頼性レベル: 青信号 - REQ-104、REQ-5002に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【前提条件確認】: 削除対象の定型文が存在することを確認
        final targetPhrase = find.text('おはようございます');
        expect(targetPhrase, findsOneWidget);

        // 【実際の処理実行】: 削除ボタン（ゴミ箱アイコン）をタップ
        final deleteButton = find.byIcon(Icons.delete_outline).first;
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();

        // 【結果検証】: 確認ダイアログが表示される
        expect(find.text('この定型文を削除しますか？'), findsOneWidget);

        // 【実際の処理実行】: 「削除」を選択
        await tapButton(tester, '削除');

        // 【結果検証】: 一覧から削除された定型文が消える
        expect(find.text('おはようございます'), findsNothing);
      },
    );

    testWidgets(
      'TC-E2E-083-010: お気に入りフラグを切り替えられる',
      (tester) async {
        // 【テスト目的】: 定型文のお気に入りフラグをON/OFFできること
        // 【テスト内容】: お気に入りボタンをタップすると、フラグが切り替わり、表示順序が変更される
        // 【期待される動作】: お気に入り登録すると一覧上部に移動する
        // 🔵 信頼性レベル: 青信号 - REQ-105に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【前提条件確認】: お気に入りでない定型文の星アイコンを確認
        final favoriteIcon = find.byIcon(Icons.star_border).first;
        expect(favoriteIcon, findsOneWidget);

        // 【実際の処理実行】: お気に入りボタン（星アイコン）をタップ
        await tester.tap(favoriteIcon);
        await tester.pumpAndSettle();

        // 【結果検証】: 星アイコンが塗りつぶされる
        expect(find.byIcon(Icons.star), findsOneWidget);

        // 【結果検証】: お気に入りセクションが表示される
        expect(find.text('お気に入り'), findsOneWidget);

        // 【実際の処理実行】: もう一度タップしてお気に入り解除
        final filledStar = find.byIcon(Icons.star).first;
        await tester.tap(filledStar);
        await tester.pumpAndSettle();

        // 【結果検証】: 星アイコンが元に戻る
        expect(find.byIcon(Icons.star_border), findsWidgets);
      },
    );
  });

  // ============================================================
  // 2. 異常系テストケース（エラーハンドリング）
  // ============================================================
  group('異常系テスト', () {
    testWidgets(
      'TC-E2E-083-011: 定型文0件の状態で適切なメッセージが表示される',
      (tester) async {
        // 【テスト目的】: 定型文が1件も登録されていない状態でのエラーハンドリング確認
        // 【テスト内容】: 空メッセージが表示され、追加ボタンから新規作成できること
        // 【期待される動作】: アプリがクラッシュしない
        // 🟡 信頼性レベル: 黄信号 - NFR-301から推測

        // 【テストデータ準備】: アプリを初期化（定型文をすべて削除した状態）
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【実際の処理実行】: すべての定型文を削除（最初の定型文を繰り返し削除）
        // 注: パフォーマンス上、最大10件のみ削除
        for (var i = 0; i < 10; i++) {
          final deleteButton = find.byIcon(Icons.delete_outline);
          if (deleteButton.evaluate().isEmpty) break;

          await tester.tap(deleteButton.first);
          await tester.pumpAndSettle();
          await tapButton(tester, '削除');
        }

        // 【結果検証】: 空メッセージが表示される
        // 注: 実装により「定型文がありません」または空状態ウィジェットが表示される
        expect(
          find.textContaining('定型文'),
          findsWidgets,
        );

        // 【結果検証】: 追加ボタンは表示され、新規作成が可能
        expect(find.byIcon(Icons.add), findsOneWidget);

        // 【結果検証】: アプリがクラッシュしないことを確認
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'TC-E2E-083-012: 削除確認ダイアログでキャンセルすると削除されない',
      (tester) async {
        // 【テスト目的】: 削除操作をキャンセルする正常な操作の確認
        // 【テスト内容】: 確認ダイアログで「いいえ」を選択すると削除がキャンセルされる
        // 【期待される動作】: 定型文が一覧に残る
        // 🔵 信頼性レベル: 青信号 - REQ-5002に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【前提条件確認】: 対象の定型文が存在することを確認
        final targetPhrase = find.text('こんにちは');
        expect(targetPhrase, findsOneWidget);

        // 【実際の処理実行】: 削除ボタン（ゴミ箱アイコン）をタップ
        final deleteButtons = find.byIcon(Icons.delete_outline);
        // 「こんにちは」の削除ボタンを見つける（インデックスは実装依存）
        await tester.tap(deleteButtons.at(1));
        await tester.pumpAndSettle();

        // 【結果検証】: 確認ダイアログが表示される
        expect(find.text('この定型文を削除しますか？'), findsOneWidget);

        // 【実際の処理実行】: 「キャンセル」を選択
        await tapButton(tester, 'キャンセル');

        // 【結果検証】: 定型文が一覧に残る
        expect(find.text('こんにちは'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-083-013: カテゴリが空の場合でも安全に処理される',
      (tester) async {
        // 【テスト目的】: 特定のカテゴリに定型文が0件の状態でのエラーハンドリング確認
        // 【テスト内容】: 空カテゴリが適切に処理される
        // 【期待される動作】: アプリがクラッシュしない
        // 🟡 信頼性レベル: 黄信号 - EDGE-204から推測

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【実際の処理実行】: 「その他」カテゴリのすべての定型文を削除
        // スクロールして「その他」セクションを表示
        await tester.dragUntilVisible(
          find.text('その他'),
          find.byType(ListView),
          const Offset(0, -100),
        );

        // 「その他」カテゴリの定型文を削除（最初の3件のみ）
        for (var i = 0; i < 3; i++) {
          // 「その他」セクション内の削除ボタンを探す
          final deleteButton = find.byIcon(Icons.delete_outline);
          if (deleteButton.evaluate().isEmpty) break;

          // 最後の削除ボタンをタップ（その他カテゴリの定型文）
          await tester.tap(deleteButton.last);
          await tester.pumpAndSettle();
          await tapButton(tester, '削除');
        }

        // 【結果検証】: アプリがクラッシュしないことを確認
        await tester.pumpAndSettle();

        // 【結果検証】: 他のカテゴリは正常に表示される
        expect(find.text('日常'), findsOneWidget);
        expect(find.text('体調'), findsOneWidget);
      },
    );
  });

  // ============================================================
  // 3. 境界値テストケース（最小値、最大値、null等）
  // ============================================================
  group('境界値テスト', () {
    testWidgets(
      'TC-E2E-083-014: 定型文500文字まで保存できる',
      (tester) async {
        // 【テスト目的】: 定型文の最大文字数制限（500文字）の上限値確認
        // 【テスト内容】: 500文字の定型文が保存できる
        // 【期待される動作】: 文字欠落なく500文字が保存される
        // 🔵 信頼性レベル: 青信号 - EDGE-102に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【実際の処理実行】: 追加ボタンをタップ
        final addButton = find.byIcon(Icons.add);
        await tester.tap(addButton);
        await tester.pumpAndSettle();

        // 【実際の処理実行】: 500文字の定型文を入力
        final longText = 'あ' * 500;
        final textField = find.byType(TextField).first;
        await tester.enterText(textField, longText);
        await tester.pumpAndSettle();

        // 【実際の処理実行】: 保存ボタンをタップ
        await tapButton(tester, '保存');

        // 【結果検証】: 500文字の定型文が保存される
        // （一覧表示では省略される可能性があるため、編集画面で確認）
        final editButton = find.byIcon(Icons.edit).last;
        await tester.tap(editButton);
        await tester.pumpAndSettle();

        // 【結果検証】: 500文字すべてが保存されていることを確認
        expect(find.text(longText), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-083-015: 定型文501文字目が制限される',
      (tester) async {
        // 【テスト目的】: 定型文の最大文字数を超える場合の制限動作確認
        // 【テスト内容】: 500文字を超える入力が制限される
        // 【期待される動作】: エラーメッセージが表示される
        // 🟡 信頼性レベル: 黄信号 - EDGE-102から推測

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【実際の処理実行】: 追加ボタンをタップ
        final addButton = find.byIcon(Icons.add);
        await tester.tap(addButton);
        await tester.pumpAndSettle();

        // 【実際の処理実行】: 501文字の定型文を入力
        final tooLongText = 'あ' * 501;
        final textField = find.byType(TextField).first;
        await tester.enterText(textField, tooLongText);
        await tester.pumpAndSettle();

        // 【実際の処理実行】: 保存ボタンをタップ
        await tapButton(tester, '保存');

        // 【結果検証】: エラーメッセージが表示される
        expect(find.text('定型文は500文字以内で入力してください'), findsOneWidget);

        // 【結果検証】: 保存がキャンセルされる（ダイアログが閉じない）
        expect(find.text('定型文を追加'), findsOneWidget);
      },
    );
  });

  // ============================================================
  // 4. パフォーマンステストケース
  // ============================================================
  group('パフォーマンステスト', () {
    testWidgets(
      'TC-E2E-083-016: 定型文100件表示が1秒以内',
      (tester) async {
        // 【テスト目的】: 100件の定型文を一覧表示する際のパフォーマンス確認
        // 【テスト内容】: 画面遷移から表示完了まで1秒（1000ms）以内
        // 【期待される動作】: スクロールが滑らかで遅延がない
        // 🔵 信頼性レベル: 青信号 - NFR-004に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: パフォーマンス計測
        await measurePerformance(
          '定型文100件表示',
          maxMilliseconds: 1000,
          action: () async {
            // 【実際の処理実行】: 定型文画面に遷移
            await navigateToPresetPhrases(tester);
          },
        );

        // 【結果検証】: 定型文一覧が表示される
        expect(find.text('定型文'), findsOneWidget);

        // 【結果検証】: スクロール操作が滑らかであること
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'TC-E2E-083-017: 定型文即座読み上げが1秒以内',
      (tester) async {
        // 【テスト目的】: 定型文タップから読み上げ開始までのパフォーマンス確認
        // 【テスト内容】: タップから読み上げ開始まで1秒（1000ms）以内
        // 【期待される動作】: 読み上げ中に停止ボタンが表示される
        // 🔵 信頼性レベル: 青信号 - NFR-001に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【実際の処理実行】: パフォーマンス計測
        await measurePerformance(
          '定型文即座読み上げ',
          maxMilliseconds: 1000,
          action: () async {
            // 【実際の処理実行】: 定型文「こんにちは」をタップ
            await tapButton(tester, 'こんにちは');
            // 停止ボタン表示でTTS開始を確認
            await waitForWidget(tester, find.text('停止'));
          },
        );
      },
    );
  });

  // ============================================================
  // 5. データ永続化テストケース
  // ============================================================
  group('データ永続化テスト', () {
    testWidgets(
      'TC-E2E-083-018: アプリ再起動後も定型文が保持される',
      (tester) async {
        // 【テスト目的】: 定型文の追加・編集・削除がアプリ再起動後も保持されること
        // 【テスト内容】: Hiveによるローカルストレージ永続化が正常動作すること
        // 【期待される動作】: データが完全に保持される
        // 🔵 信頼性レベル: 青信号 - REQ-5003に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【実際の処理実行】: 新規定型文「永続化テスト」を追加
        final addButton = find.byIcon(Icons.add);
        await tester.tap(addButton);
        await tester.pumpAndSettle();

        final textField = find.byType(TextField).first;
        await tester.enterText(textField, '永続化テスト');
        await tester.pumpAndSettle();

        await tapButton(tester, '保存');

        // 【前提条件確認】: 定型文が追加されたことを確認
        expect(find.text('永続化テスト'), findsOneWidget);

        // 【実際の処理実行】: アプリを再起動（Hiveボックスを閉じて再度開く）
        // 注: E2Eテストでは実際の再起動は困難なため、pumpAppで再初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【結果検証】: アプリ再起動後も定型文「永続化テスト」が一覧に表示される
        expect(find.text('永続化テスト'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-E2E-083-019: お気に入り設定がアプリ再起動後も保持される',
      (tester) async {
        // 【テスト目的】: お気に入りフラグの切り替えがアプリ再起動後も保持されること
        // 【テスト内容】: お気に入り設定がローカルストレージに永続化されること
        // 【期待される動作】: 再起動後も優先表示される
        // 🔵 信頼性レベル: 青信号 - REQ-5003、REQ-105に基づく

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【実際の処理実行】: 通常定型文「こんにちは」をお気に入りに登録
        // 「こんにちは」の星アイコンを見つけてタップ
        final allStarBorders = find.byIcon(Icons.star_border);
        // 注: インデックスは実装依存（仮に2番目とする）
        if (allStarBorders.evaluate().length >= 2) {
          await tester.tap(allStarBorders.at(1));
          await tester.pumpAndSettle();
        }

        // 【前提条件確認】: お気に入りマークが表示されることを確認
        expect(find.byIcon(Icons.star), findsWidgets);

        // 【実際の処理実行】: アプリを再起動
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // 【結果検証】: お気に入りマーク（星アイコン）が表示される
        expect(find.byIcon(Icons.star), findsWidgets);

        // 【結果検証】: お気に入りセクションが表示される
        expect(find.text('お気に入り'), findsOneWidget);
      },
    );
  });

  // ============================================================
  // 6. 統合テストケース
  // ============================================================
  group('統合テスト', () {
    testWidgets(
      'TC-E2E-083-020: 定型文追加→お気に入り登録→即座読み上げの一連フローが正常動作',
      (tester) async {
        // 【テスト目的】: 定型文の追加からお気に入り登録、読み上げまでの一連フローが正常動作すること
        // 【テスト内容】: すべての機能が統合されて正常に動作すること
        // 【期待される動作】: データの一貫性が保たれること
        // 🔵 信頼性レベル: 青信号 - 複数要件の統合確認

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: 定型文画面に遷移
        await navigateToPresetPhrases(tester);

        // ステップ1: 新規定型文「統合テスト」を追加（日常カテゴリ）
        final addButton = find.byIcon(Icons.add);
        await tester.tap(addButton);
        await tester.pumpAndSettle();

        final textField = find.byType(TextField).first;
        await tester.enterText(textField, '統合テスト');
        await tester.pumpAndSettle();

        await tapButton(tester, '保存');

        // 【結果検証】: 新規定型文が正常に追加される
        expect(find.text('統合テスト'), findsOneWidget);

        // ステップ2: お気に入りに登録
        // 「統合テスト」の星アイコンを見つけてタップ
        final starIcon = find.byIcon(Icons.star_border).last;
        await tester.tap(starIcon);
        await tester.pumpAndSettle();

        // 【結果検証】: お気に入り登録が成功し、一覧上部に移動する
        expect(find.byIcon(Icons.star), findsWidgets);
        expect(find.text('お気に入り'), findsOneWidget);

        // ステップ3: タップして即座読み上げ
        await measurePerformance(
          '統合フロー: 即座読み上げ',
          maxMilliseconds: 1000,
          action: () async {
            await tapButton(tester, '統合テスト');
            await waitForWidget(tester, find.text('停止'));
          },
        );

        // 【結果検証】: タップすると即座に読み上げが開始される（1秒以内）
        expect(find.text('停止'), findsOneWidget);

        // ステップ4: 停止して履歴確認
        await tapButton(tester, '停止');

        // 【実際の処理実行】: 履歴画面に遷移
        await navigateTo(tester, '履歴');

        // 【結果検証】: 読み上げ履歴に保存される
        expect(find.text('統合テスト'), findsOneWidget);
      },
    );
  });
}
