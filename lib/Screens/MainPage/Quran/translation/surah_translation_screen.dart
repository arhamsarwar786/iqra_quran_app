import "package:flutter/material.dart";
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../../../Models/aya_list_model.dart';
import '../../../../components/tranlation_card_section.dart';

class SurahTranslationScreen extends StatefulWidget {
  SurahTranslationScreen(
      {super.key,
      this.ayatList,
      this.ayatCount,
      this.suratNumber,
      this.surahName});
  final String? ayatCount;
  final List<Aya>? ayatList;
  final int? suratNumber;
  final String? surahName;

  @override
  State<SurahTranslationScreen> createState() => _SurahTranslationScreenState();
}

class _SurahTranslationScreenState extends State<SurahTranslationScreen> {
  @override
  Widget build(BuildContext context) {
    var bloc = context.read<ThemeProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Neutral modern background
      appBar: AppBar(
        title: Text(
          "${widget.surahName} Translation",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: bloc.selectedTheme,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: widget.ayatList?.length ?? 0,
        itemBuilder: (context, i) {
          return TranlationCardSection(
            provider: bloc,
            ayats: widget.ayatList!,
            index: i,
          );
        },
      ),
    );
  }
}
