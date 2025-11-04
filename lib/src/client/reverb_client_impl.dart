import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:pusher_reverb_flutter/src/streams/state_stream.dart';
import 'package:pusher_reverb_flutter/src/validations/channel_validation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../pusher_reverb_flutter.dart';
import '../listeners/reverb_event_listener.dart';
import '../models/reverb_config.dart';

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
  static ReverbClient reverbInstance = ReverbClientImpl();

  @override
  List<String> get availableClusters =>
      ClusterConfig.availableClusters.toList();

  static ClusterConfig? getClusterConfig(String cluster) =>
      ClusterConfig.fromRegion(cluster);

  @override
  void setConfiguration(ReverbConfig config) {
    reverbConfig = config;
  }
}
