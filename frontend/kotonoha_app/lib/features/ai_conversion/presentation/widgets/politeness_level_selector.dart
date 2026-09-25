/// 丁寧さレベル選択ウィジェット
/// 機能概要: 3段階の丁寧さレベル（カジュアル/普通/丁寧）を選択するUI
/// 実装方針: セグメントボタン形式で視覚的に選択状態を表示
library;

import 'package:flutter/material.dart';
import '../../domain/models/politeness_level.dart';

/// ウィジェット定義: 丁寧さレベル選択セレクター
/// 丁寧さレベルを3段階から選択可能
class PolitenessLevelSelector extends StatelessWidget {
  /// コンストラクタ: PolitenessLevelSelector
  /// パラメータ: 選択中のレベル、レベル変更コールバック
  const PolitenessLevelSelector({
    super.key,
    required this.selectedLevel,
    required this.onLevelChanged,
    this.enabled = true,
  });

  /// プロパティ定義: 現在選択されている丁寧さレベル
  final PolitenessLevel selectedLevel;

  /// プロパティ定義: レベル変更時のコールバック
  final void Function(PolitenessLevel) onLevelChanged;

  /// 選べるか（変換し直している間は false）
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // UI構築: 3つの丁寧さレベルを等幅の1行に並べる。
    // AI変換の結果画面（幅300〜400px）に置くため、固定幅にせず
    // 与えられた幅を3等分する。
    return Row(
      children: PolitenessLevel.values.map((level) {
        // 選択状態判定: 現在のレベルが選択されているかどうか
        final isSelected = level == selectedLevel;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Semantics(
              // アクセシビリティ: スクリーンリーダー用ラベル
              label: '${level.displayName}${isSelected ? "、選択中" : ""}',
              button: true,
              selected: isSelected,
              child: ElevatedButton(
                // スタイル設定: 選択状態で背景色を変える
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? Color.lerp(
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.primary,
                          0.18,
                        )
                      : Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  // アクセシビリティ対応: 最小タップターゲットサイズ44px
                  minimumSize: const Size.fromHeight(44),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                // タップ処理: レベル変更コールバックを呼び出す
                onPressed: enabled ? () => onLevelChanged(level) : null,
                // 3等分の幅に収まらない長さ（「カジュアル」など）は
                // 折り返さずに縮めて1行に保つ。
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    level.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      decoration: isSelected ? TextDecoration.underline : null,
                      decorationThickness: isSelected ? 2.5 : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
