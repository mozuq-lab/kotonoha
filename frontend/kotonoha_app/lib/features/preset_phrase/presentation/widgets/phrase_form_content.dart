/// PhraseFormContent - 定型文フォームコンテンツ
///
/// TASK-0041: 定型文CRUD機能実装
/// TDD Refactorフェーズ: 共通化
///
/// 追加・編集ダイアログで共通利用するフォーム部品。
/// テキスト入力、文字数カウンター、カテゴリ選択を提供。
///
/// 関連要件:
/// - CRUD-002: 内容とカテゴリを入力できるフォーム
/// - CRUD-104: 500文字制限
/// - CRUD-105: 空入力拒否
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/phrase_constants.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/preset_phrase_validator.dart';

/// 【機能概要】: 定型文フォームコンテンツ
/// 【実装方針】: 追加・編集ダイアログで共通利用するStatelessWidget
/// 🔵 信頼性レベル: 青信号 - CRUD-002に基づく
///
/// テキスト入力フィールド、文字数カウンター、カテゴリ選択を
/// 一つのウィジェットにまとめて提供する。
class PhraseFormContent extends StatelessWidget {
  /// 【パラメータ定義】: テキストコントローラ
  /// 🔵 信頼性レベル: 青信号 - フォーム入力の基本要素
  final TextEditingController controller;

  /// 【パラメータ定義】: 選択中のカテゴリ
  /// 🔵 信頼性レベル: 青信号 - CRUD-002に基づく
  final String selectedCategory;

  /// 【パラメータ定義】: カテゴリ変更時のコールバック
  /// 🔵 信頼性レベル: 青信号 - CRUD-002に基づく
  final ValueChanged<String> onCategoryChanged;

  /// 【パラメータ定義】: エラーメッセージ（任意）
  /// 🔵 信頼性レベル: 青信号 - CRUD-105に基づく
  final String? errorMessage;

  /// 【パラメータ定義】: 入力変更時のコールバック（任意）
  /// 🔵 信頼性レベル: 青信号 - UI更新用
  final VoidCallback? onTextChanged;

  /// 【パラメータ定義】: 現在の文字数
  /// 🔵 信頼性レベル: 青信号 - CRUD-104に基づく
  final int currentLength;

  /// PhraseFormContentを作成する
  const PhraseFormContent({
    super.key,
    required this.controller,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.currentLength,
    this.errorMessage,
    this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAtLimit = currentLength >= PresetPhraseValidator.maxLength;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 【テキスト入力フィールド】: 定型文内容の入力
        // 🔵 信頼性レベル: 青信号 - CRUD-002に基づく
        TextField(
          controller: controller,
          maxLines: 4,
          maxLength: PresetPhraseValidator.maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          decoration: InputDecoration(
            hintText: '定型文を入力',
            errorText: errorMessage,
            border: const OutlineInputBorder(),
            counterText: '', // デフォルトカウンターを非表示
          ),
          onChanged: (_) => onTextChanged?.call(),
        ),
        const SizedBox(height: AppSizes.paddingSmall),

        // 【文字数カウンター】: 入力文字数表示
        // 🔵 信頼性レベル: 青信号 - CRUD-104に基づく
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$currentLength/${PresetPhraseValidator.maxLength}',
            style: TextStyle(
              color: isAtLimit ? Colors.red : theme.textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.paddingMedium),

        // 【カテゴリ選択】: カテゴリ選択UI
        // 🔵 信頼性レベル: 青信号 - CRUD-002に基づく
        const Text('カテゴリ'),
        const SizedBox(height: AppSizes.paddingSmall),
        Wrap(
          spacing: AppSizes.paddingSmall,
          children: PhraseConstants.categoryLabels.entries.map((entry) {
            final isSelected = selectedCategory == entry.key;
            return ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onCategoryChanged(entry.key);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
