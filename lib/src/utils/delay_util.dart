import 'dart:math';

sealed class DelayUtil {
  static Duration calculateReconnectDelay({
    required int reconnectionsAttempted,
    required Duration reconnectDelay,
    required Duration maxReconnectDelay,
  }) {
    final baseDelayMs = reconnectDelay.inMilliseconds;
    final exponentialDelayMs = baseDelayMs * pow(2, reconnectionsAttempted - 1);
    final clampedDelayMs = exponentialDelayMs
        .clamp(
          reconnectDelay.inMilliseconds.toDouble(),
          maxReconnectDelay.inMilliseconds.toDouble(),
        )
        .toInt();
    return Duration(milliseconds: clampedDelayMs);
  }
}
