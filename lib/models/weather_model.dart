import 'dart:math' as math;

/// Data cuaca terkini dari objek `current` Open-Meteo Forecast API.
class CurrentWeather {
  const CurrentWeather({
    required this.time,
    required this.temperature2m,
    required this.relativeHumidity2m,
    required this.apparentTemperature,
    required this.precipitation,
    required this.weatherCode,
    required this.windSpeed10m,
    required this.isDay,
  });

  final String time;
  final double temperature2m;
  final int relativeHumidity2m;
  final double apparentTemperature;
  final double precipitation;
  final int weatherCode;
  final double windSpeed10m;
  final bool isDay;

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      time: (json['time'] as String?) ?? '',
      temperature2m: (json['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      relativeHumidity2m:
          (json['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      apparentTemperature:
          (json['apparent_temperature'] as num?)?.toDouble() ?? 0.0,
      precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (json['weather_code'] as num?)?.toInt() ?? 0,
      windSpeed10m: (json['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      isDay: ((json['is_day'] as num?)?.toInt() ?? 1) == 1,
    );
  }
}

/// Data prakiraan harian dari objek `daily` Open-Meteo Forecast API.
class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.temperature2mMax,
    required this.temperature2mMin,
    required this.precipitationProbabilityMax,
  });

  final DateTime date;
  final int weatherCode;
  final double temperature2mMax;
  final double temperature2mMin;
  final int precipitationProbabilityMax;
}

/// Respons lengkap Weather Forecast API Open-Meteo.
class WeatherResponse {
  const WeatherResponse({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.timezoneAbbreviation,
    required this.current,
    required this.daily,
  });

  final double latitude;
  final double longitude;
  final String timezone;
  final String timezoneAbbreviation;
  final CurrentWeather current;
  final List<DailyForecast> daily;

  factory WeatherResponse.fromJson(Map<String, dynamic> json) {
    final currentMap = json['current'];
    final dailyMap = json['daily'];

    if (currentMap is! Map<String, dynamic> ||
        dailyMap is! Map<String, dynamic>) {
      throw const FormatException(
        'Struktur data cuaca dari API tidak lengkap.',
      );
    }

    final times = (dailyMap['time'] as List?) ?? const [];
    final codes = (dailyMap['weather_code'] as List?) ?? const [];
    final maxTemps = (dailyMap['temperature_2m_max'] as List?) ?? const [];
    final minTemps = (dailyMap['temperature_2m_min'] as List?) ?? const [];
    final precipProbs =
        (dailyMap['precipitation_probability_max'] as List?) ?? const [];

    final count = [
      times.length,
      maxTemps.length,
      minTemps.length,
    ].reduce(math.min);

    final dailyList = <DailyForecast>[];
    for (var i = 0; i < count; i++) {
      final parsedDate = DateTime.tryParse(times[i].toString());
      if (parsedDate == null) continue;

      final code = i < codes.length && codes[i] is num
          ? (codes[i] as num).toInt()
          : 0;
      final precipProb = i < precipProbs.length && precipProbs[i] is num
          ? (precipProbs[i] as num).toInt()
          : 0;

      dailyList.add(
        DailyForecast(
          date: parsedDate,
          weatherCode: code,
          temperature2mMax: (maxTemps[i] as num).toDouble(),
          temperature2mMin: (minTemps[i] as num).toDouble(),
          precipitationProbabilityMax: precipProb,
        ),
      );
    }

    return WeatherResponse(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timezone: (json['timezone'] as String?) ?? 'Auto',
      timezoneAbbreviation: (json['timezone_abbreviation'] as String?) ?? '',
      current: CurrentWeather.fromJson(currentMap),
      daily: dailyList,
    );
  }
}
