import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../Models/aya_list_model.dart';
import '../Models/para_metadata_model.dart';
import '../Models/ruko_model.dart';
import '../Models/sajda_model.dart';
import '../Models/surah_metadata_model.dart';

class QuranDataProvider extends ChangeNotifier {
  // Singleton pattern
  static final QuranDataProvider _instance = QuranDataProvider._internal();
  factory QuranDataProvider() => _instance;
  QuranDataProvider._internal();

  List<Aya> _quranData = [];
  List<ParaMetadata> _paraMetadata = [];
  List<RukoModel> _rukoData = [];
  List<SajdaModel> _sajdaData = [];
  List<SurahMetadata> _surahMetadata = [];
  final Map<String, int> _paraAyatCounts = {};
  bool _isLoading = false;
  bool _isLoaded = false;

  List<Aya> get quranData => _quranData;
  List<ParaMetadata> get paraMetadata => _paraMetadata;
  List<RukoModel> get rukoData => _rukoData;
  List<SajdaModel> get sajdaData => _sajdaData;
  List<SurahMetadata> get surahMetadata => _surahMetadata;
  Map<String, int> get paraAyatCounts => _paraAyatCounts;
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;

  /// Loads the Quran data from assets/extraction/quran2026.json
  /// This should be called once, preferably at app startup.
  Future<void> loadQuranData() async {
    if (_isLoaded || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Quran Data Bank: Starting to load assets...');

      // Load string from assets
      final String jsonString =
          await rootBundle.loadString('assets/extraction/quran2026.json');
      debugPrint(
          'Quran Data Bank: quran2026.json loaded from assets (${jsonString.length} chars).');

      // Parse in background to avoid jank
      _quranData = await compute(_parseQuranJson, jsonString);
      debugPrint('Quran Data Bank: Parsed ${_quranData.length} ayats.');

      // Load para metadata
      debugPrint('Quran Data Bank: Loading para.json...');
      final String paraJsonString =
          await rootBundle.loadString('assets/extraction/para.json');
      final List<dynamic> paraJsonList = json.decode(paraJsonString);
      _paraMetadata =
          paraJsonList.map((j) => ParaMetadata.fromJson(j)).toList();
      debugPrint(
          'Quran Data Bank: Loaded ${_paraMetadata.length} paras metadata.');

      // Generate ruko metadata from quran2026.json markers
      debugPrint('Quran Data Bank: Generating ruko metadata from markers...');
      _rukoData = _generateRukoFromMarkers(_quranData);
      debugPrint(
          'Quran Data Bank: Generated ${_rukoData.length} ruko metadata items.');

      // Load sajda metadata
      debugPrint('Quran Data Bank: Loading sajda.json...');
      final String sajdaJsonString =
          await rootBundle.loadString('assets/extraction/sajda.json');
      _sajdaData = sajdaModelFromJson(sajdaJsonString);
      debugPrint(
          'Quran Data Bank: Loaded ${_sajdaData.length} sajda metadata.');

      // Load Surah metadata
      debugPrint('Quran Data Bank: Loading quranmetadata.json...');
      final String surahMetaJsonString = await rootBundle.loadString(
          'assets/quran_kareem/urdu_translation/quranmetadata.json');
      _surahMetadata = surahMetadataFromJson(surahMetaJsonString);
      debugPrint(
          'Quran Data Bank: Loaded ${_surahMetadata.length} surah metadata.');

      // Calculate para ayat counts
      _paraAyatCounts.clear();
      for (var item in _quranData) {
        String paraId = item.paraId?.toString() ?? "0";
        if (paraId != "0") {
          _paraAyatCounts[paraId] = (_paraAyatCounts[paraId] ?? 0) + 1;
        }
      }
      debugPrint(
          'Quran Data Bank: Calculated counts for ${_paraAyatCounts.length} paras.');

      _isLoaded = true;
      notifyListeners();
      debugPrint('Quran Data Bank: Initialization complete.');
    } catch (e, stack) {
      debugPrint('Quran Data Bank: ERROR during loading: $e');
      debugPrint(stack.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get ayats for a specific Surah
  List<Aya> getAyatsBySurah(int surahId) {
    return _quranData
        .where((aya) => aya.surahId == surahId.toString())
        .toList();
  }

  /// Get Surah metadata by ID
  SurahMetadata? getSurahMetadata(int surahId) {
    try {
      return _surahMetadata
          .firstWhere((element) => element.index == surahId.toString());
    } catch (e) {
      return null;
    }
  }

  /// Get ayats for a specific Para (Juz)
  List<Aya> getAyatsByPara(int paraId) {
    return _quranData.where((aya) => aya.paraId == paraId.toString()).toList();
  }

  /// Get ayats by Surah and Para
  List<Aya> getAyatsBySurahAndPara(int surahId, int paraId) {
    return _quranData
        .where((aya) =>
            aya.surahId == surahId.toString() &&
            aya.paraId == paraId.toString())
        .toList();
  }

  List<RukoModel> _generateRukoFromMarkers(List<Aya> data) {
    List<RukoModel> list = [];
    int serial = 1;
    String? currentSurahId;
    String? currentParaId;
    int rukoInSurah = 0;
    int rukoInPara = 0;
    int ayatsSinceLastRuko = 0;

    for (var aya in data) {
      if (aya.ayatNumber == "0") continue; // Skip Bismillah

      if (currentSurahId != aya.surahId) {
        currentSurahId = aya.surahId;
        rukoInSurah = 0;
        // ayatsSinceLastRuko = 0; // Don't reset here, will be reset by hasRuko
      }

      if (currentParaId != aya.paraId) {
        currentParaId = aya.paraId;
        rukoInPara = 0;
      }

      ayatsSinceLastRuko++;

      if (aya.hasRuko) {
        rukoInSurah++;
        rukoInPara++;
        list.add(RukoModel(
          serial: serial++,
          surat: int.tryParse(aya.surahId ?? "0") ?? 0,
          rakuNumber: rukoInSurah,
          ayaAfterRako: aya.ayatNumberInt,
          place: "ع",
          ayaBeforeRako: aya.ayatNumberInt + 1, // Next aya start
          diff: ayatsSinceLastRuko,
          bottomNumber: rukoInPara,
        ));
        ayatsSinceLastRuko = 0;
      }
    }
    return list;
  }
}

/// Top-level function for compute to parse JSON
List<Aya> _parseQuranJson(String jsonString) {
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.map((json) => Aya.fromJson(json)).toList();
}
