import 'package:flutter/material.dart';

import '../../core/utils/weather_code_helper.dart';
import '../../models/weather_model.dart';

/// Grid responsif yang menampilkan metrik detail cuaca terkini dari Open-Meteo API.
class WeatherMetricsGrid extends StatelessWidget {
  const WeatherMetricsGrid({
    super.key,
    required this.weather,
  });

  final WeatherResponse weather;

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    final today = weather.daily.isNotEmpty ? weather.daily.first : null;
    final condition = WeatherCodeHelper.describe(
      current.weatherCode,
      isDay: current.isDay,
    );

    final metrics = <_MetricItem>[
      _MetricItem(
        icon: Icons.water_drop_outlined,
        label: 'Kelembapan',
        value: '${current.relativeHumidity2m}%',
        caption: 'Kelembapan relatif udara',
      ),
      _MetricItem(
        icon: Icons.air_rounded,
        label: 'Kecepatan Angin',
        value: '${current.windSpeed10m.toStringAsFixed(1)} km/j',
        caption: 'Pada ketinggian 10m',
      ),
      _MetricItem(
        icon: Icons.thermostat_auto_rounded,
        label: 'Terasa Seperti',
        value: '${current.apparentTemperature.toStringAsFixed(1)}°C',
        caption: 'Suhu yang dirasakan',
      ),
      _MetricItem(
        icon: Icons.umbrella_outlined,
        label: 'Curah Hujan',
        value: '${current.precipitation.toStringAsFixed(1)} mm',
        caption: 'Intensitas saat ini',
      ),
      _MetricItem(
        icon: Icons.cloud_outlined,
        label: 'Peluang Hujan',
        value: today != null ? '${today.precipitationProbabilityMax}%' : '-',
        caption: 'Maksimum hari ini',
      ),
      _MetricItem(
        icon: Icons.qr_code_rounded,
        label: 'Kode Kondisi',
        value: 'WMO ${current.weatherCode}',
        caption: condition.label,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detail Cuaca Terkini',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 560 ? 3 : 2;
            const spacing = 12.0;
            final itemWidth =
                (constraints.maxWidth - (spacing * (columns - 1))) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: metrics
                  .map(
                    (metric) => SizedBox(
                      width: itemWidth,
                      child: _MetricCard(item: metric),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _MetricItem {
  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    style: theme.textTheme.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.value,
              style: theme.textTheme.headlineSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              item.caption,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
