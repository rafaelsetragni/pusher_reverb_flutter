import 'dart:async';

/// A function that provides authentication headers for private channel access.
///
/// This function is called when subscribing to a private channel to obtain
/// the necessary authentication headers for the authorization request.
///
/// [channelName] The name of the private channel being subscribed to.
/// [socketId] The socket ID assigned by the server upon connection.
///
/// Returns a Future that completes with a Map of authentication headers.
/// The headers should include any necessary tokens or credentials for
/// authenticating the private channel subscription.
typedef Authorizer =
    Future<Map<String, String>> Function(String channelName, String socketId);
