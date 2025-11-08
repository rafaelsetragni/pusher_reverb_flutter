class ReverbConfig {
  final String host;
  final int port;
  final String appKey;
  final String authEndpoint;
  final String wsPath;
  final String authToken;
  final bool useTLS;
  final String apiKey;
  final String cluster;

  const ReverbConfig({
    required this.host,
    required this.port,
    required this.appKey,
    required this.authEndpoint,
    required this.wsPath,
    required this.authToken,
    required this.useTLS,
    this.apiKey = '',
    this.cluster = '',
  });

  factory ReverbConfig.initial() => const ReverbConfig(
    host: 'localhost',
    port: 8080,
    appKey: 'your-app-key',
    authEndpoint: 'http://localhost:8000/broadcasting/auth',
    wsPath: '/',
    authToken: '',
    useTLS: false,
  );

  factory ReverbConfig.fromJson(Map<String, dynamic> json) => ReverbConfig(
    host: json['host'] ?? 'localhost',
    port: json['port'] ?? 8080,
    appKey: json['appKey'] ?? 'your-app-key',
    authEndpoint:
        json['authEndpoint'] ?? 'http://localhost:8000/broadcasting/auth',
    wsPath: json['wsPath'] ?? '/',
    authToken: json['authToken'] ?? '',
    useTLS: json['useTLS'] ?? false,
    apiKey: json['apiKey'] ?? '',
    cluster: json['cluster'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'host': host,
    'port': port,
    'appKey': appKey,
    'authEndpoint': authEndpoint,
    'wsPath': wsPath,
    'authToken': authToken,
    'useTLS': useTLS,
    'apiKey': apiKey,
    'cluster': cluster,
  };
}
