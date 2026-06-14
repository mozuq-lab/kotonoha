/// TTS速度設定ウィジェット
///
/// TASK-0049: TTS速度設定（遅い/普通/速い）
/// TDD-TTS-SLOWER-SPEED: TTS読み上げ速度の追加オプション（より遅い速度の追加）
/// 読み上げ速度を4段階から選択できるUIウィジェット
///
/// 【機能概要】: TTS読み上げ速度を視覚的に選択できるUI
/// 【設計方針】: ユーザーが直感的に操作できる4つのボタン
/// 【アクセシビリティ】: 最小タップサイズ44px、現在選択中をハイライト表示
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tts/domain/models/tts_speed.dart';
import '../../providers/settings_provider.dart';

/// TTS速度設定ウィジェット
///
/// REQ-404: 読み上げ速度を「とても遅い」「遅い」「普通」「速い」の4段階から選択できる
/// (元の要件を拡張: 3段階 → 4段階)
///
/// 【使用シーン】:
/// - ユーザーが設定画面でTTS読み上げ速度を変更する場合
/// - 高齢者向けに聞き取りやすい速度を設定する場合
/// - 聴覚に配慮が必要な方向けにより遅い速度を設定する場合
/// - 慣れたユーザーが効率的な速度を設定する場合
///
/// 【UI設計】:
/// - 4つの選択肢ボタン（とても遅い/遅い/普通/速い）
/// - 現在選択中の速度をハイライト表示（背景色・ボーダー）
/// - タップで速度を即座に変更
/// - 最小タップサイズ44px以上（アクセシビリティ要件）
///
/// 参照: requirements.md（148-158行目）、interfaces.dart（298-319行目）
/// 🔵 信頼性レベル: 高（要件定義書ベース）
class TTSSpeedSettingsWidget extends ConsumerWidget {
  /// TTS速度設定ウィジェットを作成する。
  const TTSSpeedSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 【状態取得】: 現在のアプリ設定を取得
    // 【非同期処理】: AsyncValueから値を取得し、ローディング・エラー状態を処理
    final settingsAsyncValue = ref.watch(settingsNotifierProvider);

    return settingsAsyncValue.when(
      // 【データ読み込み済み】: 設定が正常に取得できた場合
      data: (settings) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 【セクションラベル】: TTC-049-018で検証される「読み上げ速度」ラベル
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '読み上げ速度',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // 【速度選択ボタン】: 4つの選択肢（とても遅い/遅い/普通/速い）
            // 【レイアウト】: Wrapを使用してボタンが収まらない場合は折り返し
            // 【テスト対応】: TTC-VS-004、TTC-VS-012
            // 🔵 信頼性レベル: 高（要件定義書ベース）
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 【とても遅いボタン】: TTC-VS-005、TTC-VS-006で検証 🆕
                // 🔵 信頼性レベル: 高（要件定義書ベース）
                _SpeedButton(
                  label: 'とても遅い',
                  speed: TTSSpeed.verySlow,
                  isSelected: settings.ttsSpeed == TTSSpeed.verySlow,
                  onTap: () => _onSpeedChanged(ref, TTSSpeed.verySlow),
                ),
                // 【遅いボタン】: TTC-049-007、TTC-049-020で検証
                _SpeedButton(
                  label: '遅い',
                  speed: TTSSpeed.slow,
                  isSelected: settings.ttsSpeed == TTSSpeed.slow,
                  onTap: () => _onSpeedChanged(ref, TTSSpeed.slow),
                ),
                // 【普通ボタン】: TTC-049-008で検証
                _SpeedButton(
                  label: '普通',
                  speed: TTSSpeed.normal,
                  isSelected: settings.ttsSpeed == TTSSpeed.normal,
                  onTap: () => _onSpeedChanged(ref, TTSSpeed.normal),
                ),
                // 【速いボタン】: TTC-049-009、TTC-049-019で検証
                _SpeedButton(
                  label: '速い',
                  speed: TTSSpeed.fast,
                  isSelected: settings.ttsSpeed == TTSSpeed.fast,
                  onTap: () => _onSpeedChanged(ref, TTSSpeed.fast),
                ),
              ],
            ),
          ],
        );
      },
      // 【ローディング中】: 設定読み込み中の表示
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      // 【エラー時】: 設定読み込み失敗時の表示
      error: (error, stackTrace) => Center(
        child: Text('設定の読み込みに失敗しました: $error'),
      ),
    );
  }

  /// 速度変更時の処理
  ///
  /// SettingsNotifierのsetTTSSpeedを呼び出して速度を変更する。
  ///
  /// [ref] WidgetRef - Riverpodのリファレンス
  /// [speed] TTSSpeed - 新しい速度
  void _onSpeedChanged(WidgetRef ref, TTSSpeed speed) {
    // 【速度変更】: SettingsNotifierのsetTTSSpeedを呼び出し
    // 【即座反映】: 楽観的更新によりUI状態が即座に更新される（REQ-2007）
    // 【TTS連携】: SettingsNotifier内でTTSNotifierのsetSpeedも呼び出される
    final settingsNotifier = ref.read(settingsNotifierProvider.notifier);
    settingsNotifier.setTTSSpeed(speed);
  }
}

/// 速度選択ボタン
///
/// 【機能概要】: TTS速度を選択するための個別ボタン
/// 【設計方針】: 選択状態を視覚的に区別、アクセシビリティ準拠
/// 【UI設計】:
/// - 最小タップサイズ44px × 44px（アクセシビリティ要件）
/// - 選択中: プライマリカラーの背景、白テキスト
/// - 非選択: 白背景、プライマリカラーのボーダー
/// 【アクセシビリティ】: Semanticsによるスクリーンリーダー対応
/// 🔵 信頼性レベル: 高（アクセシビリティ要件準拠）
class _SpeedButton extends StatelessWidget {
  /// 速度選択ボタンを作成する。
  const _SpeedButton({
    required this.label,
    required this.speed,
    required this.isSelected,
    required this.onTap,
  });

  /// ボタンのラベル（「とても遅い」「遅い」「普通」「速い」）
  final String label;

  /// 対応するTTS速度
  final TTSSpeed speed;

  /// 選択中かどうか
  final bool isSelected;

  /// タップ時のコールバック
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 【カラースキーム取得】: テーマから色を取得
    final colorScheme = Theme.of(context).colorScheme;

    // 【アクセシビリティ強化】: Semanticsでスクリーンリーダー対応
    // 🔵 信頼性レベル: 高（アクセシビリティ要件に基づく改善）
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label読み上げ速度${isSelected ? "（選択中）" : ""}',
      child: InkWell(
        onTap: onTap,
        // 【最小タップサイズ】: 44px × 44px（アクセシビリティ要件）
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 60,
            minHeight: 44,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            // 【背景色】: 選択中はプライマリカラー、非選択はサーフェス色
            // 【AA対応】: ハードコードのColors.whiteを廃止し、テーマトークンを使用。
            // 全テーマ（ライト/ダーク/高コントラスト）でコントラストを確保する。
            color: isSelected ? colorScheme.primary : colorScheme.surface,
            // 【ボーダー】: プライマリカラーのボーダー
            border: Border.all(
              color: colorScheme.primary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                // 【テキスト色】: 選択中はonPrimary、非選択はプライマリカラー
                // 【AA対応】: onPrimaryトークンで背景に対し適切なコントラストを確保。
                color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
