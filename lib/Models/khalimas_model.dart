// To parse this JSON data, do
//
//     final khalimasModel = khalimasModelFromJson(jsonString);

import 'dart:convert';

List<KhalimasModel> khalimasModelFromJson(String str) =>
    List<KhalimasModel>.from(
        json.decode(str).map((x) => KhalimasModel.fromJson(x)));

String khalimasModelToJson(List<KhalimasModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class KhalimasModel {
  KhalimasModel({
    this.title,
    this.meaning,
    this.arabic,
    this.translation,
  });

  String? title;
  String? meaning;
  String? arabic;
  String? translation;

  factory KhalimasModel.fromJson(Map<String, dynamic> json) => KhalimasModel(
        title: json["title"],
        meaning: json["meaning"],
        arabic: json["arabic"],
        translation: json["translation"],
      );

  Map<String, dynamic> toJson() => {
        "title": title,
        "meaning": meaning,
        "arabic": arabic,
        "translation": translation,
      };
}
