/// PhraseEditDialog - 定型文編集ダイアログ
/// 定型文編集ダイアログを提供
/// 現在の内容とカテゴリを初期表示
/// updatedAtタイムスタンプを自動設定
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/persistence/programming_error_report.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/phrase_constants.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/phrase_update_result.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/preset_phrase_validator.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_form_content.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/widgets/confirmation_dialog.dart';
import 'package:kotonoha_app/shared/widgets/discard_input_guard.dart';

/// 機能概要: 定型文編集ダイアログ
/// 実装方針: AlertDialogベースでPhraseFormContentを使用、初期値設定
/// 既存の定型文を編集するためのダイアログ。
/// 現在の内容とカテゴリを初期値として表示し、編集・保存機能を提供。
class PhraseEditDialog extends StatefulWidget {
  /// パラメータ定義: 編集対象の定型文
  final PresetPhrase phrase;

  /// パラメータ定義: 保存時のコールバック
  final Future<PhraseUpdateResult> Function(PresetPhrase updatedPhrase)? onSave;

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
  bool _saving = false;

  /// 元の定型文から本文もカテゴリも変えていないか。変えていれば、戻る操作で
  /// 黙って捨てない（L-136）。
  bool get _untouched =>
      _contentController.text == widget.phrase.content &&
      _selectedCategory == widget.phrase.category;

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
    var result = PhraseUpdateResult.failed;
    try {
      // 更新処理: updatedAt自動更新
      final pending = widget.onSave?.call(widget.phrase.copyWith(
        content: _contentController.text,
        category: _selectedCategory,
        updatedAt: DateTime.now(),
      ));
      // 書込が返らなくても凍結したままにしない（L-197）。上限を過ぎたら失敗と同じに扱う
      if (pending != null) {
        result = await pending.timeout(PhraseConstants.saveTimeout);
      }
    } catch (e, s) {
      // 入力を残し、同じ場所で再試行できるようにする。catchは狭めない
      // （`_saving` が戻らなくなる方が悪い）。Errorだけログへ流す。
      reportProgrammingError(e, s);
    }
    if (!mounted) return;
    if (result == PhraseUpdateResult.saved) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      // 元の定型文が消えていても、追加には変えない（消えた定型文を元のIDで
      // 復活させない）。入力は残すので、利用者がコピーして追加し直せる。
      _errorMessage = result == PhraseUpdateResult.missing
          ? '元の定型文が見つかりません。入力内容は残っています。'
          : '保存を確認できませんでした。入力内容を残しています。';
    });
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
    // **編集ではキャンセルも保存も取り消せない**。「キャンセル」を誤って押すと
    // 打ち直した内容が消え、「保存」を誤って押すと元の文言が戻せない。
    // だから「保存」は塗らない（台帳 L-137）。
    // 端末の戻るボタンは `barrierDismissible: false` では塞げない。
    // 入力があるうちは、閉じる前に確認する（台帳 L-136）。
    // 元の文言から変わっているかどうか。変えていなければ捨てるものが無い
    // 保存の待機中は凍結する（台帳 L-177。追加フォームと同じ）。
    final frozen = _saving;
    final dialog = ConfirmationDialogLayout.build(
      title: const Text('定型文を編集'),
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
      hasInput: !_untouched,
      onDiscard: _onCancel,
      child: ExcludeFocus(
          excluding: _saving,
          child: AbsorbPointer(absorbing: _saving, child: dialog)),
    );
  }
}
