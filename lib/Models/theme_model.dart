import 'package:flutter/material.dart';

class ThemeModel {
  final String? primary;
  final String? secondary;
  final String? theme;
  final String? iconNumber;

  ThemeModel({this.primary, this.secondary, this.theme, this.iconNumber});

  ThemeModel.fromJson(Map<dynamic, dynamic> json)
      : primary = json['primary'],
        secondary = json['secondary'],
      theme = json['theme'],
      iconNumber = json['iconNumber']
        ;

  Map<String, dynamic> toJson() {
    return {
      'primary': primary,
      'secondary': secondary,
      'theme': theme,
      'iconNumber': iconNumber,
    };
  }
}