import 'dart:convert';

List<QuranFavorite> quranFavoriteFromJson(String str) => List<QuranFavorite>.from(json.decode(str).map((x) => QuranFavorite.fromJson(x)));

String quranFavoriteToJson(List<QuranFavorite> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

// @Entity()
class QuranFavorite {
    QuranFavorite({
        this.suratName,
        this.urduSuratName,
        this.suraVerses,
        // this.ayatInSura,
        this.surahCount,
    });

    var suratName;
    var urduSuratName;
    var suraVerses;
    //  List<int>? ayatInSura;
    var surahCount;
    factory QuranFavorite.fromJson(Map<String, dynamic> json) {
      return QuranFavorite(
      
       suratName: json["surat"],
        urduSuratName: json["urduSurat"],
        suraVerses: json["sura"],
        // ayatInSura: json["ayatInSura"],
        surahCount: json["surahCount"],
        // print(suratName);
        
    );}
    
    

    Map<String, dynamic> toJson() => {
      
        "surat": suratName,
        "urduSurat": urduSuratName,
        "sura": suraVerses,
        // "ayatInSura":ayatInSura,
        "surahCount":surahCount,
    };
    @override
  String toString() {
    return "$suratName , $suraVerses , $urduSuratName";
     
  }
}