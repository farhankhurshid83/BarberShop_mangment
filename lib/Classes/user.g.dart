// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final typeId = 5;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      username: fields[0] as String,
      email: fields[1] as String,
      hashedPassword: fields[2] as String,
      role: fields[3] as String?,
      isLoggedIn: fields[4] == null ? false : fields[4] as bool?,
      profilePicturePath: fields[5] as String?,
      allowedOptions: (fields[6] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.username)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.hashedPassword)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.isLoggedIn)
      ..writeByte(5)
      ..write(obj.profilePicturePath)
      ..writeByte(6)
      ..write(obj.allowedOptions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
