import '../Models/aya_list_model.dart';

/// One audio file in the recitation queue and the verses it covers.
class RecitationTrack {
  final int surahId;

  /// Verse number as numbered in the app's data. 0 means Bismillah.
  final int ayahNumber;

  /// `ayatId`s of the on-screen verses recited in this file. Empty for
  /// Bismillah, which is drawn in the surah header rather than as a verse.
  final List<String> ayatIds;

  final String url;

  const RecitationTrack({
    required this.surahId,
    required this.ayahNumber,
    required this.ayatIds,
    required this.url,
  });

  bool get isBismillah => ayahNumber == 0;

  /// True when [url] points at a downloaded file rather than the server.
  bool get isLocal => url.startsWith('file:');

  RecitationTrack withUrl(String url) => RecitationTrack(
        surahId: surahId,
        ayahNumber: ayahNumber,
        ayatIds: ayatIds,
        url: url,
      );

  /// Verse number(s) for display, e.g. "5", or "6–7" when one recording
  /// covers two on-screen verses.
  String get ayahLabel => ayatIds.length > 1
      ? '$ayahNumber–${ayahNumber + ayatIds.length - 1}'
      : '$ayahNumber';
}

/// Maps the app's verse list onto everyayah.com recitation files.
///
/// everyayah.com uses Hafs (Kufan) numbering. The app's data matches it for
/// every surah except Al-Fatiha, where it does not count Bismillah as a verse
/// and splits Hafs verse 7 into two:
///
///   app 1..5  -> Hafs 2..6 (Hafs 1 is Bismillah)
///   app 6, 7  -> Hafs 7 (a single recording)
class RecitationPlaylist {
  static const String reciterName = 'Mishary Rashid Alafasy';
  static const String _baseUrl = 'https://everyayah.com/data/Alafasy_128kbps';

  static String fileUrl(int surahId, int hafsAyah) {
    final s = surahId.toString().padLeft(3, '0');
    final a = hafsAyah.toString().padLeft(3, '0');
    return fileUrlForName('$s$a.mp3');
  }

  /// Server URL of a recording by its file name, e.g. `002255.mp3`.
  static String fileUrlForName(String name) => '$_baseUrl/$name';

  /// Recording that holds Bismillah on its own (Al-Fatiha, Hafs verse 1).
  static String get bismillahUrl => fileUrl(1, 1);

  /// Hafs verse number of the recording for an app verse.
  static int hafsAyahFor(int surahId, int appAyah) {
    if (surahId == 1) return appAyah >= 6 ? 7 : appAyah + 1;
    return appAyah;
  }

  static String urlForAyah(int surahId, int appAyah) =>
      fileUrl(surahId, hafsAyahFor(surahId, appAyah));

  /// Builds the queue for [ayats] in order. Bismillah is played before verse 1
  /// of every surah except At-Tawbah. Any Bismillah entries already in the list
  /// (ayatNumber "0") are ignored so it is never played twice.
  static List<RecitationTrack> build(List<Aya> ayats) {
    final verses = ayats.where((a) => a.ayatNumberInt > 0).toList();
    final tracks = <RecitationTrack>[];

    for (var i = 0; i < verses.length; i++) {
      final aya = verses[i];
      final surahId = int.tryParse(aya.surahId ?? '') ?? 0;
      if (surahId < 1 || surahId > 114) continue;
      final ayahNumber = aya.ayatNumberInt;

      if (ayahNumber == 1 && surahId != 9) {
        tracks.add(RecitationTrack(
          surahId: surahId,
          ayahNumber: 0,
          ayatIds: const [],
          url: bismillahUrl,
        ));
      }

      final ids = <String>[if (aya.ayatId != null) aya.ayatId!];

      // Al-Fatiha 6 and 7 share one recording: highlight both, play it once.
      if (surahId == 1 && ayahNumber == 6 && i + 1 < verses.length) {
        final next = verses[i + 1];
        if (next.surahId == aya.surahId && next.ayatNumberInt == 7) {
          if (next.ayatId != null) ids.add(next.ayatId!);
          i++;
        }
      }

      tracks.add(RecitationTrack(
        surahId: surahId,
        ayahNumber: ayahNumber,
        ayatIds: ids,
        url: urlForAyah(surahId, ayahNumber),
      ));
    }
    return tracks;
  }

  /// Identifies the recitation of [tracks], so a screen can tell whether the
  /// queue playing now is its own.
  static String keyOf(List<RecitationTrack> tracks) => tracks.isEmpty
      ? ''
      : '${tracks.first.url}|${tracks.last.url}|${tracks.length}';

  /// Queue index to start at so that [ayatId] is recited. Starting at verse 1
  /// begins with its Bismillah.
  static int startIndexFor(List<RecitationTrack> tracks, String? ayatId) {
    if (ayatId == null) return 0;
    final index = tracks.indexWhere((t) => t.ayatIds.contains(ayatId));
    if (index <= 0) return 0;
    final previous = tracks[index - 1];
    if (previous.isBismillah && previous.surahId == tracks[index].surahId) {
      return index - 1;
    }
    return index;
  }
}
