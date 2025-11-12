import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SpotifyService {
  final String clientId = '9971ab74b7694d19b7b7ff7856524724';
  final String redirectUri = 'neurohelp://callback';
  String? accessToken;

  // Authenticate user with Spotify
  Future<void> authenticate() async {
    final url = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': clientId,
      'response_type': 'token',
      'redirect_uri': redirectUri,
      'scope': 'user-read-private user-read-email streaming',
    });

    final result = await FlutterWebAuth.authenticate(
        url: url.toString(), callbackUrlScheme: 'neurohelp');

    final fragment = Uri.parse(result).fragment;
    final params = Uri.splitQueryString(fragment);

    accessToken = params['access_token'];
  }

  // Fetch new releases from Spotify
  Future<List> getTracks() async {
    if (accessToken == null) return [];

    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/browse/new-releases'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['albums']['items'];
    } else {
      print('Spotify API Error: ${response.statusCode}');
      return [];
    }
  }
}
