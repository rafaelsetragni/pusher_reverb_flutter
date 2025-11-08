part of 'reverb_service.dart';

class ReverbConnectionService {
  static ReverbConnectionService? _instance;
  final reverbService = ReverbServiceImpl.instance;

  rb.ReverbClient? _client;

  StreamSubscription? _connectionStateSubscription;
  final StreamController<rb.ReverbConnectionState> _connectionStateController =
      StreamController<rb.ReverbConnectionState>.broadcast();

  ReverbConfig get currentConfig => _config;
  ReverbConfig _config = ReverbConfig.initial();

  // Private constructor for singleton
  ReverbConnectionService._();

  /// Get the singleton instance
  static ReverbConnectionService get instance =>
      _instance ??= ReverbConnectionService._();

  /// Get the Reverb client (may be null if not initialized)
  rb.ReverbClient? get client => _client;

  /// Exposes a stream of connection state changes.
  Stream<rb.ReverbConnectionState> get onConnectionStateChange =>
      _connectionStateController.stream;

  /// Get the current connection state (if client is initialized)
  rb.ReverbConnectionState get currentConnectionState =>
      _client?.connectionState ?? rb.ReverbConnectionState.disconnected;

  /// Check if the client is initialized
  bool get isInitialized => _client != null;

  /// Load configuration from shared preferences
  Future<ReverbConfig> loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final json = {
      'host': prefs.getString('reverb_host'),
      'port': prefs.getInt('reverb_port'),
      'appKey': prefs.getString('reverb_app_key'),
      'authEndpoint': prefs.getString('reverb_auth_endpoint'),
      'wsPath': prefs.getString('reverb_ws_path'),
      'authToken': prefs.getString('reverb_auth_token'),
      'useTLS': prefs.getBool('reverb_use_tls'),
      'apiKey': prefs.getString('reverb_api_key'),
      'cluster': prefs.getString('reverb_cluster'),
    };
    return ReverbConfig.fromJson(json);
  }

  /// Save configuration to shared preferences
  Future<void> saveConfiguration(ReverbConfig config) async {
    _config = config;
    final prefs = await SharedPreferences.getInstance();
    final json = config.toJson();
    await prefs.setString('reverb_host', json['host']);
    await prefs.setInt('reverb_port', json['port']);
    await prefs.setString('reverb_app_key', json['appKey']);
    await prefs.setString('reverb_auth_endpoint', json['authEndpoint']);
    await prefs.setString('reverb_ws_path', json['wsPath']);
    await prefs.setString('reverb_auth_token', json['authToken']);
    await prefs.setBool('reverb_use_tls', json['useTLS']);
    await prefs.setString('reverb_api_key', json['apiKey']);
    await prefs.setString('reverb_cluster', json['cluster']);
  }

  /// Get current configuration
  Map<String, dynamic> get configuration => _config.toJson();

  /// Sample authorizer function for private channels
  Future<Map<String, String>> _authorizer(
    String channelName,
    String socketId,
  ) async {
    // In a real app, you would fetch the token from secure storage
    // or your authentication service
    return {
      'Authorization': 'Bearer ${_config.authToken}',
      'Content-Type': 'application/json',
    };
  }

  /// Initialize the Reverb client
  Future<void> initialize() async {
    await loadConfiguration();

    _client = rb.ReverbClient.instance(
      host: _config.host,
      port: _config.port,
      appKey: _config.appKey,
      apiKey: _config.apiKey.isNotEmpty ? _config.apiKey : null,
      cluster: _config.cluster.isNotEmpty ? _config.cluster : null,
      wsPath: _config.wsPath,
      useTLS: _config.useTLS,
      authorizer: _authorizer,
      authEndpoint: _config.authEndpoint,
      onConnecting: () {
        reverbService.emitLog('ReverbService', 500, 'Connecting to server...');
      },
      onConnected: (socketId) {
        reverbService.emitLog(
          'ReverbService',
          500,
          'Connected! Socket ID: $socketId',
        );
      },
      onReconnecting: () {
        reverbService.emitLog(
          'ReverbService',
          500,
          'Connection lost. Reconnecting...',
        );
      },
      onDisconnected: () {
        reverbService.emitLog('ReverbService', 500, 'Disconnected from server');
      },
      onError: (error) {
        reverbService.emitLog(
          'ReverbService',
          500,
          'Connection error: $error',
          error,
        );
      },
    );
    final client = _client;
    if (client == null) return;
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = client.onConnectionStateChange.listen((
      state,
    ) {
      _connectionStateController.add(state);
    });
  }

  /// Connect to the Reverb server
  Future<void> connect() async {
    final client = _client;
    if (client == null) {
      await initialize();
    }
    final currentClient = _client;
    if (currentClient == null) return;

    try {
      await currentClient.connect();
    } catch (e) {
      reverbService.emitLog('ReverbService', 3, 'Connection failed', e);
      rethrow;
    }
  }

  /// Disconnect from the Reverb server
  Future<void> disconnect() async {
    final client = _client;
    if (client == null) return;
    client.disconnect();
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
  }

  /// Reinitialize the client with new configuration
  /// Note: This creates a new client instance with updated configuration.
  /// The old client instance will be discarded.
  Future<void> reinitialize() async {
    disconnect();
    // Create a new client instance (singleton will be replaced)
    _client = null;
    await initialize();
  }

  /// Dispose of the service and clean up resources.
  void dispose() {
    _connectionStateSubscription?.cancel();
    _connectionStateController.close();
  }
}
