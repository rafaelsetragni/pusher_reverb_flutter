/// Configuration for a cluster.
///
/// This class defines the configuration parameters for a specific cluster,
/// including host, port, TLS settings, and optional additional headers.
///
/// Example:
/// ```dart
/// const config = ClusterConfig(
///   host: 'reverb-us-east-1.pusher.com',
///   port: 443,
///   useTLS: true,
///   region: 'us-east-1',
/// );
/// ```
class ClusterConfig {
  /// The host address for this cluster.
  final String host;

  /// The port number for this cluster.
  final int port;

  /// Whether to use TLS/SSL for secure connections.
  final bool useTLS;

  /// The region identifier for this cluster (optional).
  final String? region;

  /// Additional headers to include in requests (optional).
  final Map<String, String>? additionalHeaders;

  /// Creates a new ClusterConfig.
  const ClusterConfig({
    required this.host,
    required this.port,
    required this.useTLS,
    this.region,
    this.additionalHeaders,
  });

  static final _clusters = <String, ClusterConfig>{
    'us-east-1': ClusterConfig(
      host: 'reverb-us-east-1.pusher.com',
      port: 443,
      useTLS: true,
      region: 'us-east-1',
    ),
    'us-west-2': ClusterConfig(
      host: 'reverb-us-west-2.pusher.com',
      port: 443,
      useTLS: true,
      region: 'us-west-2',
    ),
    'eu-west-1': ClusterConfig(
      host: 'reverb-eu-west-1.pusher.com',
      port: 443,
      useTLS: true,
      region: 'eu-west-1',
    ),
    'ap-southeast-1': ClusterConfig(
      host: 'reverb-ap-southeast-1.pusher.com',
      port: 443,
      useTLS: true,
      region: 'ap-southeast-1',
    ),
    'local': ClusterConfig(
      host: 'localhost',
      port: 8080,
      useTLS: false,
      region: 'local',
    ),
    'staging': ClusterConfig(
      host: 'staging-reverb.pusher.com',
      port: 443,
      useTLS: true,
      region: 'staging',
    ),
  };

  static Iterable<String> get availableClusters => _clusters.keys;

  /// Factory that resolves a cluster configuration from a region name.
  static ClusterConfig? fromRegion(String? region) {
    if (region == null) return null;
    return _clusters[region];
  }

  @override
  String toString() {
    return 'ClusterConfig(host: $host, port: $port, useTLS: $useTLS, region: $region)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClusterConfig &&
        other.host == host &&
        other.port == port &&
        other.useTLS == useTLS &&
        other.region == region;
  }

  @override
  int get hashCode {
    return Object.hash(host, port, useTLS, region);
  }
}
