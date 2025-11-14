import 'dart:async';
import 'dart:convert';

import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'reverb_channel_service.dart';
part 'reverb_connection_service.dart';

abstract class ReverbLogListener {
  void onReverbLog(String name, int logLevel, String message, [dynamic error]);
}

/// Public interface for the Reverb service (facade).
///
/// Use [ReverbService.instance] to access the singleton implementation.
abstract class ReverbService {
  /// Singleton access point (through the interface).
  factory ReverbService() => ReverbServiceImpl.instance;

  // --- Connection (delegates to ReverbConnectionService) ---

  ReverbConfig get currentConfig;
  bool get isConnected;

  ReverbConnectionState get connectionState;
  Stream<ReverbConnectionState> get onConnectionStateChange;

  String? get socketId;

  bool? get isUsingCluster;

  String? get cluster;

  Future<void> initialize();

  Future<ReverbConfig?> loadConfiguration();
  Future<void> saveConfiguration(ReverbConfig config);

  // --- Logging listeners ---
  void addLogListener(ReverbLogListener listener);
  void removeLogListener(ReverbLogListener listener);

  // --- Channels (delegates to ReverbChannelService) ---
  Future<ReverbPublicChannel> registerPublicChannel(String channelName);

  Future<ReverbPrivateChannel> registerPrivateChannel(String channelName);

  Future<ReverbPresenceChannel> registerPresenceChannel(String channelName);

  Future<ReverbEncryptedChannel> registerEncryptedChannel(
    String channelName, {
    required String encryptionMasterKey,
  });

  Future<void> unsubscribe(String channelName);
  Future<void> unsubscribeAll();

  Future<void> connect();

  Future<void> disconnect();

  Future<void> setConfiguration(ReverbConfig config);
}

/// Concrete implementation hidden behind [ReverbService].
class ReverbServiceImpl implements ReverbService {
  ReverbServiceImpl._();
  static ReverbServiceImpl? _singleton;
  static ReverbServiceImpl get instance => _singleton ??= ReverbServiceImpl._();

  ReverbConnectionService get _connection => ReverbConnectionService.instance;
  ReverbChannelService get _channels => ReverbChannelService();

  final List<ReverbLogListener> _logListeners = [];

  @override
  ReverbConfig get currentConfig => _connection.currentConfig;

  @override
  String? get socketId => _connection.client?.socketId;

  @override
  String? get cluster => _connection.client?.reverbConfig.cluster;

  @override
  bool? get isUsingCluster => cluster != null;

  @override
  bool get isConnected =>
      _connection.currentConnectionState == ReverbConnectionState.connected;

  @override
  ReverbConnectionState get connectionState =>
      _connection.currentConnectionState;

  @override
  Future<void> initialize() => _connection.initialize();

  @override
  Future<ReverbConfig?> loadConfiguration() => _connection.loadConfiguration();

  @override
  Future<void> saveConfiguration(ReverbConfig config) {
    return _connection.saveConfiguration(config);
  }

  @override
  Stream<ReverbConnectionState> get onConnectionStateChange =>
      _connection.onConnectionStateChange;

  @override
  Future<void> connect() => _connection.connect();

  @override
  Future<void> disconnect() => _connection.disconnect();

  @override
  void addLogListener(ReverbLogListener listener) {
    if (!_logListeners.contains(listener)) {
      _logListeners.add(listener);
    }
  }

  @override
  void removeLogListener(ReverbLogListener listener) {
    _logListeners.remove(listener);
  }

  /// Emits a log message to all registered listeners.
  void emitLog(String name, int logLevel, String message, [dynamic error]) {
    for (final listener in _logListeners) {
      listener.onReverbLog(name, logLevel, message, error);
    }
  }

  // --- Channels ---

  @override
  Future<ReverbPublicChannel> registerPublicChannel(String channelName) async {
    final channel = await _channels.registerPublicChannel(channelName);
    // Example of emitting a log via the facade when subscription succeeds.
    emitLog('ReverbService', 20, 'Subscribed to $channelName');
    return channel;
  }

  @override
  Future<ReverbPrivateChannel> registerPrivateChannel(
    String channelName,
  ) async {
    final channel = await _channels.registerPrivateChannel(channelName);
    // Example of emitting a log via the facade when subscription succeeds.
    emitLog('ReverbService', 20, 'Subscribed to $channelName');
    return channel;
  }

  @override
  Future<ReverbPresenceChannel> registerPresenceChannel(
    String channelName,
  ) async {
    final channel = await _channels.registerPresenceChannel(channelName);
    // Example of emitting a log via the facade when subscription succeeds.
    emitLog('ReverbService', 20, 'Subscribed to $channelName');
    return channel;
  }

  @override
  Future<ReverbEncryptedChannel> registerEncryptedChannel(
    String channelName, {
    required String encryptionMasterKey,
  }) async {
    final channel = await _channels.registerEncryptedChannel(
      channelName,
      encryptionMasterKey: encryptionMasterKey,
    );
    // Example of emitting a log via the facade when subscription succeeds.
    emitLog('ReverbService', 20, 'Subscribed to $channelName');
    return channel;
  }

  @override
  Future<void> unsubscribe(String channelName) async {
    await _channels.unsubscribe(channelName);
    emitLog('ReverbService', 800, 'Unsubscribed from $channelName');
  }

  @override
  Future<void> unsubscribeAll() async {
    await _channels.unsubscribeAll();
    emitLog('ReverbService', 800, 'Unsubscribed from all channels');
  }

  @override
  Future<void> setConfiguration(ReverbConfig config) async {
    _connection.client
      ?..disconnect()
      ..setConfiguration(config);
  }
}
