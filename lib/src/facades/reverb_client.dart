import 'dart:async';

import '../../pusher_reverb_flutter.dart';
import '../listeners/reverb_event_listener.dart';
import '../models/reverb_config.dart';
import 'reverb_client_impl.dart';

class ReverbClientBuilder {
  ReverbConfig? config;

  /// Resets the singleton instance (for testing).
  ReverbClientBuilder setConfiguration(ReverbConfig config) =>
      this..config = config;

  ReverbClient build() {
    final reverbConfig = config;
    if (reverbConfig == null) {
      throw ReverbClientException.missingConfiguration();
    }
    return ReverbClientImpl(reverbConfig);
  }
}

/// A facade interface defining the contract for interacting with the Reverb WebSocket service.
///
/// This client enables subscribing to real-time channels (public, private, presence, encrypted),
/// sending messages, and tracking connection state.
///
/// Subscribed channels are automatically re-subscribed when a reconnection occurs
/// (e.g., after a dropped connection or socket replacement).
///
/// Use [ReverbClientBuilder] to create an instance of this class.
abstract class ReverbClient {
  /// Component identifier used for logging and internal tracking.
  final String component = 'ReverbClient';

  /// The current socket ID assigned upon connection, or null if not connected.
  String? get socketId;

  /// The configuration used for this client, as provided during instantiation.
  ReverbConfig get reverbConfig;

  /// A stream that emits [ReverbConnectionState] values when the connection state changes.
  Stream<ReverbConnectionState> get onConnectionStateChange;

  /// The current connection state of the WebSocket connection.
  ReverbConnectionState get connectionState;

  /// A list of channels the client is currently subscribed to.
  List<ReverbChannel> get subscribedChannels;

  /// A list of available cluster names for configuration purposes.
  static List<String> get availableClusters =>
      ClusterConfig.availableClusters.toList();

  /// Retrieves a [ClusterConfig] for the given cluster name, or null if the cluster is invalid.
  static ClusterConfig? getClusterConfig(String cluster) =>
      ClusterConfig.fromRegion(cluster);

  /// Initiates a WebSocket connection to the Reverb server.
  ///
  /// This must be called before subscribing to any channels.
  Future<void> connect();

  /// Gracefully closes the WebSocket connection and unsubscribes from all channels.
  void disconnect();

  /// Retrieves a channel by name if the client is currently subscribed to it.
  ///
  /// Returns null if the channel is not found.
  ReverbChannel? getChannel(String channelName);

  /// Subscribes to a **public** channel.
  ///
  /// [socketId] must be available from a successful connection.
  /// [channelName] must start with `"public-"`.
  ReverbPublicChannel subscribePublicChannel({required String channelName});

  /// Subscribes to a **private** channel, requiring authentication.
  ///
  /// [socketId] must be available from a successful connection.
  /// [channelName] must start with `"private-"`.
  ReverbPrivateChannel subscribePrivateChannel({required String channelName});

  /// Subscribes to a **presence** channel, which tracks user presence.
  ///
  /// [socketId] must be available from a successful connection.
  /// [channelName] must start with `"presence-"`.
  ReverbPresenceChannel subscribePresenceChannel({
    required String channelName,
    Map<String, dynamic>? channelData,
  });

  /// Subscribes to an **encrypted private** channel using the provided master key.
  ///
  /// [socketId] must be available from a successful connection.
  /// [channelName] must start with `"private-encrypted-"`.
  /// [encryptionMasterKey] must be a valid base64-encoded key.
  ReverbEncryptedChannel subscribeEncryptedChannel({
    required String channelName,
    required String encryptionMasterKey,
  });

  /// Unsubscribes from the channel with the given name.
  ///
  /// If the channel is not subscribed, this has no effect.
  void unsubscribeChannel(String channelName);

  /// Adds a global event listener to receive events from all channels.
  ///
  /// The [listener] will be notified of relevant Reverb events.
  void addListener(ReverbEventListener listener);

  /// Removes a previously added event listener.
  void removeListener(ReverbEventListener listener);

  /// Sends a raw message over the WebSocket.
  ///
  /// This is an advanced method used for internal signaling or custom events.
  void sendMessage(dynamic message);
}
