import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/src/utils/json_util.dart';

void main() {
  group('JsonUtil', () {
    test('encode returns valid JSON string', () {
      final map = {'key': 'value', 'number': 123};
      final encoded = JsonUtil.encode(map);
      expect(encoded, isA<String>());
      expect(encoded, '{"key":"value","number":123}');
    });

    test('decode returns correct map from JSON string', () {
      final jsonStr = '{"key":"value","number":123}';
      final decoded = JsonUtil.decode(jsonStr);
      expect(decoded, isA<Map<String, dynamic>>());
      expect(decoded['key'], 'value');
      expect(decoded['number'], 123);
    });

    test('encode of null returns "null"', () {
      expect(JsonUtil.encode(null), 'null');
    });

    test('decode of "null" returns null', () {
      expect(JsonUtil.decode('null'), null);
    });

    test('decode of invalid JSON throws FormatException', () {
      expect(() => JsonUtil.decode('{invalid json}'), throwsFormatException);
    });
  });
}
