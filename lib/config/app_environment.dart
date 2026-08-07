class AppEnvironment {
  const AppEnvironment({required this.apiBaseUrl});

  static const current = AppEnvironment(
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue:
          'https://salestracking-api.kindriver-61f4971f.brazilsouth.azurecontainerapps.io',
    ),
  );

  final String apiBaseUrl;
}
