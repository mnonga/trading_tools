import 'dart:async';
import 'dart:isolate';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:trading_tools/data/database.dart' as db;
import 'package:trading_tools/models/models.dart';
import 'package:trading_tools/service/candles_service.dart';
import 'package:trading_tools/service/trading_service.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: false,
      isForegroundMode: false, //true,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );
}

// to ensure this executed
// run app from xcode, then from xcode menu, select Simulate Background Fetch
void onIosBackground() {
  WidgetsFlutterBinding.ensureInitialized();
  print('FLUTTER BACKGROUND FETCH');
}

void onStart() {
  WidgetsFlutterBinding.ensureInitialized();
  final service = FlutterBackgroundService();
  service.onDataReceived.listen((event) {
    if (event!["action"] == "setAsForeground") {
      service.setForegroundMode(true);
      return;
    }

    if (event["action"] == "setAsBackground") {
      service.setForegroundMode(false);
    }

    if (event["action"] == "stopService") {
      service.stopBackgroundService();
      //TradingService.instance2.closeChannel();
    }
  });

  // bring to foreground
  service.setForegroundMode(false); //true
  Timer.periodic(Duration(seconds: 10), (timer) async {
    if (!(await service.isServiceRunning())) timer.cancel();
    /*print(
        "Updated at ${DateFormat('dd-MM-yyyy – HH:mm:ss').format(DateTime.now())}");*/
    /*Fluttertoast.cancel();
    Fluttertoast.showToast(
        msg: "${DateFormat('dd-MM-yyyy – HH:mm:ss').format(DateTime.now())}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black.withAlpha(100),
        textColor: Colors.white,
        fontSize: 16.0);*/
    /*if(false)AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 10,
            channelKey: 'basic_channel',
            title: 'Trading Tools',
            body: "${DateFormat('dd-MM-yyyy – HH:mm:ss').format(DateTime.now())}"));*/
    /*service.setNotificationInfo(
      title: "My App Service",
      content:
          "Updated at ${DateFormat('dd-MM-yyyy – HH:mm:ss').format(DateTime.now())}",
    );*/

    scanData(service);

    service.sendData(
      {"current_date": DateTime.now().toIso8601String()},
    );
  });
}

scanData(FlutterBackgroundService service){
  return;
  List<db.SymbolModel> symbols = TradingService.instance2.symbolsSubject.value;
  if(symbols.isEmpty){
    TradingService.instance2.init();
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 10,
            channelKey: 'basic_channel',
            title: 'Trading Tools - ${DateFormat(DateFormat.HOUR24_MINUTE_SECOND).format(DateTime.now())}',
            body: "Initializing..."));
    return;
  }

  AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 10,
            channelKey: 'basic_channel',
            title: 'Trading Tools - ${DateFormat(DateFormat.HOUR24_MINUTE_SECOND).format(DateTime.now())}',
            body: "Fetching..."));

  for(var symbol in symbols){
    TradingService.instance2.fetchCandles(symbol: symbol.code,subscribe: false,timeframeInSecond: Timeframe.H1.seconds, count: 3, req_id: 1000);
  }

}















// The callback function should always be a top-level function.
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
}

class FirstTaskHandler extends TaskHandler {
  bool? useAllSymbols = false;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    print("FirstTaskHandler.onStart()");
    sendPort?.send("STARTED");
    // You can use the getData function to get the data you saved.
    useAllSymbols = await FlutterForegroundTask.getData<bool>(key: 'use_all_symbols');
    print('use_all_symbols: $useAllSymbols');
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    print(
        "FirstTaskHandler.onEvent() : ${DateFormat(DateFormat.HOUR24_MINUTE_SECOND).format(timestamp)}");
    /*FlutterForegroundTask.updateService(
        notificationTitle:
            'FirstTaskHandler - ${DateFormat(DateFormat.HOUR24_MINUTE_SECOND).format(timestamp)}',
        notificationText: timestamp.toString());*/

    // Send data to the main isolate.
    sendPort?.send("${DateFormat(DateFormat.HOUR24_MINUTE_SECOND).format(timestamp)}");
    await doInBackground();
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print(
        "FirstTaskHandler.onDestroy() : ${DateFormat(DateFormat.HOUR24_MINUTE_SECOND).format(timestamp)}");
    CandlesService.instance.closeChannel();
    // You can use the clearAllData function to clear all the stored data.
    await FlutterForegroundTask.clearAllData();
  }

  doInBackground() async{
    List<db.SymbolModel> symbols;
    if(useAllSymbols!=true) symbols  = await db.MyDatabase.instance.symbolsDao.selectAllSelected();
    else symbols = await db.MyDatabase.instance.symbolsDao.selectAll();
    print("Using ${symbols.length} symbols");
    for(var symbol in symbols){
      CandlesService.instance.fetchCandles(symbolName: symbol.name, symbol: symbol.code,subscribe: false,timeframeInSecond: Timeframe.H1.seconds, count: 3, req_id: 1000);
    }
  }
}