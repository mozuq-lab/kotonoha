/// PhraseEditDialog - 定型文編集ダイアログ
/// 定型文編集ダイアログを提供
/// 現在の内容とカテゴリを初期表示
/// updatedAtタイムスタンプを自動設定
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/preset_phrase_validator.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_form_content.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

/// 機能概要: 定型文編集ダイアログ
/// 実装方針: AlertDialogベースでPhraseFormContentを使用、初期値設定
/// 既存の定型文を編集するためのダイアログ。
/// 現在の内容とカテゴリを初期値として表示し、編集・保存機能を提供。
class PhraseEditDialog extends StatefulWidget {
  /// パラメータ定義: 編集対象の定型文
  final PresetPhrase phrase;

  /// パラメータ定義: 保存時のコールバック
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
    // 初期化: 編集対象の定型文から初期値を設定
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

    // 更新処理: updatedAt自動更新
    final updatedPhrase = widget.phrase.copyWith(
      content: _contentController.text,
      category: _selectedCategory,
      updatedAt: DateTime.now(),
    );

    widget.onSave?.call(updatedPhrase);
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
