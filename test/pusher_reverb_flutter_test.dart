import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/src/models/reverb_config.dart';

void main() {
  group('ReverbClient', () {
    test('creates instance with required parameters', () {
      final client = ReverbConfig(
        host: 'localhost',
        port: 8080,
        appKey: 'test-app-key',
      );

      expect(client.host, 'localhost');
      expect(client.port, 8080);
      expect(client.appKey, 'test-app-key');
    });
  });
}
