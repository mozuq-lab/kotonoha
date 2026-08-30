/// 永続化の真実が古くならないための構造的な不変条件（ADR-005 / Phase 3 WP-1）
///
/// 【この検査が守るもの、守らないもの】
///
/// `persistenceStateProvider` は `repository_providers` から導いているため、
/// バナーと repository が**食い違う**ことは原理的に起きない（両者は Riverpod の
/// 依存関係で結ばれている）。この検査が見ているのは残りの1点、
/// 「**両方が同時に古くなる**」ことである。
///
/// 今それが起きない理由は、コードの構造に依存する。
///
/// 1. box を開くのは `initHive()` の中だけで、`runApp()` の前に完了する
/// 2. 実行中に box を閉じる経路が無い
///
/// つまり Hive の open set はアプリの生存期間を通じて不変であり、
/// キャッシュが古くなりようがない。**この前提が崩れた瞬間に
/// 「保存できていないのにバナーが出ない」が起きる**ため、前提自体を固定する。
///
/// 【完全性は無い。文字列検査で完全性は得られない】
///
/// この検査は文字列照合である。`extension` 内の receiver 無し `close()` のような
/// 形は原理的に追えない。追い始めると際限がなく、ADR-008 が3周・約4,600行かけて
/// 却下した「発火実績ゼロの検査」と同じ道になる。**完全性ではなく、
/// 現実に書かれやすい形を捕まえることを目的とする。**
/// 捕まえられない形の一覧と経緯は台帳 Issue #85。
///
/// 【自己検査について】: 検出ロジックは [detectRuntimeOpenSetChanges] に
/// 切り出してある。自己検査はこの関数を**実際に走らせて**回避コード片が
/// 拾われることを見る。定数どうしを突き合わせる形にすると、検出ロジックを
/// 壊しても自己検査が緑のまま通る（3周目のレビューで実証された）。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Dart ソースからコメントを取り除く
///
/// コメント中の記述で検査が欺かれる／誤検出することを防ぐ。
String stripComments(String source) {
  final withoutBlock =
      source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  return withoutBlock.split('\n').map((line) {
    final index = line.indexOf('//');
    return index < 0 ? line : line.substring(0, index);
  }).join('\n');
}

/// 実行中に Hive の open set を変えうる呼び出しを [source] から検出する
///
/// 【純粋関数にしてある理由】: 自己検査がこの関数を実際に走らせるため。
/// 検出ロジックとその検査が別々の定数を見ていると、片方を壊しても
/// 気づけない。
///
/// [path] は除外判定（`hive_init.dart` 自身）に使う。
List<String> detectRuntimeOpenSetChanges({
  required String path,
  required String source,
}) {
  final code = stripComments(source);

  // 【hive_init.dart の除外】: 破損復旧の削除と box のオープンは initHive の
  // 中＝runApp の前にしか走らないため、実行中の状態変化にあたらない。
  // パス区切りまで含めて比較する（`*_hive_init.dart` という名前を付けて
  // 検査を外れる抜け道を塞ぐ）。
  final isHiveInit = path.endsWith('/hive_init.dart');

  final offenders = <String>[];

  // 【`.close()` だけ Hive 限定にする理由】: このパターンだけは綴りが
  // Hive 固有でなく、StreamController や File にも当たる。`package:hive` を
  // 参照するファイルに限ることで誤検出を減らす。
  // 他のパターンは綴りが Hive 固有なので絞らない——絞ると、
  // `hive_init.dart` の公開ヘルパを（`package:hive` を import せずに）
  // 呼ぶファイルに届かなくなる。3周目のレビューが実証した穴である。
  if (code.contains('package:hive') && code.contains('.close()')) {
    offenders.add('$path: .close()');
  }

  if (!isHiveInit) {
    for (final pattern in <String>[
      'FromDisk(',
      'openBox(',
      'openBox<',
      'openLazyBox(',
      'openLazyBox<',
      'openBoxWithRecovery(',
      'openBoxWithRecovery<',
    ]) {
      if (code.contains(pattern)) {
        offenders.add('$path: $pattern');
      }
    }
  }

  return offenders;
}

/// `lib/` 配下の Dart ソースを列挙する
List<File> _libSources() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

void main() {
  group('永続化状態が古くならないための前提', () {
    test('実行中に Hive の open set を変える呼び出しが lib に無い', () {
      final offenders = <String>[
        for (final file in _libSources())
          ...detectRuntimeOpenSetChanges(
            path: file.path,
            source: file.readAsStringSync(),
          ),
      ];

      expect(
        offenders,
        isEmpty,
        reason: '実行中に Hive の open set が変わると、'
            'persistenceStateProvider と repository の両方が古くなり、'
            '「保存できていないのにバナーが出ない」が起きる。'
            'provider を box の状態変化に追随させる改修が必要（台帳 Issue #85）。'
            'Hive と無関係な .close() で落ちた場合は、'
            'このファイルを除外する判断を人が行うこと。検出: $offenders',
      );
    });

    test('main.dart は runApp より前に initHive を await する', () {
      // 【限界】: これは文字列の位置比較であり、制御フローは見ていない。
      // コメントは除去するので「コメントで欺く／コメントで壊れる」は防げるが、
      // 呼ばれない関数の中に await を置く形は見抜けない。
      // 完全な解には Dart のパースが要る（依存の追加は ADR が必要）。
      final code = stripComments(File('lib/main.dart').readAsStringSync());

      final awaitIndex = code.indexOf('await initHive()');
      expect(
        awaitIndex,
        greaterThanOrEqualTo(0),
        reason: 'main.dart が initHive() を await していない。'
            'runApp 後に box が開くと、それ以前に評価された '
            'persistenceStateProvider が古い状態を返し続ける。',
      );
      expect(
        code.indexOf('runApp('),
        greaterThan(awaitIndex),
        reason: 'runApp が initHive() の await より前にある。',
      );
    });
  });

  group('この検査自体が機能しているかの自己検査', () {
    // 【なぜ必要か】: この検査は「両方が同時に古くなることは起きない」という
    // 判断の根拠である。ザルなら、その判断ごと崩れる。
    // **検出関数を実際に走らせて**確かめる。定数どうしの突き合わせでは、
    // 検出ロジックを壊しても緑のまま通る。
    const evasions = <String, String>{
      '型引数なしの openBox': "await Hive.openBox('x');",
      '型引数ありの openBox': "await Hive.openBox<String>('x');",
      'box 単体を閉じる': "await Hive.box<String>('h').close();",
      '変数経由で閉じる': 'final h = Hive; await h.close();',
      '小文字レシーバで開く': "final hive = Hive; hive.openBox('h');",
      'deleteFromDisk': 'await Hive.deleteFromDisk();',
      'deleteBoxFromDisk': "await Hive.deleteBoxFromDisk('h');",
      'openLazyBox': "await Hive.openLazyBox('x');",
      '別名 import': "await hv.Hive.openBox(n);",
    };

    for (final entry in evasions.entries) {
      test('${entry.key} を検出する', () {
        final offenders = detectRuntimeOpenSetChanges(
          path: 'lib/features/settings/probe.dart',
          source: "import 'package:hive/hive.dart';\n"
              'Future<void> p() async { ${entry.value} }',
        );

        expect(offenders, isNotEmpty);
      });
    }

    test('hive_init.dart の公開ヘルパを他ファイルから呼ぶ経路を検出する', () {
      // 【3周目のレビューが見つけた穴】: 呼び出し元は package:hive を
      // import するとは限らない（hive_init.dart を import すれば足りる）。
      // `package:hive` で絞り込むと、この経路に一度も届かない。
      final offenders = detectRuntimeOpenSetChanges(
        path: 'lib/features/settings/probe.dart',
        source: "import 'package:kotonoha_app/core/utils/hive_init.dart';\n"
            "Future<void> p() async { await openBoxWithRecovery<int>('x'); }",
      );

      expect(offenders, isNotEmpty);
    });

    test('part ファイル（import 行を持たない）でも検出する', () {
      final offenders = detectRuntimeOpenSetChanges(
        path: 'lib/features/settings/probe_part.dart',
        source: "part of 'probe.dart';\n"
            "Future<void> p() async { await Hive.openBox('x'); }",
      );

      expect(offenders, isNotEmpty);
    });

    test('コメント中の記述では検出しない', () {
      final offenders = detectRuntimeOpenSetChanges(
        path: 'lib/features/settings/probe.dart',
        source: "import 'package:hive/hive.dart';\n"
            "// await Hive.openBox('x'); と書いてはいけない\n"
            '/* Hive.close() も同様 */\n'
            'void p() {}',
      );

      expect(offenders, isEmpty);
    });

    test('hive_init.dart 自身は box を開いてよい', () {
      final offenders = detectRuntimeOpenSetChanges(
        path: 'lib/core/utils/hive_init.dart',
        source: "import 'package:hive/hive.dart';\n"
            "Future<void> p() async { await Hive.openBox<int>('x'); }",
      );

      expect(offenders, isEmpty);
    });

    test('Hive と無関係な close() は検出しない', () {
      final offenders = detectRuntimeOpenSetChanges(
        path: 'lib/features/app_state/observer.dart',
        source: "import 'dart:async';\n"
            'void p(StreamController<int> c) { c.close(); }',
      );

      expect(offenders, isEmpty);
    });
  });
}
