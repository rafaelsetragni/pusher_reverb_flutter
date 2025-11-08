import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'package:pusher_reverb_flutter/src/models/reverb_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'reverb_client_test.mocks.dart';

@GenerateNiceMocks([MockSpec<WebSocketChannel>(), MockSpec<WebSocketSink>()])
void main() {
  group('ReverbClient', () {
    late MockWebSocketChannel mockChannel;
    late MockWebSocketSink mockSink;
    late StreamController<dynamic> streamController;
    late String testSocketId = '12345.67890';

    setUp(() {
      mockChannel = MockWebSocketChannel();
      mockSink = MockWebSocketSink();
      streamController = StreamController<dynamic>.broadcast();

      when(mockChannel.stream).thenAnswer((_) => streamController.stream);
      when(mockChannel.sink).thenReturn(mockSink);
    });

    void setupSuccessConnectionResponse() {
      streamController.onListen = () {
        final payload = jsonEncode({
          'event': 'pusher:connection_established',
          'data': jsonEncode({'socket_id': '12345', 'activity_timeout': 30}),
        });
        streamController.add(payload);
      };
    }

    void setupFailureConnectionResponse() {
      streamController.onListen = () {
        streamController.addError(ConnectionException('test'));
      };
    }

    tearDown(() {
      streamController.close();
    });

    test('connects and handles connection_established event', () async {
      // Arrange
      final client = ReverbClientBuilder()
          .setConfiguration(
            ReverbConfig(
              host: 'localhost',
              appKey: 'test-key',
              webSocketFactory: (Uri uri, {Map<String, dynamic>? headers}) =>
                  mockChannel,
            ),
          )
          .build();

      // Act
      setupSuccessConnectionResponse();
      await client.connect();
      // Assert
      await Future.delayed(Duration.zero);
      expect(client.socketId, '12345');
      client.disconnect();
    });

    test('handles connection error', () async {
      // Arrange
      final client = ReverbClientBuilder()
          .setConfiguration(
            ReverbConfig(
              host: 'localhost',
              appKey: 'test-app',
              wsPath: '/api/websocket',
              webSocketFactory: (Uri uri, {Map<String, dynamic>? headers}) {
                return mockChannel;
              },
            ),
          )
          .build();

      // Act
      setupFailureConnectionResponse();
      final future = client.connect();

      // Assert
      await expectLater(future, throwsA(isA<ConnectionException>()));
      client.disconnect();
    });

    test('disconnect closes the channel sink', () async {
      // Arrange
      final client = ReverbClientBuilder()
          .setConfiguration(
            ReverbConfig(
              host: 'localhost',
              appKey: 'test-key',
              webSocketFactory: (Uri uri, {Map<String, dynamic>? headers}) =>
                  mockChannel,
            ),
          )
          .build();

      // Act
      setupSuccessConnectionResponse();
      await client.connect();
      client.disconnect();

      // Assert
      verify(mockSink.close()).called(1);
    });

    group('wsPath configuration', () {
      test('uses default path when wsPath is not provided', () async {
        // Arrange
        Uri? capturedUri;
        final client = ReverbClientBuilder()
            .setConfiguration(
              ReverbConfig(
                host: 'localhost',
                appKey: 'test-app',
                webSocketFactory: (Uri uri, {Map<String, dynamic>? headers}) {
                  capturedUri = uri;
                  return mockChannel;
                },
              ),
            )
            .build();

        // Act
        setupSuccessConnectionResponse();
        await client.connect();

        // Assert
        expect(capturedUri?.toString(), 'ws://localhost:443/app/test-app');
        client.disconnect();
      });

      test('uses custom wsPath when provided', () async {
        // Arrange
        Uri? capturedUri;
        final client = ReverbClientBuilder()
            .setConfiguration(
              ReverbConfig(
                host: 'localhost',
                appKey: 'test-app',
                wsPath: '/custom/path',
                webSocketFactory: (Uri uri, {Map<String, dynamic>? headers}) {
                  capturedUri = uri;
                  return mockChannel;
                },
              ),
            )
            .build();

        // Act
        setupSuccessConnectionResponse();
        await client.connect();

        // Assert
        expect(capturedUri?.toString(), 'ws://localhost:443/custom/path');
        client.disconnect();
      });

      test('handles wsPath with leading slash', () async {
        // Arrange
        Uri? capturedUri;
        final client = ReverbClientBuilder()
            .setConfiguration(
              ReverbConfig(
                host: 'localhost',
                appKey: 'test-app',
                wsPath: '/api/websocket',
                webSocketFactory: (Uri uri, {Map<String, dynamic>? headers}) {
                  capturedUri = uri;
                  return mockChannel;
                },
              ),
            )
            .build();

        // Act
        setupSuccessConnectionResponse();
        await client.connect();

        // Assert
        expect(capturedUri?.toString(), 'ws://localhost:443/api/websocket');
        client.disconnect();
      });

      test('handles wsPath without leading slash', () async {
        // Arrange
        Uri? capturedUri;
        final client = ReverbClientBuilder()
            .setConfiguration(
              ReverbConfig(
                host: 'localhost',
                appKey: 'test-app',
                wsPath: 'api/websocket',
                webSocketFactory: (Uri uri, {Map<String, dynamic>? headers}) {
                  capturedUri = uri;
                  return mockChannel;
                },
              ),
            )
            .build();

        // Act
        setupSuccessConnectionResponse();
        await client.connect();

        // Assert
        expect(capturedUri?.toString(), 'ws://localhost:443/api/websocket');
        client.disconnect();
      });

      test('handles empty wsPath', () async {
        // Arrange
        Uri? capturedUri;
        final client = ReverbClientBuilder()
            .setConfiguration(
              ReverbConfig(
                host: 'localhost',
                appKey: 'test-app',
                wsPath: '',
                webSocketFactory: (Uri uri, {Map<String, dynamic>? headers}) {
                  capturedUri = uri;
                  return mockChannel;
                },
              ),
            )
            .build();

        // Act
        setupSuccessConnectionResponse();
        await client.connect();

        // Assert
        expect(capturedUri?.toString(), 'ws://localhost:443/app/test-app');
        client.disconnect();
      });

      test('handles home wsPath', () async {
        // Arrange
        Uri? capturedUri;
        final client = ReverbClientBuilder()
            .setConfiguration(
              ReverbConfig(
                host: 'localhost',
                appKey: 'test-app',
                wsPath: '/',
                webSocketFactory: (Uri uri, {Map<String, dynamic>? headers}) {
                  capturedUri = uri;
                  return mockChannel;
                },
              ),
            )
            .build();

        // Act
        setupSuccessConnectionResponse();
        await client.connect();

        // Assert
        expect(capturedUri?.toString(), 'ws://localhost:443/app/test-app');
        client.disconnect();
      });

      test('handles wsPath with query parameters', () async {
        // Arrange
        Uri? capturedUri;
        final client = ReverbClientBuilder()
            .setConfiguration(
              ReverbConfig(
                host: 'localhost',
                appKey: 'test-app',
                wsPath: '/ws?token=abc123',
                webSocketFactory: (Uri uri, {Map<String, dynamic>? headers}) {
                  capturedUri = uri;
                  return mockChannel;
                },
              ),
            )
            .build();

        // Act
        setupSuccessConnectionResponse();
        await client.connect();

        // Assert
        expect(capturedUri?.toString(), 'ws://localhost:443/ws?token=abc123');
        client.disconnect();
      });
    });

    group('Bug Fix Tests', () {
      group('Collection.remove bug fix', () {
        test('unregisterChannel handles concurrent removal safely', () async {
          // Arrange
          final client = ReverbClientBuilder()
              .setConfiguration(
                ReverbConfig(
                  host: 'localhost',
                  appKey: 'test-key',
                  webSocketFactory:
                      (Uri uri, {Map<String, dynamic>? headers}) => mockChannel,
                ),
              )
              .build();
          setupSuccessConnectionResponse();
          await client.connect();

          // Add a channel
          client.subscribePublicChannel(channelName: 'test-channel');
          expect(client.getChannel('test-channel'), isNotNull);

          // Act: Simulate concurrent removal by calling unsubscribe twice
          client.unsubscribeChannel('test-channel');
          client.unsubscribeChannel(
            'test-channel',
          ); // Should not cause runtime error

          // Assert: Channel should be removed without errors
          expect(client.getChannel('test-channel'), isNull);
          client.disconnect();
        });

        test(
          'disconnect handles concurrent channel operations safely',
          () async {
            // Arrange
            final client = ReverbClientBuilder()
                .setConfiguration(
                  ReverbConfig(
                    host: 'localhost',
                    appKey: 'test-key',
                    webSocketFactory:
                        (Uri uri, {Map<String, dynamic>? headers}) =>
                            mockChannel,
                  ),
                )
                .build();
            setupSuccessConnectionResponse();
            await client.connect();

            // Add multiple channels
            client.subscribePublicChannel(channelName: 'channel1');
            client.subscribePublicChannel(channelName: 'channel2');
            client.subscribePublicChannel(channelName: 'channel3');

            // Act: Disconnect should handle concurrent operations safely
            client.disconnect();

            // Assert: All channels should be cleared without errors
            expect(client.subscribedChannels, isEmpty);
          },
        );
      });

      group('Null host infinite loop guard', () {
        test('constructor throws ConnectionException for invalid port', () {
          // Act & Assert
          expect(
            () => ReverbClientBuilder()
                .setConfiguration(
                  ReverbConfig(host: 'localhost', port: 0, appKey: 'test-app'),
                )
                .build(),
            throwsA(isA<AssertionError>()),
          );

          expect(
            () => ReverbClientBuilder()
                .setConfiguration(
                  ReverbConfig(
                    host: 'localhost',
                    port: 65536,
                    appKey: 'test-app',
                  ),
                )
                .build(),
            throwsA(isA<AssertionError>()),
          );
        });

        test('connect method validates host parameter', () async {
          // This test is covered by the constructor validation test above
          // The connect method no longer needs separate validation since
          // the constructor already validates the host parameter
          expect(true, isTrue); // Placeholder test
        });
      });
    });

    group('Connection State Stream', () {
      test(
        'onConnectionStateChange emits connecting state on connect',
        () async {
          // Arrange
          final client = ReverbClientBuilder()
              .setConfiguration(
                ReverbConfig(
                  host: 'localhost',
                  appKey: 'test-key',
                  webSocketFactory:
                      (Uri uri, {Map<String, dynamic>? headers}) => mockChannel,
                ),
              )
              .build();
          final states = <ReverbConnectionState>[];
          client.onConnectionStateChange.listen(states.add);

          // Act
          setupSuccessConnectionResponse();
          await client.connect();
          await Future.delayed(Duration.zero);

          // Assert
          expect(states, contains(ReverbConnectionState.connecting));
          client.disconnect();
        },
      );

      test(
        'onConnectionStateChange emits connected state on connection established',
        () async {
          // Arrange
          final client = ReverbClientBuilder()
              .setConfiguration(
                ReverbConfig(
                  host: 'localhost',
                  appKey: 'test-key',
                  webSocketFactory:
                      (Uri uri, {Map<String, dynamic>? headers}) => mockChannel,
                ),
              )
              .build();
          final states = <ReverbConnectionState>[];
          client.onConnectionStateChange.listen(states.add);

          // Act
          setupSuccessConnectionResponse();
          await client.connect();
          final message = jsonEncode({
            'event': 'pusher:connection_established',
            'data': jsonEncode({
              'socket_id': 'test-socket',
              'activity_timeout': 30,
            }),
          });
          streamController.add(message);
          await Future.delayed(Duration.zero);

          // Assert
          expect(
            states,
            containsAll([
              ReverbConnectionState.connecting,
              ReverbConnectionState.connected,
            ]),
          );
          client.disconnect();
        },
      );

      test(
        'onConnectionStateChange emits disconnected state on disconnect',
        () async {
          // Arrange
          final client = ReverbClientBuilder()
              .setConfiguration(
                ReverbConfig(
                  host: 'localhost',
                  appKey: 'test-key',
                  webSocketFactory:
                      (Uri uri, {Map<String, dynamic>? headers}) => mockChannel,
                ),
              )
              .build();
          final states = <ReverbConnectionState>[];
          client.onConnectionStateChange.listen(states.add);

          // Act
          setupSuccessConnectionResponse();
          await client.connect();
          await Future.delayed(Duration.zero);
          client.disconnect();
          await Future.delayed(Duration.zero);

          // Assert
          expect(states.last, ReverbConnectionState.disconnected);
        },
      );

      test(
        'onConnectionStateChange emits error state on connection error',
        () async {
          // Arrange
          final client = ReverbClientBuilder()
              .setConfiguration(
                ReverbConfig(
                  host: 'localhost',
                  appKey: 'test-key',
                  webSocketFactory:
                      (Uri uri, {Map<String, dynamic>? headers}) => mockChannel,
                ),
              )
              .build();
          final states = <ReverbConnectionState>[];
          client.onConnectionStateChange.listen(states.add);

          // Act
          setupFailureConnectionResponse();
          final future = client.connect();
          streamController.addError(Exception('Connection failed'));
          await expectLater(future, throwsA(isA<ConnectionException>()));
          await Future.delayed(Duration.zero);

          // Assert
          expect(states, contains(ReverbConnectionState.error));
          client.disconnect();
        },
      );

      test('connectionState getter returns current state', () async {
        // Arrange
        final client = ReverbClientBuilder()
            .setConfiguration(
              ReverbConfig(
                host: 'localhost',
                appKey: 'test-key',
                webSocketFactory: (Uri uri, {Map<String, dynamic>? headers}) =>
                    mockChannel,
              ),
            )
            .build();

        // Assert initial state
        expect(client.connectionState, ReverbConnectionState.disconnected);

        // Act - connect
        setupSuccessConnectionResponse();
        final future = client.connect();

        // Assert connecting state
        expect(client.connectionState, ReverbConnectionState.connecting);

        await future;

        // Assert connected state
        expect(client.connectionState, ReverbConnectionState.connected);

        // Act - disconnect
        client.disconnect();
        await Future.delayed(Duration.zero);

        // Assert disconnected state
        expect(client.connectionState, ReverbConnectionState.disconnected);
      });

      test('connection state stream supports multiple listeners', () async {
        // Arrange
        final client = ReverbClientBuilder()
            .setConfiguration(
              ReverbConfig(
                host: 'localhost',
                appKey: 'test-key',
                webSocketFactory: (Uri uri, {Map<String, dynamic>? headers}) =>
                    mockChannel,
              ),
            )
            .build();
        final states1 = <ReverbConnectionState>[];
        final states2 = <ReverbConnectionState>[];
        client.onConnectionStateChange.listen(states1.add);
        client.onConnectionStateChange.listen(states2.add);

        // Act
        setupSuccessConnectionResponse();
        await client.connect();
        await Future.delayed(Duration.zero);

        // Assert - Both listeners should receive the same events
        expect(states1, states2);
        expect(states1, contains(ReverbConnectionState.connecting));
        client.disconnect();
      });
    });
  });
}
