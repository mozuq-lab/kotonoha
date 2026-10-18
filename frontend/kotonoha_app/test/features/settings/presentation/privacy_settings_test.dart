/// 設定画面のプライバシーポリシーと、AI 変換の同意の取り消し
///
/// ストア提出前の監査（2026-10-18）で、アプリの中からプライバシーポリシーを開けない
/// （App Store 審査ガイドライン 5.1.1）、AI 変換の同意を取り消せない、と分かった。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_links.dart';
import 'package:kotonoha_app/features/settings/presentation/settings_screen.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// ブラウザで開く操作を受け止める（外部 SDK の境界）
class _FakeLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  _FakeLauncher({this.opens = true});

  final bool opens;
  final launched = <(String, PreferredLaunchMode)>[];

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add((url, options.mode));
    return opens;
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool consented = false,
}) async {
  SharedPreferences.setMockInitialValues({'ai_privacy_consent': consented});
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: SettingsScreen()),
  ));
  await tester.pumpAndSettle();
  return container;
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  late UrlLauncherPlatform original;
  setUp(() => original = UrlLauncherPlatform.instance);
  tearDown(() => UrlLauncherPlatform.instance = original);

  group('プライバシーポリシー', () {
    testWidgets('「その他」にあり、押すとブラウザでポリシーを開く', (tester) async {
      final launcher = _FakeLauncher();
      UrlLauncherPlatform.instance = launcher;
      await _pump(tester);

      final tile = find.text('プライバシーポリシー');
      await _scrollTo(tester, tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(launcher.launched, [
        (privacyPolicyUrl, PreferredLaunchMode.externalApplication),
      ]);
    });

    testWidgets('開けなかったときは、URL を見せる', (tester) async {
      UrlLauncherPlatform.instance = _FakeLauncher(opens: false);
      await _pump(tester);

      final tile = find.text('プライバシーポリシー');
      await _scrollTo(tester, tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();

      // 知らせ（SnackBar）の中に URL を出す（タイルの下の URL とは別に）
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining(privacyPolicyUrl),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('開けませんでした'), findsOneWidget);
    });
  });

  group('AI 変換の同意', () {
    testWidgets('同意済みなら取り消せ、取り消すと保存され、開き直しても未同意のまま', (tester) async {
      final container = await _pump(tester, consented: true);
      expect(
        container
            .read(settingsNotifierProvider)
            .requireValue
            .hasAcceptedAIPrivacyPolicy,
        isTrue,
      );

      final revoke = find.text('同意を取り消す');
      await _scrollTo(tester, revoke);
      await tester.tap(revoke);
      await tester.pumpAndSettle();
      // 誤タップで取り消さないよう、確かめてから取り消す
      await tester.tap(find.text('取り消す'));
      await tester.pumpAndSettle();

      expect(
        container
            .read(settingsNotifierProvider)
            .requireValue
            .hasAcceptedAIPrivacyPolicy,
        isFalse,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('ai_privacy_consent'), isFalse);
      expect(find.text('同意を取り消す'), findsNothing);

      // 開き直す（新しい provider が保存先から読む）
      final reopened = ProviderContainer();
      addTearDown(reopened.dispose);
      await reopened.read(settingsNotifierProvider.future);
      expect(
        reopened
            .read(settingsNotifierProvider)
            .requireValue
            .hasAcceptedAIPrivacyPolicy,
        isFalse,
      );
    });

    testWidgets('確認で「やめる」を選ぶと、同意はそのまま', (tester) async {
      final container = await _pump(tester, consented: true);
      final revoke = find.text('同意を取り消す');
      await _scrollTo(tester, revoke);
      await tester.tap(revoke);
      await tester.pumpAndSettle();
      await tester.tap(find.text('やめる'));
      await tester.pumpAndSettle();

      expect(
        container
            .read(settingsNotifierProvider)
            .requireValue
            .hasAcceptedAIPrivacyPolicy,
        isTrue,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('ai_privacy_consent'), isTrue);
    });

    testWidgets('未同意なら、取り消すボタンは出さない', (tester) async {
      await _pump(tester);
      await _scrollTo(tester, find.text('プライバシーポリシー'));
      expect(find.text('同意を取り消す'), findsNothing);
      expect(find.textContaining('まだ同意していません'), findsOneWidget);
    });
  });
}
