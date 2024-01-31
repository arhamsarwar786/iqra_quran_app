import 'package:flutter/material.dart';

import '../Models/aya_list_model.dart';

class SHEET {
  static bottomSheetPreview(context, Aya aya, bloc) {
    return showModalBottomSheet<void>(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30), topRight: Radius.circular(30))),
        context: context,
        builder: (BuildContext context) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      aya.arabic,
                      style: TextStyle(
                          fontSize: bloc.arabicFontSize,
                          fontFamily: bloc.arabicFontFamily,
                          color: Colors.black
                          // Add other styles as needed
                          ),
                    ),
                    Text(aya.translation1),
                    Text(aya.translation2),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
