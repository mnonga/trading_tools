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

  // returns the generated id
  Future<int> addSymbol(SymbolsCompanion entry) {
    return into(symbols).insert(entry);
  }

  Future<int> insert({required String name, required String code, required double pip, double price=0, bool seleted=false}) {
    return addSymbol(
      SymbolsCompanion(
        name: Value(name),
        code: Value(code),
        pip: Value(pip),
        price: Value(price),
        selected: Value(seleted)
      ),
    );
  }

  Future<bool> updateSymbol(SymbolModel s){
    return (update(symbols).replace(s));
  }

  Future deleteItem(SymbolModel s) {
    return (delete(symbols)..where((s1) => s1.id.equals(s.id))).go();
  }

  Future<int> clean()=> delete(symbols).go();
}
