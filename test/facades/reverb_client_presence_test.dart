import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'package:pusher_reverb_flutter/src/models/reverb_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'reverb_client_encrypted_test.mocks.dart';

@GenerateNiceMocks([MockSpec<WebSocketChannel>(), MockSpec<WebSocketSink>()])
void main() {
  group('ReverbClient Presence Channel Integration', () {
    late String testSocketId;
    late StreamController<dynamic> streamController;
    late MockWebSocketChannel mockChannel;
    late MockWebSocketSink mockSink;

    setUp(() {
      testSocketId = '1234.5678';

      streamController = StreamController<dynamic>.broadcast();
      mockChannel = MockWebSocketChannel();
      mockSink = MockWebSocketSink();
      when(mockChannel.stream).thenAnswer((_) => streamController.stream);
      when(mockChannel.sink).thenReturn(mockSink);
    });

    tearDown(() async {
      await streamController.close();
    });

    void setupSuccessConnectionResponse() {
      streamController.onListen = () {
        final payload = jsonEncode({
          'event': 'pusher:connection_established',
          'data': jsonEncode({
            'socket_id': testSocketId,
            'activity_timeout': 30,
          }),
        });
        streamController.add(payload);
      };
    }

    group('subscribeToPresenceChannel', () {
      test('should throw error if authorizer is not configured', () {
        final clientWithoutAuthorizer = ReverbClientBuilder()
            .setConfiguration(
              ReverbConfig(
                host: 'localhost',
                appKey: 'test-key',
                authEndpoint: 'https://example.com/auth',
              ),
            )
            .build();

        expect(
          () => clientWithoutAuthorizer.subscribePresenceChannel(
            channelName: 'presence-room',
          ),
          throwsA(isA<Exception>()),
        );
      });
      test('should throw error if authEndpoint is not configured', () {
        final mockAuthorizer = (String channelName, String socketId) async {
          return {'Authorization': 'Bearer test-token'};
        };

        final clientWithoutEndpoint = ReverbClientBuilder()
            .setConfiguration(
              ReverbConfig(
                host: 'localhost',
                appKey: 'test-key',
                authorizer: mockAuthorizer,
              ),
            )
            .build();

        expect(
          () => clientWithoutEndpoint.subscribePresenceChannel(
            channelName: 'presence-room',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw error for invalid presence channel name', () async {
        final mockAuthorizer = (String channelName, String socketId) async {
          return {'auth': 'test-token'};
        };
        final client = ReverbClientBuilder()
            .setConfiguration(
              ReverbConfig(
                host: 'localhost',
                appKey: 'test-key',
                authorizer: mockAuthorizer,
                authEndpoint: 'https://example.com/auth',
                webSocketFactory: (Uri uri, {Map<String, dynamic>? headers}) =>
                    mockChannel,
              ),
            )
            .build();
        addTearDown(() async {
          client.disconnect();
        });

        setupSuccessConnectionResponse();
        await client.connect();

        expect(
          () => client.subscribePresenceChannel(channelName: 'private-channel'),
          throwsA(isA<InvalidChannelNameException>()),
        );
      });

      test('should create PresenceChannel with valid name', () async {
        final mockAuthorizer = (String channelName, String socketId) async {
          return {'auth': 'test-token'};
        };

        final client = ReverbClientBuilder()
            .setConfiguration(
              ReverbConfig(
                host: 'localhost',
                appKey: 'test-key',
                authorizer: mockAuthorizer,
                authEndpoint: 'https://example.com/auth',
                webSocketFactory: (Uri uri, {Map<String, dynamic>? headers}) =>
                    mockChannel,
              ),
            )
            .build();
        addTearDown(() async {
          client.disconnect();
        });

        setupSuccessConnectionResponse();
        await client.connect();

        final channel = client.subscribePresenceChannel(
          channelName: 'presence-room',
        );

        expect(channel, isA<ReverbPresenceChannel>());
        expect(channel.name, 'presence-room');
        expect(channel.state, ChannelState.subscribing);
      });

      test('should create PresenceChannel with channel data', () async {
        final mockAuthorizer = (String channelName, String socketId) async {
          return {'auth': 'test-token'};
        };
        final testChannelData = {
          'user_id': '123',
          'user_info': {'name': 'John Doe'},
        };

        final client = ReverbClientBuilder()
            .setConfiguration(
              ReverbConfig(
                host: 'localhost',
                appKey: 'test-key',
                authorizer: mockAuthorizer,
                authEndpoint: 'https://example.com/auth',
                webSocketFactory: (Uri uri, {Map<String, dynamic>? headers}) =>
                    mockChannel,
              ),
            )
            .build();
        addTearDown(() async {
          client.disconnect();
        });

        setupSuccessConnectionResponse();
        await client.connect();

        final channel = client.subscribePresenceChannel(
          channelName: 'presence-room',
          channelData: testChannelData,
        );

        expect(channel, isA<ReverbPresenceChannel>());
        expect(channel.channelData, testChannelData);
      });
    });
  });
}
