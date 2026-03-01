import 'package:flutter/material.dart';
import 'package:iqra/Screens/MainPage/Home/qibal/flutter_qiblah.dart';
import '../../../../widgets.dart';
import 'compass.dart';

class DirectionTOQiblah extends StatefulWidget {
  const DirectionTOQiblah({super.key});

  @override
  _DirectionTOQiblahState createState() => _DirectionTOQiblahState();
}

class _DirectionTOQiblahState extends State<DirectionTOQiblah> {
  final _deviceSupport = FlutterQiblah.androidDeviceSensorSupport();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: mainScreenAppBarPush(context, "Direction to Qiblah"),
      body: SafeArea(
        child: FutureBuilder(
          future: _deviceSupport,
          builder: (_, AsyncSnapshot<bool?> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text("Error: ${snapshot.error.toString()}"),
              );
            }

            if (snapshot.data == true) {
              return const QiblahCompass();
            } else {
              return const Center(
                  child: Text("Compass sensor not supported on this device"));
            }
          },
        ),
      ),
    );
  }
}
