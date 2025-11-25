/// TTSButton ウィジェット
///
/// TASK-0050: TTS読み上げ中断機能
/// 要件: REQ-402（読み上げボタン表示）、REQ-403（停止機能）、REQ-3003（停止ボタン表示）
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
///
/// TTS読み上げ/停止ボタンウィジェット。
/// TTSの状態に応じて「読み上げ」または「停止」ボタンを表示する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';

/// TTS読み上げ/停止ボタンウィジェット
///
/// TTSの状態（idle/speaking/stopped/completed/error）に応じて
/// 「読み上げ」または「停止」ボタンを表示する。
///
/// REQ-402: 読み上げボタンを明確に表示
/// REQ-403: 読み上げ中の停止・中断機能を提供
/// REQ-3003: 読み上げ実行中状態では「停止」ボタンとして表示
///
/// 使用例:
/// ```dart
/// TTSButton(
///   text: '読み上げるテキスト',
///   onSpeak: () => print('読み上げ開始'),
/// )
/// ```
class TTSButton extends ConsumerWidget {
  /// 読み上げるテキスト
  final String text;

  /// 読み上げボタンタップ時のコールバック
  /// TTSNotifier.speak()を呼び出す前に実行される
  final VoidCallback? onSpeak;

  /// カスタム背景色（読み上げボタン用）
  final Color? speakButtonColor;

  /// カスタム背景色（停止ボタン用）
  final Color? stopButtonColor;

  /// ボタンの幅（オプション）
  /// 指定しない場合はデフォルト値、最小44px保証
  final double? width;

  /// ボタンの高さ（オプション）
  /// 指定しない場合はデフォルト60px、最小44px保証
  final double? height;

  /// TTSButtonを作成する
  const TTSButton({
    super.key,
    required this.text,
    this.onSpeak,
    this.speakButtonColor,
    this.stopButtonColor,
    this.width,
    this.height,
  });

  /// 実際に使用する高さを計算（最小44px保証）
  /// REQ-5001: タップターゲット44px×44px以上
  double get _effectiveHeight {
    final requestedHeight = height ?? AppSizes.recommendedTapTarget;
    return requestedHeight < AppSizes.minTapTarget
        ? AppSizes.minTapTarget
        : requestedHeight;
  }

  /// 実際に使用する幅を計算（最小44px保証）
  double get _effectiveWidth {
    final requestedWidth = width ?? 120.0;
    return requestedWidth < AppSizes.minTapTarget
        ? AppSizes.minTapTarget
        : requestedWidth;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TTSの状態を監視
    final ttsState = ref.watch(ttsProvider);
    final isSpeaking = ttsState.state == TTSState.speaking;

    // ボタンラベルと色を決定
    final label = isSpeaking ? '停止' : '読み上げ';
    final backgroundColor = isSpeaking
        ? (stopButtonColor ?? Colors.red)
        : (speakButtonColor ?? Theme.of(context).primaryColor);
    final icon = isSpeaking ? Icons.stop : Icons.volume_up;

    return Semantics(
      label: label,
      button: true,
      child: SizedBox(
        width: width != null ? _effectiveWidth : null,
        height: _effectiveHeight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: _effectiveWidth,
            minHeight: _effectiveHeight,
          ),
          child: ElevatedButton.icon(
            onPressed: () => _handleTap(ref, isSpeaking),
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
                vertical: AppSizes.paddingSmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
              ),
            ),
            icon: Icon(icon),
            label: Text(
              label,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// タップハンドラ
  ///
  /// isSpeakingの状態に応じて、読み上げ開始または停止を実行
  void _handleTap(WidgetRef ref, bool isSpeaking) {
    final notifier = ref.read(ttsProvider.notifier);

    if (isSpeaking) {
      // 停止ボタンタップ: TTS停止
      notifier.stop();
    } else {
      // 読み上げボタンタップ: コールバック実行 + TTS開始
      onSpeak?.call();
      notifier.speak(text);
    }
  }
}
