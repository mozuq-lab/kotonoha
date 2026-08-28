# TASK-0091 iOSビルド設定 - 設定作業実行

## 作業概要

- **タスクID**: TASK-0091
- **作業内容**: iOSビルド設定・iOS 14.0対応・TestFlight配布設定
- **実行日時**: 2025-12-02
- **信頼性レベル**: 🔵 青信号（NFR-401の要件に基づく設定）

## 設計文書参照

- **参照文書**:
  - `docs/design/kotonoha/architecture.md` - プラットフォーム要件
  - `docs/spec/kotonoha-requirements.md` - NFR-401
  - `docs/tech-stack.md` - 技術スタック定義
- **関連要件**: NFR-401（iOS 14.0以上対応）

## 実行した作業

### 1. iOS Deployment Targetの更新

**変更ファイル**: `ios/Runner.xcodeproj/project.pbxproj`

```
IPHONEOS_DEPLOYMENT_TARGET = 13.0;
↓
IPHONEOS_DEPLOYMENT_TARGET = 14.0;
```

**変更理由**: NFR-401要件（iOS 14.0以上対応）への準拠

### 2. Podfileのプラットフォームバージョン更新

**変更ファイル**: `ios/Podfile`

```ruby
# Before
# platform :ios, '13.0'

# After
platform :ios, '14.0'
```

### 3. Info.plistの拡張

**変更ファイル**: `ios/Runner/Info.plist`

追加した設定:

| キー | 値 | 目的 |
|------|-----|------|
| `UIBackgroundModes` | `audio` | TTS・緊急音のバックグラウンド再生 |
| `CFBundleLocalizations` | `ja`, `en` | 多言語対応 |
| `CFBundleDevelopmentRegion` | `ja` | 日本語をプライマリ言語に |
| `NSAppTransportSecurity` | ローカルネットワーク許可 | 開発環境でのAPI接続 |
| `MinimumOSVersion` | `14.0` | 最小OSバージョン明示 |
| `NSHumanReadableCopyright` | Copyright表記 | App Store用 |

### 4. ExportOptions.plistの作成

**作成ファイル**: `ios/ExportOptions.plist`

```xml
<key>method</key>
<string>app-store</string>
<key>signingStyle</key>
<string>automatic</string>
<key>uploadBitcode</key>
<false/>
<key>uploadSymbols</key>
<true/>
```

**用途**: App Store/TestFlight配布用のIPA生成設定

### 5. ExportOptionsAdHoc.plistの作成

**作成ファイル**: `ios/ExportOptionsAdHoc.plist`

**用途**: Ad Hoc配布（内部テスト）用のIPA生成設定

### 6. ビルドスクリプトの作成

**作成ファイル**: `scripts/build-ios.sh`

```bash
# 使用例
./scripts/build-ios.sh debug           # デバッグビルド
./scripts/build-ios.sh release         # リリースビルド
./scripts/build-ios.sh --archive       # アーカイブ生成
./scripts/build-ios.sh --testflight    # TestFlight配布用
```

**機能**:
- Flutter依存関係の自動更新
- CocoaPods依存関係の自動インストール
- デバッグ/リリース/プロファイルビルドの切り替え
- IPA生成（App Store/TestFlight用）
- 難読化・シンボル分離対応

## 作業結果

- [x] iOS Deployment Target 14.0への更新完了
- [x] Podfile プラットフォーム設定更新完了
- [x] Info.plist 拡張設定完了
- [x] ExportOptions.plist作成完了（App Store用）
- [x] ExportOptionsAdHoc.plist作成完了（内部テスト用）
- [x] ビルドスクリプト作成完了

## 環境依存事項

### 必要な開発環境（CI/CD含む）

| ツール | 要件 | 用途 |
|--------|------|------|
| Xcode | 14.0以上 | iOSビルド・アーカイブ |
| CocoaPods | 最新版 | iOS依存関係管理 |
| Apple Developer Account | 有効なアカウント | 証明書・プロビジョニング |
| App Store Connect | セットアップ済み | TestFlight/App Store配布 |

### 環境変数（CI/CD用）

```bash
# Apple Developer関連（オプション：自動署名の場合は不要）
APPLE_TEAM_ID=XXXXXXXXXX
APPLE_ID=developer@example.com
APP_SPECIFIC_PASSWORD=xxxx-xxxx-xxxx-xxxx  # altoolアップロード用
```

## 遭遇した問題と解決方法

### 問題1: CocoaPodsが未インストール

- **発生状況**: ビルドテスト時にCocoaPodsが見つからない
- **エラーメッセージ**: `CocoaPods not installed. Skipping pod install.`
- **解決方法**:
  1. 開発環境では `gem install cocoapods` でインストール
  2. CI/CD環境では設定済み（GitHub Actions macos-latest標準）
- **影響**: 設定作業自体には影響なし（環境依存）

## 次のステップ

1. `/tsumiki:direct-verify` を実行して設定を確認
2. CocoaPodsインストール後にビルドテストを再実行
3. 実機テスト（TASK-0095）の準備

## ファイル変更一覧

| ファイル | 変更種別 |
|----------|----------|
| `ios/Runner.xcodeproj/project.pbxproj` | 更新 |
| `ios/Podfile` | 更新 |
| `ios/Runner/Info.plist` | 更新 |
| `ios/ExportOptions.plist` | 新規作成 |
| `ios/ExportOptionsAdHoc.plist` | 新規作成 |
| `scripts/build-ios.sh` | 新規作成 |

## 備考

- iOS 14.0以上を必須としたため、iOS 13.x以前の端末はサポート対象外
- TestFlight配布にはApple Developer Program登録（年間$99）が必要
- App Store審査ガイドラインへの準拠は別途確認が必要
