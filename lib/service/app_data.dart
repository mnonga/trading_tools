import 'dart:convert';

import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:trading_tools/models/models.dart';
import 'package:trading_tools/service/trading_service.dart';
import 'package:trading_tools/data/database.dart';

class AppDataService {
  static AppDataService? _instance;
  static const KEY_SYMBOLS = "SYMBOLS";
  static AppDataService get instance => _instance ??= new AppDataService._();
  
SharedPreferences? _prefs;
  AppDataService._();

  BehaviorSubject<List<SymbolModel>> _symbolsSubject =
      BehaviorSubject.seeded([]);
  List<SymbolModel> _symbols = [];

  //Stream<List<SymbolModel>> get symbols => _symbolsSubject.stream;
  Stream<List<SymbolModel>> get symbols => MyDatabase.instance.symbolsDao.selectAllStream();

  init() async{
    /*_prefs = await SharedPreferences.getInstance();
    String? symbolsAsJson = _prefs?.getString(KEY_SYMBOLS);
    print("Saved symbols: $symbolsAsJson");

    if(symbolsAsJson!=null){
      List tempList = jsonDecode(symbolsAsJson);
      _symbols = [];
      for(var json in tempList){
        _symbols.add(SymbolModel.fromJson(json));
      }
    }
    
    _symbolsSubject.add(_symbols);*/
  }

  updateSymbol(SymbolModel symbol)async{
    await MyDatabase.instance.symbolsDao.updateSymbol(symbol);
    /*_symbols = _symbols.map((e) => e.code == symbol.code ? symbol : e).toList();
    _symbolsSubject.add(_symbols);
    await save();*/
  }

  updateSymbols(List<SymbolModel> list)async{
    for(var s in list){
      await MyDatabase.instance.symbolsDao.refreshSymbol(s);
    }

    /*List<SymbolModel> temp = [];

    for(var symbol in symbols){
      int index =_symbols.indexWhere((element) => element.code == symbol.code);
      if(index!=-1){
        
        //symbol.selected = _symbols[index].selected;
        symbol = symbol.copyWith(selected: _symbols[index].selected);
        if(symbol.selected)print("Selected $symbol");
      }
      temp.add(symbol);
    }
    _symbols = temp;
    _symbolsSubject.add(_symbols);
    await save();*/
  }

  save()async{
    /*if(_prefs==null) _prefs = await SharedPreferences.getInstance();
    await _prefs?.setString(KEY_SYMBOLS, jsonEncode(_symbols));*/
  }
}
