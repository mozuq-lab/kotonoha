/// Status Buttons Feature バレルエクスポート
/// 状態ボタン機能の全コンポーネントをまとめてエクスポート。
/// 使用例
/// ```dart
/// import 'package:kotonoha_app/features/status_buttons/status_buttons.dart';
/// ドメイン層
/// StatusButtonType.pain.label; // '痛い'
/// プレゼンテーション層
/// StatusButton(statusType: StatusButtonType.pain, ...);
/// StatusButtons(onStatus: (type) => ..., ...);
/// ```
library;

export 'domain/domain.dart';
export 'presentation/presentation.dart';
