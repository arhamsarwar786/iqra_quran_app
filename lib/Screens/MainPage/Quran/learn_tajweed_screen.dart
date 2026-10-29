import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../../Models/aya_list_model.dart';
import '../../../Provider/audio_provider.dart';
import '../../../Provider/quran_data_provider.dart';
import '../../../Provider/theme_provider.dart';
import '../../../Services/quran_teacher/teacher_api.dart';
import '../../../Services/quran_teacher/word_recorder.dart';
import '../../../Services/recitation_downloads.dart';

enum _Phase {
  loading,
  reciter,
  yourTurn,
  checking,
  correct,
  wrong,
  ayahDone,
  paused,
  error
}

enum _WordState { pending, correct, wrong }

/// Learn to recite with tajweed, word by word: the reciter says a word, the
/// learner repeats it, and the Quran teacher checks it. A right word turns
/// green and the lesson moves on; a wrong one turns red, and the reciter
/// says it again for another try.
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
  final AudioPlayer _reciter = AudioPlayer();
  final WordRecorder _recorder = WordRecorder();

  late int _ayahIndex = widget.initialIndex;
  Lesson? _lesson;
  List<String> _tokens = const [];
  final Map<int, _WordState> _states = {};
  int _word = 0; // index into _lesson.words
  int _attempts = 0;
  int _firstTry = 0;
  _Phase _phase = _Phase.loading;
  String _message = '';

  // Each run of the lesson loop has an id; pausing, jumping or leaving
  // starts a new one, and the old loop stops at its next step.
  int _run = 0;
  Completer<void> _stopRecording = Completer<void>();

  // How long the learner takes over a word against the reciter, from their
  // recent right words, so the tajweed check follows their own pace.
  final List<double> _paceSamples = [];

  Aya get _aya => widget.ayats[_ayahIndex];
  int get _surahId => int.tryParse(_aya.surahId ?? '') ?? 1;

  @override
  void initState() {
    super.initState();
    // The lesson has its own sound; pause any recitation.
    final audio = context.read<AudioProvider>();
    if (audio.isPlaying) audio.pausePlayback();
    _loadAyah();
  }

  @override
  void dispose() {
    _run++;
    _cancelRecording();
    _reciter.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _cancelRecording() {
    if (!_stopRecording.isCompleted) _stopRecording.complete();
  }

  bool _stale(int run) => !mounted || run != _run;

  Future<void> _loadAyah() async {
    final run = ++_run;
    _cancelRecording();
    setState(() {
      _phase = _Phase.loading;
      _lesson = null;
      _states.clear();
      _word = 0;
      _firstTry = 0;
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
      setState(() => _lesson = lesson);
      _teach(run);
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

      // 3. The teacher checks it.
      setState(() {
        _phase = _Phase.checking;
        _message = 'Checking…';
      });
      final WordCheck result;
      try {
        result = await TeacherApi.check(
          recording: recording,
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

  // ── Controls ─────────────────────────────────────────────────────────────

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

  void _goToAyah(int index) {
    if (index < 0 || index >= widget.ayats.length) return;
    _reciter.pause();
    setState(() => _ayahIndex = index);
    _loadAyah();
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final color = theme.selectedTheme;
    final quran = context.read<QuranDataProvider>();
    final lesson = _lesson;

    return Scaffold(
      backgroundColor: theme.selectedSecondary,
      appBar: AppBar(
        title: const Text('Learn with Tajweed'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _AyahHeader(
              title: quran.recitationTitle(_surahId),
              ayah: _aya.ayatNumberInt,
              done: lesson == null ? 0 : _word.clamp(0, lesson.words.length),
              total: lesson?.words.length ?? 0,
              color: color,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: _AyahWords(
                  tokens: _tokens,
                  lesson: lesson,
                  states: _states,
                  current: _phase == _Phase.ayahDone ? null : _word,
                  phase: _phase,
                  color: color,
                  fontFamily: theme.arabicFontFamily,
                  fontSize: theme.arabicFontSize,
                  onTapWord: _jumpTo,
                ),
              ),
            ),
            _phase == _Phase.ayahDone
                ? _AyahDonePanel(
                    firstTry: _firstTry,
                    total: lesson?.words.length ?? 0,
                    color: color,
                    hasNext: _ayahIndex < widget.ayats.length - 1,
                    onRepeat: () => _goToAyah(_ayahIndex),
                    onNext: () => _goToAyah(_ayahIndex + 1),
                  )
                : _CoachPanel(
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
                  ),
          ],
        ),
      ),
    );
  }
}

class _AyahHeader extends StatelessWidget {
  final String title;
  final int ayah;
  final int done;
  final int total;
  final Color color;

  const _AyahHeader({
    required this.title,
    required this.ayah,
    required this.done,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text('$title · Ayah $ayah',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              Text(total == 0 ? '' : '$done / $total words',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
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
        ],
      ),
    );
  }
}

/// The ayah as the reader shows it, each recited word coloured by how the
/// learner did, and the word being taught highlighted.
class _AyahWords extends StatelessWidget {
  final List<String> tokens;
  final Lesson? lesson;
  final Map<int, _WordState> states;
  final int? current; // index into lesson.words
  final _Phase phase;
  final Color color;
  final String fontFamily;
  final double fontSize;
  final ValueChanged<int> onTapWord;

  const _AyahWords({
    required this.tokens,
    required this.lesson,
    required this.states,
    required this.current,
    required this.phase,
    required this.color,
    required this.fontFamily,
    required this.fontSize,
    required this.onTapWord,
  });

  @override
  Widget build(BuildContext context) {
    final words = lesson?.words ?? const <LessonWord>[];
    final currentToken = current != null && current! < words.length
        ? words[current!].token
        : null;
    final lessonIndex = {
      for (var i = 0; i < words.length; i++) words[i].token: i
    };

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 14,
        children: [
          for (var t = 0; t < tokens.length; t++)
            _wordChip(t, t == currentToken, lessonIndex[t]),
        ],
      ),
    );
  }

  Widget _wordChip(int token, bool isCurrent, int? index) {
    final state = states[token] ?? _WordState.pending;
    final Color ink;
    if ((isCurrent && phase == _Phase.wrong) ||
        (state == _WordState.wrong && !isCurrent)) {
      ink = Colors.red.shade700;
    } else if (state == _WordState.correct) {
      ink = Colors.green.shade700;
    } else if (isCurrent) {
      ink = color;
    } else {
      ink = Colors.black87;
    }
    Color? fill;
    if (isCurrent) {
      fill = phase == _Phase.wrong
          ? Colors.red.withOpacity(0.1)
          : phase == _Phase.correct
              ? Colors.green.withOpacity(0.12)
              : color.withOpacity(0.1);
    }

    return GestureDetector(
      // Pause marks and the verse number are not recited, so not taught.
      onTap: index == null ? null : () => onTapWord(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(10),
          border: isCurrent
              ? Border.all(color: ink.withOpacity(0.6), width: 1.5)
              : null,
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
      ),
    );
  }
}

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
