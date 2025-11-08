import 'dart:convert';
import 'dart:typed_data';

sealed class Base64Util {
  static String encode(String input) {
    return base64.encode(utf8.encode(input));
  }

  static Uint8List decode(String base64Str) {
    return base64.decode(base64Str);
  }
}
