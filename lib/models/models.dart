import 'dart:math';

import 'package:candlesticks/candlesticks.dart';

class Timeframe {
  final int seconds;
  final String name;

  static const M1 = Timeframe._(seconds: 60, name: "M1");
  static const M5 = Timeframe._(seconds: 60 * 5, name: "M5");
  static const M15 = Timeframe._(seconds: 60 * 15, name: "M15");
  static const H1 = Timeframe._(seconds: 60 * 60, name: "H1");
  static const H4 = Timeframe._(seconds: 60 * 60 * 4, name: "H4");

  static const List<Timeframe> LIST = [M1, M5, M15, H1, H4];

  static Timeframe fromName(String name) =>
      LIST.firstWhere((element) => element.name == name);

  static Timeframe fromSeconds(int seconds) =>
      LIST.firstWhere((element) => element.seconds == seconds);

  static List<String> namesList() => LIST.map<String>((e) => e.name).toList();

  const Timeframe._({required this.seconds, required this.name});
}

class SymbolModel {
  final String name, code;
  final double pip, price;
  bool selected;
  SymbolModel(
      {required this.name,
      required this.code,
      required this.pip,
      required this.price,
      this.selected = false});

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

  SymbolModel.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        price = json['price'],
        pip = json['pip'],
        selected = json['selected'],
        code = json['code'];

  Map<String, dynamic> toJson() => {
        "name": name,
        "code": code,
        "pip": pip,
        "price": price,
        "selected": selected
      };

  @override
  String toString() {
    return "${toJson()}";
  }
}

extension on Candle {
  static Candle fromJson(Map json) {
    return Candle(
        date: DateTime.fromMillisecondsSinceEpoch(json["epoch"] * 1000),
        high: json["high"] is String
            ? double.parse(json["high"])
            : json["high"].toDouble(),
        low: json["low"] is String
            ? double.parse(json["low"])
            : json["low"].toDouble(),
        open: json["open"] is String
            ? double.parse(json["open"])
            : json["open"].toDouble(),
        close: json["close"] is String
            ? double.parse(json["close"])
            : json["close"].toDouble(),
        volume: 1000);
  }

  int isPriceRejection() {
    double upperWick = high - max(open, close);
    double lowerWick = min(open, close) - low;
    double body = (close - open).abs();
    double upperBody = max(open, close);
    double lowerBody = min(open, close);
    double middle = low + (high - low) / 2;
    double middlePercent = 0.6;
    double upperMiddle = low + (high - low) * middlePercent;
    double lowerMiddle = high - (high - low) * middlePercent;
    const double priceRejectionPercent = 0.20;
    bool isRejectionOfHigherPrices =
        body <= upperWick * priceRejectionPercent &&
            upperBody < lowerMiddle /*middle*/;
    bool isRejectionOfLowerPrices = body <= lowerWick * priceRejectionPercent &&
        lowerBody > upperMiddle /*middle*/;

    print("higher $isRejectionOfHigherPrices  lower $isRejectionOfLowerPrices");

    if (isRejectionOfHigherPrices && !isRejectionOfLowerPrices) {
      return -1;
    } else if (isRejectionOfLowerPrices && !isRejectionOfHigherPrices) {
      return 1;
    }
    return 0;
  }
}
