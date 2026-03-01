import 'package:flutter/material.dart';
import 'package:iqra/Provider/tasbeeh_provider.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Tasbeeh/tasheeh_list_screen.dart';
import 'package:iqra/components/alerts.dart';
import 'package:iqra/components/bounce_button.dart';
import 'package:iqra/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../../Models/tasbih_model.dart';
import '../../../Provider/tasbih_count.dart';
import '../../../main.dart';
import 'digital_font.dart';
import 'tasbee_info.dart';

///////////////////////////////////////////////

class Tasbih extends StatefulWidget {
  const Tasbih({super.key});
  @override
  State<Tasbih> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Tasbih> {
  @override
  void initState() {
    super.initState();
    setSound();
  }

  final player = AudioPlayer();
  setSound() async {
    await player.setAsset('assets/sound/beep.wav');
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var tasbihProvider = Provider.of<TasbeeCount>(context);
    var tasbeehProvider = Provider.of<TasbeehProvider>(context);
    var themeProvider = Provider.of<ThemeProvider>(context);
    final selectedTasbeeh = tasbeehProvider.selectedTasbeeh;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColor,
          isExtended: true,
          child: const Icon(Icons.add),
          onPressed: () {
            push(context, const TasheehListScreen());
          }),
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text("Tasbeeh"),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () async {
                if (selectedTasbeeh != null) {
                  var user = TasbihModel(
                      virdh: selectedTasbeeh.arabic ?? '',
                      count: tasbihProvider.currentStep.toInt());
                  await objectbox.insertUser(user);
                }
                push(context, const TasbihInfo());
              },
              icon: const Icon(Icons.favorite)),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            selectedTasbeeh != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          selectedTasbeeh.arabic ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontFamily: themeProvider.arabicFontFamily,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(
                                  offset: Offset(0.5, 0.5),
                                  blurRadius: 3,
                                  color: Colors.black12),
                            ],
                          ),
                        ),
                        // const SizedBox(height: 3),
                        Text(
                          selectedTasbeeh.transliteration ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: themeProvider.urduFontFamily,
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.7),
                            fontSize: 20,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        // const SizedBox(height: 2),
                        Text(
                          selectedTasbeeh.urduMeaning ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: themeProvider.urduFontFamily,
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.8),
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
            Expanded(
              flex: 7,
              child: Center(
                child: Consumer<TasbeeCount>(builder: (context, value, widget) {
                  return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 30),
                      alignment: Alignment.center,
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: Size(size.width,
                                (size.width * 1.3375527426160339).toDouble()),
                            painter: RPSCustomPainter(context),
                          ),
                          Positioned(
                            top: size.height * 0.1,
                            left: 90,
                            right: 90,
                            child: Container(
                              alignment: Alignment.center,
                              height: size.height * 0.13,
                              width: size.width * 0.5,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  DigitalNumber(
                                    value: value.currentStep.toInt(),
                                    height: 50,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            // bottom: 70,
                            bottom: size.height * 0.1,
                            left: 0,
                            right: 0,
                            child: BouncingButton(
                              onPress: () async {
                                await value.increment();
                                player.seek(Duration.zero);
                                player.play();
                              },
                              child: CircleAvatar(
                                radius: 80,
                                backgroundColor:
                                    const Color(0xffF2EEEE).withOpacity(1.0),
                              ),
                            ),
                          ),
                          Positioned(
                              // left: 0,
                              top: 0,
                              right: size.width * 0.22,
                              bottom: 20,
                              child: BouncingButton(
                                  onPress: () {
                                    customAlertBox(context,
                                        title: "Want to Delete?",
                                        decription:
                                            "Are you sure you want to clear user data.",
                                        onTab: () async {
                                      await value.resetCount();
                                      pop(context);
                                    });
                                  },
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor:
                                        const Color.fromARGB(255, 255, 0, 0)
                                            .withOpacity(1.0),
                                  ))),
                        ],
                      ));
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RPSCustomPainter extends CustomPainter {
  final context;
  RPSCustomPainter(this.context);
  @override
  void paint(Canvas canvas, Size size) {
    Path path_0 = Path();
    path_0.moveTo(size.width * 0.9600675, size.height * 0.1923098);
    path_0.cubicTo(
        size.width * 0.8838186,
        size.height * -0.05835079,
        size.width * 0.1022333,
        size.height * -0.04452114,
        size.width * 0.03749127,
        size.height * 0.1923098);
    path_0.cubicTo(
        size.width * -0.007113333,
        size.height * 0.3554763,
        size.width * 0.01742608,
        size.height * 0.5268486,
        size.width * 0.05288608,
        size.height * 0.6238896);
    path_0.cubicTo(
        size.width * 0.07167722,
        size.height * 0.6753123,
        size.width * 0.09402574,
        size.height * 0.7374763,
        size.width * 0.1063696,
        size.height * 0.7899811);
    path_0.cubicTo(
        size.width * 0.1494911,
        size.height * 0.9733975,
        size.width * 0.4123042,
        size.height * 1.000126,
        size.width * 0.5554262,
        size.height * 0.9875079);
    path_0.cubicTo(
        size.width * 0.8134937,
        size.height * 0.9526845,
        size.width * 0.8850380,
        size.height * 0.8817539,
        size.width * 0.8966540,
        size.height * 0.6894732);
    path_0.cubicTo(
        size.width * 0.8974557,
        size.height * 0.6762019,
        size.width * 0.9005823,
        size.height * 0.6630189,
        size.width * 0.9062532,
        size.height * 0.6504290);
    path_0.cubicTo(
        size.width * 0.9849958,
        size.height * 0.4756151,
        size.width * 1.014717,
        size.height * 0.3719779,
        size.width * 0.9600675,
        size.height * 0.1923098);
    path_0.close();

    Paint paint0Stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02109705;
    paint0Stroke.color = const Color(0xffFFF8F8).withOpacity(1.0);
    canvas.drawPath(path_0, paint0Stroke);

    Paint paint0Fill = Paint()..style = PaintingStyle.fill;
    paint0Fill.color = Theme.of(context).primaryColor;
    canvas.drawPath(path_0, paint0Fill);

    Path path_1 = Path();
    path_1.moveTo(size.width * 0.9198312, size.height * 0.2192429);
    path_1.cubicTo(
        size.width * 0.8502616,
        size.height * -0.009463722,
        size.width * 0.1371308,
        size.height * 0.003154574,
        size.width * 0.07805907,
        size.height * 0.2192429);
    path_1.cubicTo(
        size.width * 0.03846806,
        size.height * 0.3640694,
        size.width * 0.05858017,
        size.height * 0.5159811,
        size.width * 0.08948861,
        size.height * 0.6056498);
    path_1.cubicTo(
        size.width * 0.1072831,
        size.height * 0.6572713,
        size.width * 0.1283114,
        size.height * 0.7200347,
        size.width * 0.1428700,
        size.height * 0.7722177);
    path_1.cubicTo(
        size.width * 0.1876304,
        size.height * 0.9326656,
        size.width * 0.4220633,
        size.height * 0.9561293,
        size.width * 0.5506329,
        size.height * 0.9447950);
    path_1.cubicTo(
        size.width * 0.7852954,
        size.height * 0.9131293,
        size.width * 0.8509283,
        size.height * 0.8487413,
        size.width * 0.8618650,
        size.height * 0.6746435);
    path_1.cubicTo(
        size.width * 0.8626962,
        size.height * 0.6613754,
        size.width * 0.8658270,
        size.height * 0.6481514,
        size.width * 0.8714895,
        size.height * 0.6355584);
    path_1.cubicTo(
        size.width * 0.9427679,
        size.height * 0.4770694,
        size.width * 0.9695232,
        size.height * 0.3825994,
        size.width * 0.9198312,
        size.height * 0.2192429);
    path_1.close();

    Paint paint1Stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    paint1Stroke.color = const Color(0xff0F0D0D).withOpacity(1.0);
    canvas.drawPath(path_1, paint1Stroke);

    Paint paint1Fill = Paint()..style = PaintingStyle.fill;
    paint1Fill.color = const Color(0xff141414).withOpacity(1.0);
    canvas.drawPath(path_1, paint1Fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
