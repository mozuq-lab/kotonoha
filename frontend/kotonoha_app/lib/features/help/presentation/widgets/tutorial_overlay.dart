/// チュートリアルオーバーレイウィジェット
///
/// TASK-0075: ヘルプ画面・初回チュートリアル実装
///
/// 信頼性レベル: 🟡 黄信号（REQ-3001から推測）
/// 関連要件:
/// - REQ-3001: 初回起動時の簡易チュートリアル表示
library;

import 'package:flutter/material.dart';

import 'package:kotonoha_app/core/constants/app_sizes.dart';

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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 【高さ適応レイアウト】: 横持ちスマホ（例: 844×390）や分割画面など
                  // 可視高さが低い環境でカードがビューポートを超えてオーバーフローしない
                  // よう、可視高さに応じてアイコン・余白を縮小し、本文はスクロール可能にする。
                  // Next/Skipボタンとステップインジケーターは常にスクロール領域外の
                  // 固定位置に置き、タップ不能にならないようにする。
                  // 🟡 信頼性レベル: 黄信号 - Codexレビュー指摘（P2）に基づく
                  final availableHeight = constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : MediaQuery.sizeOf(context).height;
                  final isCompactHeight =
                      availableHeight < AppSizes.compactHeightThreshold;

                  final outerPadding = isCompactHeight
                      ? AppSizes.paddingSmall
                      : AppSizes.paddingLarge;
                  final innerPadding = isCompactHeight
                      ? AppSizes.paddingMedium
                      : AppSizes.paddingLarge;
                  final iconSize = isCompactHeight ? 36.0 : 64.0;
                  final smallGap = isCompactHeight
                      ? AppSizes.paddingXSmall
                      : AppSizes.paddingMedium;
                  final largeGap = isCompactHeight
                      ? AppSizes.paddingSmall
                      : AppSizes.paddingLarge;

                  return Padding(
                    padding: EdgeInsets.all(outerPadding),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: availableHeight * 0.8,
                      ),
                      child: Card(
                        elevation: 8,
                        child: Padding(
                          padding: EdgeInsets.all(innerPadding),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // スクロール可能な本文（アイコン・タイトル・説明）
                              Flexible(
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // アイコン
                                      Icon(
                                        step.icon,
                                        size: iconSize,
                                        color: theme.colorScheme.primary,
                                      ),
                                      SizedBox(height: smallGap),

                                      // タイトル
                                      Text(
                                        step.title,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: smallGap),

                                      // 説明
                                      Text(
                                        step.description,
                                        style: theme.textTheme.bodyLarge,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: largeGap),

                              // ステップインジケーター（常に可視・固定位置）
                              TutorialStepIndicator(
                                totalSteps: _tutorialSteps.length,
                                currentStep: _currentStep,
                              ),
                              SizedBox(height: largeGap),

                              // ボタン（常に可視・固定位置）
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // スキップボタン
                                  if (!isLastStep) ...[
                                    TextButton(
                                      onPressed: _skip,
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(
                                          AppSizes.minTapTarget,
                                          AppSizes.minTapTarget,
                                        ),
                                      ),
                                      child: const Text('スキップ'),
                                    ),
                                    SizedBox(width: smallGap),
                                  ],

                                  // 次へ/はじめるボタン
                                  FilledButton(
                                    onPressed: _nextStep,
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(
                                        AppSizes.minTapTarget,
                                        AppSizes.minTapTarget,
                                      ),
                                    ),
                                    child: Text(isLastStep ? 'はじめる' : '次へ'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
