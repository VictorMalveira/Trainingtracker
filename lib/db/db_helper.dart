import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "trainingtracker.db");

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT,
        birthDate TEXT,
        weight REAL,
        beltLevel TEXT,
        beltDegree INTEGER,
        trainingStartDate TEXT,
        lastPromotionDate TEXT,
        xpPoints INTEGER,
        currentStreak INTEGER,
        longestStreak INTEGER
      )
    ''');
  }
}
