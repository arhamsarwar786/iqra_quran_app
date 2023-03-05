import 'package:flutter/material.dart';
import 'package:iqra/widgets.dart';
import 'package:provider/provider.dart';
import '../../../Models/tasbih_model.dart';
import '../../../Provider/tasbih_count.dart';
import '../../../Utils/constants.dart';
import '../../../main.dart';
import 'digital_font.dart';
import 'tasbee_info.dart';

///////////////////////////////////////////////

class Tasbih extends StatefulWidget {
  final value;
  Tasbih({this.value});
  @override
  State<Tasbih> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Tasbih> {
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var tasbihProvider = Provider.of<TasbeeCount>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text("Tasbih"),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () async {
                var user = widget.value.isEmpty
                    ? push(context, TasbihInfo())
                    : TasbihModel(
                        virdh: widget.value.toString(),
                        count: tasbihProvider.currentStep.toInt() != 0
                            ? tasbihProvider.currentStep.toInt()
                            : tasbihProvider.totalCount);
                widget.value.isEmpty ? null : await objectbox.insertUser(user);
                push(context, TasbihInfo());
              },
              icon: const Icon(Icons.favorite)),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // widget.value != null
          //     ? Expanded(
          //         flex: 1,
          //         child: Center(
          //           child: Text(
          //             widget.value.toString(),
          //             style: TextStyle(
          //               color: Theme.of(context).primaryColor,
          //               shadows: const [
          //                 Shadow(
          //                     offset: Offset(0.4, 0.4),
          //                     // blurRadius: 2,
          //                     color: Colors.white12),
          //               ],
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //         ),
          //       )
          //     : const Expanded(flex: 0, child: Text('')),
          Expanded(
            flex: 7,
            child: Center(
              child: Consumer<TasbeeCount>(builder: (context, value, widget) {
                return Container(
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: Size(size.width,
                              (size.width * 1.3375527426160339).toDouble()),
                          // painter: RPSCustomPainter(),
                        ),
                        Positioned(
                          top: size.height*0.1,
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
                                  height: 40,
                                  color: Colors.white,
                                ),
                                const Text(
                                  "  /  ",
                                  style: TextStyle(color: Colors.white),
                                ),
                                DigitalNumber(
                                  value: value.totalCount,
                                  height: 20,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          // bottom: 70,
                          bottom: size.height*0.1,
                          left: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              if (value.currentStep != value.totalStep) {
                                value.increment();
                              }
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
                            right: size.width*0.22,
                            bottom: 20,
                            child: GestureDetector(
                              onTap: () {
                                value.resetCount();
                              },
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    const Color(0xffF2EEEE).withOpacity(1.0),
                              ),
                            )),
                      ],
                    ));
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// class RPSCustomPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     Path path_0 = Path();
//     path_0.moveTo(size.width * 0.9600675, size.height * 0.1923098);
//     path_0.cubicTo(
//         size.width * 0.8838186,
//         size.height * -0.05835079,
//         size.width * 0.1022333,
//         size.height * -0.04452114,
//         size.width * 0.03749127,
//         size.height * 0.1923098);
//     path_0.cubicTo(
//         size.width * -0.007113333,
//         size.height * 0.3554763,
//         size.width * 0.01742608,
//         size.height * 0.5268486,
//         size.width * 0.05288608,
//         size.height * 0.6238896);
//     path_0.cubicTo(
//         size.width * 0.07167722,
//         size.height * 0.6753123,
//         size.width * 0.09402574,
//         size.height * 0.7374763,
//         size.width * 0.1063696,
//         size.height * 0.7899811);
//     path_0.cubicTo(
//         size.width * 0.1494911,
//         size.height * 0.9733975,
//         size.width * 0.4123042,
//         size.height * 1.000126,
//         size.width * 0.5554262,
//         size.height * 0.9875079);
//     path_0.cubicTo(
//         size.width * 0.8134937,
//         size.height * 0.9526845,
//         size.width * 0.8850380,
//         size.height * 0.8817539,
//         size.width * 0.8966540,
//         size.height * 0.6894732);
//     path_0.cubicTo(
//         size.width * 0.8974557,
//         size.height * 0.6762019,
//         size.width * 0.9005823,
//         size.height * 0.6630189,
//         size.width * 0.9062532,
//         size.height * 0.6504290);
//     path_0.cubicTo(
//         size.width * 0.9849958,
//         size.height * 0.4756151,
//         size.width * 1.014717,
//         size.height * 0.3719779,
//         size.width * 0.9600675,
//         size.height * 0.1923098);
//     path_0.close();

//     Paint paint_0_stroke = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = size.width * 0.02109705;
//     paint_0_stroke.color = Color(0xffFFF8F8).withOpacity(1.0);
//     canvas.drawPath(path_0, paint_0_stroke);

//     Paint paint_0_fill = Paint()..style = PaintingStyle.fill;
//     paint_0_fill.color = Theme.of(context).primaryColor;
//     canvas.drawPath(path_0, paint_0_fill);

//     Path path_1 = Path();
//     path_1.moveTo(size.width * 0.9198312, size.height * 0.2192429);
//     path_1.cubicTo(
//         size.width * 0.8502616,
//         size.height * -0.009463722,
//         size.width * 0.1371308,
//         size.height * 0.003154574,
//         size.width * 0.07805907,
//         size.height * 0.2192429);
//     path_1.cubicTo(
//         size.width * 0.03846806,
//         size.height * 0.3640694,
//         size.width * 0.05858017,
//         size.height * 0.5159811,
//         size.width * 0.08948861,
//         size.height * 0.6056498);
//     path_1.cubicTo(
//         size.width * 0.1072831,
//         size.height * 0.6572713,
//         size.width * 0.1283114,
//         size.height * 0.7200347,
//         size.width * 0.1428700,
//         size.height * 0.7722177);
//     path_1.cubicTo(
//         size.width * 0.1876304,
//         size.height * 0.9326656,
//         size.width * 0.4220633,
//         size.height * 0.9561293,
//         size.width * 0.5506329,
//         size.height * 0.9447950);
//     path_1.cubicTo(
//         size.width * 0.7852954,
//         size.height * 0.9131293,
//         size.width * 0.8509283,
//         size.height * 0.8487413,
//         size.width * 0.8618650,
//         size.height * 0.6746435);
//     path_1.cubicTo(
//         size.width * 0.8626962,
//         size.height * 0.6613754,
//         size.width * 0.8658270,
//         size.height * 0.6481514,
//         size.width * 0.8714895,
//         size.height * 0.6355584);
//     path_1.cubicTo(
//         size.width * 0.9427679,
//         size.height * 0.4770694,
//         size.width * 0.9695232,
//         size.height * 0.3825994,
//         size.width * 0.9198312,
//         size.height * 0.2192429);
//     path_1.close();

//     Paint paint_1_stroke = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2;
//     paint_1_stroke.color = Color(0xff0F0D0D).withOpacity(1.0);
//     canvas.drawPath(path_1, paint_1_stroke);

//     Paint paint_1_fill = Paint()..style = PaintingStyle.fill;
//     paint_1_fill.color = const Color(0xff141414).withOpacity(1.0);
//     canvas.drawPath(path_1, paint_1_fill);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return true;
//   }
// }
