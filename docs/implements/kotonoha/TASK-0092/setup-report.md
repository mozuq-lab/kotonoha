# TASK-0092 Androidビルド設定 - 設定作業実行

## 作業概要

- **タスクID**: TASK-0092
- **作業内容**: Androidビルド設定・Android 10以上対応・Google Play配布設定
- **実行日時**: 2025-12-02
- **信頼性レベル**: 🔵 青信号（NFR-401の要件に基づく設定）

## 設計文書参照

- **参照文書**:
  - `docs/design/kotonoha/architecture.md` - プラットフォーム要件
  - `docs/spec/kotonoha-requirements.md` - NFR-401
  - `docs/tech-stack.md` - 技術スタック定義
- **関連要件**: NFR-401（Android 10以上対応）

## 実行した作業

### 1. build.gradle.kts の更新

**変更ファイル**: `android/app/build.gradle.kts`

**変更内容**:
| 設定項目 | 変更前 | 変更後 |
|---------|--------|--------|
| minSdk | flutter.minSdkVersion (21) | 29 (Android 10) |
| targetSdk | flutter.targetSdkVersion | flutter.targetSdkVersion (変更なし) |
| isMinifyEnabled (release) | なし | true |
| isShrinkResources (release) | なし | true |
| ProGuard | なし | proguard-rules.pro |

**追加設定**:
- signingConfigs: key.propertiesからリリース署名設定を読み込み
- productFlavors: production / internal の2種類
- bundle: AAB分割設定（言語/密度/ABI）
- lint: エラー時ビルド中止しない設定

### 2. ProGuardルールファイルの作成

**作成ファイル**: `android/app/proguard-rules.pro`

**設定内容**:
- Flutter固有のクラス保持
- flutter_ttsプラグインの保持
- audioplayersプラグインの保持
- Hiveローカルストレージの保持
- リリースビルドでのログ削除
- デバッグ情報の保持（クラッシュレポート用）

### 3. key.propertiesテンプレートの作成

**作成ファイル**: `android/key.properties.example`

**設定内容**:
```properties
storeFile=keystore/release.keystore
storePassword=your_keystore_password
keyAlias=kotonoha
keyPassword=your_key_password
```

### 4. AndroidManifest.xml の拡張

**変更ファイル**: `android/app/src/main/AndroidManifest.xml`

**追加設定**:
| 設定 | 値 | 目的 |
|------|-----|------|
| INTERNET | permission | AI変換API通信 |
| ACCESS_NETWORK_STATE | permission | ネットワーク状態確認 |
| android.software.tts | feature | TTS対応表示 |
| allowBackup | true | データバックアップ許可 |
| fullBackupContent | @xml/backup_rules | バックアップ対象制御 |
| enableOnBackInvokedCallback | true | Android 13+戻るジェスチャー対応 |

### 5. 多言語リソースの作成

**作成ファイル**:
- `res/values/strings.xml` - 英語（デフォルト）
- `res/values-ja/strings.xml` - 日本語

**設定内容**:
- app_name: kotonoha / ことのは
- app_description: アプリ説明文

### 6. バックアップルールの作成

**作成ファイル**: `res/xml/backup_rules.xml`

**設定内容**:
- SharedPreferences: バックアップ対象
- Hiveデータベース: バックアップ除外（プライバシー保護）
- キャッシュ: バックアップ除外

### 7. ビルドスクリプトの作成

**作成ファイル**: `scripts/build-android.sh`

**機能**:
```bash
./scripts/build-android.sh debug      # デバッグAPK
./scripts/build-android.sh release    # リリースAPK（難読化付き）
./scripts/build-android.sh bundle     # AAB（Google Play用）
./scripts/build-android.sh internal   # 内部テストAPK
./scripts/build-android.sh clean      # クリーン
```

## 作業結果

- [x] build.gradle.kts のminSdk 29への更新完了
- [x] ProGuardルール作成完了
- [x] key.propertiesテンプレート作成完了
- [x] AndroidManifest.xml 拡張完了
- [x] 多言語リソース作成完了
- [x] バックアップルール作成完了
- [x] ビルドスクリプト作成完了
- [x] Gradle設定構文検証成功

## 環境依存事項

### 必要な開発環境（CI/CD含む）

| ツール | 要件 | 用途 |
|--------|------|------|
| Flutter SDK | 3.38+ | ビルド |
| Java JDK | 11以上 | Gradleビルド |
| Android SDK | API 29以上 | ターゲットプラットフォーム |
| Gradle | 8.12 | ビルドシステム |

### 環境変数（CI/CD用）

key.propertiesの代わりにGitHub Secretsを使用:
```bash
ANDROID_KEYSTORE_BASE64     # Base64エンコードしたキーストア
ANDROID_KEYSTORE_PASSWORD   # キーストアパスワード
ANDROID_KEY_ALIAS           # キーエイリアス
ANDROID_KEY_PASSWORD        # キーパスワード
```

## 遭遇した問題と解決方法

### 問題1: java.util.Properties参照エラー

- **発生状況**: Gradle構文チェック時
- **エラーメッセージ**: `Unresolved reference: util`
- **解決方法**: ファイル先頭に`import java.util.Properties`を追加
- **影響**: 解決済み、Flutterビルド成功

## 次のステップ

1. `/tsumiki:direct-verify` を実行して設定を確認
2. TASK-0093（Webビルド設定）の実行
3. TASK-0094（CI/CDパイプライン構築）でAndroidビルドジョブを設定
4. TASK-0095（実機テスト）でAndroid実機動作確認

## ファイル変更一覧

| ファイル | 変更種別 |
|----------|----------|
| `android/app/build.gradle.kts` | 更新 |
| `android/app/proguard-rules.pro` | 新規作成 |
| `android/key.properties.example` | 新規作成 |
| `android/app/src/main/AndroidManifest.xml` | 更新 |
| `android/app/src/main/res/values/strings.xml` | 新規作成 |
| `android/app/src/main/res/values-ja/strings.xml` | 新規作成 |
| `android/app/src/main/res/xml/backup_rules.xml` | 新規作成 |
| `scripts/build-android.sh` | 新規作成 |

## 備考

- Android 10以上を必須としたため、Android 9以前の端末はサポート対象外
- Google Play配布にはDeveloperアカウント（$25一回払い）が必要
- 内部テスト配布はplay consoleセットアップ後に可能
