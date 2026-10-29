import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom bar of the Quran reading screens: two actions either side of a
/// large recitation button that rises out of a notch in the bar. While the
/// recitation plays, previous and next buttons slide out beside it.
class ReaderBottomBar extends StatelessWidget {
  final Color color;
  final List<Widget> leading;
  final List<Widget> trailing;
  final Widget centerButton;
  final String centerLabel;

  /// Skip controls, shown beside the centre button while [onPrevious] is
  /// set. Next is disabled while [onNext] is null, on the last verse.
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  static const double _barHeight = 66;
  static const double _buttonSize = RecitationPlayButton.size;
  // How far the button rises above the bar.
  static const double _rise = 32;
  static const double _skipSize = 38;
  // Centre of each skip button from the centre of the bar.
  static const double _skipOffset = _buttonSize / 2 + 12 + _skipSize / 2;

  const ReaderBottomBar({
    super.key,
    required this.color,
    required this.leading,
    required this.trailing,
    required this.centerButton,
    required this.centerLabel,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final showSkip = onPrevious != null;
    // The bar's own height includes the raised part so the whole button
    // receives taps.
    return SizedBox(
      height: _barHeight + _rise,
      child: LayoutBuilder(builder: (context, constraints) {
        final center = constraints.maxWidth / 2;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _barHeight,
              child: CustomPaint(
                painter: _NotchedBarPainter(
                  color: color,
                  notchCenterY: _buttonSize / 2 - _rise,
                  notchRadius: _buttonSize / 2 + 6,
                ),
                child: Row(
                  children: [
                    ...leading.map((item) => Expanded(child: item)),
                    SizedBox(
                      width: _buttonSize + 24,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              centerLabel,
                              key: ValueKey(centerLabel),
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    ...trailing.map((item) => Expanded(child: item)),
                  ],
                ),
              ),
            ),
            // Skip buttons sit behind the centre button and slide out of it.
            TweenAnimationBuilder<double>(
              tween: Tween(end: showSkip ? 1 : 0),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              builder: (context, t, _) {
                if (t <= 0.01) return const SizedBox.shrink();
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _skip(
                        center - _skipOffset * t,
                        t,
                        Icons.skip_previous_rounded,
                        'Previous ayah',
                        onPrevious),
                    _skip(center + _skipOffset * t, t, Icons.skip_next_rounded,
                        'Next ayah', onNext),
                  ],
                );
              },
            ),
            Positioned(
              top: 0,
              left: center - _buttonSize / 2,
              child: centerButton,
            ),
          ],
        );
      }),
    );
  }

  Widget _skip(double centerX, double t, IconData icon, String label,
      VoidCallback? onTap) {
    return Positioned(
      top: 2,
      left: centerX - _skipSize / 2,
      child: Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.5 + 0.5 * t,
          child: _SkipButton(
            icon: icon,
            label: label,
            color: color,
            size: _skipSize,
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  const _SkipButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: color.withOpacity(0.5),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon,
                color: onTap == null ? color.withOpacity(0.3) : color,
                size: size * 0.62),
          ),
        ),
      ),
    );
  }
}

class _NotchedBarPainter extends CustomPainter {
  final Color color;
  final double notchCenterY;
  final double notchRadius;

  _NotchedBarPainter({
    required this.color,
    required this.notchCenterY,
    required this.notchRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final host = Offset.zero & size;
    final guest = Rect.fromCircle(
      center: Offset(size.width / 2, notchCenterY),
      radius: notchRadius,
    );
    final notched = const CircularNotchedRectangle().getOuterPath(host, guest);
    final rounded = Path()
      ..addRRect(RRect.fromRectAndCorners(
        host,
        topLeft: const Radius.circular(24),
        topRight: const Radius.circular(24),
      ));
    final path = Path.combine(PathOperation.intersect, notched, rounded);

    canvas.drawShadow(path, Colors.black, 10, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.12)!,
            color,
            Color.lerp(color, Colors.black, 0.25)!,
          ],
        ).createShader(host),
    );
    // A faint highlight along the top edge gives the bar some depth.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(0.18),
    );
  }

  @override
  bool shouldRepaint(_NotchedBarPainter old) =>
      old.color != color ||
      old.notchCenterY != notchCenterY ||
      old.notchRadius != notchRadius;
}

/// An icon with a label, for either side of [ReaderBottomBar].
class ReaderBarItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const ReaderBarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        highlightColor: Colors.transparent,
        splashColor: Colors.white24,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 28, child: Center(child: icon)),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Large play/pause button for the recitation. While idle it breathes
/// gently to invite a tap; while the recitation loads a sound wave dances
/// inside it; while reciting, light sweeps around its rim and ripples spread
/// from it.
class RecitationPlayButton extends StatefulWidget {
  static const double size = 70;

  final Color color;
  final bool isPlaying;

  /// Starting or buffering: shows the loading wave.
  final bool isLoading;
  final VoidCallback onPressed;

  const RecitationPlayButton({
    super.key,
    required this.color,
    required this.isPlaying,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<RecitationPlayButton> createState() => _RecitationPlayButtonState();
}

class _RecitationPlayButtonState extends State<RecitationPlayButton>
    with TickerProviderStateMixin {
  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
    value: widget.isPlaying ? 1 : 0,
  );
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();
  bool _pressed = false;

  @override
  void didUpdateWidget(RecitationPlayButton old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      widget.isPlaying ? _morph.forward() : _morph.reverse();
    }
  }

  @override
  void dispose() {
    _morph.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = RecitationPlayButton.size;
    final color = widget.color;
    final deep = Color.lerp(color, Colors.black, 0.35)!;
    final light = Color.lerp(color, Colors.white, 0.25)!;
    final loading = widget.isLoading;
    final playing = widget.isPlaying && !loading;

    return Semantics(
      button: true,
      label: loading
          ? 'Loading recitation'
          : (widget.isPlaying ? 'Pause recitation' : 'Play recitation'),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: AnimatedBuilder(
            animation: _loop,
            builder: (context, _) {
              final t = _loop.value;
              // Breathing while idle: one slow swell per loop.
              final breathe = playing || loading
                  ? 1.0
                  : 1 + 0.035 * math.sin(t * 2 * math.pi);
              return SizedBox(
                width: size,
                height: size,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (playing) ...[
                      _ripple(t % 1, color),
                      _ripple((t + 0.5) % 1, color),
                    ],
                    Transform.scale(
                      scale: breathe,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: deep.withOpacity(playing ? 0.5 : 0.35),
                              blurRadius: playing ? 18 : 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (playing || loading)
                      Transform.rotate(
                        // Spins faster while loading.
                        angle: t * 2 * math.pi * (loading ? 2 : 1),
                        child: SizedBox(
                          width: size - 4,
                          height: size - 4,
                          child: CustomPaint(
                            painter: _SweepRingPainter(color: color),
                          ),
                        ),
                      ),
                    Container(
                      width: size - 12,
                      height: size - 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [light, color, deep],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(
                          scale: animation,
                          child:
                              FadeTransition(opacity: animation, child: child),
                        ),
                        child: loading
                            ? _LoadingWave(key: const ValueKey('wave'), t: t)
                            : AnimatedIcon(
                                key: const ValueKey('icon'),
                                icon: AnimatedIcons.play_pause,
                                progress: _morph,
                                color: Colors.white,
                                size: 36,
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _ripple(double t, Color color) {
    final size = RecitationPlayButton.size * (1 + 0.55 * t);
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withOpacity(0.45 * (1 - t)),
            width: 2.5,
          ),
        ),
      ),
    );
  }
}

/// Five bars rising and falling one after another, like a voice warming up.
class _LoadingWave extends StatelessWidget {
  /// Position in the button's animation loop, 0 to 1.
  final double t;

  const _LoadingWave({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < 5; i++)
            Container(
              width: 4,
              height: 28 *
                  (0.3 +
                      0.7 * math.sin(((t * 3 - i * 0.12) % 1) * math.pi).abs()),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

/// A bright arc fading into its tail, rotated to look like light circling
/// the button's rim.
class _SweepRingPainter extends CustomPainter {
  final Color color;

  _SweepRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [color.withOpacity(0), color],
      ).createShader(rect);
    canvas.drawArc(rect.deflate(2), 0, math.pi * 1.6, false, paint);
  }

  @override
  bool shouldRepaint(_SweepRingPainter old) => old.color != color;
}
