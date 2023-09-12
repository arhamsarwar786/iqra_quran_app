
import 'dart:convert';

import 'package:flutter/material.dart';
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
  static const _nameofAllah = [
    'الرَّحْمَنُ',
    'الرَّحِيمُ',
    'الْمَلِكُ',
    'الْقُدُّوسُ',
    'السَّلاَمُ',
    'الْمُؤْمِنُ',
    'الْمُهَيْمِنُ',
    'الْعَزِيزُ',
    'الْجَبَّارُ',
    'الْمُتَكَبِّر',
    'الْخَالِقُ',
    'الْبَارِئُ',
    'الْمُصَوِّرُ',
    'الْغَفَّارُ',
    'الْقَهَّارُ',
    'الْوَهَّابُ',
    'الرَّزَّاقُ',
    'الْفَتَّاحُ',
    'اَلْعَلِيْمُ',
    'الْقَابِضُ',
    'الْبَاسِطُ',
    'الْخَافِضُ',
    'الرَّافِعُ',
    'الْمُعِزُّ',
    'ٱلْمُذِلُّ',
    'السَّمِيعُ',
    'الْبَصِيرُ',
    'الْحَكَمُ',
    'الْعَدْلُ',
    'اللَّطِيفُ',
    'الْخَبِيرُ',
    'الْحَلِيمُ',
    'الْعَظِيمُ',
    'الْغَفُور',
    'الشَّكُورُ',
    'الْعَلِيُّ',
    'الْكَبِيرُ',
    'الْحَفِيظُ',
    'المُقيِت',
    'الْحسِيبُ',
    'الْجَلِيلُ',
    'الْكَرِيمُ',
    'الرَّقِيبُ',
    'ٱلْمُجِيبُ',
    'الْوَاسِعُ',
    'الْحَكِيمُ',
    'الْوَدُودُ',
    'الْمَجِيدُ',
    'الْبَاعِثُ',
    'الشَّهِيدُ',
    'الْحَقُ',
    'الْوَكِيلُ',
    'الْقَوِيُ',
    'الْمَتِينُ',
    'الْوَلِيُّ',
    'الْحَمِيدُ',
    'الْمُحْصِي',
    'الْمُبْدِئُ',
    'ٱلْمُعِيدُ',
    'الْمُحْيِي',
    'اَلْمُمِيتُ',
    'الْحَيُّ',
    'الْقَيُّومُ',
    'الْوَاجِدُ',
    'الْمَاجِدُ',
    'الْواحِدُ',
    'اَلاَحَدُ',
    'الصَّمَدُ',
    'الْقَادِرُ',
    'الْمُقْتَدِرُ',
    'الْمُقَدِّمُ',
    'الْمُؤَخِّرُ	',
    'الأوَّلُ',
    'الآخِرُ',
    'الظَّاهِرُ',
    'الْبَاطِنُ',
    'الْوَالِي',
    'الْمُتَعَالِي',
    'الْبَرُّ',
    'التَّوَابُ',
    'الْمُنْتَقِمُ',
    'العَفُوُ',
    'الرَّؤُوفُ',
    'َمَالِكُ ٱلْمُلْكُ',
    'ذُوالْجَلاَلِ وَالإكْرَامِ',
    'الْمُقْسِطُ',
    'الْجَامِعُ',
    'ٱلْغَنيُّ',
    'ٱلْمُغْنِيُّ',
    'اَلْمَانِعُ',
    'الضَّارَ',
    'النَّافِعُ',
    'النُّورُ',
    'الْهَادِي',
    'الْبَدِيعُ',
    'اَلْبَاقِي',
    'الْوَارِثُ',
    'الرَّشِيدُ',
    'الصَّبُورُ',
  ];

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

  var names;
  loadNamesOfAllah() async {
    var data = await DefaultAssetBundle.of(context)
        .loadString("assets/json_data/names_of_Allah.json");
    names = jsonDecode(data);
    print(names);
    setState(() {});
  }

  Widget gridNames(size) {
    var bloc = context.read<ThemeProvider>();
    return ListView.builder(
        shrinkWrap: true,
        itemCount: names.length,
        itemBuilder: (context, index) {
          var name = names[index];
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
                    name["transliteration"],
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Container(
                  width: size.width * 0.45,

                  child: Text(
                    name['name'],
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
