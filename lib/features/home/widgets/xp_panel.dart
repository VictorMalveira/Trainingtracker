import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/xp_service.dart';

class XPPanel extends StatelessWidget {
  const XPPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final xpService = context.watch<XPService>();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progresso',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Nível ${xpService.level}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${xpService.xp} XP',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${xpService.xpToNextLevel} XP para o próximo nível',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Streak: ${xpService.currentStreak} dias',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Recorde: ${xpService.longestStreak} dias',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: xpService.levelProgress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 12),
            if (xpService.availableSkillPoints == 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star_border, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Próximo ponto de habilidade',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${xpService.xp % xpService.xpPorPonto}/${xpService.xpPorPonto} XP restantes',
                            style: TextStyle(
                              color: Colors.orange[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (xpService.availableSkillPoints > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  'Você tem ${xpService.availableSkillPoints} ponto${xpService.availableSkillPoints > 1 ? 's' : ''} de habilidade para distribuir! Toque nos botões +1 para usar.',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 