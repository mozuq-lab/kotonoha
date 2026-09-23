/// PhraseEditDialog - 定型文編集ダイアログ
/// 定型文編集ダイアログを提供
/// 現在の内容とカテゴリを初期表示
/// updatedAtタイムスタンプを自動設定
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/persistence/programming_error_report.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/phrase_constants.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/phrase_update_result.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/preset_phrase_validator.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_form_content.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/phrase_draft_provider.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/widgets/confirmation_dialog.dart';
import 'package:kotonoha_app/shared/widgets/discard_input_guard.dart';

/// 機能概要: 定型文編集ダイアログ
/// 実装方針: AlertDialogベースでPhraseFormContentを使用、初期値設定
/// 既存の定型文を編集するためのダイアログ。
/// 現在の内容とカテゴリを初期値として表示し、編集・保存機能を提供。
/// 元の定型文が消えた下書き（孤立）は、読む・コピー・破棄だけを出す。
class PhraseEditDialog extends StatefulWidget {
  /// パラメータ定義: 編集対象の定型文（孤立下書きを開くときはnull）
  final PresetPhrase? phrase;

  /// パラメータ定義: 保存時のコールバック
  final Future<PhraseUpdateResult> Function(PresetPhrase updatedPhrase)? onSave;

  /// 下書きの保存先。nullなら下書きを使わない。
  final PhraseDrafts? drafts;

  /// 元の定型文が見つからない下書きの対象ID（[phrase] が無いとき）。
  final String? draftId;

  /// PhraseEditDialogを作成する
  const PhraseEditDialog({
    super.key,
    this.phrase,
    this.onSave,
    this.drafts,
    this.draftId,
  }) : assert(phrase != null || draftId != null);

  @override
  State<PhraseEditDialog> createState() => _PhraseEditDialogState();
}

class _PhraseEditDialogState extends State<PhraseEditDialog> {
  late TextEditingController _contentController;
  late String _selectedCategory;
  String? _errorMessage;
  bool _saving = false;
  bool _loaded = false;
  bool _loading = false;
  bool _committed = false;
  bool _clearFailed = false;

  /// 元の定型文が見つからない下書きを閲覧している。保存は出さない。
  bool _orphaned = false;
  PhraseDraft? _orphan;
  static const _savedClearFailure = '定型文は保存済みですが、下書きを消せませんでした。閉じると次回も残ります。';
  static const _clearFailure = '下書きを消せませんでした。閉じると次回も残ります。';
  static const _loadFailure = '下書きを読み込めませんでした。入力は保存できますが、下書きは残りません。';

  /// 対象ID。新しいIDは作らない（元の定型文と下書きを結ぶのはこのIDだけ）。
  String get _id => widget.phrase?.id ?? widget.draftId!;

  /// 下書きの読み書きができる状態か。読めていない間は一切書かない。
  bool get _draftsReady => widget.drafts != null && _loaded;

  /// 元の定型文から本文もカテゴリも変えていないか。変えていれば、戻る操作で
  /// 黙って捨てず（L-136）、読み直しでも置き換えない（L-170）。
  bool get _untouched =>
      _contentController.text == (widget.phrase?.content ?? '') &&
      _selectedCategory ==
          (widget.phrase?.category ?? PhraseConstants.defaultCategory);

  @override
  void initState() {
    super.initState();
    assert(widget.phrase == null ||
        widget.draftId == null ||
        widget.phrase!.id == widget.draftId);
    // 初期化: 編集対象の定型文から初期値を設定
    _contentController =
        TextEditingController(text: widget.phrase?.content ?? '');
    _selectedCategory =
        widget.phrase?.category ?? PhraseConstants.defaultCategory;
    _loaded = widget.drafts == null;
    if (!_loaded) _load();
  }

  Future<void> _load() async {
    // 到達するのは initState と「再読み込み」（`_untouched` のときだけ出す）。
    setState(() => _loading = true);
    final loaded = await widget.drafts!.initialize();
    if (!mounted) return;
    final draft = loaded ? widget.drafts!.readEdit(_id) : null;
    setState(() {
      _loading = false;
      _loaded = loaded;
      // 下書きは補助機能。読めなくても編集そのものは止めない（ADR-005）。
      _errorMessage = loaded ? null : _loadFailure;
      if (widget.phrase == null) {
        // 入口から開いた孤立下書き。間に消えていれば「見つからない」を出す。
        _orphaned = true;
        _orphan = draft;
      } else if (draft != null) {
        // 復元そのものは変更ではないので書かない。古い本文で戻さない。
        _contentController.text = draft.content;
        _selectedCategory = draft.category;
      }
    });
  }

  void _changeDraft() {
    if (_draftsReady && !_saving && !_committed && !_orphaned) {
      widget.drafts!.changeEdit((
        id: _id,
        content: _contentController.text,
        category: _selectedCategory
      ));
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// メソッド: 保存ボタン押下時の処理
  /// 実装内容: バリデーション実行後、更新済み定型文でコールバック発火
  Future<void> _onSave() async {
    if (_saving || _loading) return;
    // 保存済みの後は下書きの消去だけを再試行する。本体は2度書かない。
    if (!_committed) {
      final validationError = PresetPhraseValidator.validateContent(
        _contentController.text,
      );
      if (validationError != null) {
        setState(() {
          _errorMessage = validationError;
        });
        return;
      }
    }

    // 未読のまま保存する経路では、下書きへは読み書きとも一切触らない。
    final ready = _draftsReady;
    // trimや切詰めをせず、保存と同じsnapshotを先に下書きへ送る。
    _changeDraft();
    setState(() => _saving = true);
    var result = PhraseUpdateResult.failed;
    var cleared = false;
    try {
      if (_committed) {
        cleared = await widget.drafts!.removeEdit(_id);
      } else if (!ready || await widget.drafts!.flush()) {
        // 更新処理: updatedAt自動更新
        result = await widget.onSave?.call(widget.phrase!.copyWith(
              content: _contentController.text,
              category: _selectedCategory,
              updatedAt: DateTime.now(),
            )) ??
            PhraseUpdateResult.failed;
        if (result == PhraseUpdateResult.saved && ready) {
          _committed = true;
          cleared = await widget.drafts!.removeEdit(_id);
        }
      }
    } catch (e, s) {
      // 入力を残し、同じ場所で再試行できるようにする。catchは狭めない
      // （`_saving` が戻らなくなる方が悪い）。Errorだけログへ流す。
      reportDraftProgrammingError(e, s);
    }
    if (!mounted) return;
    if (_committed ? cleared : result == PhraseUpdateResult.saved) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      if (_committed) {
        // 本体は保存済みで消去だけ失敗した＝閉じても失うものが無い。
        _clearFailed = true;
        _errorMessage = _savedClearFailure;
      } else if (result == PhraseUpdateResult.missing && ready) {
        // 元の定型文が消えた。下書きを残して閲覧へ移る。保存済みにも
        // 追加にも変えない（消えた定型文を元のIDで復活させない）。
        _orphaned = true;
        _orphan = widget.drafts!.readEdit(_id);
      } else {
        _errorMessage = result == PhraseUpdateResult.missing
            ? '元の定型文が見つかりません。入力内容は残っています。'
            : '保存を確認できませんでした。入力内容を残しています。';
      }
    });
  }

  /// メソッド: キャンセルボタン押下時の処理（孤立の「下書きを破棄」も同じ）
  Future<void> _onCancel() async {
    if (_saving) return;
    // 未読mapは閉じるだけで残す。
    if (!_draftsReady) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    var cleared = false;
    try {
      cleared = await widget.drafts!.removeEdit(_id);
    } catch (e, s) {
      // 例外でも`_saving`のまま固めない（固めると全操作が塞がる）。
      reportDraftProgrammingError(e, s);
    }
    if (!mounted) return;
    if (cleared) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        // 消せないまま閉じ込めない。閉じても下書きは残るので失うものは無い。
        _clearFailed = true;
        _errorMessage = _committed ? _savedClearFailure : _clearFailure;
      });
    }
  }

  /// 孤立下書きの本文をOSのクリップボードへ置く。成功するまで成功と言わない。
  Future<void> _onCopy() async {
    var copied = false;
    try {
      await Clipboard.setData(ClipboardData(text: _orphan!.content));
      copied = true;
    } catch (e, s) {
      reportDraftProgrammingError(e, s);
    }
    if (!mounted) return;
    setState(
        () => _errorMessage = copied ? 'コピーしました。' : 'コピーできませんでした。下書きは残っています。');
  }

  /// メソッド: テキスト変更時の処理
  /// 実装内容: エラーメッセージをクリアしてUIを更新
  void _onTextChanged() {
    if (_saving || _loading || _committed || _orphaned) return;
    _changeDraft();
    setState(() {
      // 打ち直した文はまだ守る対象。backの確認（L-136）を取り戻す。
      _clearFailed = false;
      // 読めていないことは入力のたびに消えてはいけない事実なので残す。
      _errorMessage = _loaded ? null : _loadFailure;
    });
  }

  /// メソッド: カテゴリ変更時の処理
  void _onCategoryChanged(String category) {
    if (_saving || _loading || _committed || _orphaned) return;
    setState(() {
      _clearFailed = false;
      _selectedCategory = category;
      _errorMessage = _loaded ? null : _loadFailure;
    });
    _changeDraft();
  }

  /// 元の定型文が消えた下書き。本文は欄（4行・凍結中はスクロール不可）に
  /// 押し込めず、全文を読めるようにする。AlertDialog がスクロールを持つ。
  Widget _buildOrphan() {
    final draft = _orphan;
    return ConfirmationDialogLayout.build(
      title: const Text('定型文の下書き'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(draft == null ? '下書きが見つかりません。' : '元の定型文が見つかりません。下書きは残っています。'),
          if (draft != null) ...[
            const SizedBox(height: AppSizes.paddingMedium),
            Text('カテゴリ: ${PhraseConstants.getCategoryLabel(draft.category)}'),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(draft.content),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSizes.paddingMedium),
            Text(_errorMessage!),
          ],
        ],
      ),
      // 「閉じる」と戻る操作は下書きを残す。消すのは「下書きを破棄」だけで、
      // 押し間違いではなく意思表示なので訊き返さない（DiscardInputGuard と同じ）。
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
        if (draft != null) ...[
          TextButton(
            onPressed: _saving ? null : _onCopy,
            child: const Text('コピー'),
          ),
          TextButton(
            onPressed: _saving ? null : _onCancel,
            child: const Text('下書きを破棄'),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_orphaned) {
      // 「閉じる」も戻る操作も閉じるだけで下書きは残るので、確認して守る
      // ものが無い。「下書きを破棄」の待機中だけ止める。
      final orphan = _buildOrphan();
      return _saving
          ? PopScope(
              canPop: false,
              child: ExcludeFocus(child: AbsorbPointer(child: orphan)),
            )
          : orphan;
    }
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
    final frozen = _loading || _committed;
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
                // `_saving` は含めない（台帳 L-177。追加フォームと同じ）。
                frozen: frozen,
              ))),
      actions: [
        // 元から変えた入力があるうちは出さない。読み直しが置き換える
        if (!_loaded && !_loading && _untouched)
          TextButton(onPressed: _load, child: const Text('再読み込み')),
        // 消去が失敗し続けても閉じられる出口。下書きは消さずに残す
        // （閉じられないとモーダルの下の緊急ボタンへ到達できない）
        if (_clearFailed)
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        // キャンセルボタン: ダイアログを閉じる
        TextButton(
          onPressed: _saving ? null : _onCancel,
          child: const Text('キャンセル'),
        ),
        // 保存ボタン: バリデーション後に保存
        ElevatedButton(
          onPressed: _saving || _loading ? null : _onSave,
          child: const Text('保存'),
        ),
      ],
    );
    // 戻る操作は閉じるだけで、下書きを消さない。消えるのは「キャンセル」と、
    // 確認で「破棄する」を選んだときだけ。
    return _saving
        ? PopScope(
            canPop: false,
            child: ExcludeFocus(child: AbsorbPointer(child: dialog)),
          )
        : DiscardInputGuard(
            // 消去に失敗した後は、閉じても下書きは残るので確認して守るものが無い
            hasInput: !_clearFailed && !_untouched,
            onDiscard: _onCancel,
            child: dialog,
          );
  }
}
