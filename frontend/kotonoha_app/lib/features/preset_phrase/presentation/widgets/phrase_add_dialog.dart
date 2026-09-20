/// PhraseAddDialog - 定型文追加ダイアログ
/// 定型文追加ダイアログを提供
/// 内容とカテゴリを入力できるフォーム
/// 500文字制限
/// 空入力拒否
/// タップターゲット44px以上
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/phrase_constants.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/preset_phrase_validator.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_form_content.dart';
import 'package:kotonoha_app/shared/widgets/confirmation_dialog.dart';

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
    // 並びは `ConfirmationDialog` と同じものを使う（台帳 L-130）。
    // 本文がフォーム（文字数カウンタ・カテゴリ選択・エラー表示）なので
    // `ConfirmationDialog`（本文は String）には入らないが、**「キャンセル」と
    // 「保存」が接すると、打った文がそのまま消える**のは同じ。
    // 指定が無いと `AlertDialog` の既定のままで、幅 320・倍率 1.3 で 0.0px に
    // なる（2026-09-20 実測）。
    //
    // なお `ConfirmKind.destructive` が置いている「取り消せない実行だけを塗って
    // 見分けられるようにする」という決定は、**この 2 つには当てはまらない**。
    // **取り消せないのは「キャンセル」側**で、押すと
    // 打った文がそのまま消える。
    // だから「保存」は塗らない（台帳 L-137）。
    return ConfirmationDialogLayout.build(
      title: const Text('定型文を追加'),
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
