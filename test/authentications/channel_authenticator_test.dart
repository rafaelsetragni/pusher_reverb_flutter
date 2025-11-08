import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'package:pusher_reverb_flutter/src/authentications/channel_authenticator.dart';
import 'package:pusher_reverb_flutter/src/utils/json_util.dart';

import 'channel_authenticator_test.mocks.dart';

@GenerateNiceMocks([MockSpec<http.Client>()])
void main() {
  late ChannelAuthenticator authenticator;
  late MockClient client;

  const endpoint = 'https://example.com/auth';
  const socketId = '1234.5678';
  const channelName = 'presence-channel';
  const headers = {'Authorization': 'Bearer token'};

  setUp(() {
    client = MockClient();
    authenticator = ChannelAuthenticator(client: client);
  });

  test('should return auth key on successful response', () async {
    final responseJson = JsonUtil.encode({'auth': 'auth-key'});
    when(
      client.post(
        Uri.parse(endpoint),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      ),
    ).thenAnswer((_) async => http.Response(responseJson, 200));

    final result = await authenticator.authenticate(
      channelName: channelName,
      authEndpoint: endpoint,
      socketId: socketId,
      authHeaders: headers,
    );

    expect(result['auth'], equals('auth-key'));
  });

  test('should return auth key and channel data when included', () async {
    final responseJson = JsonUtil.encode({
      'auth': 'auth-key',
      'channel_data': {'user_id': 42},
    });
    when(
      client.post(
        Uri.parse(endpoint),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      ),
    ).thenAnswer((_) async => http.Response(responseJson, 200));

    final result = await authenticator.authenticate(
      channelName: channelName,
      authEndpoint: endpoint,
      socketId: socketId,
      authHeaders: headers,
    );

    expect(result['auth'], equals('auth-key'));
    expect(result['channel_data'], isNotNull);
  });

  test(
    'should throw AuthenticationException when auth key is missing',
    () async {
      final responseJson = JsonUtil.encode({});
      when(
        client.post(
          Uri.parse(endpoint),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response(responseJson, 200));

      expect(
        () => authenticator.authenticate(
          channelName: channelName,
          authEndpoint: endpoint,
          socketId: socketId,
          authHeaders: headers,
        ),
        throwsA(isA<AuthenticationException>()),
      );
    },
  );

  test('should throw AuthenticationException on 403', () async {
    when(
      client.post(
        Uri.parse(endpoint),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      ),
    ).thenAnswer((_) async => http.Response('Forbidden', 403));

    expect(
      () => authenticator.authenticate(
        channelName: channelName,
        authEndpoint: endpoint,
        socketId: socketId,
        authHeaders: headers,
      ),
      throwsA(isA<AuthenticationException>()),
    );
  });

  test('should throw AuthenticationException on invalid JSON', () async {
    when(
      client.post(
        Uri.parse(endpoint),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      ),
    ).thenAnswer((_) async => http.Response('invalid json', 200));

    expect(
      () => authenticator.authenticate(
        channelName: channelName,
        authEndpoint: endpoint,
        socketId: socketId,
        authHeaders: headers,
      ),
      throwsA(isA<AuthenticationException>()),
    );
  });

  test('should throw AuthenticationException on network error', () async {
    when(
      client.post(
        Uri.parse(endpoint),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      ),
    ).thenThrow(http.ClientException('Connection failed'));

    expect(
      () => authenticator.authenticate(
        channelName: channelName,
        authEndpoint: endpoint,
        socketId: socketId,
        authHeaders: headers,
      ),
      throwsA(isA<AuthenticationException>()),
    );
  });

  test('should throw AuthenticationException on server error (500)', () async {
    when(
      client.post(
        Uri.parse(endpoint),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      ),
    ).thenAnswer((_) async => http.Response('Internal Server Error', 500));

    expect(
      () => authenticator.authenticate(
        channelName: channelName,
        authEndpoint: endpoint,
        socketId: socketId,
        authHeaders: headers,
      ),
      throwsA(isA<AuthenticationException>()),
    );
  });

  test('should throw AuthenticationException on unexpected error', () async {
    when(
      client.post(
        Uri.parse(endpoint),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      ),
    ).thenThrow(Exception('Unexpected'));

    expect(
      () => authenticator.authenticate(
        channelName: channelName,
        authEndpoint: endpoint,
        socketId: socketId,
        authHeaders: headers,
      ),
      throwsA(isA<AuthenticationException>()),
    );
  });
}
