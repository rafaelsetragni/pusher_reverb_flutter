import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/src/utils/base64_util.dart';

void main() {
  group('Base64Util', () {
    test('should encode a string to base64', () {
      final input = 'Hello, world!';
      final expected = base64Encode(utf8.encode(input));
      final result = Base64Util.encode(input);
      expect(result, expected);
    });

    test('should decode a base64 string back to original', () {
      final input = 'Hello, world!';
      final encoded = Base64Util.encode(input);
      final decoded = Base64Util.decode(encoded);
      expect(utf8.decode(decoded), input);
    });

    test('should handle empty string encoding and decoding', () {
      final input = '';
      final encoded = Base64Util.encode(input);
      final decoded = Base64Util.decode(encoded);
      expect(encoded, '');
      expect(decoded, []);
    });
  });
}
