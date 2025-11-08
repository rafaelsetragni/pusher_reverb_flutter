import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'package:pusher_reverb_flutter/src/models/reverb_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'reverb_client_test.mocks.dart';

@GenerateNiceMocks([MockSpec<WebSocketChannel>(), MockSpec<WebSocketSink>()])
void main() {
  group('ReverbClient Encrypted Channel Integration', () {
    late String testSocketId = '12345.67890';
    late String testEncryptionKey;
    late Authorizer mockAuthorizer;
    late String testAuthEndpoint;

    late MockWebSocketChannel mockChannel;
    late MockWebSocketSink mockSink;
    late StreamController<dynamic> streamController;
    late ReverbClient client;

    final connectionEstablishedPayload = jsonEncode({
      'event': 'pusher:connection_established',
      'data': jsonEncode({'socket_id': '1234567890.123456'}),
    });

    void setupSuccessConnectionResponse() {
      streamController.onListen = () {
        streamController.add(connectionEstablishedPayload);
      };
    }

    void setupSubscriptionSuccessResponse() {
      when(mockSink.add(any)).thenAnswer((invocation) {
        final sentData = invocation.positionalArguments.first;
        final jsonData = jsonDecode(sentData);
        if (jsonData['event'] == 'pusher:subscribe') {
          final channel = jsonData['data']['channel'];
          final subscriptionSucceededPayload = jsonEncode({
            'event': 'pusher_internal:subscription_succeeded',
            'channel': channel,
            'data': '{}',
          });
          streamController.add(subscriptionSucceededPayload);
        }
      });
    }

    String generateEncryptionKey() {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      final base64Key = base64.encode(keyBytes);
      return base64Key;
    }

    setUp(() {
      testEncryptionKey = generateEncryptionKey();
      mockChannel = MockWebSocketChannel();
      mockSink = MockWebSocketSink();
      streamController = StreamController<dynamic>.broadcast();

      when(mockChannel.stream).thenAnswer((_) => streamController.stream);
      when(mockChannel.sink).thenReturn(mockSink);

      testAuthEndpoint = 'https://example.com/auth';

      final mockAuthorizer = (String channelName, String socketId) async {
        return {'Authorization': 'Bearer test-token'};
      };

      client = ReverbClientBuilder()
          .setConfiguration(
            ReverbConfig(
              host: 'localhost',
              appKey: 'app-key',
              webSocketFactory: (Uri uri, {Map<String, dynamic>? headers}) =>
                  mockChannel,
              authorizer: mockAuthorizer,
              authEndpoint: testAuthEndpoint,
            ),
          )
          .build();
    });

    tearDown(() {
      streamController.close();
      client.disconnect();
    });

    group('encryptedChannel', () {
      test('should throw error if authorizer is not configured', () async {
        // Arrange
        final clientWithoutAuthorizer = ReverbClientBuilder()
            .setConfiguration(
              ReverbConfig(
                host: 'localhost',
                appKey: 'app-key',
                authEndpoint: testAuthEndpoint,
                webSocketFactory: (Uri uri, {Map<String, dynamic>? headers}) =>
                    mockChannel,
              ),
            )
            .build();
        setupSuccessConnectionResponse();
        await clientWithoutAuthorizer.connect();

        // Act & Assert
        expect(
          () => clientWithoutAuthorizer.subscribeEncryptedChannel(
            channelName: 'private-encrypted-messages',
            encryptionMasterKey: testEncryptionKey,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should not throw error if not connected', () {
        // Arrange: Client is not connected

        // Act & Assert
        expect(
          () => client.subscribeEncryptedChannel(
            channelName: 'private-encrypted-messages',
            encryptionMasterKey: testEncryptionKey,
          ),
          returnsNormally,
        );
      });

      test('should throw error for invalid encrypted channel name', () async {
        // Arrange
        setupSuccessConnectionResponse();
        await client.connect();

        // Act & Assert - Wrong prefix
        expect(
          () => client.subscribeEncryptedChannel(
            channelName: 'private-messages',
            encryptionMasterKey: testEncryptionKey,
          ),
          throwsA(isA<InvalidChannelNameException>()),
        );

        expect(
          () => client.subscribeEncryptedChannel(
            channelName: 'public-encrypted-messages',
            encryptionMasterKey: testEncryptionKey,
          ),
          throwsA(isA<InvalidChannelNameException>()),
        );
      });

      test('should create encrypted channel with valid parameters', () async {
        // Arrange
        setupSuccessConnectionResponse();
        await client.connect();
        setupSubscriptionSuccessResponse();

        // Act
        final channel = client.subscribeEncryptedChannel(
          channelName: 'private-encrypted-messages',
          encryptionMasterKey: testEncryptionKey,
        );

        // Assert
        expect(channel, isA<ReverbEncryptedChannel>());
        expect(channel.name, 'private-encrypted-messages');
        expect(channel.state, ChannelState.subscribing);
      });

      test('should return existing channel if already subscribed', () async {
        // Arrange
        setupSuccessConnectionResponse();
        await client.connect();
        setupSubscriptionSuccessResponse();

        // Act
        final channel1 = client.subscribeEncryptedChannel(
          channelName: 'private-encrypted-messages',
          encryptionMasterKey: testEncryptionKey,
        );
        final channel2 = client.subscribeEncryptedChannel(
          channelName: 'private-encrypted-messages',
          encryptionMasterKey: testEncryptionKey,
        );

        // Assert
        expect(identical(channel1, channel2), isTrue);
      });
    });

    group('mixed channel types', () {
      test('should handle public, private, and encrypted channels', () async {
        // Arrange
        setupSuccessConnectionResponse();
        await client.connect();
        setupSubscriptionSuccessResponse();

        // Act
        final publicChannel = client.subscribePublicChannel(
          channelName: 'public-channel',
        );
        final encryptedChannel = client.subscribeEncryptedChannel(
          channelName: 'private-encrypted-messages',
          encryptionMasterKey: testEncryptionKey,
        );

        // Assert
        expect(publicChannel, isA<ReverbPublicChannel>());
        expect(publicChannel, isNot(isA<ReverbPrivateChannel>()));
        expect(publicChannel, isNot(isA<ReverbEncryptedChannel>()));

        expect(encryptedChannel, isA<ReverbEncryptedChannel>());
        expect(
          encryptedChannel,
          isA<ReverbPrivateChannel>(),
        ); // EncryptedChannel extends PrivateChannel
      });

      test('should handle unsubscription for all channel types', () async {
        // Arrange
        setupSuccessConnectionResponse();
        await client.connect();
        setupSubscriptionSuccessResponse();

        // Subscribe to all types
        client.subscribePublicChannel(channelName: 'public-channel');
        client.subscribeEncryptedChannel(
          channelName: 'private-encrypted-messages',
          encryptionMasterKey: testEncryptionKey,
        );

        expect(client.subscribedChannels.length, 2);

        // Act - Unsubscribe from all
        client.unsubscribeChannel('public-channel');
        client.unsubscribeChannel('private-encrypted-messages');

        // Assert
        expect(client.subscribedChannels.length, 0);
      });
    });

    group('channel management', () {
      test('should return correct channel type from getChannel', () async {
        // Arrange
        setupSuccessConnectionResponse();
        await client.connect();
        setupSubscriptionSuccessResponse();

        // Create channels
        final publicChannel = client.subscribePublicChannel(
          channelName: 'public-channel',
        );
        final encryptedChannel = client.subscribeEncryptedChannel(
          channelName: 'private-encrypted-messages',
          encryptionMasterKey: testEncryptionKey,
        );

        // Act & Assert
        expect(client.getChannel('public-channel'), publicChannel);
        expect(
          client.getChannel('private-encrypted-messages'),
          encryptedChannel,
        );
        expect(client.getChannel('nonexistent'), isNull);
      });

      test('should track all subscribed channels correctly', () async {
        // Arrange
        setupSuccessConnectionResponse();
        await client.connect();
        setupSubscriptionSuccessResponse();

        // Act
        client.subscribePublicChannel(channelName: 'public-1');
        client.subscribeEncryptedChannel(
          channelName: 'private-encrypted-1',
          encryptionMasterKey: testEncryptionKey,
        );

        // Assert
        expect(client.subscribedChannels.length, 2);
        expect(client.getChannel('public-1'), isA<ReverbPublicChannel>());
        expect(
          client.getChannel('private-encrypted-1'),
          isA<ReverbEncryptedChannel>(),
        );
      });
    });
  });
}
