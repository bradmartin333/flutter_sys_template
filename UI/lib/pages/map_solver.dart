import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_sys_template/app_model.dart';
import 'package:flutter_sys_template/native_json.dart';
import 'package:provider/provider.dart';

const double buttonPadding = 3;

DrawingTool tool = DrawingTool.position;
double rectSize = 20;
Point mapSize = const Point(-1, -1);
Offset mapInset = Offset.zero;
Point position = const Point(0, 0);
Point target = const Point(10, 10);
List<Point<double>> points = []; // Raw local positions of user gestures

enum DrawingTool { none, position, target, draw, erase }

void gestureEvent(BuildContext context, dynamic gesture) {
  Point<double> p = Point(
      ((gesture.localPosition.dx - mapInset.dx) / rectSize).floor() * rectSize,
      ((gesture.localPosition.dy - mapInset.dy) / rectSize).floor() * rectSize);

  if (p.x >= 0 &&
      p.y >= 0 &&
      p.x < mapSize.x * rectSize &&
      p.y < mapSize.y * rectSize) {
    switch (tool) {
      case DrawingTool.position:
        if (!points.contains(p)) {
          Point newPosition =
              Point((p.x / rectSize).floor(), (p.y / rectSize).floor());
          if (position != newPosition) {
            position = newPosition;
            updateMap();
          }
        }
        break;
      case DrawingTool.target:
        if (!points.contains(p)) {
          Point newTarget =
              Point((p.x / rectSize).floor(), (p.y / rectSize).floor());
          if (target != newTarget) {
            target = newTarget;
            updateMap();
          }
        }
        break;
      case DrawingTool.draw:
        if (!points.contains(p) && p != position && p != target) {
          points.add(p);
          updateMap();
        }
        break;
      case DrawingTool.erase:
        if (points.contains(p)) {
          points.remove(p);
          updateMap();
        }
        break;
      case DrawingTool.none:
        break;
    }
  }
}

void updateMap() {
  sendMap(
      position,
      target,
      mapSize,
      String.fromCharCodes(Iterable.generate(
          (mapSize.x * mapSize.y).toInt(),
          (i) => points.contains(Point((i % mapSize.x) * rectSize,
                  (i / mapSize.x).floor() * rectSize))
              ? 120
              : 32)));
}

Widget mapSolver() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return Scaffold(
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: GestureDetector(
            child: Consumer<AppModel>(
              builder: (context, appModel, child) {
                return CustomPaint(
                  painter: MapCanvas(appModel),
                );
              },
            ),
            onTapDown: (details) => gestureEvent(context, details),
            onPanUpdate: (details) => gestureEvent(context, details),
          ),
        ),
        bottomNavigationBar: MapToolBar(),
      );
    },
  );
}

class MapToolBar extends StatefulWidget {
  const MapToolBar({
    super.key,
  });

  @override
  State<MapToolBar> createState() => _MapToolBarState();
}

class _MapToolBarState extends State<MapToolBar> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      final toolIndex = index + 1;
      if (toolIndex < DrawingTool.values.length) {
        tool = DrawingTool.values[toolIndex];
        _selectedIndex = index;
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Erase All Walls'),
              content: const Text('Are you sure you want to erase all walls?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Erase All'),
                  onPressed: () {
                    points.clear();
                    updateMap();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
            icon: Icon(Icons.my_location), label: 'Move Start'),
        BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Move Target'),
        BottomNavigationBarItem(
            icon: Icon(Icons.select_all), label: 'Draw Wall'),
        BottomNavigationBarItem(
            icon: Icon(Icons.deselect), label: 'Erase Wall'),
        BottomNavigationBarItem(
            icon: Icon(Icons.delete_forever), label: 'Erase All'),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Theme.of(context).colorScheme.secondary,
      unselectedItemColor:
          Theme.of(context).colorScheme.secondary.withAlpha(100),
      onTap: _onItemTapped,
    );
  }
}

class MapCanvas extends CustomPainter {
  var firstDraw = false;

  AppModel appModel;

  MapCanvas(this.appModel);

  @override
  void paint(Canvas canvas, Size size) {
    PathMap map = stringToPathMap(appModel.json);

    if (mapSize == const Point(-1, -1)) {
      mapSize = Point(
          (size.width / rectSize).floor(), (size.height / rectSize).floor());
      if (!map.valid) {
        updateMap();
      } else {
        // Load map into local variables
        position = map.position;
        target = map.target;
        Characters c = map.mapString.characters;
        for (var i = 0; i < c.length; i++) {
          if (c.elementAt(i) == 'x') {
            points.add(Point((i % mapSize.x) * rectSize,
                (i / mapSize.x).floor() * rectSize));
          }
        }
      }
    }

    double bottom = mapSize.y * rectSize;
    double right = mapSize.x * rectSize;
    mapInset = Offset((size.width - right) / 2.0, (size.height - bottom) / 2.0);
    canvas.drawRect(
      Offset.zero & Size(mapInset.dx, size.height * 2),
      Paint()..color = Colors.black,
    );
    canvas.drawRect(
      Offset.zero & Size(size.width * 2, mapInset.dy),
      Paint()..color = Colors.black,
    );
    canvas.drawRect(
      Offset(0, bottom + mapInset.dy) & Size(size.width * 2, size.height * 2),
      Paint()..color = Colors.black,
    );
    canvas.drawRect(
      Offset(right + mapInset.dx, 0) & Size(size.width * 2, size.height * 2),
      Paint()..color = Colors.black,
    );

    // Draw the map we are storing here
    for (var point in points) {
      canvas.drawRect(
          Rect.fromLTWH(
              point.x + mapInset.dx, point.y + mapInset.dy, rectSize, rectSize),
          Paint()..color = Colors.black);
    }

    // Parse the map json
    if (map.valid) {
      if (map.solved) {
        for (var point in map.path) {
          canvas.drawRect(
              Rect.fromLTWH(point.x * rectSize + mapInset.dx,
                  point.y * rectSize + mapInset.dy, rectSize, rectSize),
              Paint()..color = Colors.blue);
        }
      }
      canvas.drawRect(
          Rect.fromLTWH(map.position.x * rectSize + mapInset.dx,
              map.position.y * rectSize + mapInset.dy, rectSize, rectSize),
          Paint()..color = Colors.green);
      canvas.drawRect(
          Rect.fromLTWH(map.target.x * rectSize + mapInset.dx,
              map.target.y * rectSize + mapInset.dy, rectSize, rectSize),
          Paint()..color = Colors.red);
    }
  }

  @override
  bool shouldRepaint(MapCanvas oldDelegate) => true;
  @override
  bool shouldRebuildSemantics(MapCanvas oldDelegate) => false;
}
