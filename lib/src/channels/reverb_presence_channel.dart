import 'dart:async';

import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

import '../utils/json_util.dart';
import '../validations/channel_validation.dart';

/// A presence channel that tracks subscribed members.
///
/// Presence channels extend PrivateChannel with member awareness capabilities.
/// They must start with the "presence-" prefix and require authentication
/// like private channels. Additionally, they track who is currently subscribed
/// to the channel and provide member_added and member_removed events.
class ReverbPresenceChannel extends ReverbPrivateChannel {
  /// Map of currently subscribed members by their ID.
  final Map<String, PresenceMember> _members = {};

  /// Optional channel data for presence subscription (typically user info).
  final Map<String, dynamic>? channelData;

  /// Creates a new PresenceChannel instance.
  ///
  /// [name] The name of the presence channel (must start with "presence-").
  /// [authorizer] The function that provides authentication headers.
  /// [authEndpoint] The URL endpoint for authentication requests.
  /// [socketId] The socket ID for authentication.
  /// [sendMessage] Callback for sending WebSocket messages.
  /// [channelData] Optional data to include in the subscription (typically user info).
  ReverbPresenceChannel({
    required super.name,
    required super.sendMessage,
    required super.authorizer,
    required super.authEndpoint,
    required super.channelAuthenticator,
    this.channelData,
  }) {
    validatePresenceChannelName(name);
  }

  /// Returns the list of currently subscribed members.
  ///
  /// This list is updated automatically when members join or leave the channel.
  List<PresenceMember> get members => _members.values.toList();

  /// Returns the count of currently subscribed members.
  int get memberCount => _members.length;

  /// Subscribes to the presence channel with authentication and channel data.
  ///
  /// This method first authenticates with the server using the authorizer
  /// function, including channel_data in the request if provided.
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

      // Send authentication request to the server with channel data
      final authResponse = await channelAuthenticator.authenticate(
        channelName: name,
        authEndpoint: authEndpoint,
        socketId: socketId,
        authHeaders: authHeaders,
        channelData: channelData,
      );

      // Check again if channel is still subscribing before sending message
      if (state != ChannelState.subscribing) {
        return;
      }

      // Send subscription message with auth key and channel data
      final message = {
        'event': 'pusher:subscribe',
        'data': {
          'channel': name,
          'auth': authResponse['auth'],
          if (authResponse.containsKey('channel_data'))
            'channel_data': authResponse['channel_data'],
        },
      };

      sendMessage(_encodeMessage(message));
    } catch (e) {
      // Only update state if still subscribing (not already unsubscribed)
      if (state == ChannelState.subscribing) {
        setState(ChannelState.unsubscribed);
        rethrow;
      }
      // If already unsubscribed, silently ignore the error
    }
  }

  /// Handles subscription success and parses initial member list.
  ///
  /// The subscription_succeeded data contains a 'presence' field with
  /// member information.
  @override
  void handleSubscriptionSucceeded([dynamic data]) {
    setState(ChannelState.subscribed);

    // Parse initial member list from subscription data
    if (data != null && data is Map<String, dynamic>) {
      final presence = data['presence'];
      if (presence != null && presence is Map<String, dynamic>) {
        final hash = presence['hash'];
        if (hash != null && hash is Map<String, dynamic>) {
          _members.clear();
          hash.forEach((userId, userInfo) {
            final member = PresenceMember(
              id: userId,
              info: userInfo is Map<String, dynamic> ? userInfo : {},
            );
            _members[userId] = member;
          });
        }
      }
    }
  }

  /// Handles incoming events for this presence channel.
  ///
  /// Intercepts member_added and member_removed events to update the
  /// member list, then forwards all events to the base class.
  @override
  void handleEvent(String eventName, dynamic data) {
    // Handle presence-specific events
    if (eventName == 'pusher:member_added') {
      _handleMemberAdded(data);
    } else if (eventName == 'pusher:member_removed') {
      _handleMemberRemoved(data);
    }

    // Call parent to emit events to streams and callbacks
    super.handleEvent(eventName, data);
  }

  /// Handles member_added events.
  ///
  /// Parses the member data and adds it to the member list.
  void _handleMemberAdded(dynamic data) {
    if (data != null && data is Map<String, dynamic>) {
      final userId = data['user_id'] as String?;
      final userInfo = data['user_info'];

      if (userId != null) {
        final member = PresenceMember(
          id: userId,
          info: userInfo is Map<String, dynamic> ? userInfo : {},
        );
        _members[userId] = member;
      }
    }
  }

  /// Handles member_removed events.
  ///
  /// Parses the member ID and removes it from the member list.
  void _handleMemberRemoved(dynamic data) {
    if (data != null && data is Map<String, dynamic>) {
      final userId = data['user_id'] as String?;

      if (userId != null) {
        _members.remove(userId);
      }
    }
  }

  /// Encodes a message to JSON string.
  String _encodeMessage(Map<String, dynamic> message) {
    return JsonUtil.encode(message);
  }
}
