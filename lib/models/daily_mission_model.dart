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
  });

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
    };
  }

  /// Cria um modelo a partir de um Map (do banco de dados)
  factory DailyMissionModel.fromMap(Map<String, dynamic> map) {
    return DailyMissionModel(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      description: map['description'],
      xp: map['xp'],
      skill: map['skill'],
      isCompleted: map['isCompleted'] == 1,
      date: DateTime.parse(map['date']),
      estimatedTime: map['estimatedTime'] ?? 30,
      completedAt:
          map['completedAt'] != null
              ? DateTime.parse(map['completedAt'])
              : null,
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
    );
  }

  /// Verifica se a missão expirou (não foi concluída até o fim do dia)
  bool get isExpired {
    final now = DateTime.now();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return !isCompleted && now.isAfter(endOfDay);
  }

  /// Retorna o status da missão
  MissionStatus get status {
    if (isCompleted) return MissionStatus.completed;
    if (isExpired) return MissionStatus.expired;
    return MissionStatus.pending;
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
enum MissionStatus { pending, completed, expired }

/// Extensão para facilitar o uso do status
extension MissionStatusExtension on MissionStatus {
  String get displayName {
    switch (this) {
      case MissionStatus.pending:
        return 'Pendente';
      case MissionStatus.completed:
        return 'Concluída';
      case MissionStatus.expired:
        return 'Expirada';
    }
  }

  String get icon {
    switch (this) {
      case MissionStatus.pending:
        return '✅';
      case MissionStatus.completed:
        return '🎉';
      case MissionStatus.expired:
        return '⏰';
    }
  }

  int get color {
    switch (this) {
      case MissionStatus.pending:
        return 0xFF2196F3; // Azul
      case MissionStatus.completed:
        return 0xFF4CAF50; // Verde
      case MissionStatus.expired:
        return 0xFFF44336; // Vermelho
    }
  }
}
