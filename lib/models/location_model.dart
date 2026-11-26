/// Representasi data lokasi/kota dari Geocoding API Open-Meteo dan Hive Local Storage.
class LocationModel {
  const LocationModel({
    required this.id,
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.admin1,
    this.timezone,
    this.savedAt,
  });

  final int id;
  final String name;
  final String country;
  final String? admin1;
  final double latitude;
  final double longitude;
  final String? timezone;
  final DateTime? savedAt;

  /// Membentuk [LocationModel] dari objek hasil JSON Open-Meteo Geocoding API.
  factory LocationModel.fromGeocodingJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final lat = (json['latitude'] as num?)?.toDouble() ?? 0.0;
    final lon = (json['longitude'] as num?)?.toDouble() ?? 0.0;

    return LocationModel(
      id: rawId is num
          ? rawId.toInt()
          : '${json['name']}_${lat.toStringAsFixed(3)}_${lon.toStringAsFixed(3)}'
              .hashCode,
      name: (json['name'] as String?)?.trim() ?? 'Lokasi Tidak Diketahui',
      country: (json['country'] as String?)?.trim() ?? '',
      admin1: (json['admin1'] as String?)?.trim(),
      latitude: lat,
      longitude: lon,
      timezone: (json['timezone'] as String?)?.trim(),
    );
  }

  /// Ringkasan wilayah administratif dan negara, mis. "Jawa Barat, Indonesia".
  String get subtitle {
    final parts = <String>[];
    if (admin1 != null &&
        admin1!.isNotEmpty &&
        admin1!.toLowerCase() != name.toLowerCase()) {
      parts.add(admin1!);
    }
    if (country.isNotEmpty) {
      parts.add(country);
    }
    return parts.isEmpty ? 'Koordinat ${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}' : parts.join(', ');
  }

  LocationModel copyWith({
    int? id,
    String? name,
    String? country,
    String? admin1,
    double? latitude,
    double? longitude,
    String? timezone,
    DateTime? savedAt,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      admin1: admin1 ?? this.admin1,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
