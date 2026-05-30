import 'package:flutter/material.dart';
import 'package:flutter_intro/flutter_intro.dart';

const fontFamilyList = [
  {"name": "NotoNaskhArabic", "fontFamily": "notoNash"},
  {"name": "DroidNaskh", "fontFamily": "droid"},
  {"name": "LateefRegOT", "fontFamily": "lateef"},
  {"name": "KFGQPC Uthman Taha Naskh", "fontFamily": "kfg"}
];

const themeList = [
  {
    "primary": "#0E323F",
    "secondary": "#F2FCFF",
    "theme": "light",
    "iconNumber": "1"
  },
  {
    "primary": "#227C9E",
    "secondary": "#F2FCFF",
    "theme": "light",
    "iconNumber": "2"
  },
  {
    "primary": "#129C8E",
    "secondary": "#F4FFFE",
    "theme": "light",
    "iconNumber": "3"
  },
  {
    "primary": "#EE9B00",
    "secondary": "#FFFAF5",
    "theme": "light",
    "iconNumber": "4"
  },
  {
    "primary": "#9B2226",
    "secondary": "#FFF0F1",
    "theme": "light",
    "iconNumber": "5"
  },
  {
    "primary": "#5F0F40",
    "secondary": "#FFF3FA",
    "theme": "light",
    "iconNumber": "6"
  }
];

var arabicFontSize = [];

var arabicFontFamily = [
  "notoNash",
  "droid",
  "lateef",
  "kfg",
  "alQalam",
  "Muhammdi",
  "AlQalamQuranMajeed"
];

var urduFontFamily = ["jamel", "nastaleeq", "pdmsSaleem"];

const bismillaArabic = "بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِیْمِ";

Widget buildIntroOverlay(StepWidgetParams params, String text) {
  bool isLast = params.onNext == null;
  return Container(
    margin: const EdgeInsets.all(10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(text,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            if (!isLast)
              TextButton(
                onPressed: params.onFinish,
                child:
                    const Text('Skip', style: TextStyle(color: Colors.white70)),
              ),
            ElevatedButton(
              onPressed: isLast ? params.onFinish : params.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(isLast ? 'Finish' : 'Next',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    ),
  );
}
