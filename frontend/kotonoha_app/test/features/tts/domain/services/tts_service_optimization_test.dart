/// TTSService最適化テスト（Redフェーズ）
///
/// TASK-0090: TTS・ローカルストレージ最適化
/// テストケース: TC-090-001〜TC-090-004, TC-090-009, TC-090-011, TC-090-014, TC-090-015
///
/// テストフレームワーク: flutter_test + mocktail
/// 対象: TTSService、TTSNotifierのパフォーマンス最適化
///
/// 【TDD Redフェーズ】: 最適化メソッド未実装のため、テストが失敗するはず
///
/// 信頼性レベル凡例:
/// - 🔵 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
/// - 🟡 黄信号: 要件定義書から妥当な推測によるテスト
/// - 🔴 赤信号: 要件定義書にない推測によるテスト
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import '../../../../mocks/mock_flutter_tts.dart';

void main() {
  group('TTSService最適化テスト - 正常系', () {
    late MockFlutterTts mockFlutterTts;
    late TTSService service;

    setUpAll(() {
      // 【テスト前準備】: Mocktailのフォールバック値を登録
      registerFallbackValue('');
      registerFallbackValue(0.0);
      registerFallbackValue(() {});
    });

    setUp(() {
      // 【テスト前準備】: 各テストが独立して実行できるよう、クリーンな状態から開始
      // 【環境初期化】: モックを作成し、デフォルト動作を設定
      mockFlutterTts = MockFlutterTts();

      // モックのデフォルト動作を設定
      when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.setSpeechRate(any()))
          .thenAnswer((_) async => 1);
      when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);

      service = TTSService(tts: mockFlutterTts);
    });

    // =========================================================================
    // TC-090-001: TTS事前初期化がバックグラウンドで実行される
    // =========================================================================
    test('TC-090-001: TTS事前初期化のバックグラウンド実行確認', () async {
      // 【テスト目的】: TTSNotifier生成時にバックグラウンドで初期化が開始されることを確認
      // 【テスト内容】: TTSNotifierのコンストラクタ実行後、即座にinitialize()が非同期で呼び出される
      // 【期待される動作】: initialize()が自動的に1回呼び出される
      // 🔵 青信号: NFR-001、要件定義書の実装方針に基づく

      // Given: 【テストデータ準備】: モックでの初期化追跡用
      // 【初期条件設定】: TTSNotifierを作成してバックグラウンド初期化を開始

      // When: 【実際の処理実行】: TTSNotifierを作成
      // 【処理内容】: コンストラクタでバックグラウンド初期化が開始されるはず
      final notifier = TTSNotifier(
        service: TTSService(
          tts: mockFlutterTts,
          onStateChanged: () {},
        ),
      );

      // 【待機】: バックグラウンド初期化が完了するのを待つ
      await Future.delayed(const Duration(milliseconds: 100));

      // Then: 【結果検証】: 初期化が自動的に実行されていることを確認
      // 【期待値確認】: setLanguage()が呼ばれている = 初期化が実行された
      // 🔵 青信号: 事前初期化の確認
      verify(() => mockFlutterTts.setLanguage('ja-JP'))
          .called(1); // 【確認内容】: バックグラウンドで初期化が実行されたことを確認 🔵

      // 【Notifier破棄】: テスト後のクリーンアップ
      notifier.dispose();
    });

    // =========================================================================
    // TC-090-002: 事前初期化後の読み上げ開始時間が1秒以内
    // =========================================================================
    test('TC-090-002: TTS読み上げ開始時間の計測（事前初期化済み）', () async {
      // 【テスト目的】: 初期化済みの状態でspeak()を呼び出した際の開始時間を計測
      // 【テスト内容】: speak()呼び出しから読み上げ開始まで1秒以内
      // 【期待される動作】: speak()呼び出しから読み上げ開始まで1000ms以内
      // 🔵 青信号: NFR-001パフォーマンス要件

      // Given: 【テストデータ準備】: サービスを事前に初期化
      // 【初期条件設定】: TTSServiceが初期化済みの状態
      await service.initialize();
      const testText = 'こんにちは';

      // When: 【実際の処理実行】: speak()を呼び出して時間を計測
      // 【処理内容】: Stopwatchで読み上げ開始時間を計測
      final stopwatch = Stopwatch()..start();
      await service.speak(testText);
      stopwatch.stop();

      // Then: 【結果検証】: 1秒以内に読み上げが開始されることを確認
      // 【期待値確認】: 経過時間が1000ms以内
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(1000),
      ); // 【確認内容】: 読み上げ開始まで1秒以内 🔵

      expect(
        service.state,
        TTSState.speaking,
      ); // 【確認内容】: 状態がspeakingになっていること 🔵
    });

    // =========================================================================
    // TC-090-003: 初期化前でも読み上げが1秒以内に開始される
    // =========================================================================
    test('TC-090-003: TTS自動初期化込みの読み上げ開始時間計測', () async {
      // 【テスト目的】: 未初期化状態からspeak()を呼び出した際のトータル時間を計測
      // 【テスト内容】: 自動初期化を含めても1秒以内に読み上げ開始
      // 【期待される動作】: 自動初期化を含めても1秒以内に読み上げ開始
      // 🟡 黄信号: NFR-001から推測、実際のOS依存性あり

      // Given: 【テストデータ準備】: 未初期化のTTSService
      // 【初期条件設定】: initialize()を呼ばない状態
      const testText = 'テスト';

      // When: 【実際の処理実行】: 未初期化状態からspeak()を呼び出して時間を計測
      // 【処理内容】: 自動初期化を含むトータル時間を計測
      final stopwatch = Stopwatch()..start();
      await service.speak(testText);
      stopwatch.stop();

      // Then: 【結果検証】: 自動初期化込みで1秒以内に開始されることを確認
      // 【期待値確認】: 自動初期化のオーバーヘッドを含めても1秒以内
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(1000),
      ); // 【確認内容】: 自動初期化込みで1秒以内 🟡

      expect(
        service.state,
        TTSState.speaking,
      ); // 【確認内容】: 状態がspeakingになっていること 🟡
    });

    // =========================================================================
    // TC-090-004: 連続読み上げで2回目以降は即座に開始される
    // =========================================================================
    test('TC-090-004: 連続読み上げのパフォーマンス確認', () async {
      // 【テスト目的】: 2回目以降のspeak()呼び出し時の開始時間を計測
      // 【テスト内容】: 初期化済みのため即座に読み上げ開始
      // 【期待される動作】: 2回目は100ms以内に開始
      // 🟡 黄信号: パフォーマンス最適化の期待値

      // Given: 【テストデータ準備】: サービスを初期化して1回目の読み上げを実行
      // 【初期条件設定】: 1回目の読み上げが完了した状態
      await service.initialize();
      await service.speak('最初');
      await service.onComplete();
      await Future.delayed(const Duration(milliseconds: 150));

      // When: 【実際の処理実行】: 2回目のspeak()を呼び出して時間を計測
      // 【処理内容】: 初期化済み状態での2回目の読み上げ
      final stopwatch = Stopwatch()..start();
      await service.speak('次');
      stopwatch.stop();

      // Then: 【結果検証】: 2回目は100ms以内に開始されることを確認
      // 【期待値確認】: 初期化済みのためオーバーヘッドなし
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(100),
      ); // 【確認内容】: 2回目は100ms以内に開始 🟡

      expect(
        service.state,
        TTSState.speaking,
      ); // 【確認内容】: 状態がspeakingになっていること 🟡
    });
  });

  group('TTSService最適化テスト - 異常系', () {
    late MockFlutterTts mockFlutterTts;
    late TTSService service;

    setUpAll(() {
      registerFallbackValue('');
      registerFallbackValue(0.0);
      registerFallbackValue(() {});
    });

    setUp(() {
      mockFlutterTts = MockFlutterTts();
      when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.setSpeechRate(any()))
          .thenAnswer((_) async => 1);
      when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);
      service = TTSService(tts: mockFlutterTts);
    });

    // =========================================================================
    // TC-090-009: TTS初期化失敗時も読み上げが安全に失敗する
    // =========================================================================
    test('TC-090-009: TTS初期化失敗時のエラーハンドリング', () async {
      // 【テスト目的】: TTSエンジンの初期化が失敗した場合のエラーハンドリング確認
      // 【テスト内容】: 初期化失敗時にstate=error、errorMessageが設定される
      // 【期待される動作】: アプリクラッシュを防ぎ、基本機能を継続
      // 🔵 青信号: NFR-301、既存テスト（TC-048-011）のパターン

      // Given: 【テストデータ準備】: setLanguage()がExceptionをスロー
      // 【初期条件設定】: モックで例外をスロー
      when(() => mockFlutterTts.setLanguage(any()))
          .thenThrow(Exception('TTS初期化失敗'));

      // When: 【実際の処理実行】: initialize()を呼び出す
      // 【処理内容】: 初期化を試行
      final result = await service.initialize();

      // Then: 【結果検証】: 初期化が失敗し、エラー状態になることを確認
      // 【期待値確認】: falseが返され、エラーメッセージが設定される
      expect(result, isFalse); // 【確認内容】: 初期化が失敗したことを確認 🔵
      expect(
        service.errorMessage,
        isNotNull,
      ); // 【確認内容】: エラーメッセージが設定されたことを確認 🔵
      expect(
        service.errorMessage,
        contains('初期化'),
      ); // 【確認内容】: エラーメッセージに「初期化」が含まれることを確認 🔵
    });

    // =========================================================================
    // TC-090-011: 初期化未完了時のspeak()呼び出しは待機後に実行
    // =========================================================================
    test('TC-090-011: 初期化中のspeak()呼び出し処理', () async {
      // 【テスト目的】: 初期化処理中にspeak()が呼ばれた場合の競合状態防止確認
      // 【テスト内容】: 初期化中にspeak()を呼び出し、競合なく正常処理される
      // 【期待される動作】: 初期化完了を待ってから読み上げ開始
      // 🟡 黄信号: 実装上の考慮事項

      // Given: 【テストデータ準備】: 初期化に時間がかかる状況を模擬
      // 【初期条件設定】: setLanguage()を遅延させる
      when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return 1;
      });

      // When: 【実際の処理実行】: 初期化開始直後にspeak()を呼び出す
      // 【処理内容】: 並行して初期化とspeak()を実行

      // 初期化を開始（完了を待たない）
      final initFuture = service.initialize();

      // 少し待ってからspeak()を呼び出す
      await Future.delayed(const Duration(milliseconds: 10));
      await service.speak('テスト');

      // 初期化の完了を待つ
      await initFuture;

      // Then: 【結果検証】: 競合状態なく正常に処理されることを確認
      // 【期待値確認】: 状態がspeakingになり、読み上げが実行される
      expect(
        service.state,
        TTSState.speaking,
      ); // 【確認内容】: 正常に読み上げ状態になること 🟡

      verify(
        () => mockFlutterTts.speak('テスト'),
      ).called(1); // 【確認内容】: speak()が1回呼ばれること 🟡
    });
  });

  group('TTSService最適化テスト - 境界値', () {
    late MockFlutterTts mockFlutterTts;
    late TTSService service;

    setUpAll(() {
      registerFallbackValue('');
      registerFallbackValue(0.0);
      registerFallbackValue(() {});
    });

    setUp(() {
      mockFlutterTts = MockFlutterTts();
      when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.setSpeechRate(any()))
          .thenAnswer((_) async => 1);
      when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);
      service = TTSService(tts: mockFlutterTts);
    });

    // =========================================================================
    // TC-090-014: 1文字テキストの読み上げ開始時間
    // =========================================================================
    test('TC-090-014: 最小テキストでの読み上げ開始時間', () async {
      // 【テスト目的】: テキスト最小値（1文字）でのパフォーマンス確認
      // 【テスト内容】: 1文字でも正常に1秒以内に処理される
      // 【期待される動作】: 1秒以内に読み上げ開始
      // 🔵 青信号: 既存テスト（TC-048-015）

      // Given: 【テストデータ準備】: 1文字のテキスト
      // 【初期条件設定】: サービスが初期化済みの状態
      await service.initialize();
      const testText = 'あ';

      // When: 【実際の処理実行】: 1文字テキストで読み上げ時間を計測
      // 【処理内容】: 短いテキストでのパフォーマンスを検証
      final stopwatch = Stopwatch()..start();
      await service.speak(testText);
      stopwatch.stop();

      // Then: 【結果検証】: 1秒以内に読み上げが開始されることを確認
      // 【期待値確認】: 短いテキストでも遅延なし
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(1000),
      ); // 【確認内容】: 1文字でも1秒以内 🔵

      expect(
        service.state,
        TTSState.speaking,
      ); // 【確認内容】: 状態がspeakingになっていること 🔵
    });

    // =========================================================================
    // TC-090-015: 1000文字テキストの読み上げ開始時間
    // =========================================================================
    test('TC-090-015: 最大テキストでの読み上げ開始時間', () async {
      // 【テスト目的】: テキスト最大値（1000文字）でのパフォーマンス確認
      // 【テスト内容】: 長文でも1秒以内に開始
      // 【期待される動作】: 1秒以内に読み上げ開始
      // 🔵 青信号: EDGE-101対応

      // Given: 【テストデータ準備】: 1000文字のテキスト
      // 【初期条件設定】: サービスが初期化済みの状態
      await service.initialize();
      final testText = 'あ' * 1000;

      // When: 【実際の処理実行】: 1000文字テキストで読み上げ時間を計測
      // 【処理内容】: 長文でのパフォーマンスを検証
      final stopwatch = Stopwatch()..start();
      await service.speak(testText);
      stopwatch.stop();

      // Then: 【結果検証】: 1秒以内に読み上げが開始されることを確認
      // 【期待値確認】: 長文でも短いテキストと同等の開始時間
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(1000),
      ); // 【確認内容】: 1000文字でも1秒以内 🔵

      expect(
        service.state,
        TTSState.speaking,
      ); // 【確認内容】: 状態がspeakingになっていること 🔵
    });
  });

  group('TTSNotifier最適化テスト - 事前初期化', () {
    late MockFlutterTts mockFlutterTts;

    setUpAll(() {
      registerFallbackValue('');
      registerFallbackValue(0.0);
      registerFallbackValue(() {});
    });

    setUp(() {
      mockFlutterTts = MockFlutterTts();
      when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.setSpeechRate(any()))
          .thenAnswer((_) async => 1);
      when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);
    });

    // =========================================================================
    // TC-090-001a: TTSNotifier生成時にinitialize()が自動実行される
    // =========================================================================
    test('TC-090-001a: TTSNotifier生成時にバックグラウンド初期化が開始される', () async {
      // 【テスト目的】: TTSNotifierのコンストラクタでバックグラウンド初期化が開始されることを確認
      // 【テスト内容】: Future.microtask()で初期化が非同期実行される
      // 【期待される動作】: Notifier生成後、即座にバックグラウンドで初期化開始
      // 🔵 青信号: 要件定義書の実装方針（6.1節）

      // Given: 【テストデータ準備】: 初期化追跡用のモック設定
      // 【初期条件設定】: モックが設定済み

      // When: 【実際の処理実行】: TTSNotifierを生成
      // 【処理内容】: コンストラクタでバックグラウンド初期化が開始されるはず
      final service = TTSService(
        tts: mockFlutterTts,
        onStateChanged: () {},
      );
      final notifier = TTSNotifier(service: service);

      // バックグラウンド初期化が完了するのを待つ
      await Future.delayed(const Duration(milliseconds: 200));

      // Then: 【結果検証】: 初期化が自動実行されることを確認
      // 【期待値確認】: setLanguage()とsetSpeechRate()が呼ばれる
      verify(
        () => mockFlutterTts.setLanguage('ja-JP'),
      ).called(1); // 【確認内容】: 言語設定が実行された 🔵

      verify(
        () => mockFlutterTts.setSpeechRate(1.0),
      ).called(1); // 【確認内容】: 速度設定が実行された 🔵

      // 【Notifier破棄】: テスト後のクリーンアップ
      notifier.dispose();
    });
  });
}
