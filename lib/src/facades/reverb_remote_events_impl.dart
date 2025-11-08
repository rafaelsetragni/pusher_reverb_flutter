part of 'reverb_client_impl.dart';

mixin ReverbRemoteEventsImpl
    on
        ReverbClient,
        ReverbClientListenersImpl,
        ReverbConnectionImpl,
        ReverbChannelConnectionImpl {
  @override
  void sendMessage(dynamic message) {
    final webSocketChannel = this.webSocketChannel;
    if (webSocketChannel == null) throw ConnectionException.notConnected();
    webSocketChannel.sink.add(message);
  }

  void handleMessage(ReverbConfig reverbConfig, dynamic message) {
    emitOnLog('ReverbClient', 0, 'Message received: $message');
    final decodedMessage = JsonUtil.decode(message as String);
    final event = decodedMessage['event'] as String?;
    final data = decodedMessage['data'];

    if (event == null) {
      emitOnLog('ReverbClient', 900, 'Received message without event type');
      return;
    }

    switch (event) {
      case 'pusher:ping':
        handlePingRequest(reverbConfig, data);
        break;
      case 'pusher:connection_established':
        handleConnectionEstablished(reverbConfig, data);
        break;
      case 'pusher_internal:subscription_succeeded':
        handleSubscriptionSucceeded(reverbConfig, data);
        break;
      case 'pusher_internal:unsubscription_succeeded':
        handleUnsubscriptionSucceeded(reverbConfig, data);
        break;
      default:
        handleRemoteChannelEvent(reverbConfig, decodedMessage);
        break;
    }
  }

  void handlePingRequest(ReverbConfig reverbConfig, dynamic data) {
    emitOnLog('ReverbClient', 0, 'Received ping from server, sending pong...');
    final pongMessage = JsonUtil.encode({'event': 'pusher:pong'});
    sendMessage(pongMessage);
    emitOnLog('ReverbClient', 0, 'Pong sent to server.');
  }

  void handleConnectionEstablished(ReverbConfig reverbConfig, dynamic data) {
    final connectionData = JsonUtil.decode(data as String);
    socketId = connectionData['socket_id'] as String?;
    emitOnLog('ReverbClient', 0, 'Server assigned socket ID: $socketId');
    reconnectionsAttempted = 0;
    emitConnectionState(ReverbConnectionState.connected);
    startPingTimer(reverbConfig.pingInterval);
    emitOnLog(
      'ReverbClient',
      0,
      'Connection established with socket ID: $socketId',
    );
    emitOnConnected();

    if (!(connectionCompleter?.isCompleted ?? true)) {
      connectionCompleter!.complete();
    }
  }

  void handleSubscriptionSucceeded(ReverbConfig reverbConfig, dynamic data) {
    final channelData = JsonUtil.decode(data as String);
    final channelName = channelData['channel'] as String?;
    if (channelName == null) return;

    final channel = channels[channelName];
    if (channel is ReverbPresenceChannel) {
      channel.handleSubscriptionSucceeded(channelData);
    } else {
      channel?.handleSubscriptionSucceeded();
    }
  }

  void handleUnsubscriptionSucceeded(ReverbConfig reverbConfig, dynamic data) {
    final channelData = JsonUtil.decode(data as String);
    final channelName = channelData['channel'] as String?;
    if (channelName == null) return;

    final channel = channels[channelName];
    channel?.handleUnsubscriptionSucceeded();
  }

  void handleRemoteChannelEvent(
    ReverbConfig reverbConfig,
    Map<String, dynamic> decodedMessage,
  ) {
    final channelName = decodedMessage['channel'] as String?;
    if (channelName == null) return;

    final channel = channels[channelName];
    final event = decodedMessage['event'];
    final data = decodedMessage['data'];
    channel?.handleEvent(event, data);
  }
}
