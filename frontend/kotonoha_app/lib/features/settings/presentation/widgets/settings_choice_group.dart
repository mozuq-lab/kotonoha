/// 設定の選択肢（文字の大きさ・テーマ・読み上げ速度・丁寧さ）を同じ見た目で並べる。
library;

import 'package:flutter/material.dart';

/// 項目名と、その下に並ぶ選択肢。
/// 選択肢は名前の幅で並び、収まらなければ次の行へ送る。等分の分割ボタンだと
/// 電話の幅で「高コントラスト」「とても遅い」が語の途中で折り返す。
/// 選択中は色に加えて ✓ と太字でも示す。
class SettingsChoiceGroup<T> extends StatelessWidget {
  /// 選択肢の並びを作る。
  const SettingsChoiceGroup({
    super.key,
    required this.title,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onSelected,
  });

  /// 項目名（例: 「テーマ」）
  final String title;

  /// 選択肢（並べる順）
  final List<T> values;

  /// 選択肢の表示名
  final String Function(T value) labelOf;

  /// いま選ばれている値
  final T selected;

  /// 選ばれたときに呼ぶ
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((value) {
            final isSelected = value == selected;
            return ChoiceChip(
              label: Text(labelOf(value)),
              selected: isSelected,
              shape: const StadiumBorder(),
              side: BorderSide(color: scheme.outline),
              backgroundColor: scheme.surface,
              selectedColor: scheme.secondaryContainer,
              checkmarkColor: scheme.onSecondaryContainer,
              labelStyle: TextStyle(
                color:
                    isSelected ? scheme.onSecondaryContainer : scheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
              // 見た目の高さも 44px 以上にする（タップ領域は padded で 48px 四方）
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (_) => onSelected(value),
            );
          }).toList(),
        ),
      ],
    );
  }
}
