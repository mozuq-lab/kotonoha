/// チュートリアル状態管理プロバイダーテスト
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kotonoha_app/features/help/providers/tutorial_provider.dart';

void main() {
  group('TutorialProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('初回起動時はチュートリアル未完了状態', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Providerを初期化
      final notifier = container.read(tutorialProvider.notifier);
      await notifier.initialize();

      final state = container.read(tutorialProvider);
      expect(state.isCompleted, isFalse);
      expect(state.shouldShowTutorial, isTrue);
    });

    test('チュートリアル完了後はフラグがtrueになる', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(tutorialProvider.notifier);
      await notifier.initialize();

      // チュートリアルを完了
      await notifier.completeTutorial();

      final state = container.read(tutorialProvider);
      expect(state.isCompleted, isTrue);
      expect(state.shouldShowTutorial, isFalse);
    });

    test('完了フラグがshared_preferencesに保存される', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(tutorialProvider.notifier);
      await notifier.initialize();
      await notifier.completeTutorial();

      // 新しいコンテナで再読み込み
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final notifier2 = container2.read(tutorialProvider.notifier);
      await notifier2.initialize();

      final state = container2.read(tutorialProvider);
      expect(state.isCompleted, isTrue);
    });

    test('2回目以降の起動ではチュートリアルは表示されない', () async {
      SharedPreferences.setMockInitialValues({
        'tutorial_completed': true,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(tutorialProvider.notifier);
      await notifier.initialize();

      final state = container.read(tutorialProvider);
      expect(state.isCompleted, isTrue);
      expect(state.shouldShowTutorial, isFalse);
    });

    test('チュートリアルをリセットできる（テスト用）', () async {
      SharedPreferences.setMockInitialValues({
        'tutorial_completed': true,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(tutorialProvider.notifier);
      await notifier.initialize();

      // リセット
      await notifier.resetTutorial();

      final state = container.read(tutorialProvider);
      expect(state.isCompleted, isFalse);
      expect(state.shouldShowTutorial, isTrue);
    });
  });

  group('TutorialState', () {
    test('初期状態はisCompleted=false', () {
      const state = TutorialState();
      expect(state.isCompleted, isFalse);
      // isLoading=true のためshouldShowTutorialはfalse（読み込み完了まで待つ）
      expect(state.shouldShowTutorial, isFalse);
    });

    test('読み込み完了後はshouldShowTutorial=true', () {
      const state = TutorialState(isLoading: false);
      expect(state.isCompleted, isFalse);
      expect(state.shouldShowTutorial, isTrue);
    });

    test('完了状態のcopyWith', () {
      const state = TutorialState();
      final completed = state.copyWith(isCompleted: true);

      expect(completed.isCompleted, isTrue);
      expect(completed.shouldShowTutorial, isFalse);
    });

    test('isLoading状態の管理', () {
      const state = TutorialState(isLoading: true);
      expect(state.isLoading, isTrue);

      final loaded = state.copyWith(isLoading: false);
      expect(loaded.isLoading, isFalse);
    });
  });
}
