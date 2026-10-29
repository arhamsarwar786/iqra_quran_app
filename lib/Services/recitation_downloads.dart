import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../Models/aya_list_model.dart';
import '../Provider/quran_data_provider.dart';
import 'recitation_playlist.dart';

enum DownloadKind { surah, para, quran }

/// Something the listener can save for offline recitation.
class DownloadTarget {
  final DownloadKind kind;

  /// Surah or para number; 0 for the whole Quran.
  final int number;

  const DownloadTarget.surah(this.number) : kind = DownloadKind.surah;
  const DownloadTarget.para(this.number) : kind = DownloadKind.para;
  const DownloadTarget.quran()
      : kind = DownloadKind.quran,
        number = 0;

  String get key => '${kind.name}:$number';

  List<Aya> ayatsFrom(QuranDataProvider quran) {
    switch (kind) {
      case DownloadKind.surah:
        return quran.getAyatsBySurah(number);
      case DownloadKind.para:
        return quran.getAyatsByPara(number);
      case DownloadKind.quran:
        return quran.quranData;
    }
  }

  /// Name shown in the notification and messages.
  String titleFrom(QuranDataProvider quran) {
    switch (kind) {
      case DownloadKind.surah:
        final metadata = quran.getSurahMetadata(number);
        final name = metadata == null
            ? ''
            : (metadata.ename.isNotEmpty ? metadata.ename : metadata.tname);
        return name.isEmpty ? 'Surah $number' : 'Surah $name';
      case DownloadKind.para:
        return 'Para $number';
      case DownloadKind.quran:
        return 'Complete Quran';
    }
  }

  @override
  bool operator ==(Object other) => other is DownloadTarget && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

enum DownloadState { notDownloaded, partial, queued, downloading, paused, done }

class DownloadStatus {
  final DownloadState state;
  final int saved;
  final int total;

  const DownloadStatus(this.state, this.saved, this.total);

  double get progress => total == 0 ? 0 : saved / total;
  bool get isDone => state == DownloadState.done;
  bool get isBusy =>
      state == DownloadState.queued || state == DownloadState.downloading;
}

class _Job {
  final DownloadTarget target;
  final String title;
  final List<String> files;
  bool cancelled = false;
  http.Client? client;

  _Job(this.target, this.title, this.files);
}

/// Saves the recitation files [RecitationPlaylist] plays, one per ayah, so
/// they can be played without a connection.
///
/// Files are shared between targets: a surah, the paras it spans and the
/// complete Quran all use the same ayah files, so saving one counts towards
/// the others. Each file is written to a `.part` file first and renamed once
/// complete, which makes an interrupted download safe to resume: only the
/// missing ayahs are fetched again.
class RecitationDownloads extends ChangeNotifier {
  RecitationDownloads._();
  static final RecitationDownloads instance = RecitationDownloads._();

  static const String cancelActionId = 'cancel_recitation_downloads';
  static const int _notificationId = 7001;
  static const int _parallelFiles = 4;
  static const int _attemptsPerFile = 3;
  static const String _bismillahFile = '001001.mp3';
  static const MethodChannel _storageChannel = MethodChannel('iqra/storage');

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<String> _messages = StreamController.broadcast();

  Directory? _dir;
  final Set<String> _saved = {};
  int _bytes = 0;
  final Map<String, List<String>> _filesByTarget = {};
  final List<_Job> _queue = [];
  _Job? _active;
  Future<bool>? _activeRun;
  // Targets whose download stopped because the connection dropped. They
  // resume by themselves when it comes back.
  final Map<String, _Job> _paused = {};
  final List<String> _finished = [];

  Timer? _notifyTimer;
  DateTime _lastNotification = DateTime.fromMillisecondsSinceEpoch(0);

  /// Short messages for the app to show, e.g. when a download finishes.
  Stream<String> get messages => _messages.stream;

  /// Bytes of recitation saved on the device.
  int get storageBytes => _bytes;
  int get savedFiles => _saved.length;
  bool get isRunning => _active != null;
  String? get activeTitle => _active?.title;
  DownloadTarget? get activeTarget => _active?.target;
  int get queuedCount => _queue.length;

  Future<void> init() async {
    try {
      _dir = await _recitationDirectory();
      await _dir!.create(recursive: true);
      await _excludeFromBackup(_dir!);
      await for (final entity in _dir!.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (name.endsWith('.part')) {
          // Left over from a download that was interrupted.
          await entity.delete().catchError((_) => entity);
        } else if (name.endsWith('.mp3') || name.endsWith('.json')) {
          _saved.add(name);
          _bytes += await entity.length();
        }
      }
    } catch (e) {
      log('Recitation downloads unavailable: $e');
    }
    // A previous session may have been killed mid-download.
    _cancelNotification();
    Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) _resumePaused();
    });
  }

  // Android's no_backup folder and an iOS folder excluded from iCloud
  // backup: the recitation is about 1 GB and can always be downloaded again.
  Future<Directory> _recitationDirectory() async {
    final support = await getApplicationSupportDirectory();
    final base =
        Platform.isAndroid ? '${support.parent.path}/no_backup' : support.path;
    return Directory('$base/recitation/Alafasy_128kbps');
  }

  Future<void> _excludeFromBackup(Directory dir) async {
    if (!Platform.isIOS) return;
    try {
      await _storageChannel.invokeMethod('excludeFromBackup', dir.path);
    } catch (e) {
      log('Could not exclude recitation from backup: $e');
    }
  }

  static String _fileName(String url) => Uri.parse(url).pathSegments.last;

  /// A `file://` URL for [url] when it has been saved, otherwise [url].
  String resolve(String url) {
    final dir = _dir;
    final name = _fileName(url);
    if (dir == null || !_saved.contains(name)) return url;
    return Uri.file('${dir.path}/$name').toString();
  }

  bool isSaved(String url) => _saved.contains(_fileName(url));

  /// The downloaded recording at [url], if there is one.
  File? savedFile(String url) {
    final dir = _dir;
    final name = _fileName(url);
    if (dir == null || !_saved.contains(name)) return null;
    return File('${dir.path}/$name');
  }

  static String _wordsFileName(int surahId) =>
      'words_${surahId.toString().padLeft(3, '0')}.json';

  /// Words and word timings of every verse of [surahId], saved alongside its
  /// recitation so word-by-word features work offline. Keyed by Hafs verse
  /// key ("2:255"); each entry has `words` ([position, text] pairs) and
  /// `segments` (Quran.com's [index, position, start ms, end ms]).
  Future<Map<String, dynamic>?> savedWords(int surahId) async {
    final dir = _dir;
    final name = _wordsFileName(surahId);
    if (dir == null || !_saved.contains(name)) return null;
    try {
      final text = await File('${dir.path}/$name').readAsString();
      return json.decode(text) as Map<String, dynamic>;
    } catch (e) {
      log('Saved words of surah $surahId unreadable: $e');
      return null;
    }
  }

  List<String> _filesFor(DownloadTarget target, QuranDataProvider quran) {
    final cached = _filesByTarget[target.key];
    if (cached != null) return cached;
    final tracks = RecitationPlaylist.build(target.ayatsFrom(quran));
    final files = <String>{
      // Small, so they come first: word-by-word data of each surah.
      for (final track in tracks) _wordsFileName(track.surahId),
      for (final track in tracks) _fileName(track.url),
    }.toList();
    // Only remembered once the Quran text has loaded.
    if (files.isNotEmpty) _filesByTarget[target.key] = files;
    return files;
  }

  DownloadStatus statusOf(DownloadTarget target, QuranDataProvider quran) {
    final files = _filesFor(target, quran);
    final saved = files.where(_saved.contains).length;
    final DownloadState state;
    if (files.isNotEmpty && saved == files.length) {
      state = DownloadState.done;
    } else if (_active?.target == target) {
      state = DownloadState.downloading;
    } else if (_queue.any((j) => j.target == target)) {
      state = DownloadState.queued;
    } else if (_paused.containsKey(target.key)) {
      state = DownloadState.paused;
    } else {
      // Every surah shares the Bismillah recording, so having only that one
      // does not make a surah partly downloaded.
      final started =
          files.any((f) => f != _bismillahFile && _saved.contains(f));
      state = started ? DownloadState.partial : DownloadState.notDownloaded;
    }
    return DownloadStatus(state, saved, files.length);
  }

  /// Adds [target] to the download queue. Returns false when there is
  /// nothing left to download.
  bool download(DownloadTarget target, QuranDataProvider quran) {
    if (_dir == null) return false;
    final files = _filesFor(target, quran);
    if (files.isEmpty || files.every(_saved.contains)) return false;
    if (_active?.target == target || _queue.any((j) => j.target == target)) {
      return true;
    }
    _paused.remove(target.key);
    _queue.add(_Job(target, target.titleFrom(quran), files));
    // Downloading again means the connection is back: pick up anything that
    // paused too.
    _requeuePaused();
    _changed();
    _pump();
    return true;
  }

  void cancel(DownloadTarget target) {
    _paused.remove(target.key);
    _queue.removeWhere((j) => j.target == target);
    final active = _active;
    if (active != null && active.target == target) {
      active.cancelled = true;
      // Aborts the requests in flight.
      active.client?.close();
    }
    _changed();
    if (_active == null) _cancelNotification();
  }

  void cancelAll() {
    _paused.clear();
    _queue.clear();
    final active = _active;
    if (active != null) {
      active.cancelled = true;
      active.client?.close();
    }
    _changed();
    _cancelNotification();
  }

  /// Removes the saved recitation of [target]. Ayahs it shares with other
  /// surahs or paras are removed too, except Bismillah, which every surah
  /// plays.
  Future<void> delete(DownloadTarget target, QuranDataProvider quran) async {
    final run = _active?.target == target ? _activeRun : null;
    cancel(target);
    // Let requests already in flight wind down, so none of them saves a
    // file after it has been deleted.
    await run;
    final dir = _dir;
    if (dir == null) return;
    for (final name in _filesFor(target, quran)) {
      if (name == _bismillahFile && target.kind != DownloadKind.quran) {
        continue;
      }
      await _deleteFile(dir, name);
    }
    _changed();
  }

  Future<void> deleteAll() async {
    final run = _activeRun;
    cancelAll();
    await run;
    final dir = _dir;
    if (dir == null) return;
    for (final name in _saved.toList()) {
      await _deleteFile(dir, name);
    }
    _changed();
  }

  Future<void> _deleteFile(Directory dir, String name) async {
    if (!_saved.remove(name)) return;
    final file = File('${dir.path}/$name');
    try {
      _bytes -= await file.length();
      await file.delete();
    } catch (_) {}
    if (_bytes < 0) _bytes = 0;
  }

  Future<void> _pump() async {
    if (_active != null) return;
    while (_queue.isNotEmpty) {
      final job = _active = _queue.removeAt(0);
      _changed();
      final completed = await (_activeRun = _run(job));
      _active = null;
      _activeRun = null;
      if (completed) {
        _finished.add(job.title);
        _messages.add('${job.title} is ready to play offline');
      } else if (!job.cancelled) {
        // Lost the connection: hold this and everything after it until the
        // connection returns.
        _paused[job.target.key] = job;
        for (final queued in _queue) {
          _paused[queued.target.key] = queued;
        }
        _queue.clear();
        _messages.add('Download paused. It will continue when you are '
            'back online.');
      }
      _changed();
    }
    _showFinalNotification();
  }

  void _resumePaused() {
    if (_paused.isEmpty) return;
    _requeuePaused();
    _changed();
    _pump();
  }

  void _requeuePaused() {
    final jobs = _paused.values.toList();
    _paused.clear();
    for (final job in jobs) {
      if (_active?.target != job.target &&
          !_queue.any((j) => j.target == job.target)) {
        _queue.add(_Job(job.target, job.title, job.files));
      }
    }
  }

  /// Downloads the files of [job] that are missing. Returns true once every
  /// file is saved.
  Future<bool> _run(_Job job) async {
    final dir = _dir!;
    final missing = job.files.where((f) => !_saved.contains(f)).toList();
    final client = job.client = http.Client();
    var next = 0;
    var failed = false;

    Future<void> worker() async {
      while (!job.cancelled && !failed && next < missing.length) {
        final name = missing[next++];
        if (_saved.contains(name)) continue;
        if (!await _fetch(client, dir, name, job)) failed = true;
      }
    }

    await Future.wait([for (var i = 0; i < _parallelFiles; i++) worker()]);
    client.close();
    job.client = null;
    return !job.cancelled && job.files.every(_saved.contains);
  }

  Future<bool> _fetch(
      http.Client client, Directory dir, String name, _Job job) async {
    final part = File('${dir.path}/$name.part');
    for (var attempt = 0; attempt < _attemptsPerFile; attempt++) {
      if (job.cancelled) return false;
      try {
        if (name.startsWith('words_')) {
          await _fetchWords(client, part, int.parse(name.substring(6, 9)));
        } else {
          await _fetchRecording(client, part, name);
        }
        final length = await part.length();
        if (length == 0) throw const FileSystemException('Empty file');
        await part.rename('${dir.path}/$name');
        _saved.add(name);
        _bytes += length;
        _changed();
        return true;
      } catch (e) {
        await part.delete().catchError((_) => part);
        if (job.cancelled) return false;
        log('Recitation download of $name failed: $e');
        await Future<void>.delayed(Duration(seconds: 2 << attempt));
      }
    }
    return false;
  }

  Future<void> _fetchRecording(
      http.Client client, File part, String name) async {
    final url = RecitationPlaylist.fileUrlForName(name);
    final response = await client
        .send(http.Request('GET', Uri.parse(url)))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
    }
    final sink = part.openWrite();
    try {
      await sink
          .addStream(response.stream.timeout(const Duration(seconds: 30)));
    } finally {
      await sink.close();
    }
  }

  // Quran.com's words and word timings for Mishary Rashid Alafasy (its
  // recitation 7), whose recordings are the same files as everyayah.com's.
  Future<void> _fetchWords(http.Client client, File part, int surahId) async {
    const api = 'https://api.quran.com/api/v4';
    Future<Map<String, dynamic>> get(String url) async {
      final response =
          await client.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
      }
      return json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    }

    final verses = <String, Map<String, dynamic>>{};
    for (int? page = 1; page != null;) {
      final data = await get('$api/verses/by_chapter/$surahId?words=true'
          '&word_fields=text_indopak&per_page=50&page=$page');
      for (final verse in data['verses'] as List) {
        verses[verse['verse_key'] as String] = {
          'words': [
            for (final w in verse['words'] as List)
              if (w['char_type_name'] == 'word')
                [w['position'], w['text_indopak'] ?? ''],
          ],
          'segments': const [],
        };
      }
      page = data['pagination']?['next_page'] as int?;
    }
    final recitation =
        await get('$api/recitations/7/by_chapter/$surahId?fields=segments'
            '&per_page=300');
    for (final file in recitation['audio_files'] as List) {
      final verse = verses[file['verse_key']];
      if (verse != null) verse['segments'] = file['segments'] ?? const [];
    }
    if (verses.isEmpty) throw const FormatException('No verses returned');
    await part.writeAsString(json.encode(verses), flush: true);
  }

  // Many files can finish each second; rebuild at most a few times a second
  // and refresh the notification at most once a second, which is as often
  // as Android reliably shows it.
  void _changed() {
    if (_notifyTimer?.isActive ?? false) return;
    _notifyTimer = Timer(const Duration(milliseconds: 250), () {
      notifyListeners();
      final now = DateTime.now();
      if (_active != null &&
          now.difference(_lastNotification) > const Duration(seconds: 1)) {
        _lastNotification = now;
        _showProgressNotification();
      }
    });
  }

  NotificationDetails _details({
    required bool ongoing,
    int? progress,
    int? maxProgress,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'quran_recitation_downloads',
        'Quran Downloads',
        channelDescription: 'Progress of Quran recitation downloads',
        icon: 'ic_stat_recitation',
        color: const Color(0xff227C9E),
        importance: Importance.low,
        priority: Priority.low,
        onlyAlertOnce: true,
        ongoing: ongoing,
        autoCancel: !ongoing,
        showProgress: progress != null,
        progress: progress ?? 0,
        maxProgress: maxProgress ?? 0,
        actions: ongoing
            ? const [
                AndroidNotificationAction(
                  cancelActionId,
                  'Cancel',
                  // Background actions run in another isolate, which cannot
                  // reach these downloads; bring the app up to handle it.
                  showsUserInterface: true,
                  cancelNotification: true,
                ),
              ]
            : null,
      ),
    );
  }

  Future<void> _showProgressNotification() async {
    final job = _active;
    if (job == null || !Platform.isAndroid) return;
    final saved = job.files.where(_saved.contains).length;
    final total = job.files.length;
    final percent = total == 0 ? 0 : (saved * 100 ~/ total);
    final waiting = _queue.isEmpty ? '' : ' · ${_queue.length} more waiting';
    try {
      await _notifications.show(
        _notificationId,
        'Downloading ${job.title}',
        '$percent% · $saved of $total files$waiting',
        _details(ongoing: true, progress: saved, maxProgress: total),
      );
    } catch (e) {
      log('Download notification failed: $e');
    }
  }

  Future<void> _showFinalNotification() async {
    final finished = List<String>.from(_finished);
    _finished.clear();
    if (!Platform.isAndroid) return;
    try {
      if (_paused.isNotEmpty) {
        await _notifications.show(
          _notificationId,
          'Download paused',
          'No connection. It will continue when you are back online.',
          _details(ongoing: false),
        );
      } else if (finished.isNotEmpty) {
        await _notifications.show(
          _notificationId,
          'Download complete',
          finished.length == 1
              ? '${finished.first} is ready to play offline'
              : '${finished.length} downloads are ready to play offline',
          _details(ongoing: false),
        );
      } else {
        await _notifications.cancel(_notificationId);
      }
    } catch (e) {
      log('Download notification failed: $e');
    }
  }

  void _cancelNotification() {
    if (!Platform.isAndroid) return;
    _notifications.cancel(_notificationId).catchError((_) {});
  }
}

/// e.g. "245 MB" or "1.1 GB".
String formatBytes(int bytes) {
  const mb = 1024 * 1024;
  if (bytes >= 1024 * mb) {
    return '${(bytes / (1024 * mb)).toStringAsFixed(1)} GB';
  }
  if (bytes >= mb) {
    return '${(bytes / mb).toStringAsFixed(bytes < 10 * mb ? 1 : 0)} MB';
  }
  return '${(bytes / 1024).toStringAsFixed(0)} KB';
}
