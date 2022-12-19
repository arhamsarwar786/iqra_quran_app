import 'package:flutter/material.dart';
import 'package:iqra/Screens/MainPage/Dua/dua_view.dart';
import 'package:iqra/Utils/constants.dart';
import 'package:iqra/Utils/dua_data.dart';

class DuaScreen extends StatelessWidget {
  const DuaScreen({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      appBar: AppBar(
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
                  Navigator.push(context, MaterialPageRoute(builder: (_)=> DuaView(arabic: duaData[index]['arabic'],urdu: duaData[index]['urdu'] ,) ));
                },
                child: Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.only(left: 10,right: 10,bottom: 10),
                  alignment: Alignment.center,
                  constraints: BoxConstraints(
                    minHeight: 60
                  ),
                  decoration: BoxDecoration(
                    
                    color: Theme.of(context).primaryColor,
                    boxShadow: [
                      BoxShadow(color: Colors.grey,blurRadius: 5)
                    ],
                    // border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    Icon(Icons.chevron_left_outlined,size: 30,color: whiteColor,),
                    Container(
                      alignment: Alignment.centerRight,                      
                      width: size.width *0.75,
                      child: Text('${duaData[index]['title']}', textDirection: TextDirection.rtl,style: TextStyle(fontSize: 20,color: whiteColor),)),
                  ],),
                ),
              );
          }),
        ),
        
         
    );}
}