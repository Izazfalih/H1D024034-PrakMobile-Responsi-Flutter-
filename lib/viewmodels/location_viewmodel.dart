import 'package:flutter/foundation.dart';

import '../models/location_model.dart';
import '../services/local_storage_service.dart';
import '../services/weather_api_service.dart';
import 'view_state.dart';

/// ViewModel untuk Search / Location Screen & Favorites (pencarian API + persistensi Hive).
class LocationViewModel extends ChangeNotifier {
  LocationViewModel({
    required this._apiService,
    required this._storageService,
  });

  final WeatherApiService _apiService;
  final LocalStorageService _storageService;

  ViewState _searchState = ViewState.initial;
  String _query = '';
  List<LocationModel> _searchResults = const [];
  List<LocationModel> _favorites = const [];
  List<LocationModel> _searchHistory = const [];
  String? _errorMessage;
  int _activeRequestId = 0;

  ViewState get searchState => _searchState;
  String get query => _query;
  List<LocationModel> get searchResults => _searchResults;
  List<LocationModel> get favorites => _favorites;
  List<LocationModel> get searchHistory => _searchHistory;
  String? get errorMessage => _errorMessage;

  /// Membaca data lokasi favorit dan riwayat pencarian yang tersimpan di Hive.
  void loadSavedData() {
    _favorites = _storageService.getFavorites();
    _searchHistory = _storageService.getSearchHistory();
    notifyListeners();
  }

  /// Mencari lokasi berdasarkan nama kota melalui Open-Meteo Geocoding API.
  Future<void> searchCities(String rawQuery) async {
    final trimmed = rawQuery.trim();
    _query = trimmed;

    if (trimmed.isEmpty) {
      clearSearch();
      return;
    }

    final requestId = ++_activeRequestId;
    _searchState = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _apiService.searchLocations(trimmed);
      if (requestId != _activeRequestId) return;

      _searchResults = results;
      _searchState = results.isEmpty ? ViewState.empty : ViewState.loaded;
    } on WeatherApiException catch (e) {
      if (requestId != _activeRequestId) return;
      _errorMessage = e.message;
      _searchResults = const [];
      _searchState = ViewState.error;
    } catch (_) {
      if (requestId != _activeRequestId) return;
      _errorMessage = 'Gagal mencari lokasi. Coba lagi beberapa saat.';
      _searchResults = const [];
      _searchState = ViewState.error;
    }

    notifyListeners();
  }

  void clearSearch() {
    _activeRequestId++;
    _query = '';
    _searchResults = const [];
    _errorMessage = null;
    _searchState = ViewState.initial;
    notifyListeners();
  }

  bool isFavorite(int locationId) => _storageService.isFavorite(locationId);

  Future<bool> toggleFavorite(LocationModel location) async {
    final isNowFavorite = await _storageService.toggleFavorite(location);
    _favorites = _storageService.getFavorites();
    notifyListeners();
    return isNowFavorite;
  }

  Future<void> removeFavorite(int locationId) async {
    await _storageService.removeFavorite(locationId);
    _favorites = _storageService.getFavorites();
    notifyListeners();
  }

  Future<void> recordHistory(LocationModel location) async {
    await _storageService.addSearchHistory(location);
    _searchHistory = _storageService.getSearchHistory();
    notifyListeners();
  }

  Future<void> removeHistoryItem(int locationId) async {
    await _storageService.removeHistoryItem(locationId);
    _searchHistory = _storageService.getSearchHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _storageService.clearSearchHistory();
    _searchHistory = const [];
    notifyListeners();
  }
}
