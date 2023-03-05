// import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tzmap;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:adhan_dart/adhan_dart.dart';
import '../../../../Utils/constants.dart';
import '../../../../widgets.dart';
import 'package:geolocator/geolocator.dart';

class PrayerTime extends StatefulWidget {
  const PrayerTime({Key? key}) : super(key: key);

  @override
  State<PrayerTime> createState() => _PrayerTimeState();
}

class _PrayerTimeState extends State<PrayerTime> {
  static const _time = [
    '04:01 AM',
    '04:01 AM',
    '04:01 AM',
    '04:01 AM',
    '04:01 AM',
  ];
  static const _name = [
    '"Fajar',
    'Dhuhar',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  String? fajar;
  String? dhar;
  String? asar;
  String? magrrib;
  String? isa;
  @override
  Future<List<String>> locationPosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    String tza =
        tzmap.latLngToTimezoneString(position.latitude, position.longitude);
    print('Montreal is in the $tza time zone.');
    tz.initializeTimeZones();
    final location = tz.getLocation(tza);

    // Definitions
    DateTime date = tz.TZDateTime.from(DateTime.now(), location);
    Coordinates coordinates =
        Coordinates(position.latitude, position.longitude);

    CalculationParameters params = CalculationMethod.MuslimWorldLeague();
    params.madhab = Madhab.Hanafi;
    PrayerTimes prayerTimes =
        PrayerTimes(coordinates, date, params, precision: true);
    DateTime fajrTime = tz.TZDateTime.from(prayerTimes.fajr!, location);
    DateTime sunriseTime = tz.TZDateTime.from(prayerTimes.sunrise!, location);
    DateTime dhuhrTime = tz.TZDateTime.from(prayerTimes.dhuhr!, location);
    DateTime asrTime = tz.TZDateTime.from(prayerTimes.asr!, location);
    DateTime maghribTime = tz.TZDateTime.from(prayerTimes.maghrib!, location);
    DateTime ishaTime = tz.TZDateTime.from(prayerTimes.isha!, location);
    Qibla Direction;
    List<String> prayerstiming = [];
    var qiblaDirection = Qibla.qibla(coordinates);
    prayerstiming.add(DateFormat("h:mma").format(fajrTime));
    prayerstiming.add(DateFormat("h:mma").format(dhuhrTime));
    prayerstiming.add(DateFormat("h:mma").format(asrTime));
    prayerstiming.add(DateFormat("h:mma").format(maghribTime));
    prayerstiming.add(DateFormat("h:mma").format(ishaTime));
    print(qiblaDirection);
    return prayerstiming;
  }

  @override
  Widget build(BuildContext context) {   
    return Scaffold(
      appBar: customAppBar(context, "PRAYER TIME"),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(40),
                  topLeft: Radius.circular(40),
                )),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: const <Widget>[
                  Text(
                    "Lahore,Pakistan",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w500),
                  )
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.80,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      FutureBuilder<List<String>>(
                          future: locationPosition(),
                          builder: (context, snapshot) {
                            // if (snapshot.hasData) {
                            //   List data = snapshot.data as List<String>;
                            // }
                            return (snapshot.hasData)
                                ? ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _time.length,
                                    itemBuilder: (context, index) {
                                      return Card(
                                        elevation: 5,
                                        child: Container(
                                          color: Colors.white,
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.volume_up,
                                                      color: Theme.of(context).primaryColor,
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(
                                                      _name[index],
                                                      style: TextStyle(
                                                        color: Theme.of(context).primaryColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                      '${snapshot.data![index]}',
                                                      style: TextStyle(
                                                        color: Theme.of(context).primaryColor,
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Icon(
                                                      Icons.settings,
                                                      color: Theme.of(context).primaryColor,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    })
                                : Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.blueGrey,
                                    ),
                                  );
                          })
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
