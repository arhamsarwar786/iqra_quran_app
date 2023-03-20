

 
import 'package:flutter/material.dart';
import 'package:iqra/widgets.dart';

customAlertBox(BuildContext context,{ onTab, title,decription, isSuccess = true}) {  
  // Create button  
  Widget okButton = MaterialButton(  
    color: isSuccess ? Theme.of(context).primaryColor : Colors.red,
    child:  Text("OK",style: TextStyle(color: Colors.white),),  
    onPressed: onTab,  
  ); 
    Widget cancelButton = MaterialButton(  
    color:  Colors.grey,
    child:  Text("Cancel",style: TextStyle(color: Colors.white),),  
    onPressed: (){
      pop(context);
    },  
  );  
  
  // Create AlertDialog  
  AlertDialog alert = AlertDialog(  
    title: Text("$title"),  
    content: Text("$decription"),  
    actions: [  
      cancelButton,
      okButton
    ],  
  );  
  
  // show the dialog  
  showDialog(  
    context: context,  
    builder: (BuildContext context) {  
      return alert;  
    },  
  );  
}  