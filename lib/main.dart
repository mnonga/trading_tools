import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:intl/intl.dart';
import 'package:trading_tools/pages/chart.dart';
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
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String text = "Stop Service";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    TradingService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: Column(
          children: [
            StreamBuilder<Map<String, dynamic>?>(
              stream: FlutterBackgroundService().onDataReceived,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final data = snapshot.data!;
                DateTime? date = DateTime.tryParse(data["current_date"]);
                return Text(DateFormat('dd-MM-yyyy – HH:mm:ss').format(date!));
              },
            ),
            ElevatedButton(
              child: Text("Foreground Mode"),
              onPressed: () {
                FlutterBackgroundService()
                    .sendData({"action": "setAsForeground"});
              },
            ),
            ElevatedButton(
              child: Text("Background Mode"),
              onPressed: () {
                FlutterBackgroundService()
                    .sendData({"action": "setAsBackground"});
              },
            ),
            ElevatedButton(
              child: Text(text),
              onPressed: () async {
                final service = FlutterBackgroundService();
                var isRunning = await service.isServiceRunning();
                if (isRunning) {
                  service.sendData(
                    {"action": "stopService"},
                  );
                } else {
                  service.start();
                }

                if (!isRunning) {
                  text = 'Stop Service';
                } else {
                  text = 'Start Service';
                }
                setState(() {});
              },
            ),
            _listview()
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            FlutterBackgroundService().sendData({
              "hello": "world",
            });
          },
          child: Icon(Icons.play_arrow),
        ));
  }

  _listview() {
    return StreamBuilder<List<SymbolModel>>(
        stream: TradingService.instance.symbolsSubject,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Text("No symbols data !");
          return Expanded(
              child: ListView.builder(
                  itemCount: snapshot.data?.length,
                  itemBuilder: (context, index) {
                    SymbolModel? symbol = snapshot.data?[index];
                    return ListTile(
                      title: Text(
                          "${symbol?.name} (${symbol?.code})"),
                          subtitle: Text("${symbol?.price}"),
                          trailing: Checkbox(value: false, onChanged: (value){
                            print("${symbol?.name}");
                          },),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_)=> ChartPage(symbol: symbol!)));
                      },
                    );
                  }));
        });
  }
}
