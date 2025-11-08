import 'package:http/http.dart' as http;

import '../../pusher_reverb_flutter.dart';
import '../utils/json_util.dart';

class ChannelAuthenticator {
  final http.Client _client;

  ChannelAuthenticator({http.Client? client})
    : _client = client ?? http.Client();

  /// Authenticates with the server using the provided headers and optional channel data.
  ///
  /// Returns a map containing at least the `auth` key, and optionally `channel_data` if available.
  ///
  /// Throws [AuthenticationException] if authentication fails.
  Future<Map<String, dynamic>> authenticate({
    required String channelName,
    required String authEndpoint,
    required String socketId,
    required Map<String, String> authHeaders,
    Map<String, dynamic>? channelData,
  }) async {
    try {
      final requestBody = {
        'socket_id': socketId,
        'channel_name': channelName,
        if (channelData != null) 'channel_data': JsonUtil.encode(channelData),
      };

      final response = await _client.post(
        Uri.parse(authEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...authHeaders,
        },
        body: JsonUtil.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData =
            JsonUtil.decode(response.body) as Map<String, dynamic>;
        final authKey = responseData['auth'] as String?;

        if (authKey == null || authKey.isEmpty) {
          throw AuthenticationException(
            message: 'Authentication response missing auth key',
            channelName: channelName,
            statusCode: response.statusCode,
          );
        }

        return {
          'auth': authKey,
          if (responseData.containsKey('channel_data'))
            'channel_data': responseData['channel_data'],
        };
      } else if (response.statusCode == 403) {
        throw AuthenticationException(
          message: 'Authentication forbidden - insufficient permissions',
          channelName: channelName,
          statusCode: response.statusCode,
        );
      } else {
        throw AuthenticationException(
          message: 'Authentication failed with status ${response.statusCode}',
          channelName: channelName,
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw AuthenticationException(
        message: 'Network error during authentication: ${e.message}',
        channelName: channelName,
      );
    } on FormatException catch (e) {
      throw AuthenticationException(
        message: 'Invalid response format during authentication: ${e.message}',
        channelName: channelName,
      );
    } catch (e) {
      if (e is AuthenticationException) rethrow;
      throw AuthenticationException(
        message: 'Unexpected error during authentication: $e',
        channelName: channelName,
      );
    }
  }
}
