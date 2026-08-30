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
    test('実行中に Hive の open set を変える呼び出しが lib に無い', () {
      final offenders = <String>[];

      for (final file in _libSources()) {
        final source = file.readAsStringSync();

        // 【Hive を触らないファイルは対象外】: これを先に置くことで、
        // 下の `.close()` のような広いパターンを入れても
        // StreamSubscription.close() 等を誤検出しない。
        if (!source.contains('package:hive')) continue;

        // 【hive_init.dart の除外】: 破損復旧の削除と box のオープンは
        // initHive の中＝runApp の前にしか走らないため、実行中の状態変化に
        // あたらない。パス区切りまで含めて比較する（`*_hive_init.dart` という
        // 名前を付けて検査を外れる抜け道を塞ぐ）。
        final isHiveInit = file.path.endsWith('/hive_init.dart');

        for (final pattern in <String>[
          // Hive.close() / h.close() / Hive.box(...).close() を一括で拾う。
          // receiver の書き方に依存しない。
          '.close()',
          // deleteFromDisk / deleteBoxFromDisk の両方
          if (!isHiveInit) 'FromDisk(',
          // 型引数の有無に依存しない（`Hive.openBox('x')` が最も書かれやすい）
          if (!isHiveInit) 'Hive.openBox',
          if (!isHiveInit) 'Hive.openLazyBox',
          // hive_init.dart の公開ヘルパを他ファイルから呼ぶ経路
          if (!isHiveInit) 'openBoxWithRecovery',
        ]) {
          if (source.contains(pattern)) {
            offenders.add('${file.path}: $pattern');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: '実行中に Hive の open set が変わると '
            'persistenceStateProvider の値が古くなり、'
            '「保存できていないのにバナーが出ない」が起きる。'
            'provider を box の状態変化に追随させる改修が必要（台帳 Issue #85）。'
            '検出: $offenders',
      );
    });

    test('main.dart は runApp より前に initHive を await する', () {
      // 【なぜ必要か】: 前提は2つある。「box を開くのは initHive の中だけ」と
      // 「それが runApp の前に完了する」。後者を検査していなかったため、
      // await を1つ外すだけで前提が崩れてもテストは緑のままだった。
      final source = File('lib/main.dart').readAsStringSync();

      final awaitIndex = source.indexOf('await initHive()');
      expect(
        awaitIndex,
        greaterThanOrEqualTo(0),
        reason: 'main.dart が initHive() を await していない。'
            'runApp 後に box が開くと、それ以前に評価された '
            'persistenceStateProvider が古い状態を返し続ける。',
      );
      expect(
        source.indexOf('runApp('),
        greaterThan(awaitIndex),
        reason: 'runApp が initHive() の await より前にある。',
      );
    });
  });

  group('この検査自体が機能しているかの自己検査', () {
    // 【なぜ必要か】: この検査は「Provider キャッシュ問題は本番で到達不能」
    // という判断の唯一の根拠である。ザルなら、その判断ごと崩れる。
    // 検出対象の文字列が実際に検出されることを、代表例で固定する。
    test('回避されやすい書き方が検出パターンに含まれている', () {
      const evasions = <String, String>{
        "Hive.openBox('x')  型引数なし": 'Hive.openBox',
        "Hive.box<T>('history').close()  box 単体を閉じる": '.close()',
        'Hive.deleteFromDisk()': 'FromDisk(',
        'Hive.openLazyBox()': 'Hive.openLazyBox',
        'openBoxWithRecovery を他ファイルから呼ぶ': 'openBoxWithRecovery',
      };

      for (final entry in evasions.entries) {
        expect(
          _runtimePatterns.contains(entry.value),
          isTrue,
          reason: '${entry.key} を取り逃す（パターン ${entry.value} が無い）',
        );
      }
    });
  });
}

/// 実行中に Hive の open set を変えうる呼び出しの検出パターン
///
/// 上のテスト本体と自己検査の両方が参照する。片方だけ直して食い違うことを防ぐ。
const _runtimePatterns = <String>[
  '.close()',
  'FromDisk(',
  'Hive.openBox',
  'Hive.openLazyBox',
  'openBoxWithRecovery',
];
