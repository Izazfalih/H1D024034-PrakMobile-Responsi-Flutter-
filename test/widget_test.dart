import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weather_app/main.dart';
import 'package:weather_app/models/location_model.dart';
import 'package:weather_app/services/local_storage_service.dart';
import 'package:weather_app/services/weather_api_service.dart';

/// Implementasi penyimpanan lokal in-memory untuk pengujian widget yang deterministik.
class _InMemoryStorageService implements LocalStorageService {
  final Map<int, LocationModel> _favorites = {};
  final Map<int, LocationModel> _history = {};
  LocationModel? _selectedLocation;
  bool _darkMode = false;

  @override
  List<LocationModel> getFavorites() => _favorites.values.toList().reversed.toList();

  @override
  bool isFavorite(int locationId) => _favorites.containsKey(locationId);

  @override
  Future<bool> toggleFavorite(LocationModel location) async {
    if (_favorites.containsKey(location.id)) {
      _favorites.remove(location.id);
      return false;
    }
    _favorites[location.id] = location.copyWith(savedAt: DateTime.now());
    return true;
  }

  @override
  Future<void> removeFavorite(int locationId) async {
    _favorites.remove(locationId);
  }

  @override
  List<LocationModel> getSearchHistory() => _history.values.toList().reversed.toList();

  @override
  Future<void> addSearchHistory(LocationModel location) async {
    _history.remove(location.id);
    _history[location.id] = location.copyWith(savedAt: DateTime.now());
  }

  @override
  Future<void> removeHistoryItem(int locationId) async {
    _history.remove(locationId);
  }

  @override
  Future<void> clearSearchHistory() async {
    _history.clear();
  }

  @override
  LocationModel? getSelectedLocation() => _selectedLocation;

  @override
  Future<void> saveSelectedLocation(LocationModel location) async {
    _selectedLocation = location;
  }

  @override
  Future<void> clearSelectedLocation() async {
    _selectedLocation = null;
  }

  @override
  bool getDarkMode() => _darkMode;

  @override
  Future<void> saveDarkMode(bool value) async {
    _darkMode = value;
  }
}

void main() {
  testWidgets(
      'Home screen loads weather from API, Search finds city, Favorite persists, and Error retries',
      (tester) async {
    final storage = _InMemoryStorageService();
    var shouldFailWeather = false;

    final mockClient = MockClient((request) async {
      if (request.url.host.contains('geocoding')) {
        final query = request.url.queryParameters['name'] ?? '';
        if (query.toLowerCase().contains('bandung')) {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 1650357,
                  'name': 'Bandung',
                  'latitude': -6.92222,
                  'longitude': 107.60694,
                  'country': 'Indonesia',
                  'admin1': 'Jawa Barat',
                  'timezone': 'Asia/Jakarta',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('{"generationtime_ms": 0.1}', 200);
      }

      if (shouldFailWeather) {
        return http.Response('Internal Server Error', 500);
      }

      final lat = request.url.queryParameters['latitude'] ?? '';
      final isBandung = lat.startsWith('-6.92');

      return http.Response(
        jsonEncode({
          'latitude': isBandung ? -6.92 : -6.21,
          'longitude': isBandung ? 107.60 : 106.84,
          'timezone': 'Asia/Jakarta',
          'timezone_abbreviation': 'GMT+7',
          'current': {
            'time': '2026-11-25T21:45',
            'temperature_2m': isBandung ? 22.5 : 28.0,
            'relative_humidity_2m': isBandung ? 82 : 76,
            'apparent_temperature': isBandung ? 24.0 : 31.0,
            'precipitation': isBandung ? 1.2 : 0.0,
            'weather_code': isBandung ? 61 : 1,
            'wind_speed_10m': isBandung ? 8.4 : 5.2,
            'is_day': 1,
          },
          'daily': {
            'time': ['2026-11-25', '2026-11-26'],
            'weather_code': [1, 61],
            'temperature_2m_max': [31.0, 29.0],
            'temperature_2m_min': [24.0, 23.0],
            'precipitation_probability_max': [40, 85],
          },
        }),
        200,
      );
    });

    await tester.pumpWidget(
      SkyCastApp(
        apiService: WeatherApiService(client: mockClient),
        storageService: storage,
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi Home Screen awal (Jakarta dari API mock)
    expect(find.text('Jakarta'), findsWidgets);
    expect(find.text('28.0°C'), findsOneWidget);
    expect(find.text('Cerah Berawan'), findsWidgets);
    expect(find.text('76%'), findsOneWidget);
    expect(find.text('5.2 km/j'), findsOneWidget);
    expect(find.text('WMO 1'), findsWidgets);
    expect(find.text('Prakiraan 2 Hari Ke Depan'), findsOneWidget);

    // Pindah ke Search Screen lewat tab Cari Kota
    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Cari Lokasi'), findsOneWidget);

    // Uji empty state saat kota tidak ditemukan
    await tester.enterText(find.byType(TextField), 'KotaTidakAda');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Kota Tidak Ditemukan'), findsOneWidget);

    // Cari kota Bandung via input teks dan submit
    await tester.enterText(find.byType(TextField), 'Bandung');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Bandung'), findsWidgets);
    expect(find.text('Jawa Barat, Indonesia'), findsOneWidget);

    // Simpan Bandung ke favorit
    await tester.tap(find.byIcon(Icons.favorite_border_rounded).last);
    await tester.pumpAndSettle();
    expect(storage.isFavorite(1650357), isTrue);

    // Pilih kota Bandung untuk menampilkan cuacanya di Home Screen
    await tester.tap(find.text('Jawa Barat, Indonesia'));
    await tester.pumpAndSettle();

    expect(find.text('22.5°C'), findsOneWidget);
    expect(find.text('Hujan Ringan'), findsWidgets);

    // Uji error state & tombol Coba Lagi pada Home Screen
    shouldFailWeather = true;
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Gagal Memuat Data'), findsOneWidget);

    shouldFailWeather = false;
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.text('22.5°C'), findsOneWidget);

    // Selesaikan timer SnackBar agar tidak ada timer tersisa saat teardown
    await tester.pump(const Duration(seconds: 5));
  });
}
