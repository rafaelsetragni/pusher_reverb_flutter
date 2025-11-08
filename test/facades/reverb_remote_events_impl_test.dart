import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'package:pusher_reverb_flutter/src/facades/reverb_client_impl.dart';
import 'package:pusher_reverb_flutter/src/listeners/reverb_event_listener.dart';
import 'package:pusher_reverb_flutter/src/models/reverb_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'reverb_client_encrypted_test.mocks.dart';
import 'reverb_remote_events_impl_test.mocks.dart'
    hide MockWebSocketChannel, MockWebSocketSink;

late MockWebSocketChannel mockChannel;
late MockWebSocketSink mockSink;
late StreamController<dynamic> streamController;
late String testSocketId = '12345.67890';
late ReverbClientImpl client;
late ReverbConfig config;

@GenerateNiceMocks([
  MockSpec<WebSocketChannel>(),
  MockSpec<WebSocketSink>(),
  MockSpec<ReverbChannel>(),
  MockSpec<ReverbPresenceChannel>(),
])
void main() {
  setUp(() async {
    mockChannel = MockWebSocketChannel();
    mockSink = MockWebSocketSink();
    streamController = StreamController<dynamic>.broadcast();

    when(mockChannel.stream).thenAnswer((_) => streamController.stream);
    when(mockChannel.sink).thenReturn(mockSink);

    config = ReverbConfig(
      host: 'localhost',
      appKey: 'test-key',
      webSocketFactory: (Uri uri, {Map<String, dynamic>? headers}) =>
          mockChannel,
    );
    client =
        ReverbClientBuilder().setConfiguration(config).build()
            as ReverbClientImpl;

    addTearDown(() async {});

    setupSuccessConnectionResponse();
    await client.connect();
  });

  tearDown(() async {
    client.disconnect();
    await streamController.close();
  });

  group('ReverbRemoteEventsImpl', () {
    test('sendMessage sends data through sink', () {
      final message = '{"event": "test"}';
      client.sendMessage(message);
      verify(mockSink.add(message)).called(1);
    });

    test('sendMessage throws when not connected', () {
      client.webSocketChannel = null;
      expect(
        () => client.sendMessage('{"event": "test"}'),
        throwsA(isA<ConnectionException>()),
      );
    });

    test('handlePingRequest sends pong', () {
      client.handlePingRequest(config, null);
      final captured = verify(mockSink.add(captureAny)).captured.single;
      expect(jsonDecode(captured)['event'], 'pusher:pong');
    });

    test('handleConnectionEstablished updates socketId and state', () async {
      final completer = Completer<void>();
      client.connectionCompleter = completer;
      client.handleConnectionEstablished(config, '{"socket_id": "abc.123"}');
      expect(client.socketId, 'abc.123');
      expect(completer.isCompleted, isTrue);
    });

    test('handleSubscriptionSucceeded invokes handler on presence channel', () {
      final mockChannel = MockReverbPresenceChannel();
      final data = jsonEncode({'channel': 'presence-chat'});
      client.channels['presence-chat'] = mockChannel;
      client.handleSubscriptionSucceeded(config, data);
      verify(mockChannel.handleSubscriptionSucceeded(any)).called(1);
    });

    test('handleSubscriptionSucceeded invokes handler on regular channel', () {
      final mockChannel = MockReverbChannel();
      final data = jsonEncode({'channel': 'regular-chat'});
      client.channels['regular-chat'] = mockChannel;
      client.handleSubscriptionSucceeded(config, data);
      verify(mockChannel.handleSubscriptionSucceeded()).called(1);
    });

    test('handleUnsubscriptionSucceeded invokes handler', () {
      final mockChannel = MockReverbChannel();
      final data = jsonEncode({'channel': 'public-chat'});
      client.channels['public-chat'] = mockChannel;
      client.handleUnsubscriptionSucceeded(config, data);
      verify(mockChannel.handleUnsubscriptionSucceeded()).called(1);
    });

    test('handleRemoteChannelEvent forwards to channel', () {
      final mockChannel = MockReverbChannel();
      final event = {
        'channel': 'private-channel',
        'event': 'custom:event',
        'data': {'key': 'value'},
      };
      client.channels['private-channel'] = mockChannel;
      client.handleRemoteChannelEvent(config, event);
      verify(
        mockChannel.handleEvent('custom:event', {'key': 'value'}),
      ).called(1);
    });

    test('handleMessage handles ping', () {
      final message = jsonEncode({'event': 'pusher:ping'});
      client.handleMessage(config, message);
      verify(mockSink.add(any)).called(1);
    });

    test('handleMessage logs warning when event is missing', () {
      final message = jsonEncode({'data': 'some data without event'});

      final logMessages = <String>[];
      final listener = TestListener(
        onLogInterceptor: (component, level, msg, [err]) {
          logMessages.add('$component|$level|$msg');
        },
      );

      client.addListener(listener);
      client.handleMessage(config, message);

      expect(
        logMessages,
        contains('ReverbClient|900|Received message without event type'),
      );

      client.removeListener(listener);
    });

    test('handleMessage handles unsubscription_succeeded event', () {
      final mockChannel = MockReverbChannel();
      final payload = jsonEncode({
        'event': 'pusher_internal:unsubscription_succeeded',
        'data': jsonEncode({'channel': 'public-chat'}),
      });
      client.channels['public-chat'] = mockChannel;

      client.handleMessage(config, payload);

      verify(mockChannel.handleUnsubscriptionSucceeded()).called(1);
    });

    test('handleMessage handles remote channel event fallback', () {
      final mockChannel = MockReverbChannel();
      final payload = jsonEncode({
        'event': 'client-custom-event',
        'channel': 'custom-channel',
        'data': {'foo': 'bar'},
      });
      client.channels['custom-channel'] = mockChannel;

      client.handleMessage(config, payload);

      verify(
        mockChannel.handleEvent('client-custom-event', {'foo': 'bar'}),
      ).called(1);
    });
  });
}

class TestListener implements ReverbEventListener {
  void Function(String component, int level, String message, [dynamic error])?
  onLogInterceptor;

  TestListener({this.onLogInterceptor});

  @override
  void onConnecting(ReverbConfig config) {}

  @override
  void onConnected(String socketId, ReverbConfig config) {}

  @override
  void onReconnecting(String socketId, ReverbConfig config) {}

  @override
  void onDisconnected(String socketId, ReverbConfig config) {}

  @override
  void onError(String? socketId, dynamic error) {}

  @override
  void onLog(String component, int level, String message, [dynamic error]) {
    final onLogInterceptor = this.onLogInterceptor;
    if (onLogInterceptor != null) {
      onLogInterceptor(component, level, message, error);
    }
  }
}

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
