/// Quick Response Feature バレルエクスポート
///
/// TASK-0043: 「はい」「いいえ」「わからない」大ボタン実装
///
/// クイック応答機能の全コンポーネントをまとめてエクスポート。
///
/// 使用例:
/// ```dart
/// import 'package:kotonoha_app/features/quick_response/quick_response.dart';
///
/// // ドメイン層
/// QuickResponseType.yes.label; // 'はい'
/// QuickResponseConstants.debounceDurationMs; // 300
///
/// // プレゼンテーション層
/// QuickResponseButton(responseType: QuickResponseType.yes, ...);
/// QuickResponseButtons(onResponse: (type) => ..., ...);
/// ```
library;

export 'domain/domain.dart';
export 'presentation/presentation.dart';
