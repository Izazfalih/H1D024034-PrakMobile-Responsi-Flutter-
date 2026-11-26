import '../../models/location_model.dart';

/// Konstanta endpoint Open-Meteo, parameter kueri, dan konfigurasi penyimpanan lokal.
class ApiConstants {
  ApiConstants._();

  static const String weatherBaseUrl = 'api.open-meteo.com';
  static const String weatherForecastPath = '/v1/forecast';

  static const String geocodingBaseUrl = 'geocoding-api.open-meteo.com';
  static const String geocodingSearchPath = '/v1/search';

  static const String currentFields =
      'temperature_2m,relative_humidity_2m,apparent_temperature,'
      'precipitation,weather_code,wind_speed_10m,is_day';

  static const String dailyFields =
      'weather_code,temperature_2m_max,temperature_2m_min,'
      'precipitation_probability_max';

  static const String defaultTimezone = 'auto';
  static const int defaultForecastDays = 7;
  static const int geocodingResultLimit = 12;
  static const Duration requestTimeout = Duration(seconds: 15);

  // Nama box Hive
  static const String favoritesBoxName = 'favorites_box';
  static const String historyBoxName = 'history_box';
  static const String settingsBoxName = 'settings_box';

  static const String selectedLocationKey = 'selected_location';
  static const String darkModeKey = 'is_dark_mode';

  static const int maxHistoryItems = 10;

  /// Lokasi awal ketika aplikasi pertama kali dibuka dan belum ada lokasi tersimpan.
  /// Data cuacanya tetap diambil secara langsung melalui REST API Open-Meteo.
  static final LocationModel defaultLocation = LocationModel(
    id: 1642911,
    name: 'Jakarta',
    country: 'Indonesia',
    admin1: 'Jakarta',
    latitude: -6.21462,
    longitude: 106.84513,
    timezone: 'Asia/Jakarta',
  );
}
