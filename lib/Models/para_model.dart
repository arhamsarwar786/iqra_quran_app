class ParahModel {
  List<Para>? para;

  ParahModel({this.para});

  ParahModel.fromJson(Map<String, dynamic> json) {
    if (json['para'] != null) {
      para = <Para>[];
      json['para'].forEach((v) {
        para!.add(new Para.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.para != null) {
      data['para'] = this.para!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Para {
  String? name;
  int? totalAyat;
  int? totalSajda;
  int? para;
  List<Data>? data;

  Para({this.name, this.totalAyat, this.totalSajda, this.para, this.data});

  Para.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    totalAyat = json['totalAyat'];
    totalSajda = json['totalSajda'];
    para = json['para'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['totalAyat'] = this.totalAyat;
    data['totalSajda'] = this.totalSajda;
    data['para'] = this.para;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  int? part;
  List<Aya>? aya;

  Data({this.part, this.aya});

  Data.fromJson(Map<String, dynamic> json) {
    part = json['part'];
    if (json['aya'] != null) {
      aya = <Aya>[];
      json['aya'].forEach((v) {
        aya!.add(new Aya.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['part'] = this.part;
    if (this.aya != null) {
      data['aya'] = this.aya!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Aya {
  bool? isRuko;
  int? surat;
  int? rakuNumber;
  int? ayaAfterRako;
  String? place;
  int? ayaBeforeRako;
  int? diff;
  int? bottomNumber;
  String? arabic;
  String? translation1;
  String? translation2;
  int? ayatNumber;
  bool? isSurahChange;

  Aya(
      {this.isRuko,
      this.surat,
      this.rakuNumber,
      this.ayaAfterRako,
      this.place,
      this.ayaBeforeRako,
      this.diff,
      this.bottomNumber,
      this.arabic,
      this.translation1,
      this.isSurahChange,
      this.translation2,
      this.ayatNumber});

  Aya.fromJson(Map<String, dynamic> json) {
    isRuko = json['isRuko'];
    surat = json['Surat'];
    rakuNumber = json['rakuNumber'];
    ayaAfterRako = json['ayaAfterRako'];
    place = json['Place'];
    ayaBeforeRako = json['ayaBeforeRako'];
    diff = json['Diff'];
    bottomNumber = json['bottomNumber'];
    arabic = json['arabic'];
    translation1 = json['translation1'];
    translation2 = json['translation2'];
    ayatNumber = json['ayatNumber'];
    isSurahChange = json['isSurahChange'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['isRuko'] = this.isRuko;
    data['Surat'] = this.surat;
    data['rakuNumber'] = this.rakuNumber;
    data['ayaAfterRako'] = this.ayaAfterRako;
    data['Place'] = this.place;
    data['ayaBeforeRako'] = this.ayaBeforeRako;
    data['Diff'] = this.diff;
    data['bottomNumber'] = this.bottomNumber;
    data['arabic'] = this.arabic;
    data['translation1'] = this.translation1;
    data['translation2'] = this.translation2;
    data['ayatNumber'] = this.ayatNumber;
    data['isSurahChange'] = this.isSurahChange;
    return data;
  }
}
