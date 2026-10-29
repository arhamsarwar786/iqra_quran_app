import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'recitation_downloads.dart';
import 'recitation_playlist.dart';

/// When one word of a verse is recited.
class WordTiming {
  /// Index into [VerseRecitation.words].
  final int word;
  final int startMs;
  final int endMs;

  const WordTiming(this.word, this.startMs, this.endMs);
}

/// A verse's words with word-by-word timings for Mishary Rashid Alafasy's
/// recitation, and that recitation as a local audio file.
///
/// Words and timings both come from Quran.com, so every timing points at the
/// right word. To show the app's own text instead, use [timingsFor].
class VerseRecitation {
  final List<String> words;
  final List<WordTiming> timings;
  final File audio;
  final int durationMs;

  const VerseRecitation({
    required this.words,
    required this.timings,
    required this.audio,
    required this.durationMs,
  });

  static const String _api = 'https://api.quran.com/api/v4';

  // Quran.com's recitation id for Mishary Rashid Alafasy (murattal).
  static const int _alafasy = 7;

  // Quran.com's Indo-Pak text uses its own font's private-use glyphs for some
  // pause marks; no other font has them.
  static final RegExp _unsupported = RegExp('[-‎‏]');

  /// Loads the verse numbered [appAyah] in the app's data for [surahId].
  static Future<VerseRecitation> load(int surahId, int appAyah) async {
    final key = '$surahId:${RecitationPlaylist.hafsAyahFor(surahId, appAyah)}';

    final hafsAyah = RecitationPlaylist.hafsAyahFor(surahId, appAyah);
    final downloads = RecitationDownloads.instance;

    // Words and timings saved with a downloaded surah, else from Quran.com.
    List rawWords;
    List rawSegments;
    final saved = (await downloads.savedWords(surahId))?[key];
    if (saved != null) {
      rawWords = saved['words'] as List;
      rawSegments = saved['segments'] as List? ?? const [];
    } else {
      final responses = await Future.wait([
        _getJson(
          '$_api/verses/by_key/$key?words=true&word_fields=text_indopak',
        ),
        _getJson('$_api/recitations/$_alafasy/by_ayah/$key?fields=segments'),
      ]);
      rawWords = [
        for (final w in (responses[0]['verse']['words'] as List))
          if (w['char_type_name'] == 'word') [w['position'], w['text_indopak']],
      ];
      rawSegments =
          ((responses[1]['audio_files'] as List).first['segments'] as List?) ??
          const [];
    }

    // Positions are 1-based and also count the verse-end marker, which is
    // not a recited word.
    final positionToWord = <int, int>{};
    final words = <String>[];
    for (final w in rawWords) {
      final text = (w[1] as String? ?? '').replaceAll(_unsupported, '').trim();
      if (text.isEmpty) continue;
      positionToWord[(w[0] as num).toInt()] = words.length;
      words.add(text);
    }

    // Each segment is [index, word position, start ms, end ms].
    final timings = <WordTiming>[];
    for (final s in rawSegments) {
      final segment = (s as List).cast<num>();
      if (segment.length < 4) continue;
      final word = positionToWord[segment[1].toInt()];
      if (word == null) continue;
      timings.add(WordTiming(word, segment[2].toInt(), segment[3].toInt()));
    }
    timings.sort((a, b) => a.startMs.compareTo(b.startMs));

    // Quran.com serves the same recordings as everyayah.com, so a
    // downloaded recitation is used as is.
    final recordingUrl = RecitationPlaylist.fileUrl(surahId, hafsAyah);
    final audio =
        downloads.savedFile(recordingUrl) ??
        await _download(
          recordingUrl,
          'recitation_${key.replaceAll(':', '_')}.mp3',
        );
    final durationMs = timings.isEmpty ? 0 : timings.last.endMs;

    if (words.isEmpty) {
      throw const HttpException('No words found for this verse');
    }
    return VerseRecitation(
      words: words,
      timings: timings,
      audio: audio,
      durationMs: durationMs,
    );
  }

  /// [timings] moved onto [otherWords], the same verse as the app writes it,
  /// so a video can show exactly the text the app shows.
  ///
  /// The app's text has pause marks and the verse number as separate
  /// tokens, which are never recited, and splits a few words differently
  /// from Quran.com. When the recited words line up one to one they are
  /// paired in order; otherwise each word is matched by where its letters
  /// fall in the verse.
  List<WordTiming> timingsFor(List<String> otherWords) {
    final recited = [
      for (var i = 0; i < otherWords.length; i++)
        if (_letters(otherWords[i]).isNotEmpty) i,
    ];
    if (recited.isEmpty || timings.isEmpty) return const [];
    if (recited.length == words.length) {
      return [
        for (final t in timings)
          WordTiming(recited[t.word], t.startMs, t.endMs),
      ];
    }

    List<int> starts(List<int> lengths) {
      final result = <int>[0];
      for (final length in lengths) {
        result.add(result.last + length);
      }
      return result;
    }

    // Letter counts, at least 1 so no word has zero width.
    final ownLengths = [
      for (final w in words) _letters(w).length.clamp(1, 999),
    ];
    final otherLengths = [
      for (final i in recited) _letters(otherWords[i]).length.clamp(1, 999),
    ];
    final ownStarts = starts(ownLengths);
    final otherStarts = starts(otherLengths);
    // Positions in the other text, scaled to this text's letter count.
    final scale = ownStarts.last / otherStarts.last;
    final timingOf = {for (final t in timings) t.word: t};

    final result = <WordTiming>[];
    for (var k = 0; k < recited.length; k++) {
      final from = otherStarts[k] * scale;
      final to = otherStarts[k + 1] * scale;
      final middle = (from + to) / 2;
      var own = 0;
      while (own < words.length - 1 && ownStarts[own + 1] <= middle) {
        own++;
      }
      final timing = timingOf[own];
      if (timing == null) continue;
      // Share the word's time between the words it was split into.
      double share(double at) =>
          ((at - ownStarts[own]) / ownLengths[own]).clamp(0.0, 1.0);
      final span = timing.endMs - timing.startMs;
      result.add(
        WordTiming(
          recited[k],
          timing.startMs + (span * share(from)).round(),
          timing.startMs + (span * share(to)).round(),
        ),
      );
    }
    result.sort((a, b) => a.startMs.compareTo(b.startMs));
    return result;
  }

  // The base letters of [word], with the different ways Indo-Pak and other
  // scripts write the same letter folded together, and every vowel, pause
  // mark, digit and bracket dropped.
  static String _letters(String word) {
    const folded = {
      0x0622: 0x0627, 0x0623: 0x0627, 0x0625: 0x0627, 0x0671: 0x0627, // alif
      0x0649: 0x064A, 0x06CC: 0x064A, 0x06D2: 0x064A, 0x0626: 0x064A, // ya
      0x06A9: 0x0643, // kaf
      0x0629: 0x0647, 0x06C1: 0x0647, 0x06BE: 0x0647, 0x06C3: 0x0647, // ha
      0x0624: 0x0648, // waw
    };
    final buffer = StringBuffer();
    for (final rune in word.runes) {
      final c = folded[rune] ?? rune;
      final isLetter =
          (c >= 0x0621 && c <= 0x063A) ||
          (c >= 0x0641 && c <= 0x064A) ||
          (c >= 0x0671 && c <= 0x06D3) ||
          (c >= 0x06FA && c <= 0x06FC);
      if (isLetter) buffer.writeCharCode(c);
    }
    return buffer.toString();
  }

  static Future<Map<String, dynamic>> _getJson(String url) async {
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw HttpException(
        'Request failed (${response.statusCode})',
        uri: Uri.parse(url),
      );
    }
    return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<File> _download(String url, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    if (await file.exists() && await file.length() > 0) return file;
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) {
      throw HttpException(
        'Audio download failed (${response.statusCode})',
        uri: Uri.parse(url),
      );
    }
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
  }
}
