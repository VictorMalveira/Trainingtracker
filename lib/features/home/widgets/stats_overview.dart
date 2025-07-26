import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/xp_service.dart';

class StatsOverview extends StatelessWidget {
  const StatsOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final xpService = context.watch<XPService>();
    final lostXP = xpService.calculateLostXP();
    
    final stats = {
      'Streak Atual': '${xpService.currentStreak} dias',
      'Recorde': '${xpService.longestStreak} dias',
      'Total XP': '${xpService.xp}',
      'Nível': '${xpService.level}',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estatísticas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: stats.entries.map((entry) {
                return _SimpleStatItem(
                  label: entry.key,
                  value: entry.value,
                  icon: _getIconForStat(entry.key),
                );
              }).toList(),
            ),
            if (lostXP > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Você perdeu $lostXP XP por inatividade',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (xpService.lastLoginDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Último login: ${_formatDate(xpService.lastLoginDate!)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForStat(String statName) {
    switch (statName) {
      case 'Streak Atual':
        return Icons.local_fire_department;
      case 'Recorde':
        return Icons.emoji_events;
      case 'Total XP':
        return Icons.star;
      case 'Nível':
        return Icons.trending_up;
      default:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _SimpleStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SimpleStatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
} 