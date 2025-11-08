import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../pusher_reverb_flutter.dart';
import '../listeners/reverb_event_listener.dart';
import '../models/reverb_config.dart';
import '../streams/state_stream.dart';
import '../utils/delay_util.dart';
import '../utils/json_util.dart';

part 'reverb_client_channels_impl.dart';
part 'reverb_client_connection_impl.dart';
part 'reverb_client_listeners_impl.dart';
part 'reverb_remote_events_impl.dart';

class ReverbClientImpl extends ReverbClient
    with
        ReverbClientListenersImpl,
        ReverbConnectionImpl,
        ReverbClientListenersImpl,
        ReverbChannelConnectionImpl,
        ReverbRemoteEventsImpl {
  @override
  final ReverbConfig reverbConfig;
  @override
  ReverbClientImpl(this.reverbConfig) {
    remoteEventController.stream.listen((event) {
      handleMessage(reverbConfig, event);
    });
  }
}
