class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://unrife-sinless-latesha.ngrok-free.dev/api',
  );
}
