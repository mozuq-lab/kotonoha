/// 丁寧さレベル選択ウィジェット
///
/// TASK-0068: AI変換UIウィジェット実装
///
/// 【機能概要】: 3段階の丁寧さレベル（カジュアル/普通/丁寧）を選択するUI
/// 【実装方針】: セグメントボタン形式で視覚的に選択状態を表示
/// 【テスト対応】: TC-068-002, TC-068-003, TC-068-014
/// 🔵 信頼性レベル: 青信号 - REQ-903に基づく
library;

import 'package:flutter/material.dart';
import '../../domain/models/politeness_level.dart';

/// 【ウィジェット定義】: 丁寧さレベル選択セレクター
///
/// REQ-903: 丁寧さレベルを3段階から選択可能
/// 🔵 信頼性レベル: 青信号
class PolitenessLevelSelector extends StatelessWidget {
  /// 【コンストラクタ】: PolitenessLevelSelector
  /// 【パラメータ】: 選択中のレベル、レベル変更コールバック
  /// 🔵 信頼性レベル: 青信号
  const PolitenessLevelSelector({
    super.key,
    required this.selectedLevel,
    required this.onLevelChanged,
  });

  /// 【プロパティ定義】: 現在選択されている丁寧さレベル
  /// 🔵 信頼性レベル: 青信号
  final PolitenessLevel selectedLevel;

  /// 【プロパティ定義】: レベル変更時のコールバック
  /// 🔵 信頼性レベル: 青信号
  final void Function(PolitenessLevel) onLevelChanged;

  @override
  Widget build(BuildContext context) {
    // 【UI構築】: 3つの丁寧さレベルボタンを横並びで表示
    // 【実装内容】: 各レベルをElevatedButtonで表示し、選択状態で色を変える
    // 🔵 信頼性レベル: 青信号 - REQ-903
    // 【レイアウト修正】: Rowではなくalignment:centerのWrapを使う。
    // home_screen.dartのWrap内でこのウィジェットが常に全幅を占有すると、
    // AI変換ボタンが必ず2段目に折り返される（タブレット・横持ちスマホでも
    // 不要な折り返しが発生する）ため、幅に余裕がある場合は1行に収める。
    // さらにWrapにすることで、コンパクト2ペインレイアウトの狭い左ペインの
    // ように3ボタン分の幅を確保できない場合でも、RenderFlexオーバーフロー
    // を起こさずタップ操作のみで完結する形で2行以上に折り返す。
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: PolitenessLevel.values.map((level) {
        // 【選択状態判定】: 現在のレベルが選択されているかどうか
        final isSelected = level == selectedLevel;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Semantics(
            // 【アクセシビリティ】: スクリーンリーダー用ラベル
            // 🟡 信頼性レベル: 黄信号 - REQ-5001から推測
            label: '${level.displayName}${isSelected ? "、選択中" : ""}',
            button: true,
            selected: isSelected,
            child: ElevatedButton(
              // 【スタイル設定】: 選択状態で背景色を変える
              // 🔵 信頼性レベル: 青信号 - REQ-903
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                foregroundColor: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                // 【アクセシビリティ対応】: 最小タップターゲットサイズ44px
                // 🟡 信頼性レベル: 黄信号 - REQ-5001から推測
                minimumSize: const Size(80, 44),
              ),
              // 【タップ処理】: レベル変更コールバックを呼び出す
              onPressed: () => onLevelChanged(level),
              child: Text(level.displayName),
            ),
          ),
        );
      }).toList(),
    );
  }
}
