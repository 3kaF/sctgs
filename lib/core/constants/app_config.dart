/// Konfigurasi lingkungan aplikasi (dev / prod) serta konstanta batas MVP.
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
    required this.maxPhotosPerScan,
    required this.maxImageDimensionPx,
    required this.defaultSessionCardCount,
    required this.lowConfidenceThreshold,
  });

  final String flavor;
  final String appName;
  final String apiBaseUrl;
  final int maxPhotosPerScan;
  final int maxImageDimensionPx;
  final int defaultSessionCardCount;
  final double lowConfidenceThreshold;

  static const dev = AppConfig(
    flavor: 'dev',
    appName: 'TugasScroll (Dev)',
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://dev-project.supabase.co/functions/v1',
    ),
    maxPhotosPerScan: 10,
    maxImageDimensionPx: 1600,
    defaultSessionCardCount: 20,
    lowConfidenceThreshold: 0.6,
  );

  static const prod = AppConfig(
    flavor: 'prod',
    appName: 'TugasScroll',
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://prod-project.supabase.co/functions/v1',
    ),
    maxPhotosPerScan: 10,
    maxImageDimensionPx: 1600,
    defaultSessionCardCount: 20,
    lowConfidenceThreshold: 0.6,
  );
}
