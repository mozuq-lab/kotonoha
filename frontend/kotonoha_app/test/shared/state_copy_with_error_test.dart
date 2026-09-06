/// copyWith のエラー引数規約テスト（回帰テスト）
///
/// 改善対応: copyWith のエラー引数パターンの統一
///
/// 背景: 状態クラスごとに copyWith のエラー引数の扱いが3パターンに
/// 分かれており、いずれも意図しない挙動を生んでいた。
///
/// - `error: error`（favorite / history / preset_phrase）
///   → 引数を省略しただけでエラーが消える（意図せずエラーが消える）
/// - `errorMessage ?? this.errorMessage`（tts）
///   → 一度設定されたエラーを二度と消せない（逆方向のバグ）
/// - `clearXxx` フラグ方式（ai_conversion）
///   → 正しい実装。省略時は保持、`clearXxx: true` で明示的にクリア
///
/// 本テストは、全状態クラスが `clearXxx` フラグ方式に統一されたことを
/// 「明示的にクリアする」「エラーを保持したまま他フィールドを更新する」の
/// 両面から検証する。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kotonoha_app/features/ai_conversion/domain/exceptions/ai_conversion_exception.dart';
import 'package:kotonoha_app/features/ai_conversion/providers/ai_conversion_state.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';
import 'package:kotonoha_app/features/preset_phrase/data/preset_phrase_repository.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/preset_phrase_notifier.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/providers/repository_providers.dart';

import '../mocks/mock_flutter_tts.dart';

/// テスト用: 任意の初期状態から実メソッドを動かすための Notifier
///
/// 本番コードでは error を設定する入口が限られているため、
/// 「エラーが残っている状態」を起点にした回帰テストを行えるように
/// state のセッターだけを公開する。
class _TestablePresetPhraseNotifier extends PresetPhraseNotifier {
  void setStateForTest(PresetPhraseState value) => state = value;
}

/// テスト用: saveAll() の待機中に別経路がエラーを設定する状況を再現するための偽Repository
class _FakePresetPhraseRepository extends Mock
    implements PresetPhraseRepository {}

class _TestableFavoriteNotifier extends FavoriteNotifier {
  void setStateForTest(FavoriteState value) => state = value;
}

class _TestableHistoryNotifier extends HistoryNotifier {
  void setStateForTest(HistoryState value) => state = value;
}

void main() {
  group('copyWith エラー引数の規約（clearXxx フラグ方式に統一）', () {
    group('FavoriteState', () {
      test('error を省略した場合はエラーを保持する', () {
        // 背景: 旧実装（error: error）では、無関係なフィールドを更新しただけで
        // エラーが消えてしまっていた
        const state = FavoriteState(error: '読み込みに失敗しました');

        final updated = state.copyWith(isLoading: true);

        expect(updated.error, equals('読み込みに失敗しました'));
        expect(updated.isLoading, isTrue);
      });

      test('clearError: true でエラーを明示的にクリアできる', () {
        const state = FavoriteState(error: '読み込みに失敗しました');

        final updated = state.copyWith(clearError: true);

        expect(updated.error, isNull);
      });

      test('error を渡した場合は上書きされる', () {
        const state = FavoriteState(error: '古いエラー');

        expect(state.copyWith(error: '新しいエラー').error, equals('新しいエラー'));
      });

      test('clearError: true は error 引数より優先される', () {
        const state = FavoriteState(error: '古いエラー');

        expect(
          state.copyWith(error: '新しいエラー', clearError: true).error,
          isNull,
        );
      });
    });

    group('HistoryState', () {
      test('error を省略した場合はエラーを保持する', () {
        const state = HistoryState(error: '読み込みに失敗しました');

        final updated = state.copyWith(isLoading: true);

        expect(updated.error, equals('読み込みに失敗しました'));
        expect(updated.isLoading, isTrue);
      });

      test('clearError: true でエラーを明示的にクリアできる', () {
        const state = HistoryState(error: '読み込みに失敗しました');

        expect(state.copyWith(clearError: true).error, isNull);
      });

      test('error を渡した場合は上書きされる', () {
        const state = HistoryState(error: '古いエラー');

        expect(state.copyWith(error: '新しいエラー').error, equals('新しいエラー'));
      });
    });

    group('PresetPhraseState', () {
      test('error を省略した場合はエラーを保持する', () {
        const state = PresetPhraseState(error: '初期データの読み込みに失敗しました');

        final updated = state.copyWith(isLoading: true);

        expect(updated.error, equals('初期データの読み込みに失敗しました'));
        expect(updated.isLoading, isTrue);
      });

      test('clearError: true でエラーを明示的にクリアできる', () {
        const state = PresetPhraseState(error: '初期データの読み込みに失敗しました');

        expect(state.copyWith(clearError: true).error, isNull);
      });

      test('error を渡した場合は上書きされる', () {
        const state = PresetPhraseState(error: '古いエラー');

        expect(state.copyWith(error: '新しいエラー').error, equals('新しいエラー'));
      });
    });

    group('TTSServiceState', () {
      const errorState = TTSServiceState(
        state: TTSState.error,
        currentSpeed: TTSSpeed.normal,
        errorMessage: '読み上げに失敗しました',
      );

      test('errorMessage を省略した場合はエラーを保持する', () {
        final updated = errorState.copyWith(currentSpeed: TTSSpeed.fast);

        expect(updated.errorMessage, equals('読み上げに失敗しました'));
        expect(updated.currentSpeed, equals(TTSSpeed.fast));
      });

      test('clearErrorMessage: true でエラーを明示的にクリアできる', () {
        // 回帰: 旧実装（errorMessage ?? this.errorMessage）では
        // 一度設定されたエラーを消す手段が存在しなかった
        final updated = errorState.copyWith(
          state: TTSState.idle,
          clearErrorMessage: true,
        );

        expect(updated.errorMessage, isNull);
        expect(updated.state, equals(TTSState.idle));
      });

      test('errorMessage を渡した場合は上書きされる', () {
        expect(
          errorState.copyWith(errorMessage: '読み上げ停止に失敗しました').errorMessage,
          equals('読み上げ停止に失敗しました'),
        );
      });
    });

    group('AIConversionState（統一先の参照実装）', () {
      const exception = AIConversionException(
        code: 'AI_API_ERROR',
        message: 'AI変換APIでエラーが発生しました',
      );
      const errorState = AIConversionState(
        status: AIConversionStatus.error,
        error: exception,
      );

      test('error を省略した場合はエラーを保持する', () {
        final updated = errorState.copyWith(originalText: 'こんにちは');

        expect(updated.error, equals(exception));
      });

      test('clearError: true でエラーを明示的にクリアできる', () {
        expect(
          errorState
              .copyWith(status: AIConversionStatus.idle, clearError: true)
              .error,
          isNull,
        );
      });
    });
  });

  group('PresetPhraseNotifier のエラー保持・クリア挙動', () {
    late ProviderContainer container;
    late _TestablePresetPhraseNotifier notifier;

    const errorState = PresetPhraseState(
      error: '初期データの読み込みに失敗しました: Exception',
    );

    setUp(() {
      container = ProviderContainer(
        overrides: [
          presetPhraseNotifierProvider
              .overrideWith(_TestablePresetPhraseNotifier.new),
        ],
      );
      notifier = container.read(presetPhraseNotifierProvider.notifier)
          as _TestablePresetPhraseNotifier;
    });

    tearDown(() => container.dispose());

    /// 回帰テスト: エラー画面が恒久的に固着するシナリオ
    ///
    /// PresetPhraseScreen は state.error != null のときリスト全体を
    /// エラー表示へ差し替える。エラーを消すのは loadPhrases() /
    /// resetToDefaults()（どちらも lib/ に呼び出し元が無い）と
    /// initializeDefaultPhrases()（phrases が非空だと早期return）だけなので、
    /// 「初期化失敗 → 1件追加成功 → 画面再訪」でエラーが解除不能になる。
    test('初期化失敗後に定型文を1件追加すると、画面再訪してもエラーが残らない', () async {
      // 1. initializeDefaultPhrases() が失敗してエラー画面
      notifier.setStateForTest(errorState);

      // 2. FABから定型文を1件追加（成功）
      await notifier.addPhrase('おはようございます', 'daily');

      // 3. phrases が非空になる／エラーは操作成功時に解消される
      final afterAdd = container.read(presetPhraseNotifierProvider);
      expect(afterAdd.phrases.length, equals(1));
      expect(afterAdd.error, isNull);

      // 4. 画面を再訪しても（initializeDefaultPhrases は早期returnする）
      //    エラーが復活しないこと
      await notifier.initializeDefaultPhrases();
      final afterRevisit = container.read(presetPhraseNotifierProvider);
      expect(afterRevisit.phrases.length, equals(1),
          reason: 'phrases が非空なので初期データ投入は早期returnする');
      expect(afterRevisit.error, isNull);
    });

    /// 成功したCRUDはいずれもエラーを解消する。
    /// メソッドごとに独立したテストにすることで、どれか1つでも
    /// clearError を落とすと必ずどこかが失敗するようにしている。
    PresetPhraseState stuckStateWithOnePhrase() {
      notifier.setStateForTest(errorState);
      return container.read(presetPhraseNotifierProvider);
    }

    test('updatePhrase() の成功でエラーが解消する', () async {
      stuckStateWithOnePhrase();
      await notifier.addPhrase('おはようございます', 'daily');
      final id = container.read(presetPhraseNotifierProvider).phrases.first.id;
      notifier.setStateForTest(
        container.read(presetPhraseNotifierProvider).copyWith(error: 'エラー'),
      );

      await notifier.updatePhrase(id, content: 'こんばんは');

      final state = container.read(presetPhraseNotifierProvider);
      expect(state.error, isNull);
      expect(state.phrases.first.content, equals('こんばんは'));
    });

    test('toggleFavorite() の成功でエラーが解消する', () async {
      stuckStateWithOnePhrase();
      await notifier.addPhrase('おはようございます', 'daily');
      final id = container.read(presetPhraseNotifierProvider).phrases.first.id;
      notifier.setStateForTest(
        container.read(presetPhraseNotifierProvider).copyWith(error: 'エラー'),
      );

      await notifier.toggleFavorite(id);

      final state = container.read(presetPhraseNotifierProvider);
      expect(state.error, isNull);
      // 設計変更: Phase 3 / WP-2 / Stage 3b - お気に入りの正はfavoriteProvider
      // だけ（ADR-005）。切り替えが効いたことはそちらで確認する。
      expect(container.read(favoriteProvider).favorites.length, equals(1));
    });

    test('deletePhrase() の成功でエラーが解消する', () async {
      stuckStateWithOnePhrase();
      await notifier.addPhrase('おはようございます', 'daily');
      final id = container.read(presetPhraseNotifierProvider).phrases.first.id;
      notifier.setStateForTest(
        container.read(presetPhraseNotifierProvider).copyWith(error: 'エラー'),
      );

      await notifier.deletePhrase(id);

      final state = container.read(presetPhraseNotifierProvider);
      expect(state.error, isNull);
      expect(state.phrases, isEmpty);
    });

    test('loadPhrases() 成功時はエラーを明示的にクリアする', () async {
      notifier.setStateForTest(errorState);

      await notifier.loadPhrases();

      final state = container.read(presetPhraseNotifierProvider);
      expect(state.error, isNull);
      expect(state.isLoading, isFalse);
    });

    /// resetToDefaults() 自体は clearError を持たない。phrases を空にした直後に
    /// 呼ぶ initializeDefaultPhrases() が早期returnせず必ずクリアするため、
    /// 二重にクリアする必要がない（重複させるとテストで検証できない
    /// デッドコードになる）。ここでは観測可能な最終状態のみを固定する。
    test('resetToDefaults() の完了後はエラーが解消している', () async {
      notifier.setStateForTest(errorState);

      await notifier.resetToDefaults();

      final state = container.read(presetPhraseNotifierProvider);
      expect(state.error, isNull);
      expect(state.phrases, isNotEmpty);
    });

    test('initializeDefaultPhrases() の再試行はエラーを明示的にクリアする', () async {
      notifier.setStateForTest(errorState);

      await notifier.initializeDefaultPhrases();

      final state = container.read(presetPhraseNotifierProvider);
      expect(state.error, isNull);
      expect(state.phrases, isNotEmpty);
    });

    /// 成功パスは冒頭のクリアに依存せず、自分でもクリアする必要がある。
    /// `await repo.saveAll()` の待機中に他経路がエラーを設定し得るため。
    test('initializeDefaultPhrases() は待機中に入ったエラーも成功時にクリアする', () async {
      final repo = _FakePresetPhraseRepository();
      when(repo.loadAllSync).thenReturn(<PresetPhrase>[]);

      final repoContainer = ProviderContainer(
        overrides: [
          presetPhraseRepositoryProvider.overrideWithValue(repo),
          presetPhraseNotifierProvider
              .overrideWith(_TestablePresetPhraseNotifier.new),
        ],
      );
      addTearDown(repoContainer.dispose);

      final repoNotifier =
          repoContainer.read(presetPhraseNotifierProvider.notifier)
              as _TestablePresetPhraseNotifier;

      // 保存の待機中に別経路がエラーを設定する
      when(() => repo.saveAll(any())).thenAnswer((_) async {
        repoNotifier.setStateForTest(const PresetPhraseState(
          error: '待機中に発生した別経路のエラー',
        ));
      });

      await repoNotifier.initializeDefaultPhrases();

      final state = repoContainer.read(presetPhraseNotifierProvider);
      expect(state.error, isNull);
      expect(state.phrases, isNotEmpty);
    });
  });

  group('FavoriteNotifier / HistoryNotifier のエラー保持挙動', () {
    test('FavoriteNotifier: 無関係な更新でエラーが消えない', () async {
      final container = ProviderContainer(
        overrides: [
          favoriteProvider.overrideWith(_TestableFavoriteNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(favoriteProvider.notifier)
          as _TestableFavoriteNotifier;
      notifier.setStateForTest(const FavoriteState(error: '保存に失敗しました'));

      await notifier.addFavorite('ありがとうございます');

      final state = container.read(favoriteProvider);
      expect(state.favorites.length, equals(1));
      expect(state.error, equals('保存に失敗しました'));
    });

    test('HistoryNotifier: 無関係な更新でエラーが消えない', () async {
      final container = ProviderContainer(
        overrides: [
          historyProvider.overrideWith(_TestableHistoryNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      final notifier =
          container.read(historyProvider.notifier) as _TestableHistoryNotifier;
      notifier.setStateForTest(const HistoryState(error: '保存に失敗しました'));

      await notifier.addHistory('こんにちは', HistoryType.manualInput);

      final state = container.read(historyProvider);
      expect(state.histories.length, equals(1));
      expect(state.error, equals('保存に失敗しました'));
    });
  });

  group('TTSNotifier のエラークリア挙動', () {
    late ProviderContainer container;
    late MockFlutterTts mockFlutterTts;

    setUpAll(() {
      registerFallbackValue('');
      registerFallbackValue(0.0);
    });

    setUp(() {
      mockFlutterTts = MockFlutterTts();
      when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.setSpeechRate(any()))
          .thenAnswer((_) async => 1);
      when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);

      container = ProviderContainer(
        overrides: [
          ttsProvider.overrideWith(
            () => TTSNotifier(serviceOverride: TTSService(tts: mockFlutterTts)),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('読み上げ失敗後に成功するとエラーメッセージが消える', () async {
      // 回帰: 旧実装（errorMessage ?? this.errorMessage）では、
      // TTSService 側の errorMessage が null に戻らないこともあり、
      // 一度出たエラーメッセージが状態に残り続けていた
      final notifier = container.read(ttsProvider.notifier);

      // Given: 読み上げが失敗する
      when(() => mockFlutterTts.speak(any())).thenThrow(Exception('TTS error'));
      await notifier.speak('失敗するテキスト');

      expect(container.read(ttsProvider).state, equals(TTSState.error));
      expect(container.read(ttsProvider).errorMessage, equals('読み上げに失敗しました'));

      // When: 次の読み上げが成功する
      when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
      await notifier.speak('成功するテキスト');

      // Then: エラーメッセージがクリアされる
      expect(container.read(ttsProvider).state, equals(TTSState.speaking));
      expect(container.read(ttsProvider).errorMessage, isNull);
    });

    test('読み上げ失敗後に停止が成功するとエラーメッセージが消える', () async {
      final notifier = container.read(ttsProvider.notifier);

      when(() => mockFlutterTts.speak(any())).thenThrow(Exception('TTS error'));
      await notifier.speak('失敗するテキスト');
      expect(container.read(ttsProvider).errorMessage, isNotNull);

      await notifier.stop();

      expect(container.read(ttsProvider).state, equals(TTSState.stopped));
      expect(container.read(ttsProvider).errorMessage, isNull);
    });

    test('停止失敗時はエラーメッセージが状態へ反映される', () async {
      // 回帰: 旧実装の stop() は copyWith(state: ...) だけで errorMessage を
      // 渡しておらず、停止失敗のメッセージが状態に反映されていなかった
      final notifier = container.read(ttsProvider.notifier);

      await notifier.speak('読み上げるテキスト');
      when(() => mockFlutterTts.stop()).thenThrow(Exception('stop error'));

      await notifier.stop();

      expect(container.read(ttsProvider).state, equals(TTSState.error));
      expect(
        container.read(ttsProvider).errorMessage,
        equals('読み上げ停止に失敗しました'),
      );
    });

    test('未初期化のまま speak() して初期化に失敗した場合もエラーメッセージが残る', () async {
      // 回帰: TTSService.initialize() が state を error にしないと、
      // _syncStateFromService() が「エラーなし」と誤判定して
      // 初期化失敗のメッセージを消してしまう
      when(() => mockFlutterTts.setLanguage(any()))
          .thenThrow(Exception('init error'));

      final notifier = container.read(ttsProvider.notifier);
      await notifier.speak('読み上げるテキスト');

      expect(container.read(ttsProvider).state, equals(TTSState.error));
      expect(
        container.read(ttsProvider).errorMessage,
        equals('TTS初期化に失敗しました'),
      );
    });

    test('速度変更ではエラーメッセージを保持する', () async {
      final notifier = container.read(ttsProvider.notifier);

      when(() => mockFlutterTts.speak(any())).thenThrow(Exception('TTS error'));
      await notifier.speak('失敗するテキスト');
      expect(container.read(ttsProvider).errorMessage, isNotNull);

      await notifier.setSpeed(TTSSpeed.fast);

      // 速度変更はエラーの解消とは無関係なので、エラーは保持されたまま
      expect(container.read(ttsProvider).currentSpeed, equals(TTSSpeed.fast));
      expect(container.read(ttsProvider).errorMessage, equals('読み上げに失敗しました'));
    });
  });
}
