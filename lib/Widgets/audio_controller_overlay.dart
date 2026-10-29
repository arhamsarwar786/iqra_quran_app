import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iqra/Provider/audio_provider.dart';
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Quran/Quranview.dart';
import 'package:iqra/Widgets/float_over_apps_tile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Tracks the top route so the mini player can step aside for dialogs and
/// bottom sheets, and knows when a reading screen is already showing.
class MiniPlayerRouteObserver extends NavigatorObserver {
  MiniPlayerRouteObserver._();
  static final MiniPlayerRouteObserver instance = MiniPlayerRouteObserver._();

  final ValueNotifier<Route?> topRoute = ValueNotifier(null);
  final Set<Route> _readerRoutes = {};

  bool get isPopupOnTop => topRoute.value is PopupRoute;
  bool get isReaderOnTop => _readerRoutes.contains(topRoute.value);

  @override
  void didPush(Route route, Route? previousRoute) => topRoute.value = route;

  @override
  void didPop(Route route, Route? previousRoute) {
    if (topRoute.value == route) topRoute.value = previousRoute;
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    if (topRoute.value == route) topRoute.value = previousRoute;
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (topRoute.value == oldRoute) topRoute.value = newRoute;
  }
}

/// Mix into the state of a screen that highlights the recitation, so tapping
/// the mini player there does not open the same verses again.
mixin RecitationReaderScreen<T extends StatefulWidget> on State<T> {
  Route? _readerRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == _readerRoute) return;
    final readers = MiniPlayerRouteObserver.instance._readerRoutes;
    if (_readerRoute != null) readers.remove(_readerRoute);
    _readerRoute = route;
    if (route != null) readers.add(route);
  }

  @override
  void dispose() {
    MiniPlayerRouteObserver.instance._readerRoutes.remove(_readerRoute);
    super.dispose();
  }
}

/// Places the recitation mini player above every screen of the app.
class QuranMiniPlayerHost extends StatelessWidget {
  final Widget child;
  const QuranMiniPlayerHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const QuranMiniPlayer(),
      ],
    );
  }
}

/// How the recitation player is shown over the app.
enum MiniPlayerStyle {
  card('Card', 'Full controls', Icons.view_agenda_rounded),
  chip('Chip', 'Compact, move it anywhere', Icons.smart_button_rounded),
  bubble('Floating', 'IQRA logo on top, tap for controls',
      Icons.blur_circular_rounded);

  const MiniPlayerStyle(this.label, this.description, this.icon);
  final String label;
  final String description;
  final IconData icon;
}

class QuranMiniPlayer extends StatefulWidget {
  const QuranMiniPlayer({super.key});

  /// Screen area the player covers while shown, so reading screens can keep
  /// the recited verse clear of it.
  static Rect? occupiedArea;

  /// Style chosen from the player's menu; remembered across launches.
  static final ValueNotifier<MiniPlayerStyle> style =
      ValueNotifier(MiniPlayerStyle.bubble);

  @override
  State<QuranMiniPlayer> createState() => _QuranMiniPlayerState();
}

class _QuranMiniPlayerState extends State<QuranMiniPlayer>
    with TickerProviderStateMixin {
  static const String _positionKey = 'mini_player_position';
  static const String _freeXKey = 'mini_player_free_x';
  static const String _freeYKey = 'mini_player_free_y';
  static const String _styleKey = 'mini_player_style';
  static const double _cardHeight = 82;
  static const double _chipHeight = 58;
  static const double _chipWidth = 236;
  static const double _bubbleSize = 62;
  static const double _edgeGap = 10;
  // Default rests above the app's bottom bars, including Home's raised
  // centre button.
  static const double _defaultBottomClearance = 118;
  // Releasing a chip or bubble this close to the close target stops it.
  static const double _closeRadius = 64;

  /// 0 = top edge, 1 = bottom edge of the space the card can move in.
  double? _fraction;
  double _dragDx = 0;

  // Chip and bubble: the side they rest on (0 = left, 1 = right) and their
  // height as a fraction like [_fraction]. [_dragPos] is the top-left corner
  // while being dragged.
  double _freeX = 1;
  double _freeY = 0.7;
  Offset? _dragPos;
  bool _overClose = false;
  bool _expanded = false;
  // While the player's own menu is open, so the logo does not cover it.
  bool _menuOpen = false;
  bool _faded = false;
  Timer? _fadeTimer;

  late final AnimationController _pulse;
  late final AnimationController _float;
  // Opens and closes the controls around the floating logo.
  late final AnimationController _radial;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _float = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200));
    _radial = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 420),
        reverseDuration: const Duration(milliseconds: 220));
    _restore();
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _pulse.dispose();
    _float.dispose();
    _radial.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble(_positionKey);
      final style = MiniPlayerStyle.values.firstWhere(
          (s) => s.name == prefs.getString(_styleKey),
          orElse: () => MiniPlayerStyle.bubble);
      if (!mounted) return;
      QuranMiniPlayer.style.value = style;
      setState(() {
        if (saved != null) _fraction = saved;
        _freeX = prefs.getDouble(_freeXKey) ?? _freeX;
        _freeY = prefs.getDouble(_freeYKey) ?? _freeY;
      });
    } catch (_) {}
  }

  Future<void> _savePosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_fraction != null) await prefs.setDouble(_positionKey, _fraction!);
      await prefs.setDouble(_freeXKey, _freeX);
      await prefs.setDouble(_freeYKey, _freeY);
    } catch (_) {}
  }

  void _setExpanded(bool expanded) {
    if (_expanded == expanded) return;
    setState(() => _expanded = expanded);
    if (expanded) {
      HapticFeedback.lightImpact();
      _fadeTimer?.cancel();
      _faded = false;
      _radial.forward();
    } else {
      _radial.reverse();
      _scheduleFade();
    }
  }

  Future<void> _setStyle(MiniPlayerStyle style) async {
    QuranMiniPlayer.style.value = style;
    _radial.value = 0;
    setState(() {
      _expanded = false;
      _faded = false;
    });
    _scheduleFade();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_styleKey, style.name);
    } catch (_) {}
  }

  // The bubble dims after a few seconds untouched, like AssistiveTouch, so
  // it stays out of the way of the page.
  void _scheduleFade({bool rebuild = true}) {
    _fadeTimer?.cancel();
    if (_faded) {
      _faded = false;
      if (rebuild) setState(() {});
    }
    _fadeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_expanded && _dragPos == null) {
        setState(() => _faded = true);
      }
    });
  }

  // ── Card: full width, moves up and down ─────────────────────────────────

  double _minTop(MediaQueryData media) => media.padding.top + _edgeGap;

  double _maxTop(MediaQueryData media, [double height = _cardHeight]) {
    final max = media.size.height -
        media.viewInsets.bottom -
        media.padding.bottom -
        height -
        _edgeGap;
    return max < _minTop(media) ? _minTop(media) : max;
  }

  double _top(MediaQueryData media) {
    final min = _minTop(media);
    final max = _maxTop(media);
    if (_fraction == null) {
      return (max - _defaultBottomClearance).clamp(min, max);
    }
    return min + (max - min) * _fraction!;
  }

  void _onVerticalDrag(DragUpdateDetails details, MediaQueryData media) {
    final min = _minTop(media);
    final span = _maxTop(media) - min;
    if (span <= 0) return;
    final top = (_top(media) + details.delta.dy).clamp(min, min + span);
    setState(() => _fraction = (top - min) / span);
  }

  void _onHorizontalDragEnd(DragEndDetails details, double width) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragDx.abs() > width * 0.35 || velocity.abs() > 900) {
      context.read<AudioProvider>().stopPlayback();
    }
    setState(() => _dragDx = 0);
  }

  // ── Chip and bubble: move anywhere, rest against a side ─────────────────

  Offset _closeTarget(MediaQueryData media) => Offset(
      media.size.width / 2, media.size.height - media.padding.bottom - 90);

  Offset _restingTopLeft(MediaQueryData media, Size size) {
    final minLeft = _edgeGap;
    final maxLeft = media.size.width - size.width - _edgeGap;
    final min = _minTop(media);
    final max = _maxTop(media, size.height);
    return Offset(
        minLeft + (maxLeft - minLeft) * _freeX, min + (max - min) * _freeY);
  }

  void _onPanStart(MediaQueryData media, Size size) {
    _fadeTimer?.cancel();
    _radial.value = 0;
    setState(() {
      _faded = false;
      _expanded = false;
      _dragPos = _restingTopLeft(media, size);
    });
  }

  void _onPanUpdate(
      DragUpdateDetails details, MediaQueryData media, Size size) {
    final pos = _dragPos;
    if (pos == null) return;
    final next = Offset(
      (pos.dx + details.delta.dx)
          .clamp(_edgeGap, media.size.width - size.width - _edgeGap),
      (pos.dy + details.delta.dy)
          .clamp(_minTop(media), _maxTop(media, size.height)),
    );
    final center = next + Offset(size.width / 2, size.height / 2);
    final overClose = (center - _closeTarget(media)).distance < _closeRadius;
    if (overClose && !_overClose) HapticFeedback.mediumImpact();
    setState(() {
      _dragPos = next;
      _overClose = overClose;
    });
  }

  void _onPanEnd(MediaQueryData media, Size size) {
    final pos = _dragPos;
    if (pos == null) return;
    if (_overClose) {
      context.read<AudioProvider>().stopPlayback();
    } else {
      final min = _minTop(media);
      final span = _maxTop(media, size.height) - min;
      _freeX = pos.dx + size.width / 2 < media.size.width / 2 ? 0 : 1;
      _freeY = span <= 0 ? 0 : ((pos.dy - min) / span).clamp(0.0, 1.0);
      _savePosition();
    }
    setState(() {
      _dragPos = null;
      _overClose = false;
    });
    _scheduleFade();
  }

  void _openRecitedVerse(AudioProvider audio) {
    final surahId = audio.currentSurahId;
    final navigator = appNavigatorKey.currentState;
    if (surahId == null || navigator == null) return;
    _setExpanded(false);
    if (MiniPlayerRouteObserver.instance.isReaderOnTop) return;

    final metadata =
        context.read<QuranDataProvider>().getSurahMetadata(surahId);
    navigator.push(MaterialPageRoute(
      builder: (_) => QuranView(
        suratNumber: surahId,
        surahName: audio.currentSurahName,
        ayatCount: metadata?.surahTotalAyaat.toString(),
        targetAyatNumber: audio.isBismillah ? null : audio.currentAyahNumber,
        saveLastRead: false,
      ),
    ));
  }

  // The player sits above the Navigator, so its menu opens in the
  // Navigator's context.
  void _showMenu() {
    final navigatorContext = appNavigatorKey.currentContext;
    if (navigatorContext == null) return;
    _radial.value = 0;
    setState(() {
      _expanded = false;
      _menuOpen = true;
    });
    final audio = context.read<AudioProvider>();
    showModalBottomSheet<void>(
      context: navigatorContext,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PlayerMenuSheet(
        current: QuranMiniPlayer.style.value,
        onStyle: (style) {
          Navigator.pop(sheetContext);
          _setStyle(style);
        },
        onOpen: () {
          Navigator.pop(sheetContext);
          _openRecitedVerse(audio);
        },
        onStop: () {
          Navigator.pop(sheetContext);
          audio.stopPlayback();
        },
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _menuOpen = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final media = MediaQuery.of(context);

    if (audio.isPlaying && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!audio.isPlaying && _pulse.isAnimating) {
      _pulse.stop();
    }

    return ValueListenableBuilder<Route?>(
      valueListenable: MiniPlayerRouteObserver.instance.topRoute,
      builder: (context, _, __) {
        return ValueListenableBuilder<MiniPlayerStyle>(
          valueListenable: QuranMiniPlayer.style,
          builder: (context, style, _) {
            // The floating logo stays on top of everything, dialogs and
            // sheets included; the card and chip step aside for them.
            final visible = audio.isActive &&
                (style == MiniPlayerStyle.bubble
                    ? !_menuOpen
                    : !MiniPlayerRouteObserver.instance.isPopupOnTop);
            final floating = visible && style == MiniPlayerStyle.bubble;
            if (floating && !_float.isAnimating) {
              _float.repeat();
              _scheduleFade(rebuild: false);
            } else if (!floating && _float.isAnimating) {
              _float.stop();
            }
            if (!visible && _expanded) {
              _expanded = false;
              _radial.value = 0;
            }
            return style == MiniPlayerStyle.card
                ? _buildCard(audio, media, visible)
                : _buildFree(audio, media, visible, style);
          },
        );
      },
    );
  }

  Widget _buildCard(AudioProvider audio, MediaQueryData media, bool visible) {
    final width = media.size.width;
    final top = _top(media);
    QuranMiniPlayer.occupiedArea =
        visible ? Rect.fromLTWH(12, top, width - 24, _cardHeight) : null;
    return Positioned(
      left: 12 + _dragDx,
      right: 12 - _dragDx,
      top: top,
      height: _cardHeight,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 0.4),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity:
                visible ? (1 - (_dragDx.abs() / width)).clamp(0.2, 1.0) : 0,
            duration: const Duration(milliseconds: 200),
            // Its own semantics node, so screen readers see the card's
            // bounds instead of merging its text into the page.
            child: Semantics(
              container: true,
              child: GestureDetector(
                onTap: () => _openRecitedVerse(audio),
                onVerticalDragUpdate: (d) => _onVerticalDrag(d, media),
                onVerticalDragEnd: (_) => _savePosition(),
                onHorizontalDragUpdate: (d) =>
                    setState(() => _dragDx += d.delta.dx),
                onHorizontalDragEnd: (d) => _onHorizontalDragEnd(d, width),
                child: _MiniPlayerCard(
                    audio: audio, pulse: _pulse, onMore: _showMenu),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFree(AudioProvider audio, MediaQueryData media, bool visible,
      MiniPlayerStyle style) {
    final bubble = style == MiniPlayerStyle.bubble;
    final screen = media.size;
    final size = bubble
        ? const Size(_bubbleSize, _bubbleSize)
        : Size(math.min(_chipWidth, screen.width - 2 * _edgeGap), _chipHeight);
    final dragging = _dragPos != null;
    final pos = _dragPos ?? _restingTopLeft(media, size);
    QuranMiniPlayer.occupiedArea = visible ? pos & size : null;
    final theme = context.watch<ThemeProvider>().selectedTheme;

    final item = Semantics(
      container: true,
      child: GestureDetector(
        onTap: () {
          if (bubble) {
            _setExpanded(!_expanded);
          } else {
            _openRecitedVerse(audio);
          }
        },
        onPanStart: (_) => _onPanStart(media, size),
        onPanUpdate: (d) => _onPanUpdate(d, media, size),
        onPanEnd: (_) => _onPanEnd(media, size),
        child: bubble
            ? _FloatingLogo(
                audio: audio,
                pulse: _pulse,
                float: _float,
                color: theme,
                size: _bubbleSize,
                floating: !dragging && !_expanded,
              )
            : _MiniPlayerChip(audio: audio, pulse: _pulse, onMore: _showMenu),
      ),
    );

    final close = _closeTarget(media);

    return Positioned.fill(
      child: Stack(
        children: [
          if (visible && _expanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _setExpanded(false),
                child: AnimatedBuilder(
                  animation: _radial,
                  builder: (context, _) => ColoredBox(
                      color: Colors.black.withOpacity(0.4 * _radial.value)),
                ),
              ),
            ),
          if (visible && dragging)
            Positioned(
              left: close.dx - 32,
              top: close.dy - 32,
              child: _CloseTarget(active: _overClose),
            ),
          if (visible && bubble)
            Positioned.fill(
              child: _RadialControls(
                animation: _radial,
                enabled: _expanded,
                audio: audio,
                color: theme,
                anchor: pos & size,
                bounds: Rect.fromLTRB(
                  _edgeGap,
                  _minTop(media),
                  screen.width - _edgeGap,
                  screen.height - media.padding.bottom - _edgeGap,
                ),
                onOpen: () => _openRecitedVerse(audio),
                onMore: _showMenu,
              ),
            ),
          AnimatedPositioned(
            // Follows the finger while dragged, then glides to the side.
            duration:
                dragging ? Duration.zero : const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            left: pos.dx,
            top: pos.dy,
            width: size.width,
            height: size.height,
            child: IgnorePointer(
              ignoring: !visible,
              child: AnimatedScale(
                scale: !visible
                    ? 0.2
                    : (_overClose ? 0.75 : (dragging || _expanded ? 1.1 : 1)),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: AnimatedOpacity(
                  opacity: !visible ? 0 : (_faded && bubble ? 0.55 : 1),
                  duration: const Duration(milliseconds: 300),
                  child: item,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _ayahSubtitle(BuildContext context, AudioProvider audio) =>
    audio.ayahSubtitle(context.read<QuranDataProvider>());

class _MiniPlayerCard extends StatelessWidget {
  final AudioProvider audio;
  final Animation<double> pulse;
  final VoidCallback onMore;

  const _MiniPlayerCard(
      {required this.audio, required this.pulse, required this.onMore});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().selectedTheme;
    final deep = Color.lerp(theme, Colors.black, 0.35)!;
    final subtitle = _ayahSubtitle(context, audio);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme, deep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: deep.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            children: [
              // Drag handle, hinting that the card can be moved.
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 2, 0),
                  child: Row(
                    children: [
                      // Decorative, and animated every frame: keeping it out of
                      // the accessibility tree avoids flooding TalkBack.
                      ExcludeSemantics(
                        child: _Artwork(pulse: pulse, playing: audio.isPlaying),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              audio.currentSurahName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ControlButton(
                        icon: Icons.skip_previous_rounded,
                        label: 'Previous ayah',
                        onPressed: audio.skipPrevious,
                      ),
                      _PlayPauseButton(audio: audio, color: theme),
                      _ControlButton(
                        icon: Icons.skip_next_rounded,
                        label: 'Next ayah',
                        onPressed: audio.hasNext ? audio.skipNext : null,
                      ),
                      _ControlButton(
                        icon: Icons.more_vert_rounded,
                        label: 'Player options',
                        size: 22,
                        onPressed: onMore,
                      ),
                      _ControlButton(
                        icon: Icons.close_rounded,
                        label: 'Close player',
                        size: 20,
                        onPressed: audio.stopPlayback,
                      ),
                    ],
                  ),
                ),
              ),
              // Its value changes every frame; announcing it would flood
              // TalkBack, and the ayah is already read out above.
              ExcludeSemantics(child: _ProgressBar(audio: audio)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact pill: artwork with a progress ring, the ayah, play/pause and the
/// options menu.
class _MiniPlayerChip extends StatelessWidget {
  final AudioProvider audio;
  final Animation<double> pulse;
  final VoidCallback onMore;

  const _MiniPlayerChip(
      {required this.audio, required this.pulse, required this.onMore});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().selectedTheme;
    final deep = Color.lerp(theme, Colors.black, 0.35)!;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.only(left: 6, right: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [theme, deep]),
          borderRadius:
              BorderRadius.circular(_QuranMiniPlayerState._chipHeight),
          boxShadow: [
            BoxShadow(
              color: deep.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: SizedBox(
                width: 46,
                height: 46,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _Artwork(pulse: pulse, playing: audio.isPlaying),
                    Positioned.fill(child: _ProgressRing(audio: audio)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    audio.currentSurahName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  Text(
                    _ayahSubtitle(context, audio),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 11),
                  ),
                ],
              ),
            ),
            _PlayPauseButton(audio: audio, color: theme),
            _ControlButton(
              icon: Icons.more_vert_rounded,
              label: 'Player options',
              size: 22,
              onPressed: onMore,
            ),
          ],
        ),
      ),
    );
  }
}

/// The minimal player: the app's logo floating over the page, ringed by the
/// ayah's progress, with a soft pulse while reciting.
class _FloatingLogo extends StatelessWidget {
  final AudioProvider audio;
  final Animation<double> pulse;
  final Animation<double> float;
  final Color color;
  final double size;
  final bool floating;

  const _FloatingLogo({
    required this.audio,
    required this.pulse,
    required this.float,
    required this.color,
    required this.size,
    required this.floating,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Recitation player, ${audio.currentSurahName}. '
          'Tap for controls',
      child: AnimatedBuilder(
        animation: Listenable.merge([pulse, float]),
        builder: (context, child) {
          final bob = floating ? math.sin(float.value * 2 * math.pi) * 3 : 0.0;
          final t = audio.isPlaying ? pulse.value : 0.0;
          return Transform.translate(
            offset: Offset(0, bob),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (audio.isPlaying)
                  Container(
                    width: size + 14 * t,
                    height: size + 14 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.25 * (1 - t)),
                    ),
                  ),
                child!,
              ],
            ),
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: _ProgressRing(audio: audio, color: color, width: 3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/iqra-white-logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Tells at a glance whether it is reciting or paused.
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    audio.isPlaying
                        ? Icons.graphic_eq_rounded
                        : Icons.pause_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Controls that fan out of the floating logo when it is tapped: previous,
/// play/pause and next on an arc facing into the screen, and above them the
/// surah being recited with a ⋮ menu for more options.
class _RadialControls extends StatelessWidget {
  final Animation<double> animation;

  /// False while closing, so the fading buttons ignore taps.
  final bool enabled;
  final AudioProvider audio;
  final Color color;

  /// Where the logo is.
  final Rect anchor;

  /// Area the controls must stay inside.
  final Rect bounds;
  final VoidCallback onOpen;
  final VoidCallback onMore;

  const _RadialControls({
    required this.animation,
    required this.enabled,
    required this.audio,
    required this.color,
    required this.anchor,
    required this.bounds,
    required this.onOpen,
    required this.onMore,
  });

  static const double _radius = 86;
  static const double _button = 50;
  static const double _mainButton = 62;
  static const double _labelSpace = 22;
  static const double _pillWidth = 236;
  static const double _pillHeight = 58;

  // Previous, play/pause and next, from the top of the arc down.
  static const List<double> _arc = [-1.15, 0, 1.15];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        if (t == 0) return const SizedBox.shrink();
        final center = anchor.center;
        final inward = center.dx > bounds.center.dx ? -1.0 : 1.0;
        final targets = _targets(center, inward);
        final pill = _pillRect(center, inward, targets);

        Offset at(int i) {
          // Each button leaves the logo a little after the one before.
          final p =
              Interval(i * 0.12, 0.64 + i * 0.12, curve: Curves.easeOutBack)
                  .transform(t);
          return Offset.lerp(center, targets[i], p)!;
        }

        double shown(int i) =>
            Interval(i * 0.12, 0.5 + i * 0.12).transform(t).clamp(0.0, 1.0);

        final playing = audio.isPlaying;
        return IgnorePointer(
          ignoring: !enabled,
          // These sit above the Navigator, outside any Material, so the
          // labels need one for their text style.
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _place(
                  at(0),
                  shown(0),
                  _button,
                  _RadialButton(
                    icon: Icons.skip_previous_rounded,
                    label: 'Previous',
                    size: _button,
                    color: color,
                    onTap: audio.skipPrevious,
                  ),
                ),
                _place(
                  at(1),
                  shown(1),
                  _mainButton,
                  _RadialButton(
                    icon: playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    label: playing ? 'Pause' : 'Play',
                    size: _mainButton,
                    color: color,
                    filled: true,
                    loading: audio.isBuffering && playing,
                    audio: audio,
                    onTap: audio.togglePlayback,
                  ),
                ),
                _place(
                  at(2),
                  shown(2),
                  _button,
                  _RadialButton(
                    icon: Icons.skip_next_rounded,
                    label: 'Next',
                    size: _button,
                    color: color,
                    onTap: audio.hasNext ? audio.skipNext : null,
                  ),
                ),
                Positioned.fromRect(
                  rect: pill,
                  child: Opacity(
                    opacity: shown(3),
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - shown(3))),
                      child: _NowRecitingPill(
                        audio: audio,
                        color: color,
                        onOpen: onOpen,
                        onMore: onMore,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Centres a button of [size] on [center]; its label hangs below.
  Widget _place(Offset center, double shown, double size, Widget button) {
    const width = 84.0;
    return Positioned(
      left: center.dx - width / 2,
      top: center.dy - size / 2,
      width: width,
      child: Opacity(
        opacity: shown,
        child: Transform.scale(scale: 0.3 + 0.7 * shown, child: button),
      ),
    );
  }

  // The arc faces into the screen; near the top or bottom it turns until
  // every button fits.
  List<Offset> _targets(Offset center, double inward) {
    final safe = Rect.fromLTRB(
      bounds.left + _mainButton / 2,
      bounds.top + _mainButton / 2,
      bounds.right - _mainButton / 2,
      bounds.bottom - _mainButton / 2 - _labelSpace,
    );
    List<Offset> arc(double turn) => [
          for (final a in _arc)
            center +
                Offset(inward * _radius * math.cos(a + turn),
                    _radius * math.sin(a + turn)),
        ];
    for (var step = 0; step <= 6; step++) {
      for (final sign in step == 0 ? const [1.0] : const [1.0, -1.0]) {
        final points = arc(sign * step * 0.17);
        if (points.every(safe.contains)) return points;
      }
    }
    return arc(0);
  }

  Rect _pillRect(Offset center, double inward, List<Offset> targets) {
    final width = math.min(_pillWidth, bounds.width);
    final left = (center.dx + inward * _radius * 0.5 - width / 2)
        .clamp(bounds.left, bounds.right - width);
    final highest = targets.map((p) => p.dy).reduce(math.min);
    final lowest = targets.map((p) => p.dy).reduce(math.max);
    // The top and bottom of the arc are the smaller buttons.
    final above = highest - _button / 2 - 10 - _pillHeight;
    final top = above >= bounds.top
        ? above
        : math.min(lowest + _button / 2 + _labelSpace + 8,
            bounds.bottom - _pillHeight);
    return Rect.fromLTWH(left, top, width, _pillHeight);
  }
}

class _RadialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final double size;
  final Color color;
  final bool filled;
  final bool loading;

  /// For the progress ring around the main button.
  final AudioProvider? audio;
  final VoidCallback? onTap;

  const _RadialButton({
    required this.icon,
    required this.label,
    required this.size,
    required this.color,
    required this.onTap,
    this.filled = false,
    this.loading = false,
    this.audio,
  });

  @override
  Widget build(BuildContext context) {
    final deep = Color.lerp(color, Colors.black, 0.35)!;
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? null : Colors.white,
                gradient: filled
                    ? LinearGradient(
                        colors: [color, deep],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border:
                    filled ? Border.all(color: Colors.white, width: 3) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (audio != null)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: ExcludeSemantics(
                          child: _ProgressRing(audio: audio!, width: 2.5),
                        ),
                      ),
                    ),
                  if (loading)
                    SizedBox(
                      width: size * 0.4,
                      height: size * 0.4,
                      child: const CircularProgressIndicator(
                          strokeWidth: 3, color: Colors.white),
                    )
                  else
                    Icon(
                      icon,
                      size: size * 0.5,
                      color: filled
                          ? Colors.white
                          : (enabled ? color : color.withOpacity(0.3)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The surah and ayah being recited; tap to open it, ⋮ for more options.
class _NowRecitingPill extends StatelessWidget {
  final AudioProvider audio;
  final Color color;
  final VoidCallback onOpen;
  final VoidCallback onMore;

  const _NowRecitingPill({
    required this.audio,
    required this.color,
    required this.onOpen,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: Colors.black45,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 2),
          child: Row(
            children: [
              Icon(Icons.graphic_eq_rounded, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audio.currentSurahName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _ayahSubtitle(context, audio),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700], fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              // No tooltip: the player sits above the Navigator, outside
              // any Overlay.
              Semantics(
                label: 'More options',
                button: true,
                child: IconButton(
                  onPressed: onMore,
                  icon: Icon(Icons.more_vert_rounded, color: color),
                  splashRadius: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Drop zone shown while a chip or bubble is dragged; releasing over it
/// stops the recitation.
class _CloseTarget extends StatelessWidget {
  final bool active;
  const _CloseTarget({required this.active});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, t, child) =>
          Transform.scale(scale: t * (active ? 1.25 : 1), child: child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? Colors.red.shade400 : Colors.black.withOpacity(0.55),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}

/// The ⋮ menu: choose the player's style, open the surah or stop.
class _PlayerMenuSheet extends StatelessWidget {
  final MiniPlayerStyle current;
  final ValueChanged<MiniPlayerStyle> onStyle;
  final VoidCallback onOpen;
  final VoidCallback onStop;

  const _PlayerMenuSheet({
    required this.current,
    required this.onStyle,
    required this.onOpen,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().selectedTheme;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Player style',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final style in MiniPlayerStyle.values) ...[
                if (style != MiniPlayerStyle.values.first)
                  const SizedBox(width: 10),
                Expanded(
                  child: _StyleOption(
                    style: style,
                    selected: style == current,
                    color: theme,
                    onTap: () => onStyle(style),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const FloatOverAppsTile(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.menu_book_rounded, color: theme),
            title: const Text('Open the surah being recited'),
            onTap: onOpen,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.stop_circle_rounded, color: theme),
            title: const Text('Stop recitation'),
            onTap: onStop,
          ),
        ],
      ),
    );
  }
}

class _StyleOption extends StatelessWidget {
  final MiniPlayerStyle style;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StyleOption({
    required this.style,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                  height: 40, child: _StylePreview(style: style, color: color)),
              const SizedBox(height: 8),
              Text(style.label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? color : Colors.black87)),
              const SizedBox(height: 2),
              Text(
                style.description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tiny drawing of each style, so the choice is clear before picking it.
class _StylePreview extends StatelessWidget {
  final MiniPlayerStyle style;
  final Color color;

  const _StylePreview({required this.style, required this.color});

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case MiniPlayerStyle.card:
        return Container(
          width: 76,
          height: 30,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(8)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(Icons.skip_previous_rounded, color: Colors.white, size: 14),
              Icon(Icons.play_circle_fill_rounded,
                  color: Colors.white, size: 16),
              Icon(Icons.skip_next_rounded, color: Colors.white, size: 14),
            ],
          ),
        );
      case MiniPlayerStyle.chip:
        return Container(
          width: 60,
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(12)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(radius: 7, backgroundColor: Colors.white),
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
            ],
          ),
        );
      case MiniPlayerStyle.bubble:
        return Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6),
            ],
          ),
          child: ClipOval(
            child: Image.asset('assets/images/iqra-white-logo.png',
                fit: BoxFit.cover),
          ),
        );
    }
  }
}

/// Progress through the current ayah as a ring.
class _ProgressRing extends StatelessWidget {
  final AudioProvider audio;
  final Color color;
  final double width;

  const _ProgressRing(
      {required this.audio, this.color = Colors.white, this.width = 2.5});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: audio.positionStream,
      builder: (context, snapshot) {
        final total = audio.currentDuration?.inMilliseconds ?? 0;
        final position = snapshot.data?.inMilliseconds ?? 0;
        return CircularProgressIndicator(
          value: total > 0 ? (position / total).clamp(0.0, 1.0) : 0.0,
          strokeWidth: width,
          color: color,
          backgroundColor: color.withOpacity(0.2),
        );
      },
    );
  }
}

class _Artwork extends StatelessWidget {
  final Animation<double> pulse;
  final bool playing;

  const _Artwork({required this.pulse, required this.playing});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, child) {
          final t = playing ? pulse.value : 0.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (playing)
                Container(
                  width: 40 + 6 * t,
                  height: 40 + 6 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5 * (1 - t)),
                      width: 2,
                    ),
                  ),
                ),
              child!,
            ],
          );
        },
        child: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: Image.asset(
              'assets/images/iqra-white-logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double size;

  const _ControlButton(
      {required this.icon,
      required this.label,
      required this.onPressed,
      this.size = 26});

  @override
  Widget build(BuildContext context) {
    // No tooltip: the player sits above the Navigator, outside any Overlay.
    return MergeSemantics(
      child: Semantics(
        label: label,
        child: _iconButton(),
      ),
    );
  }

  Widget _iconButton() {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: size),
      color: Colors.white,
      disabledColor: Colors.white38,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final AudioProvider audio;
  final Color color;

  const _PlayPauseButton({required this.audio, required this.color});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: audio.isPlaying ? 'Pause' : 'Play',
      child: _button(),
    );
  }

  Widget _button() {
    return GestureDetector(
      onTap: audio.togglePlayback,
      child: Container(
        width: 42,
        height: 42,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: audio.isBuffering && audio.isPlaying
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: color,
                ),
              )
            : Icon(
                audio.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: color,
                size: 28,
              ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final AudioProvider audio;
  const _ProgressBar({required this.audio});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: audio.positionStream,
      builder: (context, snapshot) {
        final total = audio.currentDuration?.inMilliseconds ?? 0;
        final position = snapshot.data?.inMilliseconds ?? 0;
        final value = total > 0 ? (position / total).clamp(0.0, 1.0) : 0.0;
        return LinearProgressIndicator(
          value: value,
          minHeight: 3,
          backgroundColor: Colors.white.withOpacity(0.18),
          valueColor: const AlwaysStoppedAnimation(Colors.white),
        );
      },
    );
  }
}
