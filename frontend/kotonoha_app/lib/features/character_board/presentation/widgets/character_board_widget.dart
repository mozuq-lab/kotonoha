/// 五十音文字盤ウィジェット
///
/// TASK-0037: 五十音文字盤UI実装
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
/// 関連要件: REQ-001, REQ-002, REQ-5001, NFR-003, NFR-202
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/character_board/domain/character_data.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// 五十音文字盤ウィジェット
///
/// 五十音配列の文字盤UIを表示し、ユーザーがタップした文字を
/// コールバック経由で返却する。
///
/// 実装要件:
/// - REQ-001: 五十音配列の文字盤UI表示
/// - REQ-002: タップで入力欄に文字追加
/// - REQ-5001: タップターゲット44px × 44px以上
/// - NFR-003: 100ms以内の応答
/// - NFR-202: 推奨60px × 60px以上
class CharacterBoardWidget extends StatefulWidget {
  /// 文字盤ウィジェットを作成する。
  ///
  /// [onCharacterTap] - 文字タップ時のコールバック（必須）
  /// [fontSize] - フォントサイズ設定（デフォルト: medium）
  /// [isEnabled] - 有効/無効状態（デフォルト: true）
  /// [initialCategory] - 初期表示カテゴリ（デフォルト: basic）
  const CharacterBoardWidget({
    super.key,
    required this.onCharacterTap,
    this.fontSize = FontSize.medium,
    this.isEnabled = true,
    this.initialCategory = CharacterCategory.basic,
  });

  /// 文字タップ時のコールバック
  final void Function(String character) onCharacterTap;

  /// フォントサイズ設定
  final FontSize fontSize;

  /// 有効/無効状態
  final bool isEnabled;

  /// 初期表示カテゴリ
  final CharacterCategory initialCategory;

  @override
  State<CharacterBoardWidget> createState() => _CharacterBoardWidgetState();
}

class _CharacterBoardWidgetState extends State<CharacterBoardWidget> {
  late CharacterCategory _currentCategory;

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final characters = CharacterData.getCharacters(_currentCategory);
    final buttonSize = AppSizes.characterBoardButtonSize;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // カテゴリタブ
        _buildCategoryTabs(context),
        const SizedBox(height: AppSizes.paddingSmall),
        // 文字グリッド
        Expanded(
          child: _buildCharacterGrid(context, characters, buttonSize),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: CharacterCategory.values.map((category) {
          final isSelected = category == _currentCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingXSmall,
            ),
            child: ChoiceChip(
              label: Text(category.displayName),
              selected: isSelected,
              onSelected: widget.isEnabled
                  ? (selected) {
                      if (selected) {
                        setState(() {
                          _currentCategory = category;
                        });
                      }
                    }
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCharacterGrid(
    BuildContext context,
    List<String> characters,
    double buttonSize,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 横幅に応じて列数を計算（最低5列）
        final spacing = AppSizes.characterBoardButtonSpacing;
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        final columnsCount = (availableWidth / (buttonSize + spacing)).floor();
        final columns = columnsCount.clamp(5, 10);

        // 【fit-to-height対応】: 列数だけでなく行数・可視高さも考慮してセルの
        // 高さを決定する。スマホ縦持ちのように高さが乏しい画面では、幅基準の
        // 正方形セル（childAspectRatio: 1.0固定）だと1画面に収まらず大量の
        // スクロールが発生するため、「幅基準セル」と「高さ基準セル」のうち
        // 小さい方を採用してセルを縦に押し縮める。
        // ただし44px未満には縮めない（アクセシビリティ: タップターゲット下限）。
        // 44pxでも収まらない場合はGridView標準のスクロールに委ねる。
        const gridPadding = AppSizes.paddingSmall;
        final rows =
            characters.isEmpty ? 0 : (characters.length / columns).ceil();

        final contentWidth = availableWidth - gridPadding * 2;
        final widthBasedCellSize = columns > 0
            ? (contentWidth - spacing * (columns - 1)) / columns
            : buttonSize;

        double heightBasedCellSize = widthBasedCellSize;
        if (rows > 0 && availableHeight.isFinite) {
          final contentHeight = availableHeight - gridPadding * 2;
          heightBasedCellSize = (contentHeight - spacing * (rows - 1)) / rows;
        }

        final smallerCellSize = widthBasedCellSize < heightBasedCellSize
            ? widthBasedCellSize
            : heightBasedCellSize;
        final effectiveCellHeight = smallerCellSize < AppSizes.minTapTarget
            ? AppSizes.minTapTarget
            : smallerCellSize;

        final childAspectRatio =
            (widthBasedCellSize > 0 && effectiveCellHeight > 0)
                ? widthBasedCellSize / effectiveCellHeight
                : 1.0;

        return GridView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingSmall),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: characters.length,
          itemBuilder: (context, index) {
            final character = characters[index];
            if (character.isEmpty) {
              // 空のスペーサー（constで最適化）
              return const SizedBox.shrink();
            }
            // RepaintBoundaryで個別ボタンの再描画範囲を限定
            // タップ時に該当ボタンのみ再描画し、他のボタンへの影響を最小化
            // TASK-0089: 文字盤UI最適化 (REQ-OPT-002)
            return RepaintBoundary(
              child: CharacterButton(
                key: ValueKey('character_button_$character'),
                character: character,
                onTap: widget.isEnabled
                    ? () => widget.onCharacterTap(character)
                    : null,
                size: buttonSize,
                isEnabled: widget.isEnabled,
                fontSize: widget.fontSize,
              ),
            );
          },
        );
      },
    );
  }
}

/// 文字ボタンウィジェット
///
/// 個々の文字を表示するボタン。タップ時にコールバックを呼び出す。
///
/// 実装要件:
/// - REQ-5001: タップターゲット44px × 44px以上
/// - NFR-202: 推奨60px × 60px以上
class CharacterButton extends StatelessWidget {
  /// 文字ボタンを作成する。
  ///
  /// [character] - 表示する文字
  /// [onTap] - タップ時のコールバック
  /// [size] - ボタンサイズ（デフォルト: 60.0）
  /// [isEnabled] - 有効/無効状態（デフォルト: true）
  /// [fontSize] - フォントサイズ設定（デフォルト: medium）
  const CharacterButton({
    super.key,
    required this.character,
    required this.onTap,
    this.size = 60.0,
    this.isEnabled = true,
    this.fontSize = FontSize.medium,
  });

  /// 表示する文字
  final String character;

  /// タップ時のコールバック
  final VoidCallback? onTap;

  /// ボタンサイズ
  final double size;

  /// 有効/無効状態
  final bool isEnabled;

  /// フォントサイズ設定
  final FontSize fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textSize = _getTextSize();
    // BorderRadiusを共通化してインスタンス生成を削減
    const borderRadius = BorderRadius.all(
      Radius.circular(AppSizes.borderRadiusMedium),
    );

    return Semantics(
      label: character,
      button: true,
      enabled: isEnabled,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: isEnabled
              ? theme.colorScheme.surface
              : theme.colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: borderRadius,
          elevation: isEnabled ? AppSizes.elevationSmall : 0,
          child: InkWell(
            onTap: isEnabled ? onTap : null,
            borderRadius: borderRadius,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isEnabled
                      ? theme.colorScheme.outline
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                borderRadius: borderRadius,
              ),
              alignment: Alignment.center,
              child: Text(
                character,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: textSize,
                  color: isEnabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _getTextSize() {
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
