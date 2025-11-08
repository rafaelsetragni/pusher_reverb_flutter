import 'dart:async';

import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart' as rb;
import 'package:shared_preferences/shared_preferences.dart';

import '../exceptions/service_exceptions.dart';
import '../models/reverb_config.dart';

part 'reverb_channel_service.dart';
part 'reverb_connection_service.dart';

typedef ChannelEvent = rb.ChannelEvent;

typedef WebsocketChannel = rb.ReverbChannel;
typedef WebsocketPublicChannel = rb.ReverbPublicChannel;
typedef WebsocketPrivateChannel = rb.ReverbPrivateChannel;
typedef WebsocketEncryptedChannel = rb.ReverbEncryptedChannel;

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

  rb.ReverbConnectionState get connectionState;
  Stream<rb.ReverbConnectionState> get onConnectionStateChange;

  String? get socketId;

  bool? get isUsingCluster;

  String? get cluster;

  Future<ReverbConfig> loadConfiguration();
  Future<void> saveConfiguration(ReverbConfig config);

  // --- Logging listeners ---
  void addLogListener(ReverbLogListener listener);
  void removeLogListener(ReverbLogListener listener);

  // --- Channels (delegates to ReverbChannelService) ---
  Future<WebsocketPublicChannel> registerPublicChannel(String channelName);

  Future<WebsocketPrivateChannel> registerPrivateChannel(String channelName);

  WebsocketEncryptedChannel registerEncryptedChannel(
    String channelName, {
    required String encryptionMasterKey,
  });

  Future<void> unsubscribe(String channelName);
  Future<void> unsubscribeAll();

  Future<void> connect() async {}

  Future<void> disconnect() async {}
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
      _connection.currentConnectionState == rb.ReverbConnectionState.connected;

  @override
  rb.ReverbConnectionState get connectionState =>
      _connection.currentConnectionState;

  @override
  Future<ReverbConfig> loadConfiguration() => _connection.loadConfiguration();

  @override
  Future<void> saveConfiguration(ReverbConfig config) =>
      _connection.saveConfiguration(config);

  @override
  Stream<rb.ReverbConnectionState> get onConnectionStateChange =>
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
  Future<WebsocketPublicChannel> registerPublicChannel(
    String channelName,
  ) async {
    final channel = await _channels.registerPublicChannel(channelName);
    // Example of emitting a log via the facade when subscription succeeds.
    emitLog('ReverbService', 20, 'Subscribed to $channelName');
    return channel;
  }

  @override
  Future<WebsocketPrivateChannel> registerPrivateChannel(
    String channelName,
  ) async {
    final channel = await _channels.registerPrivateChannel(channelName);
    // Example of emitting a log via the facade when subscription succeeds.
    emitLog('ReverbService', 20, 'Subscribed to $channelName');
    return channel;
  }

  @override
  WebsocketEncryptedChannel registerEncryptedChannel(
    String channelName, {
    required String encryptionMasterKey,
  }) {
    // TODO: implement createEncryptedChannel
    throw UnimplementedError();
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
}
