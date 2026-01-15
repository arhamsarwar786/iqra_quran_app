import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/tasbeeh_model.dart';

class TasbeehProvider extends ChangeNotifier {
  TasbeehModel? _selectedTasbeeh;
  static const String _selectedTasbeehKey = 'selected_tasbeeh';

  TasbeehProvider() {
    _loadSelectedTasbeeh();
  }

  TasbeehModel? get selectedTasbeeh => _selectedTasbeeh;

  Future<void> _loadSelectedTasbeeh() async {
    final prefs = await SharedPreferences.getInstance();
    final tasbeehJson = prefs.getString(_selectedTasbeehKey);
    if (tasbeehJson != null) {
      try {
        _selectedTasbeeh = TasbeehModel.fromJson(json.decode(tasbeehJson));
        notifyListeners();
      } catch (e) {
        print('Error loading selected tasbeeh: $e');
      }
    }
  }

  Future<void> setSelectedTasbeeh(TasbeehModel tasbeeh) async {
    _selectedTasbeeh = tasbeeh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedTasbeehKey, json.encode(tasbeeh.toJson()));
    notifyListeners();
  }

  Future<void> clearSelectedTasbeeh() async {
    _selectedTasbeeh = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedTasbeehKey);
    notifyListeners();
  }

  bool get hasSelectedTasbeeh => _selectedTasbeeh != null;
}
