import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Serviço responsável por gerenciar a conexão com o banco de dados
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _db;

  /// Retorna a instância do banco de dados
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  /// Inicializa o banco de dados
  static Future<Database> _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "trainingtracker.db");

    return await openDatabase(
      path, 
      version: 2, // Incrementado para forçar a migração
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Cria as tabelas do banco de dados
  static Future<void> _onCreate(Database db, int version) async {
    // Tabela de usuários
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
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
        longestStreak INTEGER,
        lastWorkoutDate TEXT
      )
    ''');

    // Outras tabelas serão criadas pelos respectivos serviços
  }

  /// Atualiza o banco de dados quando a versão muda
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migração para adicionar a coluna 'deadline' na tabela 'daily_missions'
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE daily_missions ADD COLUMN deadline TEXT');
        await db.execute('ALTER TABLE daily_missions ADD COLUMN penaltyXP INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE daily_missions ADD COLUMN hasPenalty INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE daily_missions ADD COLUMN priority INTEGER DEFAULT 2');
      } catch (e) {
        // Ignora erros se as colunas já existirem
      }
    }
  }

  /// Fecha a conexão com o banco de dados
  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  /// Limpa todas as tabelas do banco de dados
  static Future<void> clearAllTables(Database db) async {
    await db.execute('DELETE FROM users');
    await db.execute('DELETE FROM user_skills');
    await db.execute('DELETE FROM daily_missions');
    await db.execute('DELETE FROM missions_completed');
    await db.execute('DELETE FROM workouts');
    await db.execute('DELETE FROM mission_penalties');
  }
}