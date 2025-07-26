import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/xp_service.dart';
import '../../services/user_service.dart';
import 'widgets/xp_panel.dart';
import 'widgets/skills_radar.dart';
import 'widgets/daily_missions.dart';
import 'widgets/today_workouts.dart';
import 'widgets/stats_overview.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final userService = context.read<UserService>();
      final xpService = context.read<XPService>();

      final user = await userService.getUser();
      if (user != null) {
        await xpService.initialize(user.id);
      }
    } catch (e) {
      // Trata erro silenciosamente
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JiuTracker'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const XPPanel(),
            const SizedBox(height: 16),
            const SkillsRadar(),
            const SizedBox(height: 16),
            const DailyMissions(),
            const SizedBox(height: 16),
            const TodayWorkouts(),
            const SizedBox(height: 16),
            const StatsOverview(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showQuickActions(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Ações'),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Ações Rápidas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _QuickActionButton(
                  icon: Icons.assignment,
                  title: 'Missões Diárias',
                  subtitle: 'Ver todas as missões',
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.pushNamed(context, '/daily-missions');
                  },
                ),
                _QuickActionButton(
                  icon: Icons.fitness_center,
                  title: 'Meus Treinos',
                  subtitle: 'Gerenciar treinos',
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.pushNamed(context, '/my-workouts');
                  },
                ),
                _QuickActionButton(
                  icon: Icons.ondemand_video,
                  title: 'Aula Técnica',
                  subtitle: '+25 XP',
                  onTap: () async {
                    final newPoints = await context.read<XPService>().addXP(25);
                    Navigator.pop(context);
                    String message = 'Aula assistida! +25 XP';
                    if (newPoints > 0) {
                      message +=
                          ' • +$newPoints ponto${newPoints > 1 ? 's' : ''} de habilidade!';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
                _QuickActionButton(
                  icon: Icons.fitness_center,
                  title: 'Treino Rápido',
                  subtitle: '+30 XP',
                  onTap: () async {
                    final newPoints = await context.read<XPService>().addXP(30);
                    Navigator.pop(context);
                    String message = 'Treino realizado! +30 XP';
                    if (newPoints > 0) {
                      message +=
                          ' • +$newPoints ponto${newPoints > 1 ? 's' : ''} de habilidade!';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
