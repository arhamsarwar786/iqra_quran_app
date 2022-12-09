import 'package:flutter/material.dart';
import 'package:iqra/Screens/MainPage/Home/qibal/flutter_qiblah.dart';
import '../../../../widgets.dart';
import 'comapss.dart';

class DirectionTOQiblah extends StatefulWidget {
  @override
  _DirectionTOQiblahState createState() => _DirectionTOQiblahState();
}

class _DirectionTOQiblahState extends State<DirectionTOQiblah> {
  final _deviceSupport = FlutterQiblah.androidDeviceSensorSupport();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: mainScreenAppBarPush(context, "Direction to Qiblah"),
        body: FutureBuilder(
          future: _deviceSupport,
          builder: (_, AsyncSnapshot<bool?> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return CircularProgressIndicator();
            if (snapshot.hasError)
              return Center(
                child: Text("Error: ${snapshot.error.toString()}"),
              );

            if (snapshot.data!)
              return QiblahCompass();
            else
              return Text("No data");
          },
        ),
      
    );
  }
}
