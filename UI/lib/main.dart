import 'package:flutter/material.dart';
import 'package:flutter_sys_template/app_model.dart';
import 'package:flutter_sys_template/pages/alpha.dart';
import 'package:flutter_sys_template/pages/map_solver.dart';
import 'package:flutter_sys_template/pages/one.dart';
import 'package:flutter_sys_template/native_json.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  //debugRepaintRainbowEnabled = true;
  getIt.registerSingleton<AppModel>(AppModel());
  runApp(ChangeNotifierProvider(
    create: (context) => getIt<AppModel>(),
    child: const SysApp(),
  ));
}

class SysApp extends StatelessWidget {
  const SysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

const List<Tab> tabs = <Tab>[
  Tab(
    text: 'Map Solver',
    icon: Icon(Icons.map),
  ),
  Tab(
    text: 'Alpha',
    icon: Icon(Icons.settings_accessibility_rounded),
  ),
  Tab(
    text: 'One',
    icon: Icon(Icons.hive_rounded),
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  initState() {
    super.initState();
    _loadMap();
    initPortListener(context);
  }

  Future<void> _loadMap() async {
    final prefs = await SharedPreferences.getInstance();
    String json = prefs.getString('mapJson') ?? "";
    setState(() {
      Provider.of<AppModel>(context, listen: false).updateJson(json);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Builder(
        builder: (BuildContext context) {
          final TabController tabController = DefaultTabController.of(context);
          tabController.addListener(
            () {
              if (!tabController.indexIsChanging) {
                // Your code goes here.
                // To get index of current tab use tabController.index
              }
            },
          );
          return Scaffold(
            appBar: AppBar(
              leading: Icon(
                context.watch<AppModel>().ffiState == FFIState.ok
                    ? Icons.check_circle
                    : Icons.error_outlined,
                semanticLabel: "FFI State",
              ),
              title: const Text('Systems App'),
              bottom: TabBar(tabs: tabs),
            ),
            body: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                mapSolver(),
                alpha(),
                one(),
              ],
            ),
          );
        },
      ),
    );
  }
}
