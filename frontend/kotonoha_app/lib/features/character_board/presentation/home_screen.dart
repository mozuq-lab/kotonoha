/// Home screen widget (Character Board)
///
/// TASK-0015: go_routerナビゲーション設定・ルーティング実装
/// TASK-0060: Phase 3 統合テスト - ホーム画面統合
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/router/app_router.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/delete_button.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/clear_all_button.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/quick_response/presentation/widgets/quick_response_buttons.dart';
import 'package:kotonoha_app/features/quick_response/domain/quick_response_type.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/tts_button.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';

/// ホーム画面（文字盤画面）ウィジェット
///
/// アプリケーションのメイン画面。文字盤入力機能を提供する。
///
/// 実装要件:
/// - FR-002: 初期ルート「/」でこの画面を表示
/// - REQ-001: 五十音配列の文字盤UI
/// - REQ-002: タップで入力欄に文字追加
/// - REQ-201: クイック応答ボタン（はい/いいえ/わからない）
/// - REQ-401: TTS読み上げ機能
class HomeScreen extends ConsumerWidget {
  /// ホーム画面を作成する。
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputBuffer = ref.watch(inputBufferProvider);
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final fontSize = settingsAsync.asData?.value.fontSize ?? FontSize.medium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('kotonoha'),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_list_bulleted),
            tooltip: '定型文',
            onPressed: () => context.push(AppRoutes.presetPhrases),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '履歴',
            onPressed: () => context.push(AppRoutes.history),
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'お気に入り',
            onPressed: () => context.push(AppRoutes.favorites),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '設定',
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // クイック応答ボタン（はい/いいえ/わからない）
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: QuickResponseButtons(
                onResponse: (type) {
                  // TTS読み上げと履歴保存
                  _speakAndSaveHistory(ref, type.label);
                },
                onTTSSpeak: (text) {
                  ref.read(ttsProvider.notifier).speak(text);
                },
                fontSize: fontSize,
              ),
            ),
            // 入力表示エリア
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
              ),
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius:
                    BorderRadius.circular(AppSizes.borderRadiusMedium),
              ),
              constraints: const BoxConstraints(minHeight: 80),
              child: Text(
                inputBuffer.isEmpty ? '入力してください...' : inputBuffer,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: _getFontSizeValue(fontSize),
                      color: inputBuffer.isEmpty
                          ? Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(128)
                          : Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            // コントロールボタン（削除、全消去、読み上げ）
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      DeleteButton(
                        enabled: inputBuffer.isNotEmpty,
                        onPressed: () {
                          ref
                              .read(inputBufferProvider.notifier)
                              .deleteLastCharacter();
                        },
                      ),
                      const SizedBox(width: AppSizes.paddingSmall),
                      ClearAllButton(
                        enabled: inputBuffer.isNotEmpty,
                        onConfirmed: () {
                          ref.read(inputBufferProvider.notifier).clear();
                        },
                      ),
                    ],
                  ),
                  TTSButton(
                    text: inputBuffer,
                    onSpeak: () {
                      if (inputBuffer.isNotEmpty) {
                        _saveToHistory(ref, inputBuffer);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            // 文字盤
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingSmall,
                ),
                child: CharacterBoardWidget(
                  onCharacterTap: (character) {
                    ref
                        .read(inputBufferProvider.notifier)
                        .addCharacter(character);
                  },
                  fontSize: fontSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// TTSで読み上げて履歴に保存
  void _speakAndSaveHistory(WidgetRef ref, String text) {
    ref.read(ttsProvider.notifier).speak(text);
    _saveToHistory(ref, text);
  }

  /// 履歴に保存
  void _saveToHistory(WidgetRef ref, String text) {
    ref
        .read(historyProvider.notifier)
        .addHistory(text, HistoryType.manualInput);
  }

  /// FontSizeからフォントサイズ値を取得
  ///
  /// REQ-802: 入力欄のフォントサイズを設定に追従させる
  /// 🔵 青信号: AppSizesの定義に基づく
  double _getFontSizeValue(FontSize fontSize) {
    switch (fontSize) {
      case FontSize.small:
        return AppSizes.fontSizeSmall;
      case FontSize.medium:
        return AppSizes.fontSizeMedium;
      case FontSize.large:
        return AppSizes.fontSizeLarge;
    }
  }
}
