import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';
import '../Models/tasbih_model.dart';
import '../objectbox.g.dart';

class ObjectBox {
  late final Store _store;
  late final Box<TasbihModel> _tasbihBox;
  ObjectBox._init(store) {
    _tasbihBox = Box<TasbihModel>(store);
  }
  static Future<ObjectBox> init() async {
    final open = await openStore();
    return ObjectBox._init(open);
  }

  TasbihModel? getUset(int id) => _tasbihBox.get(id);
  Stream<List<TasbihModel>> getUsers() => _tasbihBox
      .query()
      .watch(triggerImmediately: true)
      .map((query) => query.find());

  TasbihModel? getTasbehByVirdh(String virdh) {
    if (virdh.isEmpty) return null;
    final query = _tasbihBox.query(TasbihModel_.virdh.equals(virdh)).build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  TasbihModel? getTodayTasbih(String virdh) {
    if (virdh.isEmpty) return null;
    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final query = _tasbihBox
        .query(TasbihModel_.virdh
            .equals(virdh)
            .and(TasbihModel_.date.equals(dateStr)))
        .build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  /// Returns all saved records ordered newest-first (highest ObjectBox id first).
  /// Used to push recently-used tasbeehs to the top of the pick list.
  List<TasbihModel> getAllUsersSortedByDate() {
    final all = _tasbihBox.getAll();
    // Sort descending by id — ObjectBox assigns monotonically increasing ids,
    // so the highest id is the most recently inserted/updated record.
    all.sort((a, b) => b.id.compareTo(a.id));
    return all;
  }

  Future<int> insertUser(TasbihModel data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'tasbeeh_date_${data.virdh}', DateTime.now().toIso8601String());
    } catch (e) {
      log('Error saving tasbeeh date: $e');
    }
    return _tasbihBox.put(data);
  }

  Future<int> saveDailyTasbih(String virdh, int count) async {
    final now = DateTime.now();
    // Use clear YYYY-MM-DD format
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final query = _tasbihBox
        .query(TasbihModel_.virdh
            .equals(virdh)
            .and(TasbihModel_.date.equals(dateStr)))
        .build();
    var existing = query.findFirst();
    query.close();

    if (existing != null) {
      // Add the new count to the existing completely so progress isn't wiped if they start fresh at 0.
      existing.count = count;
      return insertUser(existing);
    } else {
      var newUser = TasbihModel(virdh: virdh, count: count, date: dateStr);
      return insertUser(newUser);
    }
  }

  bool deletetUser(int id) => _tasbihBox.remove(id);
  void closedStore() => _store.close();
}
