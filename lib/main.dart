import 'dart:isolate';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/intl.dart';
import 'package:trading_tools/data/database.dart' as db;
import 'package:trading_tools/models/models.dart';
import 'package:trading_tools/pages/chart.dart';
import 'package:trading_tools/service/app_data.dart';
import 'package:trading_tools/service/service.dart';
import 'package:trading_tools/service/trading_service.dart';

// https://pub.dev/packages/flutter_background_service/example

// flutter run --no-sound-null-safety

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeService();
  AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      //'resource://drawable/res_app_icon',
      null,
      [
        NotificationChannel(
            channelGroupKey: 'basic_channel_group',
            channelKey: 'basic_channel',
            channelName: 'Basic notifications',
            channelDescription: 'Notification channel for basic tests',
            defaultColor: Color(0xFF9D50DD),
            enableLights: false,
            enableVibration: false,
            playSound: false,
            ledColor: Colors.white)
      ],
      // Channel groups are only visual and are not required
      channelGroups: [
        NotificationChannelGroup(
            channelGroupkey: 'basic_channel_group',
            channelGroupName: 'Basic group')
      ],
      debug: true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trading Tools',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Trading Tools'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isServiceRunning = false;
  String? lastMessage;
  final service = FlutterBackgroundService();
  ReceivePort? _receivePort;

  Future<void> _initForegroundTask() async {
    await FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Price Rejection',
        channelDescription: 'Trading Tools service is running',
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 10000,
        autoRunOnBoot: false,
      ),
      printDevLog: true,
    );
  }

  Future<bool> _startForegroundTask() async {
    // You can save data using the saveData function.
    await FlutterForegroundTask.saveData('use_all_symbols', false);

    ReceivePort? receivePort;

    if (await FlutterForegroundTask.isRunningService) {
      print("Stopping the serice...");
      await FlutterForegroundTask.stopService();
    }

    print("Starting the serice...");
    receivePort = await FlutterForegroundTask.startService(
      notificationTitle: 'FirstTaskHandler}',
      notificationText: 'Started',
      callback: startCallback,
    );

    if (receivePort != null) {
      _receivePort = receivePort;
      _receivePort?.listen((message) {
        print('message received from service: $message');
        if (message is DateTime) {
          //print('receive timestamp: $message');
          //service.sendData({"current_date":message.toIso8601String()});
        } else if (message is String) {
          if (message == "STARTED") setState(() {});
          else{
            setState(() {
              lastMessage = message;
            });
          }
        }
      });

      return true;
    }

    return false;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    AppDataService.instance.init();
    TradingService.instance.init();
    _initForegroundTask();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _receivePort?.close();
    TradingService.instance.closeChannel();
  }

  Future<void> _stopForegroundTask() async {
    return await FlutterForegroundTask.stopService();
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
        child: Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: Column(
              children: [
                StreamBuilder<Map<String, dynamic>?>(
                  stream: service.onDataReceived,
                  //stream: _receivePort,
                  builder: (context, snapshot) {
                    /*(()async{
                  bool running = await service.isServiceRunning();
                  if(running!=isServiceRunning){
                    setState(() {
                      isServiceRunning = running;
                    });
                  }
                })();*/
                    /*setState(() async{
                  isServiceRunning = await service.isServiceRunning();
                });*/
                    if (!snapshot.hasData) {
                      return Center(
                        child: Text(
                          "$lastMessage",
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    final data = snapshot.data!;
                    DateTime? date = DateTime.tryParse(data["current_date"]);
                    return Text(
                        DateFormat('dd-MM-yyyy – HH:mm:ss').format(date!));
                  },
                ),
                /*if (isServiceRunning)
                  ElevatedButton(
                    child: Text("Foreground Mode"),
                    onPressed: () {
                      FlutterBackgroundService()
                          .sendData({"action": "setAsForeground"});
                    },
                  ),
                if (isServiceRunning)
                  ElevatedButton(
                    child: Text("Background Mode"),
                    onPressed: () {
                      FlutterBackgroundService()
                          .sendData({"action": "setAsBackground"});
                    },
                  ),*/
                _listview()
              ],
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: isServiceRunning ? Colors.red : Colors.green,
              onPressed: () async {
                /*isServiceRunning = await service.isServiceRunning();
                if (isServiceRunning) {
                  service.sendData(
                    {"action": "stopService"},
                  );
                } else {
                  service.start();
                }
                setState(() {});*/
                isServiceRunning = await FlutterForegroundTask.isRunningService;
                print("isServiceRunning: $isServiceRunning");
                if (!isServiceRunning) {
                  _startForegroundTask();
                } else {
                  _stopForegroundTask();
                }
                Future.delayed(Duration(seconds: 1), () async {
                  isServiceRunning =
                      await FlutterForegroundTask.isRunningService;
                  setState(() {});
                });
              },
              child: Icon(isServiceRunning ? Icons.close : Icons.play_arrow),
            )));
  }

  _listview() {
    return StreamBuilder<List<db.SymbolModel>>(
        stream: AppDataService.instance.symbols,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Text("No symbols data !");
          return Expanded(
              child: ListView.builder(
                  itemCount: snapshot.data?.length,
                  itemBuilder: (context, index) {
                    db.SymbolModel? symbol = snapshot.data?[index];
                    return ListTile(
                      title: Text("${symbol?.name} (${symbol?.code})"),
                      subtitle: Text("${symbol?.price}"),
                      trailing: Checkbox(
                        value: symbol?.selected,
                        onChanged: (value) {
                          print("${symbol?.name}");
                          //symbol?.selected = value!;
                          symbol = symbol?.copyWith(selected: value!);
                          AppDataService.instance.updateSymbol(symbol!);
                        },
                      ),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ChartPage(symbol: symbol!)));
                      },
                    );
                  }));
        });
  }
}
