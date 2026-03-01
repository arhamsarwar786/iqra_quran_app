import "package:flutter/material.dart";
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../../../Models/aya_list_model.dart';
import '../../../../components/tranlation_card_section.dart';

class ParahScreen extends StatefulWidget {
  ParahScreen(
      {super.key,
      this.ayatInSura,
      this.parahCount,
      this.parahname,
      this.ayatList});
  final String? parahCount;
  final List<int>? ayatInSura;
  final String? parahname;
  final List<Aya>? ayatList;

  @override
  State<ParahScreen> createState() => _ParahScreenState();
}

class _ParahScreenState extends State<ParahScreen> {
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
                }),
      ),
    );
  }
}
