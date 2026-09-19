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
import 'package:kotonoha_app/core/persistence/settings_write_failure_provider.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';

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
    final dismissed = ref.watch(recreatedNoticeDismissedProvider);
    final failedPrefKeys = ref.watch(settingsWriteFailureProvider);
    // フォントサイズ設定の倍率（読み込み中・失敗時は「中」相当の 1.0）。
    // bodyMedium 等のテーマスタイルを使わない理由は下記 Text の style コメント参照。
    final fontSizeFactor = ref
            .watch(settingsNotifierProvider)
            .asData
            ?.value
            .fontSize
            .scaleFactor ??
        1.0;
    const none = <PersistedArea>{};

    // 保存できない状態（閉じられない）と作り直しの告知（閉じられる）は別々に組み、
    // 両方あれば 1 つの文に並べる。どちらかで他方を隠さない（ADR-005、L-83／L-90）。
    final (failureColors, failedAreas, isFailureState) = switch (state) {
      PersistenceReady() => (null, none, false),
      PersistenceRecreated() => (null, none, false),
      PersistenceUnavailable() => (
          unavailableBannerColors(scheme),
          PersistedArea.values.toSet(),
          true,
        ),
      PersistenceRecoverableFailure(:final failedAreas) => (
          recoverableBannerColors(),
          failedAreas,
          true,
        ),
    };
    // 空の集合は「作り直し無し」と同じ扱い（失敗の文言で誤報しない）
    final (recreatedAreas, salvagedAreas) = switch (state) {
      PersistenceRecreated(:final recreatedAreas, :final salvagedAreas)
          when !dismissed =>
        (recreatedAreas, salvagedAreas),
      _ => (none, none),
    };

    // 設定（SharedPreferences）の保存失敗は Hive の領域と同じ告知に名前を並べる
    final failedNames = [
      ..._areaNames(failedAreas),
      ...prefFailureNames(failedPrefKeys),
    ];
    // 失敗の領域が分からないときは対象を特定しない文言に倒す（設定の失敗が重なっても同じ）
    final failureText = isFailureState && failedAreas.isEmpty
        ? '保存できません。アプリを閉じると消えます'
        : failedNames.isNotEmpty
            ? '${failedNames.join('、')}を保存できません。アプリを閉じると消えます'
            : null;
    // 空で作り直した領域と、読める分だけ救った領域（台帳 L-101）。どちらも元の
    // ファイルは退避済みなので、退避の文は最後に 1 回だけ付ける
    final lossTexts = [
      if (recreatedAreas.isNotEmpty)
        '${_areaNames(recreatedAreas).join('、')}を読み込めなかったため、空の状態で開始しました',
      if (salvagedAreas.isNotEmpty)
        '${_areaNames(salvagedAreas).join('、')}の一部を読み込めませんでした',
    ];
    final recreatedText = lossTexts.isNotEmpty
        ? '${lossTexts.join('。')}。元のデータは端末内に退避しています'
        : null;
    if (failureText == null && recreatedText == null) {
      return const SizedBox.shrink();
    }
    final colors = failureColors ?? recoverableBannerColors();
    final message = [failureText, recreatedText].whereType<String>().join(' ');
    // 「閉じる」は作り直しの文が実際に出ているときだけ（見えない告知を捨てない）
    final showRecreated = recreatedText != null;

    // 読み上げの二重化を避けるため、本文はバナーの根の 1 ノード（label）にまとめ、
    // Icon と Text は個別ノードから除く。「閉じる」は除かない（excludeSemantics で
    // 子ごと捨てると支援技術から見えなくなる）。
    return Semantics(
      label: message,
      container: true,
      child: Material(
        color: colors.background,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Icon(Icons.warning_amber_rounded,
                    size: 18, color: colors.foreground),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: ExcludeSemantics(
                  child: Text(
                    message,
                    // フォントサイズ設定の倍率を固定値 14 に掛ける（REQ-802、
                    // 台帳 L-103）。テーマの bodyMedium は使わない: 本アプリの
                    // 3 テーマはいずれも bodyMedium の fontSize が
                    // AppSizes.fontSizeMedium（20.0）で、常設バナーの見た目が
                    // 「中」設定でも 14px→20px に変わってしまい、複数の告知が
                    // 重なる「大」設定では画面高の約 34%（実測、幅 390px の
                    // 画面で高さ 288px）を占有して文字盤の可視領域を大きく
                    // 圧迫する（リスクレビューで指摘、一度 bodyMedium 化した
                    // 判断を撤回）。「中」では 14px のまま・「大」では
                    // 16.8px と、既存の見た目を保ちつつ倍率だけ追従させる。
                    style: TextStyle(
                      color: colors.foreground,
                      fontSize: 14 * fontSizeFactor,
                    ),
                  ),
                ),
              ),
              // 作り直しの告知だけ閉じられる（保存できない状態の告知は閉じられない）
              if (showRecreated)
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
  List<String> _areaNames(Set<PersistedArea> areas) => PersistedArea.values
      .where(areas.contains)
      .map((area) => area.label)
      .toList();
}
