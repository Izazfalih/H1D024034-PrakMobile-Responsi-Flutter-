import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weather_app/core/constants/api_constants.dart';
import 'package:weather_app/models/location_model.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/services/local_storage_service.dart';
import 'package:weather_app/services/weather_api_service.dart';
import 'package:weather_app/viewmodels/location_viewmodel.dart';
import 'package:weather_app/viewmodels/view_state.dart';
import 'package:weather_app/viewmodels/weather_viewmodel.dart';

Map<String, dynamic> _sampleForecastPayload() => {
      'latitude': -6.22,
      'longitude': 106.85,
      'timezone': 'Asia/Jakarta',
      'timezone_abbreviation': 'GMT+7',
      'current': {
        'time': '2026-11-25T21:45',
        'temperature_2m': 27.4,
        'relative_humidity_2m': 88,
        'apparent_temperature': 31.8,
        'precipitation': 0.2,
        'weather_code': 61,
        'wind_speed_10m': 7.5,
        'is_day': 0,
      },
      'daily': {
        'time': [
          '2026-11-25',
          '2026-11-26',
          '2026-11-27',
        ],
        'weather_code': [61, 80, 2],
        'temperature_2m_max': [32.1, 30.8, 31.5],
        'temperature_2m_min': [24.6, 24.1, 24.4],
        'precipitation_probability_max': [85, 90, null],
      },
    };

Map<String, dynamic> _sampleGeocodingPayload() => {
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
      'generationtime_ms': 0.4,
    };

void main() {
  group('Model JSON Parsing', () {
    test('WeatherResponse.fromJson parses current and daily fields accurately',
        () {
      final response = WeatherResponse.fromJson(_sampleForecastPayload());

      expect(response.timezone, 'Asia/Jakarta');
      expect(response.timezoneAbbreviation, 'GMT+7');
      expect(response.current.temperature2m, 27.4);
      expect(response.current.relativeHumidity2m, 88);
      expect(response.current.apparentTemperature, 31.8);
      expect(response.current.precipitation, 0.2);
      expect(response.current.weatherCode, 61);
      expect(response.current.windSpeed10m, 7.5);
      expect(response.current.isDay, false);

      expect(response.daily, hasLength(3));
      expect(response.daily[0].temperature2mMax, 32.1);
      expect(response.daily[0].temperature2mMin, 24.6);
      expect(response.daily[0].precipitationProbabilityMax, 85);
      // Nullable precipitation probability falls back cleanly to 0
      expect(response.daily[2].precipitationProbabilityMax, 0);
    });

    test('LocationModel.fromGeocodingJson builds subtitle properly', () {
      final results = (_sampleGeocodingPayload()['results'] as List)
          .cast<Map<String, dynamic>>();
      final city = LocationModel.fromGeocodingJson(results.first);

      expect(city.id, 1650357);
      expect(city.name, 'Bandung');
      expect(city.subtitle, 'Jawa Barat, Indonesia');
    });
  });

  group('WeatherApiService (HTTP GET)', () {
    test('fetchWeather sends expected GET query parameters and parses data',
        () async {
      Uri? capturedUri;
      String? capturedMethod;
      final client = MockClient((request) async {
        capturedUri = request.url;
        capturedMethod = request.method;
        return http.Response(jsonEncode(_sampleForecastPayload()), 200);
      });

      final service = WeatherApiService(client: client);
      final weather = await service.fetchWeather(
        latitude: -6.21,
        longitude: 106.84,
      );

      expect(capturedMethod, 'GET');
      expect(capturedUri?.host, ApiConstants.weatherBaseUrl);
      expect(capturedUri?.queryParameters['timezone'], 'auto');
      expect(
        capturedUri?.queryParameters['current'],
        contains('temperature_2m'),
      );
      expect(
        capturedUri?.queryParameters['daily'],
        contains('precipitation_probability_max'),
      );
      expect(weather.current.weatherCode, 61);
    });

    test('searchLocations returns empty list when API omits results key',
        () async {
      final client = MockClient(
        (_) async => http.Response('{"generationtime_ms": 0.1}', 200),
      );
      final service = WeatherApiService(client: client);

      final results = await service.searchLocations('KotaFiktifXYZ');
      expect(results, isEmpty);
    });

    test('fetchWeather throws WeatherApiException on non-200 status', () async {
      final client = MockClient((_) async => http.Response('Server Error', 500));
      final service = WeatherApiService(client: client);

      expect(
        () => service.fetchWeather(latitude: 0, longitude: 0),
        throwsA(isA<WeatherApiException>()),
      );
    });
  });

  group('LocalStorageService (Hive Persistence)', () {
    late Directory tempDir;
    late LocalStorageService storage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('weather_hive_test_');
      Hive.init(tempDir.path);
      LocalStorageService.registerAdapters();

      final favBox = await Hive.openBox<LocationModel>('test_favorites');
      final histBox = await Hive.openBox<LocationModel>('test_history');
      final settingsBox = await Hive.openBox<dynamic>('test_settings');

      storage = LocalStorageService(
        favoritesBox: favBox,
        historyBox: histBox,
        settingsBox: settingsBox,
      );
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('persists favorites, history, selected location, and dark mode across reopen',
        () async {
      const bandung = LocationModel(
        id: 1650357,
        name: 'Bandung',
        country: 'Indonesia',
        admin1: 'Jawa Barat',
        latitude: -6.92222,
        longitude: 107.60694,
        timezone: 'Asia/Jakarta',
      );

      final added = await storage.toggleFavorite(bandung);
      expect(added, isTrue);
      expect(storage.isFavorite(bandung.id), isTrue);

      await storage.addSearchHistory(bandung);
      await storage.saveSelectedLocation(bandung);
      await storage.saveDarkMode(true);

      // Tutup dan buka kembali semua box Hive untuk menguji persistensi
      await Hive.close();
      Hive.init(tempDir.path);
      LocalStorageService.registerAdapters();

      final reopenedStorage = LocalStorageService(
        favoritesBox: await Hive.openBox<LocationModel>('test_favorites'),
        historyBox: await Hive.openBox<LocationModel>('test_history'),
        settingsBox: await Hive.openBox<dynamic>('test_settings'),
      );

      expect(reopenedStorage.getFavorites().first.name, 'Bandung');
      expect(reopenedStorage.getSearchHistory().first.name, 'Bandung');
      expect(reopenedStorage.getSelectedLocation()?.name, 'Bandung');
      expect(reopenedStorage.getDarkMode(), isTrue);
    });
  });

  group('ViewModels (WeatherViewModel & LocationViewModel)', () {
    late Directory tempDir;
    late LocalStorageService storage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('weather_vm_test_');
      Hive.init(tempDir.path);
      LocalStorageService.registerAdapters();

      storage = LocalStorageService(
        favoritesBox: await Hive.openBox<LocationModel>('vm_fav'),
        historyBox: await Hive.openBox<LocationModel>('vm_hist'),
        settingsBox: await Hive.openBox<dynamic>('vm_set'),
      );
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('WeatherViewModel transitions to loaded and handles error/empty states',
        () async {
      var failNext = false;
      final client = MockClient((_) async {
        if (failNext) {
          return http.Response('Bad Gateway', 502);
        }
        return http.Response(jsonEncode(_sampleForecastPayload()), 200);
      });

      final vm = WeatherViewModel(
        apiService: WeatherApiService(client: client),
        storageService: storage,
      );

      await vm.initialize();
      expect(vm.state, ViewState.loaded);
      expect(vm.selectedLocation?.name, 'Jakarta');
      expect(vm.weather?.current.temperature2m, 27.4);

      failNext = true;
      await vm.refresh();
      expect(vm.state, ViewState.error);
      expect(vm.errorMessage, isNotNull);

      await vm.clearLocation();
      expect(vm.state, ViewState.empty);
      expect(vm.selectedLocation, isNull);
    });

    test('LocationViewModel searches cities and updates favorites', () async {
      final client = MockClient((request) async {
        final q = request.url.queryParameters['name'];
        if (q == 'Bandung') {
          return http.Response(jsonEncode(_sampleGeocodingPayload()), 200);
        }
        return http.Response('{"generationtime_ms": 0.1}', 200);
      });

      final vm = LocationViewModel(
        apiService: WeatherApiService(client: client),
        storageService: storage,
      );

      await vm.searchCities('Bandung');
      expect(vm.searchState, ViewState.loaded);
      expect(vm.searchResults, hasLength(1));

      final bandung = vm.searchResults.first;
      await vm.toggleFavorite(bandung);
      expect(vm.isFavorite(bandung.id), isTrue);
      expect(vm.favorites, hasLength(1));

      await vm.searchCities('UnknownCity');
      expect(vm.searchState, ViewState.empty);
    });
  });
}
