import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';

class UserService {
  Database? db;
  final String _table = 'users';

  /// Verifica se existe um usuário cadastrado
  Future<bool> userExists() async {
    if (db == null) return false;
    
    final List<Map<String, dynamic>> result = await db!.query(_table, limit: 1);
    return result.isNotEmpty;
  }

  /// Busca o usuário cadastrado
  Future<UserModel?> getUser() async {
    if (db == null) return null;
    
    final List<Map<String, dynamic>> result = await db!.query(_table, limit: 1);
    if (result.isEmpty) return null;
    
    return UserModel.fromMap(result.first);
  }

  /// Cria um novo usuário
  Future<void> createUser(UserModel user) async {
    if (db == null) throw Exception('Database not initialized');
    
    await db!.insert(_table, user.toMap());
  }

  /// Atualiza dados específicos do usuário
  Future<void> updateUserData({
    int? xpPoints,
    int? currentStreak,
    int? longestStreak,
    String? lastWorkoutDate,
  }) async {
    if (db == null) throw Exception('Database not initialized');
    
    final user = await getUser();
    if (user == null) throw Exception('Usuário não encontrado');
    
    final updateData = <String, dynamic>{};
    if (xpPoints != null) updateData['xpPoints'] = xpPoints;
    if (currentStreak != null) updateData['currentStreak'] = currentStreak;
    if (longestStreak != null) updateData['longestStreak'] = longestStreak;
    if (lastWorkoutDate != null) updateData['lastWorkoutDate'] = lastWorkoutDate;
    
    if (updateData.isNotEmpty) {
      await db!.update(_table, updateData, where: 'id = ?', whereArgs: [user.id]);
    }
  }
} 