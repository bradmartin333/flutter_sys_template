import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_sys_template/app_model.dart';
import 'package:flutter_sys_template/native_json.dart';
import 'package:provider/provider.dart';

const double buttonPadding = 3;

DrawingTool tool = DrawingTool.draw;
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

Widget makeToolButton(
    DrawingTool thisTool, IconData iconData, Function setState) {
  return Padding(
    padding: const EdgeInsets.all(buttonPadding),
    child: FilledButton.tonal(
      onPressed: () => setState(() => tool = thisTool),
      child: Icon(
        iconData,
        color: tool == thisTool ? Colors.green : null,
      ),
    ),
  );
}

Widget mapSolver() {
  var userDelete = false;

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
        bottomNavigationBar: RepaintBoundary(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.bounceIn,
            transitionBuilder: (Widget child, Animation<double> animation) {
              final offsetAnimation = Tween(
                begin: const Offset(1.0, 0.0),
                end: const Offset(0.0, 0.0),
              ).animate(animation);
              return ClipRect(
                child: SlideTransition(
                  position: offsetAnimation,
                  child: child,
                ),
              );
            },
            child: userDelete
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    key: const ValueKey<int>(0),
                    children: [
                      const Text('Delete all walls?'),
                      Padding(
                        padding: const EdgeInsets.all(buttonPadding),
                        child: FilledButton.tonal(
                          onPressed: () {
                            points.clear();
                            updateMap();
                            setState(() => userDelete = false);
                          },
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(buttonPadding),
                        child: FilledButton.tonal(
                          onPressed: () => setState(() => userDelete = false),
                          child: const Icon(
                            Icons.cancel,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    key: const ValueKey<int>(1),
                    children: [
                      makeToolButton(
                          DrawingTool.position, Icons.my_location, setState),
                      makeToolButton(DrawingTool.target, Icons.flag, setState),
                      makeToolButton(
                          DrawingTool.draw, Icons.select_all, setState),
                      makeToolButton(
                          DrawingTool.erase, Icons.deselect, setState),
                      Padding(
                        padding: const EdgeInsets.all(buttonPadding),
                        child: Visibility(
                          visible: !userDelete,
                          child: FilledButton.tonal(
                            onPressed: () {
                              setState(() {
                                tool = DrawingTool.none;
                                userDelete = true;
                              });
                            },
                            child: const Icon(Icons.delete_forever),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    },
  );
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
