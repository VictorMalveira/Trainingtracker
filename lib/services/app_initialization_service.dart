import 'dart:async';
import 'package:flutter/foundation.dart';
import 'mission_penalty_service.dart';
import 'daily_mission_service.dart';
import 'user_service.dart';
import 'xp_service.dart';
import 'database_service.dart';
import 'skill_service.dart';
import 'workout_validation_service.dart';
import 'notification_service.dart';

/// Serviço responsável pela inicialização do aplicativo
class AppInitializationService {
  static final AppInitializationService _instance = AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  late MissionPenaltyService _penaltyService;
  late DailyMissionService _missionService;
  late UserService _userService;
  late XPService _xpService;
  late WorkoutValidationService _workoutValidationService;
  late NotificationService _notificationService;
  Timer? _penaltyTimer;
  Timer? _missionGenerationTimer;
  bool _isInitialized = false;

  /// Inicializa todos os serviços necessários
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _userService = UserService();
      
      // Inicializa o banco de dados para o UserService
      _userService.db = await DatabaseService.database;
      
      // Inicializa o SkillService
      final skillService = SkillService(await DatabaseService.database);
      
      // Inicializa o XPService com as dependências necessárias
      _xpService = XPService(skillService, _userService);
      
      // Inicializa o DailyMissionService
      _missionService = DailyMissionService(await DatabaseService.database);
      _penaltyService = MissionPenaltyService(
        userService: _userService,
        xpService: _xpService,
        dailyMissionService: _missionService
      );

      // Inicializa os serviços de notificação e validação de treino
      _notificationService = NotificationService();
      await _notificationService.initialize();
      
      _workoutValidationService = WorkoutValidationService();
      await _workoutValidationService.initialize(await DatabaseService.database);

      // Verifica penalidades imediatamente
      final user = await _userService.getUser();
      if (user != null) {
        await _penaltyService.checkAndApplyPenalties(user.id);
      }

      // Configura verificação automática de penalidades
      _startPenaltyCheck();

      // Configura geração automática de missões
      _startMissionGeneration();

      _isInitialized = true;
      
      if (kDebugMode) {
        print('AppInitializationService: Serviços inicializados com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AppInitializationService: Erro na inicialização: $e');
      }
      rethrow;
    }
  }

  /// Inicia a verificação automática de penalidades
  void _startPenaltyCheck() {
    // Verifica penalidades a cada 1 minuto
    _penaltyTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      try {
        final user = await _userService.getUser();
        if (user != null) {
          await _penaltyService.checkAndApplyPenalties(user.id);
        }
      } catch (e) {
        if (kDebugMode) {
          print('AppInitializationService: Erro na verificação de penalidades: $e');
        }
      }
    });
  }

  /// Inicia a verificação para geração de novas missões
  void _startMissionGeneration() {
    // Verifica se precisa gerar novas missões a cada 5 minutos
    _missionGenerationTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        final now = DateTime.now();
        // Se for um novo dia, gera novas missões
        if (now.hour == 0 && now.minute < 5) {
          // Aqui você pode adicionar lógica para gerar novas missões
          if (kDebugMode) {
            print('AppInitializationService: Novo dia detectado, verificando missões');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('AppInitializationService: Erro na verificação de missões: $e');
        }
      }
    });
  }

  /// Para todos os timers e limpa recursos
  void dispose() {
    _penaltyTimer?.cancel();
    _missionGenerationTimer?.cancel();
    _workoutValidationService.dispose();
    _penaltyTimer = null;
    _missionGenerationTimer = null;
    _isInitialized = false;
    
    if (kDebugMode) {
      print('AppInitializationService: Serviços finalizados');
    }
  }

  /// Força uma verificação manual de penalidades
  Future<void> forceCheckPenalties() async {
    try {
      final user = await _userService.getUser();
      if (user != null) {
        await _penaltyService.checkAndApplyPenalties(user.id);
      }
    } catch (e) {
      if (kDebugMode) {
        print('AppInitializationService: Erro na verificação forçada de penalidades: $e');
      }
      rethrow;
    }
  }

  /// Obtém estatísticas de penalidades
  Future<Map<String, dynamic>> getPenaltyStats() async {
    try {
      final user = await _userService.getUser();
      if (user == null) return {};
      return await _penaltyService.getPenaltyStats(user.id);
    } catch (e) {
      if (kDebugMode) {
        print('AppInitializationService: Erro ao obter estatísticas de penalidades: $e');
      }
      return {};
    }
  }

  /// Obtém histórico de penalidades
  Future<List<Map<String, dynamic>>> getPenaltyHistory({int limit = 50}) async {
    try {
      final user = await _userService.getUser();
      if (user == null) return [];
      return await _penaltyService.getPenaltyHistory(user.id, limit: limit);
    } catch (e) {
      if (kDebugMode) {
        print('AppInitializationService: Erro ao obter histórico de penalidades: $e');
      }
      return [];
    }
  }

  /// Limpa logs antigos de penalidades
  Future<void> cleanOldPenaltyLogs() async {
    try {
      await _penaltyService.cleanOldPenaltyLogs();
    } catch (e) {
      if (kDebugMode) {
        print('AppInitializationService: Erro ao limpar logs antigos: $e');
      }
    }
  }

  /// Verifica se o serviço está inicializado
  bool get isInitialized => _isInitialized;

  /// Obtém uma instância do serviço de penalidades
  MissionPenaltyService get penaltyService {
    if (!_isInitialized) {
      throw StateError('AppInitializationService não foi inicializado');
    }
    return _penaltyService;
  }

  /// Obtém uma instância do serviço de missões
  DailyMissionService get missionService {
    if (!_isInitialized) {
      throw StateError('AppInitializationService não foi inicializado');
    }
    return _missionService;
  }

  /// Obtém uma instância do serviço de validação de treino
  WorkoutValidationService get workoutValidationService {
    if (!_isInitialized) {
      throw StateError('AppInitializationService não foi inicializado');
    }
    return _workoutValidationService;
  }

  /// Obtém uma instância do serviço de notificações
  NotificationService get notificationService {
    if (!_isInitialized) {
      throw StateError('AppInitializationService não foi inicializado');
    }
    return _notificationService;
  }
}