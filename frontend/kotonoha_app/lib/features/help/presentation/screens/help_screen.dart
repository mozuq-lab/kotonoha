/// ヘルプ画面ウィジェット
/// 初回起動時の簡易チュートリアル/ヘルプ画面表示
/// ガイド付きアクセス/画面ピン留めの設定方法説明
library;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/help/providers/tutorial_provider.dart';
import '../widgets/help_section_widget.dart';

/// ヘルプ画面ウィジェット
/// アプリケーションの使い方を説明するヘルプ画面。
/// 基本操作、機能説明、誤操作防止設定の説明を提供する。
/// 実装機能
/// 基本操作の説明（文字盤、定型文、TTS）
/// iOS/Androidの誤操作防止設定方法
/// チュートリアルの再表示導線（fix/improvement-p0-p2で配線）
/// 実装要件
/// ルートパス「/help」でこの画面を表示
/// ConsumerWidget、constコンストラクタ、keyパラメータ
/// ガイド付きアクセス/画面ピン留め設定説明
/// 初回チュートリアルをいつでも再表示できる導線
class HelpScreen extends ConsumerWidget {
  /// ヘルプ画面を作成する。
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('使い方'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基本操作セクション
            const HelpSectionWidget(
              title: '基本操作',
              icon: CupertinoIcons.hand_draw,
              children: [
                _HelpItem(
                  title: '文字盤で入力',
                  description: '五十音の文字盤をタップするか、上部の入力欄を押してキーボードで文字を入力します。'
                      '入力欄の文は、横のハートからお気に入りに登録できます。',
                ),
                SizedBox(height: 16),
                _HelpItem(
                  title: '定型文を使う',
                  description: '「定型文」タブを選択すると、'
                      'よく使う言葉をすばやく入力できます。'
                      '自分で追加することもできます。',
                ),
                SizedBox(height: 16),
                _HelpItem(
                  title: '読み上げボタン',
                  description: '入力したテキストを音声で読み上げます。'
                      '話し相手にメッセージを伝えるのに便利です。',
                ),
              ],
            ),

            // 便利な機能セクション
            const HelpSectionWidget(
              title: '便利な機能',
              icon: CupertinoIcons.lightbulb,
              children: [
                _HelpItem(
                  title: '対面表示モード',
                  description: '画面右上のアイコンをタップすると、'
                      '入力中のテキストを大きく表示できます。'
                      '画面を180度回転させて、'
                      '向かい合った相手にテキストを見せることができます。',
                ),
                SizedBox(height: 16),
                _HelpItem(
                  title: 'AI変換',
                  description: '入力したテキストを、'
                      '丁寧な表現に自動変換できます。'
                      '（インターネット接続が必要です）',
                ),
                SizedBox(height: 16),
                _HelpItem(
                  title: '履歴とお気に入り',
                  description: '読み上げた文は履歴に保存されます。'
                      'よく使う文はお気に入りに登録し、色や並び順を変えられます。'
                      '先頭の8件はホーム画面にも表示されます。',
                ),
              ],
            ),

            // 誤操作防止設定セクション
            const HelpSectionWidget(
              title: '誤操作防止の設定',
              icon: CupertinoIcons.shield,
              children: [
                _HelpItem(
                  title: 'iOSの場合（ガイド付きアクセス）',
                  description: '「設定」→「アクセシビリティ」→'
                      '「ガイド付きアクセス」をオンにします。\n'
                      'アプリ使用中にサイドボタンを3回押すと、'
                      '他のアプリへの切り替えを防止できます。\n'
                      '終了時は再度3回押してパスコードを入力します。',
                ),
                SizedBox(height: 16),
                _HelpItem(
                  title: 'Androidの場合（画面ピン留め）',
                  description: '「設定」→「セキュリティ」→'
                      '「画面ピン留め」をオンにします。\n'
                      '最近使ったアプリ画面でこのアプリのアイコンを'
                      'タップし「ピン留め」を選択します。\n'
                      '解除は「戻る」と「最近」ボタンを長押しします。',
                ),
              ],
            ),

            // 設定セクション
            const HelpSectionWidget(
              title: '設定について',
              icon: CupertinoIcons.gear_alt,
              children: [
                _HelpItem(
                  title: '文字サイズ・テーマ',
                  description: '設定画面から文字サイズ（小/中/大）や'
                      'テーマ（ライト/ダーク/高コントラスト）を'
                      '変更できます。',
                ),
                SizedBox(height: 16),
                _HelpItem(
                  title: '読み上げ速度',
                  description: '読み上げの速さを'
                      '「遅い」「普通」「速い」から選べます。',
                ),
              ],
            ),

            // チュートリアルセクション
            // 初回起動時に表示されるチュートリアルを、いつでも再度見られる導線。
            HelpSectionWidget(
              title: 'チュートリアル',
              icon: CupertinoIcons.book,
              children: [
                const _HelpItem(
                  title: '基本の使い方をもう一度確認する',
                  description: '初回起動時に表示された簡単な使い方の説明を、'
                      'いつでも見返すことができます。',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: AppSizes.minTapTarget,
                  child: ElevatedButton(
                    onPressed: () => _showTutorialAgain(context, ref),
                    child: const Text('チュートリアルをもう一度見る'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// チュートリアルを未完了状態に戻し、ホーム画面へ戻って再表示させる。
  /// チュートリアル表示自体はAppShellがtutorialProviderの状態を監視して
  /// 行うため、ここではリセットして前の画面（多くの場合ホーム画面）へ
  /// 戻るだけでよい。
  Future<void> _showTutorialAgain(BuildContext context, WidgetRef ref) async {
    await ref.read(tutorialProvider.notifier).resetTutorial();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// ヘルプ項目ウィジェット
/// タイトルと説明文を表示するシンプルなヘルプ項目。
class _HelpItem extends StatelessWidget {
  /// タイトル
  final String title;

  /// 説明文
  final String description;

  /// コンストラクタ
  const _HelpItem({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
