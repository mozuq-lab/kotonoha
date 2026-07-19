/// アプリライフサイクル監視
///
/// TASK-0079: アプリ状態復元・クラッシュリカバリ実装
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
/// 関連要件:
/// - EDGE-201: バックグラウンド復帰時の状態復元
/// - REQ-5003: クラッシュ時のデータ保持（入力中ドラフトの保存・復元）
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';

import 'app_session_provider.dart';

/// アプリライフサイクル監視ウィジェット
///
/// アプリがバックグラウンドに移行/復帰した時に
/// セッション状態の保存/復元を行う。
///
/// 【入力ドラフトの配線】: [inputBufferProvider]（文字盤の入力バッファ）の変更を
/// 監視し、[appSessionProvider]のsaveDraftTextへデバウンス付きで接続する。
/// 一文字ずつの入力に数分かかる利用者（ALS等）にとって、入力中のテキストが
/// アプリ終了・クラッシュ・OSによるkillで消失することは最もコストの高い損失
/// であるため、バックグラウンド移行時は必ず即時保存する。
///
/// 関連要件:
/// - EDGE-201: バックグラウンド復帰時の状態復元
/// - REQ-5003: クラッシュ時のデータ保持
class AppLifecycleObserver extends ConsumerStatefulWidget {
  /// 子ウィジェット
  final Widget child;

  /// コンストラクタ
  const AppLifecycleObserver({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AppLifecycleObserver> createState() =>
      _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver>
    with WidgetsBindingObserver {
  /// 【デバウンス時間】: 入力バッファ変更からドラフト保存までの待機時間
  ///
  /// 【設計判断】: 1文字ずつのタップ入力のたびにSharedPreferencesへ書き込むと
  /// I/Oが過剰になるため、400ms程度のデバウンスを設ける。
  /// タップ応答性要件（100ms以内）はUI描画側の話であり、
  /// バックグラウンドでの永続化処理には影響しない。
  /// ただしバックグラウンド移行時（didChangeAppLifecycleState）は
  /// デバウンスを待たず必ず即時保存する。
  static const Duration _draftSaveDebounce = Duration(milliseconds: 400);

  Timer? _draftSaveTimer;
  ProviderSubscription<String>? _inputBufferSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 初期化: セッション状態の復元 → 入力バッファへのドラフト復元 → 監視開始
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(appSessionProvider.notifier).initialize();
      if (!mounted) return;

      // 【ドラフト復元】: 起動時に保存済みドラフトがあれば入力バッファへ復元する
      _restoreDraftText();

      // 【監視開始】: 復元後に監視を開始することで、復元自体が保存トリガーに
      // ならないようにする
      _listenInputBuffer();
    });
  }

  /// 入力バッファの変更を監視し、デバウンス付きでドラフトを保存する
  void _listenInputBuffer() {
    _inputBufferSubscription = ref.listenManual<String>(
      inputBufferProvider,
      (previous, next) {
        _draftSaveTimer?.cancel();

        if (next.isEmpty) {
          // 【全消去の即時反映】: ユーザーが全消去した場合は、入力バッファと
          // ドラフトの整合性を保つため、デバウンスを待たず即時保存する
          ref.read(appSessionProvider.notifier).saveDraftText(next);
          return;
        }

        _draftSaveTimer = Timer(_draftSaveDebounce, () {
          ref.read(appSessionProvider.notifier).saveDraftText(next);
        });
      },
    );
  }

  /// 保存済みドラフトがあれば入力バッファへ復元する
  void _restoreDraftText() {
    final draftText = ref.read(appSessionProvider).draftText;
    if (draftText.isNotEmpty) {
      ref.read(inputBufferProvider.notifier).setText(draftText);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftSaveTimer?.cancel();
    _inputBufferSubscription?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final notifier = ref.read(appSessionProvider.notifier);

    switch (state) {
      case AppLifecycleState.paused:
        // 【即時保存】: バックグラウンド移行時はデバウンス中の変更を
        // 取りこぼさないよう、現在の入力バッファの内容を必ず即時保存する
        _draftSaveTimer?.cancel();
        final currentInput = ref.read(inputBufferProvider);
        notifier.saveDraftText(currentInput).then((_) {
          notifier.onAppPaused();
        });
        break;
      case AppLifecycleState.resumed:
        // フォアグラウンドに復帰: セッション状態を再読み込みし、
        // 入力バッファへドラフトを復元する
        notifier.onAppResumed().then((_) {
          if (mounted) _restoreDraftText();
        });
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // 他の状態は特に処理なし
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
