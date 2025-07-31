/// Modelo que representa uma missão diária
class DailyMissionModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final int xp;
  final String skill; // Habilidade relacionada que ganhará ponto extra
  final bool isCompleted;
  final DateTime date;
  final int estimatedTime; // Tempo estimado em minutos
  final DateTime? completedAt; // Quando foi concluída
  final DateTime deadline; // Prazo máximo para conclusão
  final int penaltyXP; // XP perdido se não cumprir no prazo
  final bool hasPenalty; // Se já aplicou a penalidade
  final int priority; // Prioridade da missão (1-5)

  DailyMissionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.xp,
    required this.skill,
    this.isCompleted = false,
    required this.date,
    required this.estimatedTime,
    this.completedAt,
    DateTime? deadline,
    int? penaltyXP,
    this.hasPenalty = false,
    this.priority = 3,
  }) : deadline = deadline ?? DateTime(date.year, date.month, date.day, 23, 59, 59),
       penaltyXP = penaltyXP ?? (xp * 0.5).round();

  /// Converte o modelo para um Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'xp': xp,
      'skill': skill,
      'isCompleted': isCompleted ? 1 : 0,
      'date': date.toIso8601String(),
      'estimatedTime': estimatedTime,
      'completedAt': completedAt?.toIso8601String(),
      'deadline': deadline.toIso8601String(),
      'penaltyXP': penaltyXP,
      'hasPenalty': hasPenalty ? 1 : 0,
      'priority': priority,
    };
  }

  /// Cria um modelo a partir de um Map (do banco de dados)
  factory DailyMissionModel.fromMap(Map<String, dynamic> map) {
    final date = DateTime.parse(map['date']);
    return DailyMissionModel(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      description: map['description'],
      xp: map['xp'],
      skill: map['skill'],
      isCompleted: map['isCompleted'] == 1,
      date: date,
      estimatedTime: map['estimatedTime'] ?? 30,
      completedAt:
          map['completedAt'] != null
              ? DateTime.parse(map['completedAt'])
              : null,
      deadline: map['deadline'] != null 
          ? DateTime.parse(map['deadline'])
          : DateTime(date.year, date.month, date.day, 23, 59, 59),
      penaltyXP: map['penaltyXP'] ?? ((map['xp'] ?? 0) * 0.5).round(),
      hasPenalty: map['hasPenalty'] == 1,
      priority: map['priority'] ?? 3,
    );
  }

  /// Cria uma cópia do modelo com algumas propriedades alteradas
  DailyMissionModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    int? xp,
    String? skill,
    bool? isCompleted,
    DateTime? date,
    int? estimatedTime,
    DateTime? completedAt,
    DateTime? deadline,
    int? penaltyXP,
    bool? hasPenalty,
    int? priority,
  }) {
    return DailyMissionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      xp: xp ?? this.xp,
      skill: skill ?? this.skill,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      completedAt: completedAt ?? this.completedAt,
      deadline: deadline ?? this.deadline,
      penaltyXP: penaltyXP ?? this.penaltyXP,
      hasPenalty: hasPenalty ?? this.hasPenalty,
      priority: priority ?? this.priority,
    );
  }

  /// Verifica se a missão expirou (não foi concluída até o prazo)
  bool get isExpired {
    final now = DateTime.now();
    return !isCompleted && now.isAfter(deadline);
  }
  
  /// Verifica se a missão está próxima do prazo (últimas 2 horas)
  bool get isNearDeadline {
    final now = DateTime.now();
    final twoHoursBefore = deadline.subtract(const Duration(hours: 2));
    return !isCompleted && now.isAfter(twoHoursBefore) && now.isBefore(deadline);
  }
  
  /// Retorna o tempo restante até o prazo
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(deadline)) return Duration.zero;
    return deadline.difference(now);
  }
  
  /// Retorna o tempo restante formatado
  String get timeRemainingFormatted {
    final remaining = timeRemaining;
    if (remaining == Duration.zero) return 'Expirado';
    
    if (remaining.inDays > 0) {
      return '${remaining.inDays}d ${remaining.inHours % 24}h';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}min';
    } else {
      return '${remaining.inMinutes}min';
    }
  }

  /// Retorna o status da missão
  MissionStatus get status {
    if (isCompleted) return MissionStatus.completed;
    if (isExpired) return MissionStatus.expired;
    if (isNearDeadline) return MissionStatus.urgent;
    return MissionStatus.pending;
  }
  
  /// Retorna a prioridade formatada
  String get priorityFormatted {
    switch (priority) {
      case 1: return 'Muito Baixa';
      case 2: return 'Baixa';
      case 3: return 'Normal';
      case 4: return 'Alta';
      case 5: return 'Crítica';
      default: return 'Normal';
    }
  }
  
  /// Retorna o ícone da prioridade
  String get priorityIcon {
    switch (priority) {
      case 1: return '⬇️';
      case 2: return '↘️';
      case 3: return '➡️';
      case 4: return '↗️';
      case 5: return '⬆️';
      default: return '➡️';
    }
  }

  /// Retorna o ícone baseado na habilidade
  String get skillIcon {
    switch (skill.toLowerCase()) {
      case 'força':
      case 'forca':
        return '💪';
      case 'agilidade':
        return '⚡';
      case 'técnica':
      case 'tecnica':
        return '🥋';
      case 'resistência':
      case 'resistencia':
        return '🔥';
      case 'flexibilidade':
        return '🧘';
      case 'mental':
        return '🧠';
      default:
        return '📋';
    }
  }

  /// Retorna a cor baseada na habilidade
  int get skillColor {
    switch (skill.toLowerCase()) {
      case 'força':
      case 'forca':
        return 0xFFE91E63; // Rosa
      case 'agilidade':
        return 0xFF2196F3; // Azul
      case 'técnica':
      case 'tecnica':
        return 0xFF9C27B0; // Roxo
      case 'resistência':
      case 'resistencia':
        return 0xFFFF5722; // Laranja
      case 'flexibilidade':
        return 0xFF4CAF50; // Verde
      case 'mental':
        return 0xFF607D8B; // Cinza
      default:
        return 0xFF607D8B; // Cinza
    }
  }

  /// Retorna o tempo estimado formatado
  String get estimatedTimeFormatted {
    if (estimatedTime < 60) {
      return '${estimatedTime}min';
    } else {
      final hours = estimatedTime ~/ 60;
      final minutes = estimatedTime % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}min';
      }
    }
  }

  @override
  String toString() {
    return 'DailyMissionModel(id: $id, title: $title, status: $status, date: $date)';
  }
}

/// Enum para o status da missão
enum MissionStatus { pending, urgent, completed, expired }

/// Extensão para facilitar o uso do status
extension MissionStatusExtension on MissionStatus {
  String get displayName {
    switch (this) {
      case MissionStatus.pending:
        return 'Pendente';
      case MissionStatus.urgent:
        return 'Urgente';
      case MissionStatus.completed:
        return 'Concluída';
      case MissionStatus.expired:
        return 'Expirada';
    }
  }

  String get icon {
    switch (this) {
      case MissionStatus.pending:
        return '📋';
      case MissionStatus.urgent:
        return '⚠️';
      case MissionStatus.completed:
        return '✅';
      case MissionStatus.expired:
        return '❌';
    }
  }

  int get color {
    switch (this) {
      case MissionStatus.pending:
        return 0xFF2196F3; // Azul
      case MissionStatus.urgent:
        return 0xFFFF9800; // Laranja
      case MissionStatus.completed:
        return 0xFF4CAF50; // Verde
      case MissionStatus.expired:
        return 0xFFF44336; // Vermelho
    }
  }
  
  /// Retorna se o status permite conclusão
  bool get canComplete {
    return this == MissionStatus.pending || this == MissionStatus.urgent;
  }
}
