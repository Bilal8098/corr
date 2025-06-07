import 'package:hive/hive.dart';
import 'cv_adapter.dart';

class LocalStorage {
  static const String _boxName = 'cvBox';
  static late Box<CVDocument> _box;

  static Future<void> init() async {
    Hive.registerAdapter(CVDocumentAdapter());
    _box = await Hive.openBox<CVDocument>(_boxName);
  }

  static Future<void> saveCVs(List<Map<String, dynamic>> cvs) async {
    await _box.clear();
    for (final cv in cvs) {
      final document = CVDocument(
        id: cv['id'],
        data: cv,
        lastUpdated: DateTime.now(),
      );
      await _box.put(cv['id'], document);
    }
  }

  static List<Map<String, dynamic>> getCVs() {
    return _box.values.map((doc) => doc.data).toList();
  }

  static Future<void> updateCV(Map<String, dynamic> cv) async {
    final document = CVDocument(
      id: cv['id'],
      data: cv,
      lastUpdated: DateTime.now(),
    );
    await _box.put(cv['id'], document);
  }
}