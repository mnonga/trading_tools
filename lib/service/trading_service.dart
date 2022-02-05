import 'dart:convert';

import 'package:candlesticks/candlesticks.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Timeframe {
  final int seconds;
  final String name;

  static const M1 = Timeframe._(seconds: 60, name: "M1");
  static const M5 = Timeframe._(seconds: 60 * 5, name: "M5");
  static const M15 = Timeframe._(seconds: 60 * 15, name: "M15");
  static const H1 = Timeframe._(seconds: 60 * 60, name: "H1");
  static const H4 = Timeframe._(seconds: 60 * 60 * 4, name: "H4");

  static const List<Timeframe> LIST = [M1, M5, M15, H1, H4];

  static Timeframe from(String name) =>
      LIST.firstWhere((element) => element.name == name);

  static List<String> namesList() => LIST.map<String>((e) => e.name).toList();

  const Timeframe._({required this.seconds, required this.name});
}

class SymbolModel {
  final String name, code;
  final double pip, price;
  SymbolModel(
      {required this.name,
      required this.code,
      required this.pip,
      required this.price});

  int get decimals {
    if (pip == 0.1)
      return 1;
    else if (pip == 0.01)
      return 2;
    else if (pip == 0.001)
      return 3;
    else if (pip == 0.0001)
      return 4;
    else if (pip == 0.00001) return 5;
    return 0;
  }

  @override
  String toString() {
    // TODO: implement toString
    return "$name ($code) : $price";
  }
}

class TradingService {
  static TradingService? _intance;
  static TradingService get instance => _intance ??= new TradingService();

  WebSocketChannel? _channel;

  WebSocketChannel get channel => _channel ??= WebSocketChannel.connect(
        Uri.parse("wss://ws.binaryws.com/websockets/v3?app_id=1089"),
      );

  Stream get stream => channel.stream;

  WebSocketSink get sink => channel.sink;

  //List symbols = [];
  //List candles = [];

  final MARKET = "synthetic_index";
  BehaviorSubject<List<SymbolModel>> symbolsSubject =
      BehaviorSubject.seeded([]);
  //BehaviorSubject<List> candlesSubject = BehaviorSubject.seeded([]);
  BehaviorSubject<List<Candle>> candlesSubject = BehaviorSubject.seeded([]);
    BehaviorSubject<Candle?> candleSubject = BehaviorSubject.seeded(null);

  String? candlesSubscriptionId;

  List<Candle> candles = [];
  String? lastCandleId;

  BehaviorSubject<SymbolModel?> currentSymbolSubject =
      BehaviorSubject.seeded(null);

  setCurrentSymbol(SymbolModel symbol, {Timeframe timeframe = Timeframe.M1}) {
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
        List<SymbolModel> symbols = [];
        for (var symbol in data["active_symbols"]) {
          if (symbol['market'] == MARKET) {
            symbols.add(SymbolModel(
                name: symbol['display_name'],
                code: symbol['symbol'],
                pip: symbol['pip'],
                price: symbol['spot'].toDouble()));
          }
        }
        symbols.sort((a, b) => a.name.compareTo(b.name));
        print(symbols);
        symbolsSubject.add(symbols);
        //Future.delayed(Duration(seconds: 5), () => initSymbols());
      } else if (data["msg_type"] == "candles") {
        candlesSubscriptionId =
            data["subscription"]["id"]; // use this to cancel via forget message
        for (var candle in data["candles"]) {
          candles.add(Candle(
              date: DateTime.fromMillisecondsSinceEpoch(candle["epoch"] * 1000),
              high: candle["high"].toDouble(),
              low: candle["low"].toDouble(),
              open: candle["open"].toDouble(),
              close: candle["close"].toDouble(),
              volume: 1000));
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

        candle = Candle(
            date: DateTime.fromMillisecondsSinceEpoch(candle["epoch"] * 1000),
            high: double.parse(candle["high"]),
            low: double.parse(candle["low"]),
            open: double.parse(candle["open"]),
            close: double.parse(candle["close"]),
            volume: 1000);
        if (lastCandleId == null) {
          print("ohlc: First tick");
          candles.removeAt(0);
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
    });
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

  fetchCandles({required String symbol, int timeframeInSecond = 3600}) {
    sendMessage(jsonEncode({
      "ticks_history": symbol,
      "adjust_start_time": 1,
      "count": 1000,
      "end": "latest",
      "start": 1,
      "granularity": timeframeInSecond, // H1
      "style": "candles", //"ticks"
      "subscribe": 1, // recevoir quand il y a un nouveau tick
    }));
  }
}
