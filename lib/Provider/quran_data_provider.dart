import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../Models/aya_list_model.dart';
import '../Models/para_metadata_model.dart';
import '../Models/ruko_model.dart';
import '../Models/sajda_model.dart';
import '../Models/surah_metadata_model.dart';
import '../Services/search_engine.dart';
import '../Services/analytics_service.dart';

// ─── Top-level compute functions (must be top-level for isolate use) ──────────

/// Decodes raw UTF-8 bytes → String in an isolate (avoids blocking UI thread).
String _bytesToString(Uint8List bytes) => utf8.decode(bytes);

/// Parses the full JSON string and returns a List<Aya> in an isolate.
/// Using compute() here is safe — Flutter's compute() uses Isolate.run()
/// internally which supports transferring arbitrary Dart objects.
List<Aya> _parseQuranJson(String jsonString) {
  final List<dynamic> raw = json.decode(jsonString) as List<dynamic>;
  return raw
      .map((j) => Aya.fromJson(j as Map<String, dynamic>))
      .toList(growable: false);
}

/// Generates RukoModel list from ayat list in an isolate.
List<RukoModel> _generateRukuIsolate(List<Aya> data) {
  final List<RukoModel> list = [];
  int serial = 1;
  String? curSurah;
  String? curPara;
  int rukoInSurah = 0;
  int rukoInPara = 0;
  int ayatsSinceLast = 0;

  for (final aya in data) {
    if (aya.ayatNumber == '0') continue;
    if (curSurah != aya.surahId) {
      curSurah = aya.surahId;
      rukoInSurah = 0;
    }
    if (curPara != aya.paraId) {
      curPara = aya.paraId;
      rukoInPara = 0;
    }
    ayatsSinceLast++;
    if (aya.hasRuko) {
      rukoInSurah++;
      rukoInPara++;
      list.add(RukoModel(
        serial: serial++,
        surat: int.tryParse(aya.surahId ?? '0') ?? 0,
        rakuNumber: rukoInSurah,
        ayaAfterRako: aya.ayatNumberInt,
        place: 'ع',
        ayaBeforeRako: aya.ayatNumberInt + 1,
        diff: ayatsSinceLast,
        bottomNumber: rukoInPara,
      ));
      ayatsSinceLast = 0;
    }
  }
  return list;
}

/// Data structure for pre-normalized search documents
class IndexData {
  final List<String> arabicDocs;
  final List<String> translationDocs;
  final List<String> tafseerDocs;
  IndexData(this.arabicDocs, this.translationDocs, this.tafseerDocs);
}

/// Normalizes all search fields in a background isolate
IndexData _prepareIndexData(List<Aya> data) {
  final List<String> arabicDocs = [];
  final List<String> translationDocs = [];
  final List<String> tafseerDocs = [];

  for (final aya in data) {
    arabicDocs.add(QuranDataProvider.normalizeArabic(aya.arabicText.toLowerCase()));
    translationDocs.add(QuranDataProvider.normalizeArabic((aya.tarjumaIrfan ?? "").toLowerCase()));
    tafseerDocs.add(QuranDataProvider.normalizeArabic((aya.withoutHtmlTafseer ?? "").toLowerCase()));
  }
  return IndexData(arabicDocs, translationDocs, tafseerDocs);
}

// ─── Provider ─────────────────────────────────────────────────────────────────

class QuranDataProvider extends ChangeNotifier {
  // Singleton
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

  /// 0.0 – 1.0 fine-grained loading progress (drives the splash-screen bar).
  double _loadProgress = 0.0;

  QuranSearchEngine? _searchEngine;
  Aya? _currentRandomAyat;
  Timer? _rotationTimer;

  // ── Initialization Logic for Splash ──
  double _simulatedProgress = 0.0;
  Timer? _splashTicker;

  // ── Getters ────────────────────────────────────────────────────
  List<Aya> get quranData => _quranData;
  List<ParaMetadata> get paraMetadata => _paraMetadata;
  List<RukoModel> get rukoData => _rukoData;
  List<SajdaModel> get sajdaData => _sajdaData;
  List<SurahMetadata> get surahMetadata => _surahMetadata;
  Map<String, int> get paraAyatCounts => _paraAyatCounts;
  Map<String, int> get paraRukuCounts => _paraRukuCounts;
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  double get loadProgress => _loadProgress;
  double get displayProgress => _simulatedProgress;
  Aya? get currentRandomAyat => _currentRandomAyat;

  // ── Main load entry-point ──────────────────────────────────────

  /// Orchestrates the entire app startup sequence.
  /// Moves logic out of SplashScreen and into the Provider.
  Future<void> appInitialize() async {
    if (_isLoaded || _isLoading) return;
    
    _simulatedProgress = 0.0;
    _loadProgress = 0.0;
    
    // Start the "Smooth ticker" for the UI
    _splashTicker?.cancel();
    _splashTicker = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (_isLoaded) {
        timer.cancel();
        return;
      }
      
      // Auto-step: advances by ~0.4% every 40ms (reaches 100% in ~10s if loading is slow)
      double next = _simulatedProgress + 0.004;
      
      // Sync with real progress if real progress jumps ahead
      if (_loadProgress > next) {
        next = _loadProgress;
      }
      
      // Cap at 99% until fully loaded
      if (next > 0.99) next = 0.99;
      
      if (next > _simulatedProgress) {
        _simulatedProgress = next;
        notifyListeners();
      }
    });

    await loadQuranData();
  }

  /// Loads all Quran data.  On failure it auto-releases memory and retries
  /// up to [maxRetries] times before silently continuing so the app can
  /// still open (Quran screens will just be empty rather than crashing).
  Future<void> loadQuranData({int maxRetries = 3}) async {
    if (_isLoaded || _isLoading) return;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      _isLoading = true;
      _loadProgress = 0.0;
      notifyListeners();

      try {
        await _doLoad();
        return; // success
      } catch (e) {
        debugPrint('QuranData [attempt $attempt/$maxRetries]: ERROR – $e');
        _clearData(); // free memory before next attempt
        _isLoading = false;
        notifyListeners();

        if (attempt < maxRetries) {
          // Brief pause before retrying — gives the GC time to reclaim memory
          await Future.delayed(Duration(milliseconds: 400 * attempt));
        }
      }
    }

    // All attempts failed — app continues without Quran data
    debugPrint('QuranData: All $maxRetries attempts failed. '
        'Quran screens will be empty.');
    _isLoading = false;
    _loadProgress = 0.0;
    notifyListeners();
  }

  Future<void> _doLoad() async {
    debugPrint('QuranData: Reading quran2026.json bytes…');

    // ── 1. Read as bytes (non-blocking, doesn't hold 2 copies) ───
    final ByteData byteData =
        await rootBundle.load('assets/extraction/quran2026.json');
    _setProgress(0.08);

    // ── 2. Decode bytes → String in background isolate ───────────
    final String jsonString =
        await compute(_bytesToString, byteData.buffer.asUint8List());
    _setProgress(0.18);
    debugPrint('QuranData: JSON = ${jsonString.length} chars');

    // ── 3. Parse JSON → List<Aya> in background isolate ──────────
    _setProgress(0.25);
    _quranData = await compute(_parseQuranJson, jsonString);
    _setProgress(0.50);
    debugPrint('QuranData: Parsed ${_quranData.length} ayats');

    // ── 4. Load small metadata files ─────────────────────────────
    _setProgress(0.55);
    final String paraJson =
        await rootBundle.loadString('assets/extraction/para.json');
    final List<dynamic> paraList = json.decode(paraJson) as List<dynamic>;
    _paraMetadata = paraList
        .map((j) => ParaMetadata.fromJson(j as Map<String, dynamic>))
        .toList(growable: false);
    _setProgress(0.62);

    _rukoData = await compute(_generateRukuIsolate, _quranData);
    _setProgress(0.72);

    final String sajdaJson =
        await rootBundle.loadString('assets/extraction/sajda.json');
    _sajdaData = await compute(_parseSajdaIsolate, sajdaJson);
    _setProgress(0.78);

    final String surahJson =
        await rootBundle.loadString('assets/extraction/surah.json');
    _surahMetadata = await compute(_parseSurahIsolate, surahJson);
    _setProgress(0.85);

    // ── 5. Build fast lookup counts ───────────────────────────────
    _buildCounts();
    _setProgress(0.95);

    // ── 6. Done ───────────────────────────────────────────────────
    _isLoaded = true;
    _simulatedProgress = 1.0;
    _splashTicker?.cancel();
    
    _currentRandomAyat = _pickDailyAyat();
    _setProgress(1.0);
    _isLoading = false;

    // Start rotation timer
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(const Duration(seconds: 200), (timer) {
      rotateRandomAyat();
    });

    notifyListeners();
    debugPrint('QuranData: Ready and auto-rotation started.');
  }

  void _setProgress(double value) {
    _loadProgress = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void _buildCounts() {
    _paraAyatCounts.clear();
    for (final aya in _quranData) {
      final String p = aya.paraId?.toString() ?? '0';
      if (p != '0') _paraAyatCounts[p] = (_paraAyatCounts[p] ?? 0) + 1;
    }

    // Fast lookup map: "surahId|ayatNum" → paraId
    final Map<String, String> lookup = {};
    for (final aya in _quranData) {
      if (aya.surahId != null && aya.paraId != null) {
        lookup['${aya.surahId}|${aya.ayatNumberInt}'] = aya.paraId!;
      }
    }

    _paraRukuCounts.clear();
    for (final ruko in _rukoData) {
      final String p =
          lookup['${ruko.surat}|${ruko.ayaAfterRako}'] ?? '0';
      if (p != '0') _paraRukuCounts[p] = (_paraRukuCounts[p] ?? 0) + 1;
    }
  }

  /// Builds the BM25 search index in a background isolate.
  /// This is heavy and should be called after landing on Home.
  Future<void> buildSearchIndex() async {
    // Temporarily disabled for performance testing
    return;
    /*
    if (_quranData.isEmpty || _searchEngine != null) return;
    try {
      debugPrint('QuranSearch: Building BM25 index…');
      
      // Phase 1: Heavy normalization in background isolate
      final IndexData docs = await compute(_prepareIndexData, _quranData);
      
      _searchEngine =
          QuranSearchEngine(_quranData, normalize: normalizeArabic);
          
      // Phase 2: BM25 index construction
      await _searchEngine!.buildIndexFromDocs(
        docs.arabicDocs, 
        docs.translationDocs, 
        docs.tafseerDocs
      );
      
      debugPrint('QuranSearch: Index ready.');
      notifyListeners();
    } catch (e) {
      debugPrint('QuranSearch: Index build failed – $e');
      _searchEngine = null;
    }
    */
  }

  // ── Memory management ──────────────────────────────────────────

  /// Clears all parsed data and resets state.
  /// Called automatically between retry attempts, or call manually
  /// from a screen's dispose() if you want to free RAM.
  void releaseMemory() {
    _clearData();
    notifyListeners();
    debugPrint('QuranData: Memory released.');
  }

  void _clearData() {
    _quranData = [];
    _rukoData = [];
    _sajdaData = [];
    _paraMetadata = [];
    _surahMetadata = [];
    _paraAyatCounts.clear();
    _paraRukuCounts.clear();
    _searchEngine = null;
    _currentRandomAyat = null;
    _rotationTimer?.cancel();
    _splashTicker?.cancel();
    _isLoaded = false;
    _isLoading = false;
    _loadProgress = 0.0;
    _simulatedProgress = 0.0;
  }

  void rotateRandomAyat() {
    if (_quranData.isEmpty) return;
    var small = _quranData
        .where((a) =>
            a.arabicText.length < 200 && // Slightly larger limit for variety
            a.ayatNumber != '0' &&
            a.surahId != null &&
            a.paraId != null)
        .toList();
    if (small.isEmpty) small = _quranData;
    _currentRandomAyat = small[Random().nextInt(small.length)];
    notifyListeners();
  }

  List<Aya> getAyatsBySurah(int surahId) => _quranData
      .where((a) => (int.tryParse(a.surahId ?? '0') ?? 0) == surahId)
      .toList();

  SurahMetadata? getSurahMetadata(int surahId) {
    if (_surahMetadata.isEmpty) return null;
    try {
      return _surahMetadata.firstWhere(
        (e) => (int.tryParse(e.index) ?? 0) == surahId,
        orElse: () => _surahMetadata.first,
      );
    } catch (_) {
      return (surahId > 0 && surahId <= _surahMetadata.length)
          ? _surahMetadata[surahId - 1]
          : null;
    }
  }

  List<Aya> getAyatsByPara(int paraId) => _quranData
      .where((a) => (int.tryParse(a.paraId ?? '0') ?? 0) == paraId)
      .toList();

  List<Aya> getAyatsBySurahAndPara(int surahId, int paraId) =>
      _quranData.where((a) {
        final int s = int.tryParse(a.surahId ?? '0') ?? 0;
        final int p = int.tryParse(a.paraId ?? '0') ?? 0;
        return s == surahId && p == paraId;
      }).toList();

  int getGlobalAyatIndex(String? surahIdStr, String? ayatNumberStr) {
    final int surahId = int.tryParse(surahIdStr ?? '1') ?? 1;
    int ayatNumber = int.tryParse(ayatNumberStr ?? '1') ?? 1;
    if (surahId < 1 || surahId > 114) return 1;

    int globalIndex = 0;
    for (int i = 0; i < surahId - 1; i++) {
      if (i < _surahMetadata.length) {
        globalIndex += _surahMetadata[i].surahTotalAyaat;
      }
    }
    int effectiveAyah = ayatNumber == 0 ? 1 : ayatNumber;
    if (surahId <= _surahMetadata.length) {
      effectiveAyah = effectiveAyah
          .clamp(1, _surahMetadata[surahId - 1].surahTotalAyaat);
    }
    return globalIndex + effectiveAyah;
  }

  Future<List<Aya>> searchQuran(
    String query, {
    bool searchArabic = true,
    bool searchTranslation = true,
    bool searchTafseer = true,
  }) async {
    if (query.trim().isEmpty) return [];
    
    // Temporarily disabled complex search for performance testing
    final String q = query.trim().toLowerCase();
    final match = RegExp(r'^(\d+)(?::|\ +)(\d+)$').firstMatch(q);
    if (match != null) {
      return _quranData
          .where((a) =>
              a.surahId == match.group(1) &&
              a.ayatNumber == match.group(2))
          .toList();
    }
    
    return [];
  }

  // ── Internal helpers ───────────────────────────────────────────

  Aya? _pickDailyAyat() {
    if (_quranData.isEmpty) return null;
    var small = _quranData
        .where((a) =>
            a.arabicText.length < 200 &&
            a.ayatNumber != '0' &&
            a.surahId != null &&
            a.paraId != null)
        .toList();
    if (small.isEmpty) small = _quranData;
    return small[Random().nextInt(small.length)];
  }

  static final _diacriticsRx = RegExp(
      r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u06DF-\u06E4\u06E7-\u06E8\u06EA-\u06EB]');
  static final _alifRx = RegExp(r'[\u0622\u0623\u0625\u0671]');
  static final _yehRx = RegExp(r'[\u06CC\u06D2]');
  static final _ornamentRx = RegExp(r'[\uEFB0-\uEFFF]');
  static final _zwRx = RegExp(r'[\u200B-\u200D\uFEFF]');
  static final _verseNumRx = RegExp(r'\(\d+\)');
  static final _digitsRx = RegExp(r'[0-9\u0660-\u0669]');

  static String normalizeArabic(String text) {
    if (text.isEmpty) return '';
    return text
        .replaceAll(_diacriticsRx, '')
        .replaceAll(_alifRx, '\u0627')
        .replaceAll('\u0629', '\u0647')
        .replaceAll('\u0649', '\u064A')
        .replaceAll(_yehRx, '\u064A')
        .replaceAll('\u06A9', '\u0643')
        .replaceAll(_ornamentRx, '')
        .replaceAll(_zwRx, '')
        .replaceAll(_verseNumRx, '')
        .replaceAll(_digitsRx, '')
        .trim();
  }
}

// ── Background Parse Helpers ──────────
List<SajdaModel> _parseSajdaIsolate(String json) => sajdaModelFromJson(json);
List<SurahMetadata> _parseSurahIsolate(String json) => surahMetadataFromJson(json);
