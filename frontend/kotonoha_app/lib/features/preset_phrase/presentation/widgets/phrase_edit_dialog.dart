/// PhraseEditDialog - 定型文編集ダイアログ
///
/// TASK-0041: 定型文CRUD機能実装
/// TDD Refactorフェーズ: 共通化適用
///
/// 関連要件:
/// - CRUD-004: 定型文編集ダイアログを提供
/// - CRUD-005: 現在の内容とカテゴリを初期表示
/// - CRUD-008: updatedAtタイムスタンプを自動設定
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/preset_phrase_validator.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_form_content.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

/// 機能概要: 定型文編集ダイアログ
/// 実装方針: AlertDialogベースでPhraseFormContentを使用、初期値設定
/// テスト対応: TC-041-022〜TC-041-027
/// 信頼性レベル: 青信号 - CRUD-004, CRUD-005に基づく
///
/// 既存の定型文を編集するためのダイアログ。
/// 現在の内容とカテゴリを初期値として表示し、編集・保存機能を提供。
class PhraseEditDialog extends StatefulWidget {
  /// パラメータ定義: 編集対象の定型文
  /// 信頼性レベル: 青信号 - CRUD-005に基づく
  final PresetPhrase phrase;

  /// パラメータ定義: 保存時のコールバック
  /// 信頼性レベル: 青信号 - UC-002に基づく
  final void Function(PresetPhrase updatedPhrase)? onSave;

  /// PhraseEditDialogを作成する
  const PhraseEditDialog({
    super.key,
    required this.phrase,
    this.onSave,
  });

  @override
  State<PhraseEditDialog> createState() => _PhraseEditDialogState();
}

class _PhraseEditDialogState extends State<PhraseEditDialog> {
  late TextEditingController _contentController;
  late String _selectedCategory;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 初期化: 編集対象の定型文から初期値を設定 (CRUD-005)
    _contentController = TextEditingController(text: widget.phrase.content);
    _selectedCategory = widget.phrase.category;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// メソッド: 保存ボタン押下時の処理
  /// 実装内容: バリデーション実行後、更新済み定型文でコールバック発火
  /// 信頼性レベル: 青信号 - CRUD-008に基づく
  void _onSave() {
    final validationError = PresetPhraseValidator.validateContent(
      _contentController.text,
    );

    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    // 更新処理: updatedAt自動更新 (CRUD-008)
    final updatedPhrase = widget.phrase.copyWith(
      content: _contentController.text,
      category: _selectedCategory,
      updatedAt: DateTime.now(),
    );

    widget.onSave?.call(updatedPhrase);
    Navigator.of(context).pop();
  }

  /// メソッド: キャンセルボタン押下時の処理
  /// 信頼性レベル: 青信号 - UI操作
  void _onCancel() {
    Navigator.of(context).pop();
  }

  /// メソッド: テキスト変更時の処理
  /// 実装内容: エラーメッセージをクリアしてUIを更新
  /// 信頼性レベル: 青信号 - UI更新
  void _onTextChanged() {
    setState(() {
      _errorMessage = null;
    });
  }

  /// メソッド: カテゴリ変更時の処理
  /// 信頼性レベル: 青信号 - CRUD-002に基づく
  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('定型文を編集'),
      content: SingleChildScrollView(
        child: PhraseFormContent(
          controller: _contentController,
          selectedCategory: _selectedCategory,
          onCategoryChanged: _onCategoryChanged,
          currentLength: _contentController.text.length,
          errorMessage: _errorMessage,
          onTextChanged: _onTextChanged,
        ),
      ),
      actions: [
        // キャンセルボタン: ダイアログを閉じる
        // 信頼性レベル: 青信号 - CRUD-203に基づくタップターゲットサイズ
        TextButton(
          onPressed: _onCancel,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, AppSizes.minTapTarget),
          ),
          child: const Text('キャンセル'),
        ),
        // 保存ボタン: バリデーション後に保存
        // 信頼性レベル: 青信号 - CRUD-203に基づくタップターゲットサイズ
        ElevatedButton(
          onPressed: _onSave,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, AppSizes.minTapTarget),
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }
}
