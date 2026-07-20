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
    final colorScheme = Theme.of(context).colorScheme;

    // ボタンラベルと色を決定
    // 【AA対応】: 停止時のColors.red(#F44336)+白文字は約3.9:1、
    // 読み上げ時のライトテーマprimaryColor(#2196F3)+白文字は約3.1:1で
    // いずれもWCAG AA（4.5:1）未達だった。ハードコード色をやめ、
    // テーマのcolorSchemeの色（primary/error）を背景に使用することで
    // 高コントラストテーマの枠線スタイル（ElevatedButtonThemeDataのside）も
    // 活かされるようにする。
    // 【文字色】: colorScheme.onError はライト/高コントラストテーマで
    // デフォルト値（白）のままとなっており、実際の背景色との組み合わせでは
    // AA基準（4.5:1）を満たさないケースがある（例: ダークテーマの
    // error(#D32F2F)+黒文字は約4.2:1で未達、高コントラストテーマの
    // error(#FF0000)+白文字は約4.0:1で未達）。そのため、実際の背景色の
    // 輝度から黒・白のうちコントラスト比が高い方を都度算出して使用し、
    // 3テーマ×2状態のすべてでWCAG AAを満たすことを保証する。
    final label = isSpeaking ? '停止' : '読み上げ';
    final backgroundColor = isSpeaking
        ? (stopButtonColor ?? colorScheme.error)
        : (speakButtonColor ?? colorScheme.primary);
    final foregroundColor = _bestContrastingTextColor(backgroundColor);
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
              foregroundColor: foregroundColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
                vertical: AppSizes.paddingSmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSizes.borderRadiusMedium),
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

/// 背景色に対してより高いコントラスト比を確保できる文字色（黒 or 白）を選ぶ
///
/// 【設計方針】: テーマが提供する`onError`/`onPrimary`に頼らず、実際の
/// 背景色の相対輝度（[Color.computeLuminance]）からWCAG 2.1のコントラスト比
/// （`(明るい方の輝度 + 0.05) / (暗い方の輝度 + 0.05)`）を算出し、黒・白の
/// うちコントラスト比が高い方を採用する。これにより、テーマ側の色定義に
/// 依存せず、どのテーマ・どの背景色でも常に最良のコントラストを確保できる。
Color _bestContrastingTextColor(Color background) {
  final whiteContrast = _contrastRatio(Colors.white, background);
  final blackContrast = _contrastRatio(Colors.black, background);
  return whiteContrast >= blackContrast ? Colors.white : Colors.black;
}

/// WCAG 2.1のコントラスト比を計算する
///
/// 計算式: `(L1 + 0.05) / (L2 + 0.05)`（L1は明るい方の相対輝度）
double _contrastRatio(Color a, Color b) {
  final luminanceA = a.computeLuminance();
  final luminanceB = b.computeLuminance();
  final lighter = luminanceA > luminanceB ? luminanceA : luminanceB;
  final darker = luminanceA > luminanceB ? luminanceB : luminanceA;
  return (lighter + 0.05) / (darker + 0.05);
}
