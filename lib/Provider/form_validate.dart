import 'package:flutter/material.dart';

class FormValidate extends ChangeNotifier{
   bool _value=false;
   checkValidate(value){
      this._value =value;
      print(_value);
      notifyListeners();
  }
bool get validateValue=>_value;
}