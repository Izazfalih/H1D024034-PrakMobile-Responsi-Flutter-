import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/location_model.dart';
import '../../viewmodels/location_viewmodel.dart';
import '../../viewmodels/view_state.dart';
import '../../viewmodels/weather_viewmodel.dart';
import '../widgets/location_tile.dart';
import '../widgets/state_feedback_widget.dart';

/// Screen 2 (Wajib): Search / Location Screen.
/// Menggunakan StatefulWidget untuk mengelola input teks, FocusNode, dan timer debounce pencarian API.
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.onLocationSelected,
  });

  final VoidCallback onLocationSelected;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const List<String> _popularQueries = [
    'Jakarta',
    'Bandung',
    'Yogyakarta',
    'Surabaya',
    'Denpasar',
    'Singapore',
    'Tokyo',
    'London',
  ];

  late final TextEditingController _searchController;
  late final FocusNode _focusNode;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    setState(() {});

    if (value.trim().isEmpty) {
      context.read<LocationViewModel>().clearSearch();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      context.read<LocationViewModel>().searchCities(value);
    });
  }

  void _submitSearch(String value) {
    _debounce?.cancel();
    context.read<LocationViewModel>().searchCities(value);
  }

  void _clearInput() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {});
    context.read<LocationViewModel>().clearSearch();
  }

  void _searchFromSuggestion(String cityName) {
    _debounce?.cancel();
    _searchController.text = cityName;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: cityName.length),
    );
    setState(() {});
    context.read<LocationViewModel>().searchCities(cityName);
  }

  Future<void> _selectLocation(LocationModel location) async {
    _focusNode.unfocus();
    final locationVm = context.read<LocationViewModel>();
    final weatherVm = context.read<WeatherViewModel>();

    await locationVm.recordHistory(location);
    await weatherVm.selectLocation(location);

    if (mounted) {
      widget.onLocationSelected();
    }
  }

  Future<void> _toggleFavorite(LocationModel location) async {
    final added = await context.read<LocationViewModel>().toggleFavorite(location);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            added
                ? '${location.name} ditambahkan ke lokasi favorit.'
                : '${location.name} dihapus dari lokasi favorit.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationVm = context.watch<LocationViewModel>();
    final selectedId = context.watch<WeatherViewModel>().selectedLocation?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Lokasi'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      onChanged: _onQueryChanged,
                      onSubmitted: _submitSearch,
                      decoration: InputDecoration(
                        hintText: 'Ketik nama kota, mis. Bandung atau Tokyo...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: _clearInput,
                                tooltip: 'Bersihkan pencarian',
                                icon: const Icon(Icons.close_rounded),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _popularQueries.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final city = _popularQueries[index];
                          return ActionChip(
                            label: Text(city),
                            avatar: const Icon(Icons.bolt_rounded, size: 16),
                            onPressed: () => _searchFromSuggestion(city),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildContent(
                  context,
                  theme,
                  locationVm,
                  selectedId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    LocationViewModel locationVm,
    int? selectedId,
  ) {
    switch (locationVm.searchState) {
      case ViewState.loading:
        return StateFeedbackWidget.loading(
          message: 'Mencari "${locationVm.query}" melalui Open-Meteo...',
        );
      case ViewState.error:
        return StateFeedbackWidget.error(
          message: locationVm.errorMessage ?? 'Pencarian kota gagal.',
          onRetry: () => locationVm.searchCities(_searchController.text),
        );
      case ViewState.empty:
        return StateFeedbackWidget.empty(
          icon: Icons.search_off_rounded,
          title: 'Kota Tidak Ditemukan',
          message:
              'Tidak ada hasil lokasi untuk "${locationVm.query}". Coba ejaan lain atau nama kota yang lebih umum.',
          actionLabel: 'Reset Pencarian',
          onAction: _clearInput,
        );
      case ViewState.loaded:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: locationVm.searchResults.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'Ditemukan ${locationVm.searchResults.length} lokasi untuk "${locationVm.query}"',
                  style: theme.textTheme.labelMedium,
                ),
              );
            }
            final city = locationVm.searchResults[index - 1];
            return LocationTile(
              location: city,
              isFavorite: locationVm.isFavorite(city.id),
              isSelected: city.id == selectedId,
              onTap: () => _selectLocation(city),
              onToggleFavorite: () => _toggleFavorite(city),
            );
          },
        );
      case ViewState.initial:
        final history = locationVm.searchHistory;
        final favorites = locationVm.favorites;

        if (history.isEmpty && favorites.isEmpty) {
          return StateFeedbackWidget.empty(
            icon: Icons.manage_search_rounded,
            title: 'Temukan Cuaca Kota Mana Saja',
            message:
                'Masukkan nama kota di kolom pencarian di atas untuk melihat koordinat, menyimpan favorit, dan memantau cuacanya.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            if (history.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Pencarian',
                    style: theme.textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: locationVm.clearHistory,
                    child: const Text('Hapus Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...history.map(
                (city) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LocationTile(
                    location: city,
                    leadingIcon: Icons.history_rounded,
                    isFavorite: locationVm.isFavorite(city.id),
                    isSelected: city.id == selectedId,
                    onTap: () => _selectLocation(city),
                    onToggleFavorite: () => _toggleFavorite(city),
                    onDelete: () => locationVm.removeHistoryItem(city.id),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (favorites.isNotEmpty) ...[
              Text(
                'Lokasi Favorit Tersimpan',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              ...favorites.map(
                (city) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LocationTile(
                    location: city,
                    leadingIcon: Icons.star_rounded,
                    isFavorite: true,
                    isSelected: city.id == selectedId,
                    onTap: () => _selectLocation(city),
                    onToggleFavorite: () => _toggleFavorite(city),
                  ),
                ),
              ),
            ],
          ],
        );
    }
  }
}
