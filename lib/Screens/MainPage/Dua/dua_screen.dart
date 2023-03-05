import 'package:flutter/material.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Dua/dua_view.dart';
import 'package:iqra/Utils/constants.dart';
import 'package:iqra/Utils/dua_data.dart';
import 'package:provider/provider.dart';

class DuaScreen extends StatelessWidget {
  const DuaScreen({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Builder(
      builder: (context) {
        var bloc = context.read<ThemeProvider>();
        return Scaffold(
          backgroundColor: bloc.selectedSecondary,
          appBar: AppBar(
            backgroundColor: bloc.selectedTheme,
            title: Text("Dua"),
            centerTitle: true,
            actions: [
              IconButton(onPressed: (){

              }, icon: Icon(Icons.search))
            ],
          ),
            body:  Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ListView.builder(          
                itemCount: duaData.length,
                itemBuilder: (context,index){
                  return InkWell(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (_)=> DuaView(arabic: duaData[index]['arabic'],urdu: duaData[index]['urdu'],bloc:bloc) ));
                    },
                    child: Container(
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                        Icon(Icons.chevron_left_outlined,size: 30,color: MyColors.whiteColor,),
                        Container(
                          alignment: Alignment.centerRight,                      
                          width: size.width *0.75,
                          child: Text('${duaData[index]['title']}', textDirection: TextDirection.rtl,style: TextStyle(fontSize: 20,color: MyColors.whiteColor),)),
                      ],),
                    ),
                  );
              }),
            ),
            
             
        );
      }
    );}
}