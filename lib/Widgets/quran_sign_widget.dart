import 'package:flutter/material.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';

class QuranSignWidget extends StatelessWidget {
  final String sign;
  final String? topNumber;
  final String? middleNumber;
  final String? bottomNumber;
  final String? label;

  const QuranSignWidget({
    super.key,
    required this.sign,
    this.topNumber,
    this.middleNumber,
    this.bottomNumber,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final color = theme.selectedTheme;
    final arabicFont = theme.arabicFontFamily;

    final bool isRuko = sign == "ع";
    final double frameHeight = isRuko ? 110 : 80;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // THE FRAME
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width - 40, frameHeight),
            painter: QuranSignPainter(color: color),
          ),

          // 1. THE MAIN RUKO SIGN (Balanced vertically)
          Transform.translate(
            offset: const Offset(
                0, -10), // Moved up slightly to be truly centered in the frame
            child: Text(
              sign,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isRuko ? 75 : 40,
                fontFamily: arabicFont,
                color: color,
                height: 1.0,
              ),
            ),
          ),

          // 2. THE LABEL (e.g., Arba/Nisf)
          if (label != null && label!.isNotEmpty)
            Positioned(
              left: MediaQuery.of(context).size.width / 2 + (isRuko ? 50 : 35),
              child: Text(
                label!,
                style: TextStyle(
                  fontSize: 22, // Increased font size
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: arabicFont,
                ),
              ),
            ),

          // 3. THE MIDDLE NUMBER (Positioned to the LEFT)
          if (middleNumber != null)
            Positioned(
              right: MediaQuery.of(context).size.width / 2 + (isRuko ? 50 : 35),
              child: Text(
                middleNumber!,
                style: TextStyle(
                  fontSize: 18, // Increased font size for readability
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: arabicFont,
                ),
              ),
            ),

          // 4. TOP NUMBER + DOT
          Positioned(
            top: -24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRuko || topNumber != null)
                  Container(
                    width: 7,
                    height: 7,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                const SizedBox(height: 1),
                if (topNumber != null)
                  Text(
                    topNumber!,
                    style: TextStyle(
                      fontSize: 18, // Increased count font size
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: arabicFont,
                      height: 1,
                    ),
                  ),
              ],
            ),
          ),

          // 5. BOTTOM NUMBER + DOT
          Positioned(
            bottom: -24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (bottomNumber != null)
                  Text(
                    bottomNumber!,
                    style: TextStyle(
                      fontSize: 18, // Increased count font size
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: arabicFont,
                      height: 1,
                    ),
                  ),
                const SizedBox(height: 1),
                if (isRuko || bottomNumber != null)
                  Container(
                    width: 7,
                    height: 7,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuranSignPainter extends CustomPainter {
  final Color color;
  QuranSignPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const double gap = 70.0; // Widened gap for better spacing
    const double sidePadding = 12.0;

    canvas.drawLine(
        const Offset(sidePadding, 0), Offset(size.width / 2 - gap, 0), paint);
    canvas.drawLine(Offset(size.width / 2 + gap, 0),
        Offset(size.width - sidePadding, 0), paint);
    canvas.drawLine(Offset(sidePadding, size.height),
        Offset(size.width / 2 - gap, size.height), paint);
    canvas.drawLine(Offset(size.width / 2 + gap, size.height),
        Offset(size.width - sidePadding, size.height), paint);
    canvas.drawLine(
        const Offset(sidePadding, 0), Offset(sidePadding, size.height), paint);
    canvas.drawLine(Offset(size.width - sidePadding, 0),
        Offset(size.width - sidePadding, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
