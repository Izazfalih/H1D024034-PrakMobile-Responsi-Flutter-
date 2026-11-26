import 'package:flutter/foundation.dart';

import '../core/constants/api_constants.dart';
import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../services/local_storage_service.dart';
import '../services/weather_api_service.dart';
import 'view_state.dart';

/// ViewModel untuk Home / Weather Screen (mengelola state cuaca, lokasi terpilih, dan tema).
class WeatherViewModel extends ChangeNotifier {
  WeatherViewModel({
    required this._apiService,
    required this._storageService,
  });

  final WeatherApiService _apiService;
  final LocalStorageService _storageService;

  ViewState _state = ViewState.initial;
  LocationModel? _selectedLocation;
  WeatherResponse? _weather;
  String? _errorMessage;
  DateTime? _lastUpdated;
  bool _isDarkMode = false;

  ViewState get state => _state;
  LocationModel? get selectedLocation => _selectedLocation;
  WeatherResponse? get weather => _weather;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isDarkMode => _isDarkMode;

  /// Memuat preferensi dan lokasi terakhir dari Hive, lalu mengambil cuaca terkini dari API.
  Future<void> initialize() async {
    _isDarkMode = _storageService.getDarkMode();
    final saved = _storageService.getSelectedLocation();

    if (saved != null) {
      _selectedLocation = saved;
    } else {
      final favorites = _storageService.getFavorites();
      _selectedLocation = favorites.isNotEmpty
          ? favorites.first
          : ApiConstants.defaultLocation;
      await _storageService.saveSelectedLocation(_selectedLocation!);
    }

    await loadWeather();
  }

  /// Memilih kota baru, menyimpannya ke Hive, lalu mengambil informasi cuaca terbarunya.
  Future<void> selectLocation(LocationModel location) async {
    _selectedLocation = location;
    await _storageService.saveSelectedLocation(location);
    await loadWeather();
  }

  /// Mengambil data cuaca terkini & prakiraan harian untuk [_selectedLocation].
  Future<void> loadWeather() async {
    final location = _selectedLocation;
    if (location == null) {
      _weather = null;
      _errorMessage = null;
      _state = ViewState.empty;
      notifyListeners();
      return;
    }

    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.fetchWeather(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      if (response.daily.isEmpty) {
        _weather = null;
        _state = ViewState.empty;
      } else {
        _weather = response;
        _lastUpdated = DateTime.now();
        _state = ViewState.loaded;
      }
    } on WeatherApiException catch (e) {
      _errorMessage = e.message;
      _state = ViewState.error;
    } catch (_) {
      _errorMessage = 'Terjadi kesalahan saat memuat data cuaca.';
      _state = ViewState.error;
    }

    notifyListeners();
  }

  /// Memuat ulang data cuaca (digunakan pada pull-to-refresh dan tombol muat ulang).
  Future<void> refresh() => loadWeather();

  /// Menghapus pilihan lokasi aktif untuk menampilkan kondisi kosong (empty state).
  Future<void> clearLocation() async {
    _selectedLocation = null;
    _weather = null;
    _errorMessage = null;
    _state = ViewState.empty;
    await _storageService.clearSelectedLocation();
    notifyListeners();
  }

  /// Mengubah tema terang/gelap dan menyimpannya ke Hive.
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _storageService.saveDarkMode(_isDarkMode);
    notifyListeners();
  }
}
