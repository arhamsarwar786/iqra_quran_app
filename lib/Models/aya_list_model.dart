// To parse this JSON data, do
//
//     final ayaListModel = ayaListModelFromJson(jsonString);

import 'dart:convert';

AyaListModel ayaListModelFromJson(String str) => AyaListModel.fromJson(json.decode(str));

String ayaListModelToJson(AyaListModel data) => json.encode(data.toJson());

class AyaListModel {
    List<Aya> aya;

    AyaListModel({
        required this.aya,
    });

    factory AyaListModel.fromJson(Map<String, dynamic> json) => AyaListModel(
        aya: List<Aya>.from(json["aya"].map((x) => Aya.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "aya": List<dynamic>.from(aya.map((x) => x.toJson())),
    };
}

class Aya {
    String arabic;
    String translation1;
    String translation2;
    int ayatNumber;
    String? sajda;

    Aya({
        required this.arabic,
        required this.translation1,
        required this.translation2,
        required this.ayatNumber,
        required this.sajda,
    });

    factory Aya.fromJson(Map<String, dynamic> json) => Aya(
        arabic: json["arabic"],
        translation1: json["translation1"],
        translation2: json["translation2"],
        ayatNumber: json["ayatNumber"],
        sajda: json["sajda"],
    );

    Map<String, dynamic> toJson() => {
        "arabic": arabic,
        "translation1": translation1,
        "translation2": translation2,
        "ayatNumber":ayatNumber,
        "sajda":sajda
    };
}
