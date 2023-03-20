import 'package:flutter/material.dart';
import 'package:iqra/Provider/tasbih_count.dart';
import 'package:iqra/Screens/MainPage/Tasbeeh/tasbee.dart';
import 'package:iqra/widgets.dart';
import 'package:provider/provider.dart';
import '../../../Models/tasbih_model.dart';
import '../../../Utils/constants.dart';
import '../../../main.dart';
import 'tasbee_detail.dart';

class TasbihInfo extends StatefulWidget {


  @override
  State<TasbihInfo> createState() => _TasbihInfoState();
}

class _TasbihInfoState extends State<TasbihInfo> {
  late Stream<List<TasbihModel>> streamUsers;
  @override
  void initState() {
    super.initState();
    streamUsers = objectbox.getUsers();
  }

@override
  void dispose() {
    super.dispose();
    objectbox.closedStore();
  }  

  @override
  Widget build(BuildContext context) {
var tasbihProvider= Provider.of<TasbeeCount>(context,listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor:  Theme.of(context).primaryColor,
        centerTitle: true,
        leading: IconButton(
            onPressed: () {
              // Navigator.of(context).push(MaterialPageRoute(builder: (contex){
              // return TasbeeDetail();
              // }));
              pop(context);
            },
            icon: const Icon(Icons.arrow_back_outlined)),
        title: const Text(
          "Tasbih Info",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder<List<TasbihModel>>(
          stream: streamUsers,
          builder: (context, snapshot) {
           
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            else{
            final users = snapshot.data!;
          
            return ListView.builder(
              itemCount: users.length,
              // reverse: true,
              itemBuilder: ((context, index) {
                final user = users[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
                  child: PhysicalModel(
                    borderRadius: BorderRadius.circular(8.0),
                    shadowColor: Colors.white,
                    elevation: 10,
                    color: Colors.white,
                    child: ListTile(
                      onTap: (){
                        tasbihProvider.setValue(user.count);
                        push(context, Tasbih(value:user.virdh));
                      },
                      trailing: IconButton(
                          onPressed: () {
                            objectbox.deletetUser(user.id);
                          
                          }, icon: const Icon(Icons.delete),color:  Theme.of(context).primaryColor,),
                      tileColor: Colors.white,
                      title:  Text(user.virdh.toString(),
                        //
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        "Total Count: " +user.count.toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );}
          }),
    );
  }
}
