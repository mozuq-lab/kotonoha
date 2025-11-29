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
import '../../ai_conversion/domain/models/politeness_level.dart';

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

      // 【TTS速度復元】: SharedPreferencesからTTS速度を安全に復元
      // 【DRY改善】: 共通のenum復元パターンをヘルパーメソッドで実装
      // 🔵 青信号: TC-049-013〜015（null安全性、不正値フォールバック、境界値テスト）に対応
      final ttsSpeed = _restoreEnumFromName(
        _prefs!.getString('tts_speed'),
        TTSSpeed.values,
        TTSSpeed.normal,
      );

      // 【AI丁寧さレベル復元】: SharedPreferencesからAI丁寧さレベルを安全に復元
      // 【DRY改善】: 共通のenum復元パターンをヘルパーメソッドで実装
      // 🔵 青信号: TC-074-012、TC-074-015（設定復元、不正値フォールバック）に対応
      final aiPoliteness = _restoreEnumFromName(
        _prefs!.getString('ai_politeness'),
        PolitenessLevel.values,
        PolitenessLevel.normal,
      );

      // 【設定復元】: index値からenumに変換してAppSettingsインスタンスを生成
      // 【境界値チェック】: index値が範囲外の場合はデフォルト値を使用
      // 🔵 青信号: TC-015、TC-016（境界値テスト）に対応
      return AppSettings(
        fontSize: FontSize.values[fontSizeIndex],
        theme: AppTheme.values[themeIndex],
        ttsSpeed: ttsSpeed,
        aiPoliteness: aiPoliteness,
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

  /// 【ヘルパー関数】: SharedPreferencesから読み込んだenum名を対応するenum値に安全に変換
  /// 【再利用性】: TTS速度、AI丁寧さレベルなど、name保存されたenumの復元に共通利用
  /// 【単一責任】: enum name文字列からenum値への変換とエラーハンドリングを担当
  /// 【リファクタリング改善】: 重複していた復元ロジックをDRY原則に基づき共通化
  /// 🔵 信頼性レベル: 既存の個別実装パターンを汎用化
  ///
  /// パラメータ:
  /// - `savedName`: SharedPreferencesから読み込んだenum name文字列（nullの可能性あり）
  /// - `enumValues`: 変換対象のenumのvaluesリスト（例: TTSSpeed.values）
  /// - `defaultValue`: null/不正値時のデフォルト値（例: TTSSpeed.normal）
  ///
  /// 戻り値: 復元されたenum値、または不正値時はデフォルト値
  ///
  /// 【処理フロー】:
  /// 1. savedNameがnullの場合 → デフォルト値を返す
  /// 2. enumValues内でnameが一致する値を検索
  /// 3. 見つからない場合や例外発生時 → デフォルト値を返す
  ///
  /// 【パフォーマンス】: firstWhereでO(n)の線形検索、enum値は通常3〜10個程度なので実用上問題なし
  /// 【null安全性】: null入力、不正な文字列、予期しない例外すべてに対応
  /// 【型制約】: T extends Enumにより、enum型のみを受け入れることを保証
  T _restoreEnumFromName<T extends Enum>(
    String? savedName,
    List<T> enumValues,
    T defaultValue,
  ) {
    // 【null安全性】: SharedPreferencesから読み込んだ値がnullの場合の対処
    // 【早期リターン】: 不正な入力に対して早期にデフォルト値を返す
    // 🔵 青信号: null安全性テストケース（TC-049-013、TC-074-012）に対応
    if (savedName == null) {
      return defaultValue;
    }

    try {
      // 【enum検索】: name文字列と一致するenum値を検索
      // 【型安全性】: T extends Enumにより、e.nameが型安全にアクセス可能
      // 【不正値対応】: 一致する値が見つからない場合はorElseでデフォルト値を返す
      // 🔵 青信号: 不正値フォールバックテスト（TC-049-014、TC-074-015）に対応
      return enumValues.firstWhere(
        (e) => e.name == savedName,
        orElse: () => defaultValue,
      );
    } catch (_) {
      // 【例外処理】: 予期しないエラーが発生した場合の安全策
      // 【堅牢性】: どのような状況でもアプリがクラッシュしないよう保証
      // 🟡 黄信号: 防御的プログラミング、極めて稀なケースを想定
      return defaultValue;
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

  /// 【機能概要】: AI丁寧さレベルを変更する
  /// 【実装方針】: 楽観的更新でUI即座反映、SharedPreferencesに非同期保存
  /// 【テスト対応】: TC-071-018（AI丁寧さレベル変更）
  /// 🔵 信頼性レベル: REQ-903、REQ-5003に基づく
  ///
  /// パラメータ: `level` - 新しいAI丁寧さレベル
  Future<void> setAIPoliteness(PolitenessLevel level) async {
    // 【実装内容】: AI丁寧さレベルを変更し、SharedPreferencesに保存
    // 【楽観的更新】: 保存完了を待たずにUI状態を更新
    // 🔵 青信号: REQ-903（AI丁寧さレベル設定）、REQ-5003（永続化）に基づく

    // 【現在の設定取得】: AsyncValueから現在の設定を取得
    final currentSettings = state.valueOrNull;
    if (currentSettings == null) return;

    // 【状態更新】: copyWithで新しい設定を生成し、stateを更新
    state = AsyncValue.data(currentSettings.copyWith(aiPoliteness: level));

    // 【永続化】: SharedPreferencesにAI丁寧さレベルを保存
    try {
      await _prefs?.setString('ai_politeness', level.name);
    } catch (e) {
      // 【エラーハンドリング】: 保存失敗時の処理
      // 【楽観的更新維持】: 保存失敗してもUI状態は更新済み
    }
  }
}
