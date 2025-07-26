import 'package:sqflite/sqflite.dart';
import 'daily_mission_model.dart';

/// Modelo que representa uma missão concluída (histórico)
class MissionCompletedModel {
  final String id;
  final String userId;
  final String missionId;
  final String title;
  final String description;
  final int xp;
  final String skill;
  final DateTime completedAt;
  final DateTime missionDate;

  MissionCompletedModel({
    required this.id,
    required this.userId,
    required this.missionId,
    required this.title,
    required this.description,
    required this.xp,
    required this.skill,
    required this.completedAt,
    required this.missionDate,
  });

  /// Converte o modelo para um Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'missionId': missionId,
      'title': title,
      'description': description,
      'xp': xp,
      'skill': skill,
      'completedAt': completedAt.toIso8601String(),
      'missionDate': missionDate.toIso8601String(),
    };
  }

  /// Cria um modelo a partir de um Map (do banco de dados)
  factory MissionCompletedModel.fromMap(Map<String, dynamic> map) {
    return MissionCompletedModel(
      id: map['id'],
      userId: map['userId'],
      missionId: map['missionId'],
      title: map['title'],
      description: map['description'],
      xp: map['xp'],
      skill: map['skill'],
      completedAt: DateTime.parse(map['completedAt']),
      missionDate: DateTime.parse(map['missionDate']),
    );
  }

  /// Cria um modelo a partir de uma missão diária
  factory MissionCompletedModel.fromDailyMission(DailyMissionModel mission) {
    return MissionCompletedModel(
      id: '${mission.id}_completed',
      userId: mission.userId,
      missionId: mission.id,
      title: mission.title,
      description: mission.description,
      xp: mission.xp,
      skill: mission.skill,
      completedAt: DateTime.now(),
      missionDate: mission.date,
    );
  }

  @override
  String toString() {
    return 'MissionCompletedModel(id: $id, title: $title, completedAt: $completedAt)';
  }
} 