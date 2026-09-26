# ストアアセットガイド / Store Assets Guide

このドキュメントは、App Store / Google Play への申請に必要なアセット（スクリーンショット、アイコン等）の要件と準備方法をまとめたものです。

---

## 1. アプリアイコン

### App Store（iOS）

| サイズ | 用途 |
|--------|------|
| 1024x1024 | App Store |
| 180x180 | iPhone（@3x） |
| 120x120 | iPhone（@2x） |
| 167x167 | iPad Pro |
| 152x152 | iPad |
| 76x76 | iPad（@1x） |

### Google Play（Android）

| サイズ | 用途 |
|--------|------|
| 512x512 | Play Store |
| 192x192 | xxxhdpi |
| 144x144 | xxhdpi |
| 96x96 | xhdpi |
| 72x72 | hdpi |
| 48x48 | mdpi |

### アイコンデザイン要件

- **形状**: 角丸正方形（iOS自動適用）、Adaptive Icon対応（Android）
- **背景**: 単色または控えめなグラデーション
- **シンボル**: 「言葉」「コミュニケーション」を表すシンプルなデザイン
- **色**: アクセシビリティを考慮した明確なコントラスト
- **テキスト**: 含めないことを推奨

---

## 2. スクリーンショット

### App Store（iOS）要件

#### 必須サイズ

| デバイス | サイズ（ポートレート） | 撮るシミュレータ |
|----------|------------------------|------------------|
| iPhone 6.9インチ | 1320 x 2868 | iPhone 17 Pro Max |
| iPad 13インチ | 2064 x 2752 | iPad Pro 13-inch (M5) |

iPhone と iPad の両方に対応している（`TARGETED_DEVICE_FAMILY = "1,2"`）ので、両方が要る。

#### 枚数
- 最小: 1枚
- 最大: 10枚
- 推奨: 5〜8枚

### Google Play（Android）要件

| サイズ | 用途 |
|--------|------|
| 1080 x 1920 | スマートフォン（長辺は短辺の 2 倍まで。1080 x 2400 は受け付けられない） |
| 最小 320px | タブレット（7インチ） |
| 1200 x 1920 推奨 | タブレット（10インチ） |

#### 枚数
- 最小: 2枚
- 最大: 8枚
- 推奨: 4〜8枚

### 推奨スクリーンショット一覧

以下のスクリーンショットを準備することを推奨します：

1. **文字盤画面** - 五十音文字盤のメイン画面
2. **定型文一覧** - カテゴリ別の定型文表示
3. **大ボタン** - 「はい」「いいえ」ボタンの表示
4. **状態ボタン** - 「痛い」「トイレ」などのボタン
5. **対面表示モード** - 180度回転した表示
6. **設定画面** - テーマ・フォントサイズ設定
7. **AI変換** - AI変換結果の表示（オプション）

### スクリーンショット作成ガイドライン

- **デバイスフレームなし**: Apple/Googleの審査ガイドラインに準拠
- **実際の画面**: モックアップではなく実際のアプリ画面
- **ステータスバー**: 必要に応じて非表示
- **データ**: ダミーデータを使用（個人情報を含めない）
- **テキストオーバーレイ**: 機能説明のテキストを追加可能

---

## 3. フィーチャーグラフィック（Google Play）

| サイズ | 用途 |
|--------|------|
| 1024 x 500 | フィーチャーグラフィック（必須） |

### デザイン要件
- アプリの主要機能を視覚的に表現
- テキストは最小限に
- ブランドカラーを使用
- 高コントラストで視認性を確保

---

## 4. プロモーション動画（オプション）

### App Store
- 形式: MOV, M4V, MP4
- 長さ: 15〜30秒
- 解像度: スクリーンショットと同じサイズ

### Google Play
- YouTube動画URLを指定
- 長さ: 30秒〜2分推奨
- 解像度: 1920x1080以上

---

## 5. アセット準備チェックリスト

### iOS（App Store Connect）

- [ ] アプリアイコン 1024x1024
- [ ] iPhone スクリーンショット（6.7インチ）× 5-8枚
- [ ] iPad スクリーンショット（12.9インチ）× 5-8枚
- [ ] App Preview（プロモーション動画）（オプション）

### Android（Google Play Console）

- [ ] アプリアイコン 512x512
- [ ] フィーチャーグラフィック 1024x500
- [ ] スマートフォンスクリーンショット × 4-8枚
- [ ] タブレットスクリーンショット × 4-8枚（推奨）
- [ ] プロモーション動画（オプション）

---

## 6. アセット生成ツール

### アプリアイコン生成

```bash
# flutter_launcher_icons パッケージを使用
flutter pub run flutter_launcher_icons:main
```

`pubspec.yaml` に以下を追加:

```yaml
flutter_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

### スクリーンショット取得

撮影用の結合テスト（`integration_test/store/store_screenshots_test.dart`）が、本物のアプリを操作して
6 枚（ホーム・対面表示・定型文・履歴・お気に入り・設定）を `build/screenshots/` に書く。
撮った画像は `fastlane/screenshots/ja-JP/<端末>/` に置く。

```bash
cd frontend/kotonoha_app
# iOS（シミュレータを起動しておく）
fvm flutter drive -d <シミュレータの id> \
  --driver=test_driver/screenshot_driver.dart \
  --target=integration_test/store/store_screenshots_test.dart
# Android（エミュレータの画面を 1080x1920 にしてから撮り、戻す）
adb shell wm size 1080x1920
fvm flutter drive -d emulator-5554 --flavor production \
  --driver=test_driver/screenshot_driver.dart \
  --target=integration_test/store/store_screenshots_test.dart
adb shell wm size reset
```

---

## 7. 注意事項

1. **著作権**: すべてのアセットは自作または使用許諾を得たものを使用
2. **審査ガイドライン**: 各プラットフォームの最新ガイドラインを確認
3. **更新**: アプリ更新時はスクリーンショットも適宜更新
4. **ローカライズ**: 日本語・英語両方のスクリーンショットを準備
