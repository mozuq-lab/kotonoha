// 文字盤コミュニケーション支援アプリ（kotonoha）
// Dart/Flutter インターフェース定義
//
// 🔵 信頼性レベル凡例:
// - 🔵 青信号: EARS要件定義書・設計文書を参考にした確実な定義
// - 🟡 黄信号: EARS要件定義書・設計文書から妥当な推測による定義
// - 🔴 赤信号: EARS要件定義書・設計文書にない推測による定義

// ================================================================================
// エンティティ定義
// ================================================================================

/// 定型文エンティティ 🔵
/// REQ-101, REQ-104, REQ-105, REQ-106
class PresetPhrase {
  /// 一意識別子
  final String id;

  /// 定型文の内容
  final String content;

  /// カテゴリ（「日常」「体調」「その他」）
  final PresetCategory category;

  /// お気に入りフラグ
  final bool isFavorite;

  /// 作成日時
  final DateTime createdAt;

  /// 更新日時
  final DateTime updatedAt;

  /// 並び順（お気に入り内での優先度）
  final int displayOrder;

  const PresetPhrase({
    required this.id,
    required this.content,
    required this.category,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.displayOrder = 0,
  });

  /// JSONからの変換
  factory PresetPhrase.fromJson(Map<String, dynamic> json) {
    return PresetPhrase(
      id: json['id'] as String,
      content: json['content'] as String,
      category: PresetCategory.values.byName(json['category'] as String),
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  /// JSONへの変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'category': category.name,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'display_order': displayOrder,
    };
  }

  /// copyWithメソッド（不変オブジェクトのための更新）
  PresetPhrase copyWith({
    String? id,
    String? content,
    PresetCategory? category,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? displayOrder,
  }) {
    return PresetPhrase(
      id: id ?? this.id,
      content: content ?? this.content,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}

/// 定型文カテゴリ列挙型 🔵
/// REQ-106
enum PresetCategory {
  daily('日常'),
  health('体調'),
  other('その他');

  final String displayName;
  const PresetCategory(this.displayName);
}

/// 履歴エンティティ 🔵
/// REQ-601, REQ-602, REQ-603, REQ-604
class History {
  /// 一意識別子
  final String id;

  /// 読み上げ・表示したテキスト内容
  final String content;

  /// 作成日時（読み上げ・表示した日時）
  final DateTime createdAt;

  /// 履歴の種類（文字盤入力、定型文、AI変換結果等）
  final HistoryType type;

  const History({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.type,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      type: HistoryType.values.byName(json['type'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'type': type.name,
    };
  }
}

/// 履歴の種類 🟡
enum HistoryType {
  manualInput('文字盤入力'),
  preset('定型文'),
  aiConverted('AI変換結果'),
  quickButton('大ボタン');

  final String displayName;
  const HistoryType(this.displayName);
}

/// お気に入りエンティティ 🔵
/// REQ-701, REQ-702, REQ-703, REQ-704
class Favorite {
  /// 一意識別子
  final String id;

  /// お気に入り登録したテキスト内容
  final String content;

  /// 作成日時（お気に入り登録日時）
  final DateTime createdAt;

  /// 並び順（ユーザーがカスタマイズ可能）
  final int displayOrder;

  const Favorite({
    required this.id,
    required this.content,
    required this.createdAt,
    this.displayOrder = 0,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'display_order': displayOrder,
    };
  }

  Favorite copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    int? displayOrder,
  }) {
    return Favorite(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}

/// アプリ設定エンティティ 🔵
/// REQ-404, REQ-801, REQ-803, REQ-903
class AppSettings {
  /// フォントサイズ設定
  final FontSize fontSize;

  /// テーマ設定
  final AppTheme theme;

  /// TTS読み上げ速度
  final TTSSpeed ttsSpeed;

  /// AI変換の丁寧さレベル
  final PolitenessLevel aiPoliteness;

  /// AI変換機能の有効/無効
  final bool aiConversionEnabled;

  const AppSettings({
    this.fontSize = FontSize.medium,
    this.theme = AppTheme.light,
    this.ttsSpeed = TTSSpeed.normal,
    this.aiPoliteness = PolitenessLevel.normal,
    this.aiConversionEnabled = true,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      fontSize: FontSize.values.byName(json['font_size'] as String? ?? 'medium'),
      theme: AppTheme.values.byName(json['theme'] as String? ?? 'light'),
      ttsSpeed: TTSSpeed.values.byName(json['tts_speed'] as String? ?? 'normal'),
      aiPoliteness: PolitenessLevel.values.byName(json['ai_politeness'] as String? ?? 'normal'),
      aiConversionEnabled: json['ai_conversion_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'font_size': fontSize.name,
      'theme': theme.name,
      'tts_speed': ttsSpeed.name,
      'ai_politeness': aiPoliteness.name,
      'ai_conversion_enabled': aiConversionEnabled,
    };
  }

  AppSettings copyWith({
    FontSize? fontSize,
    AppTheme? theme,
    TTSSpeed? ttsSpeed,
    PolitenessLevel? aiPoliteness,
    bool? aiConversionEnabled,
  }) {
    return AppSettings(
      fontSize: fontSize ?? this.fontSize,
      theme: theme ?? this.theme,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      aiPoliteness: aiPoliteness ?? this.aiPoliteness,
      aiConversionEnabled: aiConversionEnabled ?? this.aiConversionEnabled,
    );
  }
}

/// フォントサイズ設定 🔵
/// REQ-801
enum FontSize {
  small('小'),
  medium('中'),
  large('大');

  final String displayName;
  const FontSize(this.displayName);
}

/// アプリテーマ設定 🔵
/// REQ-803
enum AppTheme {
  light('ライトモード'),
  dark('ダークモード'),
  highContrast('高コントラストモード');

  final String displayName;
  const AppTheme(this.displayName);
}

/// TTS読み上げ速度 🔵
/// REQ-404
enum TTSSpeed {
  slow('遅い'),
  normal('普通'),
  fast('速い');

  final String displayName;
  const TTSSpeed(this.displayName);

  /// TTS APIに渡す速度値（0.5 〜 2.0）
  double get value {
    switch (this) {
      case TTSSpeed.slow:
        return 0.7;
      case TTSSpeed.normal:
        return 1.0;
      case TTSSpeed.fast:
        return 1.3;
    }
  }
}

/// AI変換の丁寧さレベル 🔵
/// REQ-903
enum PolitenessLevel {
  casual('カジュアル'),
  normal('普通'),
  polite('丁寧');

  final String displayName;
  const PolitenessLevel(this.displayName);
}

// ================================================================================
// APIリクエスト/レスポンス型定義
// ================================================================================

/// AI変換リクエスト 🔵
/// REQ-901, REQ-902, REQ-903
class AIConversionRequest {
  /// 変換元のテキスト（短い入力）
  final String inputText;

  /// 丁寧さレベル
  final PolitenessLevel politenessLevel;

  const AIConversionRequest({
    required this.inputText,
    required this.politenessLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'input_text': inputText,
      'politeness_level': politenessLevel.name,
    };
  }
}

/// AI変換レスポンス 🔵
/// REQ-901, REQ-902, REQ-904
class AIConversionResponse {
  /// 変換成功フラグ
  final bool success;

  /// 変換後のテキスト（丁寧で自然な文章）
  final String? convertedText;

  /// エラーメッセージ（失敗時）
  final String? errorMessage;

  /// エラーコード（失敗時）
  final String? errorCode;

  const AIConversionResponse({
    required this.success,
    this.convertedText,
    this.errorMessage,
    this.errorCode,
  });

  factory AIConversionResponse.fromJson(Map<String, dynamic> json) {
    return AIConversionResponse(
      success: json['success'] as bool,
      convertedText: json['converted_text'] as String?,
      errorMessage: json['error_message'] as String?,
      errorCode: json['error_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'converted_text': convertedText,
      'error_message': errorMessage,
      'error_code': errorCode,
    };
  }
}

/// 汎用APIレスポンス 🟡
class ApiResponse<T> {
  /// 成功フラグ
  final bool success;

  /// レスポンスデータ
  final T? data;

  /// エラー情報
  final ApiError? error;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse(
      success: true,
      data: data,
    );
  }

  factory ApiResponse.failure(ApiError error) {
    return ApiResponse(
      success: false,
      error: error,
    );
  }
}

/// APIエラー情報 🟡
class ApiError {
  /// エラーコード
  final String code;

  /// エラーメッセージ
  final String message;

  /// HTTPステータスコード
  final int? statusCode;

  const ApiError({
    required this.code,
    required this.message,
    this.statusCode,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String,
      message: json['message'] as String,
      statusCode: json['status_code'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'status_code': statusCode,
    };
  }
}

// ================================================================================
// UI状態定義
// ================================================================================

/// 入力画面の状態 🔵
class InputScreenState {
  /// 現在の入力テキスト
  final String inputText;

  /// 読み上げ中フラグ
  final bool isSpeaking;

  /// AI変換処理中フラグ
  final bool isConvertingAI;

  /// 対面表示モードフラグ
  final bool isFaceToFaceMode;

  /// 画面回転（180度）フラグ
  final bool isRotated180;

  /// エラーメッセージ
  final String? errorMessage;

  const InputScreenState({
    this.inputText = '',
    this.isSpeaking = false,
    this.isConvertingAI = false,
    this.isFaceToFaceMode = false,
    this.isRotated180 = false,
    this.errorMessage,
  });

  InputScreenState copyWith({
    String? inputText,
    bool? isSpeaking,
    bool? isConvertingAI,
    bool? isFaceToFaceMode,
    bool? isRotated180,
    String? errorMessage,
  }) {
    return InputScreenState(
      inputText: inputText ?? this.inputText,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isConvertingAI: isConvertingAI ?? this.isConvertingAI,
      isFaceToFaceMode: isFaceToFaceMode ?? this.isFaceToFaceMode,
      isRotated180: isRotated180 ?? this.isRotated180,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 緊急呼び出し状態 🔵
/// REQ-301, REQ-302, REQ-303, REQ-304
enum EmergencyState {
  /// 通常状態
  normal,

  /// 確認ダイアログ表示中
  confirmationDialog,

  /// 緊急音再生中・画面赤表示中
  alertActive,
}

/// ネットワーク接続状態 🔵
/// REQ-1001, REQ-1002
enum NetworkState {
  /// オンライン（AI変換利用可能）
  online,

  /// オフライン（基本機能のみ）
  offline,

  /// 接続確認中
  checking,
}

/// AI変換結果状態 🔵
/// REQ-902, REQ-904
class AIConversionResultState {
  /// 元の入力テキスト
  final String originalText;

  /// 変換後のテキスト
  final String convertedText;

  /// ユーザーの選択待ち状態
  final bool isPending;

  const AIConversionResultState({
    required this.originalText,
    required this.convertedText,
    this.isPending = true,
  });

  AIConversionResultState copyWith({
    String? originalText,
    String? convertedText,
    bool? isPending,
  }) {
    return AIConversionResultState(
      originalText: originalText ?? this.originalText,
      convertedText: convertedText ?? this.convertedText,
      isPending: isPending ?? this.isPending,
    );
  }
}

// ================================================================================
// 共通型・ユーティリティ
// ================================================================================

/// ローディング状態 🟡
enum LoadingState {
  /// アイドル
  idle,

  /// ローディング中
  loading,

  /// 成功
  success,

  /// エラー
  error,
}

/// データソース結果型 🟡
class Result<T, E> {
  final T? data;
  final E? error;
  final bool isSuccess;

  const Result._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  factory Result.success(T data) {
    return Result._(data: data, isSuccess: true);
  }

  factory Result.failure(E error) {
    return Result._(error: error, isSuccess: false);
  }

  bool get isFailure => !isSuccess;
}

/// 定型文初期データサンプル 🔵
/// REQ-107
class PresetPhraseInitialData {
  /// 50-100個程度の汎用的な定型文サンプル
  static List<PresetPhrase> getInitialPresets() {
    final now = DateTime.now();

    return [
      // 日常カテゴリ
      PresetPhrase(
        id: 'preset_001',
        content: 'おはようございます',
        category: PresetCategory.daily,
        createdAt: now,
        updatedAt: now,
        displayOrder: 1,
      ),
      PresetPhrase(
        id: 'preset_002',
        content: 'こんにちは',
        category: PresetCategory.daily,
        createdAt: now,
        updatedAt: now,
        displayOrder: 2,
      ),
      PresetPhrase(
        id: 'preset_003',
        content: 'こんばんは',
        category: PresetCategory.daily,
        createdAt: now,
        updatedAt: now,
        displayOrder: 3,
      ),
      PresetPhrase(
        id: 'preset_004',
        content: 'ありがとうございます',
        category: PresetCategory.daily,
        createdAt: now,
        updatedAt: now,
        displayOrder: 4,
      ),
      PresetPhrase(
        id: 'preset_005',
        content: 'お願いします',
        category: PresetCategory.daily,
        createdAt: now,
        updatedAt: now,
        displayOrder: 5,
      ),
      PresetPhrase(
        id: 'preset_006',
        content: 'すみません',
        category: PresetCategory.daily,
        createdAt: now,
        updatedAt: now,
        displayOrder: 6,
      ),
      PresetPhrase(
        id: 'preset_007',
        content: 'おやすみなさい',
        category: PresetCategory.daily,
        createdAt: now,
        updatedAt: now,
        displayOrder: 7,
      ),

      // 体調カテゴリ
      PresetPhrase(
        id: 'preset_101',
        content: '痛いです',
        category: PresetCategory.health,
        createdAt: now,
        updatedAt: now,
        displayOrder: 1,
      ),
      PresetPhrase(
        id: 'preset_102',
        content: '頭が痛いです',
        category: PresetCategory.health,
        createdAt: now,
        updatedAt: now,
        displayOrder: 2,
      ),
      PresetPhrase(
        id: 'preset_103',
        content: 'お腹が痛いです',
        category: PresetCategory.health,
        createdAt: now,
        updatedAt: now,
        displayOrder: 3,
      ),
      PresetPhrase(
        id: 'preset_104',
        content: 'トイレに行きたいです',
        category: PresetCategory.health,
        createdAt: now,
        updatedAt: now,
        displayOrder: 4,
      ),
      PresetPhrase(
        id: 'preset_105',
        content: '暑いです',
        category: PresetCategory.health,
        createdAt: now,
        updatedAt: now,
        displayOrder: 5,
      ),
      PresetPhrase(
        id: 'preset_106',
        content: '寒いです',
        category: PresetCategory.health,
        createdAt: now,
        updatedAt: now,
        displayOrder: 6,
      ),
      PresetPhrase(
        id: 'preset_107',
        content: 'お水をください',
        category: PresetCategory.health,
        createdAt: now,
        updatedAt: now,
        displayOrder: 7,
      ),

      // その他カテゴリ
      PresetPhrase(
        id: 'preset_201',
        content: '少し待ってください',
        category: PresetCategory.other,
        createdAt: now,
        updatedAt: now,
        displayOrder: 1,
      ),
      PresetPhrase(
        id: 'preset_202',
        content: 'もう一度お願いします',
        category: PresetCategory.other,
        createdAt: now,
        updatedAt: now,
        displayOrder: 2,
      ),

      // ... 50-100個程度まで拡張予定
    ];
  }
}
