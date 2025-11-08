import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'package:pusher_reverb_flutter/src/listeners/reverb_event_listener.dart';
import 'package:pusher_reverb_flutter/src/models/reverb_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'reverb_client_test.mocks.dart';

class TestReverbEventListener implements ReverbEventListener {
  final List<String> calls = [];
  dynamic lastError;

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
    lastError = error;
    calls.add('onError:$socketId:$error');
  }

  @override
  void onLog(String component, int level, String message, [dynamic error]) {
    calls.add('onLog:$component:$level:$message:$error');
  }
}

@GenerateNiceMocks([MockSpec<WebSocketChannel>(), MockSpec<WebSocketSink>()])
void main() {
  group('ReverbClient Connection Implementation', () {
    late MockWebSocketChannel mockChannel;
    late MockWebSocketSink mockSink;
    late StreamController<dynamic> streamController;
    late TestReverbEventListener listener;
    late String testSocketId;

    void setupSuccessConnectionResponse({String socketId = 'test-socket'}) {
      final completer = Completer<void>();
      streamController.onListen = () {
        if (!completer.isCompleted) completer.complete();
      };

      completer.future.then((_) {
        final message = jsonEncode({
          'event': 'pusher:connection_established',
          'data': jsonEncode({'socket_id': socketId}),
        });
        if (!streamController.isClosed) {
          streamController.add(message);
        }
      });
    }

    void setupFailureConnectionResponse() {
      final completer = Completer<void>();
      streamController.onListen = () {
        if (!completer.isCompleted) completer.complete();
      };
      completer.future.then((_) {
        if (!streamController.isClosed) {
          streamController.addError(Exception('Failed to connect'));
        }
      });
    }

    setUp(() {
      mockChannel = MockWebSocketChannel();
      mockSink = MockWebSocketSink();
      streamController = StreamController<dynamic>.broadcast();
      listener = TestReverbEventListener();
      testSocketId = '12345.67890';

      when(mockChannel.stream).thenAnswer((_) => streamController.stream);
      when(mockChannel.sink).thenReturn(mockSink);
    });

    tearDown(() {
      streamController.close();
    });

    ReverbClient createClient({
      int reconnectAttempts = 10,
      Duration reconnectDelay = const Duration(seconds: 1),
    }) {
      final client = ReverbClientBuilder()
          .setConfiguration(
            ReverbConfig(
              host: 'localhost',
              appKey: 'app-key',
              webSocketFactory: (Uri uri, {Map<String, dynamic>? headers}) =>
                  mockChannel,
              reconnectAttempts: reconnectAttempts,
              reconnectDelay: reconnectDelay,
            ),
          )
          .build();
      client.addListener(listener);
      return client;
    }

    group('Connection State Stream', () {
      test('emits connecting state on connect', () async {
        final client = createClient();
        final states = <ReverbConnectionState>[];
        client.onConnectionStateChange.listen(states.add);

        setupSuccessConnectionResponse(socketId: testSocketId);
        await client.connect();

        expect(states, contains(ReverbConnectionState.connecting));
        client.disconnect();
      });

      test('emits connected state on connection established', () async {
        final client = createClient();
        final states = <ReverbConnectionState>[];
        client.onConnectionStateChange.listen(states.add);

        setupSuccessConnectionResponse(socketId: testSocketId);
        await client.connect();

        expect(
          states,
          containsAll([
            ReverbConnectionState.connecting,
            ReverbConnectionState.connected,
          ]),
        );
        client.disconnect();
      });

      test('emits disconnected state on disconnect', () async {
        final client = createClient();
        final states = <ReverbConnectionState>[];
        client.onConnectionStateChange.listen(states.add);

        setupSuccessConnectionResponse(socketId: testSocketId);
        await client.connect();
        client.disconnect();
        await Future.delayed(Duration.zero);

        expect(states.last, ReverbConnectionState.disconnected);
      });

      test('emits error state on connection error', () async {
        final client = createClient();
        final states = <ReverbConnectionState>[];
        client.onConnectionStateChange.listen((data) {
          states.add(data);
        });

        setupFailureConnectionResponse();
        final future = client.connect();
        expect(() => future, throwsA(isA<ConnectionException>()));
        await Future.delayed(Duration.zero);
        expect(states, contains(ReverbConnectionState.error));
        client.disconnect();
      });
    });

    group('Connection Callbacks', () {
      test('onConnecting callback fires when connect is called', () async {
        final client = createClient();
        setupSuccessConnectionResponse();
        await client.connect();

        expect(listener.calls, contains('onConnecting'));
        client.disconnect();
      });

      test('onConnected callback fires on initial connection', () async {
        final client = createClient();

        setupSuccessConnectionResponse(socketId: testSocketId);
        await client.connect();

        expect(listener.calls, contains('onConnected:$testSocketId'));
        client.disconnect();
      });

      test('onDisconnected callback fires when connection is lost', () async {
        final client = createClient(reconnectAttempts: 0);

        setupSuccessConnectionResponse(socketId: testSocketId);
        await client.connect();
        final socketId = client.socketId;

        await streamController.close();
        await Future.delayed(Duration(seconds: 5));

        expect(listener.calls, contains('onDisconnected:$socketId'));
      });

      test('onError callback fires on connection error', () async {
        final client = createClient();

        setupFailureConnectionResponse();
        final future = client.connect();
        await expectLater(future, throwsA(isA<ConnectionException>()));

        expect(listener.lastError, isA<ConnectionException>());
        client.disconnect();
      });
    });

    group('Reconnection Logic', () {
      test(
        'onReconnecting callback fires when reconnection is triggered',
        () async {
          final client = createClient(
            reconnectAttempts: 1,
            reconnectDelay: Duration(milliseconds: 100),
          );

          setupSuccessConnectionResponse(socketId: testSocketId);
          await client.connect();
          final socketId = client.socketId;

          await streamController.close(); // Trigger connection loss
          await Future.delayed(Duration(milliseconds: 200));

          expect(listener.calls, contains('onReconnecting:$socketId'));
        },
      );

      test('manual disconnect prevents automatic reconnection', () async {
        final client = createClient(
          reconnectAttempts: 1,
          reconnectDelay: Duration(milliseconds: 100),
        );

        setupSuccessConnectionResponse(socketId: testSocketId);
        await client.connect();
        final socketId = client.socketId;

        client.disconnect(); // Manual disconnect
        await Future.delayed(Duration(milliseconds: 200));

        expect(listener.calls, isNot(contains('onReconnecting:$socketId')));
      });

      test('stops reconnecting after reaching max attempts', () async {
        final client = createClient(
          reconnectAttempts: 2,
          reconnectDelay: Duration(milliseconds: 100),
        );

        setupSuccessConnectionResponse(socketId: testSocketId);
        await client.connect();

        setupFailureConnectionResponse();
        await streamController.close(); // Trigger connection loss
        await Future.delayed(Duration(seconds: 2));

        final reconnectingCalls = listener.calls
            .where((call) => call.startsWith('onReconnecting'))
            .length;
        expect(reconnectingCalls, 2);
      });
    });
  });
}
