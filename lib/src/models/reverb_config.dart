import '../../pusher_reverb_flutter.dart';

class ReverbConfig {
  /// Interval for sending ping messages to the server.
  final Duration pingInterval;

  /// The host of the Reverb server.
  final String? host;

  /// The port of the Reverb server.
  final int port;

  /// The application key for the Reverb server.
  final String appKey;

  /// The API key for authentication (optional).
  final String? apiKey;

  /// The cluster identifier for predefined configurations (optional).
  final String? cluster;

  /// The authorizer function for private channel authentication.
  final Authorizer? authorizer;

  /// The authentication endpoint URL for private channel authentication.
  final String? authEndpoint;

  /// The custom WebSocket path for the connection.
  /// If not provided, defaults to '/app/{appKey}'.
  final String? wsPath;

  /// Whether to use TLS/SSL for secure WebSocket connections (wss://).
  /// If true, uses wss:// protocol. If false, uses ws:// protocol.
  /// Defaults to false.
  final bool useTLS;

  /// Defines the amount of reconnection retries to reestablish automatically
  /// 0 means no retries.
  final int reconnectAttempts;

  /// The initial delay between reconnection attempts.
  final Duration reconnectDelay;

  /// The maximum delay between reconnection attempts.
  final Duration maxReconnectDelay;

  /// The socket ID assigned by the server upon connection.
  String? socketId;

  late final WebSocketFactory webSocketFactory;

  final Map<String, String>? additionalHeaders;

  /// Configures a instance of ReverbClient.
  ///
  /// Example:
  /// ```dart
  /// // First initialization
  /// final client = ReverbClient().setConfig(
  ///   port: 8080,
  ///   appKey: 'my-app-key',
  ///   apiKey: 'my-api-key',
  ///   cluster: 'us-east-1',
  /// );
  ///
  /// // Later access (parameters optional)
  /// final sameClient = ReverbClient.instance();
  /// ```
  ///
  /// [host] The host of the Reverb server.
  /// [port] The port of the Reverb server.
  /// [appKey] The application key for the Reverb server.
  /// [apiKey] Optional API key for authentication.
  /// [cluster] Optional cluster identifier for predefined configurations.
  /// [authorizer] Optional authorizer function for private channel authentication.
  /// [authEndpoint] Optional authentication endpoint URL for private channel authentication.
  /// [wsPath] Optional custom WebSocket path. If not provided, defaults to '/app/{appKey}'.
  /// [useTLS] Optional flag to use secure WebSocket connections (wss://). Defaults to false.
  /// [reconnectDelay] Optional initial delay between reconnection attempts. Defaults to 1 second.
  /// [maxReconnectDelay] Optional maximum delay between reconnection attempts. Defaults to 30 seconds.
  /// [onConnecting] Optional callback for when the connection attempt starts.
  /// [onConnected] Optional callback for when the connection is successfully established.
  /// [onReconnecting] Optional callback for when the client starts attempting to reconnect.
  /// [onDisconnected] Optional callback for when the connection is closed or lost.
  /// [onError] Optional callback for when a connection error occurs.
  /// [channelFactory] Optional factory for creating WebSocket channels, primarily for testing.
  ///
  /// Throws [StateError] if called without parameters when instance is not yet initialized.
  ReverbConfig({
    required this.appKey,
    this.port = 8080,
    this.host,
    this.apiKey,
    this.cluster,
    this.authorizer,
    this.authEndpoint,
    this.wsPath,
    this.useTLS = false,
    this.reconnectAttempts = 10,
    this.reconnectDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(seconds: 30),
    this.pingInterval = const Duration(seconds: 30),
    this.additionalHeaders,
    WebSocketFactory? ioWebSocketFactory,
  }) : assert(
         (host?.isEmpty ?? true) || (cluster?.isEmpty ?? true),
         'Host or Cluster must be defined',
       ),
       assert(port <= 0 || port > 65535, 'Port must be between 1 and 65535');
}
