import 'package:flutter/material.dart';

/// Metadata visual dan deskripsi untuk setiap kode cuaca WMO Open-Meteo.
class WeatherVisual {
  const WeatherVisual({
    required this.label,
    required this.icon,
    required this.gradientColors,
  });

  final String label;
  final IconData icon;
  final List<Color> gradientColors;
}

/// Utilitas pemetaan kode cuaca WMO dan pemformatan tanggal berbahasa Indonesia.
class WeatherCodeHelper {
  WeatherCodeHelper._();

  static const List<String> _dayNames = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// Mengubah kode WMO menjadi label kondisi cuaca, ikon, dan gradien kartu.
  static WeatherVisual describe(int code, {bool isDay = true}) {
    switch (code) {
      case 0:
        return WeatherVisual(
          label: isDay ? 'Cerah' : 'Cerah Malam',
          icon: isDay ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
          gradientColors: isDay
              ? const [Color(0xFF1D6CE0), Color(0xFF38BDF8)]
              : const [Color(0xFF0F172A), Color(0xFF1E3A8A)],
        );
      case 1:
        return WeatherVisual(
          label: 'Cerah Berawan',
          icon: isDay ? Icons.wb_cloudy_rounded : Icons.nights_stay_outlined,
          gradientColors: isDay
              ? const [Color(0xFF2563EB), Color(0xFF60A5FA)]
              : const [Color(0xFF172554), Color(0xFF1E40AF)],
        );
      case 2:
        return WeatherVisual(
          label: 'Berawan Sebagian',
          icon: Icons.cloud_queue_rounded,
          gradientColors: isDay
              ? const [Color(0xFF3B82F6), Color(0xFF64748B)]
              : const [Color(0xFF1E293B), Color(0xFF334155)],
        );
      case 3:
        return WeatherVisual(
          label: 'Mendung',
          icon: Icons.cloud_rounded,
          gradientColors: isDay
              ? const [Color(0xFF475569), Color(0xFF64748B)]
              : const [Color(0xFF0F172A), Color(0xFF334155)],
        );
      case 45:
      case 48:
        return const WeatherVisual(
          label: 'Berkabut',
          icon: Icons.foggy,
          gradientColors: [Color(0xFF475569), Color(0xFF94A3B8)],
        );
      case 51:
        return const WeatherVisual(
          label: 'Gerimis Ringan',
          icon: Icons.grain_rounded,
          gradientColors: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
        );
      case 53:
      case 55:
        return const WeatherVisual(
          label: 'Gerimis Lebat',
          icon: Icons.grain_rounded,
          gradientColors: [Color(0xFF075985), Color(0xFF0284C7)],
        );
      case 56:
      case 57:
        return const WeatherVisual(
          label: 'Gerimis Beku',
          icon: Icons.ac_unit_rounded,
          gradientColors: [Color(0xFF0E7490), Color(0xFF38BDF8)],
        );
      case 61:
        return const WeatherVisual(
          label: 'Hujan Ringan',
          icon: Icons.water_drop_rounded,
          gradientColors: [Color(0xFF1D4ED8), Color(0xFF0284C7)],
        );
      case 63:
        return const WeatherVisual(
          label: 'Hujan Sedang',
          icon: Icons.water_drop_rounded,
          gradientColors: [Color(0xFF1E40AF), Color(0xFF0369A1)],
        );
      case 65:
        return const WeatherVisual(
          label: 'Hujan Lebat',
          icon: Icons.thunderstorm_outlined,
          gradientColors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
        );
      case 66:
      case 67:
        return const WeatherVisual(
          label: 'Hujan Beku',
          icon: Icons.severe_cold_rounded,
          gradientColors: [Color(0xFF164E63), Color(0xFF0284C7)],
        );
      case 71:
      case 73:
      case 75:
      case 77:
        return const WeatherVisual(
          label: 'Salju',
          icon: Icons.ac_unit_rounded,
          gradientColors: [Color(0xFF334155), Color(0xFF60A5FA)],
        );
      case 80:
      case 81:
      case 82:
        return const WeatherVisual(
          label: 'Hujan Deras',
          icon: Icons.umbrella_rounded,
          gradientColors: [Color(0xFF1E3A8A), Color(0xFF0369A1)],
        );
      case 85:
      case 86:
        return const WeatherVisual(
          label: 'Hujan Salju',
          icon: Icons.cloudy_snowing,
          gradientColors: [Color(0xFF334155), Color(0xFF38BDF8)],
        );
      case 95:
        return const WeatherVisual(
          label: 'Badai Petir',
          icon: Icons.thunderstorm_rounded,
          gradientColors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
        );
      case 96:
      case 99:
        return const WeatherVisual(
          label: 'Badai Petir & Es',
          icon: Icons.thunderstorm_rounded,
          gradientColors: [Color(0xFF0F172A), Color(0xFF4338CA)],
        );
      default:
        return const WeatherVisual(
          label: 'Bervariasi',
          icon: Icons.wb_sunny_outlined,
          gradientColors: [Color(0xFF1D6CE0), Color(0xFF0284C7)],
        );
    }
  }

  /// Memformat tanggal prakiraan harian menjadi label singkat seperti "Hari ini", "Besok", atau "Jum, 27 Nov".
  static String formatForecastDay(DateTime date, int index) {
    if (index == 0) return 'Hari ini';
    if (index == 1) return 'Besok';
    final dayName = _dayNames[(date.weekday - 1) % 7];
    final monthName = _monthNames[(date.month - 1) % 12];
    return '$dayName, ${date.day} $monthName';
  }

  /// Memformat waktu terakhir pembaruan data (HH:mm).
  static String formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
