import 'package:web_socket_channel/web_socket_channel.dart';

typedef WebSocketFactory =
    WebSocketChannel Function(Uri url, {Map<String, dynamic>? headers});
