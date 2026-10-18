/// 対面表示モード画面
/// テキストを画面中央に大きく表示する拡大表示モード
/// 画面を180度回転できる機能
/// 通常モードと対面表示モードをシンプルな操作で切り替え
/// ボタン・タップ領域を視認性が高く押しやすいサイズ
/// 配線: fix/improvement-p0-p2にてhome_screenのAppBarアクションから
/// 既存実装済みだった180度回転機能（RotationToggleButton/RotatedWrapper）を
/// この画面に組み込み、help_screen.dartの「対面表示モード」説明
/// （画面を180度回転させて相手に見せる）と実挙動を一致させる。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import '../../providers/face_to_face_provider.dart';
import '../widgets/face_to_face_text_display.dart';
import '../widgets/rotated_wrapper.dart';
import '../widgets/rotation_toggle_button.dart';
import '../widgets/face_to_face_editor.dart';

/// 対面表示モード画面
/// テキストを画面中央に大きく表示し、対面の相手が
/// メッセージを読み取りやすいようにする全画面ウィジェット。
/// 画面中央に大きく表示
/// 画面を180度回転できる機能（RotationToggleButtonで切替）
/// シンプルな操作で切り替え
/// 視認性が高く押しやすいボタン
class FaceToFaceScreen extends ConsumerStatefulWidget {
  /// 表示するテキスト
  final String displayText;

  /// 戻るボタン押下時のコールバック
  /// 指定しない場合はNavigator.popを使用
  final VoidCallback? onBack;

  /// FaceToFaceScreenを作成
  /// [displayText] 表示するテキスト
  /// [onBack] 戻るボタン押下時のコールバック（オプション）
  const FaceToFaceScreen({
    super.key,
    required this.displayText,
    this.onBack,
  });

  @override
  ConsumerState<FaceToFaceScreen> createState() => _FaceToFaceScreenState();
}

class _FaceToFaceScreenState extends ConsumerState<FaceToFaceScreen> {
  bool _isEditing = false;
  bool _hasStartedEditing = false;

  void _toggleEditing() {
    FocusScope.of(context).unfocus();
    if (!_hasStartedEditing) {
      // 入力が空で直近の履歴を表示した場合も、その文章から編集を始める。
      ref.read(inputBufferProvider.notifier).setText(widget.displayText);
    }
    setState(() {
      _hasStartedEditing = true;
      _isEditing = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 180度回転状態を監視し、テキスト表示に反映する。
    final isRotated = ref.watch(faceToFaceProvider).isRotated180;
    final buffer = ref.watch(inputBufferProvider);
    final text = _hasStartedEditing ? buffer : widget.displayText;
    final fontSize =
        ref.watch(settingsNotifierProvider).asData?.value.fontSize ??
            FontSize.medium;

    return Scaffold(
      // シンプルな背景（から推測）
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          // 横向きの電話・OS キーボード・大きい文字でも操作を潰さず、
          // 高さが足りないときは画面全体をスクロールできるようにする。
          final minHeight = _isEditing
              ? 640 *
                  MediaQuery.textScalerOf(context).scale(fontSize.scaleFactor)
              : 220.0;
          return SingleChildScrollView(
              child: SizedBox(
            height: math.max(constraints.maxHeight, minHeight),
            child: Stack(
              children: [
                // テキスト表示（画面中央）。180度回転トグルがONの場合は
                // RotatedWrapperで反転して表示する。
                Column(children: [
                  Expanded(
                    flex: _isEditing ? 3 : 1,
                    child: Padding(
                      padding: EdgeInsets.only(top: _isEditing ? 88 : 0),
                      child: RotatedWrapper(
                        isRotated: isRotated,
                        child: FaceToFaceTextDisplay(
                          text: text,
                          padding: _isEditing
                              ? const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8)
                              : const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 88),
                        ),
                      ),
                    ),
                  ),
                  if (_isEditing)
                    Expanded(
                      flex: 7,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 88),
                        child: FaceToFaceEditor(fontSize: fontSize),
                      ),
                    ),
                ]),
                // 180度回転切り替えボタン（左上に配置）
                const Positioned(
                  top: 16,
                  left: 16,
                  child: RotationToggleButton(),
                ),
                // 戻るボタン（右上に配置）
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildBackButton(context),
                ),
                // iPad を机に置いて向かい合うと、上の組は本人から遠く届きにくい
                // （iPad、2026-10-18）。下にも同じ組を置く。VoiceOver では上の組と
                // 同じ名前が 2 回読まれないよう、下の組は読ませない
                const Positioned(
                  bottom: 16,
                  left: 16,
                  child: ExcludeSemantics(child: RotationToggleButton()),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: ExcludeSemantics(child: _buildBackButton(context)),
                ),
                Positioned(
                  bottom: 16,
                  left: 88,
                  right: 88,
                  child: Center(
                      child: FilledButton.icon(
                    onPressed: _toggleEditing,
                    style:
                        FilledButton.styleFrom(minimumSize: const Size(48, 60)),
                    icon: Icon(_isEditing
                        ? CupertinoIcons.chevron_down
                        : CupertinoIcons.pencil),
                    label: Text(_isEditing ? '編集を閉じる' : '編集',
                        textAlign: TextAlign.center),
                  )),
                ),
              ],
            ),
          ));
        }),
      ),
    );
  }

  /// 戻るボタンを構築
  /// 最小タップターゲット44px×44px
  /// 視認性が高く押しやすいサイズ
  Widget _buildBackButton(BuildContext context) {
    return Semantics(
      button: true,
      label: '対面表示モードを終了',
      child: InkWell(
        onTap: widget.onBack ?? () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          // 最小タップターゲット44px×44px
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            CupertinoIcons.xmark,
            size: 24,
            semanticLabel: '閉じる',
          ),
        ),
      ),
    );
  }
}
