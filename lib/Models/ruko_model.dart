// To parse this JSON data, do
//
//     final rukoModel = rukoModelFromJson(jsonString);

import 'dart:convert';

List<RukoModel> rukoModelFromJson(String str) => List<RukoModel>.from(json.decode(str).map((x) => RukoModel.fromJson(x)));

String rukoModelToJson(List<RukoModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class RukoModel {
    String serial;
    String surat;
    String rakuNumber;
    String ayaAfterRako;
    String place;
    String ayaBeforeRako;
    String diff;

    RukoModel({
        required this.serial,
        required this.surat,
        required this.rakuNumber,
        required this.ayaAfterRako,
        required this.place,
        required this.ayaBeforeRako,
        required this.diff,
    });

    factory RukoModel.fromJson(Map<String, dynamic> json) => RukoModel(
        serial: json["Serial"],
        surat: json["Surat"],
        rakuNumber: json["rakuNumber"],
        ayaAfterRako: json["ayaAfterRako"],
        place: json["Place"],
        ayaBeforeRako: json["ayaBeforeRako"],
        diff: json["Diff"],
    );

    Map<String, dynamic> toJson() => {
        "Serial": serial,
        "Surat": surat,
        "rakuNumber": rakuNumber,
        "ayaAfterRako": ayaAfterRako,
        "Place": place,
        "ayaBeforeRako": ayaBeforeRako,
        "Diff": diff,
    };
}
