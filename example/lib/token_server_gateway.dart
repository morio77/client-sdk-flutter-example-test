import 'dart:convert';

import './env/.env.dart';
import 'package:http/http.dart' as http;

class TokenServerGateway {
  static Future<String> generateToken(
    String roomName,
    String userName,
  ) async {
    final url = Uri.http(Env.tokenServerUrl, '/token');
    final headers = {'content-type': 'application/json'};
    final body = json.encode({
      'roomName': roomName,
      'userName': userName,
    });

    final res = await http.post(url, headers: headers, body: body);
    if (res.statusCode == 200) {
      final token = res.body;
      return token;
    } else {
      print('Request failed with status: ${res.statusCode}.');
      return '';
    }
  }
}
