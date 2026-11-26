import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/location_model.dart';
import '../../viewmodels/location_viewmodel.dart';
import '../../viewmodels/view_state.dart';
import '../../viewmodels/weather_viewmodel.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/daily_forecast_list.dart';
import '../widgets/state_feedback_widget.dart';
import '../widgets/weather_metrics_grid.dart';

/// Screen 1 (Wajib): Home / Weather Screen.
/// Menampilkan cuaca terkini, detail metrik, prakiraan harian, dan pintasan kota favorit.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenSearch,
  });

  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    final weatherVm = context.watch<WeatherViewModel>();
    final locationVm = context.watch<LocationViewModel>();
    final selected = weatherVm.selectedLocation;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(selected?.name ?? 'SkyCast'),
            if (selected != null)
              Text(
                selected.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: onOpenSearch,
            tooltip: 'Cari Kota',
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            onPressed: weatherVm.state == ViewState.loading
                ? null
                : weatherVm.refresh,
            tooltip: 'Muat Ulang Cuaca',
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: weatherVm.toggleTheme,
            tooltip: weatherVm.isDarkMode ? 'Mode Terang' : 'Mode Gelap',
            icon: Icon(
              weatherVm.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(context, weatherVm, locationVm),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WeatherViewModel weatherVm,
    LocationViewModel locationVm,
  ) {
    switch (weatherVm.state) {
      case ViewState.initial:
      case ViewState.loading:
        return StateFeedbackWidget.loading(
          message: weatherVm.selectedLocation != null
              ? 'Mengambil prakiraan cuaca untuk ${weatherVm.selectedLocation!.name}...'
              : 'Menyiapkan data cuaca...',
        );
      case ViewState.error:
        return StateFeedbackWidget.error(
          message:
              weatherVm.errorMessage ?? 'Terjadi kesalahan memuat cuaca.',
          onRetry: weatherVm.refresh,
        );
      case ViewState.empty:
        return StateFeedbackWidget.empty(
          icon: Icons.travel_explore_rounded,
          title: 'Belum Ada Lokasi Dipilih',
          message:
              'Cari dan pilih kota terlebih dahulu untuk melihat informasi cuaca terkini dari Open-Meteo.',
          actionLabel: 'Cari Kota',
          onAction: onOpenSearch,
        );
      case ViewState.loaded:
        final weather = weatherVm.weather;
        final location = weatherVm.selectedLocation;
        if (weather == null || location == null) {
          return StateFeedbackWidget.empty(
            title: 'Data Cuaca Kosong',
            message: 'Data cuaca tidak tersedia untuk lokasi ini.',
            actionLabel: 'Cari Kota Lain',
            onAction: onOpenSearch,
          );
        }

        final isFav = locationVm.isFavorite(location.id);
        final favorites = locationVm.favorites;

        return RefreshIndicator(
          onRefresh: weatherVm.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (favorites.isNotEmpty) ...[
                      _QuickFavoriteBar(
                        favorites: favorites,
                        selectedId: location.id,
                        onSelect: (city) => weatherVm.selectLocation(city),
                      ),
                      const SizedBox(height: 16),
                    ],
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 840) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 11,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CurrentWeatherCard(
                                      location: location,
                                      weather: weather,
                                      isFavorite: isFav,
                                      lastUpdated: weatherVm.lastUpdated,
                                      onToggleFavorite: () => _handleToggleFavorite(
                                        context,
                                        locationVm,
                                        location,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    WeatherMetricsGrid(weather: weather),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 9,
                                child: DailyForecastList(
                                  forecasts: weather.daily,
                                ),
                              ),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CurrentWeatherCard(
                              location: location,
                              weather: weather,
                              isFavorite: isFav,
                              lastUpdated: weatherVm.lastUpdated,
                              onToggleFavorite: () => _handleToggleFavorite(
                                context,
                                locationVm,
                                location,
                              ),
                            ),
                            const SizedBox(height: 20),
                            WeatherMetricsGrid(weather: weather),
                            const SizedBox(height: 20),
                            DailyForecastList(forecasts: weather.daily),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }

  Future<void> _handleToggleFavorite(
    BuildContext context,
    LocationViewModel locationVm,
    LocationModel location,
  ) async {
    final added = await locationVm.toggleFavorite(location);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            added
                ? '${location.name} disimpan ke lokasi favorit.'
                : '${location.name} dihapus dari favorit.',
          ),
        ),
      );
  }
}

class _QuickFavoriteBar extends StatelessWidget {
  const _QuickFavoriteBar({
    required this.favorites,
    required this.selectedId,
    required this.onSelect,
  });

  final List<LocationModel> favorites;
  final int selectedId;
  final ValueChanged<LocationModel> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: favorites.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final city = favorites[index];
          final isSelected = city.id == selectedId;
          return ChoiceChip(
            avatar: Icon(
              Icons.favorite_rounded,
              size: 16,
              color: isSelected ? colorScheme.primary : Colors.redAccent,
            ),
            label: Text(city.name),
            selected: isSelected,
            onSelected: (_) => onSelect(city),
          );
        },
      ),
    );
  }
}
