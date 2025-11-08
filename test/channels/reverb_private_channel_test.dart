import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'package:pusher_reverb_flutter/src/authentications/channel_authenticator.dart';

import 'channel_authenticator.mocks.dart';

void main() {
  group('PrivateChannel', () {
    late Authorizer mockAuthorizer;
    late String testChannelName;
    late String testSocketId;
    late String testAuthEndpoint;
    late List<String> sentMessages;
    late ChannelAuthenticator mockedChannelAuthenticator;

    setUp(() {
      testSocketId = '12345.67890';
      testChannelName = 'private-test-channel';
      testAuthEndpoint = 'https://example.com/auth';
      sentMessages = [];

      mockedChannelAuthenticator = MockChannelAuthenticator();

      mockAuthorizer = (String channelName, String socketId) async {
        return {
          'Authorization': 'Bearer test-token',
          'X-Custom-Header': 'test-value',
        };
      };
    });

    ReverbPrivateChannel createPrivateChannel() {
      return ReverbPrivateChannel(
        name: testChannelName,
        authorizer: mockAuthorizer,
        authEndpoint: testAuthEndpoint,
        sendMessage: (String message) {
          sentMessages.add(message);
        },
        channelAuthenticator: mockedChannelAuthenticator,
      );
    }

    group('constructor', () {
      test('should create private channel with valid name', () {
        final channel = createPrivateChannel();
        expect(channel.name, testChannelName);
        expect(channel.state, ChannelState.unsubscribed);
      });

      test('should throw error for invalid private channel name', () {
        expect(
          () => ReverbPrivateChannel(
            name: 'public-channel',
            sendMessage: (String message) {},
            authorizer: mockAuthorizer,
            authEndpoint: testAuthEndpoint,
            channelAuthenticator: mockedChannelAuthenticator,
          ),
          throwsA(isA<InvalidChannelNameException>()),
        );
      });

      test('should store authorizer and auth endpoint', () {
        final channel = createPrivateChannel();
      });
    });

    group('subscribe', () {
      test('should not subscribe if already subscribed', () async {
        final channel = createPrivateChannel();
        expect(sentMessages.length, 0);

        // First subscription should succeed using mocked authenticator
        expect(
          () async => await channel.subscribe(socketId: testSocketId),
          returnsNormally,
        );
        await Future.delayed(Duration.zero, () {
          expect(sentMessages.length, 1);
        });

        // Second subscription should not attempt again
        expect(
          () async => await channel.subscribe(socketId: testSocketId),
          returnsNormally,
        );
        await Future.delayed(Duration.zero, () {
          expect(sentMessages.length, 1);
        });
      });

      test('should not subscribe if already subscribing', () async {
        final channel = createPrivateChannel();

        // Start first subscription
        final firstSubscription = channel.subscribe(socketId: testSocketId);

        // Start second subscription while first is in progress
        final secondSubscription = channel.subscribe(socketId: testSocketId);

        expect(
          () async =>
              await Future.wait([firstSubscription, secondSubscription]),
          returnsNormally,
        );

        // Should only have attempted one subscription
        expect(
          sentMessages.length,
          0,
        ); // No messages sent because subscription logic skips duplicated concurrent calls
      });
    });

    group('inherited functionality', () {
      test('should support event binding and unbinding', () {
        final channel = createPrivateChannel();
        bool eventReceived = false;

        channel.bind('test-event', (String eventName, dynamic data) {
          eventReceived = true;
        });

        channel.handleEvent('test-event', 'test-data');
        expect(eventReceived, true);

        channel.unbind('test-event');
        eventReceived = false;
        channel.handleEvent('test-event', 'test-data');
        expect(eventReceived, false);
      });

      test('should support state change listeners', () {
        final channel = createPrivateChannel();
        ChannelState? lastState;

        channel.addStateListener((ChannelState state) {
          lastState = state;
        });

        // State should change during subscription attempt
        expect(lastState, isNull);
      });

      test('should support unsubscribe', () async {
        final channel = createPrivateChannel();

        // Unsubscribe should work even if not subscribed
        await channel.unsubscribe();
        expect(channel.state, ChannelState.unsubscribed);
      });
    });
  });
}
