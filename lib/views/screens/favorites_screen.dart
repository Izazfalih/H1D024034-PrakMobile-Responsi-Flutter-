import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/location_model.dart';
import '../../viewmodels/location_viewmodel.dart';
import '../../viewmodels/weather_viewmodel.dart';
import '../widgets/location_tile.dart';
import '../widgets/state_feedback_widget.dart';

/// Screen 3 (Tambahan): Mengelola lokasi favorit tersimpan di Hive agar cepat dipilih kembali.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    super.key,
    required this.onLocationSelected,
    required this.onOpenSearch,
  });

  final VoidCallback onLocationSelected;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationVm = context.watch<LocationViewModel>();
    final weatherVm = context.watch<WeatherViewModel>();
    final favorites = locationVm.favorites;
    final selectedId = weatherVm.selectedLocation?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Favorit'),
        actions: [
          IconButton(
            onPressed: onOpenSearch,
            tooltip: 'Tambah Kota Favorit',
            icon: const Icon(Icons.add_location_alt_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: favorites.isEmpty
          ? StateFeedbackWidget.empty(
              icon: Icons.favorite_border_rounded,
              title: 'Belum Ada Kota Favorit',
              message:
                  'Ketuk ikon hati pada halaman Cuaca atau Pencarian untuk menyimpan kota favorit secara permanen.',
              actionLabel: 'Cari Kota Sekarang',
              onAction: onOpenSearch,
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: favorites.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${favorites.length} lokasi tersimpan di penyimpanan lokal (Hive)',
                          style: theme.textTheme.bodyMedium,
                        ),
                      );
                    }
                    final city = favorites[index - 1];
                    return LocationTile(
                      location: city,
                      leadingIcon: Icons.favorite_rounded,
                      isFavorite: true,
                      isSelected: city.id == selectedId,
                      onTap: () async {
                        await weatherVm.selectLocation(city);
                        onLocationSelected();
                      },
                      onToggleFavorite: () => _removeFavorite(
                        context,
                        locationVm,
                        city,
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }

  Future<void> _removeFavorite(
    BuildContext context,
    LocationViewModel locationVm,
    LocationModel city,
  ) async {
    await locationVm.removeFavorite(city.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('${city.name} dihapus dari daftar favorit.'),
        ),
      );
  }
}
