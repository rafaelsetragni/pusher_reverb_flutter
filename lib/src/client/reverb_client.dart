import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../pusher_reverb_flutter.dart';
import '../listeners/reverb_event_listener.dart';
import '../models/reverb_config.dart';
import 'reverb_client_impl.dart';

typedef WebSocketFactory =
    WebSocketChannel Function(Uri url, {Map<String, dynamic>? headers});

/// Facade defining the Reverb client contract for WebSocket interaction.
abstract class ReverbClient {
  static ReverbClient get instance => ReverbClientImpl.reverbInstance;

  final String component = 'ReverbClient';

  String? get socketId;
  ReverbConfig? get reverbConfig;

  /// A stream that emits connection state changes.
  Stream<ReverbConnectionState> get onConnectionStateChange;

  /// Gets the current connection state.
  ReverbConnectionState get connectionState;

  /// Gets all subscribed channels.
  List<Channel> get subscribedChannels;

  /// Gets the list of available clusters.
  List<String> get availableClusters;

  /// Connects to the Reverb server.
  Future<void> connect();

  /// Disconnects from the server.
  void disconnect();

  /// Resets the singleton instance (for testing).
  void setConfiguration(ReverbConfig config);

  /// Gets a channel by name if it exists.
  Channel? getChannel(String channelName);

  /// Subscribes to a public channel.
  PublicChannel registerPublicChannel(String channelName);

  /// Subscribes to a private channel.
  PrivateChannel registerPrivateChannel(
    String channelName, {
    required String authKey,
  });

  /// Subscribes to a presence channel.
  PresenceChannel registerToPresenceChannel(
    String channelName, {
    required String authKey,
    Map<String, dynamic>? channelData,
  });

  /// Subscribes to an encrypted channel.
  EncryptedChannel registerEncryptedChannel(
    String channelName, {
    required String authKey,
    required String encryptionMasterKey,
  });

  /// Unsubscribes from a channel.
  void unregisterChannel(String channelName);

  /// Adds an event listener.
  void addListener(ReverbEventListener listener);

  /// Removes an event listener.
  void removeListener(ReverbEventListener listener);

  void sendMessage(dynamic message);
}
