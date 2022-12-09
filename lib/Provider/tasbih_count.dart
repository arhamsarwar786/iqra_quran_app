import 'package:flutter/material.dart';

class TasbeeCount extends ChangeNotifier {
  int count = 0;
  int? totalCount;
  void increment() {
    count++;
    notifyListeners();
  }

  void setValue(vAlue) {
    totalCount = vAlue;
    count = 0;
    notifyListeners();
  }

  void resetCount() {
    count = 0;
    notifyListeners();
  }

  int get currentStep => count;
  int get totalStep => totalCount ?? 0;
}