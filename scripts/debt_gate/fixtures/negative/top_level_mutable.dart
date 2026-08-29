// 陰性 fixture（Dart）— 1件も検出されてはならない。

const int maxRetries = 3;
final String appName = 'kotonoha';
late final String lazyButFinal;

String greet(String name) {
  var buffer = name; // 関数内は対象外
  return buffer;
}

class Repository {
  var cache = <String, String>{};
}
