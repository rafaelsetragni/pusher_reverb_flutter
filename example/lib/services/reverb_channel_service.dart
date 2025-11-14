part of 'reverb_service.dart';

abstract class ReverbChannelService {
  static ReverbChannelService? _instance;
  factory ReverbChannelService() => _instance ??= ReverbChannelServiceImpl._();

  Future<ReverbPublicChannel> registerPublicChannel(String channelName);

  Future<ReverbPrivateChannel> registerPrivateChannel(String channelName);

  Future<ReverbPresenceChannel> registerPresenceChannel(
    String channelName, {
    Map<String, dynamic>? channelData,
  });

  Future<ReverbEncryptedChannel> registerEncryptedChannel(
    String channelName, {
    required String encryptionMasterKey,
  });

  Future<void> unsubscribe(String channelName);
  Future<void> unsubscribeAll();
}

class ReverbChannelServiceImpl implements ReverbChannelService {
  ReverbChannelServiceImpl._();
  final reverbService = ReverbServiceImpl.instance;

  @override
  Future<ReverbPublicChannel> registerPublicChannel(String channelName) async {
    final client = reverbService._connection.client;
    if (client == null) throw ConnectionException.notConnected();

    return client.subscribePublicChannel(channelName: channelName);
  }

  @override
  Future<ReverbPrivateChannel> registerPrivateChannel(
    String channelName,
  ) async {
    final client = reverbService._connection.client;
    if (client == null) throw ConnectionException.notConnected();

    return client.subscribePrivateChannel(channelName: channelName);
  }

  @override
  Future<ReverbPresenceChannel> registerPresenceChannel(
    String channelName, {
    Map<String, dynamic>? channelData,
  }) async {
    final client = reverbService._connection.client;
    if (client == null) throw ConnectionException.notConnected();

    return client.subscribePresenceChannel(
      channelName: channelName,
      channelData: channelData,
    );
  }

  @override
  Future<ReverbEncryptedChannel> registerEncryptedChannel(
    String channelName, {
    required String encryptionMasterKey,
  }) async {
    final client = reverbService._connection.client;
    if (client == null) throw ConnectionException.notConnected();

    return client.subscribeEncryptedChannel(
      channelName: channelName,
      encryptionMasterKey: encryptionMasterKey,
    );
  }

  @override
  Future<void> unsubscribe(String channelName) async {
    reverbService._connection.client?.unsubscribeChannel(channelName);
  }

  @override
  Future<void> unsubscribeAll() async {
    reverbService._connection.client?.unsubscribeAllChannels();
  }
}
