import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/src/exceptions/exceptions.dart';
import 'package:pusher_reverb_flutter/src/validations/channel_validation.dart';

void main() {
  group('validatePublicChannelName', () {
    test('throws if name is empty', () {
      expect(
        () => validatePublicChannelName('  '),
        throwsA(isA<InvalidChannelNameException>()),
      );
    });

    test('throws if name starts with private-', () {
      expect(
        () => validatePublicChannelName('private-channel'),
        throwsA(isA<InvalidChannelNameException>()),
      );
    });

    test('throws if name starts with private-encrypted-', () {
      expect(
        () => validatePublicChannelName('private-encrypted-room'),
        throwsA(isA<InvalidChannelNameException>()),
      );
    });

    test('throws if name starts with private-encrypted-', () {
      expect(
        () => validatePublicChannelName('private-encrypted-channel'),
        throwsA(isA<InvalidChannelNameException>()),
      );
    });

    test('throws if name starts with presence-', () {
      expect(
        () => validatePublicChannelName('presence-channel'),
        throwsA(isA<InvalidChannelNameException>()),
      );
    });

    test('throws if name exceeds 200 characters', () {
      final longName = 'a' * 201;
      expect(
        () => validatePublicChannelName(longName),
        throwsA(isA<InvalidChannelNameException>()),
      );
    });

    test('throws if name contains invalid characters', () {
      expect(
        () => validatePublicChannelName('public-chan#nel'),
        throwsA(isA<InvalidChannelNameException>()),
      );
    });

    test('passes for valid name', () {
      expect(
        () => validatePublicChannelName('public-channel_1=2@3,4.5;6'),
        returnsNormally,
      );
    });
  });

  group('validatePrivateChannelName', () {
    test('throws if name is empty', () {
      expect(
        () => validatePrivateChannelName('  '),
        throwsA(isA<InvalidChannelNameException>()),
      );
    });

    test('throws if name does not start with private-', () {
      expect(
        () => validatePrivateChannelName('pub-channel'),
        throwsA(isA<InvalidChannelNameException>()),
      );
    });

    test('throws if name exceeds 200 characters', () {
      final longName = 'private-' + 'a' * 194;
      expect(
        () => validatePrivateChannelName(longName),
        throwsA(isA<InvalidChannelNameException>()),
      );
    });

    test('throws if name contains invalid characters', () {
      expect(
        () => validatePrivateChannelName('private-chan#nel'),
        throwsA(isA<InvalidChannelNameException>()),
      );
    });

    test('passes for valid name', () {
      expect(
        () => validatePrivateChannelName('private-channel_name'),
        returnsNormally,
      );
    });
  });

  group('validatePresenceChannelName', () {
    test('throws if name is empty', () {
      expect(
        () => validatePresenceChannelName('  '),
        throwsA(isA<InvalidChannelNameException>()),
      );
    });

    test('throws if name does not start with presence-', () {
      expect(
        () => validatePresenceChannelName('pub-channel'),
        throwsA(isA<InvalidChannelNameException>()),
      );
    });

    test('throws if name exceeds 200 characters', () {
      final longName = 'presence-' + 'a' * 192;
      expect(
        () => validatePresenceChannelName(longName),
        throwsA(isA<InvalidChannelNameException>()),
      );
    });

    test('throws if name contains invalid characters', () {
      expect(
        () => validatePresenceChannelName('presence-chan#nel'),
        throwsA(isA<InvalidChannelNameException>()),
      );
    });

    test('passes for valid name', () {
      expect(
        () => validatePresenceChannelName('presence-channel'),
        returnsNormally,
      );
    });
  });

  group('validateEncryptedChannelName', () {
    test('throws if name is empty', () {
      expect(
        () => validateEncryptedChannelName('  '),
        throwsA(isA<InvalidChannelNameException>()),
      );
    });

    test('throws if name does not start with private-encrypted-', () {
      expect(
        () => validateEncryptedChannelName('private-channel'),
        throwsA(isA<InvalidChannelNameException>()),
      );
    });

    test('throws if name exceeds 200 characters', () {
      final longName = 'private-encrypted-' + 'a' * 200;
      expect(
        () => validateEncryptedChannelName(longName),
        throwsA(isA<InvalidChannelNameException>()),
      );
    });

    test('throws if name contains invalid characters', () {
      expect(
        () => validateEncryptedChannelName('private-encrypted-chan#nel'),
        throwsA(isA<InvalidChannelNameException>()),
      );
    });

    test('passes for valid name', () {
      expect(
        () => validateEncryptedChannelName('private-encrypted-name'),
        returnsNormally,
      );
    });
  });
}
