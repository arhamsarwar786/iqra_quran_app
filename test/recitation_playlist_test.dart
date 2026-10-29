import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iqra/Models/aya_list_model.dart';
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:iqra/Services/recitation_playlist.dart';

// Verses per surah in Hafs numbering, as used by everyayah.com.
const hafsAyahCounts = [
  7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, //
  111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73,
  54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49,
  62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28,
  28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30, 20,
  15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6,
];

String file(int surah, int ayah) => RecitationPlaylist.fileUrl(surah, ayah);

void main() {
  late List<Aya> quran;

  setUpAll(() {
    final raw = File('assets/extraction/quran2026.json').readAsStringSync();
    quran = (json.decode(raw) as List)
        .map((e) => Aya.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  List<Aya> surah(int id) => quran.where((a) => a.surahId == '$id').toList();
  List<Aya> para(int id) => quran.where((a) => a.paraId == '$id').toList();

  test('every surah plays each recording once, in order, with Bismillah', () {
    for (var s = 1; s <= 114; s++) {
      final tracks = RecitationPlaylist.build(surah(s));
      final expected = <String>[
        // Bismillah opens every surah but At-Tawbah. For Al-Fatiha it is
        // Hafs verse 1, which is the same file.
        if (s != 9 && s != 1) file(1, 1),
        for (var a = 1; a <= hafsAyahCounts[s - 1]; a++) file(s, a),
      ];
      expect(tracks.map((t) => t.url).toList(), expected, reason: 'surah $s');
    }
  });

  test('every on-screen verse is highlighted by exactly one recording', () {
    for (var s = 1; s <= 114; s++) {
      final verses = surah(s).where((a) => a.ayatNumber != '0').toList();
      final tracks = RecitationPlaylist.build(surah(s));
      final highlighted = tracks.expand((t) => t.ayatIds).toList();
      expect(highlighted, verses.map((a) => a.ayatId).toList(),
          reason: 'surah $s');
    }
  });

  test('Al-Fatiha highlight matches what is recited', () {
    final fatiha = surah(1);
    final text = {for (final a in fatiha) a.ayatId: a.arabicText};
    final tracks = RecitationPlaylist.build(fatiha);

    expect(tracks.first.isBismillah, isTrue);
    expect(tracks.first.url, file(1, 1));
    expect(tracks.first.ayatIds, isEmpty);

    // Hafs 2 is "Alhamdu lillahi rabbil 'alamin".
    expect(tracks[1].url, file(1, 2));
    expect(text[tracks[1].ayatIds.single], contains('اَلْحَمْدُ لِلّٰهِ'));

    // Hafs 7 covers both of the app's verses 6 and 7.
    expect(tracks.last.url, file(1, 7));
    expect(tracks.last.ayatIds.length, 2);
    expect(tracks.last.ayatIds.map((id) => text[id]).join(' '),
        allOf(contains('صِرَاطَ'), contains('الضَّآلِّیْنَ')));
    expect(tracks.length, 7);
    expect(tracks.last.ayahLabel, '6–7');
    expect(tracks[1].ayahLabel, '1');
  });

  test('starting at verse 1 begins with its Bismillah', () {
    final baqarah = surah(2);
    final tracks = RecitationPlaylist.build(baqarah);
    final verse1 = baqarah.firstWhere((a) => a.ayatNumber == '1');
    final verse5 = baqarah.firstWhere((a) => a.ayatNumber == '5');

    expect(RecitationPlaylist.startIndexFor(tracks, verse1.ayatId), 0);
    expect(tracks[0].isBismillah, isTrue);
    expect(tracks[RecitationPlaylist.startIndexFor(tracks, verse5.ayatId)].url,
        file(2, 5));
    expect(RecitationPlaylist.startIndexFor(tracks, null), 0);
    expect(RecitationPlaylist.startIndexFor(tracks, 'missing'), 0);
  });

  test('At-Tawbah has no Bismillah', () {
    final tracks = RecitationPlaylist.build(surah(9));
    expect(tracks.where((t) => t.isBismillah), isEmpty);
    expect(tracks.first.url, file(9, 1));
  });

  test('a para crossing surahs inserts Bismillah once per new surah', () {
    // Para 1 runs from Al-Fatiha into Al-Baqarah and contains Al-Baqarah's
    // own Bismillah entry, which must not be played twice.
    final tracks = RecitationPlaylist.build(para(1));
    final bismillahSurahs =
        tracks.where((t) => t.isBismillah).map((t) => t.surahId).toList();
    expect(bismillahSurahs, [1, 2]);

    final baqarahStart =
        tracks.indexWhere((t) => t.surahId == 2 && t.isBismillah);
    expect(tracks[baqarahStart - 1].url, file(1, 7));
    expect(tracks[baqarahStart + 1].url, file(2, 1));
  });

  test('a filtered list without Bismillah entries still gets them', () {
    final withoutBismillah =
        surah(2).where((a) => a.ayatNumber != '0').toList();
    final tracks = RecitationPlaylist.build(withoutBismillah);
    expect(tracks.first.isBismillah, isTrue);
    expect(tracks[1].url, file(2, 1));
  });

  test('single-verse URLs used by search follow the same mapping', () {
    expect(QuranDataProvider.recitationUrl('1', '1'), file(1, 2));
    expect(QuranDataProvider.recitationUrl('1', '6'), file(1, 7));
    expect(QuranDataProvider.recitationUrl('1', '7'), file(1, 7));
    expect(QuranDataProvider.recitationUrl('2', '255'), file(2, 255));
    expect(QuranDataProvider.recitationUrl('114', '6'), file(114, 6));
  });
}
