import 'dart:async';
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
  final Map<String, int> _paraRukuCounts = {};
  bool _isLoading = false;
  bool _isLoaded = false;

  Aya? _currentRandomAyat;
  Timer? _backgroundTimer;

  List<Aya> get quranData => _quranData;
  List<ParaMetadata> get paraMetadata => _paraMetadata;
  List<RukoModel> get rukoData => _rukoData;
  List<SajdaModel> get sajdaData => _sajdaData;
  List<SurahMetadata> get surahMetadata => _surahMetadata;
  Map<String, int> get paraAyatCounts => _paraAyatCounts;
  Map<String, int> get paraRukuCounts => _paraRukuCounts;
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  Aya? get currentRandomAyat => _currentRandomAyat;

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
      debugPrint('Quran Data Bank: Loading surah.json...');
      final String surahMetaJsonString =
          await rootBundle.loadString('assets/extraction/surah.json');
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

      // Calculate para ruku counts
      _paraRukuCounts.clear();
      for (var ruko in _rukoData) {
        // Get the para ID for this ruko by finding the ayat
        var ayat = _quranData.firstWhere(
          (aya) =>
              aya.surahId == ruko.surat.toString() &&
              aya.ayatNumberInt == ruko.ayaAfterRako,
          orElse: () => Aya(ayatNumber: "0", arabicText: ""),
        );
        String paraId = ayat.paraId?.toString() ?? "0";
        if (paraId != "0") {
          _paraRukuCounts[paraId] = (_paraRukuCounts[paraId] ?? 0) + 1;
        }
      }
      debugPrint(
          'Quran Data Bank: Calculated ruku counts for ${_paraRukuCounts.length} paras.');

      _isLoaded = true;
      _startBackgroundVerseTimer();
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
        .where((aya) => (int.tryParse(aya.surahId ?? "0") ?? 0) == surahId)
        .toList();
  }

  /// Get Surah metadata by ID
  SurahMetadata? getSurahMetadata(int surahId) {
    if (_surahMetadata.isEmpty) return null;
    try {
      return _surahMetadata.firstWhere(
        (element) => (int.tryParse(element.index) ?? 0) == surahId,
        orElse: () => _surahMetadata.first,
      );
    } catch (e) {
      if (_surahMetadata.isNotEmpty &&
          surahId > 0 &&
          surahId <= _surahMetadata.length) {
        return _surahMetadata[surahId - 1];
      }
      return null;
    }
  }

  /// Get ayats for a specific Para (Juz)
  List<Aya> getAyatsByPara(int paraId) {
    return _quranData
        .where((aya) => (int.tryParse(aya.paraId ?? "0") ?? 0) == paraId)
        .toList();
  }

  /// Get ayats by Surah and Para
  List<Aya> getAyatsBySurahAndPara(int surahId, int paraId) {
    return _quranData.where((aya) {
      int sId = int.tryParse(aya.surahId ?? "0") ?? 0;
      int pId = int.tryParse(aya.paraId ?? "0") ?? 0;
      return sId == surahId && pId == paraId;
    }).toList();
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

  /// Get a random small ayat (length < 150 characters)
  Aya? getRandomSmallAyat() {
    if (_quranData.isEmpty) return null;

    // Filter for small ayats, excluding Bismillah (often ayat 0) if present
    var smallAyats = _quranData.where((aya) {
      return aya.arabicText.length < 150 &&
          aya.ayatNumber != "0" &&
          aya.surahId != null &&
          aya.paraId != null;
    }).toList();

    if (smallAyats.isEmpty) {
      // Fallback to any random ayat if no small ones found (unlikely)
      smallAyats = _quranData;
    }

    // Return a random ayat
    return smallAyats[DateTime.now().microsecond % smallAyats.length];
  }

  void _startBackgroundVerseTimer() {
    if (_backgroundTimer != null) return;

    // Set initial random verse
    _currentRandomAyat = getRandomSmallAyat();

    _backgroundTimer = Timer.periodic(const Duration(seconds: 150), (timer) {
      _currentRandomAyat = getRandomSmallAyat();
      notifyListeners();
    });
  }

  /// Normalizes Arabic text by removing diacritics
  String _normalizeArabic(String text) {
    // Regular expression for Arabic diacritics
    final diacritics = RegExp(
        r"[\u064B-\u0652\u06D6-\u06ED\u06DF-\u06E4\u06E7-\u06E8\u06EA-\u06EB]");
    return text.replaceAll(diacritics, "");
  }

  /// Search Quran based on filters with normalization
  List<Aya> searchQuran(String query,
      {bool searchArabic = true,
      bool searchTranslation = true,
      bool searchTafseer = true}) {
    if (query.isEmpty) return [];

    final normalizedQuery = _normalizeArabic(query.toLowerCase().trim());
    final lowercaseQuery = query.toLowerCase().trim();

    return _quranData.where((aya) {
      bool matches = false;

      if (searchArabic) {
        // Match against normalized Arabic text or withoutArab field
        final normalizedArabic = _normalizeArabic(aya.arabicText);
        if (normalizedArabic.contains(normalizedQuery) ||
            (aya.withoutArab?.contains(lowercaseQuery) ?? false)) {
          matches = true;
        }
      }

      if (!matches && searchTranslation) {
        if ((aya.tarjumaIrfan?.toLowerCase().contains(lowercaseQuery) ??
                false) ||
            (aya.tarjumaHind?.toLowerCase().contains(lowercaseQuery) ??
                false) ||
            (aya.tarjumaPak?.toLowerCase().contains(lowercaseQuery) ?? false)) {
          matches = true;
        }
      }

      if (!matches && searchTafseer) {
        if (aya.withoutHtmlTafseer?.toLowerCase().contains(lowercaseQuery) ??
            false) {
          matches = true;
        }
      }

      return matches;
    }).toList();
  }
}

/// Top-level function for compute to parse JSON
List<Aya> _parseQuranJson(String jsonString) {
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.map((json) => Aya.fromJson(json)).toList();
}
