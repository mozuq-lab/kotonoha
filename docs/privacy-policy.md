# プライバシーポリシー / Privacy Policy

最終更新日: 2026年10月31日
Last Updated: October 31, 2026

---

## 日本語

### はじめに

このプライバシーポリシーは、アプリ「ことのは」（以下「本アプリ」）が利用者の情報をどう扱うかを説明します。ご利用の前にお読みください。要点は次の 3 つです。

- 入力した文・履歴・定型文・お気に入り・設定は、お使いの端末の中に保存します
- 本アプリが端末の外へデータを送るのは、AI 変換を使うときだけです。初めて使う前に同意をいただきます
- 本アプリが、クラッシュの情報を自分で送ることはありません

### 端末の中に保存するもの

本アプリは、次のデータをお使いの端末の中に保存します。本アプリがこれらを端末の外へ送るのは、AI 変換を使うときだけです（送るものは次の節に書きます）。

- **入力履歴**: 文字盤やキーボードで入力して読み上げた文など（最大 50 件）
- **入力中の文**: アプリが終了しても入力が消えないように保存します。入力欄を空にすると消えます
- **定型文**: 利用者が追加した定型文
- **お気に入り**: お気に入りに登録した文
- **設定**: 文字の大きさ、テーマ、読み上げの速さと声など

### AI 変換を使うときに送るもの

AI 変換は、使うかどうかを選べる機能です。使うと、本アプリは次のデータを、ことのはのサーバー（ことのは backend）へ送ります。

- **入力した文**: 変換したい文
- **丁寧さ**: 選んだ丁寧さ（カジュアル・普通・丁寧）
- **前回の変換結果**: 再生成するときだけ

ことのは backend は、入力した文（再生成では前回の変換結果も）と、丁寧さに応じた指示を、Cloudflare, Inc.（米国）の AI サービス（Workers AI）へ送ります。変換の結果は、ことのは backend を通って本アプリへ戻ります。処理は日本の外で行われることがあります。提供先・米国の制度・提供先の措置は「外国にある第三者への提供について」に書きます。

**接続元の IP アドレス**は、通信の仕組み上、送るたびにことのは backend へ届きます。ことのは backend は、短い時間に多くの変換が送られたときに制限するためだけに、IP アドレスをメモリの中で使い、そこから作った識別子を Cloudflare のアクセス回数を制限する機能へ渡します。識別子は 1 分ごとに切り替えます。ことのは backend は、IP アドレスや識別子を独自のログやデータベースに記録・保存せず、Workers AI へのリクエストにも含めません。Cloudflare の制限機能で識別子が削除される時刻は、このポリシーでは保証しません。ことのは backend は Cloudflare, Inc. の設備の上で動いているため、通信の仕組み上、同社の設備は接続元の IP アドレスを受け取ります。

### クラッシュの情報

本アプリには、クラッシュの情報を集めて送る仕組み（Firebase Crashlytics、Sentry などの SDK）を入れていません。

ただし、端末の OS とアプリストアには、アプリが異常終了したときの情報を開発者へ届ける仕組みがあります。届くのは、利用者が OS の設定で許可している場合だけです。

- **iOS / iPadOS**: 「設定 > プライバシーとセキュリティ > 解析と改善」で、「iPhoneの解析を共有」と「App デベロッパと共有」を有効にしている場合に、Apple を通して届きます
- **Android**: 端末の設定で「使用状況と診断情報」の自動共有を有効にしている場合に、Google Play を通して届きます（Android vitals）

届くことがある情報には、アプリが止まった箇所を示す技術情報（スタックトレース）、端末の機種名、OS のバージョン、アプリのバージョンがあります。本アプリが、入力した文・定型文・履歴・お気に入りを意図してこの情報に添えることはありません。ただし、中身は OS とアプリストアの仕組みと設定で決まります。共有するかどうかは、OS の設定でいつでも変えられます。詳しくは Apple と Google のプライバシーの説明をご覧ください。

### 使う目的

データは、本アプリの機能を提供するため（AI 変換の結果を作ることを含む）にだけ使います。

### 保管と削除

- **端末の中のデータ**: 本アプリがクラウドへ同期することはありません。ただし、OS のバックアップ（iOS の iCloud バックアップやパソコンへのバックアップ、Android の自動バックアップなど）を有効にしていると、ほかのアプリのデータと同じようにバックアップされることがあります。機種変更のときのデータ移行や復元で、新しい端末に移ることもあります
- **壊れたデータの写し**: iOS 版と Android 版は、保存したデータのファイルが壊れているのを起動時に見つけると、手を加える前に、その写しを端末の中に残します。写しには、それまでの入力履歴・定型文・お気に入りが含まれることがあり、アプリの中で個別に削除した項目が含まれることもあります。本アプリが写しを端末の外へ送ることはありません。OS のバックアップを有効にしている場合は、写しもバックアップの対象になります
- **ことのは backend**: データベースを持たず、入力した文・前回の変換結果・変換の結果を、処理の後に保存しません
- **Cloudflare, Inc.**: 同社は、送られた内容を AI の学習やサービスの改善に使わないとしています。同社での保存期間は、このポリシーでは保証しません。ことのはは、同社の AI Gateway に内容の記録を残さない設定で送っています

データは次の方法で削除できます。

- 履歴とお気に入りは、履歴の画面・お気に入りの画面から、1 件ずつ、またはすべて削除できます
- 定型文は、定型文の画面から 1 件ずつ削除できます
- アプリをアンインストールすると、端末の中のデータはすべて消えます

次の 2 つは、アプリの中で削除しても消えません。

- **すでに取られた OS のバックアップ**: 削除したデータが入っていると、端末の復元や再インストールで戻ることがあります
- **壊れたデータの写し**: 同じ種類のデータで次に壊れたファイルが見つかると、新しい写しに置き換わることがあります。アンインストールすると端末からは消えます。OS のバックアップに入った写しは、そのバックアップが消されるまで残り、端末の復元や再インストールで戻ることがあります

### 第三者への提供

AI 変換で Cloudflare, Inc. へ送ることを除き、法令に基づく場合のほかは、利用者の個人情報を第三者に提供しません。

### 外国にある第三者への提供について

AI 変換を使うと、「AI 変換を使うときに送るもの」に書いたデータが、外国にある第三者へ提供されます。本アプリは、初めて AI 変換を使う前に次の要点を示し、同意をいただいてから送ります（個人情報保護法第 28 条）。

- **提供先**: Cloudflare, Inc.（米国カリフォルニア州）。ことのは backend も同社の設備（Cloudflare Workers）の上で動いています
- **提供する情報と目的**: 入力した文・丁寧さ・前回の変換結果（再生成のときだけ）を、AI 変換のためだけに送ります。入力した文に名前や体調など個人に関する情報を書いた場合は、それも送られます
- **処理する国**: 同社の世界各地の設備で処理され、日本の外になることがあります。どの国の設備で処理するかはリクエストごとに同社の設備の状況で決まるため、前もって特定できません
- **米国の個人情報保護の制度**: 個人情報保護委員会の調査（2021 年 10 月時点）によると、次のとおりです。調査より後の法改正は反映していません（出典: 個人情報保護委員会「外国制度（アメリカ合衆国）」 https://www.ppc.go.jp/enforcement/infoprovision/laws/offshore_report_america/ ）
  - 連邦レベルの包括的な個人情報保護法は無く、通信・金融・医療など分野ごとの法律があります
  - APEC の越境プライバシールール（CBPR）システムに参加しています。参加国の事業者の個人情報の扱いを、国際的な基準に沿って第三者機関が認証する仕組みです
  - 同社の本社があるカリフォルニア州には、包括的な消費者プライバシー法（CCPA）があります。OECD プライバシーガイドラインの 8 原則のうち「責任の原則」に当たる規定は見当たらないとされています
  - 事業者に政府の情報収集への協力を義務づける制度や、データを国内に保存する義務のうち、本人の権利利益に重大な影響を及ぼす可能性のあるものは、同調査では挙げられていません
- **提供先が講じている措置**: 同社は公式の文書で次のことを示しています。このほか、ことのはは、同社の AI Gateway に内容の記録を残さない設定で送っています
  - 送られた内容を、AI モデルの学習や同社・第三者のサービスの改善に使わず、ほかの顧客に見せない（ https://developers.cloudflare.com/workers-ai/platform/privacy/ ）
  - データ処理契約（DPA）で、顧客の指示の範囲でだけ処理すること、守秘、暗号化などの安全管理、漏えいの通知、政府からの開示要求への対応を定めている（ https://www.cloudflare.com/cloudflare-customer-dpa/ ）
  - ISO/IEC 27001・27018・27701 の認証（ https://www.cloudflare.com/trust-hub/compliance-resources/iso-certifications/ ）と、Global CBPR・Global PRP の認証（ https://www.cloudflare.com/press/press-releases/2025/cloudflare-earns-new-landmark-global-privacy-certifications/ ）を受けている
- **講じられていない措置**: 同社の措置は、OECD プライバシーガイドラインの 8 原則におおむね対応すると考えます。ただし、同社の DPA が名前を挙げている法令は EU・EEA・スイス・英国・米国の州法で、日本の個人情報保護法は挙がっていません。同法に基づく保護や、本人の請求への協力も明記されていません

同意しない場合、AI 変換は使えませんが、ほかの機能はすべて使えます。同意は、アプリの「設定」→「AI設定」からいつでも取り消せます。取り消すと、次に AI 変換を使うときにもう一度確認します。

### お子様のプライバシー

本アプリは、13 歳未満のお子様から意図して個人情報を集めることはしません。

### このポリシーの変更

このポリシーを変えるときは、このページの内容と最終更新日を書き換えてお知らせします。大きな変更は、アプリの更新時にストアに載せる更新内容でもお知らせします。

### お問い合わせ

プライバシーについてのご質問は、次までお寄せください。

- サポート: https://github.com/mozuq-lab/kotonoha/issues
- メール: hello@mozuq-lab.com

---

## English

### Introduction

This Privacy Policy explains how the app "Kotonoha" (the "App") handles your information. Please read it before using the App. In short:

- The text you enter, your history, preset phrases, favorites, and settings are stored on your device
- The App sends data off your device only when you use AI conversion, and asks for your consent before the first use
- The App never sends crash information by itself

### What Is Stored on Your Device

The App stores the following data on your device. The App sends this data off your device only when you use AI conversion (what is sent is described in the next section).

- **Input History**: Text you entered on the character board or keyboard and had read aloud, among others (up to 50 entries)
- **Text Being Entered**: Saved so that it is not lost if the App closes. It is deleted when you clear the input field
- **Preset Phrases**: Phrases you added
- **Favorites**: Phrases you added to favorites
- **Settings**: Font size, theme, speech rate and voice, and other settings

### What Is Sent When You Use AI Conversion

AI conversion is optional. When you use it, the App sends the following data to the Kotonoha server (the "Kotonoha backend"):

- **Input Text**: The text you want to convert
- **Politeness Level**: The level you chose (Casual, Normal, or Polite)
- **Previous Conversion Result**: Only when regenerating

The Kotonoha backend sends the Input Text (and the Previous Conversion Result when regenerating), with instructions based on the Politeness Level, to the AI service (Workers AI) of Cloudflare, Inc. (United States). The result returns to the App through the Kotonoha backend. Processing may take place outside Japan. The recipient, the US system, and the recipient's measures are described under "Transfer to Third Parties Outside Japan."

Your **source IP address** reaches the Kotonoha backend with every request as part of how network communication works. The backend uses it in memory only to limit requests when many conversions are sent in a short time. It sends an identifier derived from the IP address to Cloudflare's rate limiting service. The identifier changes every minute. The Kotonoha backend does not record the IP address or identifier in its own logs or database, and does not include either in requests to Workers AI. This policy does not guarantee when identifiers are deleted from Cloudflare's rate limiting service. Because the Kotonoha backend runs on Cloudflare, Inc.'s infrastructure, Cloudflare's infrastructure receives your source IP address as part of how network communication works.

### Crash Information

The App contains no mechanism for collecting and sending crash information (no SDK such as Firebase Crashlytics or Sentry).

However, your device's operating system and app store can share information with developers when an app terminates unexpectedly. This happens only if you allow it in your OS settings.

- **iOS / iPadOS**: Provided through Apple only if "Share iPhone Analytics" and "Share With App Developers" are enabled under Settings > Privacy & Security > Analytics & Improvements
- **Android**: Provided through Google Play (Android vitals) only if you have turned on automatic sharing of usage and diagnostics data

This information may include where the App stopped (a stack trace), the device model, the OS version, and the App version. The App does not intentionally attach text you entered, preset phrases, history, or favorites to it. However, its contents are determined by the OS and app store mechanisms and settings. You can change whether to share it at any time in your OS settings. For details, see Apple's and Google's privacy documentation.

### How We Use Your Data

Your data is used only to provide the App's features (including generating AI conversion results).

### Storage and Deletion

- **Data on your device**: The App does not sync it to any cloud. However, if you have enabled OS backup (such as iCloud Backup or a computer backup on iOS, or Auto Backup on Android), it may be backed up like other apps' data. It may also move to a new device when you transfer data or restore when changing devices
- **Copies of damaged data**: On iOS and Android, if the App finds at startup that a saved data file is damaged, it keeps a copy of that file on your device before changing it. The copy may contain input history, preset phrases, and favorites saved up to that point, including items you had deleted individually in the App. The App never sends the copy off your device. If you have enabled OS backup, copies may be backed up as well
- **Kotonoha backend**: It has no database and does not store the Input Text, the Previous Conversion Result, or the Conversion Result after processing
- **Cloudflare, Inc.**: Cloudflare states that it does not use the content to train AI models or improve its services. This policy does not guarantee how long Cloudflare keeps it. Kotonoha sends requests with content logging in Cloudflare AI Gateway turned off

You can delete data as follows:

- History and favorites: one by one or all at once, from the History and Favorites screens
- Preset phrases: one by one, from the Preset Phrases screen
- Uninstalling the App deletes all data on your device

The following are not removed by deleting data in the App:

- **OS backups already taken**: Deleted data in them may come back when you restore your device or reinstall the App
- **Copies of damaged data**: A copy may be replaced by a newer one the next time a damaged file of the same kind is found. It is deleted from your device when you uninstall the App. A copy in an OS backup remains until that backup is deleted, and may come back when you restore your device or reinstall the App

### Sharing with Third Parties

Except for sending data to Cloudflare, Inc. for AI conversion, the App does not provide your personal information to third parties unless required by law.

### Transfer to Third Parties Outside Japan

When you use AI conversion, the data described under "What Is Sent When You Use AI Conversion" is provided to a third party outside Japan. Before the first AI conversion, the App shows the key points below and sends data only after you consent (Article 28 of Japan's Act on the Protection of Personal Information).

- **Recipient**: Cloudflare, Inc. (California, United States). The Kotonoha backend also runs on Cloudflare's infrastructure (Cloudflare Workers)
- **Data and purpose**: The Input Text, the Politeness Level, and the Previous Conversion Result (only when regenerating) are sent solely for AI conversion. If you type personal information such as a name or a health condition, it is sent as well
- **Country of processing**: Processing takes place in Cloudflare facilities around the world and may be outside Japan. The country cannot be identified in advance because Cloudflare's infrastructure decides it for each request
- **Personal information protection system in the United States**: The following is based on a survey by Japan's Personal Information Protection Commission (as of October 2021). Later legal changes are not reflected (source: https://www.ppc.go.jp/enforcement/infoprovision/laws/offshore_report_america/ )
  - There is no comprehensive federal privacy law; instead there are sector-specific laws for areas such as telecommunications, finance, and healthcare
  - The United States participates in the APEC Cross-Border Privacy Rules (CBPR) system, in which third-party bodies certify businesses' handling of personal information against an international standard
  - California, where Cloudflare is headquartered, has a comprehensive consumer privacy law (the CCPA), which reportedly has no provision corresponding to the Accountability Principle of the eight OECD Privacy Guidelines principles
  - The survey lists no obligation for businesses to cooperate with government information collection, and no data localization requirement, that may significantly affect individuals' rights and interests
- **Measures taken by the recipient**: Cloudflare states the following in its official documents. In addition, Kotonoha sends requests with content logging in Cloudflare AI Gateway turned off
  - It does not use the content to train AI models or improve its or third parties' services, and does not show it to other customers ( https://developers.cloudflare.com/workers-ai/platform/privacy/ )
  - Its Data Processing Addendum (DPA) provides for processing only on the customer's instructions, confidentiality, security measures such as encryption, breach notification, and handling of government requests ( https://www.cloudflare.com/cloudflare-customer-dpa/ )
  - It holds ISO/IEC 27001, 27018, and 27701 certifications ( https://www.cloudflare.com/trust-hub/compliance-resources/iso-certifications/ ) and Global CBPR and Global PRP certifications ( https://www.cloudflare.com/press/press-releases/2025/cloudflare-earns-new-landmark-global-privacy-certifications/ )
- **Measures not taken**: We consider that Cloudflare's measures broadly correspond to the eight OECD Privacy Guidelines principles. However, the laws its DPA names are those of the EU, the EEA, Switzerland, the UK, and US states. It does not name Japan's Act on the Protection of Personal Information, and does not expressly provide protection or cooperation with individuals' requests under that Act

If you do not consent, AI conversion is unavailable, but all other features remain available. You can withdraw your consent at any time in the App under 設定 (Settings) > AI設定 (AI Settings). After you withdraw it, the App asks again the next time you use AI conversion.

### Children's Privacy

The App does not intentionally collect personal information from children under 13.

### Changes to This Policy

When we change this policy, we will update this page and its Last Updated date. For significant changes, we will also announce them in the release notes shown in the app store when the App is updated.

### Contact Us

For privacy questions, please contact us:

- Support: https://github.com/mozuq-lab/kotonoha/issues
- Email: hello@mozuq-lab.com
