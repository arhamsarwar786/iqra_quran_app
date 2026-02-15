import 'dart:convert';

List<SurahMetadata> surahMetadataFromJson(String str) {
  final jsonData = json.decode(str);
  // Check if it's a list directly (new format) or nested (old format)
  if (jsonData is List) {
    return List<SurahMetadata>.from(
        jsonData.map((x) => SurahMetadata.fromJson(x)));
  } else {
    // Fallback for old expected structure just in case, though we are switching source
    final suras = jsonData['quran']['suras']['sura'];
    return List<SurahMetadata>.from(
        suras.map((x) => SurahMetadata.fromJson(x)));
  }
}

class SurahMetadata {
  // New fields from surah.json
  final int surahId;
  final String surahName;
  final String romanName;
  final String surahIntroduction;
  final int surahTotalRuku;
  final int surahTotalAyaat;
  final String surahPlace;
  final int surahTarteebNuzool;
  final int surahParaId;
  final int surahManzil;
  final int surahVisible;
  final String mushtamilPara;
  final int totalWords;
  final int totalLetters;
  final String romanUrl;
  final String searchSurahName;
  final String searchSurahNo;
  final int favouriteSurah;
  final String romanEngName;

  SurahMetadata({
    required this.surahId,
    required this.surahName,
    required this.romanName,
    required this.surahIntroduction,
    required this.surahTotalRuku,
    required this.surahTotalAyaat,
    required this.surahPlace,
    required this.surahTarteebNuzool,
    required this.surahParaId,
    required this.surahManzil,
    required this.surahVisible,
    required this.mushtamilPara,
    required this.totalWords,
    required this.totalLetters,
    required this.romanUrl,
    required this.searchSurahName,
    required this.searchSurahNo,
    required this.favouriteSurah,
    required this.romanEngName,
  });

  // Backward compatibility getters
  String get index => surahId.toString();
  String get ayas => surahTotalAyaat.toString();
  String get start => ""; // Not present in new JSON, return empty
  String get name => surahName; // Arabic name
  String get tname => romanName; // Transliterated/Roman name
  String get ename => romanEngName; // English name
  String get type => surahPlace == "مکیۃ"
      ? "Meccan"
      : "Medinan"; // Map to old expected values if needed, or stick to new values
  String get order => surahTarteebNuzool.toString();
  String get rukus => surahTotalRuku.toString();

  factory SurahMetadata.fromJson(Map<String, dynamic> json) {
    // Handle both old and new formats if necessary, but prioritizing new format
    if (json.containsKey('surahId')) {
      return SurahMetadata(
        surahId: json["surahId"],
        surahName: json["surahName"] ?? "",
        romanName: json["roman_name"] ?? "",
        surahIntroduction: json["surahIntroduction"] ?? "",
        surahTotalRuku: json["surahTotalRuku"] ?? 0,
        surahTotalAyaat: json["surahTotalAyaat"] ?? 0,
        surahPlace: json["surahPlace"] ?? "",
        surahTarteebNuzool: json["surahTarteebNuzool"] ?? 0,
        surahParaId: json["surahParaId"] ?? 0,
        surahManzil: json["surahManzil"] ?? 0,
        surahVisible: json["surahVisible"] ?? 0,
        mushtamilPara: json["mushtamil_para"] ?? "",
        totalWords: json["total_words"] ?? 0,
        totalLetters: json["total_letters"] ?? 0,
        romanUrl: json["roman_url"] ?? "",
        searchSurahName: json["search_surah_name"] ?? "",
        searchSurahNo: json["search_surah_no"] ?? "",
        favouriteSurah: json["favourite_surah"] ?? 0,
        romanEngName: json["roman_eng_name"] ?? "",
      );
    } else {
      // Only partial fallback for old structure to avoid crash if old file is somehow loaded
      // This constructs a dummy object or tries to map what it can. Use default values.
      return SurahMetadata(
        surahId: int.tryParse(json["index"] ?? "0") ?? 0,
        surahName: json["name"] ?? "",
        romanName: json["tname"] ?? "", // approximate
        surahIntroduction: "",
        surahTotalRuku: int.tryParse(json["rukus"] ?? "0") ?? 0,
        surahTotalAyaat: int.tryParse(json["ayas"] ?? "0") ?? 0,
        surahPlace: json["type"] == "Meccan" ? "مکیۃ" : "مدنیۃ",
        surahTarteebNuzool: int.tryParse(json["order"] ?? "0") ?? 0,
        surahParaId: 0,
        surahManzil: 0,
        surahVisible: 1,
        mushtamilPara: "",
        totalWords: 0,
        totalLetters: 0,
        romanUrl: "",
        searchSurahName: "",
        searchSurahNo: "",
        favouriteSurah: 0,
        romanEngName: json["ename"] ?? "",
      );
    }
  }

  Map<String, dynamic> toJson() => {
        "surahId": surahId,
        "surahName": surahName,
        "roman_name": romanName,
        "surahIntroduction": surahIntroduction,
        "surahTotalRuku": surahTotalRuku,
        "surahTotalAyaat": surahTotalAyaat,
        "surahPlace": surahPlace,
        "surahTarteebNuzool": surahTarteebNuzool,
        "surahParaId": surahParaId,
        "surahManzil": surahManzil,
        "surahVisible": surahVisible,
        "mushtamil_para": mushtamilPara,
        "total_words": totalWords,
        "total_letters": totalLetters,
        "roman_url": romanUrl,
        "search_surah_name": searchSurahName,
        "search_surah_no": searchSurahNo,
        "favourite_surah": favouriteSurah,
        "roman_eng_name": romanEngName,
      };
}
