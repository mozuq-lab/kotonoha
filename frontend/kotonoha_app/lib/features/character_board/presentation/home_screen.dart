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
import 'package:kotonoha_app/features/ai_conversion/domain/exceptions/ai_conversion_exception.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/ai_conversion_button.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/ai_conversion_result_dialog.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/politeness_level_selector.dart';
import 'package:kotonoha_app/features/ai_conversion/providers/ai_conversion_provider.dart';
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
    final settings = settingsAsync.asData?.value;
    final fontSize = settings?.fontSize ?? FontSize.medium;
    final aiPoliteness = settings?.aiPoliteness ?? PolitenessLevel.normal;

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
              // 【アクセシビリティ対応】: liveRegionで入力中テキストの変化を
              // スクリーンリーダーが自動読み上げできるようにする。
              child: Semantics(
                liveRegion: true,
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSizes.paddingMedium,
                runSpacing: AppSizes.paddingSmall,
                children: [
                  PolitenessLevelSelector(
                    selectedLevel: aiPoliteness,
                    onLevelChanged: (level) {
                      ref
                          .read(settingsNotifierProvider.notifier)
                          .setAIPoliteness(level);
                    },
                  ),
                  AIConversionButton(
                    inputText: inputBuffer,
                    politenessLevel: aiPoliteness,
                    onConvert: () => _convertWithAI(
                      context,
                      ref,
                      inputBuffer,
                      aiPoliteness,
                    ),
                    onConversionComplete: (convertedText) {
                      if (!context.mounted) return;
                      _showConversionResult(
                        context,
                        ref,
                        inputBuffer,
                        convertedText,
                        aiPoliteness,
                      );
                    },
                    onConversionError: (error) {
                      if (!context.mounted) return;
                      _showAIConversionError(context, error);
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

  Future<String> _convertWithAI(
    BuildContext context,
    WidgetRef ref,
    String inputText,
    PolitenessLevel politenessLevel,
  ) async {
    final hasConsent = await _ensureAIPrivacyConsent(context, ref);
    if (!hasConsent) {
      throw const AIConversionException(
        code: 'PRIVACY_CONSENT_REQUIRED',
        message: 'AI変換を利用するにはプライバシー同意が必要です。',
      );
    }

    await ref.read(aiConversionProvider.notifier).convert(
          inputText: inputText,
          politenessLevel: politenessLevel,
        );

    final state = ref.read(aiConversionProvider);
    if (state.hasResult && state.convertedText != null) {
      return state.convertedText!;
    }

    throw state.error ??
        const AIConversionException(
          code: 'AI_CONVERSION_FAILED',
          message: 'AI変換に失敗しました。しばらく待ってから再度お試しください。',
        );
  }

  Future<String> _regenerateWithAI(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final hasConsent = await _ensureAIPrivacyConsent(context, ref);
    if (!hasConsent) {
      throw const AIConversionException(
        code: 'PRIVACY_CONSENT_REQUIRED',
        message: 'AI変換を利用するにはプライバシー同意が必要です。',
      );
    }

    await ref.read(aiConversionProvider.notifier).regenerate();

    final state = ref.read(aiConversionProvider);
    if (state.hasResult && state.convertedText != null) {
      return state.convertedText!;
    }

    throw state.error ??
        const AIConversionException(
          code: 'AI_REGENERATION_FAILED',
          message: 'AI再生成に失敗しました。しばらく待ってから再度お試しください。',
        );
  }

  Future<bool> _ensureAIPrivacyConsent(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final loadedSettings = ref.read(settingsNotifierProvider).asData?.value;
    final settings =
        loadedSettings ?? await ref.read(settingsNotifierProvider.future);
    if (settings == null) return false;
    if (settings.hasAcceptedAIPrivacyPolicy) return true;
    if (!context.mounted) return false;

    final accepted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('AI変換の利用確認'),
            content: const Text(
              'AI変換では入力した文章を外部のAIサービスへ送信します。送信前に内容を確認し、同意できる場合のみ利用してください。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('同意しない'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('同意して利用'),
              ),
            ],
          ),
        ) ??
        false;

    if (accepted) {
      await ref
          .read(settingsNotifierProvider.notifier)
          .setAIPrivacyConsent(true);
    }
    return accepted;
  }

  void _showConversionResult(
    BuildContext context,
    WidgetRef ref,
    String originalText,
    String convertedText,
    PolitenessLevel politenessLevel,
  ) {
    AIConversionResultDialog.show(
      context: context,
      originalText: originalText,
      convertedText: convertedText,
      politenessLevel: politenessLevel,
      onAdopt: (result) {
        Navigator.of(context).pop();
        ref.read(inputBufferProvider.notifier).setText(result);
      },
      onRegenerate: () {
        Navigator.of(context).pop();
        Future<void>.microtask(() async {
          if (!context.mounted) return;
          try {
            final result = await _regenerateWithAI(context, ref);
            if (!context.mounted) return;
            _showConversionResult(
              context,
              ref,
              originalText,
              result,
              politenessLevel,
            );
          } catch (e) {
            if (context.mounted) {
              _showAIConversionError(context, e);
            }
          }
        });
      },
      onUseOriginal: (original) {
        Navigator.of(context).pop();
        ref.read(inputBufferProvider.notifier).setText(original);
      },
    );
  }

  void _showAIConversionError(BuildContext context, Object error) {
    if (error is AIConversionException &&
        error.code == 'PRIVACY_CONSENT_REQUIRED') {
      return;
    }

    final message = error is AIConversionException
        ? error.message
        : 'AI変換に失敗しました。しばらく待ってから再度お試しください。';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
