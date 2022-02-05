import 'package:candlesticks/candlesticks.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trading_tools/service/trading_service.dart';

class ChartPage extends StatefulWidget {
  final SymbolModel symbol;
  ChartPage({Key? key, required this.symbol}) : super(key: key);

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  SymbolModel? symbol;

  Timeframe timeframe = Timeframe.M1;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    symbol = widget.symbol;
    TradingService.instance
        .setCurrentSymbol(widget.symbol, timeframe: timeframe);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    TradingService.instance.forgetAllSubscriptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //title: Text(widget.symbol.name),
        title: StreamBuilder<List<SymbolModel>>(
            stream: TradingService.instance.symbolsSubject,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Text("...");
              var symbols = snapshot.data!;
              return PopupMenuButton<SymbolModel>(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "${symbol!.name} (${timeframe.name})",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: StreamBuilder<Candle?>(
                      stream: TradingService.instance.candleSubject,
                      builder: (context, snapshot){
                        if(!snapshot.hasData) return Text("${timeframe.name}", style: TextStyle(color: Colors.white));
                        Candle candle = snapshot.data!;
                        return 
                        Text("OHLC: ${candle.open} ${candle.high} ${candle.low} ${candle.close} -> ${DateFormat(DateFormat.HOUR24_MINUTE_SECOND).format(candle.date)} ", style: TextStyle(color: Colors.white));
                    },)
                  ),
                  onSelected: (value) {
                    if (value == symbol) return;
                    setState(() {
                      symbol = value;
                    });
                    TradingService.instance
                        .setCurrentSymbol(symbol!, timeframe: timeframe);
                  },
                  itemBuilder: (context) => symbols
                      .map((e) => PopupMenuItem(
                            child: Text(e.name),
                            value: e,
                          ))
                      .toList());
            }),

        leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.arrow_back)),
      ),
      body: StreamBuilder<List<Candle>>(
        stream: TradingService.instance.candlesSubject,
        builder: (context, snapshot) {
          print("ohlc: Update chart");
          if (!snapshot.hasData) return CircularProgressIndicator();
          return Candlesticks(
            onIntervalChange: (String name) async {
              setState(() {
                timeframe = Timeframe.from(name);
              });
              TradingService.instance
                  .setCurrentSymbol(symbol!, timeframe: timeframe);
            },
            candles: snapshot.data!,
            intervals: Timeframe.namesList(),
            interval: timeframe.name,
          );
        },
      ),
    );
  }
}