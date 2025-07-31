import 'package:flutter/material.dart';
import '../../../models/skill_model.dart';

class SkillPointDistributor extends StatelessWidget {
  final List<SkillModel> skills;
  final int availablePoints;
  final Function(String) onAddPoint;

  const SkillPointDistributor({
    super.key,
    required this.skills,
    required this.availablePoints,
    required this.onAddPoint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribuir Pontos de Habilidade',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Você tem $availablePoints ${availablePoints == 1 ? "ponto" : "pontos"} disponível${availablePoints == 1 ? "" : "s"}. Toque nos botões para distribuir.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        ...skills.map((skill) => _buildSkillItem(context, skill)).toList(),
      ],
    );
  }

  Widget _buildSkillItem(BuildContext context, SkillModel skill) {
    final Color skillColor = _getSkillColor(skill.name);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: skillColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: skillColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: skillColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getSkillIcon(skill.name),
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nível ${skill.level} (${skill.pointsInvested} pontos)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: availablePoints > 0 ? () => onAddPoint(skill.name) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: skillColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('+1'),
          ),
        ],
      ),
    );
  }

  Color _getSkillColor(String skillName) {
    switch (skillName.toLowerCase()) {
      case 'força':
        return Colors.red;
      case 'agilidade':
        return Colors.green;
      case 'técnica':
        return Colors.blue;
      case 'resistência':
        return Colors.orange;
      case 'flexibilidade':
        return Colors.purple;
      case 'mental':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getSkillIcon(String skillName) {
    switch (skillName.toLowerCase()) {
      case 'força':
        return '💪';
      case 'agilidade':
        return '🏃';
      case 'técnica':
        return '🥋';
      case 'resistência':
        return '🔄';
      case 'flexibilidade':
        return '🤸';
      case 'mental':
        return '🧠';
      default:
        return '⭐';
    }
  }
}