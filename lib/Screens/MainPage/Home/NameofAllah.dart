
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:iqra/Models/name_of_Allah_model.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';

import '../../../Utils/constants.dart';

class NameofAllah extends StatefulWidget {
  const NameofAllah({Key? key}) : super(key: key);

  @override
  State<NameofAllah> createState() => _NameofAllahState();
}

class _NameofAllahState extends State<NameofAllah> {

  @override
  void initState() {
    loadNamesOfAllah();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Builder(
      builder: (context) {
        var bloc = context.read<ThemeProvider>();
        return Scaffold(      
          backgroundColor: bloc.selectedSecondary,
          appBar: AppBar(
            title: const Text("Name of Allah"),
            centerTitle: true,
            backgroundColor: Theme.of(context).primaryColor,
          ),
          body: names == null
              ? const Center(
                  child: CircularProgressIndicator.adaptive(),
                )
              : gridNames(size),
        );
      }
    );
  }

  List<NameOfAllahModel>? names;
  loadNamesOfAllah() async {
    var data = await DefaultAssetBundle.of(context)
        .loadString("assets/json_data/name_of_Allah.json");
    // names = jsonDecode(data);
    print(data);
    debugger();
    names = nameOfAllahModelFromJson(data);
    print(names);
    setState(() {});
  }

  Widget gridNames(size) {
    var bloc = context.read<ThemeProvider>();
    return ListView.builder(
        shrinkWrap: true,
        itemCount: names!.length,
        itemBuilder: (context, index) {
          var name = names![index];
          return Container(
            margin: EdgeInsets.only(left: 10, right: 10, top: 10),
            padding: EdgeInsets.all(15),
            constraints: BoxConstraints(
              minHeight: 80
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).primaryColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: size.width * 0.40,
                  child: Text(
                    name.namesOfAllahInUrdu!,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Container(
                  width: size.width * 0.45,

                  child: Text(
                    name.namesOfAllahInArabic!,
                     textDirection: TextDirection.rtl,
                    style:  TextStyle(
                      fontFamily:bloc.arabicFontFamily,
                        color: Colors.white,
                        fontSize: 40,
                        // letterSpacing: 1,
                        fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          );
        });
  }
}
