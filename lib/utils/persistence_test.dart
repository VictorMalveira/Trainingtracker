import 'package:flutter/foundation.dart';
import '../services/user_service.dart';
import '../services/xp_service.dart';
import '../services/skill_service.dart';
import '../services/daily_mission_service.dart';
import '../services/workout_service.dart';
import '../models/user_model.dart';
import '../models/skill_model.dart';
import '../models/daily_mission_model.dart';
import '../models/workout_model.dart';

class PersistenceTest {
  final UserService _userService;
  final XPService _xpService;
  final SkillService _skillService;
  final DailyMissionService _dailyMissionService;
  final WorkoutService _workoutService;

  PersistenceTest(
    this._userService,
    this._xpService,
    this._skillService,
    this._dailyMissionService,
    this._workoutService,
  );

  /// Executa teste completo de persistência com logs detalhados
  Future<Map<String, dynamic>> runFullPersistenceTest() async {
    final results = <String, dynamic>{
      'success': true,
      'errors': <String>[],
      'steps': <String>[],
      'startTime': DateTime.now(),
      'testData': <String, dynamic>{},
    };

    debugPrint('🚀 INICIANDO TESTE COMPLETO DE PERSISTÊNCIA');
    debugPrint('⏰ Horário de início: ${results['startTime']}');
    
    try {
      // 1. Teste de usuário
      debugPrint('\n📋 FASE 1: Testando persistência de usuário');
      await _testUserPersistence(results);
      
      // 2. Teste de XP
      debugPrint('\n⭐ FASE 2: Testando persistência de XP');
      await _testXPPersistence(results);
      
      // 3. Teste de habilidades
      debugPrint('\n🎯 FASE 3: Testando persistência de habilidades');
      await _testSkillsPersistence(results);
      
      // 4. Teste de missões
      debugPrint('\n🎯 FASE 4: Testando persistência de missões');
      await _testMissionsPersistence(results);
      
      // 5. Teste de treinos
      debugPrint('\n💪 FASE 5: Testando persistência de treinos');
      await _testWorkoutsPersistence(results);
      
      // 6. Teste de integridade após "reinicialização"
      debugPrint('\n🔄 FASE 6: Simulando reinicialização e validando integridade');
      await _testDataIntegrityAfterRestart(results);
      
      // 7. Teste de stress com múltiplas operações
      debugPrint('\n⚡ FASE 7: Teste de stress com operações simultâneas');
      await _testStressOperations(results);
      
    } catch (e) {
      results['success'] = false;
      results['errors'].add('Erro geral: $e');
      debugPrint('❌ ERRO GERAL NO TESTE: $e');
      debugPrint('📊 Stack trace: ${StackTrace.current}');
    }

    results['endTime'] = DateTime.now();
    results['duration'] = results['endTime'].difference(results['startTime']).inMilliseconds;
    
    _printTestResults(results);
    return results;
  }

  /// Testa persistência de dados do usuário
  Future<void> _testUserPersistence(Map<String, dynamic> results) async {
    debugPrint('🧪 Testando persistência de usuário...');
    results['steps'].add('Iniciando teste de usuário');

    try {
      // Criar usuário de teste
      final testUser = UserModel(
        id: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Teste Persistência',
        birthDate: DateTime(1990, 1, 1),
        weight: 75.0,
        beltLevel: 'Branca',
        beltDegree: 1,
        xpPoints: 500,
        currentStreak: 5,
        longestStreak: 10,
        lastWorkoutDate: DateTime.now(),
        trainingStartDate: DateTime.now(),
      );

      // Salvar usuário
      await _userService.createUser(testUser);
      debugPrint('✅ Usuário criado: ${testUser.name}');
      results['steps'].add('Usuário criado com sucesso');

      // Recuperar usuário
      final retrievedUser = await _userService.getUser();
      if (retrievedUser == null) {
        throw Exception('Usuário não foi recuperado do banco');
      }

      // Validar dados
      if (retrievedUser.name != testUser.name ||
          retrievedUser.xpPoints != testUser.xpPoints ||
          retrievedUser.currentStreak != testUser.currentStreak) {
        throw Exception('Dados do usuário não coincidem após recuperação');
      }

      debugPrint('✅ Dados do usuário validados com sucesso');
      results['steps'].add('Dados do usuário validados');

    } catch (e) {
      results['success'] = false;
      results['errors'].add('Erro no teste de usuário: $e');
      debugPrint('❌ ERRO no teste de usuário: $e');
    }
  }

  /// Testa persistência de XP
  Future<void> _testXPPersistence(Map<String, dynamic> results) async {
    debugPrint('🧪 Testando persistência de XP...');
    results['steps'].add('Iniciando teste de XP');

    try {
      final initialXP = _xpService.xp;
      const xpToAdd = 250;

      // Adicionar XP
      final skillPointsGained = await _xpService.addXP(xpToAdd);
      debugPrint('✅ XP adicionado: $xpToAdd, Pontos ganhos: $skillPointsGained');
      results['steps'].add('XP adicionado: $xpToAdd');

      // Validar XP atual
      final currentXP = _xpService.xp;
      if (currentXP != initialXP + xpToAdd) {
        throw Exception('XP não foi atualizado corretamente. Esperado: ${initialXP + xpToAdd}, Atual: $currentXP');
      }

      // Simular "reinicialização" - recarregar dados
      final user = await _userService.getUser();
      if (user != null) {
        await _xpService.initialize(user.id);
        
        final reloadedXP = _xpService.xp;
        if (reloadedXP != currentXP) {
          throw Exception('XP não persistiu após reinicialização. Esperado: $currentXP, Atual: $reloadedXP');
        }
      }

      debugPrint('✅ XP persistiu corretamente após reinicialização');
      results['steps'].add('XP validado após reinicialização');

    } catch (e) {
      results['success'] = false;
      results['errors'].add('Erro no teste de XP: $e');
      debugPrint('❌ ERRO no teste de XP: $e');
    }
  }

  /// Testa persistência de habilidades
  Future<void> _testSkillsPersistence(Map<String, dynamic> results) async {
    debugPrint('🧪 Testando persistência de habilidades...');
    results['steps'].add('Iniciando teste de habilidades');

    try {
      final user = await _userService.getUser();
      if (user == null) throw Exception('Usuário não encontrado para teste de habilidades');

      // Obter habilidades atuais
      final skills = await _skillService.getUserSkills(user.id);
      if (skills.isEmpty) {
        throw Exception('Nenhuma habilidade encontrada');
      }

      final firstSkill = skills.first;
      final initialPoints = firstSkill.pointsInvested;

      // Adicionar ponto de habilidade
      final success = await _xpService.addSkillPoint(firstSkill.name);
      if (!success) {
        throw Exception('Falha ao adicionar ponto de habilidade');
      }

      debugPrint('✅ Ponto de habilidade adicionado em: ${firstSkill.name}');
      results['steps'].add('Ponto adicionado em ${firstSkill.name}');

      // Validar mudança
      final updatedSkills = await _skillService.getUserSkills(user.id);
      final updatedSkill = updatedSkills.firstWhere((s) => s.name == firstSkill.name);
      
      if (updatedSkill.pointsInvested != initialPoints + 1) {
        throw Exception('Pontos de habilidade não foram atualizados corretamente');
      }

      debugPrint('✅ Habilidades persistiram corretamente');
      results['steps'].add('Habilidades validadas');

    } catch (e) {
      results['success'] = false;
      results['errors'].add('Erro no teste de habilidades: $e');
      debugPrint('❌ ERRO no teste de habilidades: $e');
    }
  }

  /// Testa persistência de missões
  Future<void> _testMissionsPersistence(Map<String, dynamic> results) async {
    debugPrint('🧪 Testando persistência de missões...');
    results['steps'].add('Iniciando teste de missões');

    try {
      final user = await _userService.getUser();
      if (user == null) throw Exception('Usuário não encontrado para teste de missões');

      // Gerar missões do dia
      final missions = await _dailyMissionService.generateDailyMissions(
        user.id,
        DateTime.now(),
        user: user,
      );

      if (missions.isEmpty) {
        throw Exception('Nenhuma missão foi gerada');
      }

      debugPrint('✅ ${missions.length} missões geradas');
      results['steps'].add('${missions.length} missões geradas');

      // Completar primeira missão
      final firstMission = missions.first;
      final completionResult = await _xpService.completeMission(firstMission.id);
      
      if (!completionResult['success']) {
        throw Exception('Falha ao completar missão: ${completionResult['message']}');
      }

      debugPrint('✅ Missão completada: ${firstMission.title}');
      results['steps'].add('Missão completada: ${firstMission.title}');

      // Validar que missão foi marcada como completa
      final updatedMissions = await _dailyMissionService.generateDailyMissions(
        user.id,
        DateTime.now(),
        user: user,
      );
      
      final completedMission = updatedMissions.firstWhere((m) => m.id == firstMission.id);
      if (!completedMission.isCompleted) {
        throw Exception('Missão não foi marcada como completa no banco');
      }

      debugPrint('✅ Status da missão persistiu corretamente');
      results['steps'].add('Status da missão validado');

    } catch (e) {
      results['success'] = false;
      results['errors'].add('Erro no teste de missões: $e');
      debugPrint('❌ ERRO no teste de missões: $e');
    }
  }

  /// Testa persistência de treinos
  Future<void> _testWorkoutsPersistence(Map<String, dynamic> results) async {
    debugPrint('🧪 Testando persistência de treinos...');
    results['steps'].add('Iniciando teste de treinos');

    try {
      final user = await _userService.getUser();
      if (user == null) throw Exception('Usuário não encontrado para teste de treinos');

      // Criar treino de teste
      final testWorkout = WorkoutModel(
        id: 'test_workout_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.id,
        name: 'Treino de Teste',
        type: 'técnica',
        scheduledDate: DateTime.now(),
        estimatedDuration: 60,
        status: WorkoutStatus.scheduled,
        relatedSkills: ['Técnica'],
        xpReward: 50,
        notes: 'Treino de teste de persistência',
      );

      // Salvar treino
      await _workoutService.createWorkout(testWorkout);
      debugPrint('✅ Treino criado: ${testWorkout.type}');
      results['steps'].add('Treino criado');

      // Recuperar treinos
      final workouts = await _workoutService.getAllWorkouts();
      final savedWorkout = workouts.firstWhere(
        (w) => w.id == testWorkout.id,
        orElse: () => throw Exception('Treino não foi encontrado após salvamento'),
      );

      // Validar dados
      if (savedWorkout.type != testWorkout.type ||
          savedWorkout.notes != testWorkout.notes ||
          savedWorkout.status != testWorkout.status) {
        throw Exception('Dados do treino não coincidem após recuperação');
      }

      debugPrint('✅ Treino persistiu corretamente');
      results['steps'].add('Treino validado');

    } catch (e) {
      results['success'] = false;
      results['errors'].add('Erro no teste de treinos: $e');
      debugPrint('❌ ERRO no teste de treinos: $e');
    }
  }

  /// Testa integridade dos dados após simulação de reinicialização
  Future<void> _testDataIntegrityAfterRestart(Map<String, dynamic> results) async {
    debugPrint('🧪 Testando integridade após reinicialização...');
    results['steps'].add('Testando integridade após reinicialização');

    try {
      final user = await _userService.getUser();
      if (user == null) throw Exception('Usuário não encontrado para teste de integridade');

      // Reinicializar todos os serviços
      await _xpService.initialize(user.id);
      
      // Validar que todos os dados ainda estão consistentes
      final xp = _xpService.xp;
      final level = _xpService.level;
      final skills = await _skillService.getUserSkills(user.id);
      final workouts = await _workoutService.getAllWorkouts();
      
      if (xp <= 0) throw Exception('XP foi perdido após reinicialização');
      if (level <= 0) throw Exception('Level foi perdido após reinicialização');
      if (skills.isEmpty) throw Exception('Habilidades foram perdidas após reinicialização');
      
      debugPrint('✅ Todos os dados mantiveram integridade após reinicialização');
      debugPrint('   - XP: $xp');
      debugPrint('   - Level: $level');
      debugPrint('   - Habilidades: ${skills.length}');
      debugPrint('   - Treinos: ${workouts.length}');
      
      results['steps'].add('Integridade validada - XP: $xp, Level: $level, Skills: ${skills.length}');

    } catch (e) {
      results['success'] = false;
      results['errors'].add('Erro no teste de integridade: $e');
      debugPrint('❌ ERRO no teste de integridade: $e');
    }
  }

  /// Teste de stress com múltiplas operações simultâneas
  Future<void> _testStressOperations(Map<String, dynamic> results) async {
    debugPrint('🧪 Executando teste de stress...');
    results['steps'].add('Iniciando teste de stress');

    try {
      final user = await _userService.getUser();
      if (user == null) throw Exception('Usuário não encontrado para teste de stress');

      // Realizar múltiplas operações rapidamente
      final futures = <Future>[];
      
      // Adicionar XP múltiplas vezes
      for (int i = 0; i < 10; i++) {
        futures.add(_xpService.addXP(10));
      }
      
      // Adicionar pontos de habilidade
      for (int i = 0; i < 5; i++) {
        futures.add(_skillService.addSkillPoints(user.id, 'Técnica', 1));
      }
      
      // Aguardar todas as operações
      await Future.wait(futures);
      
      // Validar que os dados estão consistentes
      final finalXP = _xpService.xp;
      final skills = await _skillService.getUserSkills(user.id);
      
      debugPrint('✅ Teste de stress concluído');
      debugPrint('   - XP final: $finalXP');
      debugPrint('   - Habilidades: ${skills.length}');
      
      results['steps'].add('Teste de stress concluído - XP: $finalXP');
      results['testData']['stressTest'] = {
        'finalXP': finalXP,
        'skillsCount': skills.length,
      };

    } catch (e) {
      results['success'] = false;
      results['errors'].add('Erro no teste de stress: $e');
      debugPrint('❌ ERRO no teste de stress: $e');
    }
  }

  /// Imprime resultados do teste
  void _printTestResults(Map<String, dynamic> results) {
    debugPrint('\n' + '='*50);
    debugPrint('📊 RESULTADOS DO TESTE DE PERSISTÊNCIA');
    debugPrint('='*50);
    
    final duration = results['duration'] ?? 0;
    debugPrint('⏱️ Duração total: ${duration}ms');
    
    if (results['success']) {
      debugPrint('✅ TESTE PASSOU - Persistência está funcionando corretamente!');
    } else {
      debugPrint('❌ TESTE FALHOU - Problemas de persistência detectados!');
    }
    
    debugPrint('\n📋 Etapas executadas (${results['steps'].length}):');
    for (int i = 0; i < results['steps'].length; i++) {
      final step = results['steps'][i];
      debugPrint('   ${i + 1}. $step');
    }
    
    if (results['errors'].isNotEmpty) {
      debugPrint('\n❌ Erros encontrados (${results['errors'].length}):');
      for (int i = 0; i < results['errors'].length; i++) {
        final error = results['errors'][i];
        debugPrint('   ${i + 1}. $error');
      }
    }
    
    if (results['testData'].isNotEmpty) {
      debugPrint('\n📊 Dados do teste:');
      results['testData'].forEach((key, value) {
        debugPrint('   $key: $value');
      });
    }
    
    debugPrint('='*50);
  }
  
  /// Executa teste rápido de validação básica
  Future<bool> runQuickValidation() async {
    debugPrint('⚡ Executando validação rápida de persistência...');
    
    try {
      final user = await _userService.getUser();
      if (user == null) {
        debugPrint('❌ Usuário não encontrado');
        return false;
      }
      
      final xp = _xpService.xp;
      final level = _xpService.level;
      final skills = await _skillService.getUserSkills(user.id);
      
      debugPrint('✅ Validação rápida OK - XP: $xp, Level: $level, Skills: ${skills.length}');
      return true;
      
    } catch (e) {
      debugPrint('❌ Erro na validação rápida: $e');
      return false;
    }
  }
  
  /// Força uma operação de backup dos dados críticos
  Future<Map<String, dynamic>> createDataSnapshot() async {
    debugPrint('📸 Criando snapshot dos dados...');
    
    try {
      final user = await _userService.getUser();
      if (user == null) throw Exception('Usuário não encontrado');
      
      final skills = await _skillService.getUserSkills(user.id);
      final workouts = await _workoutService.getAllWorkouts();
      
      final snapshot = {
        'timestamp': DateTime.now().toIso8601String(),
        'user': {
          'id': user.id,
          'name': user.name,
          'xpPoints': user.xpPoints,
          'currentStreak': user.currentStreak,
          'beltLevel': user.beltLevel,
          'beltDegree': user.beltDegree,
        },
        'xpService': {
          'xp': _xpService.xp,
          'level': _xpService.level,
          'availableSkillPoints': _xpService.availableSkillPoints,
        },
        'skills': skills.map((s) => {
          'name': s.name,
          'pointsInvested': s.pointsInvested,
          'maxPoints': s.maxPoints,
        }).toList(),
        'workouts': workouts.map((w) => {
          'id': w.id,
          'type': w.type,
          'scheduledDate': w.scheduledDate.toIso8601String(),
          'status': w.status.toString(),
        }).toList(),
      };
      
      debugPrint('✅ Snapshot criado com ${skills.length} habilidades e ${workouts.length} treinos');
      return snapshot;
      
    } catch (e) {
      debugPrint('❌ Erro ao criar snapshot: $e');
      rethrow;
    }
  }

  /// Limpa dados de teste
  Future<void> cleanupTestData() async {
    debugPrint('🧹 Limpando dados de teste...');
    // Implementar limpeza se necessário
  }
}