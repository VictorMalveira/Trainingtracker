import 'package:sqflite/sqflite.dart';
import '../models/daily_mission_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/user_service.dart';
import '../services/xp_service.dart';
import '../services/daily_mission_service.dart';

/// Serviço responsável por gerenciar penalidades de missões expiradas
class MissionPenaltyService {
  static const String _penaltyLogTable = 'mission_penalties';
  late Database _db;
  
  final UserService _userService;
  final XPService _xpService;
  final DailyMissionService _dailyMissionService;
  
  MissionPenaltyService({
    required UserService userService,
    required XPService xpService,
    required DailyMissionService dailyMissionService,
  }) : _userService = userService,
       _xpService = xpService,
       _dailyMissionService = dailyMissionService;

  /// Inicializa o serviço
  Future<void> initialize() async {
    _db = await DatabaseService.database;
    await _createPenaltyLogTable();
  }

  /// Cria a tabela de log de penalidades
  Future<void> _createPenaltyLogTable() async {
    await _db.execute('''
      CREATE TABLE IF NOT EXISTS $_penaltyLogTable (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        missionId TEXT NOT NULL,
        missionTitle TEXT NOT NULL,
        penaltyXP INTEGER NOT NULL,
        appliedAt TEXT NOT NULL,
        reason TEXT NOT NULL
      )
    ''');
  }

  /// Verifica e aplica penalidades para missões expiradas
  Future<Map<String, dynamic>> checkAndApplyPenalties(String userId) async {
    print('🔍 Verificando penalidades para usuário: $userId');
    
    try {
      // Busca missões expiradas que ainda não tiveram penalidade aplicada
      final expiredMissions = await _getExpiredMissionsWithoutPenalty(userId);
      
      if (expiredMissions.isEmpty) {
        print('✅ Nenhuma missão expirada encontrada');
        return {
          'success': true,
          'penaltiesApplied': 0,
          'totalXPLost': 0,
          'missions': [],
        };
      }

      print('⚠️ Encontradas ${expiredMissions.length} missões expiradas');
      
      int totalXPLost = 0;
      List<Map<String, dynamic>> penalizedMissions = [];
      
      for (final mission in expiredMissions) {
        final penaltyResult = await _applyPenaltyToMission(mission);
        if (penaltyResult['success']) {
          totalXPLost += penaltyResult['xpLost'] as int;
          penalizedMissions.add({
            'mission': mission,
            'xpLost': penaltyResult['xpLost'],
          });
        }
      }
      
      print('💸 Total de XP perdido: $totalXPLost');
      
      return {
        'success': true,
        'penaltiesApplied': penalizedMissions.length,
        'totalXPLost': totalXPLost,
        'missions': penalizedMissions,
      };
      
    } catch (e) {
      print('❌ Erro ao aplicar penalidades: $e');
      return {
        'success': false,
        'error': e.toString(),
        'penaltiesApplied': 0,
        'totalXPLost': 0,
        'missions': [],
      };
    }
  }

  /// Busca missões expiradas que ainda não tiveram penalidade aplicada
  Future<List<DailyMissionModel>> _getExpiredMissionsWithoutPenalty(String userId) async {
    final now = DateTime.now();
    
    // Busca missões do usuário que expiraram e não foram concluídas
    final List<Map<String, dynamic>> maps = await _db.query(
      'daily_missions',
      where: 'userId = ? AND isCompleted = 0 AND hasPenalty = 0 AND deadline < ?',
      whereArgs: [userId, now.toIso8601String()],
    );

    return List.generate(maps.length, (i) => DailyMissionModel.fromMap(maps[i]));
  }

  /// Aplica penalidade a uma missão específica
  Future<Map<String, dynamic>> _applyPenaltyToMission(DailyMissionModel mission) async {
    try {
      print('💸 Aplicando penalidade à missão: ${mission.title}');
      
      // Remove XP do usuário
      final xpRemoved = await _xpService.removeXP(mission.penaltyXP);
      
      if (!xpRemoved) {
        print('⚠️ Não foi possível remover XP (usuário pode ter XP insuficiente)');
      }
      
      // Marca a missão como tendo penalidade aplicada
      final updatedMission = mission.copyWith(hasPenalty: true);
      await _dailyMissionService.updateMission(updatedMission);
      
      // Registra no log de penalidades
      await _logPenalty(
        mission.userId,
        mission.id,
        mission.title,
        mission.penaltyXP,
        'Missão expirada sem conclusão',
      );
      
      print('✅ Penalidade aplicada: -${mission.penaltyXP} XP');
      
      return {
        'success': true,
        'xpLost': mission.penaltyXP,
        'mission': mission,
      };
      
    } catch (e) {
      print('❌ Erro ao aplicar penalidade à missão ${mission.title}: $e');
      return {
        'success': false,
        'error': e.toString(),
        'xpLost': 0,
      };
    }
  }

  /// Registra uma penalidade no log
  Future<void> _logPenalty(
    String userId,
    String missionId,
    String missionTitle,
    int penaltyXP,
    String reason,
  ) async {
    final penaltyId = '${missionId}_penalty_${DateTime.now().millisecondsSinceEpoch}';
    
    await _db.insert(_penaltyLogTable, {
      'id': penaltyId,
      'userId': userId,
      'missionId': missionId,
      'missionTitle': missionTitle,
      'penaltyXP': penaltyXP,
      'appliedAt': DateTime.now().toIso8601String(),
      'reason': reason,
    });
  }

  /// Busca histórico de penalidades de um usuário
  Future<List<Map<String, dynamic>>> getPenaltyHistory(String userId, {int limit = 50}) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _penaltyLogTable,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'appliedAt DESC',
      limit: limit,
    );

    return maps.map((map) => {
      'id': map['id'],
      'missionId': map['missionId'],
      'missionTitle': map['missionTitle'],
      'penaltyXP': map['penaltyXP'],
      'appliedAt': DateTime.parse(map['appliedAt']),
      'reason': map['reason'],
    }).toList();
  }

  /// Busca estatísticas de penalidades
  Future<Map<String, dynamic>> getPenaltyStats(String userId) async {
    final penalties = await getPenaltyHistory(userId);
    
    final totalPenalties = penalties.length;
    final totalXPLost = penalties.fold<int>(0, (sum, penalty) => sum + (penalty['penaltyXP'] as int));
    
    // Penalidades dos últimos 7 dias
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentPenalties = penalties.where((p) => 
      (p['appliedAt'] as DateTime).isAfter(weekAgo)
    ).length;
    
    return {
      'totalPenalties': totalPenalties,
      'totalXPLost': totalXPLost,
      'recentPenalties': recentPenalties,
      'averageXPLostPerPenalty': totalPenalties > 0 ? (totalXPLost / totalPenalties).round() : 0,
    };
  }

  /// Executa verificação automática de penalidades (para ser chamado periodicamente)
  Future<void> runAutomaticPenaltyCheck() async {
    print('🔄 Executando verificação automática de penalidades...');
    
    try {
      // Busca todos os usuários ativos
      final users = await _userService.getAllUsers();
      
      for (final user in users) {
        await checkAndApplyPenalties(user.id);
      }
      
      print('✅ Verificação automática de penalidades concluída');
    } catch (e) {
      print('❌ Erro na verificação automática de penalidades: $e');
    }
  }

  /// Limpa logs de penalidades antigas (mais de 90 dias)
  Future<void> cleanOldPenaltyLogs() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
    
    final deletedCount = await _db.delete(
      _penaltyLogTable,
      where: 'appliedAt < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
    
    print('🧹 Removidos $deletedCount logs de penalidades antigas');
  }
}