import 'package:pusher_reverb_flutter/src/authentications/channel_authenticator.dart';

class MockChannelAuthenticator implements ChannelAuthenticator {
  final Map<String, dynamic> response;

  MockChannelAuthenticator({this.response = const {'auth': 'some-auth-key'}});

  @override
  Future<Map<String, dynamic>> authenticate({
    required String channelName,
    required String authEndpoint,
    required String socketId,
    required Map<String, String> authHeaders,
    Map<String, dynamic>? channelData,
  }) async => response;
}
