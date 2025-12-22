import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

enum FFIState { none, sent, waiting, ok, fail }

class AppModel extends ChangeNotifier {
  var json = "";
  FFIState ffiState = FFIState.none;

  void updateFFIState(FFIState state) {
    ffiState = state;
    notifyListeners();
  }

  void updateJson(String json) async {
    this.json = json;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mapJson', json);
  }
}
