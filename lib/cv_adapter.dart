import 'package:hive/hive.dart';

part 'cv_adapter.g.dart';

@HiveType(typeId: 0)
class CVDocument extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final Map<String, dynamic> data;

  @HiveField(2)
  final DateTime lastUpdated;

  CVDocument({
    required this.id,
    required this.data,
    required this.lastUpdated,
  });
}