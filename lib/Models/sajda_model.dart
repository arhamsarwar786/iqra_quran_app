// To parse this JSON data, do
//
//     final sajdaModel = sajdaModelFromJson(jsonString);

import 'dart:convert';

List<SajdaModel> sajdaModelFromJson(String str) => List<SajdaModel>.from(json.decode(str).map((x) => SajdaModel.fromJson(x)));

String sajdaModelToJson(List<SajdaModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class SajdaModel {
    String? serial;
    String surat;
    String? rukuNumber;
    String ayaBeforeSajda;
    String? place;

    SajdaModel({
        required this.serial,
        required this.surat,
        required this.rukuNumber,
        required this.ayaBeforeSajda,
        required this.place,
    });

    factory SajdaModel.fromJson(Map<String, dynamic> json) => SajdaModel(
        serial: json["Serial"],
        surat: json["Surat"],
        rukuNumber: json["rukuNumber"],
        ayaBeforeSajda: json["ayaBeforeSajda"],
        place: json["Place"]!,
    );

    Map<String, dynamic> toJson() => {
        "Serial": serial,
        "Surat": surat,
        "rukuNumber": rukuNumber,
        "ayaBeforeSajda": ayaBeforeSajda,
        "Place": place,
    };
}