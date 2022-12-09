import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iqra/Provider/form_validate.dart';
import 'package:iqra/Screens/MainPage/Home/HomeScreen.dart';
import 'package:iqra/Screens/MainPage/Tasbeeh/tasbee.dart';
import 'package:iqra/Utils/constants.dart';
import 'package:iqra/widgets.dart';
import 'package:provider/provider.dart';
import '../../../Provider/tasbih_count.dart';

class TasbeeDetail extends StatefulWidget {

  @override
  State<TasbeeDetail> createState() => _TasbeeDetailState();
}

class _TasbeeDetailState extends State<TasbeeDetail> {
    var countController = TextEditingController();

    var nameController = TextEditingController();
@override
  void dispose() {
    super.dispose();
    countController.dispose();
    nameController.dispose();
  }
  @override
  Widget build(BuildContext context) {
    var tasbihProvider = Provider.of<TasbeeCount>(context, listen: false);
    var size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primayColor,
        centerTitle: true,
        leading: IconButton(
            onPressed: () {
              // Navigator.pop(context)
              push(context, Home());
            },
            icon: const Icon(Icons.arrow_back_outlined)),
        title: const Text(
          "Tasbih Input",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Time to count tasbih",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
             Divider(
              color: primayColor,
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              "Title Tasbih",
              style: TextStyle(),
            ),
            PhysicalModel(
              shadowColor: Colors.white,
              color: Colors.white,
              elevation: 10.0,
              borderRadius: BorderRadius.circular(10),
              child: TextField(
                controller: nameController,
                keyboardType: TextInputType.text,
                cursorColor: const Color(0xff005d66),
                autofocus: false,
              
              
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(left: 10),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:  BorderSide(color: primayColor),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderSide:  BorderSide(color: primayColor),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  border: OutlineInputBorder(
                    borderSide:  BorderSide(color: primayColor),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:  BorderSide(color:primayColor),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              "Count",
              style: TextStyle(),
            ),
            PhysicalModel(
              shadowColor: Colors.white,
              color: Colors.white,
              elevation: 10.0,
              borderRadius: BorderRadius.circular(10),
              child: Consumer<FormValidate>(
                builder: (context, value,child) {
                  return TextField(
                    controller: countController,
                    keyboardType: TextInputType.number,
                    cursorColor: const Color(0xff005d66),
                   
                    autofocus: false,
                   
                    decoration: InputDecoration(
                      errorText:value.validateValue==true?"Enter correct value":null ,
                      contentPadding: const EdgeInsets.only(left: 10.0),
                      fillColor: Colors.white,
                      filled: true,
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:  BorderSide(color: primayColor),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderSide:  BorderSide(color: primayColor),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      border: OutlineInputBorder(
                        borderSide:  BorderSide(color: primayColor),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:  BorderSide(color: primayColor),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  );
                }
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              height: 50,
              child: Align(
                alignment: Alignment.center,
                child:  Consumer<FormValidate>(
                builder: (context, value,child) {
                    return CupertinoButton(
                        minSize: size.width,
                        color: primayColor,
                        onPressed: () {
                        
                            if(countController.text.isEmpty){
                            value.checkValidate(true);
                          }
                          else{
                            value.checkValidate(false);
                            tasbihProvider.setValue(int.parse(countController.text));
                            push(context,Tasbih(value:nameController.text ,), );
                          }
                      
                          },
                        child: const Text(
                          "Go to next",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),);
                  }
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
