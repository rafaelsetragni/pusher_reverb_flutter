import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../pusher_reverb_flutter.dart';
import '../authentications/channel_authenticator.dart';
import '../types/websocket_factory.dart';

class ReverbConfig {
  /// Interval for sending ping messages to the server.
  final Duration pingInterval;

  /// The host of the Reverb server.
  late final String? host;

  /// The port of the Reverb server.
  late final int port;

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
  late final bool useTLS;

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

  final ChannelAuthenticator channelAuthenticator;

  @Deprecated('Use host, port, useTLS, and cluster directly instead')
  String? get effectiveHost => host;
  @Deprecated('Use host, port, useTLS, and cluster directly instead')
  int? get effectivePort => port;
  @Deprecated('Use host, port, useTLS, and cluster directly instead')
  bool? get effectiveUseTLS => useTLS;

  bool? get isUsingCluster => cluster != null;

  late final ClusterConfig? _clusterConfig;

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
    this.apiKey,
    int? port,
    String? host,
    this.cluster,
    this.authorizer,
    this.authEndpoint,
    this.wsPath,
    bool useTLS = false,
    this.reconnectAttempts = 10,
    this.reconnectDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(seconds: 30),
    this.pingInterval = const Duration(seconds: 30),
    this.additionalHeaders,
    WebSocketFactory? webSocketFactory,
    ChannelAuthenticator? channelAuthenticator,
  }) : assert(appKey.isNotEmpty, 'App key must be defined'),
       assert(cluster?.isNotEmpty ?? true, 'cluster cannot be empty'),
       assert(
         host?.isNotEmpty ?? cluster?.isNotEmpty == true,
         'Host and Cluster cannot be defined at same time',
       ),
       assert(
         port == null || port > 0 && port <= 65535,
         'Port must be between 1 and 65535',
       ),
       channelAuthenticator = channelAuthenticator ?? ChannelAuthenticator() {
    this.webSocketFactory = webSocketFactory ?? createNewWebsocketConnection;

    final clusterConfig = ClusterConfig.fromRegion(cluster);
    assert(
      cluster == null || clusterConfig != null,
      'Invalid cluster configuration',
    );

    this.useTLS = clusterConfig?.useTLS ?? useTLS;
    this.host = clusterConfig?.host ?? host;
    this.port = clusterConfig?.port ?? port ?? 443;
  }

  WebSocketChannel createNewWebsocketConnection(
    Uri url, {
    Map<String, dynamic>? headers,
  }) {
    return IOWebSocketChannel.connect(url, headers: headers);
  }

  static ReverbConfig fromJson(Map<String, Object?> json) {
    return ReverbConfig(
      appKey: json['appKey'] as String,
      apiKey: json['apiKey'] as String?,
      host: json['host'] as String?,
      port: json['port'] as int?,
      cluster: json['cluster'] as String?,
      authEndpoint: json['authEndpoint'] as String?,
      wsPath: json['wsPath'] as String?,
      useTLS: json['useTLS'] as bool? ?? false,
      reconnectAttempts: json['reconnectAttempts'] as int? ?? 10,
      reconnectDelay: Duration(
        milliseconds: json['reconnectDelayMs'] as int? ?? 1000,
      ),
      maxReconnectDelay: Duration(
        milliseconds: json['maxReconnectDelayMs'] as int? ?? 30000,
      ),
      pingInterval: Duration(
        milliseconds: json['pingIntervalMs'] as int? ?? 30000,
      ),
      additionalHeaders: (json['additionalHeaders'] as Map?)?.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      ),
      channelAuthenticator: ChannelAuthenticator(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'appKey': appKey,
      'apiKey': apiKey,
      'host': host,
      'port': port,
      'cluster': cluster,
      'authEndpoint': authEndpoint,
      'wsPath': wsPath,
      'useTLS': useTLS,
      'reconnectAttempts': reconnectAttempts,
      'reconnectDelayMs': reconnectDelay.inMilliseconds,
      'maxReconnectDelayMs': maxReconnectDelay.inMilliseconds,
      'pingIntervalMs': pingInterval.inMilliseconds,
      'additionalHeaders': additionalHeaders,
    };
  }

  ReverbConfig copyWith({
    Duration? pingInterval,
    String? host,
    int? port,
    String? appKey,
    String? apiKey,
    String? cluster,
    Authorizer? authorizer,
    String? authEndpoint,
    String? wsPath,
    bool? useTLS,
    int? reconnectAttempts,
    Duration? reconnectDelay,
    Duration? maxReconnectDelay,
    WebSocketFactory? webSocketFactory,
    Map<String, String>? additionalHeaders,
  }) {
    return ReverbConfig(
      pingInterval: pingInterval ?? this.pingInterval,
      host: host ?? this.host,
      port: port ?? this.port,
      appKey: appKey ?? this.appKey,
      apiKey: apiKey ?? this.apiKey,
      cluster: cluster ?? this.cluster,
      authorizer: authorizer ?? this.authorizer,
      authEndpoint: authEndpoint ?? this.authEndpoint,
      wsPath: wsPath ?? this.wsPath,
      useTLS: useTLS ?? this.useTLS,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      reconnectDelay: reconnectDelay ?? this.reconnectDelay,
      maxReconnectDelay: maxReconnectDelay ?? this.maxReconnectDelay,
      webSocketFactory: webSocketFactory ?? this.webSocketFactory,
      additionalHeaders: additionalHeaders ?? this.additionalHeaders,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReverbConfig &&
            runtimeType == other.runtimeType &&
            pingInterval == other.pingInterval &&
            host == other.host &&
            port == other.port &&
            appKey == other.appKey &&
            apiKey == other.apiKey &&
            cluster == other.cluster &&
            authorizer == other.authorizer &&
            authEndpoint == other.authEndpoint &&
            wsPath == other.wsPath &&
            useTLS == other.useTLS &&
            reconnectAttempts == other.reconnectAttempts &&
            reconnectDelay == other.reconnectDelay &&
            maxReconnectDelay == other.maxReconnectDelay &&
            additionalHeaders.toString() ==
                other.additionalHeaders.toString() &&
            webSocketFactory == other.webSocketFactory;
  }

  @override
  int get hashCode => Object.hash(
    pingInterval,
    host,
    port,
    appKey,
    apiKey,
    cluster,
    authorizer,
    authEndpoint,
    wsPath,
    useTLS,
    reconnectAttempts,
    reconnectDelay,
    maxReconnectDelay,
    additionalHeaders.toString(),
    webSocketFactory,
  );
}
