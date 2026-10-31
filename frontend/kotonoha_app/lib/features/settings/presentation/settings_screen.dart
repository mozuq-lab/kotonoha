/// Settings screen widget
library;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:kotonoha_app/core/constants/app_links.dart';
import 'package:kotonoha_app/core/router/app_router.dart';
import 'package:kotonoha_app/core/utils/spoken_label.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/shared/widgets/confirmation_dialog.dart';
import 'widgets/settings_section_widget.dart';
import 'widgets/font_size_settings_widget.dart';
import 'widgets/theme_settings_widget.dart';
import 'widgets/tts_speed_settings_widget.dart';
import 'widgets/tts_voice_settings_widget.dart';
import 'widgets/ai_politeness_settings_widget.dart';
import 'widgets/simple_mode_settings_widget.dart';

/// 設定画面ウィジェット
/// アプリケーションの設定を管理する画面。
/// セクション分けされた設定項目を提供する。
/// 実装機能
/// 表示設定: フォントサイズ、テーマ
/// 音声設定: TTS速度、読み上げの声
/// AI設定: 丁寧さレベル
/// 実装要件
/// ルートパス「/settings」でこの画面を表示
/// StatelessWidget、constコンストラクタ、keyパラメータ
/// フォントサイズを3段階から選択可能
/// テーマを3種類から選択可能
/// TTS速度を4段階から選択可能
/// AI丁寧さレベルを3段階から選択可能
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
            // 表示設定セクション
            const SettingsSectionWidget(
              title: '表示設定',
              children: [
                FontSizeSettingsWidget(),
                SizedBox(height: 16),
                ThemeSettingsWidget(),
                SizedBox(height: 16),
                SimpleModeSettingsWidget(),
              ],
            ),
            // 音声設定セクション
            const SettingsSectionWidget(
              title: '音声設定',
              children: [
                TTSSpeedSettingsWidget(),
                SizedBox(height: 16),
                TTSVoiceSettingsWidget(),
              ],
            ),
            // AI設定セクション
            const SettingsSectionWidget(
              title: 'AI設定',
              children: [
                AIPolitenessSettingsWidget(),
                SizedBox(height: 16),
                _AIConsentSetting(),
              ],
            ),
            // その他セクション
            SettingsSectionWidget(
              title: 'その他',
              children: [
                _HelpListTile(
                  onTap: () => context.push(AppRoutes.help),
                ),
                const _PrivacyPolicyListTile(),
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
      leading: const Icon(CupertinoIcons.question_circle),
      title: const Text('使い方'),
      trailing: const Icon(CupertinoIcons.chevron_right),
      onTap: onTap,
    );
  }
}

/// プライバシーポリシーを開くタイル。App Store 審査ガイドライン 5.1.1 は、アプリの
/// 中のすぐ開ける場所にポリシーへの入口を求める（ストア提出前の監査、2026-10-18）
class _PrivacyPolicyListTile extends StatelessWidget {
  const _PrivacyPolicyListTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(CupertinoIcons.lock_shield),
      title: const Text('プライバシーポリシー'),
      subtitle: const Text(privacyPolicyUrl),
      trailing: const Icon(CupertinoIcons.arrow_up_right_square),
      onTap: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(privacyPolicyUrl),
        mode: LaunchMode.externalApplication,
      );
    } on Exception {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(const SnackBar(
        content: Text('ブラウザで開けませんでした。次の URL を開いてください: $privacyPolicyUrl'),
      ));
    }
  }
}

/// AI 変換の利用の同意。同意済みなら取り消せる（取り消すと、次に AI 変換を
/// 使うときにもう一度確認する）。これまで一度同意すると取り消せなかった
/// （ストア提出前の監査、2026-10-18）
class _AIConsentSetting extends ConsumerWidget {
  const _AIConsentSetting();

  static const _title = 'AI変換の利用の同意';
  static const _consented = '同意済みです。取り消すと、次にAI変換を使うときに、もう一度確認します。';
  static const _notYet = 'まだ同意していません。初めてAI変換を使うときに確認します。';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consented = ref
            .watch(settingsNotifierProvider)
            .asData
            ?.value
            .hasAcceptedAIPrivacyPolicy ??
        false;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _title,
          semanticsLabel: spokenLabel(_title),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          consented ? _consented : _notYet,
          semanticsLabel: spokenLabel(consented ? _consented : _notYet),
          style: theme.textTheme.bodyMedium,
        ),
        if (consented) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _revoke(context, ref),
            child: const Text('同意を取り消す'),
          ),
        ],
      ],
    );
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => ConfirmationDialog(
            title: '同意を取り消しますか',
            message: 'AI変換の利用の同意を取り消します。'
                '取り消した後は、AI変換を使うときに、もう一度確認します。',
            cancelLabel: 'やめる',
            confirmLabel: '取り消す',
            kind: ConfirmKind.normal,
            onCancel: () => Navigator.of(dialogContext).pop(false),
            onConfirm: () => Navigator.of(dialogContext).pop(true),
          ),
        ) ??
        false;
    if (confirmed) {
      await ref
          .read(settingsNotifierProvider.notifier)
          .setAIPrivacyConsent(false);
    }
  }
}
