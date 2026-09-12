/// 永続化バナー（ADR-005 / Phase 3 WP-1）
/// 保存できない状態を利用者に伝え続ける常設バナー。
/// なぜ常設か: 対象の利用者は発話で確認・訂正ができず、データは端末内に
/// しか無い。一度きりの通知は見落とすと取り返しがつかないため、保存できない
/// 間はずっと表示する。保存できているとき（[PersistenceReady]）は高さ0で
/// 画面を1pxも占有しない。
/// 起動はブロックしない: 。ストレージが壊れていても文字盤・TTS は
/// 使えるべきなので、伝えたうえで継続する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/persistence/persistence_state_provider.dart';
import 'package:kotonoha_app/core/persistence/recreated_areas_provider.dart';

/// バナーの前景色と背景色の組
/// コントラスト比を測るテストが参照するため公開している。
@immutable
class PersistenceBannerColors {
  /// 文字とアイコンの色
  final Color foreground;

  /// 帯の背景色
  final Color background;

  /// 前景色と背景色を指定して作る
  const PersistenceBannerColors({
    required this.foreground,
    required this.background,
  });
}

/// 何も保存できないときの配色
/// 最も強い警告なので `error` / `onError` を使う。3テーマとも
/// コントラスト比を検証済み（`persistence_banner_test.dart`）。
PersistenceBannerColors unavailableBannerColors(ColorScheme scheme) =>
    PersistenceBannerColors(
      foreground: scheme.onError,
      background: scheme.error,
    );

/// 一部だけ保存できないときの配色
/// 全滅より一段弱い扱いとして、自前背景を持つ警告表示の既存パターン
/// （音量警告・AI変換不可と同じ [AppColors.warningContainer]）を使う。
/// `colorScheme.errorContainer` を使わない理由: 本アプリの3テーマは
/// `ColorScheme.light`/`dark` に `error` だけを渡しており
/// `errorContainer` は `error` にフォールバックする。そのため全滅と
/// 一部失敗が同じ色になり、区別が付かない（テストで検出した）。
/// テーマに依らない固定色なので ColorScheme は受け取らない。
PersistenceBannerColors recoverableBannerColors() =>
    const PersistenceBannerColors(
      foreground: AppColors.onWarningContainer,
      background: AppColors.warningContainer,
    );

/// 保存できない状態を伝える常設バナー
/// `AppShell` の画面本体の先頭に置き、全画面で表示される。
class PersistenceBanner extends ConsumerWidget {
  /// バナーを作る
  const PersistenceBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(persistenceStateProvider);
    final scheme = Theme.of(context).colorScheme;

    // 文言は失われる領域から作る: バナーが「消える」と言ってよい対象は
    // PersistenceState が実際に把握している領域（＝PersistedArea）に限る。
    // 「入力内容」と書いてはいけない: 下書き（入力バッファ）は Hive では
    // なく SharedPreferences に保存され、AppLifecycleObserver が復元する。
    // Hive が全滅しても入力内容は残るため、「入力内容は消えます」は誤報である。
    // 1文字に分単位かかる利用者に「急げ・アプリを閉じるな」という誤った行動を
    // 強いることになる。
    final dismissed = ref.watch(recreatedNoticeDismissedProvider);
    const none = <PersistedArea>{};
    final (colors, failedAreas, recreatedAreas) = switch (state) {
      PersistenceReady() => (null, none, none),
      PersistenceUnavailable() => (
          unavailableBannerColors(scheme),
          PersistedArea.values.toSet(),
          none,
        ),
      PersistenceRecoverableFailure(:final failedAreas) => (
          recoverableBannerColors(),
          failedAreas,
          none,
        ),
      // 破損で退避して作り直した告知（ADR-005、L-90）。利用者が閉じるまで残る
      PersistenceRecreated(:final recreatedAreas) => dismissed
          ? (null, none, none)
          : (recoverableBannerColors(), none, recreatedAreas),
    };
    // フェイルセーフ: ADR-005 は「保存されないことは**必ず**伝える」と
    // 定めている。failure 状態で無音になる経路を作ってはならない。
    // resolvePersistenceState は空集合の RecoverableFailure を作らないが
    // コンストラクタは公開されており、型が空集合を禁じてもいない。
    // 領域名が得られないときは、対象を特定しない文言に倒す。
    // **沈黙は、文言が多少不自然であることより悪い。**
    final message = colors == null
        ? null
        : recreatedAreas.isNotEmpty
            ? '${_areaNames(recreatedAreas)}を読み込めなかったため、空の状態で開始しました。元のデータは端末内に退避しています'
            : failedAreas.isEmpty
                ? '保存できません。アプリを閉じると消えます'
                : '${_areaNames(failedAreas)}を保存できません。アプリを閉じると消えます';

    if (colors == null || message == null) return const SizedBox.shrink();

    // Material で包む理由: このバナーは AppShell に置かれ、各画面の
    // Scaffold より外側にある。Material 祖先が無い位置の Text は
    // WidgetsApp の既定スタイル（赤文字＋黄色の二重下線）を継承するため
    // style を部分指定しただけでは下線が残る（実機の Chrome で確認した）。
    // excludeSemantics: 付けないと、この label と子 Text のラベルが
    // 同一ノードに連結され、スクリーンリーダーが同じ文を2回読む。
    return Semantics(
      label: message,
      excludeSemantics: true,
      child: Material(
        color: colors.background,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 18, color: colors.foreground),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  style: TextStyle(color: colors.foreground, fontSize: 14),
                ),
              ),
              // 作り直しの告知だけ閉じられる（保存できない状態の告知は閉じられない）
              if (recreatedAreas.isNotEmpty)
                TextButton(
                  onPressed: () => ref
                      .read(recreatedNoticeDismissedProvider.notifier)
                      .dismiss(),
                  child: Text(
                    '閉じる',
                    style: TextStyle(color: colors.foreground),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 保存できない領域の名前を、宣言順で読点区切りにする
  /// Set の反復順に依存すると文言が実行ごとに変わるため
  /// [PersistedArea] の宣言順に並べ直す。
  String _areaNames(Set<PersistedArea> areas) => PersistedArea.values
      .where(areas.contains)
      .map((area) => area.label)
      .join('、');
}
