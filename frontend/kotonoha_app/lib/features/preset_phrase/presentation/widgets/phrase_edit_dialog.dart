/// PhraseEditDialog - 定型文編集ダイアログ
/// 定型文編集ダイアログを提供
/// 現在の内容とカテゴリを初期表示
/// updatedAtタイムスタンプを自動設定
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/preset_phrase_validator.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_form_content.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/widgets/confirmation_dialog.dart';

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
    // 並びは `ConfirmationDialog` と同じものを使う（台帳 L-130）。
    // 本文がフォーム（文字数カウンタ・カテゴリ選択・エラー表示）なので
    // `ConfirmationDialog`（本文は String）には入らないが、**「キャンセル」と
    // 「保存」が接すると、打った文がそのまま消える**のは同じ。
    // 指定が無いと `AlertDialog` の既定のままで、幅 320・倍率 1.3 で 0.0px に
    // なる（2026-09-20 実測）。
    //
    // なお `ConfirmKind.destructive` が置いている「取り消せない実行だけを塗って
    // 見分けられるようにする」という決定は、**この 2 つには当てはまらない**。
    // **編集ではキャンセルも保存も取り消せない**。「キャンセル」を誤って押すと
    // 打ち直した内容が消え、「保存」を誤って押すと元の文言が戻せない。
    // だから「保存」は塗らない（台帳 L-137）。
    return ConfirmationDialogLayout.build(
      title: const Text('定型文を編集'),
      // 自前の `SingleChildScrollView` は持たない。
      // `ConfirmationDialogLayout.build` が `scrollable: true` を渡すので、
      // `AlertDialog` が title と content をスクロールに入れる。重ねると
      // 内側は無限高さ制約で `maxScrollExtent = 0` になり、ドラッグを取らない
      // 死んだ仕組みになる（ADR-008。台帳 L-138）
      content: PhraseFormContent(
        controller: _contentController,
        selectedCategory: _selectedCategory,
        onCategoryChanged: _onCategoryChanged,
        currentLength: _contentController.text.length,
        errorMessage: _errorMessage,
        onTextChanged: _onTextChanged,
      ),
      actions: [
        // キャンセルボタン: ダイアログを閉じる
        TextButton(
          onPressed: _onCancel,
          child: const Text('キャンセル'),
        ),
        // 保存ボタン: バリデーション後に保存
        ElevatedButton(
          onPressed: _onSave,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
