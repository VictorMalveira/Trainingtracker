import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/skill_model.dart';

class SkillService {
  final Database _db;
  final String _table = 'user_skills';
  final Uuid _uuid = const Uuid();

  SkillService(this._db);

  /// Cria a tabela de habilidades
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_skills (
        id TEXT PRIMARY KEY,
        userId TEXT,
        name TEXT,
        pointsInvested INTEGER,
        maxPoints INTEGER
      )
    ''');
  }

  /// Busca todas as habilidades do usuário
  Future<List<SkillModel>> getUserSkills(String userId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _table,
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) {
      // Cria habilidades padrão se não existirem
      return await _createDefaultSkills(userId);
    }

    return List.generate(maps.length, (i) => SkillModel.fromMap(maps[i]));
  }

  /// Atualiza uma habilidade
  Future<void> updateSkill(SkillModel skill) async {
    await _db.update(
      _table,
      skill.toMap(),
      where: 'id = ?',
      whereArgs: [skill.id],
    );
  }

  /// Cria habilidades padrão para um usuário
  Future<List<SkillModel>> _createDefaultSkills(String userId) async {
    final defaultSkills = [
      {'name': 'Força', 'pointsInvested': 1},
      {'name': 'Agilidade', 'pointsInvested': 1},
      {'name': 'Técnica', 'pointsInvested': 1},
      {'name': 'Resistência', 'pointsInvested': 0},
      {'name': 'Flexibilidade', 'pointsInvested': 0},
      {'name': 'Mental', 'pointsInvested': 0},
    ];

    final skills = <SkillModel>[];

    for (final skillData in defaultSkills) {
      final skill = SkillModel(
        id: _uuid.v4(),
        userId: userId,
        name: skillData['name'] as String,
        pointsInvested: skillData['pointsInvested'] as int,
      );

      await _db.insert(_table, skill.toMap());
      skills.add(skill);
    }

    return skills;
  }

  /// Busca uma habilidade específica
  Future<SkillModel?> getSkill(String userId, String skillName) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _table,
      where: 'userId = ? AND name = ?',
      whereArgs: [userId, skillName],
    );

    if (maps.isEmpty) return null;
    return SkillModel.fromMap(maps.first);
  }

  /// Adiciona pontos a uma habilidade
  Future<bool> addSkillPoints(
    String userId,
    String skillName,
    int points,
  ) async {
    final skill = await getSkill(userId, skillName);
    if (skill == null) return false;

    final updatedSkill = skill.copyWith(
      pointsInvested: (skill.pointsInvested + points).clamp(0, skill.maxPoints),
    );

    await updateSkill(updatedSkill);
    return true;
  }

  /// Remove pontos de uma habilidade
  Future<bool> removeSkillPoints(
    String userId,
    String skillName,
    int points,
  ) async {
    final skill = await getSkill(userId, skillName);
    if (skill == null) return false;

    final updatedSkill = skill.copyWith(
      pointsInvested: (skill.pointsInvested - points).clamp(0, skill.maxPoints),
    );

    await updateSkill(updatedSkill);
    return true;
  }

  /// Reseta todas as habilidades do usuário
  Future<void> resetSkills(String userId) async {
    await _db.delete(_table, where: 'userId = ?', whereArgs: [userId]);
    await _createDefaultSkills(userId);
  }
}
