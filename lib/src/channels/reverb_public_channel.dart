import 'dart:async';

import 'package:pusher_reverb_flutter/src/validations/channel_validation.dart';

import '../utils/json_util.dart';
import 'reverb_channel.dart';

/// A private channel that requires authentication for subscription.
///
/// Private channels extend the base Channel functionality with authentication
/// capabilities. They must start with the "private-" prefix and require
/// an authorizer function to provide authentication headers.
class ReverbPublicChannel extends ReverbChannel {
  /// Creates a new PrivateChannel instance.
  ///
  /// [name] The name of the private channel (must start with "private-").
  /// [authorizer] The function that provides authentication headers.
  /// [authEndpoint] The URL endpoint for authentication requests.
  /// [sendMessage] Callback for sending WebSocket messages.
  ReverbPublicChannel({required super.name, required super.sendMessage}) {
    validatePublicChannelName(name);
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

    // Send subscription message with auth key
    final message = {
      'event': 'pusher:subscribe',
      'data': {'channel': name},
    };

    sendMessage(JsonUtil.encode((message)));
  }
}
