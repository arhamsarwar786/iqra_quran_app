import 'dart:convert';

import "package:flutter/material.dart";
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Utils/constants.dart';
import 'package:iqra/Utils/customThemes.dart';
import 'package:provider/provider.dart';

import '../../../../Models/aya_list_model.dart';
import '../../../../components/tranlation_card_section.dart';

class SurahTranslationScreen extends StatefulWidget {
  SurahTranslationScreen(
      {super.key, this.ayatList, this.ayatCount, this.suratNumber,this.surahName});
  final String? ayatCount;
  List<Aya>? ayatList;
  final int? suratNumber;
  final String? surahName;

  @override
  State<SurahTranslationScreen> createState() => _SurahTranslationScreenState();
}

class _SurahTranslationScreenState extends State<SurahTranslationScreen> {

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Builder(builder: (context) {
        var bloc = context.read<ThemeProvider>();
        return Scaffold(
          appBar: PreferredSize(
              preferredSize: Size.fromHeight(100.0),
              child: AppBar(
                centerTitle: true,
                title: Text("Translation"),
                backgroundColor: Color.fromARGB(255, 170, 170, 170),
                bottom: PreferredSize(
                  child: Container(
                    height: 50,
                    color: bloc.selectedTheme,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Text(
                      "${widget.surahName}",
                      style: MyTextStyle.heading3
                          .copyWith(color: MyColors.whiteColor),
                    ),
                  ),
                  preferredSize: Size.fromHeight(50),
                ),
              )),
          body: ListView.builder(
                    itemCount: int.parse(widget.ayatCount!),
                    itemBuilder: (context, i) {
                      return TranlationCardSection(
                        provider: bloc,
                        arabic: widget.ayatList![i].arabic,
                        urdu: widget.ayatList![i].translation1,
                      );
                    })
        );
      }),
    );
  }
}
