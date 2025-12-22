import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

enum FFIState { none, waiting, ok, fail }

class AppModel extends ChangeNotifier {
  var json = "";
  FFIState ffiState = FFIState.none;
  Icon get ffiIcon {
    switch (ffiState) {
      case FFIState.none:
        return Icon(
          Icons.hotel,
          color: Colors.blue,
        );
      case FFIState.waiting:
        return Icon(
          Icons.circle,
          color: Colors.yellow,
        );
      case FFIState.ok:
        return Icon(
          Icons.circle,
          color: Colors.green,
        );
      case FFIState.fail:
        return Icon(
          Icons.error,
          color: Colors.red,
        );
    }
  }

  void updateFFIState(FFIState state) {
    ffiState = state;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void updateJson(String json) async {
    this.json = json;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mapJson', json);
  }
}
