// To parse this JSON data, do
//
//     final nameOfAllahModel = nameOfAllahModelFromJson(jsonString);

import 'dart:convert';

List<NameOfAllahModel> nameOfAllahModelFromJson(String str) => List<NameOfAllahModel>.from(json.decode(str).map((x) => NameOfAllahModel.fromJson(x)));

String nameOfAllahModelToJson(List<NameOfAllahModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class NameOfAllahModel {
    int sr;
    String? transliteration;
    String? namesOfAllahInUrdu;
    String? namesOfAllahInArabic;
    String? urduMeaning;
    String? englishMeaning;

    NameOfAllahModel({
        required this.sr,
        required this.transliteration,
        required this.namesOfAllahInUrdu,
        required this.namesOfAllahInArabic,
        required this.urduMeaning,
        required this.englishMeaning,
    });

    factory NameOfAllahModel.fromJson(Map<String, dynamic> json) => NameOfAllahModel(
        sr: json["SR#"],
        transliteration: json["Transliteration"],
        namesOfAllahInUrdu: json["Names of Allah in Urdu"],
        namesOfAllahInArabic: json["Names of Allah in Arabic"],
        urduMeaning: json["Urdu Meaning"],
        englishMeaning: json["English Meaning"],
    );

    Map<String, dynamic> toJson() => {
        "SR#": sr,
        "Transliteration": transliteration,
        "Names of Allah in Urdu": namesOfAllahInUrdu,
        "Names of Allah in Arabic": namesOfAllahInArabic,
        "Urdu Meaning": urduMeaning,
        "English Meaning": englishMeaning,
    };
}
