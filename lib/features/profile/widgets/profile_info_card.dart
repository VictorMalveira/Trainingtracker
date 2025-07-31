import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../services/xp_service.dart';

class ProfileInfoCard extends StatelessWidget {
  final UserModel user;

  const ProfileInfoCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final xpService = context.watch<XPService>();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Hero(
                  tag: 'profile-avatar',
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildBeltBadge(user.beltLevel, user.beltDegree),
                          const SizedBox(width: 8),
                          Text(
                            'Nível ${xpService.level}',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, 'XP Total', '${xpService.xp}', Icons.star),
                _buildStatItem(
                  context,
                  'Sequência',
                  '${xpService.currentStreak} dias',
                  Icons.local_fire_department,
                ),
                _buildStatItem(
                  context,
                  'Peso',
                  '${user.weight} kg',
                  Icons.fitness_center,
                ),
              ],
            ),
            if (xpService.availableSkillPoints > 0) ...[  
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Você tem ${xpService.availableSkillPoints} ponto${xpService.availableSkillPoints > 1 ? 's' : ''} de habilidade para distribuir!',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBeltBadge(String beltLevel, int degree) {
    Color beltColor;
    switch (beltLevel.toLowerCase()) {
      case 'branca':
        beltColor = Colors.white;
        break;
      case 'azul':
        beltColor = Colors.blue;
        break;
      case 'roxa':
        beltColor = Colors.purple;
        break;
      case 'marrom':
        beltColor = Colors.brown;
        break;
      case 'preta':
        beltColor = Colors.black;
        break;
      default:
        beltColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: beltColor,
        borderRadius: BorderRadius.circular(4),
        border: beltColor == Colors.white
            ? Border.all(color: Colors.grey[300]!)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            beltLevel,
            style: TextStyle(
              color: beltColor == Colors.white || beltColor == Colors.yellow
                  ? Colors.black
                  : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          if (degree > 0) ...[  
            const SizedBox(width: 4),
            Text(
              '• $degree',
              style: TextStyle(
                color: beltColor == Colors.white || beltColor == Colors.yellow
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}