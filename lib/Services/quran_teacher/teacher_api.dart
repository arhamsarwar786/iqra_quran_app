import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Where the Quran teacher service runs: the live server by default. Point
/// it elsewhere with `--dart-define=TEACHER_API=…`, for example
/// `http://10.0.2.2:8000` for a server on this computer from the emulator.
const String teacherApiBase = String.fromEnvironment(
  'TEACHER_API',
  defaultValue: 'http://194.163.191.107:8090',
);

/// Where one word sits in the reciter's recording of its ayah.
class LessonWord {
  /// Position in the ayah's `arabicText.trim().split(RegExp(r'\s+'))`.
  final int token;
  final Duration start;
  final Duration end;

  const LessonWord(this.token, this.start, this.end);

  Duration get length => end - start;
}

class Lesson {
  final String recordingUrl;

  /// Only the words that are recited, in order: pause marks and the verse
  /// number are left out.
  final List<LessonWord> words;

  const Lesson(this.recordingUrl, this.words);
}

class TeacherIssue {
  /// "silence", "word", "madd" or "ghunnah".
  final String kind;
  final String message;

  const TeacherIssue(this.kind, this.message);
}

class WordCheck {
  final bool correct;
  final String heard;
  final List<TeacherIssue> issues;
  final int? durationMs;
  final int? referenceMs;

  const WordCheck({
    required this.correct,
    required this.heard,
    required this.issues,
    this.durationMs,
    this.referenceMs,
  });
}

class TeacherException implements Exception {
  final String message;
  const TeacherException(this.message);

  @override
  String toString() => message;
}

/// The Quran teacher service: each word's place in the reciter's recording,
/// and checking a word the learner recited.
class TeacherApi {
  static Future<Lesson> lesson(int surah, int ayah) async {
    final response = await _send(() => http
        .get(Uri.parse('$teacherApiBase/v1/teacher/lesson/$surah/$ayah'))
        .timeout(const Duration(seconds: 15)));
    final data = _json(response);
    return Lesson(
      data['recording_url'] as String,
      [
        for (final w in data['words'] as List)
          LessonWord(
            w['token'] as int,
            Duration(milliseconds: w['start_ms'] as int),
            Duration(milliseconds: w['end_ms'] as int),
          ),
      ],
    );
  }

  /// Checks [recording] (16 kHz mono WAV) of the learner reciting word
  /// [token] of [surah]:[ayah], written [expected]. [pace] is how long the
  /// learner usually takes against the reciter, 1 for the same.
  /// [ayahWords] is the whole ayah as shown, so saying another of its words
  /// instead (a skipped or swapped word) is caught.
  static Future<WordCheck> check({
    required File recording,
    required String expected,
    required int surah,
    required int ayah,
    required int token,
    double pace = 1,
    String ayahWords = '',
  }) async {
    final request = http.MultipartRequest(
        'POST', Uri.parse('$teacherApiBase/v1/teacher/check'))
      ..fields.addAll({
        'expected': expected,
        'surah': '$surah',
        'ayah': '$ayah',
        'token': '$token',
        'pace': pace.toStringAsFixed(2),
        'ayah_words': ayahWords,
      })
      ..files.add(await http.MultipartFile.fromPath('audio', recording.path));
    final response = await _send(() async => http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 30))));
    final data = _json(response);
    return WordCheck(
      correct: data['correct'] as bool,
      heard: data['heard'] as String? ?? '',
      issues: [
        for (final i in data['issues'] as List)
          TeacherIssue(i['kind'] as String, i['message'] as String),
      ],
      durationMs: data['duration_ms'] as int?,
      referenceMs: data['reference_ms'] as int?,
    );
  }

  static Future<http.Response> _send(
      Future<http.Response> Function() request) async {
    try {
      return await request();
    } on SocketException {
      throw const TeacherException(
          'The Quran teacher needs an internet connection.');
    } on Exception {
      throw const TeacherException(
          'The Quran teacher is not responding. Please try again.');
    }
  }

  static Map<String, dynamic> _json(http.Response response) {
    if (response.statusCode == 503) {
      throw const TeacherException(
          'The Quran teacher is starting up. Please try again in a minute.');
    }
    if (response.statusCode != 200) {
      throw TeacherException(
          'The Quran teacher could not help with this (${response.statusCode}).');
    }
    return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}
