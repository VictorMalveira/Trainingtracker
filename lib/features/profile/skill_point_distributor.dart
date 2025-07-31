import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/skill_model.dart';
import '../../services/xp_service.dart';

class SkillPointDistributor extends StatefulWidget {
  const SkillPointDistributor({super.key});

  @override
  State<SkillPointDistributor> createState() => _SkillPointDistributorState();
}

class _SkillPointDistributorState extends State<SkillPointDistributor> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xpService = context.watch<XPService>();
    final skills = xpService.skills;
    final availablePoints = xpService.availableSkillPoints;

    return FadeTransition(
      opacity: _animation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPointsHeader(availablePoints),
          const SizedBox(height: 16),
          ...skills.map((skill) => _buildSkillItem(skill, xpService)).toList(),
        ],
      ),
    );
  }

  Widget _buildPointsHeader(int availablePoints) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: availablePoints > 0 ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: availablePoints > 0 ? Colors.green[300]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            availablePoints > 0 ? Icons.star : Icons.star_border,
            color: availablePoints > 0 ? Colors.green[700] : Colors.grey[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  availablePoints > 0
                      ? 'Pontos de Habilidade Disponíveis'
                      : 'Sem Pontos Disponíveis',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: availablePoints > 0 ? Colors.green[700] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  availablePoints > 0
                      ? 'Você tem $availablePoints ponto${availablePoints > 1 ? 's' : ''} para distribuir'
                      : 'Continue treinando para ganhar mais pontos',
                  style: TextStyle(
                    fontSize: 12,
                    color: availablePoints > 0 ? Colors.green[600] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (availablePoints > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$availablePoints',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkillItem(SkillModel skill, XPService xpService) {
    final canAddPoint = xpService.canAddSkillPoint() && !skill.isMaxLevel;
    final color = Color(skill.color);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    skill.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                    Text(
                      'Nível ${skill.level}',
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
                    '${skill.pointsInvested}/${skill.maxPoints}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: skill.isMaxLevel ? Colors.green[700] : Colors.grey[800],
                    ),
                  ),
                  Text(
                    skill.isMaxLevel ? 'MÁXIMO' : 'pontos',
                    style: TextStyle(
                      fontSize: 10,
                      color: skill.isMaxLevel ? Colors.green[700] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: skill.progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _getSkillDescription(skill.name),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (canAddPoint)
                ElevatedButton.icon(
                  onPressed: () async {
                    final success = await xpService.addSkillPoint(skill.name);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ponto adicionado em ${skill.name}!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Adicionar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              if (!canAddPoint && skill.isMaxLevel)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Nível Máximo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSkillDescription(String skillName) {
    switch (skillName.toLowerCase()) {
      case 'força':
      case 'forca':
        return 'Aumenta sua capacidade de aplicar pressão e controlar oponentes.';
      case 'agilidade':
        return 'Melhora sua velocidade de movimento e capacidade de transição entre posições.';
      case 'técnica':
      case 'tecnica':
        return 'Aprimora a execução correta de movimentos e a eficiência dos golpes.';
      case 'resistência':
      case 'resistencia':
        return 'Aumenta sua capacidade de manter o ritmo durante toda a luta.';
      case 'flexibilidade':
        return 'Melhora sua capacidade de escapar de posições difíceis e executar movimentos complexos.';
      case 'mental':
        return 'Fortalece sua concentração, estratégia e capacidade de manter a calma sob pressão.';
      default:
        return 'Melhora suas habilidades gerais no Jiu-Jitsu.';
    }
  }
}