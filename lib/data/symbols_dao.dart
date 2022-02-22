import 'package:moor/moor.dart';
import 'database.dart';

part 'symbols_dao.g.dart';

// the _SymbolsDaoMixin will be created by moor. It contains all the necessary
// fields for the tables. The <MyDatabase> type annotation is the database class
// that should use this dao.
@UseDao(tables: [Symbols])
class SymbolsDao extends DatabaseAccessor<MyDatabase> with _$SymbolsDaoMixin {
  static SymbolsDao? _instance;

  static SymbolsDao get instance =>
      _instance ??= new SymbolsDao(MyDatabase.instance);

  // this constructor is required so that the main database can create an instance
  // of this object.
  SymbolsDao(MyDatabase db) : super(db);

  Stream<List<SymbolModel>> selectedSymbolsStream() {
    return (select(symbols)..where((s) => s.selected.equals(true))).watch();
  }

  Stream<List<SymbolModel>> selectAllStream() {
    return (select(symbols)).watch();
  }

  Future<List<SymbolModel>> selectAll() => select(symbols).get();

  Future<List<SymbolModel>> selectAllSelected() => (select(symbols)..where((s) => s.selected)).get();

  // returns the generated id
  Future<int> addSymbol(SymbolsCompanion entry) {
    //return into(symbols).insert(entry);
    return into(symbols).insertOnConflictUpdate(entry);
  }

  Future<int> insert(
      {required String name,
      required String code,
      required double pip,
      double price = 0,
      bool seleted = false}) {
    return addSymbol(
      SymbolsCompanion(
          name: Value(name),
          code: Value(code),
          pip: Value(pip),
          price: Value(price),
          selected: Value(seleted)),
    );
  }

  Future<bool> updateSymbol(SymbolModel s) {
    return (update(symbols).replace(s));
  }

  Future<void> updateMultipleSymbols(List<SymbolModel> list) {
    return batch((batch) => batch.insertAllOnConflictUpdate(symbols, list));
  }

  Future<void> refreshSymbol(SymbolModel s) {
    return into(symbols).insert(
      s,
      //onConflict: DoUpdate((old) => WordsCompanion.custom(usages: old.usages + Constant(1))),
      onConflict: DoUpdate((old) =>
          SymbolsCompanion.custom(selected: old.selected.equals(true))),
      //onConflict: DoUpdate((old) => s.copyWith(selected: old.selected.equals(true))),
    );
  }

  Future deleteItem(SymbolModel s) {
    return (delete(symbols)..where((s1) => s1.code.equals(s.code))).go();
  }

  Future<int> clean() => delete(symbols).go();
}
