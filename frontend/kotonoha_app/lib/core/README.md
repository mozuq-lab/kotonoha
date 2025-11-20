# Core

アプリケーション全体で共有される基盤コンポーネントを格納するディレクトリです。

## ディレクトリ構成

### constants/
アプリケーション全体で使用される定数を定義します。

- `app_colors.dart`: カラーパレット定義（ライト/ダーク/高コントラスト）
- `app_text_styles.dart`: テキストスタイル定義
- `app_sizes.dart`: サイズ定数（タップターゲット、フォントサイズ、余白など）

### themes/
Material Designテーマ設定を定義します。

- `light_theme.dart`: ライトモードテーマ
- `dark_theme.dart`: ダークモードテーマ
- `high_contrast_theme.dart`: 高コントラストモード（WCAG 2.1 AA準拠）

### router/
アプリケーションのルーティング設定を管理します。

- `app_router.dart`: go_routerを使用したルーティング設定（TASK-0015で実装予定）

### utils/
ユーティリティ関数・クラスを格納します。

- `logger.dart`: ロギングユーティリティ（TASK-0018で実装予定）

## 使用方法

### カラーの使用例
```dart
import 'package:kotonoha_app/core/constants/app_colors.dart';

Container(
  color: AppColors.primaryLight,
)
```

### サイズの使用例
```dart
import 'package:kotonoha_app/core/constants/app_sizes.dart';

SizedBox(
  width: AppSizes.recommendedTapTarget,
  height: AppSizes.recommendedTapTarget,
)
```

### テーマの適用
```dart
import 'package:kotonoha_app/core/themes/light_theme.dart';

MaterialApp(
  theme: lightTheme,
)
```
