/// チュートリアルオーバーレイウィジェット
///
/// TASK-0075: ヘルプ画面・初回チュートリアル実装
///
/// 信頼性レベル: 🟡 黄信号（REQ-3001から推測）
/// 関連要件:
/// - REQ-3001: 初回起動時の簡易チュートリアル表示
library;

import 'package:flutter/material.dart';

/// チュートリアルステップデータ
class _TutorialStep {
  /// タイトル
  final String title;

  /// 説明
  final String description;

  /// アイコン
  final IconData icon;

  const _TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// チュートリアルステップ定義
const _tutorialSteps = [
  _TutorialStep(
    title: 'ようこそ、ことのはへ',
    description: 'このアプリは、文字盤を使ってコミュニケーションをサポートするアプリです。\n'
        '基本的な使い方をご説明します。',
    icon: Icons.waving_hand,
  ),
  _TutorialStep(
    title: '文字盤で入力',
    description: '五十音の文字盤をタップして文字を入力します。\n'
        '入力した文字は画面上部に表示されます。',
    icon: Icons.grid_view,
  ),
  _TutorialStep(
    title: '定型文を使う',
    description: 'よく使う言葉は定型文として登録できます。\n'
        'タップするだけですばやく入力できます。',
    icon: Icons.format_quote,
  ),
  _TutorialStep(
    title: '読み上げ機能',
    description: '入力したテキストを音声で読み上げます。\n'
        '話し相手にメッセージを伝えられます。',
    icon: Icons.volume_up,
  ),
  _TutorialStep(
    title: '準備完了',
    description: 'これで基本的な使い方はおしまいです。\n'
        '詳しい使い方は「設定」→「使い方」から確認できます。',
    icon: Icons.check_circle,
  ),
];

/// チュートリアルオーバーレイウィジェット
///
/// 初回起動時に表示されるチュートリアルオーバーレイ。
/// ステップごとに基本的な使い方を説明する。
///
/// [child] オーバーレイの背後に表示されるメインコンテンツ
/// [onComplete] チュートリアル完了時のコールバック
class TutorialOverlay extends StatefulWidget {
  /// オーバーレイの背後に表示されるメインコンテンツ
  final Widget child;

  /// チュートリアル完了時のコールバック
  final VoidCallback onComplete;

  /// コンストラクタ
  const TutorialOverlay({
    super.key,
    required this.child,
    required this.onComplete,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  /// 現在のステップ
  int _currentStep = 0;

  /// 次のステップへ進む
  void _nextStep() {
    if (_currentStep < _tutorialSteps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _complete();
    }
  }

  /// チュートリアルを完了
  void _complete() {
    widget.onComplete();
  }

  /// チュートリアルをスキップ
  void _skip() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = _tutorialSteps[_currentStep];
    final isLastStep = _currentStep == _tutorialSteps.length - 1;

    return Stack(
      children: [
        // メインコンテンツ（背景）
        widget.child,

        // オーバーレイ
        Container(
          color: Colors.black54,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // アイコン
                        Icon(
                          step.icon,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),

                        // タイトル
                        Text(
                          step.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // 説明
                        Text(
                          step.description,
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // ステップインジケーター
                        TutorialStepIndicator(
                          totalSteps: _tutorialSteps.length,
                          currentStep: _currentStep,
                        ),
                        const SizedBox(height: 24),

                        // ボタン
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // スキップボタン
                            if (!isLastStep) ...[
                              TextButton(
                                onPressed: _skip,
                                child: const Text('スキップ'),
                              ),
                              const SizedBox(width: 16),
                            ],

                            // 次へ/はじめるボタン
                            FilledButton(
                              onPressed: _nextStep,
                              child: Text(isLastStep ? 'はじめる' : '次へ'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// チュートリアルステップインジケーター
///
/// 現在のステップをドットで表示する。
class TutorialStepIndicator extends StatelessWidget {
  /// 総ステップ数
  final int totalSteps;

  /// 現在のステップ
  final int currentStep;

  /// コンストラクタ
  const TutorialStepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        final isPast = index < currentStep;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Container(
            width: isActive ? 12 : 8,
            height: isActive ? 12 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive || isPast
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        );
      }),
    );
  }
}
