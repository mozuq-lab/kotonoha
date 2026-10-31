/// アプリの言語が日本語であること（端末の言語に依らない）
///
/// 以前は `MaterialApp.router` に言語を渡していなかったので、アプリの言語は
/// 既定の英語（en_US）だった。Flutter はアプリの言語を
/// `PlatformDispatcher.setApplicationLocale` で OS に伝え、iOS の VoiceOver は
/// それを読み上げの言語に使う。物理 iPad の VoiceOver で、日本語のボタン名が
/// 英語の声でおかしな発音に読まれた（2026-10-17）。文言はすべて日本語なので、
/// 端末が英語でも日本語に固定する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/app.dart';
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _japanese = Locale('ja', 'JP');

void main() {
  testWidgets('端末が英語でも、アプリの言語は日本語で、OS にも日本語と伝える', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    // 前のテストの値を引き継がない
    tester.platformDispatcher.applicationLocale = null;
    SharedPreferences.setMockInitialValues({'tutorial_completed': true});

    await tester.pumpWidget(const ProviderScope(child: KotonohaApp()));
    await tester.pumpAndSettle();

    // VoiceOver の読み上げの言語になる値（OS へ渡る値）
    expect(tester.platformDispatcher.applicationLocale, _japanese,
        reason: 'OS に日本語と伝えていない（VoiceOver が英語の声で読む）');
    final context = tester.element(find.byType(HomeScreen));
    expect(Localizations.localeOf(context), _japanese);
    // Material の既定の文言（戻るボタンなど）も日本語になる
    expect(MaterialLocalizations.of(context).backButtonTooltip, '戻る');
  });
}
