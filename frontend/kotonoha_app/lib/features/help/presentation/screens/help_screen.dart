/// ヘルプ画面ウィジェット
///
/// TASK-0075: ヘルプ画面・初回チュートリアル実装
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
/// 関連要件:
/// - REQ-3001: 初回起動時の簡易チュートリアル/ヘルプ画面表示
/// - NFR-205: ガイド付きアクセス/画面ピン留めの設定方法説明
library;

import 'package:flutter/material.dart';

import '../widgets/help_section_widget.dart';

/// ヘルプ画面ウィジェット
///
/// アプリケーションの使い方を説明するヘルプ画面。
/// 基本操作、機能説明、誤操作防止設定の説明を提供する。
///
/// 実装機能:
/// - 基本操作の説明（文字盤、定型文、TTS）
/// - 緊急ボタンの使い方
/// - iOS/Androidの誤操作防止設定方法（NFR-205）
///
/// 実装要件:
/// - FR-003: ルートパス「/help」でこの画面を表示
/// - FR-005: StatelessWidget、constコンストラクタ、keyパラメータ
/// - NFR-205: ガイド付きアクセス/画面ピン留め設定説明
class HelpScreen extends StatelessWidget {
  /// ヘルプ画面を作成する。
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('使い方'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 【基本操作セクション】
            HelpSectionWidget(
              title: '基本操作',
              icon: Icons.touch_app,
              children: [
                _HelpItem(
                  title: '文字盤で入力',
                  description: '五十音の文字盤をタップして文字を入力します。'
                      '入力した文字は上部のテキストエリアに表示されます。',
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

            // 【緊急ボタンセクション】
            HelpSectionWidget(
              title: '緊急ボタン',
              icon: Icons.warning_amber,
              children: [
                _HelpItem(
                  title: '緊急時の使い方',
                  description: '画面右下の赤い緊急ボタンを押すと、'
                      '確認ダイアログが表示されます。'
                      '「はい」を押すと緊急アラート画面に移動し、'
                      '音と画面で周囲に助けを求めることができます。',
                ),
              ],
            ),

            // 【便利な機能セクション】
            HelpSectionWidget(
              title: '便利な機能',
              icon: Icons.lightbulb_outline,
              children: [
                _HelpItem(
                  title: '対面表示モード',
                  description: '画面を180度回転させて、'
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
                  description: '過去に入力したテキストは履歴に保存されます。'
                      'よく使うものはお気に入りに登録できます。',
                ),
              ],
            ),

            // 【誤操作防止設定セクション】: NFR-205
            HelpSectionWidget(
              title: '誤操作防止の設定',
              icon: Icons.security,
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

            // 【設定セクション】
            HelpSectionWidget(
              title: '設定について',
              icon: Icons.settings,
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
          ],
        ),
      ),
    );
  }
}

/// ヘルプ項目ウィジェット
///
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
