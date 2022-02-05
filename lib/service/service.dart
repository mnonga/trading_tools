import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
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
    }
  });

  // bring to foreground
  service.setForegroundMode(false); //true
  Timer.periodic(Duration(seconds: 5), (timer) async {
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
    if(false)AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 10,
            channelKey: 'basic_channel',
            title: 'Trading Tools',
            body: "${DateFormat('dd-MM-yyyy – HH:mm:ss').format(DateTime.now())}"));
    /*service.setNotificationInfo(
      title: "My App Service",
      content:
          "Updated at ${DateFormat('dd-MM-yyyy – HH:mm:ss').format(DateTime.now())}",
    );*/

    service.sendData(
      {"current_date": DateTime.now().toIso8601String()},
    );
  });
}
