import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'package:pusher_reverb_flutter/src/models/reverb_config.dart';

void main() {
  group('ReverbClientBuilder', () {
    test('should throw if configuration is not set', () {
      final builder = ReverbClientBuilder();

      expect(() => builder.build(), throwsA(isA<ReverbClientException>()));
    });

    test('should build ReverbClient if configuration is set', () {
      final config = ReverbConfig(
        apiKey: 'test-key',
        cluster: 'local',
        appKey: 'test-app',
      );

      final builder = ReverbClientBuilder().setConfiguration(config);
      final client = builder.build();

      expect(client, isA<ReverbClient>());
    });
  });
}
