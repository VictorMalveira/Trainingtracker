import 'package:flutter/foundation.dart';
import '../models/skill_model.dart';
import '../models/user_model.dart';
import 'skill_service.dart';
import 'user_service.dart';
import 'daily_mission_service.dart';

class XPService extends ChangeNotifier {
  final SkillService _skillService;
  final UserService? _userService;
  final DailyMissionService? _dailyMissionService;

  int _xp = 0;
  int _level = 1;
  int _availableSkillPoints = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastLoginDate;
  List<SkillModel> _skills = [];

  // Constantes
  static const int _xpPorPonto = 100;

  XPService(this._skillService, [this._userService, this._dailyMissionService]);

  // Getters
  int get xp => _xp;
  int get level => _level;
  int get availableSkillPoints => _availableSkillPoints;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  DateTime? get lastLoginDate => _lastLoginDate;
  List<SkillModel> get skills => _skills;
  int get xpPorPonto => _xpPorPonto;

  /// Inicializa o serviço carregando dados do usuário
  Future<void> initialize(String userId) async {
    // Carrega habilidades
    _skills = await _skillService.getUserSkills(userId);

    // Carrega dados do usuário se disponível
    if (_userService != null) {
      final user = await _userService!.getUser();
      if (user != null) {
        _xp = user.xpPoints;
        _currentStreak = user.currentStreak;
        _longestStreak = user.longestStreak;
        _lastLoginDate = user.lastWorkoutDate;

        // Verifica bônus de login e inatividade
        await _checkDailyLoginAndInactivity(userId, user);
      }
    }

    _calculateLevel();
    _calculateAvailableSkillPoints();
    notifyListeners();
  }

  /// Verifica bônus de login e inatividade
  Future<Map<String, dynamic>> _checkDailyLoginAndInactivity(
    String userId,
    UserModel user,
  ) async {
    Map<String, dynamic> results = {
      'loginBonus': null,
      'inactivityPenalty': null,
    };

    // Verifica bônus de login
    if (_dailyMissionService != null) {
      final loginBonus = await _dailyMissionService!.checkDailyLoginBonus(
        userId,
      );
      if (!loginBonus['alreadyReceived']) {
        await addXP(loginBonus['xpBonus']);
        if (loginBonus['skillPointBonus'] > 0) {
          _availableSkillPoints += loginBonus['skillPointBonus'] as int;
        }
        results['loginBonus'] = loginBonus;
      }
    }

    // Verifica inatividade
    if (_dailyMissionService != null) {
      final inactivity = await _dailyMissionService!.checkInactivity(
        userId,
        user,
      );
      if (inactivity['hasPenalty']) {
        await removeXP(inactivity['penaltyAmount']);
        results['inactivityPenalty'] = inactivity;
      }
    }

    return results;
  }

  /// Adiciona XP e retorna pontos de habilidade ganhos
  Future<int> addXP(int amount) async {
    final oldPoints = _availableSkillPoints;
    _xp += amount;

    _calculateLevel();
    _calculateAvailableSkillPoints();

    final newPoints = _availableSkillPoints - oldPoints;

    // Salva no banco se UserService estiver disponível
    if (_userService != null) {
      await _userService!.updateUserData(xpPoints: _xp);
    }

    notifyListeners();
    return newPoints;
  }

  /// Remove XP (para penalidades)
  Future<void> removeXP(int amount) async {
    _xp = (_xp - amount).clamp(0, _xp);

    _calculateLevel();
    _calculateAvailableSkillPoints();

    // Salva no banco se UserService estiver disponível
    if (_userService != null) {
      await _userService!.updateUserData(xpPoints: _xp);
    }

    notifyListeners();
  }

  /// Adiciona um ponto de habilidade
  Future<bool> addSkillPoint(String skillName) async {
    if (_availableSkillPoints <= 0) return false;

    final skillIndex = _skills.indexWhere(
      (s) => s.name.toLowerCase() == skillName.toLowerCase(),
    );
    if (skillIndex == -1) return false;

    _skills[skillIndex] = _skills[skillIndex].copyWith(
      pointsInvested: _skills[skillIndex].pointsInvested + 1,
    );

    _availableSkillPoints--;

    // Salva no banco
    await _skillService.updateSkill(_skills[skillIndex]);

    notifyListeners();
    return true;
  }

  /// Remove um ponto de habilidade
  Future<bool> removeSkillPoint(String skillName) async {
    final skillIndex = _skills.indexWhere(
      (s) => s.name.toLowerCase() == skillName.toLowerCase(),
    );
    if (skillIndex == -1) return false;

    if (_skills[skillIndex].pointsInvested <= 0) return false;

    _skills[skillIndex] = _skills[skillIndex].copyWith(
      pointsInvested: _skills[skillIndex].pointsInvested - 1,
    );

    _availableSkillPoints++;

    // Salva no banco
    await _skillService.updateSkill(_skills[skillIndex]);

    notifyListeners();
    return true;
  }

  /// Conclui uma missão e adiciona XP
  Future<Map<String, dynamic>> completeMission(String missionId) async {
    if (_dailyMissionService == null) {
      return {'success': false, 'message': 'Serviço de missões não disponível'};
    }

    final success = await _dailyMissionService!.completeMission(missionId);
    if (!success) {
      return {
        'success': false,
        'message': 'Não foi possível concluir a missão',
      };
    }

    // Busca a missão para obter o XP
    final mission = await _dailyMissionService!.getMission(missionId);
    if (mission == null) {
      return {'success': false, 'message': 'Missão não encontrada'};
    }

    // Adiciona XP
    final newPoints = await addXP(mission.xp);

    return {
      'success': true,
      'xpGained': mission.xp,
      'skillPointsGained': newPoints,
      'mission': mission,
    };
  }

  /// Atualiza a data do último treino
  Future<void> updateLastWorkoutDate() async {
    if (_userService != null) {
      await _userService!.updateUserData(
        lastWorkoutDate: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Calcula o nível baseado no XP
  void _calculateLevel() {
    _level = (_xp / _xpPorPonto).floor() + 1;
  }

  /// Calcula pontos de habilidade disponíveis
  void _calculateAvailableSkillPoints() {
    final pointsFromLevel = (_xp / _xpPorPonto).floor();
    final totalPointsInvested = _skills.fold<int>(
      0,
      (sum, skill) => sum + skill.pointsInvested,
    );
    _availableSkillPoints = pointsFromLevel - totalPointsInvested;
  }

  /// Recarrega as habilidades
  Future<void> reloadSkills(String userId) async {
    _skills = await _skillService.getUserSkills(userId);
    _calculateAvailableSkillPoints();
    notifyListeners();
  }

  /// Reseta todas as habilidades
  Future<void> resetSkills(String userId) async {
    await _skillService.resetSkills(userId);
    _skills = await _skillService.getUserSkills(userId);
    _calculateAvailableSkillPoints();
    notifyListeners();
  }

  /// Obtém estatísticas do usuário
  Map<String, dynamic> getUserStats() {
    final totalPointsInvested = _skills.fold<int>(
      0,
      (sum, skill) => sum + skill.pointsInvested,
    );
    final averageLevel =
        _skills.isNotEmpty
            ? _skills.map((s) => s.level).reduce((a, b) => a + b) /
                _skills.length
            : 0.0;

    return {
      'xp': _xp,
      'level': _level,
      'availableSkillPoints': _availableSkillPoints,
      'totalPointsInvested': totalPointsInvested,
      'averageSkillLevel': averageLevel,
      'currentStreak': _currentStreak,
      'longestStreak': _longestStreak,
      'skills':
          _skills
              .map(
                (s) => {
                  'name': s.name,
                  'level': s.level,
                  'pointsInvested': s.pointsInvested,
                  'progress': s.progress,
                },
              )
              .toList(),
    };
  }

  /// Verifica se o usuário pode ganhar um ponto de habilidade
  bool canGainSkillPoint() {
    return _availableSkillPoints > 0;
  }

  /// Obtém a próxima habilidade recomendada para investir pontos
  SkillModel? getRecommendedSkill() {
    if (_availableSkillPoints <= 0) return null;

    // Retorna a habilidade com menor nível
    _skills.sort((a, b) => a.level.compareTo(b.level));
    return _skills.first;
  }

  /// Retorna XP necessário para o próximo nível
  int get xpToNextLevel {
    final xpForCurrentLevel = (_level - 1) * _xpPorPonto;
    return xpForCurrentLevel + _xpPorPonto - _xp;
  }

  /// Retorna progresso para o próximo nível (0.0 a 1.0)
  double get levelProgress {
    final xpForCurrentLevel = (_level - 1) * _xpPorPonto;
    final xpInCurrentLevel = _xp - xpForCurrentLevel;
    return (xpInCurrentLevel / _xpPorPonto).clamp(0.0, 1.0);
  }

  /// Calcula XP perdido por inatividade
  int calculateLostXP() {
    if (_lastLoginDate == null) return 0;

    final now = DateTime.now();
    final daysSinceLastLogin = now.difference(_lastLoginDate!).inDays;

    if (daysSinceLastLogin > 7) {
      return (daysSinceLastLogin - 7) * 5; // 5 XP por dia após 7 dias
    }

    return 0;
  }

  /// Retorna mensagem motivacional
  String getMotivationalMessage() {
    if (_availableSkillPoints > 0) {
      return 'Você tem $_availableSkillPoints ponto${_availableSkillPoints > 1 ? 's' : ''} de habilidade para distribuir!';
    }

    final xpToNextPoint = _xp % _xpPorPonto;
    if (xpToNextPoint > 0) {
      final remaining = _xpPorPonto - xpToNextPoint;
      return 'Faltam $remaining XP para o próximo ponto de habilidade!';
    }

    return 'Continue treinando para ganhar mais pontos de habilidade!';
  }

  /// Verifica se pode adicionar ponto de habilidade
  bool canAddSkillPoint() {
    return _availableSkillPoints > 0;
  }

  /// Retorna informações sobre o próximo ponto
  Map<String, dynamic> getNextPointInfo() {
    final xpToNextPoint = _xp % _xpPorPonto;
    final remaining = _xpPorPonto - xpToNextPoint;

    return {
      'current': xpToNextPoint,
      'total': _xpPorPonto,
      'remaining': remaining,
      'percentage': (xpToNextPoint / _xpPorPonto) * 100,
    };
  }
}
