import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/workout_model.dart';
import 'workout_service.dart';
import 'notification_service.dart';
import 'xp_service.dart';
import 'user_service.dart';

/// Serviço responsável pela validação automática de treinos
class WorkoutValidationService {
  static final WorkoutValidationService _instance = WorkoutValidationService._internal();
  factory WorkoutValidationService() => _instance;
  WorkoutValidationService._internal();

  WorkoutService? _workoutService;
  final NotificationService _notificationService = NotificationService();
  Timer? _validationTimer;
  bool _isInitialized = false;

  /// Inicializa o serviço
  Future<void> initialize(Database db) async {
    if (_isInitialized) return;

    _workoutService = WorkoutService(db);
    await _notificationService.initialize();
    _startValidationTimer();
    _isInitialized = true;
    debugPrint('WorkoutValidationService inicializado');
  }

  /// Inicia o timer de verificação automática
  void _startValidationTimer() {
    // Verifica a cada 5 minutos se há treinos que precisam ser validados
    _validationTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkWorkoutsForValidation();
    });
  }

  /// Para o serviço
  void dispose() {
    _validationTimer?.cancel();
    _isInitialized = false;
  }

  /// Agenda um treino com validação automática
  Future<WorkoutModel> scheduleWorkoutWithValidation({
    required String userId,
    required String name,
    required String type,
    required DateTime startTime,
    required int duration, // em minutos
    required List<String> relatedSkills,
    required int xpReward,
    String? notes,
  }) async {
    final endTime = startTime.add(Duration(minutes: duration));
    final xpExpiresAt = endTime.add(const Duration(hours: 24)); // XP expira em 24h

    final workout = WorkoutModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      name: name,
      type: type,
      scheduledDate: startTime,
      estimatedDuration: duration,
      status: WorkoutStatus.scheduled,
      relatedSkills: relatedSkills,
      xpReward: xpReward,
      startPlanned: startTime,
      endPlanned: endTime,
      plannedDuration: duration,
      xpExpiresAt: xpExpiresAt,
      notes: notes,
    );

    // Salva o treino no banco
    await _workoutService!.createWorkout(workout);

    // Agenda a notificação para o fim do treino
    await _notificationService.scheduleWorkoutValidationNotification(
      workoutId: workout.id,
      workoutName: workout.name,
      scheduledTime: endTime,
    );

    debugPrint('Treino agendado: ${workout.name} de $startTime até $endTime');
    return workout;
  }

  /// Verifica treinos que precisam ser validados
  Future<void> _checkWorkoutsForValidation() async {
    try {
      final now = DateTime.now();
      
      // Busca todos os treinos agendados
      final allWorkouts = await _workoutService!.getAllWorkouts();
      
      for (final workout in allWorkouts) {
        // Verifica se o treino passou do horário planejado
        if (workout.status == WorkoutStatus.scheduled && 
            workout.endPlanned != null && 
            now.isAfter(workout.endPlanned!)) {
          
          await _moveToValidation(workout);
        }
        
        // Verifica se o XP expirou
        if (workout.status == WorkoutStatus.toValidate && 
            workout.xpExpiresAt != null && 
            now.isAfter(workout.xpExpiresAt!)) {
          
          await _expireWorkout(workout);
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar treinos para validação: $e');
    }
  }

  /// Move um treino para status de validação
  Future<void> _moveToValidation(WorkoutModel workout) async {
    final updatedWorkout = workout.copyWith(
      status: WorkoutStatus.toValidate,
    );
    
    await _workoutService!.updateWorkout(updatedWorkout);
    
    // Envia notificação imediata se ainda não foi enviada
    await _notificationService.showImmediateNotification(
      title: '🏋️ Validar Treino',
      body: 'Você concluiu o treino "${workout.name}"? Toque para confirmar!',
      payload: 'workout_validation_${workout.id}',
    );
    
    debugPrint('Treino movido para validação: ${workout.name}');
  }

  /// Expira um treino que não foi validado a tempo
  Future<void> _expireWorkout(WorkoutModel workout) async {
    final updatedWorkout = workout.copyWith(
      status: WorkoutStatus.cancelled,
      notes: (workout.notes ?? '') + '\n[XP expirado por falta de validação]',
    );
    
    await _workoutService!.updateWorkout(updatedWorkout);
    
    // Cancela notificações pendentes
    await _notificationService.cancelNotification(workout.id);
    
    debugPrint('Treino expirado: ${workout.name}');
  }

  /// Confirma um treino e concede XP
  Future<bool> confirmWorkout(String workoutId, XPService xpService) async {
    try {
      final workout = await _workoutService!.getWorkout(workoutId);
      if (workout == null || workout.status != WorkoutStatus.toValidate) {
        return false;
      }

      // Verifica se o XP ainda não expirou
      if (workout.xpExpiresAt != null && DateTime.now().isAfter(workout.xpExpiresAt!)) {
        await _expireWorkout(workout);
        return false;
      }

      // Atualiza o status para concluído
      final updatedWorkout = workout.copyWith(
        status: WorkoutStatus.completed,
        completedAt: DateTime.now(),
      );
      
      await _workoutService!.updateWorkout(updatedWorkout);
      
      // Concede XP baseado na duração planejada
      final xpToGrant = workout.plannedDuration != null 
          ? _calculateXpFromPlannedDuration(workout.plannedDuration!, workout.type)
          : workout.xpReward;
      
      await xpService.addXP(xpToGrant);
      
      // Cancela notificações pendentes
      await _notificationService.cancelNotification(workout.id);
      
      debugPrint('Treino confirmado: ${workout.name} - XP concedido: $xpToGrant');
      return true;
    } catch (e) {
      debugPrint('Erro ao confirmar treino: $e');
      return false;
    }
  }

  /// Nega um treino (XP = 0)
  Future<bool> denyWorkout(String workoutId) async {
    try {
      final workout = await _workoutService!.getWorkout(workoutId);
      if (workout == null || workout.status != WorkoutStatus.toValidate) {
        return false;
      }

      // Atualiza o status para cancelado
      final updatedWorkout = workout.copyWith(
        status: WorkoutStatus.cancelled,
        notes: (workout.notes ?? '') + '\n[Treino negado pelo usuário]',
      );
      
      await _workoutService!.updateWorkout(updatedWorkout);
      
      // Cancela notificações pendentes
      await _notificationService.cancelNotification(workout.id);
      
      debugPrint('Treino negado: ${workout.name}');
      return true;
    } catch (e) {
      debugPrint('Erro ao negar treino: $e');
      return false;
    }
  }

  /// Calcula XP baseado na duração planejada e tipo de treino
  int _calculateXpFromPlannedDuration(int plannedDuration, String workoutType) {
    // Base XP por minuto baseado no tipo de treino
    double xpPerMinute;
    
    switch (workoutType.toLowerCase()) {
      case 'técnica':
      case 'tecnica':
        xpPerMinute = 0.8; // Treinos técnicos dão mais XP
        break;
      case 'musculação':
      case 'musculacao':
        xpPerMinute = 0.7;
        break;
      case 'funcional':
        xpPerMinute = 0.6;
        break;
      case 'cardio':
        xpPerMinute = 0.5;
        break;
      case 'flexibilidade':
        xpPerMinute = 0.4;
        break;
      default:
        xpPerMinute = 0.6;
    }
    
    return (plannedDuration * xpPerMinute).round();
  }

  /// Obtém treinos aguardando validação para um usuário
  Future<List<WorkoutModel>> getWorkoutsAwaitingValidation(String userId) async {
    final allWorkouts = await _workoutService!.getUserWorkouts(userId);
    return allWorkouts.where((w) => w.status == WorkoutStatus.toValidate).toList();
  }

  /// Força verificação de treinos (útil para testes)
  Future<void> forceValidationCheck() async {
    await _checkWorkoutsForValidation();
  }

  /// Cancela um treino agendado
  Future<bool> cancelScheduledWorkout(String workoutId) async {
    try {
      final workout = await _workoutService!.getWorkout(workoutId);
      if (workout == null || workout.status != WorkoutStatus.scheduled) {
        return false;
      }

      final updatedWorkout = workout.copyWith(
        status: WorkoutStatus.cancelled,
        notes: (workout.notes ?? '') + '\n[Cancelado pelo usuário]',
      );
      
      await _workoutService!.updateWorkout(updatedWorkout);
      await _notificationService.cancelNotification(workout.id);
      
      debugPrint('Treino cancelado: ${workout.name}');
      return true;
    } catch (e) {
      debugPrint('Erro ao cancelar treino: $e');
      return false;
    }
  }

  /// Obtém estatísticas de validação
  Future<Map<String, dynamic>> getValidationStats(String userId) async {
    final allWorkouts = await _workoutService!.getUserWorkouts(userId);
    
    final scheduled = allWorkouts.where((w) => w.status == WorkoutStatus.scheduled).length;
    final toValidate = allWorkouts.where((w) => w.status == WorkoutStatus.toValidate).length;
    final completed = allWorkouts.where((w) => w.status == WorkoutStatus.completed).length;
    final cancelled = allWorkouts.where((w) => w.status == WorkoutStatus.cancelled).length;
    final expired = allWorkouts.where((w) => 
        w.status == WorkoutStatus.cancelled && 
        (w.notes?.contains('XP expirado') ?? false)).length;
    
    final total = allWorkouts.length;
    final validationRate = total > 0 ? completed / total : 0.0;
    
    return {
      'scheduled': scheduled,
      'toValidate': toValidate,
      'completed': completed,
      'cancelled': cancelled,
      'expired': expired,
      'total': total,
      'validationRate': validationRate,
    };
  }
}