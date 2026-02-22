import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:provider/provider.dart';
import '../Models/aya_list_model.dart';
import '../Models/surah_metadata_model.dart';

class SHEET {
  static bottomSheetPreview(BuildContext context, Aya aya, bloc) {
    final quranProvider =
        Provider.of<QuranDataProvider>(context, listen: false);
    final int surahId = int.tryParse(aya.surahId ?? "1") ?? 1;
    final SurahMetadata? surah = quranProvider.getSurahMetadata(surahId);

    String translationText = "";
    String translatorName = "";

    if (bloc.selectedTranslation == "irfan") {
      translationText = aya.tarjumaIrfan ?? "";
      translatorName = "عرفان القرآن (ڈاکٹر محمد طاہر القادری)";
    } else if (bloc.selectedTranslation == "hind") {
      translationText = aya.tarjumaHind ?? "";
      translatorName = "ترجمہ ہند";
    } else {
      translationText = aya.tarjumaPak ?? "";
      translatorName = "ترجمہ پاک";
    }

    return showModalBottomSheet<void>(
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        context: context,
        builder: (BuildContext context) {
          return Container(
            decoration: BoxDecoration(
              color: bloc.selectedSecondary,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Verse $surahId:${aya.ayatNumber}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: bloc.selectedTheme,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        surah?.name ?? "",
                        style: TextStyle(
                          fontFamily: bloc.arabicFontFamily,
                          fontSize: 22,
                          color: bloc.selectedTheme,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          aya.arabicText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: bloc.arabicFontSize - 5,
                            fontFamily: bloc.arabicFontFamily,
                            color: Colors.black,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color: bloc.selectedTheme.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                translatorName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: bloc.selectedTheme,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                translationText,
                                style: TextStyle(
                                  fontSize: bloc.urduFontSize - 5,
                                  fontFamily: bloc.urduFontFamily,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionButton(
                        context,
                        icon: Icons.share,
                        label: "Share",
                        onTap: () {
                          // Implement share logic or use existing AppShare
                          Navigator.pop(context);
                        },
                        color: bloc.selectedTheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        });
  }

  static Widget _actionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      required Color color}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
