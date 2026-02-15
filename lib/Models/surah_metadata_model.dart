import 'dart:convert';

List<SurahMetadata> surahMetadataFromJson(String str) {
  final jsonData = json.decode(str);
  final suras = jsonData['quran']['suras']['sura'];
  return List<SurahMetadata>.from(suras.map((x) => SurahMetadata.fromJson(x)));
}

class SurahMetadata {
  String index;
  String ayas;
  String start;
  String name;
  String tname;
  String ename;
  String type;
  String order;
  String rukus;

  SurahMetadata({
    required this.index,
    required this.ayas,
    required this.start,
    required this.name,
    required this.tname,
    required this.ename,
    required this.type,
    required this.order,
    required this.rukus,
  });

  factory SurahMetadata.fromJson(Map<String, dynamic> json) => SurahMetadata(
        index: json["index"] ?? "",
        ayas: json["ayas"] ?? "",
        start: json["start"] ?? "",
        name: json["name"] ?? "",
        tname: json["tname"] ?? "",
        ename: json["ename"] ?? "",
        type: json["type"] ?? "",
        order: json["order"] ?? "",
        rukus: json["rukus"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "index": index,
        "ayas": ayas,
        "start": start,
        "name": name,
        "tname": tname,
        "ename": ename,
        "type": type,
        "order": order,
        "rukus": rukus,
      };
}
