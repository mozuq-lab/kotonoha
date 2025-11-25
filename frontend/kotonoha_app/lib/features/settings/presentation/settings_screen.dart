/// Settings screen widget
///
/// TASK-0015: go_routerナビゲーション設定・ルーティング実装
/// TASK-0049: TTS速度設定（遅い/普通/速い）
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
library;

import 'package:flutter/material.dart';
import 'widgets/tts_speed_settings_widget.dart';

/// 設定画面ウィジェット
///
/// アプリケーションの設定を管理する画面。
///
/// 実装機能:
/// - TTS速度設定（遅い/普通/速い）
///
/// 実装要件:
/// - FR-003: ルートパス「/settings」でこの画面を表示
/// - FR-005: StatelessWidget、constコンストラクタ、keyパラメータ
/// - REQ-404: 読み上げ速度を「遅い」「普通」「速い」の3段階から選択
class SettingsScreen extends StatelessWidget {
  /// 設定画面を作成する。
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 【TTS速度設定】: TASK-0049で実装
            // 【機能概要】: 読み上げ速度を3段階（遅い/普通/速い）から選択
            // 🔵 青信号: REQ-404（TTS速度設定）に基づく
            TTSSpeedSettingsWidget(),
            SizedBox(height: 24),
            // 今後、他の設定項目を追加予定
          ],
        ),
      ),
    );
  }
}
