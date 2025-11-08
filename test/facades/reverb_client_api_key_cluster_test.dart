import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'package:pusher_reverb_flutter/src/models/reverb_config.dart';

void main() {
  group('ReverbClient API Key and Cluster Tests', () {
    group('API Key Support', () {
      test('should store API key when provided', () {
        const apiKey = 'test-api-key';

        final config = ReverbConfig(
          host: 'localhost',
          port: 8080,
          appKey: 'test-app-key',
          apiKey: apiKey,
        );

        expect(config.apiKey, equals(apiKey));
      });

      test('should work without API key (backward compatibility)', () {
        final config = ReverbConfig(
          host: 'localhost',
          port: 8080,
          appKey: 'test-app-key',
          // No API key provided
        );

        expect(config.apiKey, isNull);
      });

      test('should throw exception for empty API key', () {
        expect(
          () => ReverbConfig(
            host: 'localhost',
            port: 8080,
            appKey: 'test-app-key',
            apiKey: '', // Empty API key
          ),
          throwsAssertionError,
        );
      });
    });

    group('Cluster Support', () {
      test('should resolve us-east-1 cluster configuration', () {
        final config = ReverbConfig(
          port: 8080, // This should be overridden
          appKey: 'test-app-key',
          cluster: 'us-east-1',
          useTLS: false, // This should be overridden
        );

        expect(config.effectiveHost, equals('reverb-us-east-1.pusher.com'));
        expect(config.effectivePort, equals(443));
        expect(config.effectiveUseTLS, equals(true));
        expect(config.isUsingCluster, equals(true));
      });

      test('should resolve eu-west-1 cluster configuration', () {
        final config = ReverbConfig(
          port: 8080,
          appKey: 'test-app-key',
          cluster: 'eu-west-1',
        );

        expect(config.effectiveHost, equals('reverb-eu-west-1.pusher.com'));
        expect(config.effectivePort, equals(443));
        expect(config.effectiveUseTLS, equals(true));
      });

      test('should resolve local cluster configuration', () {
        final config = ReverbConfig(
          port: 9000,
          appKey: 'test-app-key',
          cluster: 'local',
        );

        expect(config.effectiveHost, equals('localhost'));
        expect(config.effectivePort, equals(8080));
        expect(config.effectiveUseTLS, equals(false));
      });

      test('should throw exception for invalid cluster', () {
        expect(
          () => ReverbConfig(
            port: 8080,
            appKey: 'test-app-key',
            cluster: 'invalid-cluster',
          ),
          throwsAssertionError,
        );
      });

      test('Cluster configuration should prevail over host configuration', () {
        final config = ReverbConfig(
          host: 'localhost',
          appKey: 'test-app-key',
          cluster: 'us-east-1',
        );
        expect(config.effectiveHost, equals('reverb-us-east-1.pusher.com'));
        expect(config.host, equals('reverb-us-east-1.pusher.com'));
      });

      test('should return available clusters', () {
        final clusters = ReverbClient.availableClusters;
        expect(clusters, contains('us-east-1'));
        expect(clusters, contains('eu-west-1'));
        expect(clusters, contains('local'));
        expect(clusters, isNotEmpty);
      });

      test('should get cluster configuration', () {
        final config = ReverbClient.getClusterConfig('us-east-1');
        expect(config, isNotNull);
        expect(config!.host, equals('reverb-us-east-1.pusher.com'));
        expect(config.port, equals(443));
        expect(config.useTLS, equals(true));
      });
    });

    group('Backward Compatibility', () {
      test('should work with existing parameters only', () {
        final config = ReverbConfig(
          host: 'localhost',
          port: 8080,
          appKey: 'test-app-key',
          // No new parameters
        );

        expect(config.effectiveHost, equals('localhost'));
        expect(config.effectivePort, equals(8080));
        expect(config.effectiveUseTLS, equals(false));
        expect(config.isUsingCluster, equals(false));
      });
    });

    group('Configuration Access', () {
      test('should provide access to resolved configuration', () {
        final client = ReverbClientBuilder()
            .setConfiguration(
              ReverbConfig(appKey: 'test-app-key', cluster: 'us-east-1'),
            )
            .build();

        final resolvedConfig = client.reverbConfig;
        expect(resolvedConfig.host, equals('reverb-us-east-1.pusher.com'));
        expect(resolvedConfig.port, equals(443));
        expect(resolvedConfig.useTLS, equals(true));
      });
    });

    group('Edge Cases', () {
      test('should handle null API key gracefully', () {
        final config = ReverbConfig(
          host: 'localhost',
          port: 8080,
          appKey: 'test-app-key',
          apiKey: null,
        );

        expect(config.apiKey, isNull);
      });

      test('should throw exception for empty cluster', () {
        expect(
          () => ReverbConfig(
            host: 'localhost',
            port: 8080,
            appKey: 'test-app-key',
            cluster: '', // Empty cluster should throw exception
          ),
          throwsAssertionError,
        );
      });

      test('should handle special characters in API key', () {
        const apiKey = 'test-api-key-with-special-chars!@#\$%^&*()';

        final config = ReverbConfig(
          host: 'localhost',
          port: 8080,
          appKey: 'test-app-key',
          apiKey: apiKey,
        );

        expect(config.apiKey, equals(apiKey));
      });

      test('should handle very long API key', () {
        final apiKey = 'a' * 1000; // Very long API key

        final config = ReverbConfig(
          host: 'localhost',
          port: 8080,
          appKey: 'test-app-key',
          apiKey: apiKey,
        );

        expect(config.apiKey, equals(apiKey));
      });
    });
  });
}
