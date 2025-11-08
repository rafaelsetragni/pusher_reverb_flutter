import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/src/utils/delay_util.dart';

void main() {
  group('DelayUtil.calculateReconnectDelay', () {
    const reconnectDelay = Duration(seconds: 2);
    const maxReconnectDelay = Duration(seconds: 60);

    test('returns initial reconnect delay for first attempt', () {
      final result = DelayUtil.calculateReconnectDelay(
        reconnectionsAttempted: 1,
        reconnectDelay: reconnectDelay,
        maxReconnectDelay: maxReconnectDelay,
      );
      expect(result, reconnectDelay);
    });

    test('returns exponential delay for subsequent attempts', () {
      final result = DelayUtil.calculateReconnectDelay(
        reconnectionsAttempted: 3,
        reconnectDelay: reconnectDelay,
        maxReconnectDelay: maxReconnectDelay,
      );
      // 2 * 2^(3-1) = 2 * 4 = 8 seconds
      expect(result, Duration(seconds: 8));
    });

    test('clamps delay to maxReconnectDelay', () {
      final result = DelayUtil.calculateReconnectDelay(
        reconnectionsAttempted: 10,
        reconnectDelay: reconnectDelay,
        maxReconnectDelay: maxReconnectDelay,
      );
      expect(result, maxReconnectDelay);
    });

    test('clamps delay to minimum of 100 milliseconds', () {
      final result = DelayUtil.calculateReconnectDelay(
        reconnectionsAttempted: 1,
        reconnectDelay: Duration(milliseconds: 100),
        maxReconnectDelay: Duration(seconds: 1),
      );
      expect(result, Duration(milliseconds: 100));
    });
  });
}
