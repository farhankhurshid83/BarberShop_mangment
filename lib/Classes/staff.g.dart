// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StaffAdapter extends TypeAdapter<Staff> {
  @override
  final typeId = 7;

  @override
  Staff read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Staff(
      name: fields[0] as String,
      salary: (fields[1] as num).toDouble(),
      contact: fields[2] as String,
      address: fields[3] as String,
      role: fields[4] as String,
      profilePicturePath: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Staff obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.salary)
      ..writeByte(2)
      ..write(obj.contact)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.role)
      ..writeByte(5)
      ..write(obj.profilePicturePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
