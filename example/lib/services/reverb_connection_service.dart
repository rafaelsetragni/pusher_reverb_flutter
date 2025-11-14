part of 'reverb_service.dart';

class _ReverbConnectionListener implements ReverbEventListener {
  final ReverbServiceImpl reverbService;

  _ReverbConnectionListener(this.reverbService);

  @override
  void onConnecting(ReverbConfig config) {
    reverbService.emitLog('ReverbService', 500, 'Connecting to server...');
  }

  @override
  void onConnected(String socketId, ReverbConfig config) {
    reverbService.emitLog(
      'ReverbService',
      500,
      'Connected! Socket ID: $socketId',
    );
  }

  @override
  void onReconnecting(String socketId, ReverbConfig config) {
    reverbService.emitLog(
      'ReverbService',
      500,
      'Connection lost. Reconnecting...',
    );
  }

  @override
  void onDisconnected(String socketId, ReverbConfig config) {
    reverbService.emitLog('ReverbService', 500, 'Disconnected from server');
  }

  @override
  void onError(String? socketId, dynamic error) {
    reverbService.emitLog(
      'ReverbService',
      500,
      'Connection error: \$error',
      error,
    );
  }

  @override
  void onLog(String component, int level, String message, [dynamic error]) {
    // Not used in this context to avoid log loops
  }
}

class ReverbConnectionService {
  static ReverbConnectionService? _instance;
  final reverbService = ReverbServiceImpl.instance;

  ReverbClient? _client;

  StreamSubscription? _connectionStateSubscription;
  final StreamController<ReverbConnectionState> _connectionStateController =
      StreamController<ReverbConnectionState>.broadcast();

  ReverbConfig get currentConfig => _config;
  ReverbConfig _config = ReverbConfig(appKey: 'Your-api-key', cluster: 'local');

  // Private constructor for singleton
  ReverbConnectionService._();

  /// Get the singleton instance
  static ReverbConnectionService get instance =>
      _instance ??= ReverbConnectionService._();

  /// Get the Reverb client (may be null if not initialized)
  ReverbClient? get client => _client;

  /// Exposes a stream of connection state changes.
  Stream<ReverbConnectionState> get onConnectionStateChange =>
      _connectionStateController.stream;

  /// Get the current connection state (if client is initialized)
  ReverbConnectionState get currentConnectionState =>
      _client?.connectionState ?? ReverbConnectionState.disconnected;

  /// Check if the client is initialized
  bool get isInitialized => _client != null;

  /// Load configuration from shared preferences
  Future<ReverbConfig?> loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('reverb_config_json');
    if (jsonString == null) return null;
    final json = jsonDecode(jsonString);
    final config = _config = ReverbConfig.fromJson(json);
    return config;
  }

  /// Save configuration to shared preferences
  Future<void> saveConfiguration(ReverbConfig config) async {
    _config = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reverb_config_json', jsonEncode(config.toJson()));
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
      'Authorization': 'Bearer \${_config.authToken}',
      'Content-Type': 'application/json',
    };
  }

  /// Initialize the Reverb client
  Future<void> initialize() async {
    final reverbConfig = await loadConfiguration() ?? _config;

    final client = _client = ReverbClientBuilder()
        .setConfiguration(reverbConfig)
        .build();

    client.addListener(_ReverbConnectionListener(reverbService));
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
  }

  /// Reinitialize the client with new configuration
  /// Note: This creates a new client instance with updated configuration.
  /// The old client instance will be discarded.
  Future<void> reinitialize() async {
    disconnect();
    // Create a new client instance
    _client = null;
    await initialize();
  }

  /// Dispose of the service and clean up resources.
  void dispose() {
    _connectionStateSubscription?.cancel();
    _connectionStateController.close();
  }
}
