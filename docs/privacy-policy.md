# プライバシーポリシー / Privacy Policy

最終更新日: 2026年9月21日
Last Updated: September 21, 2026

---

## 日本語

### はじめに

本プライバシーポリシーは、「ことのは」（以下「本アプリ」）における個人情報の取り扱いについて説明します。本アプリをご利用いただく前に、本ポリシーをよくお読みください。

### 収集する情報

#### 1. ローカルに保存されるデータ

本アプリは、以下のデータをお使いの端末内に保存します。本アプリ自身がこれらのデータを外部サーバーへ送信することはありません。ただし、AI変換を実行したときは、次項に記載するデータがその経路で送信されます。

- **入力履歴**: 文字盤で入力した内容（最大50件）
- **入力中の文**: 文字盤で入力している途中の内容。アプリが終了しても入力が消えないように保存します。入力欄を空にすると削除されます
- **定型文**: ユーザーが追加したカスタム定型文
- **追加中の定型文の下書き**: 本文・カテゴリ・保存先を識別するID。文字盤の入力中の文とは別に端末内へ保存し、次に追加フォームを開くと復元します。下書きを読み込めていれば、保存成功、明示キャンセル、確認済み破棄で消去します。読み込めなかった場合や消去できなかった場合は、端末内に残ります。端末の OS のバックアップ機能を有効にしている場合は、バックアップの対象になることがあります。保存時点と終了時の限界は[サポート](./support.md)をご覧ください
- **お気に入り**: お気に入りに登録したフレーズ
- **アプリ設定**: フォントサイズ、テーマ、音声速度などの設定

#### 2. AI変換機能使用時

AI変換機能（オプション）を使用すると、以下のデータが本アプリからことのは backend に送信されます。

- **入力テキスト**: AI変換を行うテキスト
- **丁寧さレベル**: 選択した変換レベル（カジュアル/普通/丁寧）
- **前回の変換結果**: 再変換を行う場合のみ

ことのは backend は、入力テキスト（再変換時は前回の変換結果も含む）と、選択した丁寧さレベルに応じた指示を prompt に含め、設定された外部 AI provider（Anthropic または OpenAI）へ送信します。provider が生成した変換結果は、ことのは backend を経由して本アプリへ返されます。

**重要**: AI変換機能の初回使用時に、データ送信についての同意確認を行います。

#### 3. クラッシュ情報（診断データ）

**本アプリは、クラッシュ情報を、クラッシュ解析SDKなど本アプリ自身の仕組みで外部へ送信しません。**
クラッシュ解析のためのSDK（Firebase Crashlytics、Sentry等）を一切組み込んでいません。

ただし、お使いの端末のOSとアプリストアには、アプリが異常終了した際にその情報を
開発者へ提供する仕組みがあります。**この提供は、お使いの端末のOS設定で
あなたが許可した場合に限り行われます。**

- **iOS / iPadOS**: 「設定 > プライバシーとセキュリティ > 解析と改善」で
  「iPhoneの解析を共有」および「App デベロッパと共有」を有効にしている場合に限り、
  Apple 経由で開発者にクラッシュ情報が提供されます
- **Android**: 端末の設定で「使用状況と診断情報」の自動共有を有効にしている場合に限り、
  Google Play 経由で開発者にクラッシュ情報（Android vitals）が提供されます

本アプリには、文字盤で入力した内容・定型文・履歴・お気に入りをクラッシュ情報へ
意図的に添付する実装はありません。ただし、OSとアプリストアが生成する診断データの
内容は、その仕組みと設定によって決まります。提供されることがある情報には、アプリが
停止した箇所を示す技術情報（スタックトレース）、端末の機種名、OSのバージョン、
アプリのバージョンがあります。

共有するかどうかは、お使いの端末のOS設定でいつでも変更できます。
これらの仕組みの詳細は Apple および Google のプライバシーに関する説明をご確認ください。

### データの利用目的

収集したデータは、以下の目的でのみ使用されます。

- 本アプリの機能提供
- AI変換結果の生成
- ユーザー体験の向上

### データの保管

- **ローカルデータ**: お使いの端末内に保存されます。本アプリ自身がクラウドへ同期することはありません。端末の OS のバックアップ機能（Android の自動バックアップ、iOS の iCloud バックアップ）を有効にしている場合は、他のアプリのデータと同様に OS によってバックアップされ、機種変更時に復元されることがあります
- **壊れたデータの写し**: iOS・Android 版では、端末に保存されたデータのファイルが壊れていることを起動時に見つけた場合、壊れたファイルに手を加える前に、その写しを端末内に残します。写しには、それまでに保存されていた入力履歴・定型文・お気に入りが含まれることがあります（アプリ内で個別に削除した項目が含まれることもあります）。本アプリが写しを外部へ送信することはありません。OS のバックアップ機能を有効にしている場合は、ほかのローカルデータと同様にバックアップの対象になります
- **ことのは backend における AI 変換データ**: backend はデータベースを持たず、処理後に入力テキスト・前回の変換結果・変換結果を保存しません
- **外部 AI provider における AI 変換データ**: 保存期間や学習利用について、本ポリシーでは保証しません。各 provider の規約および適用される設定に従います

### データの削除

ユーザーは以下の方法でデータを削除できます。

- アプリ内の履歴画面・お気に入り画面から、履歴とお気に入りを個別または全件削除
- アプリ内の定型文画面から、定型文を個別に削除
- 定型文の追加フォームで下書きを読み込めていれば、「キャンセル」（または戻る操作で「破棄する」）で、追加中の下書きを削除。フォームを閉じるだけでは残ります
- アプリをアンインストールすることで、すべてのローカルデータが削除されます

アプリ内で削除したデータが、すでに取られた OS のバックアップに含まれている場合、その削除はバックアップには及びません。端末の復元や再インストールで戻ることがあります。

「データの保管」に記載した壊れたデータの写しは、アプリ内の削除の操作では消えません。同じ種類のデータで次に破損が見つかったときに新しい写しで置き換えられることがあり、アプリをアンインストールすると端末からは削除されます。OS のバックアップに含まれた写しは、OS 側でそのバックアップが削除されるまで残り、端末の復元や再インストールの際に戻ることがあります。

### 第三者への提供

「AI変換機能使用時」に記載した外部 AI provider への送信を除き、本アプリは、法令に基づく場合を除いてユーザーの個人情報を第三者に提供しません。

### お子様のプライバシー

本アプリは、13歳未満のお子様から意図的に個人情報を収集しません。

### プライバシーポリシーの変更

本ポリシーを変更する場合は、本ページにて通知します。重要な変更がある場合は、アプリ内でも通知します。

### お問い合わせ

プライバシーに関するご質問は、以下までお問い合わせください。

- サポートURL: https://github.com/mozuq-lab/kotonoha/issues
- メール: support@kotonoha-app.example.com

---

## English

### Introduction

This Privacy Policy explains how "Kotonoha" (hereinafter "the App") handles personal information. Please read this policy carefully before using the App.

### Information We Collect

#### 1. Data Stored Locally

The App stores the following data on your device. The App itself does not send this data to external servers, except for the data and transmission described in the next section when you choose to use AI conversion.

- **Input History**: Content entered via the keyboard (up to 50 entries)
- **Text Being Entered**: The text you are currently typing. It is saved so that it is not lost if the App closes, and it is deleted when you clear the input field
- **Preset Phrases**: Custom phrases added by the user
- **Draft preset phrase additions**: Text, category, and a save ID stored locally, separately from the character-board draft, and restored on reopening the add form. If the draft was loaded successfully, saving, explicit cancellation, or confirmed discard removes it. If it could not be loaded, or removal fails, the draft stays on your device. If you have enabled your device's OS backup, it may be included. See [Support](./support.md) for timing and termination limitations
- **Favorites**: Phrases registered as favorites
- **App Settings**: Settings such as font size, theme, and speech rate

#### 2. When Using AI Conversion

When you use the optional AI conversion feature, the following data is sent from the App to the Kotonoha backend:

- **Input Text**: Text to be converted by AI
- **Politeness Level**: Selected conversion level (Casual/Normal/Polite)
- **Previous Conversion Result**: Only when regenerating

The Kotonoha backend includes the Input Text (and the Previous Conversion Result when regenerating) and instructions based on the selected Politeness Level in a prompt sent to the configured external AI provider (Anthropic or OpenAI). The provider's Conversion Result is returned to the App through the Kotonoha backend.

**Important**: We will ask for your consent about data transmission when you first use the AI conversion feature.

#### 3. Crash Information (Diagnostic Data)

**The App does not transmit crash information through any crash-reporting mechanism of its
own.** No crash reporting SDK (such as Firebase Crashlytics or Sentry) is embedded in the App.

However, your device's operating system and app store provide a mechanism that shares
information with developers when an app terminates unexpectedly. **This sharing occurs only
if you have enabled it in your device's OS settings.**

- **iOS / iPadOS**: Crash information is provided to the developer through Apple only if
  "Share iPhone Analytics" and "Share With App Developers" are enabled under
  Settings > Privacy & Security > Analytics & Improvements
- **Android**: Crash information (Android vitals) is provided to the developer through
  Google Play only if you have opted in to automatically share usage and diagnostics data

The App does not intentionally attach text entered on the character board, preset phrases,
history, or favorites to crash information. However, the contents of diagnostic data generated
by the OS and app store depend on their mechanisms and settings. Information that may be
provided includes technical information indicating where the App stopped (a stack trace),
the device model, the OS version, and the App version.

You can change whether to share this at any time in your device's OS settings. For details,
please refer to Apple's and Google's respective privacy documentation.

### How We Use Your Data

The collected data is used only for the following purposes:

- Providing the App's functionality
- Generating AI conversion results
- Improving user experience

### Data Storage

- **Local Data**: Stored on your device. The App itself does not synchronize it to any cloud. If you have enabled your device's OS backup (Android Auto Backup or iCloud Backup), the OS may back it up and restore it on a new device, as it does for other apps
- **Copies of Damaged Data**: On iOS and Android, if the App finds at startup that a data file stored on your device is damaged, it keeps a copy of the damaged file on your device before modifying it. The copy may contain input history, preset phrases, and favorites saved up to that point, including items you had deleted individually within the App. The App never sends the copy off your device. If you have enabled your device's OS backup, the copy may be backed up in the same way as other local data
- **AI Conversion Data on the Kotonoha Backend**: The backend has no database and does not store Input Text, the Previous Conversion Result, or the Conversion Result after processing
- **AI Conversion Data at the External AI Provider**: This policy does not guarantee the provider's retention period or whether data is used for model training. These matters are governed by the provider's terms and applicable settings

### Data Deletion

Users can delete data in the following ways:

- Delete history and favorites individually or entirely, from the History and Favorites screens in the App
- Delete preset phrases individually, from the Preset Phrases screen in the App
- If the draft was loaded, delete it with Cancel in the add form (or Discard when going back); merely closing the form keeps it
- Uninstalling the app deletes all local data

If data you delete within the App is already included in an OS backup, deleting it in the App does not remove it from that backup. It may come back when you restore your device or reinstall the App.

The copies of damaged data described under "Data Storage" are not removed by deleting data within the App. A copy may be replaced by a newer one the next time damage is found in the same kind of data, and it is deleted from your device when you uninstall the App. A copy included in an OS backup remains until that backup is deleted, and may come back when you restore your device or reinstall the App.

### Sharing with Third Parties

Except for transmission to the external AI provider described under "When Using AI Conversion," the App does not share users' personal information with third parties unless required by law.

### Children's Privacy

The App does not intentionally collect personal information from children under 13 years of age.

### Changes to This Policy

If we make changes to this policy, we will notify you on this page. For significant changes, we will also notify you within the App.

### Contact Us

For privacy-related questions, please contact us:

- Support URL: https://github.com/mozuq-lab/kotonoha/issues
- Email: support@kotonoha-app.example.com
