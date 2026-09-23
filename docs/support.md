# サポート / Support

---

## 日本語

### ことのは サポートページ

発話困難な方のためのコミュニケーション支援アプリ「ことのは」のサポートページです。

### よくある質問 (FAQ)

詳細なFAQは以下のドキュメントをご参照ください。

- [FAQ - よくある質問](./user-guide/faq.md)
- [トラブルシューティング](./user-guide/troubleshooting.md)

### 定型文を追加・編集中に終了した場合

追加フォームと編集フォームの本文とカテゴリは、最後の変更から400ms後に下書きとして保存を始め、次に同じフォーム（編集は同じ定型文の編集）を開いたときに復元します。編集の下書きは、定型文画面の「下書き」から選んで開くこともできます。元の定型文が削除されても編集の下書きは残り、「下書き」から開くと本文とカテゴリを読めます。「コピー」で本文を端末のクリップボードに置き、「下書きを破棄」で確認のうえ消せます。「閉じる」や戻る操作では消えません。削除された定型文を下書きから元に戻すことはしないので、必要なら本文をコピーして新しく追加してください。元の定型文があるかどうかを確認できないときは開かずにお知らせし、下書きは残します。保存前に終了した場合や、非同期書き込み中の強制終了・タブ終了では最新の入力が失われることがあります。書き込み完了の応答も、物理ディスクへの永続化を保証しません。Web で同じアプリを複数のタブで開いていると、下書きが消えたり古い内容に戻ったり、削除した定型文が他のタブでの保存によって戻ったりすることがあります。
下書きを読み込めている場合、「キャンセル」または戻る操作で「破棄する」を選ぶと下書きを消去します。定型文の保存に成功した場合も消去します。フォームを閉じるだけ、戻る操作で閉じるだけでは消去しません。消去できなかったときはその旨をお知らせします。そのまま「閉じる」で閉じられ、下書きは次回も残ります。定型文の保存後に消去だけ失敗した場合は入力を止めるので、「保存」で消去を再試行するか、「閉じる」で閉じてください。書き込みの失敗をアプリが受け取れるのは Web と Android だけで、iOS では失敗が返らないためお知らせできません。下書きの破棄は、すでに保存された定型文の削除ではありません。
下書きを読み込めなかったときは「再読み込み」を押してください（「下書き」の場合はもう一度押してください）。読み込めない間も定型文の追加・編集はできますが、下書きは保存されません。この間に保存・キャンセル・破棄をしても下書きには触れず、前回保存された下書きは次回そのまま読み込まれます。編集の下書きの本文かカテゴリが保存済みの内容と違うときは、開いたときにそのことをお知らせします（読み込めない間に保存した後などは保存済みより古い下書きが出ることがあり、「キャンセル」で下書きを消すと保存済みの内容に戻ります）。入力を始めるか、カテゴリを変えると、打った内容を読み直しで置き換えてしまわないように「再読み込み」は出なくなります（本文とカテゴリをフォームを開いたときの状態に戻すと戻ります）。追加フォームで復元した下書きと同じIDの定型文が別の内容になっている場合は上書きせず入力を残します。必要な内容をコピーしてから、下書きを明示的に破棄できます。同じ内容ですでに保存されていた場合は、その下書きを消して空の追加フォームを開きます。
下書きを読み込めているのに書き込みに失敗しているあいだは、定型文の保存には進まず、入力を残してお知らせするので（書き込みの失敗を受け取れるのは Web と Android です）、書き込めるようになってから同じフォームの「保存」で再試行してください。

### 使い方ガイド

- [iOS ガイド付きアクセス設定](./user-guide/ios-guided-access.md)
- [Android 画面ピン留め設定](./user-guide/android-screen-pinning.md)

### お問い合わせ方法

#### 1. GitHub Issues（推奨）

技術的な問題やバグ報告、機能リクエストは、GitHubのIssuesをご利用ください。

- URL: https://github.com/mozuq-lab/kotonoha/issues

#### 2. メール

プライバシーに関するお問い合わせや、GitHubをご利用でない場合は、メールでお問い合わせください。

- メール: support@kotonoha-app.example.com

### お問い合わせの際に

以下の情報をお知らせいただくと、より迅速に対応できます。

- ご利用の端末（例：iPad Pro 11インチ、Samsung Galaxy Tab S8）
- OSバージョン（例：iOS 17.0、Android 14）
- アプリのバージョン（設定画面で確認できます）
- 問題が発生した操作の詳細
- エラーメッセージ（表示されている場合）

### 対応時間

- 通常、お問い合わせから3〜5営業日以内にご返信いたします
- 緊急のお問い合わせには可能な限り早く対応いたします

---

## English

### Kotonoha Support Page

This is the support page for "Kotonoha," a communication support app for people with speech difficulties.

### Frequently Asked Questions (FAQ)

Please refer to the following documents for detailed FAQ:

- [FAQ - Frequently Asked Questions](./user-guide/faq.md)
- [Troubleshooting Guide](./user-guide/troubleshooting.md)

### If the app closes while adding or editing a preset phrase

The add and edit forms start saving their text and category as a draft 400ms after the last change and restore it when you next open the same form (for edits, the edit form of the same phrase). You can also pick an edit draft from Drafts on the Preset Phrases screen. If the original phrase has been deleted, its edit draft remains; open it from Drafts to read its text and category, press Copy to place the text on your device's clipboard, or press Discard draft and confirm to remove it. Close and going back do not remove it. The App does not bring a deleted phrase back from a draft; if needed, copy the text and add it as a new phrase. If the App cannot confirm whether the original phrase exists, it tells you so instead of opening the draft, and the draft remains. Closing or terminating the app or tab before or during asynchronous writing can lose recent input; a completed write response does not guarantee physical disk durability. If the App is open in more than one browser tab on the Web, drafts may disappear or revert to older content, and a deleted phrase may come back when it is saved in another tab.
If the draft was loaded, Cancel or confirmed discard removes it, as does a successful phrase save. Merely closing the form, or going back, does not remove it. If removal fails, the form tells you so and you can still close it with Close; the draft then remains for next time. If the phrase was saved but draft removal failed, the form stops accepting input: press Save to retry removal, or Close to leave it. Only Web and Android report a failed write back to the App; on iOS no failure is returned, so it cannot be reported. Discarding a draft does not delete a phrase already saved.
Use Reload if the draft cannot be loaded (for Drafts, press it again). You can still add and edit preset phrases while it cannot be loaded, but no draft is saved then. Saving, cancelling, or discarding while in this state leaves the draft untouched; the previously stored draft loads normally next time. When an edit draft differs from the saved phrase, the form tells you so when it opens (after saving while the draft could not be loaded, for example, a draft older than the saved text can appear; Cancel removes the draft and brings back the saved content). Once you start typing or change the category, Reload is hidden so that reloading cannot replace what you entered; it comes back when you return the text and category to how the form opened. If a draft restored in the add form has an ID that belongs to different phrase content, saving is refused and your input is retained. You can copy it before explicitly discarding the draft. If the same content was already saved under that ID, the draft is removed and an empty add form opens.
While the draft was loaded but a draft write is failing, the App does not go on to save the preset phrase; it keeps your input and tells you so (only Web and Android report a failed write), so retry with Save in the same form once writing succeeds again.

### User Guides

- [iOS Guided Access Setup](./user-guide/ios-guided-access.md)
- [Android Screen Pinning Setup](./user-guide/android-screen-pinning.md)

### How to Contact Us

#### 1. GitHub Issues (Recommended)

For technical issues, bug reports, or feature requests, please use GitHub Issues.

- URL: https://github.com/mozuq-lab/kotonoha/issues

#### 2. Email

For privacy-related inquiries or if you don't use GitHub, please contact us by email.

- Email: support@kotonoha-app.example.com

### When Contacting Us

Providing the following information helps us respond more quickly:

- Device you're using (e.g., iPad Pro 11-inch, Samsung Galaxy Tab S8)
- OS version (e.g., iOS 17.0, Android 14)
- App version (can be found in Settings)
- Details of the operation when the problem occurred
- Error message (if displayed)

### Response Time

- We typically respond within 3-5 business days
- We will try to respond to urgent inquiries as quickly as possible
