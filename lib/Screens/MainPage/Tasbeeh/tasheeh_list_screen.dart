import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iqra/Models/tasbeeh_model.dart';
import 'package:iqra/Provider/tasbeeh_provider.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Utils/constants.dart';
import 'package:provider/provider.dart';

class TasheehListScreen extends StatefulWidget {
  const TasheehListScreen({Key? key}) : super(key: key);

  @override
  State<TasheehListScreen> createState() => _TasheehListScreenState();
}

class _TasheehListScreenState extends State<TasheehListScreen> {
  List<TasbeehModel> tasbeehList = [];
  bool isLoading = true;

  @override
  void initState() {    
    super.initState();
    loadTasbeehData();
  }

  loadTasbeehData() async {
    try {
      final String response = await rootBundle.loadString('assets/json_data/tasbeeh.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        tasbeehList = data.map((item) => TasbeehModel.fromJson(item)).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading tasbeeh data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      var bloc = context.read<ThemeProvider>();
      return Scaffold(
        backgroundColor: bloc.selectedSecondary,
        appBar: AppBar(
          backgroundColor: bloc.selectedTheme,
          title: const Text("Tasbeeh"),
          centerTitle: true,
          // actions: [IconButton(onPressed: () {}, icon: Icon(Icons.search))],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.only(top: 10),
          child: ListView.builder(
              itemCount: tasbeehList.length,
              itemBuilder: (context, index) {
                final tasbeeh = tasbeehList[index];
                return InkWell(
                  onTap: () {
                    context.read<TasbeehProvider>().setSelectedTasbeeh(tasbeeh);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
                    padding: const EdgeInsets.all(15),
                    constraints: const BoxConstraints(minHeight: 80),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Theme.of(context).primaryColor,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.chevron_left_outlined,
                          size: 30,
                          color: MyColors.whiteColor,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                tasbeeh.arabic ?? '',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: bloc.arabicFontFamily,
                                  fontSize: 32,
                                  color: MyColors.whiteColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // const SizedBox(height: 5),
                              // Text(
                              //   tasbeeh.transliteration ?? '',
                              //   textDirection: TextDirection.ltr,
                              //   style: TextStyle(
                              //     fontSize: 14,
                              //     color: MyColors.whiteColor.withOpacity(0.8),
                              //     fontStyle: FontStyle.italic,
                              //   ),
                              // ),
                              const SizedBox(height: 15),
                              Text(
                                tasbeeh.urduMeaning ?? '',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: bloc.urduFontFamily,
                                  fontSize: 20,
                                  color: MyColors.whiteColor.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
        ),
      );
    });
  }
}
