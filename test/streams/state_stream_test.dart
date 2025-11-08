import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/src/streams/state_stream.dart';

void main() {
  group('StateStream', () {
    test(
      'should throw StateError when value is accessed before any emission',
      () {
        final stream = StateStream<int>.broadcast();
        expect(() => stream.value, throwsA(isA<StateError>()));
      },
    );

    test('should return initial value when provided', () {
      final stream = StateStream<int>.broadcast(initialValue: 10);
      expect(stream.value, 10);
      expect(stream.hasValue, isTrue);
    });

    test('should emit and store the latest value', () async {
      final stream = StateStream<String>.broadcast();
      final emitted = <String>[];

      stream.stream.listen(emitted.add);
      stream.add('A');
      stream.add('B');

      await Future.delayed(Duration.zero); // allow stream to emit

      expect(emitted, ['A', 'B']);
      expect(stream.value, 'B');
    });

    test('should notify listeners of new values', () async {
      final stream = StateStream<bool>.broadcast();
      final completer = Completer<void>();

      stream.stream.listen((val) {
        if (val == true) {
          completer.complete();
        }
      });

      stream.add(true);

      await expectLater(completer.future, completes);
    });

    test('should properly close the stream', () async {
      final stream = StateStream<double>.broadcast();
      await stream.close();
      expect(stream.stream.isBroadcast, isTrue); // still a broadcast stream
    });

    test('should indicate whether it has a value', () {
      final stream = StateStream<String>.broadcast();
      expect(stream.hasValue, isFalse);
      stream.add('hello');
      expect(stream.hasValue, isTrue);
    });
  });
}
