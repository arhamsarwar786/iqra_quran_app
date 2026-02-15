class ParaMetadata {
  int? paraId;
  String? paraName;
  int? paraStartSurahId;
  int? paraStartRukuId;
  int? paraStartAyatId;
  int? paraVisible;
  String? searchParaName;
  String? searchParaNo;

  ParaMetadata({
    this.paraId,
    this.paraName,
    this.paraStartSurahId,
    this.paraStartRukuId,
    this.paraStartAyatId,
    this.paraVisible,
    this.searchParaName,
    this.searchParaNo,
  });

  factory ParaMetadata.fromJson(Map<String, dynamic> json) {
    return ParaMetadata(
      paraId: json['paraId'],
      paraName: json['paraName'],
      paraStartSurahId: json['paraStartSurahId'],
      paraStartRukuId: json['paraStartRukuId'],
      paraStartAyatId: json['paraStartAyatId'],
      paraVisible: json['paraVisible'],
      searchParaName: json['search_para_name'],
      searchParaNo: json['search_para_no'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['paraId'] = paraId;
    data['paraName'] = paraName;
    data['paraStartSurahId'] = paraStartSurahId;
    data['paraStartRukuId'] = paraStartRukuId;
    data['paraStartAyatId'] = paraStartAyatId;
    data['paraVisible'] = paraVisible;
    data['search_para_name'] = searchParaName;
    data['search_para_no'] = searchParaNo;
    return data;
  }
}
