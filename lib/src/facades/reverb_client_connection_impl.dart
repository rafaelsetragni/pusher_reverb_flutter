part of 'reverb_client_impl.dart';

mixin ReverbConnectionImpl on ReverbClient, ReverbClientListenersImpl {
  @override
  String? socketId;

  final Map<String, ReverbChannel> channels = {};

  final StateStream<ReverbConnectionState> connectionStateController =
      StateStream.broadcast(initialValue: ReverbConnectionState.disconnected);

  final StateStream<dynamic> remoteEventController = StateStream.broadcast();

  @override
  Stream<ReverbConnectionState> get onConnectionStateChange =>
      connectionStateController.stream;

  @override
  ReverbConnectionState get connectionState => connectionStateController.value;

  void emitConnectionState(ReverbConnectionState newState) {
    if (connectionState == newState) return;
    if (connectionState == ReverbConnectionState.connected) {
      reconnectionsAttempted = 0;
    }
    connectionStateController.add(newState);
  }

  Completer<void>? reconnectCompleter;

  StreamSubscription? websocketSubscription;

  int reconnectionsAttempted = 0;

  Timer? pingTimer;

  WebSocketChannel? webSocketChannel;
  Completer<void>? connectionCompleter;

  @override
  Future<void> connect() async {
    Completer<void> connectionCompleter = this.connectionCompleter =
        Completer();
    try {
      final reverbConfig = this.reverbConfig;

      emitConnectionState(ReverbConnectionState.connecting);
      emitOnLog(component, 1, 'Connecting to server...');
      emitOnConnecting();

      late WebSocketChannel webSocketChannel;
      final uri = _constructWebSocketUri(
        useTLS: reverbConfig.useTLS,
        wsPath: reverbConfig.wsPath,
        appKey: reverbConfig.appKey,
        host: reverbConfig.host,
        port: reverbConfig.port,
      );

      // Create WebSocket with API key headers if provided
      final apiKey = reverbConfig.apiKey;
      if (reverbConfig.apiKey != null) {
        final headers = <String, dynamic>{
          'Authorization': 'Bearer $apiKey',
          ...?reverbConfig.additionalHeaders,
        };
        webSocketChannel = this.webSocketChannel = reverbConfig
            .webSocketFactory(uri, headers: headers);
      } else {
        webSocketChannel = this.webSocketChannel = reverbConfig
            .webSocketFactory(uri);
      }

      websocketSubscription = webSocketChannel.stream.listen(
        remoteEventController.add,
        onError: (error) {
          // Wrap WebSocket errors in ConnectionException
          emitOnLog(component, 3, 'WebSocket error occurred', error);
          final exception = ConnectionException(
            'WebSocket error occurred',
            cause: error,
          );
          emitConnectionState(ReverbConnectionState.error);
          emitOnError(exception);

          if (!connectionCompleter.isCompleted) {
            connectionCompleter.completeError(exception);
          }
        },
        onDone: () {
          emitOnLog(component, 2, 'Connection closed by remote');
          emitConnectionState(ReverbConnectionState.disconnected);
          emitOnDisconnected();

          if (!connectionCompleter.isCompleted) {
            connectionCompleter.complete();
          }

          automaticReconnection(reverbConfig);
        },
      );

      return connectionCompleter.future;
    } catch (e) {
      // Wrap all connection errors in ConnectionException
      final exception = e is PusherException
          ? e
          : ConnectionException('Failed to connect to server', cause: e);
      emitConnectionState(ReverbConnectionState.error);
      emitOnError(exception);
      if (!connectionCompleter.isCompleted) {
        connectionCompleter.completeError(e);
      }
      rethrow;
    }
  }

  Uri _constructWebSocketUri({
    required bool useTLS,
    required String? wsPath,
    required String? appKey,
    required String? host,
    required int port,
  }) {
    final path = ((wsPath?.isEmpty ?? true) || wsPath == '/')
        ? '/app/$appKey'
        : '$wsPath';
    final scheme = useTLS ? 'wss' : 'ws';

    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$scheme://$host:$port$normalizedPath');
  }

  Future<void> automaticReconnection(ReverbConfig reverbConfig) async {
    if (reverbConfig.reconnectAttempts == 0) return;
    final attemptsExhausted =
        reconnectionsAttempted++ >= reverbConfig.reconnectAttempts;
    if (attemptsExhausted) return;
    final reconnectCompleter = this.reconnectCompleter = Completer<void>();

    try {
      final delay = DelayUtil.calculateReconnectDelay(
        reconnectionsAttempted: reconnectionsAttempted,
        reconnectDelay: reverbConfig.reconnectDelay,
        maxReconnectDelay: reverbConfig.maxReconnectDelay,
      );

      emitOnLog(
        component,
        500,
        'Attempting to reconnect in ${delay.inMilliseconds}ms...',
      );

      emitConnectionState(ReverbConnectionState.reconnecting);
      emitOnReconnecting();
      await Future.any([Future.delayed(delay), reconnectCompleter.future]);

      await connect();
    } finally {
      this.reconnectCompleter = null;
    }
  }

  /// Closes the connection to the Reverb server.
  @override
  void disconnect() {
    emitOnLog(component, 1, 'Manual disconnection requested');
    reconnectionsAttempted = 0;

    for (final channel in channels.values) {
      channel
        ..unsubscribe()
        ..dispose();
    }
    channels.clear();

    // Cancel any ongoing reconnection
    reconnectCompleter?.complete();
    reconnectCompleter = null;

    // Stop ping timer before cleaning up channels and socket
    stopPingTimer();

    websocketSubscription?.cancel();
    webSocketChannel?.sink.close();

    emitConnectionState(ReverbConnectionState.disconnected);
    emitOnDisconnected();
  }

  void startPingTimer(Duration pingInterval) {
    stopPingTimer();
    emitOnLog(
      component,
      0,
      'Starting ping timer every ${pingInterval.inSeconds} seconds',
    );
    pingTimer = Timer.periodic(pingInterval, (_) {
      final pingMessage = JsonUtil.encode({'event': 'pusher:ping'});
      sendMessage(pingMessage);
      emitOnLog(component, 0, 'Ping sent to server.');
    });
  }

  void stopPingTimer() {
    if (pingTimer != null) {
      emitOnLog(component, 0, 'Stopping ping timer.');
      pingTimer!.cancel();
      pingTimer = null;
    }
  }
}
