import 'dart:async';

import '../../pusher_reverb_flutter.dart';
import '../authentications/channel_authenticator.dart';
import '../utils/json_util.dart';
import '../validations/channel_validation.dart';

/// A private channel that requires authentication for subscription.
///
/// Private channels extend the base Channel functionality with authentication
/// capabilities. They must start with the "private-" prefix and require
/// an authorizer function to provide authentication headers.
class ReverbPrivateChannel extends ReverbChannel {
  final Authorizer authorizer;
  final String authEndpoint;
  final ChannelAuthenticator channelAuthenticator;

  /// Creates a new PrivateChannel instance.
  ///
  /// [name] The name of the private channel (must start with "private-").
  /// [authorizer] The function that provides authentication headers.
  /// [authEndpoint] The URL endpoint for authentication requests.
  /// [socketId] The socket ID for authentication.
  /// [sendMessage] Callback for sending WebSocket messages.
  ReverbPrivateChannel({
    required super.name,
    required super.sendMessage,
    required this.authorizer,
    required this.authEndpoint,
    required this.channelAuthenticator,
  }) {
    // Only validate if this is actually a PrivateChannel, not a subclass
    if (runtimeType == ReverbPrivateChannel) {
      validatePrivateChannelName(name);
    }
  }

  /// Subscribes to the private channel with authentication.
  ///
  /// This method first authenticates with the server using the authorizer
  /// function, then proceeds with the normal subscription process.
  @override
  Future<void> subscribe({required String socketId}) async {
    if (state == ChannelState.subscribed || state == ChannelState.subscribing) {
      return;
    }

    setState(ChannelState.subscribing);
    try {
      // Get authentication headers from the authorizer
      final authHeaders = await authorizer(name, socketId);

      // Check if channel is still subscribing (not unsubscribed during auth)
      if (state != ChannelState.subscribing) {
        return;
      }

      // Send authentication request to the server
      final authKey = await channelAuthenticator.authenticate(
        channelName: name,
        authEndpoint: authEndpoint,
        socketId: socketId,
        authHeaders: authHeaders,
      );

      // Check again if channel is still subscribing before sending message
      if (state != ChannelState.subscribing) {
        return;
      }

      // Send subscription message with auth key
      final message = {
        'event': 'pusher:subscribe',
        'data': {'channel': name, 'auth': authKey},
      };
      sendMessage(JsonUtil.encode((message)));
    } catch (e) {
      // Only update state if still subscribing (not already unsubscribed)
      if (state == ChannelState.subscribing) {
        setState(ChannelState.unsubscribed);
        rethrow;
      }
      // If already unsubscribed, silently ignore the error
    }
  }
}
