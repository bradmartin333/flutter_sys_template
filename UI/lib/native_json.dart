import 'dart:convert';
import 'dart:ffi';
import 'dart:io' show Directory, Platform;
import 'dart:isolate';
import 'dart:math';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sys_template/app_model.dart';
import 'package:flutter_sys_template/generated_bindings.dart';
import 'package:path/path.dart';

class PathMap {
  final bool valid;
  final bool solved;
  final Point position;
  final Point target;
  final Point mapSize;
  final String mapString;
  final List<Point> path;

  PathMap(this.valid, this.solved, this.position, this.target, this.mapSize,
      this.mapString, this.path);

  Map<String, dynamic> toJson() {
    var output = {
      'valid': valid,
      'solved': solved,
      'position': {'x': position.x, 'y': position.y},
      'target': {'x': target.x, 'y': target.y},
      'map': {'x': mapSize.x, 'y': mapSize.y, 'str': mapString},
    };

    List<dynamic> points = [];
    for (var i = 0; i < path.length; i++) {
      points.add({'x': path[i].x, 'y': path[i].y});
    }
    output['path'] = points;

    return output;
  }
}

PathMap stringToPathMap(String s) {
  Point np = const Point(-1, -1); // Null point

  Map<String, dynamic> json;
  try {
    json = jsonDecode(s);
  } catch (e) {
    return PathMap(false, false, np, np, np, "", []);
  }

  bool solved = json['solved'];
  Point pos = Point(json['position']['x'] as int, json['position']['y'] as int);
  Point target = Point(json['target']['x'] as int, json['target']['y'] as int);
  Point mapSize = Point(json['map']['x'] as int, json['map']['y'] as int);
  String mapString = json['map']['str'];

  List<Point> path = [];
  var points = json['path'];
  if (points != null) {
    for (var point in points) {
      path.add(Point(point['x'] as int, point['y'] as int));
    }
  }

  return PathMap(true, solved, pos, target, mapSize, mapString, path);
}

final DynamicLibrary dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    throw UnsupportedError('Usupported platform: ${Platform.operatingSystem}');
  }
  if (Platform.isAndroid) {
    return DynamicLibrary.open('libjson.so');
  }
  if (Platform.isLinux) {
    return DynamicLibrary.open(join(
        Directory.current.parent.path, 'json_library', 'bin', 'libjson.so'));
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open(join(Directory.current.parent.path,
        'json_library', 'bin', 'Debug', 'json_library.dll'));
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

final NativeJSON _bindings = NativeJSON(dylib);

final port = ReceivePort();

void initPortListener(BuildContext context) {
  // Enable async callbacks in dart
  _bindings.Dart_InitializeApiDL(NativeApi.initializeApiDLData);

  port.listen((data) {
    getIt<AppModel>().updateFFIState(FFIState.ok);
    getIt<AppModel>().updateJson(data);
  });
}

String helloJSON() {
  return _bindings.hello_json().cast<Utf8>().toDartString();
}

void sendMap(
  Point position,
  Point target,
  Point mapSize,
  String mapString,
) {
  PathMap pathmap = PathMap(
    true,
    false,
    position,
    target,
    mapSize,
    mapString,
    [],
  );
  getIt<AppModel>().updateFFIState(FFIState.waiting);
  String pathJsonString = jsonEncode(pathmap.toJson());
  var ptr = pathJsonString.toNativeUtf8().cast<Char>();
  _bindings.makeMap(ptr, pathJsonString.length, port.sendPort.nativePort);
}
