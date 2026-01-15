class NameOfMuhammadModel {
  final int no;
  final String transliteration;
  final String nameUrdu;
  final String nameArabic;
  final String meaningUrdu;
  final String meaningEnglish;

  NameOfMuhammadModel({
    required this.no,
    required this.transliteration,
    required this.nameUrdu,
    required this.nameArabic,
    required this.meaningUrdu,
    required this.meaningEnglish,
  });

  factory NameOfMuhammadModel.fromJson(Map<String, dynamic> json) {
    return NameOfMuhammadModel(
      no: json['No'] ?? 0,
      transliteration: json['Transliteration'] ?? '',
      nameUrdu: json['Muhammad (SAW) Names in Urdu'] ?? '',
      nameArabic: json['Muhammad (SAW) Names in Arabic'] ?? '',
      meaningUrdu: json['Meanings in Urdu'] ?? '',
      meaningEnglish: json['Meanings in English'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'No': no,
      'Transliteration': transliteration,
      'Muhammad (SAW) Names in Urdu': nameUrdu,
      'Muhammad (SAW) Names in Arabic': nameArabic,
      'Meanings in Urdu': meaningUrdu,
      'Meanings in English': meaningEnglish,
    };
  }
}
