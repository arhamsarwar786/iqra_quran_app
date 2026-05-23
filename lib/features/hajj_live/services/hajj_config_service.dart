import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../config/hajj_live_config.dart';
import '../models/hajj_stream_model.dart';

class HajjConfigService {
  Future<HajjStreamModel> fetchConfig() async {
    try {
      final response = await http
          .get(
            Uri.parse(HajjLiveConfig.githubConfigUrl),
            headers: HajjLiveConfig.cacheBypassHeaders,
          )
          .timeout(HajjLiveConfig.fetchTimeout);
      // debugger();
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return HajjStreamModel.fromJson(data);
      } else {
        throw Exception('Failed to load config: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
