import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Models/aya_list_model.dart';
import '../../../Provider/audio_provider.dart';
import '../../../Provider/quran_data_provider.dart';
import '../../../Provider/theme_provider.dart';
import '../../../Services/quran_teacher/phrase_listener.dart';
import '../../../Services/quran_teacher/teacher_api.dart';
import '../../../Services/quran_teacher/word_recorder.dart';
import '../../../Services/recitation_downloads.dart';

/// How the learner practises.
enum LearnMode {
  /// The reciter says each word and the learner repeats it.
  word,

  /// The learner recites the whole ayah; each word turns green or red as
  /// they go.
  ayah,

  /// As [ayah], going on to the next ayah until the end of the surah.
  surah,
}

enum _Phase {
  loading,
  // Word by word.
  reciter,
  yourTurn,
  checking,
  correct,
  wrong,
  paused,
  // Ayah and surah.
  ready,
  listening,
  playingAyah,
  // Both.
  ayahDone,
  surahDone,
  error,
}

enum _WordState { pending, correct, wrong }

/// How many words of an ayah the learner got right.
class _Score {
  final int right;
  final int total;

  const _Score(this.right, this.total);

  bool get perfect => right == total;
}

/// Learn to recite with tajweed: word by word after the reciter, or a whole
/// ayah or surah at once, with the Quran teacher marking each word green
/// when it is right and red when it is not.
class LearnTajweedScreen extends StatefulWidget {
  /// The ayahs the learner can move through, in order.
  final List<Aya> ayats;
  final int initialIndex;

  const LearnTajweedScreen(
      {super.key, required this.ayats, required this.initialIndex});

  @override
  State<LearnTajweedScreen> createState() => _LearnTajweedScreenState();
}

class _LearnTajweedScreenState extends State<LearnTajweedScreen> {
  static const _modeKey = 'learn_mode';

  final AudioPlayer _reciter = AudioPlayer();
  final WordRecorder _recorder = WordRecorder();
  final PhraseListener _listener = PhraseListener();
  StreamSubscription<Uint8List>? _phrases;

  /// Null until the learner has chosen how to learn.
  LearnMode? _mode;
  bool _modeLoaded = false;

  /// The ayahs to learn. The readers list Bismillah as ayah 0 at the top
  /// of most surahs; it has no lesson, so it is left out.
  late final List<Aya> _ayats =
      widget.ayats.where((a) => a.ayatNumberInt > 0).toList();
  late int _ayahIndex = _initialIndex();
  Lesson? _lesson;
  List<String> _tokens = const [];
  final Map<int, _WordState> _states = {};
  // What was heard for each wrong word, by token.
  final Map<int, String> _heardFor = {};
  _Phase _phase = _Phase.loading;
  String _message = '';

  // Word by word: the word being taught, an index into _lesson.words.
  int _word = 0;
  int _attempts = 0;
  int _firstTry = 0;

  // Ayah and surah: the first word not yet recited, null once all are.
  int? _nextToken;
  // Phrases sent to the teacher and not yet back.
  int _checking = 0;
  Future<void> _queue = Future.value();
  // The word the reciter is saying while the whole ayah plays.
  int? _playingToken;
  // Right and total words of each ayah recited, by index into ayats.
  final Map<int, _Score> _scores = {};
  // In a surah: going on to the next ayah by itself after this one.
  bool _autoNext = false;

  // Each run of the lesson has an id; loading another ayah, changing mode
  // or leaving starts a new one, and work of the old one stops.
  int _run = 0;
  Completer<void> _stopRecording = Completer<void>();

  // How long the learner takes over a word against the reciter, from their
  // recent right words, so the tajweed check follows their own pace.
  final List<double> _paceSamples = [];

  int _initialIndex() {
    if (widget.ayats.isEmpty) return 0;
    final start =
        widget.ayats[widget.initialIndex.clamp(0, widget.ayats.length - 1)];
    final i = _ayats.indexOf(start);
    return i < 0 ? 0 : i;
  }

  Aya get _aya => _ayats[_ayahIndex];
  int get _surahId => int.tryParse(_aya.surahId ?? '') ?? 1;
  bool get _reciting => _mode == LearnMode.ayah || _mode == LearnMode.surah;

  @override
  void initState() {
    super.initState();
    // The lesson has its own sound; pause any recitation.
    final audio = context.read<AudioProvider>();
    if (audio.isPlaying) audio.pausePlayback();
    _phrases = _listener.phrases.listen(_onPhrase);
    _start();
  }

  Future<void> _start() async {
    LearnMode? saved;
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_modeKey);
      for (final m in LearnMode.values) {
        if (m.name == name) saved = m;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _mode = saved;
      _modeLoaded = true;
    });
    if (saved != null) _loadAyah();
  }

  @override
  void dispose() {
    _run++;
    _cancelRecording();
    _phrases?.cancel();
    _reciter.dispose();
    _recorder.dispose();
    _listener.dispose();
    super.dispose();
  }

  void _cancelRecording() {
    if (!_stopRecording.isCompleted) _stopRecording.complete();
  }

  bool _stale(int run) => !mounted || run != _run;

  /// Stops whatever is going on: teaching, listening or playing.
  void _stopAll() {
    _run++;
    _cancelRecording();
    _listener.stop();
    _reciter.pause();
    _checking = 0;
    _playingToken = null;
  }

  Future<void> _chooseMode(LearnMode mode, {int? startToken}) async {
    if (mode == _mode && startToken == null) return;
    HapticFeedback.selectionClick();
    setState(() => _mode = mode);
    _loadAyah(startToken: startToken);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modeKey, mode.name);
    } catch (_) {}
  }

  /// Loads the current ayah's lesson. Word by word starts teaching at once
  /// (from [startToken] if given); ayah and surah wait for the microphone
  /// unless [listen].
  Future<void> _loadAyah({bool listen = false, int? startToken}) async {
    _stopAll();
    final run = _run;
    setState(() {
      _phase = _Phase.loading;
      _lesson = null;
      _states.clear();
      _heardFor.clear();
      _word = 0;
      _attempts = 0;
      _firstTry = 0;
      _nextToken = null;
      _autoNext = false;
      _message = '';
      _tokens = _aya.arabicText.trim().split(RegExp(r'\s+'));
    });
    try {
      if (!await _recorder.hasPermission()) {
        throw const TeacherException(
            'Allow microphone access so the teacher can hear you recite.');
      }
      final lesson = await TeacherApi.lesson(_surahId, _aya.ayatNumberInt);
      if (_stale(run)) return;
      // Plays the downloaded recording when there is one.
      final uri =
          Uri.parse(RecitationDownloads.instance.resolve(lesson.recordingUrl));
      await _reciter.setAudioSource(AudioSource.uri(uri));
      if (_stale(run)) return;
      setState(() {
        _lesson = lesson;
        _nextToken = lesson.words.isEmpty ? null : lesson.words.first.token;
        if (startToken != null) {
          final i = lesson.words.indexWhere((w) => w.token == startToken);
          if (i >= 0) _word = i;
        }
      });
      if (!_reciting) {
        _teach(run);
      } else if (listen) {
        _startListening();
      } else {
        setState(() => _phase = _Phase.ready);
      }
    } on TeacherException catch (e) {
      if (!_stale(run)) setState(() => _fail(e.message));
    } catch (_) {
      if (!_stale(run)) {
        setState(() =>
            _fail('The recitation could not be loaded. Please try again.'));
      }
    }
  }

  void _fail(String message) {
    _phase = _Phase.error;
    _message = message;
  }

  // ── Word by word ─────────────────────────────────────────────────────────

  /// The lesson loop for the current word, then the next, until the ayah is
  /// done or the loop is stopped.
  Future<void> _teach(int run) async {
    final lesson = _lesson;
    if (lesson == null) return;
    while (!_stale(run) && _word < lesson.words.length) {
      final word = lesson.words[_word];

      // 1. The reciter says the word.
      setState(() {
        _phase = _Phase.reciter;
        _message = 'Listen to the reciter';
      });
      await _playWord(word);
      if (_stale(run)) return;

      // 2. The learner says it.
      setState(() {
        _phase = _Phase.yourTurn;
        _message = 'Your turn: recite the highlighted word';
      });
      _stopRecording = Completer<void>();
      final recording =
          await _recorder.recordWord(cancel: _stopRecording.future);
      if (_stale(run) || recording == null) return;
      if (!recording.spoke) {
        setState(() {
          _phase = _Phase.wrong;
          _message =
              "I couldn't hear you. Recite the word again, a little louder.";
          _attempts++;
        });
        await Future<void>.delayed(const Duration(milliseconds: 1800));
        continue;
      }

      // 3. The teacher checks it.
      setState(() {
        _phase = _Phase.checking;
        _message = 'Checking…';
      });
      final WordCheck result;
      try {
        result = await TeacherApi.check(
          recording: recording.file,
          expected: _tokens[word.token],
          surah: _surahId,
          ayah: _aya.ayatNumberInt,
          token: word.token,
          pace: _pace,
          ayahWords: _tokens.join(' '),
        );
      } on TeacherException catch (e) {
        if (!_stale(run)) setState(() => _fail(e.message));
        return;
      }
      if (_stale(run)) return;

      if (result.correct) {
        HapticFeedback.lightImpact();
        _notePace(result);
        setState(() {
          if (_attempts == 0) _firstTry++;
          _states[word.token] = _WordState.correct;
          _phase = _Phase.correct;
          _message = 'Correct, mashaAllah';
          _attempts = 0;
        });
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (_stale(run)) return;
        setState(() => _word++);
      } else {
        HapticFeedback.mediumImpact();
        setState(() {
          _states[word.token] = _WordState.wrong;
          _phase = _Phase.wrong;
          _message = result.issues.isEmpty
              ? 'Not quite. Listen again and repeat the word.'
              : result.issues.first.message;
          _attempts++;
        });
        // Time to read the advice before the reciter says it again.
        await Future<void>.delayed(const Duration(milliseconds: 2200));
      }
    }
    if (!_stale(run)) {
      _scores[_ayahIndex] = _Score(_firstTry, lesson.words.length);
      setState(() {
        _phase = _Phase.ayahDone;
        _message = '';
      });
    }
  }

  Future<void> _playWord(LessonWord word) async {
    final start = word.start - const Duration(milliseconds: 40);
    await _reciter.setClip(
      start: start.isNegative ? Duration.zero : start,
      end: word.end + const Duration(milliseconds: 60),
    );
    await _reciter.seek(Duration.zero);
    // Completes when the clip has finished.
    await _reciter.play();
    await _reciter.pause();
  }

  double get _pace {
    if (_paceSamples.length < 3) return 1;
    final sorted = [..._paceSamples]..sort();
    return sorted[sorted.length ~/ 2];
  }

  void _notePace(WordCheck result) {
    final spoke = result.durationMs, reference = result.referenceMs;
    if (spoke == null || reference == null || reference < 300) return;
    _paceSamples.add(spoke / reference);
    if (_paceSamples.length > 8) _paceSamples.removeAt(0);
  }

  void _pause() {
    _run++;
    _cancelRecording();
    _reciter.pause();
    setState(() {
      _phase = _Phase.paused;
      _message = 'Paused';
    });
  }

  void _resume() {
    if (_lesson == null) {
      _loadAyah();
      return;
    }
    _teach(++_run);
  }

  /// Goes to word [index] of the lesson and teaches from there.
  void _jumpTo(int index) {
    final lesson = _lesson;
    if (lesson == null) return;
    _run++;
    _cancelRecording();
    _reciter.pause();
    setState(() {
      _word = index.clamp(0, lesson.words.length - 1);
      _attempts = 0;
    });
    _teach(++_run);
  }

  void _skip() =>
      _jumpTo(_word + 1 < (_lesson?.words.length ?? 0) ? _word + 1 : _word);

  // ── Ayah and surah ───────────────────────────────────────────────────────

  Future<void> _startListening() async {
    final lesson = _lesson;
    if (lesson == null || lesson.words.isEmpty) return;
    final run = _run;
    await _reciter.pause();
    // Reciting a finished ayah again starts it afresh.
    if (_nextToken == null || _phase == _Phase.ayahDone) {
      _states.clear();
      _heardFor.clear();
      _nextToken = lesson.words.first.token;
    }
    try {
      await _listener.start();
    } catch (_) {
      if (!_stale(run)) {
        setState(() =>
            _fail('The microphone could not be started. Please try again.'));
      }
      return;
    }
    if (_stale(run)) {
      _listener.stop();
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _phase = _Phase.listening;
      _message = _states.isEmpty
          ? 'Recite the ayah at your own pace'
          : 'Go on from the glowing word';
    });
  }

  /// Stops listening; phrases already sent are still marked.
  Future<void> _stopListening() async {
    await _listener.stop();
    if (!mounted || _phase != _Phase.listening) return;
    setState(() {
      _phase = _Phase.ready;
      _message = 'Paused. Tap the microphone to go on.';
    });
  }

  void _onPhrase(Uint8List wav) {
    if (_phase != _Phase.listening) return;
    final run = _run;
    setState(() => _checking++);
    _queue = _queue.then((_) => _checkPhrase(run, wav));
  }

  Future<void> _checkPhrase(int run, Uint8List wav) async {
    try {
      final from = _nextToken;
      if (_stale(run) || from == null) return;
      final result = await TeacherApi.recite(
        wav: wav,
        surah: _surahId,
        ayah: _aya.ayatNumberInt,
        fromToken: from,
        ayahWords: _tokens.join(' '),
      );
      if (_stale(run)) return;
      if (result.words.isEmpty) {
        setState(() =>
            _message = "I couldn't make that out. Go on, a little louder.");
        return;
      }
      final wrong = result.words.where((w) => !w.correct).length;
      wrong == 0 ? HapticFeedback.lightImpact() : HapticFeedback.mediumImpact();
      setState(() {
        for (final w in result.words) {
          _states[w.token] = w.correct ? _WordState.correct : _WordState.wrong;
          if (w.correct) {
            _heardFor.remove(w.token);
          } else {
            _heardFor[w.token] = w.heard;
          }
        }
        _nextToken = result.nextToken;
        _message = wrong == 0
            ? 'MashaAllah, keep going'
            : wrong == 1
                ? 'One word in red. Keep going'
                : '$wrong words in red. Keep going';
      });
      if (result.nextToken == null) unawaited(_finishAyah(run));
    } on TeacherException catch (e) {
      if (!_stale(run)) {
        await _listener.stop();
        setState(() => _fail(e.message));
      }
    } finally {
      if (!_stale(run) && _checking > 0) setState(() => _checking--);
    }
  }

  Future<void> _finishAyah(int run) async {
    await _listener.stop();
    if (_stale(run)) return;
    final lesson = _lesson!;
    final right = lesson.words
        .where((w) => _states[w.token] == _WordState.correct)
        .length;
    _scores[_ayahIndex] = _Score(right, lesson.words.length);
    HapticFeedback.mediumImpact();
    final last = _ayahIndex == _ayats.length - 1;
    setState(() {
      _phase =
          _mode == LearnMode.surah && last ? _Phase.surahDone : _Phase.ayahDone;
      _message = '';
      _autoNext = _mode == LearnMode.surah && !last;
    });
    if (!_autoNext) return;
    // Go on to the next ayah after a moment to see the marks, unless the
    // learner stays here or does something else meanwhile.
    await Future<void>.delayed(const Duration(milliseconds: 2400));
    if (_stale(run)) return;
    if (_phase == _Phase.ayahDone && _autoNext) {
      _goToAyah(_ayahIndex + 1, listen: true);
    } else {
      setState(() => _autoNext = false);
    }
  }

  /// Stops going on to the next ayah by itself.
  void _holdHere() => setState(() => _autoNext = false);

  /// Plays the whole ayah, lighting up each word as the reciter says it.
  Future<void> _playAyah() async {
    final lesson = _lesson;
    if (lesson == null || lesson.words.isEmpty) return;
    if (_phase == _Phase.playingAyah) {
      await _reciter.pause();
      return;
    }
    // The microphone would hear the reciter as the learner.
    await _listener.stop();
    final back = _phase == _Phase.listening ? _Phase.ready : _phase;
    final run = _run;
    final words = lesson.words;
    var clipStart = words.first.start - const Duration(milliseconds: 80);
    if (clipStart.isNegative) clipStart = Duration.zero;
    await _reciter.setClip(
        start: clipStart,
        end: words.last.end + const Duration(milliseconds: 300));
    await _reciter.seek(Duration.zero);
    if (_stale(run)) return;
    setState(() {
      _phase = _Phase.playingAyah;
      _message = 'Listen and follow the words';
    });
    final position = _reciter.positionStream.listen((p) {
      final at = clipStart + p;
      int? token;
      for (final w in words) {
        if (at >= w.start - const Duration(milliseconds: 60)) token = w.token;
      }
      if (token != _playingToken && mounted) {
        setState(() => _playingToken = token);
      }
    });
    await _reciter.play();
    await _reciter.pause();
    await position.cancel();
    if (_stale(run)) return;
    setState(() {
      _playingToken = null;
      _phase = back;
      _message = back == _Phase.ready ? '' : _message;
    });
  }

  /// The reciter says one word; in ayah and surah the learner taps a word
  /// to hear it.
  Future<void> _hearWord(int token) async {
    final words = _lesson?.words.where((w) => w.token == token);
    if (words == null || words.isEmpty || _phase == _Phase.playingAyah) {
      return;
    }
    final word = words.first;
    _autoNext = false;
    if (_phase == _Phase.listening) await _stopListening();
    setState(() => _playingToken = token);
    await _playWord(word);
    if (mounted) setState(() => _playingToken = null);
  }

  void _goToAyah(int index, {bool listen = false}) {
    if (index < 0 || index >= _ayats.length) return;
    setState(() => _ayahIndex = index);
    _loadAyah(listen: listen);
  }

  void _restartSurah() {
    _scores.clear();
    _goToAyah(0);
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final color = theme.selectedTheme;

    return Scaffold(
      backgroundColor: theme.selectedSecondary,
      appBar: AppBar(
        title: const Text('Learn with Tajweed'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: !_modeLoaded
            ? const SizedBox()
            : _mode == null
                ? _ModeChooser(color: color, onChoose: _chooseMode)
                : _lessonView(theme, color),
      ),
    );
  }

  Widget _lessonView(ThemeProvider theme, Color color) {
    final quran = context.read<QuranDataProvider>();
    final lesson = _lesson;
    final total = lesson?.words.length ?? 0;
    final marked = _reciting
        ? (lesson?.words.where((w) => _states.containsKey(w.token)).length ?? 0)
        : _word.clamp(0, total);

    int? current;
    if (lesson != null && lesson.words.isNotEmpty) {
      if (!_reciting) {
        if (_phase != _Phase.ayahDone && _word < lesson.words.length) {
          current = lesson.words[_word].token;
        }
      } else if (_phase == _Phase.listening || _phase == _Phase.ready) {
        current = _nextToken;
      }
    }

    return Column(
      children: [
        _Header(
          mode: _mode!,
          onMode: (m) => _chooseMode(m),
          title: quran.recitationTitle(_surahId),
          ayah: _aya.ayatNumberInt,
          index: _ayahIndex,
          count: _ayats.length,
          done: marked,
          total: total,
          scores: _scores,
          color: color,
          onPrevious: _ayahIndex > 0 ? () => _goToAyah(_ayahIndex - 1) : null,
          onNext: _ayahIndex < _ayats.length - 1
              ? () => _goToAyah(_ayahIndex + 1)
              : null,
          onAyah: _goToAyah,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
            child: _AyahWords(
              tokens: _tokens,
              lesson: lesson,
              states: _states,
              current: current,
              playing: _playingToken,
              shake: !_reciting && _phase == _Phase.wrong,
              glow: !_reciting && _phase == _Phase.correct,
              color: color,
              fontFamily: theme.arabicFontFamily,
              fontSize: theme.arabicFontSize,
              onTapToken: (token) {
                if (_reciting) {
                  _hearWord(token);
                } else {
                  final i = lesson!.words.indexWhere((w) => w.token == token);
                  if (i >= 0) _jumpTo(i);
                }
              },
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: _panel(color),
        ),
      ],
    );
  }

  Widget _panel(Color color) {
    final lesson = _lesson;
    final hasNext = _ayahIndex < _ayats.length - 1;
    if (_phase == _Phase.surahDone) {
      return _SurahDonePanel(
        scores: _scores,
        ayats: _ayats,
        color: color,
        onRestart: _restartSurah,
      );
    }
    if (!_reciting) {
      if (_phase == _Phase.ayahDone) {
        return _AyahDonePanel(
          firstTry: _firstTry,
          total: lesson?.words.length ?? 0,
          color: color,
          hasNext: hasNext,
          onRepeat: () => _goToAyah(_ayahIndex),
          onNext: () => _goToAyah(_ayahIndex + 1),
        );
      }
      return _CoachPanel(
        phase: _phase,
        message: _message,
        color: color,
        level: _recorder.level,
        attempts: _attempts,
        onPause: _pause,
        onResume: _resume,
        onHearAgain: lesson == null || _word >= lesson.words.length
            ? null
            : () => _jumpTo(_word),
        onSkip: _attempts >= 2 ? _skip : null,
      );
    }
    if (_phase == _Phase.ayahDone && lesson != null) {
      final wrong = [
        for (final w in lesson.words)
          if (_states[w.token] != _WordState.correct) w.token
      ];
      return _ReciteDonePanel(
        right: lesson.words.length - wrong.length,
        total: lesson.words.length,
        mistakes: [for (final t in wrong) _tokens[t]],
        color: color,
        autoNext: _autoNext,
        hasNext: hasNext,
        onHear: (i) => _hearWord(wrong[i]),
        onAgain: () => _loadAyah(listen: true),
        onPractise: wrong.isEmpty
            ? null
            : () => _chooseMode(LearnMode.word, startToken: wrong.first),
        onNext: () =>
            _goToAyah(_ayahIndex + 1, listen: _mode == LearnMode.surah),
        onHold: _holdHere,
      );
    }
    return _ListenPanel(
      phase: _phase,
      mode: _mode!,
      message: _message,
      checking: _checking,
      color: color,
      level: _listener.level,
      speaking: _listener.speaking,
      onMic: _phase == _Phase.listening ? _stopListening : _startListening,
      onPlay: lesson == null ? null : _playAyah,
      onRetry: () => _loadAyah(),
    );
  }
}

// ── Choosing a mode ────────────────────────────────────────────────────────

class _ModeInfo {
  final LearnMode mode;
  final IconData icon;
  final String title;
  final String short;
  final String detail;

  const _ModeInfo(this.mode, this.icon, this.title, this.short, this.detail);
}

const _modes = [
  _ModeInfo(LearnMode.word, Icons.record_voice_over_rounded, 'Word by word',
      'Word', 'The reciter says a word, you repeat it. Best to begin with.'),
  _ModeInfo(LearnMode.ayah, Icons.graphic_eq_rounded, 'Ayah by ayah', 'Ayah',
      'Recite a whole ayah. Words turn green or red as you go.'),
  _ModeInfo(LearnMode.surah, Icons.menu_book_rounded, 'Surah by surah', 'Surah',
      'Recite ayah after ayah to the end of the surah.'),
];

class _ModeChooser extends StatelessWidget {
  final Color color;
  final ValueChanged<LearnMode> onChoose;

  const _ModeChooser({required this.color, required this.onChoose});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      children: [
        Icon(Icons.school_rounded, color: color, size: 52),
        const SizedBox(height: 10),
        Text('How would you like to learn?',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('You can change this any time at the top of the lesson.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 24),
        for (final m in _modes)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Material(
              color: Colors.white,
              elevation: 2,
              shadowColor: color.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onChoose(m.mode),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: color.withOpacity(0.12),
                        child: Icon(m.icon, color: color, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.title,
                                style: TextStyle(
                                    color: color,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(m.detail,
                                style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                    height: 1.35)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: color),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final LearnMode mode;
  final ValueChanged<LearnMode> onMode;
  final String title;
  final int ayah;
  final int index;
  final int count;
  final int done;
  final int total;
  final Map<int, _Score> scores;
  final Color color;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int> onAyah;

  const _Header({
    required this.mode,
    required this.onMode,
    required this.title,
    required this.ayah,
    required this.index,
    required this.count,
    required this.done,
    required this.total,
    required this.scores,
    required this.color,
    required this.onPrevious,
    required this.onNext,
    required this.onAyah,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Colors.white,
      child: Column(
        children: [
          _ModeSwitch(mode: mode, color: color, onMode: onMode),
          const SizedBox(height: 10),
          Row(
            children: [
              _arrow(Icons.chevron_left_rounded, onPrevious),
              Expanded(
                child: Column(
                  children: [
                    Text('$title · Ayah $ayah',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text(
                        total == 0
                            ? '${index + 1} of $count'
                            : '$done / $total words · ${index + 1} of $count',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              _arrow(Icons.chevron_right_rounded, onNext),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: total == 0 ? 0 : done / total),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                color: Colors.green.shade600,
                backgroundColor: color.withOpacity(0.12),
              ),
            ),
          ),
          if (mode == LearnMode.surah && count > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 22,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: count,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) => _dot(i),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dot(int i) {
    final score = scores[i];
    final Color fill = score == null
        ? Colors.grey.shade300
        : score.perfect
            ? Colors.green.shade600
            : Colors.orange.shade700;
    final here = i == index;
    return GestureDetector(
      onTap: () => onAyah(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: here ? 22 : 14,
        height: 14,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: here && score == null ? color : fill,
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback? onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      color: color,
      disabledColor: Colors.grey[300],
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  final LearnMode mode;
  final Color color;
  final ValueChanged<LearnMode> onMode;

  const _ModeSwitch(
      {required this.mode, required this.color, required this.onMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final m in _modes)
            Expanded(
              child: GestureDetector(
                onTap: () => onMode(m.mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: m.mode == mode ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(m.icon,
                          size: 17,
                          color: m.mode == mode ? Colors.white : color),
                      const SizedBox(width: 6),
                      Text(m.short,
                          style: TextStyle(
                              color: m.mode == mode ? Colors.white : color,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── The ayah ───────────────────────────────────────────────────────────────

/// The ayah as the reader shows it, each recited word coloured by how the
/// learner did; the word to recite next glows, and the word the reciter is
/// saying is lit up.
class _AyahWords extends StatelessWidget {
  final List<String> tokens;
  final Lesson? lesson;
  final Map<int, _WordState> states;
  final int? current;
  final int? playing;
  final bool shake;
  final bool glow;
  final Color color;
  final String fontFamily;
  final double fontSize;
  final ValueChanged<int> onTapToken;

  const _AyahWords({
    required this.tokens,
    required this.lesson,
    required this.states,
    required this.current,
    required this.playing,
    required this.shake,
    required this.glow,
    required this.color,
    required this.fontFamily,
    required this.fontSize,
    required this.onTapToken,
  });

  @override
  Widget build(BuildContext context) {
    final recited = {for (final w in lesson?.words ?? const []) w.token};
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 14,
        children: [
          for (var t = 0; t < tokens.length; t++)
            _wordChip(t, recited.contains(t)),
        ],
      ),
    );
  }

  Widget _wordChip(int token, bool recited) {
    final state = states[token] ?? _WordState.pending;
    final isCurrent = token == current;
    final isPlaying = token == playing;

    Color ink = Colors.black87;
    Color? fill;
    Color? border;
    if (isPlaying) {
      ink = Colors.white;
      fill = color;
    } else if (isCurrent && shake) {
      ink = Colors.red.shade700;
      fill = Colors.red.withOpacity(0.1);
      border = ink;
    } else if (isCurrent && glow) {
      ink = Colors.green.shade700;
      fill = Colors.green.withOpacity(0.12);
      border = ink;
    } else if (state == _WordState.correct) {
      ink = Colors.green.shade700;
      fill = Colors.green.withOpacity(0.08);
    } else if (state == _WordState.wrong) {
      ink = Colors.red.shade700;
      fill = Colors.red.withOpacity(0.1);
    } else if (isCurrent) {
      ink = color;
      fill = color.withOpacity(0.1);
      border = color;
    }

    final text = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: border == null
            ? null
            : Border.all(color: border.withOpacity(0.6), width: 1.5),
      ),
      child: Text(
        tokens[token],
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          color: ink,
          height: 1.6,
        ),
      ),
    );

    return GestureDetector(
      // Pause marks and the verse number are not recited, so not taught.
      onTap: recited ? () => onTapToken(token) : null,
      // A word pops as it is marked.
      child: TweenAnimationBuilder<double>(
        key: ValueKey(state),
        tween: Tween(begin: state == _WordState.pending ? 1 : 1.18, end: 1),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: isCurrent && !shake && !glow && !isPlaying
            ? _Pulse(color: color, child: text)
            : text,
      ),
    );
  }
}

/// A soft glow breathing around the word to recite next.
class _Pulse extends StatefulWidget {
  final Color color;
  final Widget child;

  const _Pulse({required this.color, required this.child});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.08 + 0.22 * _c.value),
              blurRadius: 6 + 10 * _c.value,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ── Ayah and surah panels ──────────────────────────────────────────────────

/// The microphone, live listening and what the teacher says while the
/// learner recites a whole ayah.
class _ListenPanel extends StatelessWidget {
  final _Phase phase;
  final LearnMode mode;
  final String message;
  final int checking;
  final Color color;
  final Stream<double> level;
  final Stream<bool> speaking;
  final VoidCallback onMic;
  final VoidCallback? onPlay;
  final VoidCallback onRetry;

  const _ListenPanel({
    required this.phase,
    required this.mode,
    required this.message,
    required this.checking,
    required this.color,
    required this.level,
    required this.speaking,
    required this.onMic,
    required this.onPlay,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final listening = phase == _Phase.listening;
    final playing = phase == _Phase.playingAyah;
    final error = phase == _Phase.error;

    Widget status;
    if (phase == _Phase.loading) {
      status = SizedBox(
          height: 34,
          child: Center(
              child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                      color: color, strokeWidth: 3))));
    } else if (listening) {
      status = _LiveStatus(
          level: level, speaking: speaking, checking: checking, color: color);
    } else if (playing) {
      status = SizedBox(
        height: 34,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volume_up_rounded, color: color),
            const SizedBox(width: 8),
            Text('The reciter is reading',
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    } else {
      status = const SizedBox(height: 4);
    }

    final hint = error
        ? message
        : message.isNotEmpty
            ? message
            : mode == LearnMode.surah
                ? 'Tap the microphone and recite. The next ayah follows by itself.'
                : 'Tap the microphone and recite the whole ayah.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          status,
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              hint,
              key: ValueKey(hint),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: error ? Colors.red.shade700 : Colors.grey[800],
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SideButton(
                  icon: playing ? Icons.stop_rounded : Icons.headphones_rounded,
                  label: playing ? 'Stop' : 'Listen first',
                  color: color,
                  onTap: error || phase == _Phase.loading ? null : onPlay,
                ),
              ),
              error
                  ? _MicButton(
                      icon: Icons.refresh_rounded,
                      color: color,
                      active: false,
                      onTap: onRetry)
                  : _MicButton(
                      icon: listening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: listening ? Colors.red.shade600 : color,
                      active: listening,
                      onTap: phase == _Phase.loading || playing ? null : onMic,
                    ),
              Expanded(
                child: Center(
                  child: Text(
                    listening
                        ? 'Tap to stop'
                        : (error ? 'Try again' : 'Tap to recite'),
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Tap any word to hear it · Tajweed checks are a guide (beta)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ],
      ),
    );
  }
}

/// While listening: a red dot and a live sound wave of the learner's voice,
/// and how many phrases the teacher is still checking.
class _LiveStatus extends StatelessWidget {
  final Stream<double> level;
  final Stream<bool> speaking;
  final int checking;
  final Color color;

  const _LiveStatus({
    required this.level,
    required this.speaking,
    required this.checking,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          const _RecordingDot(),
          const SizedBox(width: 8),
          StreamBuilder<bool>(
            stream: speaking,
            initialData: false,
            builder: (context, snap) => Text(
              snap.data == true ? 'Hearing you' : 'Listening',
              style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _LiveWave(level: level, color: color)),
          const SizedBox(width: 10),
          AnimatedOpacity(
            opacity: checking > 0 ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Row(
              children: [
                SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: color)),
                const SizedBox(width: 6),
                Text('Checking',
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingDot extends StatefulWidget {
  const _RecordingDot();

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
      child: Container(
        width: 10,
        height: 10,
        decoration:
            BoxDecoration(color: Colors.red.shade600, shape: BoxShape.circle),
      ),
    );
  }
}

/// The learner's voice as a moving wave of bars, newest on the right.
class _LiveWave extends StatefulWidget {
  final Stream<double> level;
  final Color color;

  const _LiveWave({required this.level, required this.color});

  @override
  State<_LiveWave> createState() => _LiveWaveState();
}

class _LiveWaveState extends State<_LiveWave> {
  static const _bars = 32;
  final List<double> _levels = List.filled(_bars, 0, growable: true);
  StreamSubscription<double>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.level.listen((v) {
      if (!mounted) return;
      setState(() {
        _levels.add(v);
        if (_levels.length > _bars) _levels.removeAt(0);
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WavePainter(List.of(_levels), widget.color),
      size: const Size(double.infinity, 34),
    );
  }
}

class _WavePainter extends CustomPainter {
  final List<double> levels;
  final Color color;

  _WavePainter(this.levels, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / levels.length;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2, step * 0.55);
    for (var i = 0; i < levels.length; i++) {
      final v = levels[i];
      final h = math.max(3.0, v * size.height);
      final x = step * (i + 0.5);
      paint.color = color.withOpacity(0.35 + 0.65 * (i / levels.length));
      canvas.drawLine(Offset(x, (size.height - h) / 2),
          Offset(x, (size.height + h) / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => true;
}

class _MicButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback? onTap;

  const _MicButton({
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? color : Colors.grey.shade300,
          boxShadow: [
            BoxShadow(
              color: (enabled ? color : Colors.grey).withOpacity(0.35),
              blurRadius: active ? 22 : 12,
              spreadRadius: active ? 4 : 0,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 38),
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _SideButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Icon(icon, color: enabled ? color : Colors.grey[350], size: 28),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: enabled ? color : Colors.grey[400],
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// The ayah recited: how many words were right, the ones to fix, and what
/// next.
class _ReciteDonePanel extends StatelessWidget {
  final int right;
  final int total;
  final List<String> mistakes;
  final Color color;
  final bool autoNext;
  final bool hasNext;
  final ValueChanged<int> onHear;
  final VoidCallback onAgain;
  final VoidCallback? onPractise;
  final VoidCallback onNext;
  final VoidCallback onHold;

  const _ReciteDonePanel({
    required this.right,
    required this.total,
    required this.mistakes,
    required this.color,
    required this.autoNext,
    required this.hasNext,
    required this.onHear,
    required this.onAgain,
    required this.onPractise,
    required this.onNext,
    required this.onHold,
  });

  @override
  Widget build(BuildContext context) {
    final perfect = mistakes.isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _ScoreRing(right: right, total: total),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        perfect
                            ? 'Every word right, mashaAllah!'
                            : 'Ayah complete',
                        style: TextStyle(
                            color: perfect ? Colors.green.shade700 : color,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(
                        perfect
                            ? '$right of $total words'
                            : '$right of $total words right. Tap a red word to hear it.',
                        style:
                            TextStyle(color: Colors.grey[700], fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          if (!perfect) ...[
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < mistakes.length; i++)
                    ActionChip(
                      avatar: Icon(Icons.volume_up_rounded,
                          size: 16, color: Colors.red.shade700),
                      label: Text(mistakes[i],
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 18)),
                      backgroundColor: Colors.red.withOpacity(0.07),
                      side: BorderSide(color: Colors.red.withOpacity(0.25)),
                      onPressed: () => onHear(i),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (autoNext)
            _AutoNext(color: color, onHold: onHold)
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAgain,
                    icon: const Icon(Icons.replay_rounded, size: 20),
                    label: const Text('Again'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (onPractise != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onPractise,
                      icon:
                          const Icon(Icons.record_voice_over_rounded, size: 20),
                      label: const Text('Practise'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
                if (hasNext) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

/// In a surah: a bar filling up until the next ayah starts, and a way to
/// stay on this one.
class _AutoNext extends StatelessWidget {
  final Color color;
  final VoidCallback onHold;

  const _AutoNext({required this.color, required this.onHold});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Next ayah coming up…',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 2400),
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 5,
                    color: color,
                    backgroundColor: color.withOpacity(0.12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: onHold,
          style: TextButton.styleFrom(foregroundColor: color),
          child: const Text('Stay here'),
        ),
      ],
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int right;
  final int total;

  const _ScoreRing({required this.right, required this.total});

  @override
  Widget build(BuildContext context) {
    final share = total == 0 ? 0.0 : right / total;
    final tone = share == 1
        ? Colors.green.shade600
        : share >= 0.6
            ? Colors.orange.shade700
            : Colors.red.shade600;
    return SizedBox(
      width: 62,
      height: 62,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: share),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 6,
                color: tone,
                backgroundColor: tone.withOpacity(0.15),
              ),
            ),
            Text('$right/$total',
                style: TextStyle(
                    color: tone, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _SurahDonePanel extends StatelessWidget {
  final Map<int, _Score> scores;
  final List<Aya> ayats;
  final Color color;
  final VoidCallback onRestart;

  const _SurahDonePanel({
    required this.scores,
    required this.ayats,
    required this.color,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    var right = 0, total = 0;
    for (final s in scores.values) {
      right += s.right;
      total += s.total;
    }
    final toFix = [
      for (final e in scores.entries)
        if (!e.value.perfect) ayats[e.key].ayatNumberInt
    ]..sort();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded,
              color: Colors.amber.shade700, size: 52),
          const SizedBox(height: 6),
          Text('Surah complete',
              style: TextStyle(
                  color: color, fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$right of $total words right',
              style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          if (toFix.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
                'Practise again: ayah ${toFix.join(', ')}. Tap a dot above to go there.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.orange.shade800, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Recite the surah again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Word by word panels ────────────────────────────────────────────────────

/// What the teacher is doing and saying, with the microphone and controls.
class _CoachPanel extends StatelessWidget {
  final _Phase phase;
  final String message;
  final Color color;
  final Stream<double> level;
  final int attempts;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback? onHearAgain;
  final VoidCallback? onSkip;

  const _CoachPanel({
    required this.phase,
    required this.message,
    required this.color,
    required this.level,
    required this.attempts,
    required this.onPause,
    required this.onResume,
    required this.onHearAgain,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final stopped = phase == _Phase.paused || phase == _Phase.error;
    final Color tone = phase == _Phase.correct
        ? Colors.green.shade700
        : phase == _Phase.wrong || phase == _Phase.error
            ? Colors.red.shade700
            : color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 92,
            child: Center(child: _indicator(tone)),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              message,
              key: ValueKey(message),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: tone, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          if (phase == _Phase.wrong ||
              (attempts > 0 && phase == _Phase.reciter))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Tajweed checks are a guide (beta)',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _control(Icons.replay_rounded, 'Hear again', onHearAgain),
              _control(
                stopped ? Icons.play_arrow_rounded : Icons.pause_rounded,
                stopped
                    ? (phase == _Phase.error ? 'Try again' : 'Resume')
                    : 'Pause',
                stopped ? onResume : onPause,
              ),
              _control(Icons.skip_next_rounded, 'Skip word', onSkip),
            ],
          ),
        ],
      ),
    );
  }

  Widget _indicator(Color tone) {
    switch (phase) {
      case _Phase.yourTurn:
        // The microphone grows with the learner's voice.
        return StreamBuilder<double>(
          stream: level,
          initialData: 0,
          builder: (context, snapshot) {
            final v = snapshot.data ?? 0;
            return Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 90),
                  width: 64 + 28 * v,
                  height: 64 + 28 * v,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.15),
                  ),
                ),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: color,
                  child: const Icon(Icons.mic_rounded,
                      color: Colors.white, size: 32),
                ),
              ],
            );
          },
        );
      case _Phase.reciter:
        return CircleAvatar(
          radius: 32,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(Icons.volume_up_rounded, color: color, size: 32),
        );
      case _Phase.checking:
      case _Phase.loading:
        return SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(color: color, strokeWidth: 3.5),
        );
      case _Phase.correct:
        return Icon(Icons.check_circle_rounded, color: tone, size: 64);
      case _Phase.wrong:
      case _Phase.error:
        return Icon(Icons.error_rounded, color: tone, size: 64);
      default:
        return Icon(Icons.pause_circle_filled_rounded, color: color, size: 64);
    }
  }

  Widget _control(IconData icon, String label, VoidCallback? onTap) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            Icon(icon, color: enabled ? color : Colors.grey[350], size: 28),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: enabled ? color : Colors.grey[400],
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _AyahDonePanel extends StatelessWidget {
  final int firstTry;
  final int total;
  final Color color;
  final bool hasNext;
  final VoidCallback onRepeat;
  final VoidCallback onNext;

  const _AyahDonePanel({
    required this.firstTry,
    required this.total,
    required this.color,
    required this.hasNext,
    required this.onRepeat,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded,
              color: Colors.amber.shade700, size: 52),
          const SizedBox(height: 8),
          Text('Ayah complete',
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$firstTry of $total words right on the first try',
              style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRepeat,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Practise again'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (hasNext) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Next ayah'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
