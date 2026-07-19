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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 【レスポンシブ対応】: 可視高さ・幅に応じてレイアウトを切り替える。
            // - isCompactHeight: 主に横持ちスマホ（可視高さ< compactHeightThreshold）。
            //   固定サイズのセクションを縦に積むと必要高さが可視高さを超え、
            //   RenderFlexオーバーフローが発生するため、左右2ペイン構成に切替える。
            // - isPhoneWidth: 縦持ちスマホ幅（< phoneMaxWidth）。オーバーフローは
            //   しないが、各セクションをコンパクト化し文字盤の可視行数を増やす。
            final isCompactHeight =
                constraints.maxHeight < AppSizes.compactHeightThreshold;
            final isPhoneWidth = constraints.maxWidth < AppSizes.phoneMaxWidth;

            if (isCompactHeight) {
              return _buildCompactLandscapeLayout(
                context,
                ref,
                inputBuffer: inputBuffer,
                fontSize: fontSize,
                aiPoliteness: aiPoliteness,
                availableHeight: constraints.maxHeight,
              );
            }

            return _buildStandardLayout(
              context,
              ref,
              inputBuffer: inputBuffer,
              fontSize: fontSize,
              aiPoliteness: aiPoliteness,
              compact: isPhoneWidth,
              availableHeight: constraints.maxHeight,
            );
          },
        ),
      ),
    );
  }

  /// 標準レイアウト（タブレット・縦持ちスマホ）
  ///
  /// 各セクションを縦に積むレイアウト。[compact] がtrue（スマホ幅）の場合は
  /// パディング・ボタン高さを圧縮し、文字盤（Expanded）の可視領域を広げる。
  Widget _buildStandardLayout(
    BuildContext context,
    WidgetRef ref, {
    required String inputBuffer,
    required FontSize fontSize,
    required PolitenessLevel aiPoliteness,
    required bool compact,
    required double availableHeight,
  }) {
    final sectionGap = compact ? AppSizes.paddingXSmall : AppSizes.paddingSmall;

    return Column(
      children: [
        // クイック応答ボタン（はい/いいえ/わからない）
        _buildQuickResponseSection(
          ref,
          fontSize: fontSize,
          padding: compact ? AppSizes.paddingSmall : AppSizes.paddingMedium,
          compact: compact,
        ),
        // 入力表示エリア
        _buildInputArea(
          context,
          inputBuffer: inputBuffer,
          fontSize: fontSize,
          compact: compact,
          availableHeight: availableHeight,
        ),
        SizedBox(height: sectionGap),
        // コントロールボタン（削除、全消去、読み上げ）
        _buildControlRow(ref, inputBuffer: inputBuffer),
        SizedBox(height: sectionGap),
        _buildPolitenessAIRow(
          context,
          ref,
          aiPoliteness: aiPoliteness,
          inputBuffer: inputBuffer,
          compact: compact,
        ),
        SizedBox(height: sectionGap),
        // 文字盤
        Expanded(
          child: _buildCharacterBoard(ref, fontSize: fontSize),
        ),
      ],
    );
  }

  /// コンパクト2ペインレイアウト（主に横持ちスマホ、可視高さが乏しい場合）
  ///
  /// 縦積みだと固定セクションの必要高さが可視高さを超えRenderFlex
  /// オーバーフローが発生するため、左ペイン（各種操作UI・スクロール可）と
  /// 右ペイン（文字盤、残り全高さをExpandedで使用）の横並びに切り替える。
  /// アプリの主機能である文字盤が消えてしまう不具合を解消する。
  Widget _buildCompactLandscapeLayout(
    BuildContext context,
    WidgetRef ref, {
    required String inputBuffer,
    required FontSize fontSize,
    required PolitenessLevel aiPoliteness,
    required double availableHeight,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 左ペイン: 操作UI一式（スクロール可能にしてオーバーフローを防止）
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.paddingXSmall,
            ),
            child: Column(
              children: [
                _buildQuickResponseSection(
                  ref,
                  fontSize: fontSize,
                  padding: AppSizes.paddingXSmall,
                  compact: true,
                ),
                _buildInputArea(
                  context,
                  inputBuffer: inputBuffer,
                  fontSize: fontSize,
                  compact: true,
                  availableHeight: availableHeight,
                ),
                const SizedBox(height: AppSizes.paddingXSmall),
                _buildControlRow(ref, inputBuffer: inputBuffer),
                const SizedBox(height: AppSizes.paddingXSmall),
                _buildPolitenessAIRow(
                  context,
                  ref,
                  aiPoliteness: aiPoliteness,
                  inputBuffer: inputBuffer,
                  compact: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSizes.paddingXSmall),
        // 右ペイン: 文字盤（主機能。残り全高さを使用する）
        Expanded(
          flex: 3,
          child: _buildCharacterBoard(ref, fontSize: fontSize),
        ),
      ],
    );
  }

  /// クイック応答ボタンセクションを構築する
  Widget _buildQuickResponseSection(
    WidgetRef ref, {
    required FontSize fontSize,
    required double padding,
    required bool compact,
  }) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: QuickResponseButtons(
        onResponse: (type) {
          // TTS読み上げと履歴保存
          _speakAndSaveHistory(ref, type.label);
        },
        onTTSSpeak: (text) {
          ref.read(ttsProvider.notifier).speak(text);
        },
        fontSize: fontSize,
        buttonHeight:
            compact ? AppSizes.quickResponseButtonHeightCompact : null,
      ),
    );
  }

  /// 入力表示エリアを構築する
  ///
  /// 長文（最大1000文字）入力時に文字盤エリアを圧迫しないよう、
  /// 可視高さの約20%を上限（maxHeight）とし、内部をSingleChildScrollView
  /// （reverse: true）にすることで、超過分は末尾（最新入力）が見える形で
  /// スクロール可能にする。
  Widget _buildInputArea(
    BuildContext context, {
    required String inputBuffer,
    required FontSize fontSize,
    required bool compact,
    required double availableHeight,
  }) {
    final minHeight = compact
        ? AppSizes.inputAreaMinHeightCompact
        : AppSizes.inputAreaMinHeightStandard;
    final ratioBasedMaxHeight = availableHeight.isFinite
        ? availableHeight * AppSizes.inputAreaMaxHeightRatio
        : double.infinity;
    final maxHeight =
        ratioBasedMaxHeight > minHeight ? ratioBasedMaxHeight : minHeight;
    final horizontalMargin =
        compact ? AppSizes.paddingSmall : AppSizes.paddingMedium;
    final contentPadding =
        compact ? AppSizes.paddingSmall : AppSizes.paddingMedium;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      padding: EdgeInsets.all(contentPadding),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
      ),
      constraints: BoxConstraints(minHeight: minHeight, maxHeight: maxHeight),
      // 【アクセシビリティ対応】: liveRegionで入力中テキストの変化を
      // スクリーンリーダーが自動読み上げできるようにする。
      child: Semantics(
        liveRegion: true,
        child: SingleChildScrollView(
          reverse: true,
          child: Text(
            inputBuffer.isEmpty ? '入力してください...' : inputBuffer,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: _getFontSizeValue(fontSize),
                  color: inputBuffer.isEmpty
                      ? Theme.of(context).colorScheme.onSurface.withAlpha(128)
                      : Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
      ),
    );
  }

  /// コントロールボタン行（削除・全消去・読み上げ）を構築する
  ///
  /// 【バグ修正】: コンパクト2ペインレイアウトの左ペイン（幅の狭いExpanded flex:2）
  /// では、固定サイズのボタン群がRow(mainAxisAlignment.spaceBetween)の
  /// 幅を超えRenderFlexオーバーフローが発生していた。Wrapに変更することで、
  /// 幅に余裕がある場合は従来通り1行（spaceBetween相当）で表示しつつ、
  /// 幅が不足する場合はスワイプ操作を必要とせず2行に折り返して収める
  /// （タップ操作のみで完結させるための対応）。
  Widget _buildControlRow(
    WidgetRef ref, {
    required String inputBuffer,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSizes.paddingSmall,
        runSpacing: AppSizes.paddingSmall,
        children: [
          // 【バグ修正】: 削除・全消去ボタン（各60px推奨サイズ）は、コンパクト
          // 2ペインレイアウトの左ペインのように2ボタン分の幅すら確保できない
          // 極端に狭い幅では、この内側グループ自体もWrapにしないと
          // オーバーフローする（外側WrapはRunをまたぐ折り返しのみ制御し、
          // 単一の子の内部レイアウトまでは救えないため）。
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSizes.paddingSmall,
            runSpacing: AppSizes.paddingSmall,
            children: [
              DeleteButton(
                enabled: inputBuffer.isNotEmpty,
                onPressed: () {
                  ref.read(inputBufferProvider.notifier).deleteLastCharacter();
                },
              ),
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
    );
  }

  /// 丁寧さレベル選択＋AI変換ボタンのセクションを構築する
  Widget _buildPolitenessAIRow(
    BuildContext context,
    WidgetRef ref, {
    required PolitenessLevel aiPoliteness,
    required String inputBuffer,
    required bool compact,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSizes.paddingMedium,
        runSpacing: compact ? AppSizes.paddingXSmall : AppSizes.paddingSmall,
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
    );
  }

  /// 文字盤セクションを構築する
  Widget _buildCharacterBoard(
    WidgetRef ref, {
    required FontSize fontSize,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSmall,
      ),
      child: CharacterBoardWidget(
        onCharacterTap: (character) {
          ref.read(inputBufferProvider.notifier).addCharacter(character);
        },
        fontSize: fontSize,
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
