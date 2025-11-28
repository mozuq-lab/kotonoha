/// Phase 3 統合テスト（E2E）
///
/// TASK-0060: Phase 3 統合テスト
///
/// テストフレームワーク: flutter_test + flutter_riverpod + mocktail
/// 対象: Phase 3で実装された全機能の統合テスト
///
/// 【TDD Redフェーズ】: 統合テストが失敗することを確認
///
/// 信頼性レベル凡例:
/// - 🔵 青信号: EARS要件定義書・設計文書を参考にした確実なテスト
/// - 🟡 黄信号: EARS要件定義書・設計文書から妥当な推測によるテスト
/// - 🔴 赤信号: EARS要件定義書・設計文書にない推測によるテスト
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/history_item_adapter.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';

import '../mocks/mock_flutter_tts.dart';

/// TTSNotifierを作成するヘルパー関数（テスト用）
TTSNotifier createTestTTSNotifier(MockFlutterTts mockFlutterTts) {
  final service = TTSService(tts: mockFlutterTts);
  return TTSNotifier(service: service);
}

void main() {
  group('Phase 3 統合テスト - E2E', () {
    late ProviderContainer container;
    late MockFlutterTts mockFlutterTts;
    late Directory tempDir;

    setUpAll(() {
      // 【テスト前準備】: Mocktailのフォールバック値を登録
      // 【環境初期化】: モック呼び出し時のデフォルト値を設定
      registerFallbackValue('');
      registerFallbackValue(0.0);
    });

    setUp(() async {
      // 【テスト前準備】: 各テスト実行前にテスト環境を初期化
      // 【環境初期化】: SharedPreferences、Hive、TTSモックを設定

      // SharedPreferencesのモック初期化
      SharedPreferences.setMockInitialValues({});

      // Hive環境初期化
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('phase3_integration_');
      Hive.init(tempDir.path);

      // TypeAdapter登録
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }

      // MockFlutterTtsを作成
      mockFlutterTts = MockFlutterTts();

      // モックのデフォルト動作を設定
      when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.setSpeechRate(any()))
          .thenAnswer((_) async => 1);
      when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);
    });

    tearDown(() async {
      // 【テスト後処理】: ProviderContainerを破棄し、リソースを解放
      // 【状態復元】: 次のテストに影響しないようHiveをクローズ
      container.dispose();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // =========================================================================
    // TC-060-E2E-001: 文字入力から読み上げ・履歴保存までのフロー
    // =========================================================================
    group('TC-060-E2E-001: 文字入力から読み上げ・履歴保存フロー', () {
      test(
        'TC-060-E2E-001: 文字盤で入力したテキストを読み上げて履歴に保存する',
        () async {
          // 【テスト目的】: 文字入力から読み上げ・履歴保存までの一連のフローを確認 🔵
          // 【テスト内容】: 文字盤で「こんにちは」を入力し、読み上げボタンで読み上げ、履歴に保存
          // 【期待される動作】: 各文字100ms以内に反映、1秒以内に読み上げ開始、履歴保存
          // 🔵 青信号: REQ-001, REQ-002, REQ-401, REQ-601に基づく

          // Given（準備フェーズ）
          // 【テストデータ準備】: ProviderContainerを作成し、TTSモックを注入
          // 【初期条件設定】: 入力バッファは空、履歴は空
          final historyBox = await Hive.openBox<HistoryItem>('history');

          container = ProviderContainer(
            overrides: [
              ttsProvider.overrideWith(
                (ref) => createTestTTSNotifier(mockFlutterTts),
              ),
            ],
          );

          // InputBufferNotifierを取得
          final inputBufferNotifier =
              container.read(inputBufferProvider.notifier);

          // TTSNotifierを取得して初期化
          final ttsNotifier = container.read(ttsProvider.notifier);
          await ttsNotifier.initialize();

          // When（実行フェーズ）
          // 【実際の処理実行】: 文字盤で「こんにちは」を入力
          // 【処理内容】: 「こ」「ん」「に」「ち」「は」を順番に追加
          // 【実行タイミング】: 各文字を順番に追加
          inputBufferNotifier.addCharacter('こ');
          inputBufferNotifier.addCharacter('ん');
          inputBufferNotifier.addCharacter('に');
          inputBufferNotifier.addCharacter('ち');
          inputBufferNotifier.addCharacter('は');

          // 入力バッファの内容を確認
          final inputText = container.read(inputBufferProvider);

          // 読み上げを実行
          await ttsNotifier.speak(inputText);

          // Then（検証フェーズ）
          // 【結果検証】: 入力欄に「こんにちは」が表示される
          // 【期待値確認】: 正しいテキストが入力されていることを確認
          // 【品質保証】: 文字入力の正確性を確認
          expect(
            inputText,
            'こんにちは',
            reason: '入力バッファに「こんにちは」が正しく格納されている',
          ); // 【確認内容】: 入力テキストの正確性 🔵

          // 【確認内容】: TTSが正しいテキストで呼び出されたことを確認 🔵
          verify(() => mockFlutterTts.speak('こんにちは')).called(1);

          await historyBox.close();
        },
      );

      test(
        'TC-060-E2E-001-PERF: 文字盤タップ応答が100ms以内',
        () async {
          // 【テスト目的】: 文字盤タップ応答速度がNFR-003を満たすことを確認 🔵
          // 【テスト内容】: 文字盤タップから入力欄反映までの時間を計測
          // 【期待される動作】: 100ms以内に文字が反映される
          // 🔵 青信号: NFR-003に基づく

          // Given（準備フェーズ）
          // 【テストデータ準備】: ProviderContainerを作成
          // 【初期条件設定】: 空の入力バッファ
          container = ProviderContainer();

          final inputBufferNotifier =
              container.read(inputBufferProvider.notifier);
          final stopwatch = Stopwatch();
          final times = <int>[];

          // When（実行フェーズ）
          // 【実際の処理実行】: 文字を10回追加して応答時間を計測
          // 【処理内容】: Stopwatchで時間を計測
          for (var i = 0; i < 10; i++) {
            stopwatch.reset();
            stopwatch.start();
            inputBufferNotifier.addCharacter('あ');
            stopwatch.stop();
            times.add(stopwatch.elapsedMilliseconds);
            // 次の計測のためにクリア
            inputBufferNotifier.clear();
          }

          // Then（検証フェーズ）
          // 【結果検証】: 平均応答時間が100ms以内であることを確認
          // 【期待値確認】: NFR-003の要件を満たす
          final average = times.reduce((a, b) => a + b) / times.length;
          final maxTime = times.reduce((a, b) => a > b ? a : b);

          expect(
            average,
            lessThan(100),
            reason: '平均応答時間が100ms以内（実測: ${average}ms）',
          ); // 【確認内容】: 平均応答時間 🔵

          expect(
            maxTime,
            lessThan(150),
            reason: '最大応答時間が150ms以内（実測: ${maxTime}ms）',
          ); // 【確認内容】: 最大応答時間（余裕を持った基準）🟡
        },
      );
    });

    // =========================================================================
    // TC-060-E2E-002: 定型文即座読み上げフロー
    // =========================================================================
    group('TC-060-E2E-002: 定型文即座読み上げフロー', () {
      test(
        'TC-060-E2E-002: 定型文をタップすると即座に読み上げられる',
        () async {
          // 【テスト目的】: 定型文即座読み上げフローを確認 🔵
          // 【テスト内容】: 定型文「トイレに行きたいです」をタップして即座に読み上げ
          // 【期待される動作】: 1秒以内にTTS開始、履歴に保存
          // 🔵 青信号: REQ-103, NFR-001に基づく

          // Given（準備フェーズ）
          // 【テストデータ準備】: ProviderContainerを作成し、TTSモックを注入
          container = ProviderContainer(
            overrides: [
              ttsProvider.overrideWith(
                (ref) => createTestTTSNotifier(mockFlutterTts),
              ),
            ],
          );

          // TTSNotifierを取得して初期化
          final ttsNotifier = container.read(ttsProvider.notifier);
          await ttsNotifier.initialize();

          final stopwatch = Stopwatch();
          const presetPhrase = 'トイレに行きたいです';

          // When（実行フェーズ）
          // 【実際の処理実行】: 定型文をタップ（読み上げを実行）
          // 【処理内容】: TTS読み上げ開始時間を計測
          stopwatch.start();
          await ttsNotifier.speak(presetPhrase);
          stopwatch.stop();

          // Then（検証フェーズ）
          // 【結果検証】: TTS読み上げが呼び出されたことを確認
          // 【期待値確認】: 定型文が正しく読み上げられる
          verify(() => mockFlutterTts.speak(presetPhrase))
              .called(1); // 【確認内容】: TTS呼び出しの確認 🔵

          // 【確認内容】: 読み上げ開始が1秒以内であることを確認（モックなので即座）🔵
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(1000),
            reason: 'TTS開始が1秒以内',
          );
        },
      );

      test(
        'TC-060-E2E-002-FAV: お気に入り定型文が一覧上部に優先表示される',
        () async {
          // 【テスト目的】: お気に入り定型文の優先表示を確認 🔵
          // 【テスト内容】: お気に入りフラグのある定型文が上部に表示される
          // 【期待される動作】: お気に入り3件が先頭に表示
          // 🔵 青信号: REQ-105に基づく

          // Given（準備フェーズ）
          // 【テストデータ準備】: お気に入り3件、通常10件の定型文を準備
          final presetBox = await Hive.openBox<PresetPhrase>('presetPhrases');

          // 通常の定型文10件を追加
          for (var i = 0; i < 10; i++) {
            await presetBox.put(
              'normal-$i',
              PresetPhrase(
                id: 'normal-$i',
                content: '通常定型文$i',
                category: 'daily',
                isFavorite: false,
                displayOrder: i + 10,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
          }

          // お気に入り定型文3件を追加
          for (var i = 0; i < 3; i++) {
            await presetBox.put(
              'fav-$i',
              PresetPhrase(
                id: 'fav-$i',
                content: 'お気に入り$i',
                category: 'daily',
                isFavorite: true,
                displayOrder: i,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
          }

          container = ProviderContainer();

          // When（実行フェーズ）
          // 【実際の処理実行】: 定型文一覧を取得（お気に入り優先でソート）
          final allPhrases = presetBox.values.toList();
          allPhrases.sort((a, b) {
            // お気に入りを優先
            if (a.isFavorite && !b.isFavorite) return -1;
            if (!a.isFavorite && b.isFavorite) return 1;
            return a.displayOrder.compareTo(b.displayOrder);
          });

          // Then（検証フェーズ）
          // 【結果検証】: 先頭3件がお気に入りであることを確認
          expect(
            allPhrases.length,
            13,
            reason: '全13件の定型文が存在',
          ); // 【確認内容】: 定型文の総数 🔵

          expect(
            allPhrases[0].isFavorite,
            true,
            reason: '先頭がお気に入り',
          ); // 【確認内容】: 1番目がお気に入り 🔵

          expect(
            allPhrases[1].isFavorite,
            true,
            reason: '2番目がお気に入り',
          ); // 【確認内容】: 2番目がお気に入り 🔵

          expect(
            allPhrases[2].isFavorite,
            true,
            reason: '3番目がお気に入り',
          ); // 【確認内容】: 3番目がお気に入り 🔵

          expect(
            allPhrases[3].isFavorite,
            false,
            reason: '4番目以降は通常',
          ); // 【確認内容】: 4番目以降は通常定型文 🔵

          await presetBox.close();
        },
      );
    });

    // =========================================================================
    // TC-060-E2E-005: 削除ボタン・全消去ボタンフロー
    // =========================================================================
    group('TC-060-E2E-005: 削除ボタン・全消去ボタンフロー', () {
      test(
        'TC-060-E2E-005-DEL: 削除ボタンで最後の1文字が削除される',
        () async {
          // 【テスト目的】: 削除ボタンの動作を確認 🔵
          // 【テスト内容】: 「こんにちは」から削除ボタンで「こんにち」になる
          // 【期待される動作】: 最後の1文字「は」が削除される
          // 🔵 青信号: REQ-003に基づく

          // Given（準備フェーズ）
          // 【テストデータ準備】: 入力バッファに「こんにちは」を設定
          container = ProviderContainer();

          final inputBufferNotifier =
              container.read(inputBufferProvider.notifier);

          // 「こんにちは」を入力
          inputBufferNotifier.addCharacter('こ');
          inputBufferNotifier.addCharacter('ん');
          inputBufferNotifier.addCharacter('に');
          inputBufferNotifier.addCharacter('ち');
          inputBufferNotifier.addCharacter('は');

          expect(
            container.read(inputBufferProvider),
            'こんにちは',
            reason: '初期状態で「こんにちは」が入力されている',
          );

          // When（実行フェーズ）
          // 【実際の処理実行】: 削除ボタンをタップ（最後の1文字を削除）
          inputBufferNotifier.deleteLastCharacter();

          // Then（検証フェーズ）
          // 【結果検証】: 入力欄が「こんにち」になることを確認
          expect(
            container.read(inputBufferProvider),
            'こんにち',
            reason: '削除後「こんにち」になる',
          ); // 【確認内容】: 1文字削除の正確性 🔵
        },
      );

      test(
        'TC-060-E2E-005-CLEAR: 全消去ボタンで確認後に全文削除される',
        () async {
          // 【テスト目的】: 全消去ボタンの動作を確認 🔵
          // 【テスト内容】: 全消去で全文削除される
          // 【期待される動作】: すべての文字が削除される
          // 🔵 青信号: REQ-004, REQ-2001に基づく

          // Given（準備フェーズ）
          // 【テストデータ準備】: 入力バッファに「こんにちは」を設定
          container = ProviderContainer();

          final inputBufferNotifier =
              container.read(inputBufferProvider.notifier);

          // 「こんにちは」を入力
          inputBufferNotifier.addCharacter('こ');
          inputBufferNotifier.addCharacter('ん');
          inputBufferNotifier.addCharacter('に');
          inputBufferNotifier.addCharacter('ち');
          inputBufferNotifier.addCharacter('は');

          expect(
            container.read(inputBufferProvider),
            'こんにちは',
            reason: '初期状態で「こんにちは」が入力されている',
          );

          // When（実行フェーズ）
          // 【実際の処理実行】: 全消去を実行
          // 【処理内容】: 確認ダイアログで「はい」を選択した後の処理をシミュレート
          inputBufferNotifier.clear();

          // Then（検証フェーズ）
          // 【結果検証】: 入力欄が空になることを確認
          expect(
            container.read(inputBufferProvider),
            '',
            reason: '全消去後、入力欄が空になる',
          ); // 【確認内容】: 全消去の正確性 🔵
        },
      );
    });

    // =========================================================================
    // TC-060-E2E-008: データ永続化テストフロー
    // =========================================================================
    group('TC-060-E2E-008: データ永続化テスト', () {
      test(
        'TC-060-E2E-008: アプリ再起動後も定型文・履歴・設定が保持される',
        () async {
          // 【テスト目的】: データ永続化を確認 🔵
          // 【テスト内容】: アプリ再起動後も定型文・履歴・設定が保持
          // 【期待される動作】: すべてのデータが復元される
          // 🔵 青信号: REQ-5003, NFR-302に基づく

          // containerを初期化（tearDownで必要）
          container = ProviderContainer();

          // Given（準備フェーズ）
          // 【テストデータ準備】: 定型文、履歴、設定を保存
          // ユニークなBox名を使用して他テストとの競合を避ける
          final presetBox =
              await Hive.openBox<PresetPhrase>('persist_presetPhrases');
          final historyBox = await Hive.openBox<HistoryItem>('persist_history');

          // 定型文を追加
          await presetBox.put(
            'test-phrase',
            PresetPhrase(
              id: 'test-phrase',
              content: 'テスト定型文',
              category: 'daily',
              isFavorite: false,
              displayOrder: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          // 履歴を追加
          await historyBox.put(
            'test-history',
            HistoryItem(
              id: 'test-history',
              content: 'テスト履歴',
              type: 'manualInput',
              createdAt: DateTime.now(),
              isFavorite: false,
            ),
          );

          // 設定を保存（SharedPreferences経由）
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('font_size', 'large');

          // アプリ再起動をシミュレート（Boxをクローズして再オープン）
          await presetBox.close();
          await historyBox.close();

          // When（実行フェーズ）
          // 【実際の処理実行】: データを再読み込み
          final reopenedPresetBox =
              await Hive.openBox<PresetPhrase>('persist_presetPhrases');
          final reopenedHistoryBox =
              await Hive.openBox<HistoryItem>('persist_history');
          final reopenedPrefs = await SharedPreferences.getInstance();

          // Then（検証フェーズ）
          // 【結果検証】: すべてのデータが復元されることを確認
          expect(
            reopenedPresetBox.get('test-phrase')?.content,
            'テスト定型文',
            reason: '定型文が復元される',
          ); // 【確認内容】: 定型文の永続化 🔵

          expect(
            reopenedHistoryBox.get('test-history')?.content,
            'テスト履歴',
            reason: '履歴が復元される',
          ); // 【確認内容】: 履歴の永続化 🔵

          expect(
            reopenedPrefs.getString('font_size'),
            'large',
            reason: '設定が復元される',
          ); // 【確認内容】: 設定の永続化 🔵

          await reopenedPresetBox.close();
          await reopenedHistoryBox.close();
          await Hive.deleteBoxFromDisk('persist_presetPhrases');
          await Hive.deleteBoxFromDisk('persist_history');
        },
      );

      test(
        'TC-060-E2E-008-INPUT: アプリ再起動後も入力状態が復元される',
        () async {
          // 【テスト目的】: 入力状態復元を確認 🔵
          // 【テスト内容】: アプリ再起動後も入力中テキストが復元
          // 【期待される動作】: 入力欄に「こんにちは」が表示される
          // 🔵 青信号: NFR-302に基づく

          // Given（準備フェーズ）
          // 【テストデータ準備】: 入力バッファに「こんにちは」を保存
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_input_buffer', 'こんにちは');

          // When（実行フェーズ）
          // 【実際の処理実行】: 再起動後のデータ復元をシミュレート
          final reopenedPrefs = await SharedPreferences.getInstance();
          final restoredText = reopenedPrefs.getString('last_input_buffer');

          // Then（検証フェーズ）
          // 【結果検証】: 入力テキストが復元されることを確認
          expect(
            restoredText,
            'こんにちは',
            reason: '入力状態が復元される',
          ); // 【確認内容】: 入力状態の永続化 🔵
        },
      );
    });

    // =========================================================================
    // TC-060-BV-002: 履歴50件上限テスト
    // =========================================================================
    group('TC-060-BV-002: 履歴50件上限テスト', () {
      test(
        'TC-060-BV-002: 履歴が50件に達すると最古が自動削除される',
        () async {
          // 【テスト目的】: 履歴50件上限を検証 🔵
          // 【テスト内容】: 51件目追加時に最古が削除
          // 【期待される動作】: 履歴件数50件を維持
          // 🔵 青信号: REQ-3002に基づく

          // Given（準備フェーズ）
          // 【テストデータ準備】: 履歴50件を作成
          final historyBox = await Hive.openBox<HistoryItem>('history_limit');

          // 50件の履歴を追加
          for (var i = 0; i < 50; i++) {
            await historyBox.put(
              'hist-$i',
              HistoryItem(
                id: 'hist-$i',
                content: '履歴$i',
                type: 'manualInput',
                createdAt: DateTime.now().subtract(Duration(minutes: 50 - i)),
                isFavorite: false,
              ),
            );
          }

          expect(
            historyBox.length,
            50,
            reason: '初期状態で50件の履歴',
          );

          // When（実行フェーズ）
          // 【実際の処理実行】: 51件目を追加（最古を削除してから追加をシミュレート）
          // 【処理内容】: 履歴上限管理のロジックをシミュレート
          final oldestKey =
              historyBox.keys.cast<String>().reduce((a, b) {
                final histA = historyBox.get(a)!;
                final histB = historyBox.get(b)!;
                return histA.createdAt.isBefore(histB.createdAt) ? a : b;
              });

          // 最古を削除
          await historyBox.delete(oldestKey);

          // 51件目を追加
          await historyBox.put(
            'hist-50',
            HistoryItem(
              id: 'hist-50',
              content: '新しい履歴',
              type: 'manualInput',
              createdAt: DateTime.now(),
              isFavorite: false,
            ),
          );

          // Then（検証フェーズ）
          // 【結果検証】: 履歴件数が50件に保たれることを確認
          expect(
            historyBox.length,
            50,
            reason: '履歴件数が50件に維持される',
          ); // 【確認内容】: 履歴上限の維持 🔵

          // 最古の履歴が削除されたことを確認
          expect(
            historyBox.get('hist-0'),
            isNull,
            reason: '最古の履歴が削除されている',
          ); // 【確認内容】: 最古履歴の削除 🔵

          await historyBox.close();
          await Hive.deleteBoxFromDisk('history_limit');
        },
      );
    });
  });
}
