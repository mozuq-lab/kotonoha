/// Error screen widget for navigation errors
///
/// TASK-0015: go_routerナビゲーション設定・ルーティング実装
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kotonoha_app/core/router/app_router.dart';

/// エラー画面ウィジェット
///
/// 存在しないルートへのアクセス時に表示される画面。
/// ユーザーがホーム画面へ復帰できるボタンを提供する。
///
/// 実装要件:
/// - FR-004: 存在しないルートへのアクセス時にエラー画面を表示
/// - FR-005: StatelessWidget、constコンストラクタ、keyパラメータ
/// - NFR-204: 分かりやすい日本語でエラーメッセージを表示
/// - アクセシビリティ: タップターゲット44px以上
class ErrorScreen extends StatelessWidget {
  /// エラー画面を作成する。
  ///
  /// [error] - このナビゲーションエラーの原因となった例外。
  /// 不明なエラーの場合はnullになる可能性がある。
  const ErrorScreen({
    super.key,
    required this.error,
  });

  /// ナビゲーションエラーの原因となった例外
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('エラー'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'エラーが発生しました',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ページが見つかりません',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              // タップターゲット48px以上を確保（推奨サイズ）
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.home),
                  icon: const Icon(Icons.home),
                  label: const Text('ホームに戻る'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
