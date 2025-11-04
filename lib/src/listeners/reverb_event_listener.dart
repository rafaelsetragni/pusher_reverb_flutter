import '../models/reverb_config.dart';

abstract class ReverbEventListener {
  /// Callback for when the connection attempt starts.
  void onConnecting(ReverbConfig reverbConfig);

  /// Callback for when the connection is successfully established.
  void onConnected(String socketId, ReverbConfig reverbConfig);

  /// Callback for when the client starts attempting to reconnect.
  void onReconnecting(String socketId, ReverbConfig reverbConfig);

  /// Callback for when the connection is closed or lost.
  void onDisconnected(String socketId, ReverbConfig reverbConfig);

  /// Callback for when a connection error occurs.
  void onError(String? socketId, dynamic error);

  void onLog(String component, int level, String message, [dynamic error]);
}
