import 'package:moor/moor.dart';

// These imports are only needed to open the database
import 'package:moor/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'symbols_dao.dart';

part 'database.g.dart';

// this will generate a table called "todos" for us. The rows of that table will
// be represented by a class called "Todo".
@DataClassName("SymbolModel")
class Symbols extends Table {
  TextColumn get name => text()();
  TextColumn get code => text()();
  RealColumn get pip => real()();
  RealColumn get price => real().withDefault(const Constant(0))();
  BoolColumn get selected => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {code};
  
}


LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return VmDatabase(file);
  });
}

// run this to generate the code
// $ flutter packages pub run build_runner build
// it will generate a file named filename.g.dart

@UseMoor(tables: [Symbols], daos: [SymbolsDao])
class MyDatabase extends _$MyDatabase {
  static MyDatabase? _instance;

  static MyDatabase get instance => _instance ??= new MyDatabase();

  // we tell the database where to store the data with this constructor
  MyDatabase() : super(_openConnection());

  // you should bump this number whenever you change or add a table definition. Migrations
  // are covered later in this readme.
  @override
  int get schemaVersion => 1;
}
