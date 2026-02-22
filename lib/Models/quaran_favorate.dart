import 'dart:convert';

List<QuranFavorite> quranFavoriteFromJson(String str) =>
    List<QuranFavorite>.from(
        json.decode(str).map((x) => QuranFavorite.fromJson(x)));

String quranFavoriteToJson(List<QuranFavorite> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

// @Entity()
class QuranFavorite {
  QuranFavorite({
    this.suratName,
    this.urduSuratName,
    this.suraVerses,
    this.surahCount,
    this.isPara,
  });

  var suratName;
  var urduSuratName;
  var suraVerses;
  var surahCount;
  bool? isPara;

  factory QuranFavorite.fromJson(Map<String, dynamic> json) {
    return QuranFavorite(
      suratName: json["surat"],
      urduSuratName: json["urduSurat"],
      suraVerses: json["sura"],
      surahCount: json["surahCount"],
      isPara: json["isPara"] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        "surat": suratName,
        "urduSurat": urduSuratName,
        "sura": suraVerses,
        "surahCount": surahCount,
        "isPara": isPara ?? false,
      };

  @override
  String toString() {
    return "$suratName , $suraVerses , $urduSuratName, isPara: $isPara";
  }
}
