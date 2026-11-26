import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/utils/weather_code_helper.dart';
import '../../models/weather_model.dart';

/// Kartu daftar prakiraan cuaca harian untuk beberapa hari ke depan.
class DailyForecastList extends StatelessWidget {
  const DailyForecastList({
    super.key,
    required this.forecasts,
  });

  final List<DailyForecast> forecasts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (forecasts.isEmpty) {
      return const SizedBox.shrink();
    }

    final weekMin = forecasts
        .map((e) => e.temperature2mMin)
        .reduce(math.min);
    final weekMax = forecasts
        .map((e) => e.temperature2mMax)
        .reduce(math.max);
    final span = math.max(1.0, weekMax - weekMin);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Prakiraan ${forecasts.length} Hari Ke Depan',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < forecasts.length; i++) ...[
              _DailyForecastRow(
                forecast: forecasts[i],
                index: i,
                weekMin: weekMin,
                weekSpan: span,
              ),
              if (i < forecasts.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DailyForecastRow extends StatelessWidget {
  const _DailyForecastRow({
    required this.forecast,
    required this.index,
    required this.weekMin,
    required this.weekSpan,
  });

  final DailyForecast forecast;
  final int index;
  final double weekMin;
  final double weekSpan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final visual = WeatherCodeHelper.describe(forecast.weatherCode);

    final startRatio =
        ((forecast.temperature2mMin - weekMin) / weekSpan).clamp(0.0, 1.0);
    final endRatio =
        ((forecast.temperature2mMax - weekMin) / weekSpan).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                WeatherCodeHelper.formatForecastDay(forecast.date, index),
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                visual.label,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          visual.icon,
          size: 22,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 52,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.water_drop_rounded,
                  size: 13,
                  color: colorScheme.secondary,
                ),
                const SizedBox(width: 2),
                Text(
                  '${forecast.precipitationProbabilityMax}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              '${forecast.temperature2mMin.toStringAsFixed(0)}°',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final left = trackWidth * startRatio;
              final width = math.max(
                10.0,
                trackWidth * (endRatio - startRatio),
              );

              return Container(
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: math.min(left, math.max(0, trackWidth - width)),
                      width: math.min(width, trackWidth),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.secondary,
                              const Color(0xFFF59E0B),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 34,
          child: Text(
            '${forecast.temperature2mMax.toStringAsFixed(0)}°',
            textAlign: TextAlign.right,
            style: theme.textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}
