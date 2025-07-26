/// Modelo que representa um treino agendado
class WorkoutModel {
  final String id;
  final String userId;
  final String name;
  final String type; // musculação, funcional, técnica
  final DateTime scheduledDate;
  final int estimatedDuration; // em minutos
  final WorkoutStatus status;
  final List<String> relatedSkills; // habilidades impactadas
  final int xpReward; // XP ganho ao concluir
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;

  WorkoutModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.scheduledDate,
    required this.estimatedDuration,
    this.status = WorkoutStatus.scheduled,
    required this.relatedSkills,
    required this.xpReward,
    this.startedAt,
    this.completedAt,
    this.notes,
  });

  /// Converte o modelo para um Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type,
      'scheduledDate': scheduledDate.toIso8601String(),
      'estimatedDuration': estimatedDuration,
      'status': status.index,
      'relatedSkills': relatedSkills.join(','),
      'xpReward': xpReward,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  /// Cria um modelo a partir de um Map (do banco de dados)
  factory WorkoutModel.fromMap(Map<String, dynamic> map) {
    return WorkoutModel(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      type: map['type'],
      scheduledDate: DateTime.parse(map['scheduledDate']),
      estimatedDuration: map['estimatedDuration'],
      status: WorkoutStatus.values[map['status'] ?? 0],
      relatedSkills: (map['relatedSkills'] as String?)?.split(',') ?? [],
      xpReward: map['xpReward'],
      startedAt: map['startedAt'] != null ? DateTime.parse(map['startedAt']) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      notes: map['notes'],
    );
  }

  /// Cria uma cópia do modelo com algumas propriedades alteradas
  WorkoutModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    DateTime? scheduledDate,
    int? estimatedDuration,
    WorkoutStatus? status,
    List<String>? relatedSkills,
    int? xpReward,
    DateTime? startedAt,
    DateTime? completedAt,
    String? notes,
  }) {
    return WorkoutModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      status: status ?? this.status,
      relatedSkills: relatedSkills ?? this.relatedSkills,
      xpReward: xpReward ?? this.xpReward,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  /// Verifica se o treino está atrasado
  bool get isOverdue {
    return status == WorkoutStatus.scheduled && 
           DateTime.now().isAfter(scheduledDate.add(Duration(minutes: estimatedDuration)));
  }

  /// Verifica se o treino pode ser iniciado
  bool get canStart {
    return status == WorkoutStatus.scheduled && !isOverdue;
  }

  /// Verifica se o treino pode ser concluído
  bool get canComplete {
    return status == WorkoutStatus.inProgress;
  }

  /// Retorna o ícone baseado no tipo de treino
  String get typeIcon {
    switch (type.toLowerCase()) {
      case 'musculação':
      case 'musculacao':
        return '💪';
      case 'funcional':
        return '🔥';
      case 'técnica':
      case 'tecnica':
        return '🥋';
      case 'cardio':
        return '🏃';
      case 'flexibilidade':
        return '🧘';
      default:
        return '🏋️';
    }
  }

  /// Retorna a cor baseada no tipo de treino
  int get typeColor {
    switch (type.toLowerCase()) {
      case 'musculação':
      case 'musculacao':
        return 0xFFE57373; // Vermelho
      case 'funcional':
        return 0xFFFFB74D; // Laranja
      case 'técnica':
      case 'tecnica':
        return 0xFF81C784; // Verde
      case 'cardio':
        return 0xFF64B5F6; // Azul
      case 'flexibilidade':
        return 0xFFBA68C8; // Roxo
      default:
        return 0xFF90A4AE; // Cinza
    }
  }

  /// Retorna a duração formatada
  String get durationFormatted {
    if (estimatedDuration < 60) {
      return '${estimatedDuration}min';
    } else {
      final hours = estimatedDuration ~/ 60;
      final minutes = estimatedDuration % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}min';
      }
    }
  }

  /// Retorna a data/hora formatada
  String get scheduledDateFormatted {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final workoutDate = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
    
    if (workoutDate.isAtSameMomentAs(today)) {
      return 'Hoje às ${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}';
    } else if (workoutDate.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      return 'Amanhã às ${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}';
    } else {
      return '${scheduledDate.day.toString().padLeft(2, '0')}/${scheduledDate.month.toString().padLeft(2, '0')} às ${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  String toString() {
    return 'WorkoutModel(id: $id, name: $name, type: $type, status: $status)';
  }
}

/// Enum para status do treino
enum WorkoutStatus {
  scheduled,   // Agendado
  inProgress,  // Em andamento
  completed,   // Concluído
  cancelled,   // Cancelado
}

/// Extensão para facilitar o uso do enum
extension WorkoutStatusExtension on WorkoutStatus {
  String get displayName {
    switch (this) {
      case WorkoutStatus.scheduled:
        return 'Agendado';
      case WorkoutStatus.inProgress:
        return 'Em andamento';
      case WorkoutStatus.completed:
        return 'Concluído';
      case WorkoutStatus.cancelled:
        return 'Cancelado';
    }
  }

  String get icon {
    switch (this) {
      case WorkoutStatus.scheduled:
        return '📅';
      case WorkoutStatus.inProgress:
        return '⏳';
      case WorkoutStatus.completed:
        return '✅';
      case WorkoutStatus.cancelled:
        return '❌';
    }
  }

  int get color {
    switch (this) {
      case WorkoutStatus.scheduled:
        return 0xFF2196F3; // Azul
      case WorkoutStatus.inProgress:
        return 0xFFFF9800; // Laranja
      case WorkoutStatus.completed:
        return 0xFF4CAF50; // Verde
      case WorkoutStatus.cancelled:
        return 0xFFF44336; // Vermelho
    }
  }
} 