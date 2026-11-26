import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../models/location_model.dart';
import '../models/weather_model.dart';

/// Exception khusus ketika permintaan ke REST API Open-Meteo gagal atau respons tidak valid.
class WeatherApiException implements Exception {
  const WeatherApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Service jaringan untuk melakukan HTTP GET ke Weather Forecast API dan Geocoding API Open-Meteo.
class WeatherApiService {
  WeatherApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Mengambil data cuaca terkini (`current`) dan prakiraan harian (`daily`) menggunakan HTTP GET.
  Future<WeatherResponse> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      ApiConstants.weatherBaseUrl,
      ApiConstants.weatherForecastPath,
      {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': ApiConstants.currentFields,
        'daily': ApiConstants.dailyFields,
        'timezone': ApiConstants.defaultTimezone,
        'forecast_days': ApiConstants.defaultForecastDays.toString(),
      },
    );

    final decoded = await _getJson(uri);

    if (decoded['error'] == true) {
      final reason = decoded['reason']?.toString() ?? 'Permintaan cuaca ditolak server.';
      throw WeatherApiException(reason);
    }

    try {
      return WeatherResponse.fromJson(decoded);
    } on FormatException catch (e) {
      throw WeatherApiException(e.message);
    }
  }

  /// Mencari daftar kota berdasarkan nama menggunakan Open-Meteo Geocoding API (HTTP GET).
  Future<List<LocationModel>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final uri = Uri.https(
      ApiConstants.geocodingBaseUrl,
      ApiConstants.geocodingSearchPath,
      {
        'name': trimmed,
        'count': ApiConstants.geocodingResultLimit.toString(),
        'language': 'id',
        'format': 'json',
      },
    );

    final decoded = await _getJson(uri);

    if (decoded['error'] == true) {
      final reason = decoded['reason']?.toString() ?? 'Pencarian lokasi gagal.';
      throw WeatherApiException(reason);
    }

    final rawResults = decoded['results'];
    if (rawResults is! List) {
      return const [];
    }

    return rawResults
        .whereType<Map<String, dynamic>>()
        .map(LocationModel.fromGeocodingJson)
        .toList();
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(ApiConstants.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw WeatherApiException(
          'Server mengembalikan status ${response.statusCode}. Silakan coba lagi.',
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const WeatherApiException('Format JSON dari server tidak sesuai.');
      }
      return decoded;
    } on TimeoutException {
      throw const WeatherApiException(
        'Koneksi timeout. Periksa koneksi internet Anda lalu coba lagi.',
      );
    } on http.ClientException {
      throw const WeatherApiException(
        'Tidak dapat terhubung ke server Open-Meteo. Pastikan perangkat terhubung ke internet.',
      );
    } on FormatException {
      throw const WeatherApiException('Respons data dari server tidak dapat dibaca.');
    }
  }

  void dispose() {
    _client.close();
  }
}
