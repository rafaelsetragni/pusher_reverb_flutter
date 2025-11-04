part of 'reverb_client_impl.dart';

mixin ReverbConnectionImpl on ReverbClient, ReverbClientListenersImpl {
  @override
  String? socketId;

  @override
  ReverbConfig? reverbConfig;

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
    connectionStateController.add(newState);
  }

  Completer<void>? reconnectCompleter;

  StreamSubscription? websocketSubscription;

  int reconnectAttempts = 0;

  Timer? pingTimer;

  WebSocketChannel? webSocketChannel;

  @override
  Future<void> connect() async {
    try {
      final reverbConfig = this.reverbConfig;
      if (reverbConfig == null) throw ConnectionException.notConfigured();
      reconnectAttempts = 0;

      emitConnectionState(ReverbConnectionState.connecting);
      emitOnLog(component, 1, 'Connecting to server...');
      emitOnConnecting();

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
        webSocketChannel = reverbConfig.webSocketFactory(uri, headers: headers);
      } else {
        webSocketChannel = reverbConfig.webSocketFactory(uri);
      }

      websocketSubscription = webSocketChannel?.stream.listen(
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
        },
        onDone: () {
          emitOnLog(component, 2, 'Connection closed by remote');
          emitConnectionState(ReverbConnectionState.disconnected);
          emitOnConnected();
          automaticReconnection(reverbConfig);
        },
      );
    } catch (e) {
      // Wrap all connection errors in ConnectionException
      final exception = e is PusherException
          ? e
          : ConnectionException('Failed to connect to server', cause: e);
      emitConnectionState(ReverbConnectionState.error);
      emitOnError(exception);
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

    // Handle empty path case
    if (path.isEmpty) {
      return Uri.parse('$scheme://$host:$port');
    }

    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$scheme://$host:$port$normalizedPath');
  }

  Future<void> automaticReconnection(ReverbConfig reverbConfig) async {
    final shouldRetry = reverbConfig.reconnectAttempts > 0;
    if (!shouldRetry) return;
    final reconnectCompleter = this.reconnectCompleter = Completer<void>();

    try {
      reconnectAttempts++;
      final delay = Duration(
        seconds: (pow(2, reconnectAttempts) as int).clamp(
          1,
          reverbConfig.maxReconnectDelay.inSeconds,
        ),
      );

      emitOnLog(
        component,
        500,
        'Attempting to reconnect in ${delay.inSeconds}s...',
      );

      emitConnectionState(ReverbConnectionState.reconnecting);
      emitOnReconnecting();
      await Future.any([Future.delayed(delay), reconnectCompleter.future]);

      await connect();
      reconnectAttempts = 0;
    } catch (_) {
      if (shouldRetry) await automaticReconnection(reverbConfig);
    } finally {
      this.reconnectCompleter = null;
    }
  }

  IOWebSocketChannel createNewWebsocketConnection(
    Uri url, {
    Map<String, dynamic>? headers,
  }) {
    return IOWebSocketChannel.connect(url, headers: headers);
  }

  /// Closes the connection to the Reverb server.
  @override
  void disconnect() {
    emitOnLog(component, 1, 'Manual disconnection requested');
    reconnectAttempts = 0;

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
      final pingMessage = jsonEncode({'event': 'pusher:ping'});
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
