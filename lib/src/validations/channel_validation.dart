import '../exceptions/exceptions.dart';

bool channelNameIsEmpty(String channelName) {
  return channelName.trim().isEmpty;
}

bool channelNameNotContainsPrivatePrefix(String channelName) {
  return !channelName.startsWith('private-');
}

bool channelNameNotContainsPrivateEncryptedPrefix(String channelName) {
  return !channelName.startsWith('private-encrypted-');
}

bool channelNameNotContainsPresencePrefix(String channelName) {
  return !channelName.startsWith('presence-');
}

bool channelNameExceedsMaxLength(String channelName) {
  return channelName.length > 200;
}

bool channelNameContainsInvalidCharacters(String channelName) {
  final invalidChars = RegExp(r'[^a-zA-Z0-9_\-=@,.;]');
  return invalidChars.hasMatch(channelName);
}

/// Validates that a channel name is a valid public channel name.
///
/// Public channels should NOT start with "private-", "private-encrypted-", or "presence-".
///
/// [channelName] The channel name to validate.
///
/// Throws [InvalidChannelNameException] if the channel name is invalid.
void validatePublicChannelName(String channelName) {
  if (channelNameIsEmpty(channelName)) {
    throw InvalidChannelNameException(
      'Channel name cannot be empty',
      channelName,
    );
  }

  if (!channelNameNotContainsPrivateEncryptedPrefix(channelName)) {
    throw InvalidChannelNameException(
      'Public channel name cannot start with "private-encrypted-" prefix',
      channelName,
    );
  }

  if (!channelNameNotContainsPresencePrefix(channelName)) {
    throw InvalidChannelNameException(
      'Public channel name cannot start with "presence-" prefix',
      channelName,
    );
  }

  if (!channelNameNotContainsPrivatePrefix(channelName)) {
    throw InvalidChannelNameException(
      'Public channel name cannot start with "private-" prefix',
      channelName,
    );
  }

  if (channelNameExceedsMaxLength(channelName)) {
    throw InvalidChannelNameException(
      'Channel name cannot exceed 200 characters',
      channelName,
    );
  }

  if (channelNameContainsInvalidCharacters(channelName)) {
    throw InvalidChannelNameException(
      'Channel name contains invalid characters. Only alphanumeric characters, '
      'underscores, hyphens, equals signs, at signs, commas, periods, and semicolons are allowed',
      channelName,
    );
  }
}

/// Validates that a channel name is a valid private channel name.
///
/// Private channels must start with the "private-" prefix.
///
/// [channelName] The channel name to validate.
///
/// Throws [InvalidChannelNameException] if the channel name is not a valid private channel name.
void validatePrivateChannelName(String channelName) {
  if (channelNameIsEmpty(channelName)) {
    throw InvalidChannelNameException(
      'Channel name cannot be empty',
      channelName,
    );
  }

  if (channelNameNotContainsPrivatePrefix(channelName)) {
    throw InvalidChannelNameException(
      'Private channel name must start with "private-" prefix',
      channelName,
    );
  }

  // Use the same validation as the base Channel class for the rest of the name
  if (channelNameExceedsMaxLength(channelName)) {
    throw InvalidChannelNameException(
      'Channel name cannot exceed 200 characters',
      channelName,
    );
  }

  if (channelNameContainsInvalidCharacters(channelName)) {
    throw InvalidChannelNameException(
      'Channel name contains invalid characters. Only alphanumeric characters, '
      'underscores, hyphens, equals signs, at signs, commas, periods, and semicolons are allowed',
      channelName,
    );
  }
}

/// Validates that a channel name is a valid presence channel name.
///
/// Presence channels must start with the "presence-" prefix.
///
/// [channelName] The channel name to validate.
///
/// Throws [InvalidChannelNameException] if the channel name is not a valid presence channel name.
void validatePresenceChannelName(String channelName) {
  if (channelNameIsEmpty(channelName)) {
    throw InvalidChannelNameException(
      'Channel name cannot be empty',
      channelName,
    );
  }

  if (channelNameNotContainsPresencePrefix(channelName)) {
    throw InvalidChannelNameException(
      'Presence channel name must start with "presence-" prefix',
      channelName,
    );
  }

  // Use the same validation as the base Channel class for the rest of the name
  if (channelNameExceedsMaxLength(channelName)) {
    throw InvalidChannelNameException(
      'Channel name cannot exceed 200 characters',
      channelName,
    );
  }

  if (channelNameContainsInvalidCharacters(channelName)) {
    throw InvalidChannelNameException(
      'Channel name contains invalid characters. Only alphanumeric characters, '
      'underscores, hyphens, equals signs, at signs, commas, periods, and semicolons are allowed',
      channelName,
    );
  }
}

/// Validates that a channel name is a valid encrypted channel name.
///
/// Encrypted channels must start with the "private-encrypted-" prefix.
/// They combine private channel authentication with end-to-end encryption.
///
/// [channelName] The channel name to validate.
///
/// Throws [InvalidChannelNameException] if the channel name is not a valid encrypted channel name.
void validateEncryptedChannelName(String channelName) {
  if (channelNameIsEmpty(channelName)) {
    throw InvalidChannelNameException(
      'Channel name cannot be empty',
      channelName,
    );
  }

  if (channelNameNotContainsPrivateEncryptedPrefix(channelName)) {
    throw InvalidChannelNameException(
      'Encrypted channel name must start with "private-encrypted-" prefix',
      channelName,
    );
  }

  // Use the same validation as the base Channel class for the rest of the name
  if (channelNameExceedsMaxLength(channelName)) {
    throw InvalidChannelNameException(
      'Channel name cannot exceed 200 characters',
      channelName,
    );
  }

  if (channelNameContainsInvalidCharacters(channelName)) {
    throw InvalidChannelNameException(
      'Channel name contains invalid characters. Only alphanumeric characters, '
      'underscores, hyphens, equals signs, at signs, commas, periods, and semicolons are allowed',
      channelName,
    );
  }
}
