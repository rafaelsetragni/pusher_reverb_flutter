part of 'reverb_client_impl.dart';

mixin ReverbClientListenersImpl on ReverbClient {
  final List<ReverbEventListener> _listeners = [];

  @override
  void addListener(ReverbEventListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  @override
  void removeListener(ReverbEventListener listener) {
    _listeners.remove(listener);
  }

  void emitOnConnecting() {
    final config = reverbConfig;
    for (final listener in List<ReverbEventListener>.from(_listeners)) {
      try {
        listener.onConnecting(config);
      } catch (_) {}
    }
  }

  void emitOnConnected() {
    final id = socketId;
    final config = reverbConfig;
    if (id == null) return;
    for (final listener in List<ReverbEventListener>.from(_listeners)) {
      try {
        listener.onConnected(id, config);
      } catch (_) {}
    }
  }

  void emitOnReconnecting() {
    final id = socketId;
    final config = reverbConfig;
    if (id == null) return;
    for (final listener in List<ReverbEventListener>.from(_listeners)) {
      try {
        listener.onReconnecting(id, config);
      } catch (_) {}
    }
  }

  void emitOnDisconnected() {
    final id = socketId;
    final config = reverbConfig;
    if (id == null) return;
    for (final listener in List<ReverbEventListener>.from(_listeners)) {
      try {
        listener.onDisconnected(id, config);
      } catch (_) {}
    }
  }

  void emitOnError(dynamic error) {
    for (final listener in List<ReverbEventListener>.from(_listeners)) {
      try {
        listener.onError(socketId, error);
      } catch (_) {}
    }
  }

  void emitOnLog(String component, int level, String message, [dynamic error]) {
    for (final listener in List<ReverbEventListener>.from(_listeners)) {
      try {
        listener.onLog(component, level, message, error);
      } catch (_) {}
    }
  }
}
