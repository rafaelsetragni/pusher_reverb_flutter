import 'dart:convert';

sealed class JsonUtil {
  /// Encodes a Dart object into a JSON string.
  static String encode(Object? data) {
    return jsonEncode(data);
  }

  /// Decodes a JSON string into a Dart object.
  static dynamic decode(String source) {
    return jsonDecode(source);
  }
}
