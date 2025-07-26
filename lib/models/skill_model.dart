class SkillModel {
  final String id;
  final String userId;
  final String name;
  final int pointsInvested;
  final int maxPoints;

  SkillModel({
    required this.id,
    required this.userId,
    required this.name,
    this.pointsInvested = 0,
    this.maxPoints = 10,
  });

  /// Converte o modelo para um Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'pointsInvested': pointsInvested,
      'maxPoints': maxPoints,
    };
  }

  /// Cria um modelo a partir de um Map (do banco de dados)
  factory SkillModel.fromMap(Map<String, dynamic> map) {
    return SkillModel(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      pointsInvested: map['pointsInvested'] ?? 0,
      maxPoints: map['maxPoints'] ?? 10,
    );
  }

  /// Cria uma cópia do modelo com algumas propriedades alteradas
  SkillModel copyWith({
    String? id,
    String? userId,
    String? name,
    int? pointsInvested,
    int? maxPoints,
  }) {
    return SkillModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      pointsInvested: pointsInvested ?? this.pointsInvested,
      maxPoints: maxPoints ?? this.maxPoints,
    );
  }

  /// Retorna o nível da habilidade (0-10)
  int get level => pointsInvested.clamp(0, maxPoints);

  /// Retorna a porcentagem de progresso (0.0 a 1.0)
  double get progress => pointsInvested / maxPoints;

  /// Verifica se a habilidade está no nível máximo
  bool get isMaxLevel => pointsInvested >= maxPoints;

  /// Retorna o ícone baseado no nome da habilidade
  String get icon {
    switch (name.toLowerCase()) {
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

  /// Retorna a cor baseada no nome da habilidade
  int get color {
    switch (name.toLowerCase()) {
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

  @override
  String toString() {
    return 'SkillModel(id: $id, name: $name, level: $level)';
  }
}
