import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_model.dart';

class WorkoutService {
  final Database _db;
  final String _table = 'workouts';
  final Uuid _uuid = const Uuid();

  WorkoutService(this._db);

  /// Cria a tabela de treinos
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workouts (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        scheduledDate TEXT NOT NULL,
        estimatedDuration INTEGER NOT NULL,
        status INTEGER NOT NULL,
        relatedSkills TEXT NOT NULL,
        xpReward INTEGER NOT NULL,
        startedAt TEXT,
        completedAt TEXT,
        notes TEXT
      )
    ''');
  }

  /// Cria um novo treino
  Future<String> createWorkout(WorkoutModel workout) async {
    final id = _uuid.v4();
    final workoutWithId = workout.copyWith(id: id);
    
    await _db.insert(_table, workoutWithId.toMap());
    return id;
  }

  /// Busca todos os treinos de um usuário
  Future<List<WorkoutModel>> getUserWorkouts(String userId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _table,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'scheduledDate ASC',
    );

    return List.generate(maps.length, (i) => WorkoutModel.fromMap(maps[i]));
  }

  /// Busca treinos agendados (futuros e em andamento)
  Future<List<WorkoutModel>> getScheduledWorkouts(String userId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _table,
      where: 'userId = ? AND status IN (0, 1)', // scheduled, inProgress
      whereArgs: [userId],
      orderBy: 'scheduledDate ASC',
    );

    return List.generate(maps.length, (i) => WorkoutModel.fromMap(maps[i]));
  }

  /// Busca treinos de hoje
  Future<List<WorkoutModel>> getTodayWorkouts(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await _db.query(
      _table,
      where: 'userId = ? AND scheduledDate >= ? AND scheduledDate < ?',
      whereArgs: [userId, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'scheduledDate ASC',
    );

    return List.generate(maps.length, (i) => WorkoutModel.fromMap(maps[i]));
  }

  /// Busca um treino específico
  Future<WorkoutModel?> getWorkout(String workoutId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _table,
      where: 'id = ?',
      whereArgs: [workoutId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return WorkoutModel.fromMap(maps.first);
  }

  /// Atualiza um treino
  Future<bool> updateWorkout(WorkoutModel workout) async {
    final result = await _db.update(
      _table,
      workout.toMap(),
      where: 'id = ?',
      whereArgs: [workout.id],
    );
    return result > 0;
  }

  /// Inicia um treino
  Future<bool> startWorkout(String workoutId) async {
    final workout = await getWorkout(workoutId);
    if (workout == null || !workout.canStart) return false;

    final updatedWorkout = workout.copyWith(
      status: WorkoutStatus.inProgress,
      startedAt: DateTime.now(),
    );

    return await updateWorkout(updatedWorkout);
  }

  /// Conclui um treino
  Future<bool> completeWorkout(String workoutId) async {
    final workout = await getWorkout(workoutId);
    if (workout == null || !workout.canComplete) return false;

    final updatedWorkout = workout.copyWith(
      status: WorkoutStatus.completed,
      completedAt: DateTime.now(),
    );

    return await updateWorkout(updatedWorkout);
  }

  /// Cancela um treino
  Future<bool> cancelWorkout(String workoutId) async {
    final workout = await getWorkout(workoutId);
    if (workout == null || workout.status == WorkoutStatus.completed) return false;

    final updatedWorkout = workout.copyWith(
      status: WorkoutStatus.cancelled,
    );

    return await updateWorkout(updatedWorkout);
  }

  /// Remove um treino
  Future<bool> deleteWorkout(String workoutId) async {
    final result = await _db.delete(
      _table,
      where: 'id = ?',
      whereArgs: [workoutId],
    );
    return result > 0;
  }

  /// Busca estatísticas de treinos
  Future<Map<String, dynamic>> getWorkoutStats(String userId) async {
    final allWorkouts = await getUserWorkouts(userId);
    
    final totalWorkouts = allWorkouts.length;
    final completedWorkouts = allWorkouts.where((w) => w.status == WorkoutStatus.completed).length;
    final scheduledWorkouts = allWorkouts.where((w) => w.status == WorkoutStatus.scheduled).length;
    final inProgressWorkouts = allWorkouts.where((w) => w.status == WorkoutStatus.inProgress).length;
    final cancelledWorkouts = allWorkouts.where((w) => w.status == WorkoutStatus.cancelled).length;
    
    final totalXpEarned = allWorkouts
        .where((w) => w.status == WorkoutStatus.completed)
        .fold<int>(0, (sum, w) => sum + w.xpReward);
    
    final completionRate = totalWorkouts > 0 ? completedWorkouts / totalWorkouts : 0.0;
    
    return {
      'totalWorkouts': totalWorkouts,
      'completedWorkouts': completedWorkouts,
      'scheduledWorkouts': scheduledWorkouts,
      'inProgressWorkouts': inProgressWorkouts,
      'cancelledWorkouts': cancelledWorkouts,
      'totalXpEarned': totalXpEarned,
      'completionRate': completionRate,
    };
  }

  /// Busca treinos por tipo
  Future<List<WorkoutModel>> getWorkoutsByType(String userId, String type) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _table,
      where: 'userId = ? AND type = ?',
      whereArgs: [userId, type],
      orderBy: 'scheduledDate DESC',
    );

    return List.generate(maps.length, (i) => WorkoutModel.fromMap(maps[i]));
  }

  /// Busca treinos concluídos recentemente
  Future<List<WorkoutModel>> getRecentCompletedWorkouts(String userId, {int limit = 10}) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _table,
      where: 'userId = ? AND status = 2', // completed
      whereArgs: [userId],
      orderBy: 'completedAt DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => WorkoutModel.fromMap(maps[i]));
  }

  /// Limpa treinos antigos (mais de 30 dias)
  Future<int> cleanupOldWorkouts() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    final result = await _db.delete(
      _table,
      where: 'scheduledDate < ? AND status IN (2, 3)', // completed, cancelled
      whereArgs: [thirtyDaysAgo.toIso8601String()],
    );
    
    return result;
  }

  /// Retorna tipos de treino disponíveis
  List<Map<String, dynamic>> getAvailableWorkoutTypes() {
    return [
      {
        'name': 'Musculação',
        'type': 'musculação',
        'icon': '💪',
        'color': 0xFFE57373,
        'defaultDuration': 60,
        'defaultXp': 40,
        'relatedSkills': ['Força'],
        'description': 'Treino focado em força e hipertrofia',
      },
      {
        'name': 'Funcional',
        'type': 'funcional',
        'icon': '🔥',
        'color': 0xFFFFB74D,
        'defaultDuration': 45,
        'defaultXp': 35,
        'relatedSkills': ['Força', 'Resistência'],
        'description': 'Treino de alta intensidade e funcionalidade',
      },
      {
        'name': 'Técnica',
        'type': 'técnica',
        'icon': '🥋',
        'color': 0xFF81C784,
        'defaultDuration': 90,
        'defaultXp': 50,
        'relatedSkills': ['Técnica', 'Mental'],
        'description': 'Treino focado em técnicas de Jiu-Jitsu',
      },
      {
        'name': 'Cardio',
        'type': 'cardio',
        'icon': '🏃',
        'color': 0xFF64B5F6,
        'defaultDuration': 30,
        'defaultXp': 25,
        'relatedSkills': ['Resistência'],
        'description': 'Treino cardiovascular e aeróbico',
      },
      {
        'name': 'Flexibilidade',
        'type': 'flexibilidade',
        'icon': '🧘',
        'color': 0xFFBA68C8,
        'defaultDuration': 30,
        'defaultXp': 20,
        'relatedSkills': ['Flexibilidade'],
        'description': 'Treino de alongamento e mobilidade',
      },
    ];
  }

  /// Retorna mensagem motivacional baseada no progresso
  String getMotivationalMessage(Map<String, dynamic> stats) {
    final completionRate = stats['completionRate'] as double;
    final completedWorkouts = stats['completedWorkouts'] as int;
    final totalWorkouts = stats['totalWorkouts'] as int;
    
    if (totalWorkouts == 0) {
      return 'Comece sua jornada agendando seu primeiro treino!';
    }
    
    if (completionRate >= 0.8) {
      return 'Excelente! Você está mantendo uma consistência incrível!';
    } else if (completionRate >= 0.6) {
      return 'Bom trabalho! Continue assim para melhorar ainda mais!';
    } else if (completionRate >= 0.4) {
      return 'Você está no caminho certo! Tente completar mais treinos.';
    } else {
      return 'Não desista! Cada treino é um passo para o seu objetivo.';
    }
  }
} 