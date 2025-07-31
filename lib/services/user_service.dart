import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';

class UserService {
  Database? db;
  final String _table = 'users';

  /// Retorna todos os usuários cadastrados
  Future<List<UserModel>> getAllUsers() async {
    if (db == null) return [];
    
    final List<Map<String, dynamic>> result = await db!.query(_table);
    return result.map((map) => UserModel.fromMap(map)).toList();
  }

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
  
  /// Atualiza o usuário completo
  Future<void> updateUser(UserModel user) async {
    if (db == null) throw Exception('Database not initialized');
    
    await db!.update(
      _table, 
      user.toMap(), 
      where: 'id = ?', 
      whereArgs: [user.id]
    );
  }

  /// Exclui o perfil do usuário e todos os dados relacionados
  Future<Map<String, dynamic>> deleteUserProfile() async {
    if (db == null) throw Exception('Database not initialized');
    
    final result = {
      'success': false,
      'message': '',
      'deletedTables': <String>[],
    };

    try {
      final user = await getUser();
      if (user == null) {
        result['message'] = 'Nenhum usuário encontrado para excluir';
        return result;
      }

      final userId = user.id;
      
      // Iniciar transação para garantir consistência
      await db!.transaction((txn) async {
        // 1. Excluir missões completadas do usuário
        await txn.delete('mission_completed', where: 'userId = ?', whereArgs: [userId]);
        (result['deletedTables'] as List<String>).add('mission_completed');
        
        // 2. Excluir missões diárias do usuário
        await txn.delete('daily_missions', where: 'userId = ?', whereArgs: [userId]);
        (result['deletedTables'] as List<String>).add('daily_missions');
        
        // 3. Excluir treinos do usuário
        await txn.delete('workouts', where: 'userId = ?', whereArgs: [userId]);
        (result['deletedTables'] as List<String>).add('workouts');
        
        // 4. Excluir habilidades do usuário
        await txn.delete('skills', where: 'userId = ?', whereArgs: [userId]);
        (result['deletedTables'] as List<String>).add('skills');
        
        // 5. Excluir o usuário
        await txn.delete(_table, where: 'id = ?', whereArgs: [userId]);
        (result['deletedTables'] as List<String>).add('users');
      });

      result['success'] = true;
      result['message'] = 'Perfil excluído com sucesso. Todas as tabelas relacionadas foram limpas.';
      
      print('✅ PERFIL EXCLUÍDO: ${user.name}');
      print('📋 Tabelas limpas: ${(result["deletedTables"] as List<String>).join(", ")}');
      
    } catch (e) {
      result['success'] = false;
      result['message'] = 'Erro ao excluir perfil: $e';
      print('❌ ERRO ao excluir perfil: $e');
    }

    return result;
  }

  /// Valida se o banco está limpo após exclusão
  Future<Map<String, dynamic>> validateCleanDatabase() async {
    if (db == null) throw Exception('Database not initialized');
    
    final validation = {
      'isClean': true,
      'remainingData': <String, int>{},
    };

    try {
      // Verificar cada tabela
      final tables = ['users', 'skills', 'daily_missions', 'mission_completed', 'workouts'];
      
      for (final table in tables) {
        final count = Sqflite.firstIntValue(
          await db!.rawQuery('SELECT COUNT(*) FROM $table')
        ) ?? 0;
        
        (validation['remainingData'] as Map<String, int>)[table] = count;
        if (count > 0) {
          validation['isClean'] = false;
        }
      }
      
      if (validation['isClean'] == true) {
        print('✅ BANCO LIMPO: Todas as tabelas estão vazias');
      } else {
        print('⚠️ DADOS REMANESCENTES encontrados:');
        (validation['remainingData'] as Map<String, int>).forEach((table, count) {
          if (count > 0) {
            print('  - $table: $count registros');
          }
        });
      }
      
    } catch (e) {
      validation['isClean'] = false;
      print('❌ ERRO na validação do banco: $e');
    }

    return validation;
  }
}