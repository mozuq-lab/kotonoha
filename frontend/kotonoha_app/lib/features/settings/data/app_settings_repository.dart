import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/shared/models/app_settings.dart';

/// 【Repository定義】: アプリ設定のshared_preferences永続化を担当するRepository
/// 【実装内容】: AppSettings のCRUD操作をshared_preferencesに委譲
/// 【設計根拠】: Repositoryパターンによりデータアクセス層を抽象化
/// 🔵 信頼性レベル: 青信号 - architecture.mdのローカルストレージ設計に基づく
class AppSettingsRepository {
  /// 【フィールド定義】: SharedPreferences インスタンス
  /// 【実装内容】: コンストラクタで注入されたインスタンスを保持
  /// 🔵 信頼性レベル: 青信号 - DIパターン
  final SharedPreferences _prefs;

  /// shared_preferencesキー定数
  static const String _fontSizeKey = 'fontSize';
  static const String _themeKey = 'theme';
  static const String _ttsSpeedKey = 'ttsSpeed';
  static const String _politenessLevelKey = 'politenessLevel';

  /// 【コンストラクタ】: Repository生成
  /// 【実装内容】: SharedPreferencesを外部から注入（テスト容易性のため）
  /// 🔵 信頼性レベル: 青信号 - DI（依存性注入）パターン
  AppSettingsRepository({required SharedPreferences prefs}) : _prefs = prefs;

  /// 【メソッド定義】: 全設定を読み込み
  /// 【実装内容】: shared_preferencesから各設定を取得し、AppSettingsオブジェクトを生成
  /// 【戻り値】: AppSettings（保存されていない項目はデフォルト値）
  /// 🔵 信頼性レベル: 青信号 - REQ-801, REQ-803, REQ-404, REQ-903, NFR-101対応
  Future<AppSettings> load() async {
    final fontSize = _loadFontSize();
    final theme = _loadTheme();
    final ttsSpeed = _loadTtsSpeed();
    final politenessLevel = _loadPolitenessLevel();

    return AppSettings(
      fontSize: fontSize,
      theme: theme,
      ttsSpeed: ttsSpeed,
      politenessLevel: politenessLevel,
    );
  }

  /// 【メソッド定義】: フォントサイズを保存
  /// 【実装内容】: 列挙型のname（文字列）をshared_preferencesに保存
  /// 【引数】: fontSize - 保存するフォントサイズ
  /// 🔵 信頼性レベル: 青信号 - REQ-801
  Future<void> saveFontSize(FontSize fontSize) async {
    await _prefs.setString(_fontSizeKey, fontSize.name);
  }

  /// 【メソッド定義】: テーマを保存
  /// 【実装内容】: 列挙型のname（文字列）をshared_preferencesに保存
  /// 【引数】: theme - 保存するテーマ
  /// 🔵 信頼性レベル: 青信号 - REQ-803
  Future<void> saveTheme(AppTheme theme) async {
    await _prefs.setString(_themeKey, theme.name);
  }

  /// 【メソッド定義】: TTS速度を保存
  /// 【実装内容】: 列挙型のname（文字列）をshared_preferencesに保存
  /// 【引数】: ttsSpeed - 保存するTTS速度
  /// 🔵 信頼性レベル: 青信号 - REQ-404
  Future<void> saveTtsSpeed(TtsSpeed ttsSpeed) async {
    await _prefs.setString(_ttsSpeedKey, ttsSpeed.name);
  }

  /// 【メソッド定義】: AI丁寧さレベルを保存
  /// 【実装内容】: 列挙型のname（文字列）をshared_preferencesに保存
  /// 【引数】: level - 保存する丁寧さレベル
  /// 🔵 信頼性レベル: 青信号 - REQ-903
  Future<void> savePolitenessLevel(PolitenessLevel level) async {
    await _prefs.setString(_politenessLevelKey, level.name);
  }

  /// 【メソッド定義】: 全設定を一括保存
  /// 【実装内容】: AppSettingsオブジェクトの全フィールドを保存
  /// 【引数】: settings - 保存する設定
  /// 🔵 信頼性レベル: 青信号 - FR-056-001〜004
  Future<void> saveAll(AppSettings settings) async {
    await saveFontSize(settings.fontSize);
    await saveTheme(settings.theme);
    await saveTtsSpeed(settings.ttsSpeed);
    await savePolitenessLevel(settings.politenessLevel);
  }

  // --- プライベートメソッド ---

  /// 【プライベートメソッド】: フォントサイズを読み込み
  /// 【エッジケース】: 不正な値または未保存の場合はデフォルト値を返す
  FontSize _loadFontSize() {
    final value = _prefs.getString(_fontSizeKey);
    if (value == null) return FontSize.medium;

    return FontSize.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FontSize.medium,
    );
  }

  /// 【プライベートメソッド】: テーマを読み込み
  /// 【エッジケース】: 不正な値または未保存の場合はデフォルト値を返す
  AppTheme _loadTheme() {
    final value = _prefs.getString(_themeKey);
    if (value == null) return AppTheme.light;

    return AppTheme.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppTheme.light,
    );
  }

  /// 【プライベートメソッド】: TTS速度を読み込み
  /// 【エッジケース】: 不正な値または未保存の場合はデフォルト値を返す
  TtsSpeed _loadTtsSpeed() {
    final value = _prefs.getString(_ttsSpeedKey);
    if (value == null) return TtsSpeed.normal;

    return TtsSpeed.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TtsSpeed.normal,
    );
  }

  /// 【プライベートメソッド】: AI丁寧さレベルを読み込み
  /// 【エッジケース】: 不正な値または未保存の場合はデフォルト値を返す
  PolitenessLevel _loadPolitenessLevel() {
    final value = _prefs.getString(_politenessLevelKey);
    if (value == null) return PolitenessLevel.normal;

    return PolitenessLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PolitenessLevel.normal,
    );
  }
}
