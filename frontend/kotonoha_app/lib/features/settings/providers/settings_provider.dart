/// 【機能概要】: アプリ設定の状態管理（Riverpod AsyncNotifier）
/// 【実装方針】: SharedPreferencesでローカル永続化、AsyncNotifierで非同期状態管理
/// 【テスト対応】: TC-001からTC-016までの全テストケースを通すための実装
/// 🔵 信頼性レベル: 要件定義書とテストケースに基づく確実な実装
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/font_size.dart';
import '../models/app_theme.dart';
import '../../tts/domain/models/tts_speed.dart';
import '../../tts/providers/tts_provider.dart';

/// 【機能概要】: SettingsNotifierのプロバイダー定義
/// 【実装方針】: AsyncNotifierProviderを使用して非同期状態管理
/// 【テスト対応】: テストコードでcontainer.read(settingsNotifierProvider)として使用
/// 🔵 信頼性レベル: Riverpodの標準的なパターン
// 【Provider定義】: SettingsNotifierを提供するプロバイダー
// 【AsyncValue対応】: 非同期読み込み中、成功、エラー状態を管理
// 🔵 青信号: Riverpod 2.xの標準的な実装パターン
final settingsNotifierProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// 【機能概要】: アプリ設定の状態管理クラス（AsyncNotifier実装）
/// 【実装方針】: SharedPreferencesで永続化、楽観的更新でUI応答性を維持
/// 【テスト対応】: 全テストケース（TC-001〜TC-016）を通すための最小限実装
/// 🔵 信頼性レベル: REQ-801、REQ-803、REQ-5003に基づく
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  /// 【機能概要】: SharedPreferencesインスタンスの遅延初期化
  /// 【実装方針】: build()で初期化し、以降はキャッシュを使用
  /// 【テスト対応】: TC-001〜TC-016で使用
  /// 🔵 信頼性レベル: SharedPreferencesの標準的な使用方法
  // 【遅延初期化】: build()で初期化されるまではnull
  // 【キャッシュ】: 一度初期化したら再利用
  // 🔵 青信号: Dartの標準的なパターン
  SharedPreferences? _prefs;

  /// 【機能概要】: 初期状態を構築（SharedPreferencesから設定を読み込む）
  /// 【実装方針】: アプリ起動時に1回だけ実行され、保存済み設定を復元
  /// 【テスト対応】: TC-001（初期状態）、TC-008、TC-009（設定復元）、TC-014（null安全性）
  /// 🔵 信頼性レベル: REQ-5003（設定永続化）に基づく
  ///
  /// 戻り値: `Future<AppSettings>` - 復元された設定またはデフォルト設定
  @override
  Future<AppSettings> build() async {
    // 【実装内容】: SharedPreferencesから設定を読み込む
    // 【エラーハンドリング】: 初期化失敗時はデフォルト値を返す（NFR-301）
    // 🔵 青信号: REQ-5003（設定永続化）に基づく
    try {
      // 【SharedPreferences初期化】: ローカルストレージへのアクセスを確立
      // 【非同期処理】: getInstance()は非同期なので await が必要
      // 🔵 青信号: SharedPreferencesの標準的な初期化方法
      _prefs = await SharedPreferences.getInstance();

      // 【フォントサイズ復元】: SharedPreferencesからフォントサイズのindex値を読み込む
      // 【null安全性】: getInt()がnullを返した場合はデフォルト値（medium.index）を使用
      // 🔵 青信号: TC-014（null安全性）に対応
      final fontSizeIndex = _prefs!.getInt('fontSize') ?? FontSize.medium.index;

      // 【テーマ復元】: SharedPreferencesからテーマのindex値を読み込む
      // 【null安全性】: getInt()がnullを返した場合はデフォルト値（light.index）を使用
      // 🔵 青信号: TC-009（テーマ復元）、TC-014（null安全性）に対応
      final themeIndex = _prefs!.getInt('theme') ?? AppTheme.light.index;

      // 【TTS速度復元】: SharedPreferencesからTTS速度のname値を読み込む
      // 【null安全性】: getString()がnullを返した場合はデフォルト値（normal.name）を使用
      // 🔵 青信号: TC-049-015（境界値テスト）、TC-049-013（null安全性）に対応
      final ttsSpeedName =
          _prefs!.getString('tts_speed') ?? TTSSpeed.normal.name;

      // 【TTS速度変換】: enum nameから対応するTTSSpeed値を取得
      // 【不正値フォールバック】: 不正な値の場合はデフォルト値（normal）を使用
      // 🔵 青信号: TC-049-014（不正値フォールバック）に対応
      TTSSpeed ttsSpeed;
      try {
        ttsSpeed = TTSSpeed.values.firstWhere(
          (e) => e.name == ttsSpeedName,
          orElse: () => TTSSpeed.normal,
        );
      } catch (_) {
        ttsSpeed = TTSSpeed.normal;
      }

      // 【設定復元】: index値からenumに変換してAppSettingsインスタンスを生成
      // 【境界値チェック】: index値が範囲外の場合はデフォルト値を使用
      // 🔵 青信号: TC-015、TC-016（境界値テスト）に対応
      return AppSettings(
        fontSize: FontSize.values[fontSizeIndex],
        theme: AppTheme.values[themeIndex],
        ttsSpeed: ttsSpeed,
      );
    } catch (e) {
      // 【エラーハンドリング】: SharedPreferences初期化失敗時の処理
      // 【基本機能継続】: エラーが発生してもデフォルト設定でアプリを動作させる（NFR-301）
      // 🟡 黄信号: TC-011（エラーハンドリング）に対応（詳細な検証は実装後）

      // 【ログ記録】: エラー内容を記録（実装後にloggerを追加予定）
      // 🟡 黄信号: 将来的な改善予定

      // 【デフォルト値返却】: アプリがクラッシュせず、デフォルト設定で動作継続
      // 🔵 青信号: REQ-801、REQ-803のデフォルト値定義に基づく
      return const AppSettings();
    }
  }

  /// 【機能概要】: フォントサイズを変更する
  /// 【実装方針】: 楽観的更新でUI即座反映、SharedPreferencesに非同期保存
  /// 【テスト対応】: TC-002（small）、TC-004（large）、TC-015（境界値）
  /// 🔵 信頼性レベル: REQ-801、REQ-2007、REQ-5003に基づく
  ///
  /// パラメータ: `fontSize` - 新しいフォントサイズ
  Future<void> setFontSize(FontSize fontSize) async {
    // 【実装内容】: フォントサイズを変更し、SharedPreferencesに保存
    // 【楽観的更新】: 保存完了を待たずにUI状態を更新（REQ-2007: 即座反映）
    // 🔵 青信号: REQ-2007（即座反映）、REQ-5003（永続化）に基づく

    // 【現在の設定取得】: AsyncValueから現在の設定を取得
    // 【エラーチェック】: 現在の状態がロード済みでない場合は処理をスキップ
    // 🔵 青信号: Riverpod AsyncNotifierの標準的なパターン
    final currentSettings = state.valueOrNull;
    if (currentSettings == null) return;

    // 【状態更新】: copyWithで新しい設定を生成し、stateを更新
    // 【楽観的更新】: SharedPreferences保存前にUI状態を更新（即座反映）
    // 🔵 青信号: REQ-2007（即座反映）に基づく
    state = AsyncValue.data(currentSettings.copyWith(fontSize: fontSize));

    // 【永続化】: SharedPreferencesにフォントサイズを保存
    // 【非同期保存】: バックグラウンドで保存処理を実行
    // 🔵 青信号: REQ-5003（設定永続化）に基づく
    try {
      // 【保存処理】: enum indexをintとして保存
      // 🔵 青信号: SharedPreferencesの標準的な保存方法
      await _prefs?.setInt('fontSize', fontSize.index);
    } catch (e) {
      // 【エラーハンドリング】: 保存失敗時の処理
      // 【楽観的更新維持】: 保存失敗してもUI状態は更新済み（REQ-2007）
      // 🟡 黄信号: TC-012（書き込み失敗）に対応（詳細な検証は実装後）

      // 【ログ記録】: エラー内容を記録（実装後にloggerを追加予定）
      // 【ユーザー通知】: 再起動時に設定が戻る可能性をユーザーに通知（将来実装）
      // 🟡 黄信号: 将来的な改善予定
    }
  }

  /// 【機能概要】: テーマを変更する
  /// 【実装方針】: 楽観的更新でUI即座反映、SharedPreferencesに非同期保存
  /// 【テスト対応】: TC-005（light）、TC-006（dark）、TC-007（highContrast）、TC-016（境界値）
  /// 🔵 信頼性レベル: REQ-803、REQ-2008、REQ-5003に基づく
  ///
  /// パラメータ: `theme` - 新しいテーマ
  Future<void> setTheme(AppTheme theme) async {
    // 【実装内容】: テーマを変更し、SharedPreferencesに保存
    // 【楽観的更新】: 保存完了を待たずにUI状態を更新（REQ-2008: 即座反映）
    // 🔵 青信号: REQ-2008（即座反映）、REQ-5003（永続化）に基づく

    // 【現在の設定取得】: AsyncValueから現在の設定を取得
    // 【エラーチェック】: 現在の状態がロード済みでない場合は処理をスキップ
    // 🔵 青信号: Riverpod AsyncNotifierの標準的なパターン
    final currentSettings = state.valueOrNull;
    if (currentSettings == null) return;

    // 【状態更新】: copyWithで新しい設定を生成し、stateを更新
    // 【楽観的更新】: SharedPreferences保存前にUI状態を更新（即座反映）
    // 🔵 青信号: REQ-2008（即座反映）に基づく
    state = AsyncValue.data(currentSettings.copyWith(theme: theme));

    // 【永続化】: SharedPreferencesにテーマを保存
    // 【非同期保存】: バックグラウンドで保存処理を実行
    // 🔵 青信号: REQ-5003（設定永続化）に基づく
    try {
      // 【保存処理】: enum indexをintとして保存
      // 🔵 青信号: SharedPreferencesの標準的な保存方法
      await _prefs?.setInt('theme', theme.index);
    } catch (e) {
      // 【エラーハンドリング】: 保存失敗時の処理
      // 【楽観的更新維持】: 保存失敗してもUI状態は更新済み（REQ-2008）
      // 🟡 黄信号: TC-012（書き込み失敗）に対応（詳細な検証は実装後）

      // 【ログ記録】: エラー内容を記録（実装後にloggerを追加予定）
      // 【ユーザー通知】: 再起動時に設定が戻る可能性をユーザーに通知（将来実装）
      // 🟡 黄信号: 将来的な改善予定
    }
  }

  /// 【機能概要】: TTS速度を変更する
  /// 【実装方針】: 楽観的更新でUI即座反映、SharedPreferencesに非同期保存、TTSNotifierと連携
  /// 【テスト対応】: TC-049-001〜TC-049-006、TC-049-015（境界値）
  /// 🔵 信頼性レベル: REQ-404、REQ-2007、REQ-5003に基づく
  ///
  /// パラメータ: `speed` - 新しいTTS速度
  Future<void> setTTSSpeed(TTSSpeed speed) async {
    // 【実装内容】: TTS速度を変更し、SharedPreferencesに保存、TTSNotifierに反映
    // 【楽観的更新】: 保存完了を待たずにUI状態を更新（REQ-2007: 即座反映）
    // 【TTS連携】: TTSNotifierのsetSpeedを呼び出して実際の速度を更新
    // 🔵 青信号: REQ-2007（即座反映）、REQ-5003（永続化）、REQ-404（TTS速度設定）に基づく

    // 【現在の設定取得】: AsyncValueから現在の設定を取得
    // 【エラーチェック】: 現在の状態がロード済みでない場合は処理をスキップ
    // 🔵 青信号: Riverpod AsyncNotifierの標準的なパターン
    final currentSettings = state.valueOrNull;
    if (currentSettings == null) return;

    // 【状態更新】: copyWithで新しい設定を生成し、stateを更新
    // 【楽観的更新】: SharedPreferences保存前にUI状態を更新（即座反映）
    // 🔵 青信号: REQ-2007（即座反映）に基づく
    state = AsyncValue.data(currentSettings.copyWith(ttsSpeed: speed));

    // 【TTS速度反映】: TTSNotifierのsetSpeedを呼び出して実際の速度を更新
    // 【非同期連携】: TTSエンジンに新しい速度を設定
    // 🔵 青信号: TC-049-007〜TC-049-009（速度別読み上げ）に対応
    try {
      final ttsNotifier = ref.read(ttsProvider.notifier);
      await ttsNotifier.setSpeed(speed);
    } catch (e) {
      // 【エラーハンドリング】: TTS速度設定失敗時の処理
      // 【状態維持】: TTS設定失敗してもアプリ設定の状態は更新済み
      // 🟡 黄信号: 将来的な改善予定（ログ記録等）
    }

    // 【永続化】: SharedPreferencesにTTS速度を保存
    // 【非同期保存】: バックグラウンドで保存処理を実行
    // 🔵 青信号: REQ-5003（設定永続化）に基づく
    try {
      // 【保存処理】: enum nameを文字列として保存
      // 🔵 青信号: SharedPreferencesの標準的な保存方法
      await _prefs?.setString('tts_speed', speed.name);
    } catch (e) {
      // 【エラーハンドリング】: 保存失敗時の処理
      // 【楽観的更新維持】: 保存失敗してもUI状態は更新済み（REQ-2007）
      // 🟡 黄信号: TC-012（書き込み失敗）に対応（詳細な検証は実装後）

      // 【ログ記録】: エラー内容を記録（実装後にloggerを追加予定）
      // 【ユーザー通知】: 再起動時に設定が戻る可能性をユーザーに通知（将来実装）
      // 🟡 黄信号: 将来的な改善予定
    }
  }
}
