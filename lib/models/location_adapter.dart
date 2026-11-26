import 'package:hive/hive.dart';

import 'location_model.dart';

/// TypeAdapter biner Hive untuk menyimpan [LocationModel] secara persisten.
class LocationAdapter extends TypeAdapter<LocationModel> {
  @override
  final int typeId = 0;

  @override
  LocationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return LocationModel(
      id: fields[0] as int,
      name: fields[1] as String,
      country: fields[2] as String,
      admin1: fields[3] as String?,
      latitude: fields[4] as double,
      longitude: fields[5] as double,
      timezone: fields[6] as String?,
      savedAt: fields[7] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[7] as int)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, LocationModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.country)
      ..writeByte(3)
      ..write(obj.admin1)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.timezone)
      ..writeByte(7)
      ..write(obj.savedAt?.millisecondsSinceEpoch);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
