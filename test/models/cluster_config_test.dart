import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

void main() {
  group('ClusterConfig', () {
    test('should correctly assign properties', () {
      const config = ClusterConfig(
        host: 'test-host',
        port: 1234,
        useTLS: true,
        region: 'test-region',
        additionalHeaders: {'Authorization': 'Bearer token'},
      );

      expect(config.host, 'test-host');
      expect(config.port, 1234);
      expect(config.useTLS, isTrue);
      expect(config.region, 'test-region');
      expect(config.additionalHeaders, {'Authorization': 'Bearer token'});
    });

    test('should return correct string representation', () {
      const config = ClusterConfig(
        host: 'host',
        port: 80,
        useTLS: false,
        region: 'dev',
      );

      expect(
        config.toString(),
        'ClusterConfig(host: host, port: 80, useTLS: false, region: dev)',
      );
    });

    test('should compare equal for identical configs', () {
      const config1 = ClusterConfig(
        host: 'host',
        port: 80,
        useTLS: true,
        region: 'us-east-1',
      );

      const config2 = ClusterConfig(
        host: 'host',
        port: 80,
        useTLS: true,
        region: 'us-east-1',
      );

      expect(config1 == config2, isTrue);
    });

    test('should return false for configs with different properties', () {
      const config1 = ClusterConfig(
        host: 'host1',
        port: 443,
        useTLS: true,
        region: 'us-east-1',
      );

      const config2 = ClusterConfig(
        host: 'host2',
        port: 443,
        useTLS: true,
        region: 'us-east-1',
      );

      const config3 = ClusterConfig(
        host: 'host1',
        port: 80,
        useTLS: true,
        region: 'us-east-1',
      );

      const config4 = ClusterConfig(
        host: 'host1',
        port: 443,
        useTLS: false,
        region: 'us-east-1',
      );

      const config5 = ClusterConfig(
        host: 'host1',
        port: 443,
        useTLS: true,
        region: 'eu-west-1',
      );

      expect(config1 == config2, isFalse);
      expect(config1 == config3, isFalse);
      expect(config1 == config4, isFalse);
      expect(config1 == config5, isFalse);
    });

    test('should return correct hashCode', () {
      const config = ClusterConfig(
        host: 'host',
        port: 443,
        useTLS: true,
        region: 'us-west-2',
      );

      final expectedHash = Object.hash('host', 443, true, 'us-west-2');
      expect(config.hashCode, expectedHash);
    });

    test('should return known cluster from region', () {
      final config = ClusterConfig.fromRegion('us-east-1');
      expect(config, isNotNull);
      expect(config!.host, 'reverb-us-east-1.pusher.com');
    });

    test('should return null for unknown region', () {
      final config = ClusterConfig.fromRegion('unknown');
      expect(config, isNull);
    });

    test('should return all available cluster keys', () {
      final clusters = ClusterConfig.availableClusters;
      expect(
        clusters,
        containsAll([
          'us-east-1',
          'us-west-2',
          'eu-west-1',
          'ap-southeast-1',
          'local',
          'staging',
        ]),
      );
    });
  });
}
