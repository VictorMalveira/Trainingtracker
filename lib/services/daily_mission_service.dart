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
        completedAt TEXT,
        deadline TEXT,
        penaltyXP INTEGER DEFAULT 0,
        hasPenalty INTEGER DEFAULT 0,
        priority INTEGER DEFAULT 2
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
      
      // Calcula prazo baseado na prioridade e dificuldade
      final priority = _calculateMissionPriority(missionData);
      final deadline = _calculateMissionDeadline(date, priority, missionData['estimatedTime']);
      final penaltyXP = _calculatePenaltyXP(missionData['xp'], priority);
      
      final mission = DailyMissionModel(
        id: _uuid.v4(),
        userId: userId,
        title: missionData['title'],
        description: missionData['description'],
        xp: missionData['xp'],
        skill: missionData['skill'],
        date: date,
        estimatedTime: missionData['estimatedTime'],
        deadline: deadline,
        penaltyXP: penaltyXP,
        priority: priority,
      );
      missions.add(mission);
    }

    // Salva as missões no banco
    for (final mission in missions) {
      await insertMission(mission);
    }

    return missions;
  }

  // Calcula a prioridade da missão baseada na dificuldade e XP
  int _calculateMissionPriority(Map<String, dynamic> missionData) {
    final xp = missionData['xp'] as int;
    final estimatedTime = missionData['estimatedTime'] as int;
    
    // Missões com mais XP ou que demoram mais têm prioridade menor (mais tempo)
    if (xp >= 100 || estimatedTime >= 60) {
      return 1; // Baixa prioridade
    } else if (xp >= 50 || estimatedTime >= 30) {
      return 2; // Média prioridade
    } else {
      return 3; // Alta prioridade
    }
  }

  // Calcula o prazo da missão baseado na prioridade
  DateTime _calculateMissionDeadline(DateTime date, int priority, int estimatedTime) {
    final baseHours = switch (priority) {
      1 => 18, // Baixa prioridade: até 18h do dia
      2 => 15, // Média prioridade: até 15h do dia
      3 => 12, // Alta prioridade: até 12h do dia
      _ => 18,
    };
    
    // Adiciona tempo extra baseado no tempo estimado
    final extraHours = (estimatedTime / 30).ceil();
    final totalHours = baseHours + extraHours;
    
    return DateTime(date.year, date.month, date.day, totalHours.clamp(8, 23));
  }

  // Calcula a penalidade de XP baseada no XP da missão e prioridade
  int _calculatePenaltyXP(int missionXP, int priority) {
    final penaltyMultiplier = switch (priority) {
      1 => 0.3, // Baixa prioridade: 30% do XP
      2 => 0.5, // Média prioridade: 50% do XP
      3 => 0.8, // Alta prioridade: 80% do XP
      _ => 0.5,
    };
    
    return (missionXP * penaltyMultiplier).round();
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

  /// Atualiza uma missão existente
  Future<bool> updateMission(DailyMissionModel mission) async {
    final result = await _db.update(
      _table,
      mission.toMap(),
      where: 'id = ?',
      whereArgs: [mission.id],
    );
    return result > 0;
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
    final allMissions = [
      // Missões básicas (disponíveis para todos)
      {
        'title': 'Alongamento Matinal',
        'description': 'Faça 10 minutos de alongamento para melhorar a flexibilidade',
        'xp': 15,
        'skill': 'Flexibilidade',
        'estimatedTime': 10,
        'minBelt': 'Branca',
      },
      {
        'title': 'Estudo de Técnica Básica',
        'description': 'Assista um vídeo sobre posições fundamentais',
        'xp': 20,
        'skill': 'Técnica',
        'estimatedTime': 15,
        'minBelt': 'Branca',
      },
      {
        'title': 'Hidratação',
        'description': 'Beba 2L de água durante o dia',
        'xp': 10,
        'skill': 'Resistência',
        'estimatedTime': 0,
        'minBelt': 'Branca',
      },
      // Missões intermediárias
      {
        'title': 'Treino de Passagens de Guarda',
        'description': 'Pratique 3 técnicas de passagem de guarda',
        'xp': 30,
        'skill': 'Técnica',
        'estimatedTime': 20,
        'minBelt': 'Azul',
      },
      {
        'title': 'Sparring Leve',
        'description': 'Faça 15 minutos de sparring focado em defesa',
        'xp': 35,
        'skill': 'Resistência',
        'estimatedTime': 15,
        'minBelt': 'Azul',
      },
      // Missões avançadas
      {
        'title': 'Análise de Luta',
        'description': 'Analise uma luta profissional e anote 5 pontos',
        'xp': 40,
        'skill': 'Mental',
        'estimatedTime': 30,
        'minBelt': 'Roxa',
      },
      {
        'title': 'Treino de Finalizações Avançadas',
        'description': 'Pratique sequências de finalizações complexas',
        'xp': 45,
        'skill': 'Técnica',
        'estimatedTime': 25,
        'minBelt': 'Marrom',
      },
      {
        'title': 'Sessão de Drilling',
        'description': 'Faça drilling de transições por 20 minutos',
        'xp': 50,
        'skill': 'Agilidade',
        'estimatedTime': 20,
        'minBelt': 'Preta',
      },
      // Adicione mais missões conforme necessário
    ];

    if (user == null) return allMissions;

    final beltOrder = ['Branca', 'Azul', 'Roxa', 'Marrom', 'Preta'];
    final userBeltIndex = beltOrder.indexOf(user.beltLevel);
    final degreeFactor = user.beltDegree / 4; // Normaliza grau

    // Filtra missões disponíveis para o nível do usuário ou inferior
    final available = allMissions.where((m) {
      final minIndex = beltOrder.indexOf(m['minBelt'] as String);
      return minIndex <= userBeltIndex;
    }).toList();

    // Ajusta XP baseado no grau
    return available.map((m) {
      final adjustedXp = (m['xp'] as int) + ((m['xp'] as int) * degreeFactor).round();
      return {...m, 'xp': adjustedXp};
    }).toList();
  }

  /// Busca missões completadas para um usuário específico
  Future<List<MissionCompletedModel>> getCompletedMissionsForUser(String userId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _completedTable,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'completedAt DESC',
    );

    return List.generate(maps.length, (i) => MissionCompletedModel.fromMap(maps[i]));
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