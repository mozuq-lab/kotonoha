/// Settings screen widget
///
/// TASK-0015: go_routerナビゲーション設定・ルーティング実装
/// TASK-0049: TTS速度設定（遅い/普通/速い）
/// TASK-0071: 設定画面UI実装（セクション分け）
/// TASK-0075: ヘルプ画面・初回チュートリアル実装
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kotonoha_app/core/router/app_router.dart';
import 'widgets/settings_section_widget.dart';
import 'widgets/font_size_settings_widget.dart';
import 'widgets/theme_settings_widget.dart';
import 'widgets/tts_speed_settings_widget.dart';
import 'widgets/ai_politeness_settings_widget.dart';

/// 設定画面ウィジェット
///
/// アプリケーションの設定を管理する画面。
/// セクション分けされた設定項目を提供する。
///
/// 実装機能:
/// - 表示設定: フォントサイズ、テーマ
/// - 音声設定: TTS速度
/// - AI設定: 丁寧さレベル
///
/// 実装要件:
/// - FR-003: ルートパス「/settings」でこの画面を表示
/// - FR-005: StatelessWidget、constコンストラクタ、keyパラメータ
/// - REQ-801: フォントサイズを3段階から選択可能
/// - REQ-803: テーマを3種類から選択可能
/// - REQ-404: TTS速度を3段階から選択可能
/// - REQ-903: AI丁寧さレベルを3段階から選択可能
class SettingsScreen extends StatelessWidget {
  /// 設定画面を作成する。
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 【表示設定セクション】: REQ-801, REQ-803
            const SettingsSectionWidget(
              title: '表示設定',
              children: [
                FontSizeSettingsWidget(),
                SizedBox(height: 16),
                ThemeSettingsWidget(),
              ],
            ),
            // 【音声設定セクション】: REQ-404
            const SettingsSectionWidget(
              title: '音声設定',
              children: [
                TTSSpeedSettingsWidget(),
              ],
            ),
            // 【AI設定セクション】: REQ-903
            const SettingsSectionWidget(
              title: 'AI設定',
              children: [
                AIPolitenessSettingsWidget(),
              ],
            ),
            // 【その他セクション】: REQ-3001, NFR-205
            SettingsSectionWidget(
              title: 'その他',
              children: [
                _HelpListTile(
                  onTap: () => context.push(AppRoutes.help),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ヘルプ画面へのリンクタイル
class _HelpListTile extends StatelessWidget {
  final VoidCallback onTap;

  const _HelpListTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.help_outline),
      title: const Text('使い方'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
