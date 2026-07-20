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

      // 【フォントサイズ復元】: SharedPreferencesからフォントサイズを読み込む
      // 【永続化形式】: 新形式（enum name文字列）を優先し、旧形式（enum index int）が
      // 残っている場合は読み替えた上でstring形式へマイグレーションする
      // 🔵 青信号: TC-014（null安全性）、TC-072-008（旧形式からの復元）に対応
      final fontSize = await _restoreEnumWithMigration(
        'fontSize',
        FontSize.values,
        FontSize.medium,
      );

      // 【テーマ復元】: SharedPreferencesからテーマを読み込む
      // 【永続化形式】: 新形式（enum name文字列）を優先し、旧形式（enum index int）が
      // 残っている場合は読み替えた上でstring形式へマイグレーションする
      // 🔵 青信号: TC-009（テーマ復元）、TC-014（null安全性）、TC-073-006（旧形式からの復元）に対応
      final theme = await _restoreEnumWithMigration(
        'theme',
        AppTheme.values,
        AppTheme.light,
      );

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
      final hasAcceptedAIPrivacyPolicy =
          _prefs!.getBool('ai_privacy_consent') ?? false;

      // 【シンプルモード復元】: SharedPreferencesからシンプルモードのON/OFFを復元
      // 【永続化形式】: bool値をそのまま保存（enum化不要のためマイグレーション対象外）
      // 🟡 信頼性レベル: 黄信号 - fix/improvement-p0-p2で追加
      final simpleMode = _prefs!.getBool('simple_mode') ?? false;

      // 【TTS速度のエンジンへの反映について】: 復元した速度を実際のTTSエンジンへ
      // 反映する処理は、ここ（SettingsNotifier.build()）からTTSNotifierへ
      // push するのではなく、TTSNotifier側（tts_provider.dart の
      // `_applyPersistedSpeedIfAvailable`）がSettingsNotifierから pull する
      // 一方向の依存関係にしている。
      //
      // 【レビューで判明した重大バグ】: 以前はここでも
      // `if (ref.exists(ttsProvider)) { await ref.read(ttsProvider.notifier)
      // .setSpeed(ttsSpeed); }` という逆方向（Settings→TTS）の反映を
      // 行っていたが、これは実アプリのHomeScreen.build()内で
      // `ref.watch(settingsNotifierProvider)` の直後に
      // `ref.listen(ttsProvider, ...)` が呼ばれる実行順（同一同期フレーム内で
      // 両Providerが生成される）と組み合わさると、以下の循環待機による
      // **デッドロック**を引き起こすことを確認した:
      //   SettingsNotifier.build()
      //     → await ttsProvider.notifier.setSpeed()
      //       → await _initFuture
      //         → await _applyPersistedSpeedIfAvailable()
      //           → await ref.read(settingsNotifierProvider.future)  // ← build()自身の完了待ち
      // この結果 settingsNotifierProvider.future が永久に解決せず、
      // アプリ起動直後に設定画面・AI丁寧さ・フォントサイズ等がすべて
      // デフォルト値のまま固まってしまう（再現テストで確認済み）。
      // TTS→Settingsの一方向pull（tts_provider.dart側）だけで
      // 「再起動後に保存済み速度がTTSエンジンへ反映される」という
      // 本来の目的は満たされるため、逆方向のpushは行わない。
      // 🔵 信頼性レベル: REQ-404（読み上げ速度設定）、REQ-5003（設定永続化）に基づく

      // 【設定復元】: 復元済みのenum値からAppSettingsインスタンスを生成
      // 【境界値チェック】: 旧形式の index値が範囲外の場合はデフォルト値を使用
      // 🔵 青信号: TC-015、TC-016（境界値テスト）に対応
      return AppSettings(
        fontSize: fontSize,
        theme: theme,
        ttsSpeed: ttsSpeed,
        aiPoliteness: aiPoliteness,
        hasAcceptedAIPrivacyPolicy: hasAcceptedAIPrivacyPolicy,
        simpleMode: simpleMode,
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

  /// 【ヘルパー関数】: SharedPreferencesからenum値を安全に復元し、旧形式（int index）
  /// で保存されていた場合は新形式（String name）へマイグレーションする
  /// 【背景】: enumの並び替え・要素追加が起きると、int indexでの永続化は
  /// 既存ユーザーの設定値が別の値に化ける危険がある（例: TTSSpeedへのverySlow追加）。
  /// 本メソッドはfontSize/themeの永続化キーをString name方式に統一するための
  /// 後方互換読み込み・書き戻し処理を担う。
  /// 🔵 信頼性レベル: REQ-5003（設定永続化）、NFR-304（堅牢性）に基づく
  ///
  /// パラメータ:
  /// - `key`: SharedPreferencesのキー名
  /// - `enumValues`: 変換対象のenumのvaluesリスト
  /// - `defaultValue`: 未保存・不正値時のデフォルト値
  ///
  /// 【処理フロー】:
  /// 1. `SharedPreferences.get()`で型を問わず生の値を取得する
  /// 2. Stringの場合（新形式） → `_restoreEnumFromName`で復元
  /// 3. intの場合（旧形式） → 範囲内ならenumへ変換し、String形式で再保存
  ///    （マイグレーション）。範囲外ならデフォルト値
  /// 4. null・その他の型 → デフォルト値
  ///
  /// 戻り値: 復元されたenum値（旧形式からの読み替え、または新形式からの復元）
  Future<T> _restoreEnumWithMigration<T extends Enum>(
    String key,
    List<T> enumValues,
    T defaultValue,
  ) async {
    // 【型を問わない取得】: getString()/getInt()は保存済みの値の型と異なると
    // 例外を投げる可能性があるため、型を問わないget()で安全に読み取る
    // 🔵 青信号: SharedPreferencesのAPI仕様に基づく
    final raw = _prefs!.get(key);

    if (raw is String) {
      // 【新形式】: enum name文字列として復元
      return _restoreEnumFromName(raw, enumValues, defaultValue);
    }

    if (raw is int) {
      // 【旧形式】: enum indexとして復元を試みる
      // 【境界値チェック】: 範囲外の場合はデフォルト値にフォールバック
      // 🔵 青信号: TC-072-010、TC-073-010（範囲外index）に対応
      if (raw < 0 || raw >= enumValues.length) {
        return defaultValue;
      }

      final migrated = enumValues[raw];

      // 【マイグレーション】: 次回以降はString形式で読み込めるよう再保存する
      // 【エラーハンドリング】: 再保存に失敗しても、今回の読み込み結果自体は
      // 正しく返す（NFR-301: 基本機能継続）
      try {
        await _prefs!.setString(key, migrated.name);
      } catch (_) {
        // 再保存失敗時もアプリはクラッシュさせない
      }

      return migrated;
    }

    // 【null・未知の型】: デフォルト値を使用
    return defaultValue;
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
    final currentSettings = state.asData?.value;
    if (currentSettings == null) return;

    // 【状態更新】: copyWithで新しい設定を生成し、stateを更新
    // 【楽観的更新】: SharedPreferences保存前にUI状態を更新（即座反映）
    // 🔵 青信号: REQ-2007（即座反映）に基づく
    state = AsyncValue.data(currentSettings.copyWith(fontSize: fontSize));

    // 【永続化】: SharedPreferencesにフォントサイズを保存
    // 【非同期保存】: バックグラウンドで保存処理を実行
    // 🔵 青信号: REQ-5003（設定永続化）に基づく
    try {
      // 【保存処理】: enum nameを文字列として保存
      // 【フォーマット統一】: index保存はenumの並び替え・追加で値が化けるため、
      // name文字列で保存する（読み込み側は_restoreEnumWithMigrationで旧形式もサポート）
      // 🔵 青信号: SharedPreferencesの標準的な保存方法
      await _prefs?.setString('fontSize', fontSize.name);
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
    final currentSettings = state.asData?.value;
    if (currentSettings == null) return;

    // 【状態更新】: copyWithで新しい設定を生成し、stateを更新
    // 【楽観的更新】: SharedPreferences保存前にUI状態を更新（即座反映）
    // 🔵 青信号: REQ-2008（即座反映）に基づく
    state = AsyncValue.data(currentSettings.copyWith(theme: theme));

    // 【永続化】: SharedPreferencesにテーマを保存
    // 【非同期保存】: バックグラウンドで保存処理を実行
    // 🔵 青信号: REQ-5003（設定永続化）に基づく
    try {
      // 【保存処理】: enum nameを文字列として保存
      // 【フォーマット統一】: index保存はenumの並び替え・追加で値が化けるため、
      // name文字列で保存する（読み込み側は_restoreEnumWithMigrationで旧形式もサポート）
      // 🔵 青信号: SharedPreferencesの標準的な保存方法
      await _prefs?.setString('theme', theme.name);
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
    final currentSettings = state.asData?.value;
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
    final currentSettings = state.asData?.value;
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

  /// 【機能概要】: AI変換のプライバシー同意状態を変更する
  /// 【実装方針】: 明示同意をSharedPreferencesへ永続化し、次回以降の再確認を省略する
  /// 🔵 信頼性レベル: NFR-102（AI変換時の明示的な同意取得）に基づく
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

  /// 【機能概要】: シンプルモードのON/OFFを切り替える
  /// 【実装方針】: 楽観的更新でUI即座反映、SharedPreferencesに非同期保存
  /// 【背景】: 疲労時・症状進行時に文字盤なしの大ボタン画面へ切り替えるための設定。
  /// 誤操作で意図せず切り替わったままにならないよう、ホーム画面・設定画面
  /// 双方から同じメソッドで確実にトグルできるようにする。
  /// 🟡 信頼性レベル: 黄信号 - fix/improvement-p0-p2で追加
  Future<void> setSimpleMode(bool enabled) async {
    final currentSettings = state.asData?.value;
    if (currentSettings == null) return;

    state = AsyncValue.data(currentSettings.copyWith(simpleMode: enabled));

    try {
      await _prefs?.setBool('simple_mode', enabled);
    } catch (e) {
      // 【エラーハンドリング】: 保存失敗時の処理
      // 【楽観的更新維持】: 保存失敗してもUI状態は更新済み
    }
  }
}
