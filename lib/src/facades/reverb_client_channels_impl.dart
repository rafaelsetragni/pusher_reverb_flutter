part of 'reverb_client_impl.dart';

enum ChannelType { public, private, presence, encrypted }

mixin ReverbChannelConnectionImpl on ReverbClient
    implements ReverbClientListenersImpl, ReverbConnectionImpl {
  T _createChannel<T extends ReverbChannel>({
    required String channelName,
    required ChannelType channelType,
    required T Function() onAbsentChannel,
  }) {
    ReverbChannel existingChannel = channels[channelName] ?? onAbsentChannel();

    channels[channelName] = existingChannel;
    return existingChannel as T;
  }

  @override
  ReverbPublicChannel subscribePublicChannel({required String channelName}) {
    final channel = _createChannel(
      channelName: channelName,
      channelType: ChannelType.public,
      onAbsentChannel: () =>
          ReverbPublicChannel(name: channelName, sendMessage: sendMessage),
    );

    final socketId = this.socketId;
    if (socketId != null) {
      channel.subscribe(socketId: socketId);
    }

    return channel;
  }

  @override
  ReverbPrivateChannel subscribePrivateChannel({required String channelName}) {
    final authorizers = _validateAuthorizer(channelName);

    final channel = _createChannel(
      channelName: channelName,
      channelType: ChannelType.private,
      onAbsentChannel: () => ReverbPrivateChannel(
        name: channelName,
        sendMessage: sendMessage,
        authEndpoint: authorizers.authEndpoint,
        authorizer: authorizers.authorizer,
        channelAuthenticator: reverbConfig.channelAuthenticator,
      ),
    );

    final socketId = this.socketId;
    if (socketId != null) {
      channel.subscribe(socketId: socketId);
    }
    return channel;
  }

  @override
  ReverbPresenceChannel subscribePresenceChannel({
    required String channelName,
    Map<String, dynamic>? channelData,
  }) {
    final authorizers = _validateAuthorizer(channelName);

    final channel = _createChannel(
      channelName: channelName,
      channelType: ChannelType.private,
      onAbsentChannel: () => ReverbPresenceChannel(
        name: channelName,
        sendMessage: sendMessage,
        channelData: channelData,
        authEndpoint: authorizers.authEndpoint,
        authorizer: authorizers.authorizer,
        channelAuthenticator: reverbConfig.channelAuthenticator,
      ),
    );

    final socketId = this.socketId;
    if (socketId != null) {
      channel.subscribe(socketId: socketId);
    }
    return channel;
  }

  @override
  ReverbEncryptedChannel subscribeEncryptedChannel({
    required String channelName,
    required String encryptionMasterKey,
  }) {
    final authorizers = _validateAuthorizer(channelName);

    final channel = _createChannel(
      channelName: channelName,
      channelType: ChannelType.private,
      onAbsentChannel: () => ReverbEncryptedChannel(
        name: channelName,
        sendMessage: sendMessage,
        encryptionMasterKey: encryptionMasterKey,
        authEndpoint: authorizers.authEndpoint,
        authorizer: authorizers.authorizer,
        channelAuthenticator: reverbConfig.channelAuthenticator,
      ),
    );

    final socketId = this.socketId;
    if (socketId != null) {
      channel.subscribe(socketId: socketId);
    }
    return channel;
  }

  ({Authorizer authorizer, String authEndpoint}) _validateAuthorizer(
    String channelName,
  ) {
    final authorizer = reverbConfig.authorizer;
    final authEndpoint = reverbConfig.authEndpoint;
    if (authorizer == null || authEndpoint == null) {
      throw ChannelException.authorizerNotConfigured(channelName);
    }
    return (authorizer: authorizer, authEndpoint: authEndpoint);
  }

  /// Unsubscribes from a channel.
  @override
  void unsubscribeChannel(String channelName) {
    channels.remove(channelName)
      ?..unsubscribe()
      ..dispose();
  }

  /// Gets a channel by name if it exists.
  @override
  ReverbChannel? getChannel(String channelName) {
    return channels[channelName];
  }

  /// Gets all subscribed channels.
  @override
  List<ReverbChannel> get subscribedChannels => channels.values.toList();
}
