import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_demo/models/airpot_model.dart';
import 'package:flutter/foundation.dart';

class RemoteData extends ChangeNotifier {
  RemoteData({this.val});
  final RemoteData? val;
  List<AirPorts> _remoteData = [];
  List<AirPorts> get getRemoteData => _remoteData;

  Future<void> fetchRemoteData(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final String responseBody = response.body;
        log(responseBody);
        Map<String, dynamic> data = jsonDecode(responseBody);
        log(data.toString());
        _remoteData = [AirPorts.fromJson(data)];
        notifyListeners();
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching remote data: $e');
      rethrow;
    }
  }
}
