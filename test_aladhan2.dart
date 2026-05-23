import 'dart:convert';
import 'dart:io';

void main() async {
  var request = await HttpClient().getUrl(Uri.parse('http://api.aladhan.com/v1/timings?latitude=31.5204&longitude=74.3587'));
  var response = await request.close();
  var responseBody = await response.transform(utf8.decoder).join();
  var json = jsonDecode(responseBody);
  print(json['data']['date']['hijri']['day']);
}
