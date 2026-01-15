class TasbeehModel {
  String? no;
  String? arabic;
  String? transliteration;
  String? englishMeaning;
  String? urduMeaning;

  TasbeehModel({
    this.no,
    this.arabic,
    this.transliteration,
    this.englishMeaning,
    this.urduMeaning,
  });

  factory TasbeehModel.fromJson(Map<String, dynamic> json) {
    return TasbeehModel(
      no: json['No']?.toString(),
      arabic: json['Arabic']?.toString(),
      transliteration: json['Transliteration']?.toString(),
      englishMeaning: json['English Meaning']?.toString(),
      urduMeaning: json['Urdu Meaning']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'No': no,
      'Arabic': arabic,
      'Transliteration': transliteration,
      'English Meaning': englishMeaning,
      'Urdu Meaning': urduMeaning,
    };
  }
}
