/// home_screen: AI変換結果ダイアログ表示メソッド内でのpop禁止を保証する回帰テスト
///
/// 【テスト目的】: `_showConversionResult` の中でNavigatorのpopが行われていないことを
/// ソースレベルで保証する
///
/// 【背景（実障害）】:
/// showDialogはroot Navigatorにダイアログを積む一方、呼び出し元contextは
/// go_routerのShellRoute配下branch Navigatorに属する。呼び出し元contextで
/// popすると、ダイアログではなく背後のページがpopされ、
/// リリースビルドで画面が空白になり再操作不能になる。
/// ダイアログのクローズは AIConversionResultDialog.show() 内部の
/// dialogContext が担当するため、このメソッドはpopしてはならない。
///
/// 【検査方針】:
/// `_showConversionResult` メソッド本体に pop / popUntil / maybePop が
/// 「一切現れないこと」だけを見る。
///
/// レシーバ（`Navigator.of(context)` なのか `context` なのか等）を解析せず、
/// メソッド内では全面禁止とすることで、`Navigator.pop(context)`・
/// `context.pop()`・`GoRouter.of(context).pop()`・変数経由・カスケード・
/// 総称呼び出し `pop<T>()` など、レシーバの書き方を問わず検出できる。
/// レシーバ解析に由来する網羅漏れは発生しない。
///
/// ダイアログ自身を閉じる正当なpop（`Navigator.of(dialogContext).pop()` 等）は
/// AIConversionResultDialog.show() の内部と、home_screen内の別ダイアログに
/// 存在するが、いずれもこのメソッドの外なので影響しない。
///
/// 【このテストの限界】:
/// - ソース検査であり実行時の挙動は検証しない
///   （実挙動は ai_conversion_result_dialog_shell_route_test.dart が担当）
/// - コールバック本体を別メソッドへ切り出し、そのメソッド内でpopする形は
///   検出できない。ダイアログ表示と同じメソッドに処理を保つこと
/// - `_showConversionResult` を改名・移動・式本体化（`=> `）した場合や、
///   総称メソッド・プレフィクス付き型・レコード型戻り値に変更した場合は
///   抽出できず、健全性チェックで明示的に落ちる（偽陰性にはならない）
/// - 行頭の `else` など一部のキーワードは戻り値型として吸われうるため、
///   宣言ではなく呼び出し箇所に先行マッチして別ブロックを抽出することがある。
///   その場合も健全性チェックが拾って落ちる
/// - `pop` を実行しない tear-off（`onTap: nav.pop,`）は検出しない（実害なし）
/// - 未終端の文字列リテラルがあると以降が空白化される（コンパイル不能なソースのみ）
///
/// 🔵 信頼性レベル: 青信号 - P0障害（ShellRoute配下でのダイアログpop）の回帰防止
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 対象ソースのパス（パッケージルートからの相対）。
///
/// `flutter test` は常にパッケージルートをcwdにするため相対パスで解決できる。
const String kHomeScreenPath =
    'lib/features/character_board/presentation/home_screen.dart';

/// 検査対象のメソッド名。
const String kTargetMethod = '_showConversionResult';

/// Dartソースを検査可能な形に正規化する。
///
/// - コメント（行/ブロック/doc）を空白化する
/// - 文字列リテラルの**中身**を空白化する（引用符と補間 `${...}` のコードは残す）
///
/// 文字列を素通しすると、`"http://x//y"` のようなURLの `//` を行コメント開始と
/// 誤認して以降のコードを消してしまい、実在するpopを見逃す（偽陰性）。
/// 逆に文字列の中身を残すと `'}'` のような閉じ波括弧でブレース計数が壊れる。
/// そのため「引用符は残し中身だけ空白化」する。
///
/// 補間の内側は実際に実行されるコードなので、コードとして通す
/// （`'${list.pop()}'` のpopは検出対象になる）。
///
/// 改行は原則として保持する（ただし行継続のバックスラッシュ＋改行は
/// エスケープとして2文字まとめて空白化するため、その1箇所は詰まる）。
String sanitizeDartSource(String source) {
  final out = StringBuffer();
  // 文字列フレームのスタック。補間 `${...}` の内側は「コード」として扱うため、
  // 文字列に入るたび push し、補間を抜けたら再開する。
  final stringStack = <({String quote, bool raw, int braceDepth})>[];
  var i = 0;

  bool inString() => stringStack.isNotEmpty && stringStack.last.braceDepth == 0;

  while (i < source.length) {
    if (inString()) {
      final frame = stringStack.last;
      if (!frame.raw && source[i] == r'\') {
        out.write('  ');
        i += 2;
        continue;
      }
      if (source.startsWith(frame.quote, i)) {
        out.write(frame.quote);
        i += frame.quote.length;
        stringStack.removeLast();
        continue;
      }
      if (!frame.raw && source.startsWith(r'${', i)) {
        // 補間開始: コードとして通す
        stringStack[stringStack.length - 1] =
            (quote: frame.quote, raw: frame.raw, braceDepth: 1);
        out.write(r'${');
        i += 2;
        continue;
      }
      out.write(source[i] == '\n' ? '\n' : ' ');
      i++;
      continue;
    }

    // ---- コード領域（トップレベル or 補間の内側）----
    if (stringStack.isNotEmpty) {
      final frame = stringStack.last;
      if (source[i] == '{') {
        stringStack[stringStack.length - 1] = (
          quote: frame.quote,
          raw: frame.raw,
          braceDepth: frame.braceDepth + 1
        );
      } else if (source[i] == '}') {
        final d = frame.braceDepth - 1;
        stringStack[stringStack.length - 1] =
            (quote: frame.quote, raw: frame.raw, braceDepth: d);
      }
    }

    if (source.startsWith('/*', i)) {
      final end = source.indexOf('*/', i + 2);
      final seg = source.substring(i, end < 0 ? source.length : end + 2);
      out.write(seg.replaceAll(RegExp(r'[^\n]'), ' '));
      i = end < 0 ? source.length : end + 2;
      continue;
    }
    if (source.startsWith('//', i)) {
      final end = source.indexOf('\n', i);
      final stop = end < 0 ? source.length : end;
      out.write(' ' * (stop - i));
      i = stop;
      continue;
    }

    // 文字列リテラル開始
    var qStart = i;
    var raw = false;
    if (source[i] == 'r' &&
        i + 1 < source.length &&
        (source[i + 1] == "'" || source[i + 1] == '"')) {
      raw = true;
      qStart = i + 1;
    }
    String? quote;
    for (final c in const ["'''", '"""', "'", '"']) {
      if (source.startsWith(c, qStart)) {
        quote = c;
        break;
      }
    }
    if (quote != null) {
      if (raw) out.write('r');
      out.write(quote);
      i = qStart + quote.length;
      stringStack.add((quote: quote, raw: raw, braceDepth: 0));
      continue;
    }

    out.write(source[i]);
    i++;
  }
  return out.toString();
}

/// メソッド名から、その本体（波括弧ブロック）を抽出する。
///
/// 【重要】: 単に名前を検索すると、そのメソッドを呼び出している箇所
/// （`_showConversionResult` は自身を再帰的に呼ぶ）に先にマッチしてしまう。
/// そのため「行頭 + 戻り値型 + メソッド名 + (」という宣言の形に限定して探す。
///
/// 宣言から最初の `{` を探し、対応する `}` までを返す。
/// 式本体（`=> ...`）やゲッターは対象外でnullを返す（呼び出し側で明示的に落ちる）。
String? extractMethodBody(String source, String methodName) {
  // 例: `  void _showConversionResult(` / `  Future<String> _convertWithAI(`
  // 行頭が await/return/yield/throw の場合は「宣言」ではなく呼び出し式なので除外する。
  // これが無いと `await _showConversionResult(...)` の行を宣言と誤認する。
  const prefix = r'^[ \t]*(?:@\w+\s+)*(?!(?:await|return|yield|throw)\b)'
      r'(?:static\s+)?[A-Za-z_][A-Za-z0-9_<>,\s\?]*\s+';
  final declaration = RegExp(
    '$prefix${RegExp.escape(methodName)}${r'\s*\('}',
    multiLine: true,
  );
  final match = declaration.firstMatch(source);
  if (match == null) return null;

  final braceStart = source.indexOf('{', match.end);
  if (braceStart < 0) return null;

  var depth = 0;
  for (var i = braceStart; i < source.length; i++) {
    final char = source[i];
    if (char == '{') {
      depth++;
    } else if (char == '}') {
      depth--;
      if (depth == 0) return source.substring(braceStart, i + 1);
    }
  }
  return null;
}

/// pop系の呼び出しをすべて列挙する（レシーバは問わない）。
///
/// `pop<bool>(true)` のような総称呼び出しも対象にする。
/// 結果を返すダイアログでよく使われる正当な記法のため、見逃すと偽陰性になる。
List<String> findPopCalls(String source) {
  final pattern = RegExp(
    r'\b(?:pop|popUntil|maybePop)\s*(?:<[^<>{};()]*>)?\s*\(',
  );
  return pattern.allMatches(source).map((m) => m.group(0)!).toList();
}

void main() {
  group('home_screen: ダイアログ表示メソッド内のpop禁止', () {
    late String code;

    setUpAll(() {
      final file = File(kHomeScreenPath);
      expect(
        file.existsSync(),
        isTrue,
        reason: '$kHomeScreenPath が見つからない（パス変更時は本テストも更新すること）',
      );
      code = sanitizeDartSource(file.readAsStringSync());
    });

    test('$kTargetMethod 内にpopが一切存在しない', () {
      final body = extractMethodBody(code, kTargetMethod);
      expect(
        body,
        isNotNull,
        reason: '$kTargetMethod メソッドが見つからない'
            '（改名・式本体化・別ファイルへの移動時は本テストも更新すること）',
      );

      // 【健全性】: 抽出範囲が空振り・早期終了していないこと。
      // ここが落ちる場合は抽出ロジック側の問題であり、pop検査の結果は信用できない。
      expect(body, contains('AIConversionResultDialog.show('),
          reason: '抽出した本体にダイアログ呼び出しが含まれていない');
      expect(body, contains('onAdopt'));
      expect(body, contains('onRegenerate'));
      expect(body, contains('onUseOriginal'));

      // 【結果検証】: このメソッドはダイアログを閉じる責務を持たない
      final pops = findPopCalls(body!);
      expect(
        pops,
        isEmpty,
        reason: '$kTargetMethod 内にpop（${pops.join(", ")}）が存在する。'
            'ダイアログのクローズは AIConversionResultDialog.show() 内部の '
            'dialogContext が行うため、このメソッドでpopしてはならない。'
            '呼び出し元contextはShellRoute配下のbranch Navigatorに属し、'
            'popすると背後のページが消える',
      );
    });

    group('検出ロジックの自己検証', () {
      test('あらゆる記法のpopを検出できる', () {
        const cases = <String, String>{
          'Navigator.pop(context)': 'Navigator.pop(context);',
          'Navigator.of(context).pop()': 'Navigator.of(context).pop();',
          'rootNavigator付き':
              'Navigator.of(context, rootNavigator: true).pop();',
          'GoRouter.of(context).pop()': 'GoRouter.of(context).pop();',
          'context.pop()': 'context.pop();',
          'this.context.pop()': 'this.context.pop();',
          '別名context': 'pageContext.pop();',
          '変数経由': 'final nav = Navigator.of(context);\nnav.pop();',
          'カスケード': 'nav..pop();',
          'popUntil': 'Navigator.popUntil(context, (r) => r.isFirst);',
          'maybePop': 'Navigator.maybePop(context);',
          'メンバー経由': 'widget.navigator.pop();',
          '総称呼び出し': 'Navigator.of(context).pop<bool>(true);',
          '総称呼び出し（静的）': 'Navigator.pop<String>(context, "x");',
        };

        cases.forEach((label, snippet) {
          expect(
            findPopCalls(snippet),
            isNotEmpty,
            reason: '$label を検出できていない: $snippet',
          );
        });
      });

      test('pop以外の呼び出しを誤検出しない', () {
        const cases = <String>[
          'list.popular();',
          'const populate = 1;',
          'widget.population();',
          'popupMenu();',
        ];
        for (final snippet in cases) {
          expect(
            findPopCalls(snippet),
            isEmpty,
            reason: '誤検出している: $snippet',
          );
        }
      });

      test('宣言ではなく呼び出し箇所にマッチしない', () {
        // 【回帰防止】: 再帰呼び出しが先に現れても宣言側の本体を抽出すること
        const snippet = '''
void _caller(BuildContext context) {
  _target(context);
}

void _target(BuildContext context) {
  final marker = 1;
}
''';
        final body = extractMethodBody(sanitizeDartSource(snippet), '_target');
        expect(body, isNotNull);
        expect(body, contains('marker'), reason: '呼び出し箇所ではなく宣言の本体を抽出する必要がある');
      });
    });

    group('ソース正規化の自己検証', () {
      test('行コメント内のpopは検出対象から外れる', () {
        const snippet = '// Navigator.of(context).pop() を呼んではならない';
        expect(findPopCalls(sanitizeDartSource(snippet)), isEmpty);
      });

      test('doc comment内のpopも検出対象から外れる', () {
        const snippet = '/// 例: Navigator.pop(context)';
        expect(findPopCalls(sanitizeDartSource(snippet)), isEmpty);
      });

      test('ブロックコメント内のpopも検出対象から外れる', () {
        const snippet = '/* Navigator.pop(context); */';
        expect(findPopCalls(sanitizeDartSource(snippet)), isEmpty);
      });

      test('文字列内のURLの // でコードが消えない', () {
        // 【回帰防止】: 文字列を素通しすると "http://x//y" の // を
        // 行コメント開始と誤認し、以降の実在するpopを見逃す
        const snippet = 'final u = "http://x//y"; Navigator.pop(c);';
        expect(
          findPopCalls(sanitizeDartSource(snippet)),
          isNotEmpty,
          reason: '文字列内のURLでpopを見逃している（偽陰性）',
        );
      });

      test('文字列内のコメント記号でコードが消えない', () {
        const snippet = 'final u = "a/*b"; Navigator.pop(c);';
        expect(findPopCalls(sanitizeDartSource(snippet)), isNotEmpty);
      });

      test('文字列内のpopは誤検出しない', () {
        const snippet = "final s = 'Navigator.pop(c)';";
        expect(findPopCalls(sanitizeDartSource(snippet)), isEmpty);
      });

      test('補間内のpopはコードとして検出する', () {
        const snippet = "final s = '\${list.pop()}';";
        expect(findPopCalls(sanitizeDartSource(snippet)), isNotEmpty);
      });

      test('文字列内の閉じ波括弧でブレース計数が壊れない', () {
        const snippet = "void _t() { final a = '}'; Navigator.pop(c); }";
        final body = extractMethodBody(sanitizeDartSource(snippet), '_t');
        expect(body, isNotNull);
        expect(
          findPopCalls(body!),
          isNotEmpty,
          reason: '文字列内の } で抽出が早期終了し、popを見逃している',
        );
      });

      test('raw文字列・三重クォートを正しく抜ける', () {
        const raws = <String>[
          "final s = r'\\n pop(' ; Navigator.pop(c);",
          "final s = '''a ' b''' ; Navigator.pop(c);",
        ];
        for (final snippet in raws) {
          expect(findPopCalls(sanitizeDartSource(snippet)), isNotEmpty,
              reason: '検出できていない: $snippet');
        }
      });

      test('await付きの呼び出し行を宣言と誤認しない', () {
        const snippet = '''
void _caller() {
  await _target(a, b);
  if (x) { Navigator.pop(context); }
}

void _target(int a, int b) {
  final marker = 1;
}
''';
        final body = extractMethodBody(sanitizeDartSource(snippet), '_target');
        expect(body, isNotNull);
        expect(body, contains('marker'), reason: 'await付き呼び出し行を宣言として抽出している');
        expect(findPopCalls(body!), isEmpty);
      });

      test('実コードのpopは除去されずに残る', () {
        const snippet = '// comment\nNavigator.pop(context);';
        expect(findPopCalls(sanitizeDartSource(snippet)), hasLength(1));
      });
    });
  });
}
