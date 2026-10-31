/// 読み上げの声
/// 端末に入っている日本語の声のうち、端末の中で読み上げるものだけを表す。
library;

/// 声の品質（iOS の「拡張」「プレミアム」。Android は区別せず標準）
enum TTSVoiceQuality { standard, enhanced, premium }

/// 読み上げの声
/// 作れるのは [TTSVoice.fromPlugin] だけで、エンジンが通信を要すると申告する声
/// （Android の `-network` の声）と、使うとダウンロードが始まる声は作らない
/// （守る約束 ②）。Android の端末内の声も `networkTimeoutMs` を持つので、
/// 判断は申告（`network_required`）だけで行う。「標準」の別名
/// （`legacySetLanguageVoice`。`setLanguage` が選ぶ声）も、同じ声が 2 つ並ぶので作らない。
class TTSVoice {
  const TTSVoice._({
    required this.name,
    required this.locale,
    required this.quality,
    this.gender,
    this.identifier,
  });

  /// flutter_tts の `getVoices` の 1 件から作る。選べない声なら null
  static TTSVoice? fromPlugin(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name'];
    final locale = raw['locale'];
    if (name is! String || locale is! String) return null;
    if (!locale.toLowerCase().startsWith('ja')) return null;
    if (raw['network_required'] == '1') return null;
    final features = raw['features'];
    if (features is String) {
      final keys = features.split('\t');
      if (keys.contains('notInstalled') ||
          keys.contains('legacySetLanguageVoice')) {
        return null;
      }
    }
    final identifier = raw['identifier'];
    return TTSVoice._(
      name: name,
      locale: locale,
      quality: switch (raw['quality']) {
        'premium' => TTSVoiceQuality.premium,
        'enhanced' => TTSVoiceQuality.enhanced,
        _ => TTSVoiceQuality.standard,
      },
      gender: raw['gender'] is String ? raw['gender'] as String : null,
      identifier:
          identifier is String && identifier.isNotEmpty ? identifier : null,
    );
  }

  /// 声の名前（iOS は「Kyoko」、Android は「ja-jp-x-htm-local」の形）
  final String name;

  /// 言語（例: ja-JP）
  final String locale;

  /// 品質
  final TTSVoiceQuality quality;

  /// 性別（iOS の male / female。分からなければ null）
  final String? gender;

  /// iOS の声の識別子。同じ名前の標準版と拡張版を見分ける（Android は null）
  final String? identifier;

  /// 保存する ID。iOS は識別子、Android は名前
  String get id => identifier ?? name;

  /// 名前が人に読める形か（Android の名前は記号の並びなので出さない）
  bool get hasReadableName => identifier != null;

  /// エンジンへ渡す形（`FlutterTts.setVoice`）
  Map<String, String> get pluginArguments => {
        'name': name,
        'locale': locale,
        if (identifier != null) 'identifier': identifier!,
      };

  /// 品質の高い順、同じ品質なら名前の順
  static int compare(TTSVoice a, TTSVoice b) {
    final byQuality = b.quality.index.compareTo(a.quality.index);
    return byQuality != 0 ? byQuality : a.name.compareTo(b.name);
  }
}
