/// InputBufferProvider テスト
///
/// TASK-0038: 文字入力バッファ管理（Riverpod StateNotifier）
///
/// テスト対象: InputBufferNotifier
///
/// テストグループ:
/// - 正常系テスト: 基本的な文字追加・削除・クリア操作
/// - 異常系テスト: 空文字、制御文字、空バッファでの操作
/// - 境界値テスト: 1000文字制限の検証
/// - エッジケーステスト: 特殊文字、連続操作
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';

void main() {
  group('InputBufferNotifier - 正常系テスト', () {
    late ProviderContainer container;

    setUp(() {
      // 【テスト前準備】: 各テストが独立して実行できるよう、クリーンな状態から開始
      container = ProviderContainer();
    });

    tearDown(() {
      // 【テスト後処理】: ProviderContainerを破棄し、メモリリークを防ぐ
      container.dispose();
    });

    // TC-001: 初期状態テスト - 空文字列の確認
    test('TC-001: InputBufferNotifierの初期状態が空文字列であることを確認', () {
      // 【テスト目的】: InputBufferNotifierの初期状態が空文字列であることを確認
      // 【テスト内容】: ProviderContainerを作成し、inputBufferProviderの状態を読み取る
      // 【期待される動作】: 状態が空文字列 '' である
      // 青信号: REQ-002、interfaces.dartに基づく

      // When: inputBufferProviderの状態を読み取る
      final state = container.read(inputBufferProvider);

      // Then: 状態が空文字列であることを確認
      expect(state, '');
    });

    // TC-002: 文字追加テスト - 単一文字の追加
    test('TC-002: addCharacter()で1文字が入力バッファに追加されることを確認', () {
      // 【テスト目的】: addCharacter()で1文字が追加されることを確認
      // 【テスト内容】: 空のバッファに'あ'を追加し、状態を確認する
      // 【期待される動作】: 状態が'あ'である
      // 青信号: REQ-002

      // Given: InputBufferNotifierを取得
      final notifier = container.read(inputBufferProvider.notifier);

      // When: addCharacter('あ')を呼び出す
      notifier.addCharacter('あ');

      // Then: 状態が'あ'であることを確認
      expect(container.read(inputBufferProvider), 'あ');
    });

    // TC-003: 文字追加テスト - 連続した複数文字の追加
    test('TC-003: 複数回のaddCharacter()で文字が連続追加されることを確認', () {
      // 【テスト目的】: 複数回のaddCharacter()で文字が連続追加されることを確認
      // 【テスト内容】: 'あ'、'い'、'う'を順に追加し、状態を確認する
      // 【期待される動作】: 状態が'あいう'である
      // 青信号: REQ-002

      // Given: InputBufferNotifierを取得
      final notifier = container.read(inputBufferProvider.notifier);

      // When: addCharacter()を3回呼び出す
      notifier.addCharacter('あ');
      notifier.addCharacter('い');
      notifier.addCharacter('う');

      // Then: 状態が'あいう'であることを確認
      expect(container.read(inputBufferProvider), 'あいう');
    });

    // TC-004: 文字追加テスト - ひらがな・カタカナ・漢字の混在
    test('TC-004: ひらがな、カタカナ、漢字を連続追加できることを確認', () {
      // 【テスト目的】: ひらがな、カタカナ、漢字を連続追加できることを確認
      // 【テスト内容】: 'あ'、'ア'、'亜'を順に追加し、状態を確認する
      // 【期待される動作】: 状態が'あア亜'である
      // 青信号: REQ-002

      // Given: InputBufferNotifierを取得
      final notifier = container.read(inputBufferProvider.notifier);

      // When: addCharacter()で異なる種類の文字を追加
      notifier.addCharacter('あ');
      notifier.addCharacter('ア');
      notifier.addCharacter('亜');

      // Then: 状態が'あア亜'であることを確認
      expect(container.read(inputBufferProvider), 'あア亜');
    });

    // TC-005: 文字削除テスト - 最後の1文字削除
    test('TC-005: deleteLastCharacter()で最後の1文字が削除されることを確認', () {
      // 【テスト目的】: deleteLastCharacter()で最後の1文字が削除されることを確認
      // 【テスト内容】: 'こんにちは'から最後の1文字を削除し、状態を確認する
      // 【期待される動作】: 状態が'こんにち'である
      // 青信号: REQ-003

      // Given: InputBufferNotifierを取得し、初期状態を設定
      final notifier = container.read(inputBufferProvider.notifier);
      notifier.setText('こんにちは');

      // When: deleteLastCharacter()を呼び出す
      notifier.deleteLastCharacter();

      // Then: 状態が'こんにち'であることを確認
      expect(container.read(inputBufferProvider), 'こんにち');
    });

    // TC-006: 文字削除テスト - 連続削除
    test('TC-006: 複数回のdeleteLastCharacter()で文字が連続削除されることを確認', () {
      // 【テスト目的】: 複数回のdeleteLastCharacter()で文字が連続削除されることを確認
      // 【テスト内容】: 'あいう'から2文字を連続削除し、状態を確認する
      // 【期待される動作】: 状態が'あ'である
      // 青信号: REQ-003

      // Given: InputBufferNotifierを取得し、初期状態を設定
      final notifier = container.read(inputBufferProvider.notifier);
      notifier.setText('あいう');

      // When: deleteLastCharacter()を2回呼び出す
      notifier.deleteLastCharacter();
      notifier.deleteLastCharacter();

      // Then: 状態が'あ'であることを確認
      expect(container.read(inputBufferProvider), 'あ');
    });

    // TC-007: 全消去テスト - バッファクリア
    test('TC-007: clear()で入力バッファが全消去されることを確認', () {
      // 【テスト目的】: clear()で入力バッファが全消去されることを確認
      // 【テスト内容】: 'おはようございます'を設定し、clear()を呼び出す
      // 【期待される動作】: 状態が空文字列''である
      // 青信号: REQ-004

      // Given: InputBufferNotifierを取得し、初期状態を設定
      final notifier = container.read(inputBufferProvider.notifier);
      notifier.setText('おはようございます');

      // When: clear()を呼び出す
      notifier.clear();

      // Then: 状態が空文字列であることを確認
      expect(container.read(inputBufferProvider), '');
    });

    // TC-008: setTextテスト - テキスト設定
    test('TC-008: setText()でバッファ内容を設定できることを確認', () {
      // 【テスト目的】: setText()でバッファ内容を設定できることを確認
      // 【テスト内容】: setText('ありがとう')を呼び出し、状態を確認する
      // 【期待される動作】: 状態が'ありがとう'である
      // 青信号: REQ-002

      // Given: InputBufferNotifierを取得
      final notifier = container.read(inputBufferProvider.notifier);

      // When: setText('ありがとう')を呼び出す
      notifier.setText('ありがとう');

      // Then: 状態が'ありがとう'であることを確認
      expect(container.read(inputBufferProvider), 'ありがとう');
    });

    // TC-009: setTextテスト - 既存テキストの上書き
    test('TC-009: setText()で既存テキストが上書きされることを確認', () {
      // 【テスト目的】: setText()で既存テキストが上書きされることを確認
      // 【テスト内容】: '古いテキスト'を設定後、'新しいテキスト'で上書きする
      // 【期待される動作】: 状態が'新しいテキスト'である
      // 青信号: REQ-002

      // Given: InputBufferNotifierを取得し、初期状態を設定
      final notifier = container.read(inputBufferProvider.notifier);
      notifier.setText('古いテキスト');

      // When: setText('新しいテキスト')を呼び出す
      notifier.setText('新しいテキスト');

      // Then: 状態が'新しいテキスト'であることを確認
      expect(container.read(inputBufferProvider), '新しいテキスト');
    });

    // TC-010: setTextテスト - 空文字列での設定（クリア目的）
    test('TC-010: setText(\'\')で空文字列を設定できることを確認', () {
      // 【テスト目的】: setText('')で空文字列を設定できることを確認
      // 【テスト内容】: 'テスト'を設定後、setText('')を呼び出す
      // 【期待される動作】: 状態が空文字列''である
      // 青信号: REQ-004

      // Given: InputBufferNotifierを取得し、初期状態を設定
      final notifier = container.read(inputBufferProvider.notifier);
      notifier.setText('テスト');

      // When: setText('')を呼び出す
      notifier.setText('');

      // Then: 状態が空文字列であることを確認
      expect(container.read(inputBufferProvider), '');
    });

    // TC-011: 状態通知テスト - Riverpod stateの自動更新確認
    test('TC-011: 状態変更がRiverpod stateに即座に反映されることを確認', () {
      // 【テスト目的】: 状態変更がRiverpod stateに即座に反映されることを確認
      // 【テスト内容】: inputBufferProviderを監視し、addCharacter()呼び出し後の状態を確認
      // 【期待される動作】: 状態変更が監視側に通知される
      // 青信号: NFR-003 (100ms以内応答), dataflow.md

      // Given: 状態変更を記録するリスト
      final states = <String>[];
      container.listen<String>(
        inputBufferProvider,
        (previous, next) {
          states.add(next);
        },
        fireImmediately: true,
      );

      // When: addCharacter('あ')を呼び出す
      final notifier = container.read(inputBufferProvider.notifier);
      notifier.addCharacter('あ');

      // Then: 状態変更が通知されたことを確認
      expect(states, ['', 'あ']);
    });

    // TC-031: Provider定義テスト - inputBufferProviderの型確認
    test('TC-031: inputBufferProviderがStateNotifierProvider<InputBufferNotifier, String>であることを確認', () {
      // 【テスト目的】: inputBufferProviderの型が正しいことを確認
      // 【テスト内容】: Providerから読み取った値の型を確認する
      // 【期待される動作】: Providerの状態型がStringである
      // 青信号: architecture.md, requirements.md「Providerの定義」

      // When: inputBufferProviderから状態を読み取る
      final state = container.read(inputBufferProvider);

      // Then: 状態がString型であることを確認
      expect(state, isA<String>());
    });
  });

  group('InputBufferNotifier - 異常系テスト', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // TC-012: 空文字追加の防止
    test('TC-012: addCharacter(\'\')で空文字列を追加しようとしても無視されることを確認', () {
      // 【テスト目的】: 空文字列の追加が無視されることを確認
      // 【テスト内容】: 'あいう'を設定後、空文字を追加しようとする
      // 【期待される動作】: 状態が'あいう'のまま変化しない
      // 黄信号: requirements.md「制約条件」

      // Given: InputBufferNotifierを取得し、初期状態を設定
      final notifier = container.read(inputBufferProvider.notifier);
      notifier.setText('あいう');

      // When: addCharacter('')を呼び出す
      notifier.addCharacter('');

      // Then: 状態が変化していないことを確認
      expect(container.read(inputBufferProvider), 'あいう');
    });

    // TC-013: 空バッファでの削除（安全処理）
    test('TC-013: 空バッファでdeleteLastCharacter()を呼び出してもエラーにならないことを確認', () {
      // 【テスト目的】: 空バッファでの削除がエラーにならないことを確認
      // 【テスト内容】: 空の状態でdeleteLastCharacter()を呼び出す
      // 【期待される動作】: エラーが発生せず、状態が空文字列''のまま
      // 青信号: AC-009

      // Given: InputBufferNotifierを取得（初期状態は空）
      final notifier = container.read(inputBufferProvider.notifier);
      expect(container.read(inputBufferProvider), '');

      // When: deleteLastCharacter()を呼び出す（エラーが発生しないことを確認）
      expect(() => notifier.deleteLastCharacter(), returnsNormally);

      // Then: 状態が空文字列のままであることを確認
      expect(container.read(inputBufferProvider), '');
    });

    // TC-014: 空バッファでの全消去（安全処理）
    test('TC-014: 空バッファでclear()を呼び出してもエラーにならないことを確認', () {
      // 【テスト目的】: 空バッファでのclear()がエラーにならないことを確認
      // 【テスト内容】: 空の状態でclear()を呼び出す
      // 【期待される動作】: エラーが発生せず、状態が空文字列''のまま
      // 黄信号: AC-009類推

      // Given: InputBufferNotifierを取得（初期状態は空）
      final notifier = container.read(inputBufferProvider.notifier);
      expect(container.read(inputBufferProvider), '');

      // When: clear()を呼び出す（エラーが発生しないことを確認）
      expect(() => notifier.clear(), returnsNormally);

      // Then: 状態が空文字列のままであることを確認
      expect(container.read(inputBufferProvider), '');
    });

    // TC-015: 制御文字（改行）の入力防止
    test('TC-015: addCharacter()で改行文字を追加しようとしても無視されることを確認', () {
      // 【テスト目的】: 改行文字の追加が無視されることを確認
      // 【テスト内容】: 'あいう'を設定後、改行文字を追加しようとする
      // 【期待される動作】: 状態が'あいう'のまま変化しない
      // 黄信号: requirements.md「エラー1: 制御文字の入力」

      // Given: InputBufferNotifierを取得し、初期状態を設定
      final notifier = container.read(inputBufferProvider.notifier);
      notifier.setText('あいう');

      // When: addCharacter('\n')を呼び出す
      notifier.addCharacter('\n');

      // Then: 状態が変化していないことを確認
      expect(container.read(inputBufferProvider), 'あいう');
    });

    // TC-016: 制御文字（タブ）の入力防止
    test('TC-016: addCharacter()でタブ文字を追加しようとしても無視されることを確認', () {
      // 【テスト目的】: タブ文字の追加が無視されることを確認
      // 【テスト内容】: 'あいう'を設定後、タブ文字を追加しようとする
      // 【期待される動作】: 状態が'あいう'のまま変化しない
      // 黄信号: requirements.md「エラー1: 制御文字の入力」

      // Given: InputBufferNotifierを取得し、初期状態を設定
      final notifier = container.read(inputBufferProvider.notifier);
      notifier.setText('あいう');

      // When: addCharacter('\t')を呼び出す
      notifier.addCharacter('\t');

      // Then: 状態が変化していないことを確認
      expect(container.read(inputBufferProvider), 'あいう');
    });

    // TC-032: 複数文字列の連続addCharacter（2文字以上の文字列）
    test('TC-032: addCharacter()に2文字以上の文字列を渡した場合、最初の1文字のみが追加されることを確認', () {
      // 【テスト目的】: 2文字以上の文字列が渡された場合の動作を確認
      // 【テスト内容】: addCharacter('あい')を呼び出す（2文字）
      // 【期待される動作】: 最初の1文字のみが追加される（'あ'）
      // 黄信号: requirements.md「制約: 1回の呼び出しで1文字のみ追加」

      // Given: InputBufferNotifierを取得
      final notifier = container.read(inputBufferProvider.notifier);

      // When: addCharacter('あい')を呼び出す（2文字）
      notifier.addCharacter('あい');

      // Then: 最初の1文字のみが追加されることを確認
      expect(container.read(inputBufferProvider), 'あ');
    });
  });

  group('InputBufferNotifier - 境界値テスト', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // TC-017: 1000文字ちょうどの入力 - 境界値下限
    test('TC-017: 999文字の状態から1文字追加で1000文字になることを確認', () {
      // 【テスト目的】: 999文字から1000文字への追加が成功することを確認
      // 【テスト内容】: 999文字の状態で1文字追加し、1000文字になることを確認
      // 【期待される動作】: 状態の文字数が1000文字である
      // 黄信号: EDGE-101

      // Given: InputBufferNotifierを取得し、999文字を設定
      final notifier = container.read(inputBufferProvider.notifier);
      final text999 = 'あ' * 999;
      notifier.setText(text999);
      expect(container.read(inputBufferProvider).length, 999);

      // When: addCharacter('い')を呼び出す
      notifier.addCharacter('い');

      // Then: 状態の文字数が1000文字であることを確認
      expect(container.read(inputBufferProvider).length, 1000);
    });

    // TC-018: 1000文字制限 - 境界値上限での追加拒否
    test('TC-018: 1000文字の状態から文字追加しても追加されないことを確認', () {
      // 【テスト目的】: 1000文字制限で追加が拒否されることを確認
      // 【テスト内容】: 1000文字の状態で文字追加を試みる
      // 【期待される動作】: 状態の文字数が1000文字のまま（追加されない）
      // 黄信号: EDGE-101, AC-011

      // Given: InputBufferNotifierを取得し、1000文字を設定
      final notifier = container.read(inputBufferProvider.notifier);
      final text1000 = 'あ' * 1000;
      notifier.setText(text1000);
      expect(container.read(inputBufferProvider).length, 1000);

      // When: addCharacter('い')を呼び出す
      notifier.addCharacter('い');

      // Then: 状態の文字数が1000文字のままであることを確認
      expect(container.read(inputBufferProvider).length, 1000);
    });

    // TC-019: setTextでの1001文字切り捨て
    test('TC-019: setText()で1001文字以上を設定しても1000文字で切り捨てられることを確認', () {
      // 【テスト目的】: setText()での文字数制限が機能することを確認
      // 【テスト内容】: 1001文字のテキストを設定する
      // 【期待される動作】: 状態の文字数が1000文字である（切り捨て）
      // 黄信号: EDGE-101, AC-012

      // Given: InputBufferNotifierを取得
      final notifier = container.read(inputBufferProvider.notifier);
      final text1001 = 'あ' * 1001;

      // When: setText()で1001文字を設定
      notifier.setText(text1001);

      // Then: 状態の文字数が1000文字であることを確認
      expect(container.read(inputBufferProvider).length, 1000);
    });

    // TC-020: setTextでの大量文字（2000文字）切り捨て
    test('TC-020: setText()で2000文字を設定しても1000文字で切り捨てられることを確認', () {
      // 【テスト目的】: 大量文字でもsetText()の文字数制限が機能することを確認
      // 【テスト内容】: 2000文字のテキストを設定する
      // 【期待される動作】: 状態の文字数が1000文字である（切り捨て）
      // 黄信号: EDGE-101, AC-012

      // Given: InputBufferNotifierを取得
      final notifier = container.read(inputBufferProvider.notifier);
      final text2000 = 'あ' * 2000;

      // When: setText()で2000文字を設定
      notifier.setText(text2000);

      // Then: 状態の文字数が1000文字であることを確認
      expect(container.read(inputBufferProvider).length, 1000);
    });

    // TC-021: 1文字のみの状態から削除
    test('TC-021: 1文字のみの状態からdeleteLastCharacter()で空になることを確認', () {
      // 【テスト目的】: 1文字から0文字への削除が成功することを確認
      // 【テスト内容】: 1文字の状態でdeleteLastCharacter()を呼び出す
      // 【期待される動作】: 状態が空文字列''である
      // 青信号: REQ-003

      // Given: InputBufferNotifierを取得し、1文字を設定
      final notifier = container.read(inputBufferProvider.notifier);
      notifier.setText('あ');
      expect(container.read(inputBufferProvider).length, 1);

      // When: deleteLastCharacter()を呼び出す
      notifier.deleteLastCharacter();

      // Then: 状態が空文字列であることを確認
      expect(container.read(inputBufferProvider), '');
    });

    // TC-022: 1000文字から全消去
    test('TC-022: 1000文字の状態からclear()で空になることを確認', () {
      // 【テスト目的】: 大量文字からのclear()が成功することを確認
      // 【テスト内容】: 1000文字の状態でclear()を呼び出す
      // 【期待される動作】: 状態が空文字列''である
      // 青信号: REQ-004, EDGE-101

      // Given: InputBufferNotifierを取得し、1000文字を設定
      final notifier = container.read(inputBufferProvider.notifier);
      final text1000 = 'あ' * 1000;
      notifier.setText(text1000);
      expect(container.read(inputBufferProvider).length, 1000);

      // When: clear()を呼び出す
      notifier.clear();

      // Then: 状態が空文字列であることを確認
      expect(container.read(inputBufferProvider), '');
    });
  });

  group('InputBufferNotifier - エッジケーステスト', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // TC-026: 濁点・半濁点付き文字の追加
    test('TC-026: 濁点・半濁点付き文字が正しく追加されることを確認', () {
      // 【テスト目的】: 濁点・半濁点付き文字が正しく追加されることを確認
      // 【テスト内容】: 'が'と'ぱ'を追加し、状態を確認する
      // 【期待される動作】: 状態が'がぱ'である
      // 青信号: REQ-002

      // Given: InputBufferNotifierを取得
      final notifier = container.read(inputBufferProvider.notifier);

      // When: addCharacter()で濁点・半濁点付き文字を追加
      notifier.addCharacter('が');
      notifier.addCharacter('ぱ');

      // Then: 状態が'がぱ'であることを確認
      expect(container.read(inputBufferProvider), 'がぱ');
    });

    // TC-027: 半角数字・記号の追加
    test('TC-027: 半角数字・記号が正しく追加されることを確認', () {
      // 【テスト目的】: 半角数字・記号が正しく追加されることを確認
      // 【テスト内容】: '1'と'!'を追加し、状態を確認する
      // 【期待される動作】: 状態が'1!'である
      // 黄信号: REQ-002類推

      // Given: InputBufferNotifierを取得
      final notifier = container.read(inputBufferProvider.notifier);

      // When: addCharacter()で半角数字・記号を追加
      notifier.addCharacter('1');
      notifier.addCharacter('!');

      // Then: 状態が'1!'であることを確認
      expect(container.read(inputBufferProvider), '1!');
    });

    // TC-028: 全角数字・記号の追加
    test('TC-028: 全角数字・記号が正しく追加されることを確認', () {
      // 【テスト目的】: 全角数字・記号が正しく追加されることを確認
      // 【テスト内容】: '１'と'！'を追加し、状態を確認する
      // 【期待される動作】: 状態が'１！'である
      // 黄信号: REQ-002類推

      // Given: InputBufferNotifierを取得
      final notifier = container.read(inputBufferProvider.notifier);

      // When: addCharacter()で全角数字・記号を追加
      notifier.addCharacter('１');
      notifier.addCharacter('！');

      // Then: 状態が'１！'であることを確認
      expect(container.read(inputBufferProvider), '１！');
    });

    // TC-029: 連続操作テスト - 追加→削除→追加
    test('TC-029: 追加、削除、追加の連続操作が正しく動作することを確認', () {
      // 【テスト目的】: 連続操作が正しく動作することを確認
      // 【テスト内容】: 'あ'追加→'い'追加→削除→'う'追加
      // 【期待される動作】: 状態が'あう'である
      // 青信号: REQ-002, REQ-003

      // Given: InputBufferNotifierを取得
      final notifier = container.read(inputBufferProvider.notifier);

      // When: 連続操作を実行
      notifier.addCharacter('あ');
      notifier.addCharacter('い');
      notifier.deleteLastCharacter();
      notifier.addCharacter('う');

      // Then: 状態が'あう'であることを確認
      expect(container.read(inputBufferProvider), 'あう');
    });

    // TC-030: 連続操作テスト - 全消去後の追加
    test('TC-030: 全消去後に文字追加ができることを確認', () {
      // 【テスト目的】: 全消去後に文字追加ができることを確認
      // 【テスト内容】: 'テスト'を設定→clear()→'新'を追加
      // 【期待される動作】: 状態が'新'である
      // 青信号: REQ-002, REQ-004

      // Given: InputBufferNotifierを取得し、初期状態を設定
      final notifier = container.read(inputBufferProvider.notifier);
      notifier.setText('テスト');

      // When: 全消去後に文字追加
      notifier.clear();
      notifier.addCharacter('新');

      // Then: 状態が'新'であることを確認
      expect(container.read(inputBufferProvider), '新');
    });
  });
}
