/// AI変換を初めて使うときの同意画面
///
/// App Store 5.1.2(i): 何を・誰に送るかを示す。
/// 個人情報保護法 28 条（施行規則 17 条 2 項）: 外国の名称・その国の制度・提供先の措置を
/// 同意の前に示す（2026-10-03、安全側に倒すと人が決定）。2026-10-31 に、最初の本文を短くし、
/// 残りを同じ画面の「詳しく見る」で読める形にすると人が決めた。
/// 送り先を変えたらプライバシーポリシーの「外国にある第三者への提供について」と一緒に直す。
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/utils/spoken_label.dart';
import 'package:kotonoha_app/shared/widgets/confirmation_dialog.dart';

/// AI変換の同意画面
class AIPrivacyConsentDialog extends StatelessWidget {
  static const _message = 'AI変換を使うと、入力した文章と選んだ丁寧さが、'
      '米国の Cloudflare, Inc. のAIサービスへ送られます（再生成では前回の変換結果も）。'
      '処理は日本の外で行われることがあります。\n'
      'ことのはのサーバーは内容を保存しません。'
      '同社は、送られた文章をAIの学習やサービスの改善に使わないとしています。';

  static const _details = '文章はことのはのサーバーを経由して送られます。'
      '処理は同社の世界各地の設備で行われ、どの国かは前もって特定できません。\n'
      '米国には連邦の包括的な個人情報保護法が無く、'
      '分野ごとの法律と州の法律（カリフォルニア州のCCPAなど）があります。\n'
      '日本の法律に基づく保護は、同社の契約に明記されていません。\n'
      '詳しくはプライバシーポリシー（mozuq-lab.github.io/kotonoha/privacy-policy.html）の'
      '「外国にある第三者への提供について」をご覧ください。';

  /// 同意しないとき
  final VoidCallback onCancel;

  /// 同意するとき
  final VoidCallback onConfirm;

  /// AIPrivacyConsentDialogを作成する
  const AIPrivacyConsentDialog({
    super.key,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title: 'AI変換の利用確認',
      message: _message,
      details: ExpansionTile(
        key: const Key('ai_privacy_consent_details'),
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
        expandedAlignment: Alignment.centerLeft,
        title: const Text('詳しく見る'),
        children: [Text(_details, semanticsLabel: spokenLabel(_details))],
      ),
      cancelLabel: '同意しない',
      confirmLabel: '同意して利用',
      kind: ConfirmKind.normal,
      onCancel: onCancel,
      onConfirm: onConfirm,
    );
  }
}
