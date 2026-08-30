/// 永続化の真実が1つであるための構造的な不変条件（ADR-005 / Phase 3 WP-1）
///
/// 【守っているもの】: `persistenceStateProvider` も `repository_providers` も
/// `Hive.isBoxOpen` を読むが、Riverpod の `Provider` はキャッシュされるため
/// 「同じ述語を読む」ことは「同じ値を返す」ことを保証しない。両者が別々の
/// 時点でキャッシュした値を持つと、片方だけが古くなりうる。
///
/// 今は安全である。理由は次の2つだけで、どちらもコードの構造に依存する。
///
/// 1. box を開くのは `initHive()` の中だけで、`runApp()` の前に完了する
/// 2. 実行中に box を閉じる経路が無い
///
/// つまり `Hive.isBoxOpen` はアプリの生存期間を通じて不変であり、
/// キャッシュが古くなりようがない。**この2つが崩れた瞬間に
/// 「保存できていないのにバナーが出ない」が起きる**——ADR-005 が最も
/// 避けたい形である。そこで前提そのものをテストで固定する。
///
/// このテストが落ちたら、`persistenceStateProvider` を box の状態変化に
/// 追随させる（`Hive.box(...).listenable()` を使う等）改修が必要になる。
/// 経緯は台帳 Issue #85。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `lib/` 配下の Dart ソースを列挙する
List<File> _libSources() {
  final libDir = Directory('lib');
  return libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();
}

void main() {
  group('永続化状態のキャッシュが古くならないための前提', () {
    test('実行中に Hive box を閉じるコードが lib に無い', () {
      final offenders = <String>[];

      for (final file in _libSources()) {
        final source = file.readAsStringSync();
        // 【hive_init.dart の除外】: 破損復旧のための deleteBoxFromDisk は
        // initHive の中＝runApp の前にしか走らないため、実行中の状態変化に
        // あたらない。
        final isHiveInit = file.path.endsWith('hive_init.dart');

        for (final pattern in <String>[
          'Hive.close(',
          if (!isHiveInit) 'deleteBoxFromDisk(',
        ]) {
          if (source.contains(pattern)) {
            offenders.add('${file.path}: $pattern');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: '実行中に box を閉じると persistenceStateProvider の値が古くなり、'
            '「保存できていないのにバナーが出ない」が起きる。'
            'provider を box の状態変化に追随させる改修が必要（台帳 Issue #85）。'
            '検出: $offenders',
      );
    });

    test('Hive box を開くのは hive_init.dart だけである', () {
      final offenders = <String>[];

      for (final file in _libSources()) {
        if (file.path.endsWith('hive_init.dart')) continue;
        final source = file.readAsStringSync();
        // コメント中の言及は対象外。実際の呼び出し（`Hive.openBox<`）を見る。
        if (source.contains('Hive.openBox<') ||
            source.contains('Hive.openLazyBox<')) {
          offenders.add(file.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'box を後から開くと、それ以前に評価された '
            'persistenceStateProvider が古い状態を返し続ける。'
            '検出: $offenders',
      );
    });
  });
}
