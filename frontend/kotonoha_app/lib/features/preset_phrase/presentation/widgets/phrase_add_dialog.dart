/// PhraseAddDialog - 定型文追加ダイアログ
/// 定型文追加ダイアログを提供
/// 内容とカテゴリを入力できるフォーム
/// 500文字制限
/// 空入力拒否
/// タップターゲット44px以上
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/phrase_constants.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/preset_phrase_validator.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_form_content.dart';

/// 機能概要: 定型文追加ダイアログ
/// 実装方針: AlertDialogベースでPhraseFormContentを使用
/// 新しい定型文を追加するためのダイアログ。
/// 内容入力、カテゴリ選択、保存・キャンセル機能を提供。
class PhraseAddDialog extends StatefulWidget {
  /// パラメータ定義: 保存時のコールバック
  final void Function(String content, String category)? onSave;

  /// PhraseAddDialogを作成する
  const PhraseAddDialog({
    super.key,
    this.onSave,
  });

  @override
  State<PhraseAddDialog> createState() => _PhraseAddDialogState();
}

class _PhraseAddDialogState extends State<PhraseAddDialog> {
  final _contentController = TextEditingController();
  String _selectedCategory = PhraseConstants.defaultCategory;
  String? _errorMessage;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// メソッド: 保存ボタン押下時の処理
  /// 実装内容: バリデーション実行後、コールバック発火
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

    widget.onSave?.call(_contentController.text, _selectedCategory);
    Navigator.of(context).pop();
  }

  /// メソッド: キャンセルボタン押下時の処理
  void _onCancel() {
    Navigator.of(context).pop();
  }

  /// メソッド: テキスト変更時の処理
  /// 実装内容: エラーメッセージをクリアしてUIを更新
  void _onTextChanged() {
    setState(() {
      _errorMessage = null;
    });
  }

  /// メソッド: カテゴリ変更時の処理
  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('定型文を追加'),
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
        TextButton(
          onPressed: _onCancel,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, AppSizes.minTapTarget),
          ),
          child: const Text('キャンセル'),
        ),
        // 保存ボタン: バリデーション後に保存
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
