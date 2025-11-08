part of 'reverb_service.dart';

abstract class ReverbChannelService {
  static ReverbChannelService? _instance;
  factory ReverbChannelService() => _instance ??= ReverbPublicServiceImpl._();

  Future<WebsocketPublicChannel> registerPublicChannel(String channelName);

  Future<WebsocketPrivateChannel> registerPrivateChannel(String channelName);

  Future<WebsocketPrivateChannel> registerPresenceChannel(String channelName);

  Future<WebsocketPrivateChannel> registerEncryptedChannel(String channelName);

  Future<void> unsubscribe(String channelName);
  Future<void> unsubscribeAll();
}

class ReverbPublicServiceImpl implements ReverbChannelService {
  ReverbPublicServiceImpl._();
  final reverbService = ReverbServiceImpl.instance;

  final Map<String, WebsocketPublicChannel> _channels = {};

  @override
  Future<WebsocketPublicChannel> registerPublicChannel(
    String channelName, [
    String? eventName,
  ]) async {
    try {
      final oldChannel = _channels[channelName];
      if (oldChannel != null) oldChannel.stream;

      final client = reverbService._connection.client;
      if (client == null) throw NotConnectedException();

      final ch = _channels[channelName] = client.subscribePublicChannel(
        channelName,
      );

      return ch;
    } on rb.InvalidChannelNameException catch (_) {
      throw InvalidChannelNameException();
    } on rb.ChannelException catch (_) {
      throw ChannelException();
    }
  }

  @override
  Future<void> unsubscribe(String channelName) async {
    final ch = _channels[channelName];
    if (ch == null) return;
    await ch.unsubscribe();
    _channels.remove(channelName);
  }

  @override
  Future<void> unsubscribeAll() async {
    final channels = Map<String, WebsocketChannel>.from(_channels);
    for (final entry in channels.entries) {
      try {
        await entry.value.unsubscribe();
        _channels.remove(entry.key);
      } catch (_) {
        // ignore or log internally
      }
    }
  }

  @override
  Future<WebsocketPrivateChannel> registerEncryptedChannel(String channelName) {
    // TODO: implement registerEncryptedChannel
    throw UnimplementedError();
  }

  @override
  Future<WebsocketPrivateChannel> registerPresenceChannel(String channelName) {
    // TODO: implement registerPresenceChannel
    throw UnimplementedError();
  }

  @override
  Future<WebsocketPrivateChannel> registerPrivateChannel(String channelName) {
    // TODO: implement registerPrivateChannel
    throw UnimplementedError();
  }
}
