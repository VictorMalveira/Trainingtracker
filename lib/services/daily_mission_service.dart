import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/daily_mission_model.dart';
import '../models/mission_completed_model.dart';
import '../models/user_model.dart';

class DailyMissionService {
  final Database _db;
  final String _table = 'daily_missions';
  final String _completedTable = 'missions_completed';
  final String _loginBonusTable = 'login_bonuses';
  final Uuid _uuid = const Uuid();

  DailyMissionService(this._db);

  /// Cria as tabelas necessárias
  static Future<void> createTable(Database db) async {
    // Tabela de missões diárias
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_missions (
        id TEXT PRIMARY KEY,
        userId TEXT,
        title TEXT,
        description TEXT,
        xp INTEGER,
        skill TEXT,
        isCompleted INTEGER,
        date TEXT,
        estimatedTime INTEGER,
        completedAt TEXT
      )
    ''');

    // Tabela de missões concluídas (histórico)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS missions_completed (
        id TEXT PRIMARY KEY,
        userId TEXT,
        missionId TEXT,
        title TEXT,
        description TEXT,
        xp INTEGER,
        skill TEXT,
        completedAt TEXT,
        missionDate TEXT
      )
    ''');

    // Tabela de bônus de login diário
    await db.execute('''
      CREATE TABLE IF NOT EXISTS login_bonuses (
        id TEXT PRIMARY KEY,
        userId TEXT,
        date TEXT,
        xpBonus INTEGER,
        skillPointBonus INTEGER,
        streakCount INTEGER
      )
    ''');
  }

  /// Verifica e processa o bônus de login diário
  Future<Map<String, dynamic>> checkDailyLoginBonus(String userId) async {
    final today = DateTime.now();
    final todayString = DateTime(today.year, today.month, today.day).toIso8601String();
    
    // Verifica se já recebeu bônus hoje
    final existingBonus = await _db.query(
      _loginBonusTable,
      where: 'userId = ? AND date = ?',
      whereArgs: [userId, todayString],
    );

    if (existingBonus.isNotEmpty) {
      return {
        'alreadyReceived': true,
        'xpBonus': existingBonus.first['xpBonus'],
        'skillPointBonus': existingBonus.first['skillPointBonus'],
        'streakCount': existingBonus.first['streakCount'],
      };
    }

    // Calcula o streak atual
    final streakCount = await _calculateCurrentStreak(userId);
    final xpBonus = _calculateLoginBonus(streakCount);
    final skillPointBonus = streakCount >= 7 ? 1 : 0; // Bônus de ponto extra a cada 7 dias

    // Salva o bônus
    await _db.insert(_loginBonusTable, {
      'id': _uuid.v4(),
      'userId': userId,
      'date': todayString,
      'xpBonus': xpBonus,
      'skillPointBonus': skillPointBonus,
      'streakCount': streakCount,
    });

    return {
      'alreadyReceived': false,
      'xpBonus': xpBonus,
      'skillPointBonus': skillPointBonus,
      'streakCount': streakCount,
    };
  }

  /// Calcula o streak atual de login
  Future<int> _calculateCurrentStreak(String userId) async {
    final bonuses = await _db.query(
      _loginBonusTable,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    if (bonuses.isEmpty) return 1;

    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    for (final bonus in bonuses) {
      final bonusDate = DateTime.parse(bonus['date'] as String);
      final daysDiff = currentDate.difference(bonusDate).inDays;
      
      if (daysDiff == streak) {
        streak++;
        currentDate = bonusDate;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Calcula o bônus de XP baseado no streak
  int _calculateLoginBonus(int streak) {
    if (streak <= 1) return 10;
    if (streak <= 3) return 15;
    if (streak <= 7) return 25;
    if (streak <= 14) return 35;
    if (streak <= 30) return 50;
    return 75; // 30+ dias
  }

  /// Verifica inatividade e aplica penalidades
  Future<Map<String, dynamic>> checkInactivity(String userId, UserModel user) async {
    final now = DateTime.now();
    final lastWorkout = user.lastWorkoutDate;
    
    if (lastWorkout == null) {
      return {
        'hasPenalty': false,
        'daysInactive': 0,
        'penaltyAmount': 0,
      };
    }

    final daysInactive = now.difference(lastWorkout).inDays;
    int penaltyAmount = 0;
    bool hasPenalty = false;

    // Aplica penalidades baseadas na inatividade
    if (daysInactive >= 7) {
      penaltyAmount = 20;
      hasPenalty = true;
    } else if (daysInactive >= 3) {
      penaltyAmount = 10;
      hasPenalty = true;
    }

    return {
      'hasPenalty': hasPenalty,
      'daysInactive': daysInactive,
      'penaltyAmount': penaltyAmount,
    };
  }

  /// Gera missões diárias baseadas no nível, faixa e grau do usuário
  Future<List<DailyMissionModel>> generateDailyMissions(
    String userId,
    DateTime date, {
    UserModel? user,
  }) async {
    // Verifica se já existem missões para esta data
    final existingMissions = await getMissionsForDate(userId, date);
    if (existingMissions.isNotEmpty) {
      return existingMissions;
    }

    // Determina o número de missões baseado no nível do usuário
    int missionCount = 3; // Base
    if (user != null) {
      final level = _calculateUserLevel(user);
      if (level >= 5) missionCount = 4;
      if (level >= 10) missionCount = 5;
    }

    final missions = <DailyMissionModel>[];
    final availableMissions = _getAvailableMissions(user);

    // Seleciona missões aleatórias
    availableMissions.shuffle();
    for (int i = 0; i < missionCount && i < availableMissions.length; i++) {
      final missionData = availableMissions[i];
      final mission = DailyMissionModel(
        id: _uuid.v4(),
        userId: userId,
        title: missionData['title'],
        description: missionData['description'],
        xp: missionData['xp'],
        skill: missionData['skill'],
        date: date,
        estimatedTime: missionData['estimatedTime'],
      );
      missions.add(mission);
    }

    // Salva as missões no banco
    for (final mission in missions) {
      await insertMission(mission);
    }

    return missions;
  }

  /// Insere uma missão no banco
  Future<void> insertMission(DailyMissionModel mission) async {
    await _db.insert(_table, mission.toMap());
  }

  /// Busca missões para uma data específica
  Future<List<DailyMissionModel>> getMissionsForDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await _db.query(
      _table,
      where: 'userId = ? AND date >= ? AND date < ?',
      whereArgs: [userId, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'date ASC',
    );

    return List.generate(maps.length, (i) => DailyMissionModel.fromMap(maps[i]));
  }

  /// Busca missões de hoje
  Future<List<DailyMissionModel>> getTodayMissions(String userId) async {
    return getMissionsForDate(userId, DateTime.now());
  }

  /// Conclui uma missão
  Future<bool> completeMission(String missionId) async {
    final mission = await getMission(missionId);
    if (mission == null || mission.isCompleted) return false;

    final completedMission = mission.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    // Atualiza a missão
    final result = await _db.update(
      _table,
      completedMission.toMap(),
      where: 'id = ?',
      whereArgs: [missionId],
    );

    if (result > 0) {
      // Salva no histórico
      final completedRecord = MissionCompletedModel.fromDailyMission(completedMission);
      await _db.insert(_completedTable, completedRecord.toMap());
    }

    return result > 0;
  }

  /// Busca uma missão específica
  Future<DailyMissionModel?> getMission(String missionId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _table,
      where: 'id = ?',
      whereArgs: [missionId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return DailyMissionModel.fromMap(maps.first);
  }

  /// Busca estatísticas das missões de hoje
  Future<Map<String, dynamic>> getTodayStats(String userId) async {
    final missions = await getTodayMissions(userId);
    final completedCount = missions.where((m) => m.isCompleted).length;
    final totalXp = missions.fold<int>(0, (sum, m) => sum + m.xp);
    final earnedXp = missions.where((m) => m.isCompleted).fold<int>(0, (sum, m) => sum + m.xp);
    final completionRate = missions.isEmpty ? 0.0 : (completedCount / missions.length) * 100;

    return {
      'totalMissions': missions.length,
      'completedMissions': completedCount,
      'totalXp': totalXp,
      'earnedXp': earnedXp,
      'completionRate': completionRate,
    };
  }

  /// Busca histórico de missões concluídas
  Future<List<MissionCompletedModel>> getMissionHistory(String userId, {int limit = 50}) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _completedTable,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'completedAt DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => MissionCompletedModel.fromMap(maps[i]));
  }

  /// Limpa missões antigas (mais de 30 dias)
  Future<void> cleanupOldMissions() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    await _db.delete(
      _table,
      where: 'date < ?',
      whereArgs: [thirtyDaysAgo.toIso8601String()],
    );
  }

  /// Calcula o nível do usuário baseado no XP
  int _calculateUserLevel(UserModel user) {
    return (user.xpPoints / 100).floor() + 1;
  }

  /// Lista de missões disponíveis
  List<Map<String, dynamic>> _getAvailableMissions(UserModel? user) {
    return [
      {
        'title': 'Alongamento Matinal',
        'description': 'Faça 10 minutos de alongamento para melhorar a flexibilidade',
        'xp': 15,
        'skill': 'Flexibilidade',
        'estimatedTime': 10,
      },
      {
        'title': 'Estudo de Técnica',
        'description': 'Assista um vídeo ou leia sobre uma técnica de Jiu-Jitsu',
        'xp': 20,
        'skill': 'Técnica',
        'estimatedTime': 15,
      },
      {
        'title': 'Hidratação',
        'description': 'Beba 2L de água durante o dia',
        'xp': 10,
        'skill': 'Resistência',
        'estimatedTime': 0,
      },
      {
        'title': 'Respiração Controlada',
        'description': 'Pratique exercícios de respiração por 5 minutos',
        'xp': 12,
        'skill': 'Mental',
        'estimatedTime': 5,
      },
      {
        'title': 'Mobilidade Articular',
        'description': 'Faça exercícios de mobilidade para ombros e quadril',
        'xp': 18,
        'skill': 'Flexibilidade',
        'estimatedTime': 12,
      },
      {
        'title': 'Visualização',
        'description': 'Visualize uma técnica ou sequência por 5 minutos',
        'xp': 15,
        'skill': 'Mental',
        'estimatedTime': 5,
      },
      {
        'title': 'Aquecimento Dinâmico',
        'description': 'Faça 8 minutos de aquecimento dinâmico',
        'xp': 16,
        'skill': 'Agilidade',
        'estimatedTime': 8,
      },
      {
        'title': 'Reflexão de Treino',
        'description': 'Anote 3 pontos positivos do seu último treino',
        'xp': 12,
        'skill': 'Mental',
        'estimatedTime': 5,
      },
      {
        'title': 'Exercício de Força',
        'description': 'Faça 3 séries de flexões ou agachamentos',
        'xp': 25,
        'skill': 'Força',
        'estimatedTime': 15,
      },
      {
        'title': 'Cardio Rápido',
        'description': 'Faça 10 minutos de cardio (pular corda, polichinelo)',
        'xp': 22,
        'skill': 'Resistência',
        'estimatedTime': 10,
      },
    ];
  }

  /// Retorna mensagem motivacional baseada no progresso
  String getMotivationalMessage(double completionRate) {
    if (completionRate >= 100) {
      return '🎉 Incrível! Você completou todas as missões do dia!';
    } else if (completionRate >= 80) {
      return '🔥 Quase lá! Falta pouco para completar todas as missões!';
    } else if (completionRate >= 60) {
      return '💪 Ótimo progresso! Continue assim!';
    } else if (completionRate >= 40) {
      return '⚡ Você está no caminho certo! Vamos lá!';
    } else if (completionRate >= 20) {
      return '🌟 Começou bem! Agora é só continuar!';
    } else {
      return '🚀 Vamos começar! Cada missão te aproxima dos seus objetivos!';
    }
  }
} 