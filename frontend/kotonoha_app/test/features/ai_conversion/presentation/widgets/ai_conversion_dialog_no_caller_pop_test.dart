/// home_screen: AI変換結果ダイアログ表示メソッド内でのpop禁止を保証する回帰テスト
///
/// 【テスト目的】: `_showConversionResult` の中でNavigatorのpopが行われていないことを
/// 保証する
///
/// 【背景（実障害）】:
/// showDialogはroot Navigatorにダイアログを積む一方、呼び出し元contextは
/// go_routerのShellRoute配下branch Navigatorに属する。呼び出し元contextで
/// popすると、ダイアログではなく背後のページがpopされ、
/// リリースビルドで画面が空白になり再操作不能になっていた。
/// ダイアログのクローズは AIConversionResultDialog.show() 内部の
/// dialogContext が担当するため、このメソッドはpopしてはならない。
///
/// 【検査方針】:
/// analyzer でDartの構文木を解析し、`_showConversionResult` の本体に
/// pop / popUntil / maybePop の呼び出しが一切現れないことを検証する。
///
/// レシーバ（`Navigator.of(context)` なのか `context` なのか等）は問わない。
/// メソッド内では全面禁止とすることで、`Navigator.pop(context)`・
/// `context.pop()`・`GoRouter.of(context).pop()`・変数経由・カスケード・
/// 総称呼び出し `pop<T>()` など記法を問わず検出できる。
///
/// 構文木を使うため、コメント・文字列リテラル・文字列補間・波括弧の対応は
/// パーサが正しく扱う。自前の字句解析は不要。
///
/// 【このテストの限界】:
/// - 静的解析であり実行時の挙動は検証しない
///   （実挙動は ai_conversion_result_dialog_shell_route_test.dart が担当）
/// - コールバック本体を別メソッドへ切り出し、そのメソッド内でpopする形は
///   検出できない。ダイアログ表示と同じメソッドに処理を保つこと
/// - tear-off（`onTap: nav.pop`）は呼び出しではないため検出しない（実害なし）
/// - `_showConversionResult` を改名・移動した場合は健全性チェックで明示的に落ちる
///
/// 🔵 信頼性レベル: 青信号 - P0障害（ShellRoute配下でのダイアログpop）の回帰防止
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

/// 対象ソースのパス（パッケージルートからの相対）。
///
/// `flutter test` は常にパッケージルートをcwdにするため相対パスで解決できる。
const String kHomeScreenPath =
    'lib/features/character_board/presentation/home_screen.dart';

/// 検査対象のメソッド名。
const String kTargetMethod = '_showConversionResult';

/// 禁止するNavigator操作。
const Set<String> kForbiddenCalls = {'pop', 'popUntil', 'maybePop'};

/// 指定名のメソッド宣言を探す。
class _MethodDeclarationFinder extends RecursiveAstVisitor<void> {
  _MethodDeclarationFinder(this.methodName);

  final String methodName;
  final List<MethodDeclaration> found = [];

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == methodName) {
      found.add(node);
    }
    super.visitMethodDeclaration(node);
  }
}

/// pop系の呼び出しを収集する。
class _PopCallCollector extends RecursiveAstVisitor<void> {
  final List<String> calls = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (kForbiddenCalls.contains(node.methodName.name)) {
      calls.add(node.toSource());
    }
    super.visitMethodInvocation(node);
  }
}

void main() {
  group('home_screen: ダイアログ表示メソッド内のpop禁止', () {
    late CompilationUnit unit;

    setUpAll(() {
      final file = File(kHomeScreenPath);
      expect(
        file.existsSync(),
        isTrue,
        reason: '$kHomeScreenPath が見つからない（パス変更時は本テストも更新すること）',
      );
      // 構文エラーがあれば例外になる（＝解析結果を信用してよいことの保証）
      unit = parseString(content: file.readAsStringSync()).unit;
    });

    test('$kTargetMethod 内にpopが一切存在しない', () {
      final finder = _MethodDeclarationFinder(kTargetMethod);
      unit.accept(finder);

      expect(
        finder.found,
        hasLength(1),
        reason: '$kTargetMethod がちょうど1つ見つかる必要がある'
            '（改名・移動・多重定義時は本テストも更新すること）',
      );

      final body = finder.found.single.body;

      // 【健全性】: 検査対象が期待どおりのメソッドであること
      final source = body.toSource();
      expect(source, contains('AIConversionResultDialog.show'));
      expect(source, contains('onAdopt'));
      expect(source, contains('onRegenerate'));
      expect(source, contains('onUseOriginal'));

      // 【結果検証】: このメソッドはダイアログを閉じる責務を持たない
      final collector = _PopCallCollector();
      body.accept(collector);
      expect(
        collector.calls,
        isEmpty,
        reason: '$kTargetMethod 内にpop（${collector.calls.join(", ")}）が存在する。'
            'ダイアログのクローズは AIConversionResultDialog.show() 内部の '
            'dialogContext が行うため、このメソッドでpopしてはならない。'
            '呼び出し元contextはShellRoute配下のbranch Navigatorに属し、'
            'popすると背後のページが消える',
      );
    });

    test('検出ロジックがあらゆる記法のpopを拾える', () {
      // 【テスト自体の妥当性】: 常に空を返すだけの空テストでないことを保証する
      const snippet = '''
class Sample {
  void a(BuildContext context) => Navigator.pop(context);
  void b(BuildContext context) => Navigator.of(context).pop();
  void c(BuildContext context) => Navigator.of(context, rootNavigator: true).pop();
  void d(BuildContext context) => GoRouter.of(context).pop();
  void e(BuildContext context) => context.pop();
  void f() => this.context.pop();
  void g(BuildContext context) => Navigator.of(context).pop<bool>(true);
  void h(BuildContext context) => Navigator.popUntil(context, (r) => r.isFirst);
  void i(BuildContext context) => Navigator.maybePop(context);
  void j(NavigatorState nav) => nav..pop();
  void k(NavigatorState nav) => nav.pop();
}
''';
      final collector = _PopCallCollector();
      parseString(content: snippet).unit.accept(collector);
      expect(
        collector.calls,
        hasLength(11),
        reason: '11通りの記法すべてを検出する必要がある: ${collector.calls}',
      );
    });

    test('コメント・文字列内のpopは検出しない', () {
      // 構文木を使うため字句レベルの誤検出は起きない
      const snippet = '''
class Sample {
  // Navigator.pop(context) を呼んではならない
  /// 例: Navigator.of(context).pop()
  void a() {
    final url = "http://example.com//path";
    final message = 'Navigator.pop(context) と書いてはいけない';
    final brace = '}';
    debugPrint('\$url \$message \$brace');
  }
}
''';
      final collector = _PopCallCollector();
      parseString(content: snippet).unit.accept(collector);
      expect(collector.calls, isEmpty);
    });

    test('pop以外の呼び出しを誤検出しない', () {
      const snippet = '''
class Sample {
  void a(List<int> list) {
    list.removeLast();
    popular();
    showPopupMenu();
  }
  void popular() {}
  void showPopupMenu() {}
}
''';
      final collector = _PopCallCollector();
      parseString(content: snippet).unit.accept(collector);
      expect(collector.calls, isEmpty);
    });
  });
}
