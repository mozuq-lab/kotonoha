/// 画面の文字を、VoiceOver / TalkBack に読ませるときの文字列にする。
///
/// 見た目はそのままにして、読み方だけを直す。`Text.semanticsLabel` や
/// `Semantics.label` に渡す。利用者の文を声に出す読み上げ（flutter_tts）には使わない。
///
/// 「AI」は日本語の声で「あい」と読まれた（物理 iPad の VoiceOver、2026-10-17）。
library;

/// [shown] を読み上げ用の文字列にする
String spokenLabel(String shown) => shown.replaceAll('AI', 'エーアイ');
