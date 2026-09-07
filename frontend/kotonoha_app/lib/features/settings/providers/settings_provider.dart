library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/font_size.dart';
import '../models/app_theme.dart';
import '../../tts/domain/models/tts_speed.dart';
import '../../tts/providers/tts_provider.dart';
import '../../ai_conversion/domain/models/politeness_level.dart';

final settingsNotifierProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// SharedPreferencesで設定を永続化し、保存前にUIを更新するNotifier。
/// 読み込みに失敗した場合はデフォルト設定で動作を継続する。
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  SharedPreferences? _prefs;

  @override
  Future<AppSettings> build() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      final fontSize = await _restoreEnumWithMigration(
        'fontSize',
        FontSize.values,
        FontSize.medium,
      );

      final theme = await _restoreEnumWithMigration(
        'theme',
        AppTheme.values,
        AppTheme.light,
      );

      final ttsSpeed = _restoreEnumFromName(
        _prefs!.getString('tts_speed'),
        TTSSpeed.values,
        TTSSpeed.normal,
      );

      final aiPoliteness = _restoreEnumFromName(
        _prefs!.getString('ai_politeness'),
        PolitenessLevel.values,
        PolitenessLevel.normal,
      );
      final hasAcceptedAIPrivacyPolicy =
          _prefs!.getBool('ai_privacy_consent') ?? false;

      // 永続化形式: bool値をそのまま保存（enum化不要のためマイグレーション対象外）
      final simpleMode = _prefs!.getBool('simple_mode') ?? false;

      // 保存済み速度はTTS側からSettingsの初期化完了後に取得する。
      // ここでTTSの初期化を待つと、TTSもsettingsNotifierProvider.futureを
      // 待つため循環待機になる。
      return AppSettings(
        fontSize: fontSize,
        theme: theme,
        ttsSpeed: ttsSpeed,
        aiPoliteness: aiPoliteness,
        hasAcceptedAIPrivacyPolicy: hasAcceptedAIPrivacyPolicy,
        simpleMode: simpleMode,
      );
    } catch (e) {
      return const AppSettings();
    }
  }

  /// 保存されたenum名を復元し、null・不正値ならデフォルトを返す。
  T _restoreEnumFromName<T extends Enum>(
    String? savedName,
    List<T> enumValues,
    T defaultValue,
  ) {
    if (savedName == null) {
      return defaultValue;
    }

    try {
      return enumValues.firstWhere(
        (e) => e.name == savedName,
        orElse: () => defaultValue,
      );
    } catch (_) {
      return defaultValue;
    }
  }

  /// fontSize/themeを復元し、旧形式のenum indexはname形式へ書き戻す。
  /// indexのままだとenumの追加・並び替えで保存済みの設定が別の値になるため。
  /// 未保存・不正値はデフォルト値を返し、書き戻しの失敗は復元結果に影響させない。
  Future<T> _restoreEnumWithMigration<T extends Enum>(
    String key,
    List<T> enumValues,
    T defaultValue,
  ) async {
    // getString/getIntは旧形式と型が異なると例外になるため、getで読む。
    final raw = _prefs!.get(key);

    if (raw is String) {
      // 新形式: enum name文字列として復元
      return _restoreEnumFromName(raw, enumValues, defaultValue);
    }

    if (raw is int) {
      // 旧形式: enum indexとして復元を試みる
      if (raw < 0 || raw >= enumValues.length) {
        return defaultValue;
      }

      final migrated = enumValues[raw];

      // 再保存に失敗しても、今回復元した値は返す。
      try {
        await _prefs!.setString(key, migrated.name);
      } catch (_) {
        // 再保存失敗時もアプリはクラッシュさせない
      }

      return migrated;
    }

    // null・未知の型: デフォルト値を使用
    return defaultValue;
  }

  Future<void> setFontSize(FontSize fontSize) async {
    final currentSettings = state.asData?.value;
    if (currentSettings == null) return;

    state = AsyncValue.data(currentSettings.copyWith(fontSize: fontSize));

    try {
      await _prefs?.setString('fontSize', fontSize.name);
    } catch (e) {
      // 保存に失敗しても、現在のUI状態は維持する。
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    final currentSettings = state.asData?.value;
    if (currentSettings == null) return;

    state = AsyncValue.data(currentSettings.copyWith(theme: theme));

    try {
      await _prefs?.setString('theme', theme.name);
    } catch (e) {
      // 保存に失敗しても、現在のUI状態は維持する。
    }
  }

  Future<void> setTTSSpeed(TTSSpeed speed) async {
    final currentSettings = state.asData?.value;
    if (currentSettings == null) return;

    state = AsyncValue.data(currentSettings.copyWith(ttsSpeed: speed));

    try {
      final ttsNotifier = ref.read(ttsProvider.notifier);
      await ttsNotifier.setSpeed(speed);
    } catch (e) {
      // TTS反映に失敗しても、設定状態と保存処理は継続する。
    }

    try {
      await _prefs?.setString('tts_speed', speed.name);
    } catch (e) {
      // 保存に失敗しても、現在のUI状態は維持する。
    }
  }

  Future<void> setAIPoliteness(PolitenessLevel level) async {
    final currentSettings = state.asData?.value;
    if (currentSettings == null) return;

    state = AsyncValue.data(currentSettings.copyWith(aiPoliteness: level));

    try {
      await _prefs?.setString('ai_politeness', level.name);
    } catch (e) {
      // 保存に失敗しても、現在のUI状態は維持する。
    }
  }

  Future<void> setAIPrivacyConsent(bool accepted) async {
    final currentSettings = state.asData?.value;
    if (currentSettings == null) return;

    state = AsyncValue.data(
      currentSettings.copyWith(hasAcceptedAIPrivacyPolicy: accepted),
    );

    try {
      await _prefs?.setBool('ai_privacy_consent', accepted);
    } catch (e) {
      // 保存失敗時も現在セッションでは同意状態を保持する。
    }
  }

  /// 背景: 疲労時・症状進行時に文字盤なしの大ボタン画面へ切り替えるための設定。
  /// 誤操作で意図せず切り替わったままにならないよう、ホーム画面・設定画面
  /// 双方から同じメソッドで確実にトグルできるようにする。
  Future<void> setSimpleMode(bool enabled) async {
    final currentSettings = state.asData?.value;
    if (currentSettings == null) return;

    state = AsyncValue.data(currentSettings.copyWith(simpleMode: enabled));

    try {
      await _prefs?.setBool('simple_mode', enabled);
    } catch (e) {
      // 保存に失敗しても、現在のUI状態は維持する。
    }
  }
}
