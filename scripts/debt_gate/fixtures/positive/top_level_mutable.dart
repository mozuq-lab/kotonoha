// 陽性 fixture（Dart）— トップレベルの可変変数は検出されなければならない。
// お気に入りが4箇所に散った件（ADR-005）と同じ形の入口。

var currentUserName = 'unset';
late String cachedPhrase;

class Presenter {
  var instanceField = 0; // クラス内はインデントされるので対象外
  void run() {
    var local = 1; // 関数内も対象外
    print(local);
  }
}
