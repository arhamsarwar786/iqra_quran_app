import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iqra/Helper/favourite.dart';
import 'package:iqra/Models/quaran_favorate.dart';
import 'package:iqra/Screens/MainPage/Quran/Quranview.dart';
import 'package:iqra/Utils/constants.dart';

class Favorite extends StatefulWidget {
  Favorite({this.suratTitle, this.verses, this.urduMeaning});
  final suratTitle;
  final verses;
  final urduMeaning;

  @override
  State<Favorite> createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  // fetchPref(){

  // }
  @override
  List list = [];
  void initState() {
    super.initState();
    list.add(widget.suratTitle);
  }

   List<int> numberofayat = [7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // floatingActionButton: FloatingActionButton(onPressed: () {
      //   // var data ;

      //   //  SavedPreferences.getFav().then((value){
      //   //    print("value ${value}");
      //   //  });
        
      //   SavedPreferences.clearFavPreference();
      // }),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/BgImage.png"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          iconSize: 20,
          color: const Color(0xff005d66),
          icon: const Icon(Icons.arrow_back),
        ),
        centerTitle: true,
        title: const Text(
          "Favourite",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xff005d66),
          ),
        ),
      ),
      body:FutureBuilder (
        future: SavedPreferences.getFav(),
        builder: (context, snapshot) {
          if(snapshot.hasData==false){
            return Center(child: CircularProgressIndicator(),);
          } 
          //  var data =snapshot.data;
          List<QuranFavorite> list;
         list= quranFavoriteFromJson(jsonEncode(snapshot.data));
         print("snapshot is ${snapshot.data}");
        
          return Stack(
            children: [
              Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                    color: Color(0xff005d66),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(40),
                      topLeft: Radius.circular(40),
                    )),
              ),
              Container(
                height: MediaQuery.of(context).size.height * 0.80,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: const Color(0xff005d66),
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListView.builder(
                    itemCount:list.length,
                    itemBuilder: (context, index) { 
                      var data = list[index];        
                      return Card(
                        elevation: 5,
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            onTap: (){
                              Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => QuranView(
                                                ayatInSura: numberofayat,
                                                ayatCount:data.suraVerses,
                                                surahCount: data.surahCount,
                                                surahName: data.urduSuratName,
                                              ),),);
                            },
                            title: Text(
                              data.suratName.toString(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              data.suraVerses.toString(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            leading: CircleAvatar(
                              radius: 15,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Center(
                                  child: Text(
                                (index +1).toString(),
                                style: const TextStyle(color: Colors.white),
                              )),
                            ),
                            trailing: FittedBox(
                              child: Column(
                                children: [
                                  Text(
                                    data.urduSuratName.toString(),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                 IconButton(onPressed: ()async{
                                   list.removeAt(index);
                                  
                                   await SavedPreferences.setFav(list);
                                 }, icon: const Icon(
                                    Icons.star,
                                    color: Colors.red,
                                  ),)
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}
