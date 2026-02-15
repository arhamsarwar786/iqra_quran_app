// To parse this JSON data, do
//
//     final ayaListModel = ayaListModelFromJson(jsonString);

import 'dart:convert';

AyaListModel ayaListModelFromJson(String str) =>
    AyaListModel.fromJson(json.decode(str));

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
  String? ayatId;
  String? ayatNumber;
  String? groupId;
  String? surahId;
  String? paraId;
  String? tafseerId;
  String arabicText;
  String? tarjumaIrfan;
  String? tarjumaHind;
  String? tarjumaPak;
  String? withoutArab;
  String? withoutHtmlTafseer;
  String? sajda;
  String? manzil;

  Aya({
    this.ayatId,
    this.ayatNumber,
    this.groupId,
    this.surahId,
    this.paraId,
    this.tafseerId,
    required this.arabicText,
    this.tarjumaIrfan,
    this.tarjumaHind,
    this.tarjumaPak,
    this.withoutArab,
    this.withoutHtmlTafseer,
    this.sajda,
    this.manzil,
  });

  factory Aya.fromJson(Map<String, dynamic> json) => Aya(
        ayatId: json["ayatId"]?.toString(),
        ayatNumber: json["ayatNumber"]?.toString(),
        groupId: json["groupId"]?.toString(),
        surahId: json["surahId"]?.toString(),
        paraId: json["paraId"]?.toString(),
        tafseerId: json["tafseerId"]?.toString(),
        arabicText: json["arabicText"] ?? "",
        tarjumaIrfan: json["tarjumaIrfan"],
        tarjumaHind: json["tarjumaHind"],
        tarjumaPak: json["tarjumaPak"],
        withoutArab: json["withoutArab"],
        withoutHtmlTafseer: json["withoutHtmlTafseer"],
        sajda: json["sajda"],
        manzil: json["manzil"],
      );

  Map<String, dynamic> toJson() => {
        "ayatId": ayatId,
        "ayatNumber": ayatNumber,
        "groupId": groupId,
        "surahId": surahId,
        "paraId": paraId,
        "tafseerId": tafseerId,
        "arabicText": arabicText,
        "tarjumaIrfan": tarjumaIrfan,
        "tarjumaHind": tarjumaHind,
        "tarjumaPak": tarjumaPak,
        "withoutArab": withoutArab,
        "withoutHtmlTafseer": withoutHtmlTafseer,
        "sajda": sajda,
        "manzil": manzil,
      };

  // Backward compatibility getters
  String get arabic => arabicText;
  String get translation1 => tarjumaIrfan ?? "";
  String get translation2 => tarjumaHind ?? "";
  int get ayatNumberInt => int.tryParse(ayatNumber ?? "0") ?? 0;
  bool get hasRuko => arabicText.contains('\u06E0');
  bool get hasSajda => arabicText.contains('\u06E9');
  bool get hasArba => arabicText.contains('\u065B');
  bool get hasNisf => arabicText.contains('\u065C');
  bool get hasSalsa => arabicText.contains('\u065D');
}
