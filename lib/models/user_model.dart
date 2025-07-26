class UserModel {
  final String id;
  final String name;
  final DateTime birthDate;
  final double weight;
  final String beltLevel;
  final int beltDegree;
  final int xpPoints;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastWorkoutDate;
  final DateTime trainingStartDate;
  final DateTime? lastPromotionDate;

  UserModel({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.weight,
    required this.beltLevel,
    required this.beltDegree,
    this.xpPoints = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.lastWorkoutDate,
    required this.trainingStartDate,
    this.lastPromotionDate,
  });

  /// Converte o modelo para um Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'weight': weight,
      'beltLevel': beltLevel,
      'beltDegree': beltDegree,
      'xpPoints': xpPoints,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastWorkoutDate': lastWorkoutDate.toIso8601String(),
      'trainingStartDate': trainingStartDate.toIso8601String(),
      'lastPromotionDate': lastPromotionDate?.toIso8601String(),
    };
  }

  /// Cria um modelo a partir de um Map (do banco de dados)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      birthDate: DateTime.parse(map['birthDate']),
      weight: map['weight'],
      beltLevel: map['beltLevel'],
      beltDegree: map['beltDegree'],
      xpPoints: map['xpPoints'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastWorkoutDate: DateTime.parse(map['lastWorkoutDate']),
      trainingStartDate: DateTime.parse(map['trainingStartDate']),
      lastPromotionDate:
          map['lastPromotionDate'] != null
              ? DateTime.parse(map['lastPromotionDate'])
              : null,
    );
  }

  /// Cria uma cópia do modelo com algumas propriedades alteradas
  UserModel copyWith({
    String? id,
    String? name,
    DateTime? birthDate,
    double? weight,
    String? beltLevel,
    int? beltDegree,
    int? xpPoints,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastWorkoutDate,
    DateTime? trainingStartDate,
    DateTime? lastPromotionDate,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      weight: weight ?? this.weight,
      beltLevel: beltLevel ?? this.beltLevel,
      beltDegree: beltDegree ?? this.beltDegree,
      xpPoints: xpPoints ?? this.xpPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
      trainingStartDate: trainingStartDate ?? this.trainingStartDate,
      lastPromotionDate: lastPromotionDate ?? this.lastPromotionDate,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, beltLevel: $beltLevel, beltDegree: $beltDegree)';
  }
}
