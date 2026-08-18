class AppEnvironment {
  const AppEnvironment({required this.apiBaseUrl});

  static const current = AppEnvironment(
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.urbantrack.io',
    ),
  );

  final String apiBaseUrl;
}
