import 'package:flutter/material.dart';

class ThemeModel {
  final String? primary;
  final String? secondary;

  ThemeModel({this.primary, this.secondary});

  ThemeModel.fromJson(Map<dynamic, dynamic> json)
      : primary = json['primary'],
        secondary = json['secondary'];

  Map<String, dynamic> toJson() {
    return {
      'primary': primary,
      'secondary': secondary,
    };
  }
}