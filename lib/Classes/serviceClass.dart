import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

part 'serviceClass.g.dart';

@HiveType(typeId: 4)
class Service {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double price;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final Map<String, dynamic>? iconData; // Store IconData as a map

  @HiveField(4)
  final String imagePath;

  @HiveField(5)
  final bool isAsset;

  Service({
    required this.name,
    required this.price,
    required this.category,
    IconData? icon,
    required this.imagePath,
    this.isAsset = true,
  }) : iconData = icon != null
      ? {'codePoint': icon.codePoint, 'fontFamily': icon.fontFamily}
      : null;

  IconData? get icon => iconData != null
      ? IconData(
    iconData!['codePoint'],
    fontFamily: iconData!['fontFamily'],
  )
      : null;
}