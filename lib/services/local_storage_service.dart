import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/api_constants.dart';
import '../models/location_adapter.dart';
import '../models/location_model.dart';

/// Service penyimpanan lokal berbasis Hive untuk lokasi favorit, riwayat pencarian, dan preferensi aplikasi.
class LocalStorageService {
  LocalStorageService({
    required this._favoritesBox,
    required this._historyBox,
    required this._settingsBox,
  });

  final Box<LocationModel> _favoritesBox;
  final Box<LocationModel> _historyBox;
  final Box<dynamic> _settingsBox;

  /// Menginisialisasi Hive Flutter, mendaftarkan [LocationAdapter], dan membuka seluruh box.
  static Future<LocalStorageService> init() async {
    await Hive.initFlutter();
    registerAdapters();

    final favoritesBox = await Hive.openBox<LocationModel>(
      ApiConstants.favoritesBoxName,
    );
    final historyBox = await Hive.openBox<LocationModel>(
      ApiConstants.historyBoxName,
    );
    final settingsBox = await Hive.openBox<dynamic>(
      ApiConstants.settingsBoxName,
    );

    return LocalStorageService(
      favoritesBox: favoritesBox,
      historyBox: historyBox,
      settingsBox: settingsBox,
    );
  }

  /// Mendaftarkan adapter Hive secara idempoten (aman dipanggil di app maupun unit test).
  static void registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LocationAdapter());
    }
  }

  // --- Lokasi Favorit ---

  List<LocationModel> getFavorites() {
    final items = _favoritesBox.values.toList();
    items.sort((a, b) {
      final timeA = a.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final timeB = b.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return timeB.compareTo(timeA);
    });
    return items;
  }

  bool isFavorite(int locationId) {
    return _favoritesBox.containsKey(locationId.toString());
  }

  Future<bool> toggleFavorite(LocationModel location) async {
    final key = location.id.toString();
    if (_favoritesBox.containsKey(key)) {
      await _favoritesBox.delete(key);
      return false;
    } else {
      await _favoritesBox.put(
        key,
        location.copyWith(savedAt: DateTime.now()),
      );
      return true;
    }
  }

  Future<void> removeFavorite(int locationId) async {
    await _favoritesBox.delete(locationId.toString());
  }

  // --- Riwayat Pencarian ---

  List<LocationModel> getSearchHistory() {
    final items = _historyBox.values.toList();
    items.sort((a, b) {
      final timeA = a.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final timeB = b.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return timeB.compareTo(timeA);
    });
    return items;
  }

  Future<void> addSearchHistory(LocationModel location) async {
    final key = location.id.toString();
    await _historyBox.put(
      key,
      location.copyWith(savedAt: DateTime.now()),
    );

    final sorted = getSearchHistory();
    if (sorted.length > ApiConstants.maxHistoryItems) {
      for (final old in sorted.skip(ApiConstants.maxHistoryItems)) {
        await _historyBox.delete(old.id.toString());
      }
    }
  }

  Future<void> removeHistoryItem(int locationId) async {
    await _historyBox.delete(locationId.toString());
  }

  Future<void> clearSearchHistory() async {
    await _historyBox.clear();
  }

  // --- Lokasi Terakhir & Tema ---

  LocationModel? getSelectedLocation() {
    final stored = _settingsBox.get(ApiConstants.selectedLocationKey);
    return stored is LocationModel ? stored : null;
  }

  Future<void> saveSelectedLocation(LocationModel location) async {
    await _settingsBox.put(ApiConstants.selectedLocationKey, location);
  }

  Future<void> clearSelectedLocation() async {
    await _settingsBox.delete(ApiConstants.selectedLocationKey);
  }

  bool getDarkMode() {
    final stored = _settingsBox.get(ApiConstants.darkModeKey);
    return stored is bool ? stored : false;
  }

  Future<void> saveDarkMode(bool value) async {
    await _settingsBox.put(ApiConstants.darkModeKey, value);
  }
}
