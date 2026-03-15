import 'package:bm25/bm25.dart';
import '../Models/aya_list_model.dart';

/// A professional search engine powered by the 'bm25' package.
class QuranSearchEngine {
  final List<Aya> data;
  final String Function(String) normalize;
  
  // BM25 instances per field
  BM25? _arabicBM25;
  BM25? _translationBM25;
  BM25? _tafseerBM25;

  QuranSearchEngine(this.data, {required this.normalize});

  /// Builds the search index for all fields asynchronously using the BM25 package.
  Future<void> buildIndex() async {
    final List<String> arabicDocs = [];
    final List<String> translationDocs = [];
    final List<String> tafseerDocs = [];

    for (var aya in data) {
      arabicDocs.add(normalize(aya.arabicText.toLowerCase()));
      translationDocs.add(normalize((aya.tarjumaIrfan ?? "").toLowerCase()));
      tafseerDocs.add(normalize((aya.withoutHtmlTafseer ?? "").toLowerCase()));
    }

    await buildIndexFromDocs(arabicDocs, translationDocs, tafseerDocs);
  }

  /// Builds the search index from pre-normalized documents.
  Future<void> buildIndexFromDocs(
      List<String> arabicDocs, List<String> translationDocs, List<String> tafseerDocs) async {
    // Initialize indices sequentially with small yields to prevent memory spikes
    // and keep the UI thread responsive during construction.
    _arabicBM25 = await BM25.build(arabicDocs);
    await Future.delayed(const Duration(milliseconds: 100)); // Yield
    
    _translationBM25 = await BM25.build(translationDocs);
    await Future.delayed(const Duration(milliseconds: 100)); // Yield
    
    _tafseerBM25 = await BM25.build(tafseerDocs);
  }

  /// Performs a ranked search asynchronously across enabled fields.
  Future<List<SearchResult>> search(String query, {
    bool searchArabic = true,
    bool searchTranslation = true,
    bool searchTafseer = true,
  }) async {
    final String normalizedQuery = normalize(query.toLowerCase());
    if (normalizedQuery.isEmpty) return [];

    final Map<int, double> aggregatedScores = {};

    Future<void> addFieldScores(BM25? engine, double weight) async {
      if (engine == null) return;
      final results = await engine.search(normalizedQuery);
      for (final res in results) {
        if (res.score > 0) {
          final int docId = res.doc.id;
          aggregatedScores[docId] = (aggregatedScores[docId] ?? 0) + (res.score * weight);
        }
      }
    }

    await Future.wait([
      if (searchArabic) addFieldScores(_arabicBM25, 1.3),
      if (searchTranslation) addFieldScores(_translationBM25, 1.0),
      if (searchTafseer) addFieldScores(_tafseerBM25, 1.0),
    ]);

    final results = aggregatedScores.entries
        .map((e) => SearchResult(data[e.key], e.value))
        .toList();
    
    // Sort by descending score
    results.sort((a, b) => b.score.compareTo(a.score));
    
    return results;
  }
}

class SearchResult {
  final Aya aya;
  final double score;
  SearchResult(this.aya, this.score);
}
