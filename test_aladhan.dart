import 'dart:convert';
import 'dart:io';

void main() async {
  var request = await HttpClient().getUrl(Uri.parse('http://api.aladhan.com/v1/timingsByCity?city=Lahore&country=Pakistan'));
  var response = await request.close();
  var responseBody = await response.transform(utf8.decoder).join();
  var json = jsonDecode(responseBody);
  print(json['data']['date']['hijri']['day']);
  print(json['data']['date']['hijri']['month']['en']);
}
