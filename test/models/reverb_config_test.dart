import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/src/models/reverb_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  group('ReverbConfig', () {
    Future<Map<String, String>> mockAuthorizer(
      String channelName,
      String socketId,
    ) async {
      return {
        'Authorization': 'Bearer test-token',
        'X-Custom-Header': 'test-value',
      };
    }

    test('should instantiate with correct default values', () {
      final config = ReverbConfig(appKey: 'app-key', host: 'localhost');

      expect(config.appKey, equals('app-key'));
      expect(config.host, equals('localhost'));
      expect(config.port, equals(443));
      expect(config.useTLS, isFalse);

      final defaultWebSocket = config.createNewWebsocketConnection(
        Uri.parse('wss://example.com'),
        headers: {'Authorization': 'Bearer test'},
      );
      expect(defaultWebSocket, isA<WebSocketChannel>());
    });

    test('should support copyWith for all fields', () {
      final original = ReverbConfig(
        appKey: 'original-key',
        port: 443,
        pingInterval: Duration(seconds: 25),
        apiKey: 'original-api',
        cluster: 'local',
        authorizer: mockAuthorizer,
        authEndpoint: 'https://original-auth-endpoint',
        wsPath: '/original-ws',
        useTLS: false,
        reconnectAttempts: 3,
        reconnectDelay: Duration(seconds: 2),
        maxReconnectDelay: Duration(seconds: 10),
        webSocketFactory: (_, {headers}) => throw UnimplementedError(),
        additionalHeaders: {'X-Test': 'Header'},
      );

      final newAuthorizer = (_, __) async => {
        'Authorization': 'Bearer test-token',
      };
      final newFactory = (_, {headers}) => throw Exception('stub');

      final modified = original.copyWith(
        appKey: 'updated-key',
        pingInterval: Duration(seconds: 30),
        apiKey: 'updated-api',
        cluster: 'staging',
        authorizer: newAuthorizer,
        authEndpoint: 'https://updated-auth-endpoint',
        wsPath: '/updated-ws',
        useTLS: true,
        reconnectAttempts: 7,
        reconnectDelay: Duration(seconds: 5),
        maxReconnectDelay: Duration(seconds: 20),
        webSocketFactory: newFactory,
        additionalHeaders: {'X-New': 'Header'},
      );

      expect(modified.appKey, 'updated-key');
      expect(modified.port, 443);
      expect(modified.pingInterval, Duration(seconds: 30));
      expect(modified.apiKey, 'updated-api');
      expect(modified.cluster, 'staging');
      expect(modified.authorizer, newAuthorizer);
      expect(modified.authEndpoint, 'https://updated-auth-endpoint');
      expect(modified.wsPath, '/updated-ws');
      expect(modified.useTLS, isTrue);
      expect(modified.reconnectAttempts, 7);
      expect(modified.reconnectDelay, Duration(seconds: 5));
      expect(modified.maxReconnectDelay, Duration(seconds: 20));
      expect(modified.webSocketFactory, same(newFactory));
      expect(modified.additionalHeaders, {'X-New': 'Header'});
    });

    test(
      'copyWith should retain all original values if no overrides provided',
      () {
        final original = ReverbConfig(
          appKey: 'keep-key',
          host: 'keep-host',
          port: 9999,
        );

        final copied = original.copyWith();

        expect(copied.appKey, equals(original.appKey));
        expect(copied.host, equals(original.host));
        expect(copied.port, equals(original.port));
      },
    );

    test('should compare equal when values match', () {
      Future<Map<String, String>> mockAuthorizer(String _, String __) async => {
        'Authorization': 'token',
      };
      final factory = (Uri _, {dynamic headers}) => throw UnimplementedError();

      final config1 = ReverbConfig(
        appKey: 'same-key',
        host: 'same-host',
        port: 443,
        pingInterval: Duration(seconds: 30),
        apiKey: 'same-api-key',
        cluster: null,
        authorizer: mockAuthorizer,
        authEndpoint: 'https://auth-endpoint.com',
        wsPath: '/ws',
        useTLS: true,
        reconnectAttempts: 5,
        reconnectDelay: Duration(seconds: 2),
        maxReconnectDelay: Duration(seconds: 10),
        additionalHeaders: {'X-Custom': 'value'},
        webSocketFactory: factory,
      );

      final config2 = ReverbConfig(
        appKey: 'same-key',
        host: 'same-host',
        port: 443,
        pingInterval: Duration(seconds: 30),
        apiKey: 'same-api-key',
        cluster: null,
        authorizer: mockAuthorizer,
        authEndpoint: 'https://auth-endpoint.com',
        wsPath: '/ws',
        useTLS: true,
        reconnectAttempts: 5,
        reconnectDelay: Duration(seconds: 2),
        maxReconnectDelay: Duration(seconds: 10),
        additionalHeaders: {'X-Custom': 'value'},
        webSocketFactory: factory,
      );

      expect(config1, equals(config2));
    });

    test('should produce consistent hashCode for identical configs', () {
      Future<Map<String, String>> mockAuthorizer(String _, String __) async => {
        'Authorization': 'token',
      };
      final factory = (Uri _, {dynamic headers}) => throw UnimplementedError();

      final config1 = ReverbConfig(
        appKey: 'same-key',
        host: 'same-host',
        port: 443,
        pingInterval: Duration(seconds: 30),
        apiKey: 'same-api-key',
        cluster: null,
        authorizer: mockAuthorizer,
        authEndpoint: 'https://auth-endpoint.com',
        wsPath: '/ws',
        useTLS: true,
        reconnectAttempts: 5,
        reconnectDelay: Duration(seconds: 2),
        maxReconnectDelay: Duration(seconds: 10),
        additionalHeaders: {'X-Custom': 'value'},
        webSocketFactory: factory,
      );

      final config2 = ReverbConfig(
        appKey: 'same-key',
        host: 'same-host',
        port: 443,
        pingInterval: Duration(seconds: 30),
        apiKey: 'same-api-key',
        cluster: null,
        authorizer: mockAuthorizer,
        authEndpoint: 'https://auth-endpoint.com',
        wsPath: '/ws',
        useTLS: true,
        reconnectAttempts: 5,
        reconnectDelay: Duration(seconds: 2),
        maxReconnectDelay: Duration(seconds: 10),
        additionalHeaders: {'X-Custom': 'value'},
        webSocketFactory: factory,
      );

      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('should compare unequal when values differ', () {
      final config1 = ReverbConfig(appKey: 'key1', host: 'same-host');
      final config2 = ReverbConfig(appKey: 'key2', host: 'other-host');

      expect(config1, isNot(equals(config2)));
    });

    test(
      'should throw assertion error if neither host nor cluster is provided',
      () {
        expect(
          () => ReverbConfig(appKey: 'app-key'),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test(
      'should throw assertion error if both host and cluster are provided',
      () {
        expect(
          () => ReverbConfig(
            appKey: 'app-key',
            host: 'localhost',
            cluster: 'test-cluster',
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test('should throw assertion error if port is invalid (0)', () {
      expect(
        () => ReverbConfig(appKey: 'app-key', host: 'localhost', port: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should throw assertion error if port is invalid (>65535)', () {
      expect(
        () => ReverbConfig(appKey: 'app-key', host: 'localhost', port: 70000),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should not throw if only host is provided', () {
      expect(
        () => ReverbConfig(appKey: 'app-key', host: 'localhost'),
        returnsNormally,
      );
    });

    test('should not throw if only cluster is provided', () {
      expect(
        () => ReverbConfig(appKey: 'app-key', cluster: 'us-east-1'),
        returnsNormally,
      );
    });
  });
}
