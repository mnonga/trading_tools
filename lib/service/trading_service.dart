import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:candlesticks/candlesticks.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:trading_tools/data/database.dart' as db;
import 'package:trading_tools/service/app_data.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:trading_tools/models/models.dart';

class TradingService {
  static TradingService? _instance, _instance2;
  static TradingService get instance => _instance ??= new TradingService._();
  static TradingService get instance2 => _instance2 ??= new TradingService._();

  TradingService._();

  WebSocketChannel? _channel;

  WebSocketChannel get channel => _channel ??= createChannel;

  WebSocketChannel get createChannel => WebSocketChannel.connect(
        Uri.parse("wss://ws.binaryws.com/websockets/v3?app_id=1089"),
      );

  Stream get stream => channel.stream;

  WebSocketSink get sink => channel.sink;

  //List symbols = [];
  //List candles = [];

  final MARKET = "synthetic_index";
  BehaviorSubject<List<db.SymbolModel>> symbolsSubject =
      BehaviorSubject.seeded([]);
  //BehaviorSubject<List> candlesSubject = BehaviorSubject.seeded([]);
  BehaviorSubject<List<Candle>> candlesSubject = BehaviorSubject.seeded([]);
  BehaviorSubject<Candle?> candleSubject = BehaviorSubject.seeded(null);

  String? candlesSubscriptionId;

  List<Candle> candles = [];
  String? lastCandleId;

  BehaviorSubject<db.SymbolModel?> currentSymbolSubject =
      BehaviorSubject.seeded(null);

  setCurrentSymbol(db.SymbolModel symbol,
      {Timeframe timeframe = Timeframe.M1}) {
    currentSymbolSubject.add(symbol);
    forgetAllSubscriptions();
    fetchCandles(symbol: symbol.code, timeframeInSecond: timeframe.seconds);
  }

  initMessageListener() {
    channel.stream.listen((event) {
      print("ws: got a message $event");
      Map data = jsonDecode(event);
      if (data["msg_type"] == "tick") {
        print("Ticks update: $data");
      } else if (data["msg_type"] == "active_symbols") {
        List<db.SymbolModel> symbols = [];
        for (var symbol in data["active_symbols"]) {
          if (symbol['market'] == MARKET) {
            symbols.add(db.SymbolModel(
                name: symbol['display_name'],
                code: symbol['symbol'],
                pip: symbol['pip'],
                price: symbol['spot'].toDouble(),
                selected: false));
          }
        }
        symbols.sort((a, b) => a.name.compareTo(b.name));
        AppDataService.instance.updateSymbols(symbols);
        print("ohlc: $symbols");
        symbolsSubject.add(symbols);
        //Future.delayed(Duration(seconds: 5), () => initSymbols());
      } else if (data["msg_type"] == "candles") {
        if (data["req_id"] == 1000)
          return handleCandles(data["candles"], "${data['tick_history']}");
        //if(data["req_id"]==null && data["subscription"]!=null)
        candlesSubscriptionId =
            data["subscription"]["id"]; // use this to cancel via forget message
        for (var candle in data["candles"]) {
          //candles.add(Candle.fromJsonOHLC(candle));
          candles.add(CandleExtension.fromJsonOHLC(candle));
        }
        print("ohlc: $data");
        candles = List.from(candles.reversed);
        candlesSubject.add(candles);
      } else if (data["msg_type"] == "ohlc") {
        var candle = data["ohlc"];
        var id = "${candle["open_time"]}";
        print("ohlc: $lastCandleId == $id ${lastCandleId == id}");
        print("ohlc: ${lastCandleId != id ? 'new' : 'update'} $candle");
        if (candle["symbol"] != currentSymbolSubject.value?.code) return;

        //candle = Candle.fromJson(candle);
        candle = CandleExtension.fromJsonOHLC(candle);
        if (lastCandleId == null) {
          print("ohlc: First tick");
          if (candles.isNotEmpty) candles.removeAt(0);
        } else if (lastCandleId == id) {
          candles.removeAt(0);
          print("ohlc: Update candle");
        } else {
          print("ohlc: New candle");
        }
        candles.insert(0, candle);
        lastCandleId = id;
        candlesSubject.add(candles);
        candleSubject.add(candle);
      } else {
        print(data);
      }
    }, onDone: () {
      print("ws: done");
    }, onError: (error) {
      print("ws: error $error");
    }, cancelOnError: true);
  }

  closeChannel() {
    channel.sink.close();
  }

  sendMessage(String message) {
    channel.sink.add(message);
  }

  init() {
    initMessageListener();
    initSymbols();
  }

  resetChannel() async {
    closeChannel();
    _channel = createChannel;
    initMessageListener();
  }

  initSymbols() {
    sendMessage(jsonEncode({
      "active_symbols": "full",
      "product_type": "basic",
    }));
  }

  forgetAllSubscriptions() {
    candles = [];
    candlesSubject.add(candles);
    candlesSubscriptionId = null;
    lastCandleId = null;
    sendMessage(jsonEncode({
      "forget_all": ["candles", "ticks"]
    }));
  }

  fetchCandles(
      {required String symbol,
      int timeframeInSecond = 3600,
      bool subscribe = true,
      int? req_id,
      int count = 1000}) {
    sendMessage(jsonEncode({
      "ticks_history": symbol,
      "adjust_start_time": 1,
      "count": count,
      "end": "latest",
      "start": 1,
      "granularity": timeframeInSecond, // H1
      "style": "candles", //"ticks"
      if (subscribe) "subscribe": 1, // recevoir quand il y a un nouveau tick
      if (req_id != null) "req_id": req_id
    }));
  }

  handleCandles(List candlesData, String symbol) {
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 10,
            channelKey: 'basic_channel',
            notificationLayout: NotificationLayout.BigText,
            title:
                'Trading Tools - ${DateFormat(DateFormat.HOUR24_MINUTE_SECOND).format(DateTime.now())}',
            body: "${candlesData[0]}"));

    for (var c in candlesData) {
      var candle = Candle(
          date: DateTime.fromMillisecondsSinceEpoch(c["epoch"] * 1000),
          high: c["high"].toDouble(),
          low: c["low"].toDouble(),
          open: c["open"].toDouble(),
          close: c["close"].toDouble(),
          volume: 1000);
    }
  }
}
