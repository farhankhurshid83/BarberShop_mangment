import 'package:hive_ce/hive.dart';
part 'category.g.dart';

@HiveType(typeId: 6) // Unique typeId, assuming 0-5 are used by other classes
class Category {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String imagePath;

  @HiveField(2)
  final bool isAsset;

  Category({
    required this.name,
    required this.imagePath,
    required this.isAsset,
  });

  @override
  String toString() {
    return 'Category(name: $name, imagePath: $imagePath, isAsset: $isAsset)';
  }
}