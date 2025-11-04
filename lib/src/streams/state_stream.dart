import 'dart:async';

/// A stream controller that always keeps track of the latest emitted value.
/// Throws [StateError] if [value] is accessed before any event is added.
class StateStream<T> {
  final StreamController<T> _controller;
  T? _lastValue;
  bool _hasValue = false;

  StateStream._(this._controller);

  /// Creates a broadcast stream with an optional initial value.
  factory StateStream.broadcast({T? initialValue}) {
    final controller = StreamController<T>.broadcast();
    final instance = StateStream._(controller);

    if (initialValue != null) {
      instance._lastValue = initialValue;
      instance._hasValue = true;
      controller.add(initialValue);
    }

    return instance;
  }

  /// The current value, or throws if no value has been emitted yet.
  T get value {
    if (!_hasValue) {
      throw StateError('No value has been emitted yet');
    }
    return _lastValue as T;
  }

  /// Adds a new value to the stream.
  void add(T newValue) {
    _lastValue = newValue;
    _hasValue = true;
    _controller.add(newValue);
  }

  /// Returns the broadcast stream for listening.
  Stream<T> get stream => _controller.stream;

  /// Whether the stream has a current value.
  bool get hasValue => _hasValue;

  /// Closes the underlying stream controller.
  Future<void> close() => _controller.close();
}
