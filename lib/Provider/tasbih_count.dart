import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TasbeeCount extends ChangeNotifier {
  int count = 0;
  static const String _countKey = 'tasbeeh_count';

  TasbeeCount() {
    _loadCount();
  }

  Future<void> _loadCount() async {
    final prefs = await SharedPreferences.getInstance();
    count = prefs.getInt(_countKey) ?? 0;
    notifyListeners();
  }

  Future<void> _saveCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey, count);
  }

  void increment() {
    count++;
    _saveCount();
    notifyListeners();
  }

  void resetCount() {
    count = 0;
    _saveCount();
    notifyListeners();
  }

  int get currentStep => count;
}