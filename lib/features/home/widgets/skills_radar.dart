import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../../services/xp_service.dart';
import '../../../models/skill_model.dart';

class SkillsRadar extends StatefulWidget {
  const SkillsRadar({super.key});

  @override
  State<SkillsRadar> createState() => _SkillsRadarState();
}

class _SkillsRadarState extends State<SkillsRadar>
    with TickerProviderStateMixin {
  late AnimationController _radarAnimationController;
  late Animation<double> _radarAnimation;

  @override
  void initState() {
    super.initState();
    _radarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _radarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _radarAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _radarAnimationController.forward();
  }

  @override
  void dispose() {
    _radarAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xpService = context.watch<XPService>();
    final skills = xpService.skills;

    if (skills.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Carregando habilidades...')),
        ),
      );
    }

    return Column(
      children: [
        _PointsPanel(xpService: xpService),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Habilidades',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: AnimatedBuilder(
                      animation: _radarAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _radarAnimation.value,
                          child: _buildRadarChart(skills),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SkillsList(xpService: xpService),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadarChart(List skills) {
    return CustomPaint(
      size: const Size(200, 200),
      painter: RadarChartPainter(skills),
    );
  }
}

class _PointsPanel extends StatelessWidget {
  final XPService xpService;

  const _PointsPanel({required this.xpService});

  @override
  Widget build(BuildContext context) {
    final availablePoints = xpService.availableSkillPoints;

    if (availablePoints == 0) {
      final nextPointInfo = xpService.getNextPointInfo();
      return Container(
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
                    '${nextPointInfo['current']}/${nextPointInfo['total']} XP restantes',
                    style: TextStyle(color: Colors.orange[600], fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
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
              'Você tem $availablePoints ponto${availablePoints > 1 ? 's' : ''} de habilidade para distribuir!',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillsList extends StatelessWidget {
  final XPService xpService;

  const _SkillsList({required this.xpService});

  @override
  Widget build(BuildContext context) {
    final skills = xpService.skills;

    return Column(
      children:
          skills
              .map((skill) => _SkillItem(skill: skill, xpService: xpService))
              .toList(),
    );
  }
}

class _SkillItem extends StatelessWidget {
  final SkillModel skill;
  final XPService xpService;

  const _SkillItem({required this.skill, required this.xpService});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Text(skill.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Nível ${skill.level}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${skill.pointsInvested}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'pontos',
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
            ],
          ),
          const SizedBox(width: 8),
          if (xpService.canAddSkillPoint())
            InkWell(
              onTap: () async {
                final success = await xpService.addSkillPoint(skill.name);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('+1 ponto em ${skill.name}!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final List skills;

  RadarChartPainter(this.skills);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Desenha círculos de fundo
    final paint =
        Paint()
          ..color = Colors.grey[300]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, radius * i / 5, paint);
    }

    // Desenha linhas radiais
    final angleStep = 2 * 3.14159 / skills.length;
    for (int i = 0; i < skills.length; i++) {
      final angle = i * angleStep;
      final endPoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(center, endPoint, paint);
    }

    // Desenha os pontos das habilidades
    final skillPaint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

    for (int i = 0; i < skills.length; i++) {
      final angle = i * angleStep;
      final skillLevel = skills[i].level / 10.0; // Normaliza para 0-1
      final pointRadius = radius * skillLevel;

      final point = Offset(
        center.dx + pointRadius * cos(angle),
        center.dy + pointRadius * sin(angle),
      );

      canvas.drawCircle(point, 6, skillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
