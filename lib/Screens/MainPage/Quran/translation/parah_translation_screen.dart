import "package:flutter/material.dart";
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../../../Models/aya_list_model.dart';
import '../../../../Models/para_model.dart' hide Aya;
import '../../../../components/tranlation_card_section.dart';

class ParahTranslationScreen extends StatefulWidget {
  ParahTranslationScreen({
    super.key,
    this.para,
    this.ayatInPara,
    this.parahCount,
    this.parahname,
    this.ayatList,
  });
  final String? parahCount;
  final int? ayatInPara;
  final Para? para;
  final String? parahname;
  final List<Aya>? ayatList;

  @override
  State<ParahTranslationScreen> createState() => _ParahTranslationScreenState();
}

class _ParahTranslationScreenState extends State<ParahTranslationScreen> {
  @override
  Widget build(BuildContext context) {
    var bloc = context.read<ThemeProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(
          "${widget.parahname} Translation",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: bloc.selectedTheme,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: widget.ayatList == null
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: widget.ayatList!.length,
                itemBuilder: (context, i) {
                  return TranlationCardSection(
                    provider: bloc,
                    ayats: widget.ayatList!,
                    index: i,
                  );
                },
              ),
      ),
    );
  }
}
