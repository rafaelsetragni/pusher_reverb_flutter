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

import '../channels/channel_authenticator.mocks.dart';
import 'reverb_client_encrypted_test.mocks.dart';

Future<Map<String, String>> mockAuthorizer(
  String channelName,
  String socketId,
) async {
  return {
    'Authorization': 'Bearer test-token',
    'X-Custom-Header': 'test-value',
  };
}

class TestReverbEventListener implements ReverbEventListener {
  final List<String> calls = [];

  @override
  void onConnecting(ReverbConfig config) {
    calls.add('onConnecting');
  }

  @override
  void onConnected(String socketId, ReverbConfig config) {
    calls.add('onConnected:$socketId');
  }

  @override
  void onReconnecting(String socketId, ReverbConfig config) {
    calls.add('onReconnecting:$socketId');
  }

  @override
  void onDisconnected(String socketId, ReverbConfig config) {
    calls.add('onDisconnected:$socketId');
  }

  @override
  void onError(String? socketId, dynamic error) {
    calls.add('onError:$socketId:$error');
  }

  @override
  void onLog(String component, int level, String message, [dynamic error]) {
    calls.add('onLog:$component:$level:$message:$error');
  }
}

@GenerateNiceMocks([MockSpec<WebSocketChannel>(), MockSpec<WebSocketSink>()])
void main() {
  group('ReverbClientListenersImpl', () {
    late ReverbClientImpl client;
    late TestReverbEventListener listener;
    late String testSocketId;
    late StreamController<dynamic> streamController;
    late MockWebSocketChannel mockChannel;
    late MockWebSocketSink mockSink;

    void setupSuccessConnectionResponse({required String testSocketId}) {
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

    setUp(() {
      streamController = StreamController<dynamic>.broadcast();
      mockChannel = MockWebSocketChannel();
      mockSink = MockWebSocketSink();
      when(mockChannel.stream).thenAnswer((_) => streamController.stream);
      when(mockChannel.sink).thenReturn(mockSink);
      testSocketId = '12345.67890';

      listener = TestReverbEventListener();
      client =
          ReverbClientBuilder()
                  .setConfiguration(
                    ReverbConfig(
                      host: 'localhost',
                      appKey: 'test-app',
                      authorizer: mockAuthorizer,
                      authEndpoint: 'https://original-auth-endpoint',
                      webSocketFactory:
                          (Uri uri, {Map<String, dynamic>? headers}) =>
                              mockChannel,
                      channelAuthenticator: MockChannelAuthenticator(),
                    ),
                  )
                  .build()
              as ReverbClientImpl;
      client.addListener(listener);
      setupSuccessConnectionResponse(testSocketId: testSocketId);
    });

    test('addListener should register listener', () async {
      await client.connect();
      expect(listener.calls, contains('onConnecting'));
    });

    test('removeListener should unregister listener', () async {
      client.removeListener(listener);

      await client.connect();
      expect(listener.calls, isNot(contains('onConnecting')));
    });

    test(
      'emitOnConnected should notify listeners with socketId and config',
      () async {
        await client.connect();
        expect(listener.calls, contains('onConnected:$testSocketId'));
      },
    );

    test(
      'emitOnReconnecting should notify listeners with socketId and config',
      () async {
        await client.connect();
        client.emitOnReconnecting();
        expect(listener.calls, contains('onReconnecting:$testSocketId'));
      },
    );

    test(
      'emitOnDisconnected should notify listeners with socketId and config',
      () async {
        await client.connect();
        client.emitOnDisconnected();
        expect(listener.calls, contains('onDisconnected:$testSocketId'));
      },
    );

    test('emitOnError should notify listeners with error', () async {
      await client.connect();
      client.emitOnError('TestError');
      expect(listener.calls, contains('onError:$testSocketId:TestError'));
    });

    test('emitOnLog should notify listeners with log data', () {
      client.emitOnLog('component', 1, 'message', 'error');
      expect(listener.calls, contains('onLog:component:1:message:error'));
    });
  });
}
