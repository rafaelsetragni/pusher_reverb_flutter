import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/src/channels/reverb_channel.dart';

void main() {
  group('Channel', () {
    late List<String> sentMessages;
    late ReverbChannel channel;

    setUp(() {
      sentMessages = [];
      channel = _TestChannel(
        name: 'test-channel',
        sendMessage: (msg) => sentMessages.add(msg),
      );
    });

    test('should add and remove event listeners', () {
      bool called = false;
      void listener(String event, dynamic data) {
        called = true;
      }

      channel.bind('event1', listener);
      channel.handleEvent('event1', 'payload');
      expect(called, isTrue);

      called = false;
      channel.unbind('event1', listener);
      channel.handleEvent('event1', 'payload');
      expect(called, isFalse);
    });

    test('should emit event through stream', () async {
      final future = channel.stream.first;
      channel.handleEvent('event2', 'payload');
      final event = await future;

      expect(event.eventName, 'event2');
      expect(event.data, 'payload');
    });

    test('should notify state listeners on state change', () {
      ChannelState? newState;
      channel.addStateListener((state) {
        newState = state;
      });

      channel.setState(ChannelState.subscribing);
      expect(newState, ChannelState.subscribing);
    });

    test('should clear all event listeners on unsubscription succeeded', () {
      bool called = false;
      channel.bind('event3', (event, data) {
        called = true;
      });

      channel.handleUnsubscriptionSucceeded();
      channel.handleEvent('event3', 'payload');
      expect(called, isFalse);
    });
  });
}

class _TestChannel extends ReverbChannel {
  _TestChannel({
    required super.name,
    required void Function(String) sendMessage,
  }) : super(sendMessage: sendMessage);

  @override
  Future<void> subscribe({required String socketId}) async {}
}
