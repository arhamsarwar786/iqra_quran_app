import 'package:hijri/hijri_calendar.dart';
void main() {
  HijriCalendar.setLocal('en');
  var today = HijriCalendar.now();
  print("Today is: ${today.hDay} ${today.longMonthName} ${today.hYear}");
}
