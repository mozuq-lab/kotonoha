/// PhraseAddDialog - 定型文追加ダイアログ
/// 定型文追加ダイアログを提供
/// 内容とカテゴリを入力できるフォーム
/// 500文字制限
/// 空入力拒否
/// タップターゲット44px以上
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/persistence/programming_error_report.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/phrase_constants.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/preset_phrase_validator.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_form_content.dart';
import 'package:kotonoha_app/shared/widgets/confirmation_dialog.dart';
import 'package:kotonoha_app/shared/widgets/discard_input_guard.dart';

/// 機能概要: 定型文追加ダイアログ
/// 実装方針: AlertDialogベースでPhraseFormContentを使用
/// 新しい定型文を追加するためのダイアログ。
/// 内容入力、カテゴリ選択、保存・キャンセル機能を提供。
class PhraseAddDialog extends StatefulWidget {
  /// パラメータ定義: 保存時のコールバック
  final Future<bool> Function(String content, String category)? onSave;

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
  bool _saving = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// メソッド: 保存ボタン押下時の処理
  /// 実装内容: バリデーション実行後、コールバック発火
  Future<void> _onSave() async {
    if (_saving) return;
    final validationError = PresetPhraseValidator.validateContent(
      _contentController.text,
    );

    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    setState(() => _saving = true);
    var succeeded = false;
    try {
      succeeded = await widget.onSave
              ?.call(_contentController.text, _selectedCategory) ??
          false;
    } catch (e, s) {
      // 入力を残し、同じ場所で再試行できるようにする。catchは狭めない
      // （`_saving` が戻らなくなる方が悪い）。Errorだけログへ流す。
      reportProgrammingError(e, s);
    }
    if (!mounted) return;
    if (succeeded) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _errorMessage = '保存を確認できませんでした。入力内容を残しています。';
      });
    }
  }

  /// メソッド: キャンセルボタン押下時の処理
  void _onCancel() {
    if (_saving) return;
    Navigator.of(context).pop();
  }

  /// メソッド: テキスト変更時の処理
  /// 実装内容: エラーメッセージをクリアしてUIを更新
  void _onTextChanged() {
    if (_saving) return;
    setState(() => _errorMessage = null);
  }

  /// メソッド: カテゴリ変更時の処理
  void _onCategoryChanged(String category) {
    if (_saving) return;
    setState(() {
      _selectedCategory = category;
      _errorMessage = null;
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
    // 端末の戻るボタンは `barrierDismissible: false` では塞げない。
    // 入力があるうちは、閉じる前に確認する（台帳 L-136）。
    // 新しく打った文があるかどうか。空なら捨てるものが無い
    // 保存の待機中は凍結する（L-177。失敗で解けても焦点は戻らない＝受け入れ済み）。
    final frozen = _saving;
    final dialog = ConfirmationDialogLayout.build(
      title: const Text('定型文を追加'),
      // 自前の `SingleChildScrollView` は持たない。
      // `ConfirmationDialogLayout.build` が `scrollable: true` を渡すので、
      // `AlertDialog` が title と content をスクロールに入れる。重ねると
      // 内側は無限高さ制約で `maxScrollExtent = 0` になり、ドラッグを取らない
      // 死んだ仕組みになる（ADR-008。台帳 L-138）
      content: ExcludeFocus(
          excluding: frozen,
          child: AbsorbPointer(
              absorbing: frozen,
              child: PhraseFormContent(
                controller: _contentController,
                selectedCategory: _selectedCategory,
                onCategoryChanged: _onCategoryChanged,
                currentLength: _contentController.text.length,
                errorMessage: _errorMessage,
                onTextChanged: _onTextChanged,
                // 支援技術のfocusまで止めるのは`TextField`自身にしかできない。
                frozen: frozen,
              ))),
      actions: [
        // キャンセルボタン: ダイアログを閉じる
        TextButton(
          onPressed: _saving ? null : _onCancel,
          child: const Text('キャンセル'),
        ),
        // 保存ボタン: バリデーション後に保存
        ElevatedButton(
          onPressed: _saving ? null : _onSave,
          child: const Text('保存'),
        ),
      ],
    );
    // 待機中も包みの型は替えない（替えると子孫の State が作り直される）。
    return DiscardInputGuard(
      busy: _saving,
      hasInput: _contentController.text.trim().isNotEmpty,
      onDiscard: _onCancel,
      child: ExcludeFocus(
          excluding: _saving,
          child: AbsorbPointer(absorbing: _saving, child: dialog)),
    );
  }
}
