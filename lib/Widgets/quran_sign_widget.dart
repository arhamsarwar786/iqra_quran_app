import 'package:flutter/material.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Utils/customThemes.dart';
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
    final bloc = context.watch<ThemeProvider>();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Borders
          Row(
            children: [
              Expanded(
                child: Image.asset(
                  "assets/images/borderLeft${bloc.iconNumber}.png",
                  color: bloc.selectedTheme,
                  fit: BoxFit.contain,
                ),
              ),
              Expanded(
                child: Image.asset(
                  "assets/images/borderRight${bloc.iconNumber}.png",
                  color: bloc.selectedTheme,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),

          // Sign and Numbers
          SizedBox(
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  sign,
                  style: MyTextStyle.heading1.copyWith(
                    fontSize: sign == "ع" ? 70 : 35,
                    fontFamily: bloc.arabicFontFamily,
                    color: bloc.selectedTheme,
                  ),
                ),
                if (label != null && label!.isNotEmpty)
                  Positioned(
                    top: 10,
                    child: Text(
                      label!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: bloc.selectedTheme,
                      ),
                    ),
                  ),
                if (topNumber != null)
                  Positioned(
                    top: sign == "ع" ? 20 : 15,
                    child: Text(
                      topNumber!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                if (middleNumber != null)
                  Positioned(
                    top: sign == "ع" ? 45 : 40,
                    right: sign == "ع"
                        ? MediaQuery.of(context).size.width * 0.44
                        : null,
                    child: Text(
                      middleNumber!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                if (bottomNumber != null)
                  Positioned(
                    bottom: sign == "ع" ? 10 : 15,
                    child: Text(
                      bottomNumber!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
