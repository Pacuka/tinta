import 'package:flutter_test/flutter_test.dart';
import 'package:folio/database/init.dart';
import 'package:folio/database/struct.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('migration keeps rows that did not need migrating', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    const oldStruct = DatabaseStruct("t", {"id": String, "a": String});
    const newStruct =
        DatabaseStruct("t", {"id": String, "a": String, "b": String});
    await createTable(db, oldStruct);
    await db.execute("ALTER TABLE t ADD COLUMN b TEXT");
    // student: already complete; parent: new row missing column b
    await db.insert("t", {"id": "student", "a": "grades", "b": "x"});
    await db.insert("t", {"id": "parent", "a": "grades2"});

    await migrateDB(db, struct: newStruct, defaultValues: {"b": "[]"});

    final rows = await db.query("t", orderBy: "id");
    expect(rows.map((r) => r["id"]), ["parent", "student"]);
    expect(rows.firstWhere((r) => r["id"] == "student")["a"], "grades");
    expect(rows.firstWhere((r) => r["id"] == "parent")["b"], "[]");
    await db.close();
  });
}
