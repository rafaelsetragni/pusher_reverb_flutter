part of 'reverb_client_impl.dart';

enum ChannelType { public, private, presence, encrypted }

mixin ReverbChannelConnectionImpl on ReverbClient
    implements ReverbClientListenersImpl, ReverbConnectionImpl {
  final Map<String, Channel> channels = {};

  T _createChannel<T extends Channel>({
    required String channelName,
    required T Function() onAbsentChannel,
    required ChannelType channelType,
  }) {
    validatePrivateChannelName(channelName);
    Channel existingChannel = channels[channelName] ?? onAbsentChannel();

    if (existingChannel is! T) {
      throw ChannelException.mismatchedChannelType(
        channelType.name,
        channelName,
      );
    }

    channels[channelName] = existingChannel;
    return existingChannel;
  }

  @override
  PublicChannel registerPublicChannel(String channelName) {
    validatePublicChannelName(channelName);

    final channel = _createChannel(
      channelName: channelName,
      channelType: ChannelType.public,
      onAbsentChannel: () =>
          PublicChannel(name: channelName, sendMessage: sendMessage),
    );

    final socketId = this.socketId;
    if (socketId != null) {
      channel.subscribe();
    }

    return channel;
  }

  @override
  PrivateChannel registerPrivateChannel(
    String channelName, {
    required String authKey,
  }) {
    validatePrivateChannelName(channelName);

    final channel = _createChannel(
      channelName: channelName,
      channelType: ChannelType.private,
      onAbsentChannel: () =>
          PrivateChannel(name: channelName, sendMessage: sendMessage),
    );

    final socketId = this.socketId;
    if (socketId != null) {
      channel.subscribe(authKey: authKey);
    }
    return channel;
  }

  @override
  PresenceChannel registerToPresenceChannel(
    String channelName, {
    required String authKey,
    Map<String, dynamic>? channelData,
  }) {
    validatePresenceChannelName(channelName);

    final channel = _createChannel(
      channelName: channelName,
      channelType: ChannelType.private,
      onAbsentChannel: () => PresenceChannel(
        name: channelName,
        sendMessage: sendMessage,
        channelData: channelData,
      ),
    );

    final socketId = this.socketId;
    if (socketId != null) {
      channel.subscribe(authKey: authKey);
    }
    return channel;
  }

  @override
  EncryptedChannel registerEncryptedChannel(
    String channelName, {
    required String authKey,
    required String encryptionMasterKey,
  }) {
    validateEncryptedChannelName(channelName);

    final channel = _createChannel(
      channelName: channelName,
      channelType: ChannelType.private,
      onAbsentChannel: () => EncryptedChannel(
        name: channelName,
        sendMessage: sendMessage,
        encryptionMasterKey: encryptionMasterKey,
      ),
    );

    final socketId = this.socketId;
    if (socketId != null) {
      channel.subscribe(authKey: authKey);
    }
    return channel;
  }

  /// Unsubscribes from a channel.
  void unsubscribeFromChannel(String channelName) {
    final channel = channels[channelName];
    if (channel != null) {
      channel.unsubscribe();
      channel.dispose();
      if (channels.containsKey(channelName)) {
        channels.remove(channelName);
      }
    }
  }

  /// Gets a channel by name if it exists.
  @override
  Channel? getChannel(String channelName) {
    return channels[channelName];
  }

  /// Gets all subscribed channels.
  @override
  List<Channel> get subscribedChannels => channels.values.toList();

  @override
  void unregisterChannel(String channelName) {
    // TODO: implement unRegisterChannel
  }
}
