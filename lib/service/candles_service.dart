import 'dart:async';
import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:candlesticks/candlesticks.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:trading_tools/data/database.dart' as db;
import 'package:trading_tools/service/app_data.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:trading_tools/models/models.dart';

class CandlesService {
  static CandlesService? _instance;
  static CandlesService get instance => _instance ??= new CandlesService._();

  static const TAG_NAME = "candles_service";

  CandlesService._();

  WebSocketChannel? _channel;

  WebSocketChannel get channel => _channel ??= createChannel;

  WebSocketChannel get createChannel => WebSocketChannel.connect(
        Uri.parse("wss://ws.binaryws.com/websockets/v3?app_id=1089"),
      );

  Stream get stream => channel.stream;

  WebSocketSink get sink => channel.sink;

  bool _isInitialized = false;

  BehaviorSubject<Map<String, int>> priceRejectionSubject = BehaviorSubject.seeded({});
  StreamSubscription? priceRejectionSubscription;

  sendMessage(String message) {
    channel.sink.add(message);
  }

  closeChannel() {
    channel.sink.close();
    priceRejectionSubscription?.cancel();
  }

  initMessageListener() {
    if(_isInitialized) return;
    _isInitialized = true;
    print("$TAG_NAME: initMessageListener()");

    channel.stream.listen((event) {
      print("$TAG_NAME: got a message $event");
      Map data = jsonDecode(event);
      print("$TAG_NAME: $data");
      if (data["msg_type"] == "candles") {
        if (data["req_id"] == 1000)
          return handleCandles(data["candles"], data['passthrough']['symbolName'], data['passthrough']['timeframe']);
      }
    }, onDone: () {
      print("$TAG_NAME: done");
    }, onError: (error) {
      print("$TAG_NAME: error $error");
    }, cancelOnError: true);

    priceRejectionSubscription = priceRejectionSubject.listen((value) {
      FlutterForegroundTask.updateService(
        notificationTitle:
            'FirstTaskHandler - ${DateFormat(DateFormat.HOUR24_MINUTE_SECOND).format(DateTime.now())}',
        notificationText: " ${value}");
    });


  }

  fetchCandles(
      {required String symbol, required String symbolName,
      int timeframeInSecond = 3600,
      bool subscribe = true,
      int? req_id,
      int count = 1000
      }) {
    sendMessage(jsonEncode({
      "ticks_history": symbol,
      "adjust_start_time": 1,
      "count": count,
      "end": "latest",
      "start": 1,
      "granularity": timeframeInSecond, // H1
      "style": "candles", //"ticks"
      "passthrough": {"symbolName":symbolName, "symbol":symbol, "timeframe":Timeframe.fromSeconds(timeframeInSecond).name},
      if (subscribe) "subscribe": 1, // recevoir quand il y a un nouveau tick
      if (req_id != null) "req_id": req_id
    }));
    if(!_isInitialized){
      initMessageListener();
    }
  }

  handleCandles(List candlesData, String symbol, String timeframe) {
    /*FlutterForegroundTask.updateService(
        notificationTitle:
            'FirstTaskHandler - ${DateFormat(DateFormat.HOUR24_MINUTE_SECOND).format(DateTime.now())}',
        notificationText: "$symbol ${candlesData[0]}");*/
    /*AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 10,
            channelKey: 'basic_channel',
            notificationLayout: NotificationLayout.BigText,
            title:
                'Trading Tools - ${DateFormat(DateFormat.HOUR24_MINUTE_SECOND).format(DateTime.now())}',
            body: "${candlesData[0]}"));*/
    

    for (var c in candlesData) {
      /*var candle = Candle(
          date: DateTime.fromMillisecondsSinceEpoch(c["epoch"] * 1000),
          high: c["high"].toDouble(),
          low: c["low"].toDouble(),
          open: c["open"].toDouble(),
          close: c["close"].toDouble(),
          volume: 1000);*/
       var candle =   CandleExtension.fromJsonOHLC(c);
       int priceRejection = candle.isPriceRejection();
       if(priceRejection==1 ||priceRejection==-1){
         var map =priceRejectionSubject.value;
         map[symbol] = priceRejection;
         priceRejectionSubject.add(map);
       }
    }
  }
}
