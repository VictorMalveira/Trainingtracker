import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/xp_service.dart';
import '../../services/workout_service.dart';
import '../../services/daily_mission_service.dart';
import '../../services/user_service.dart';
import '../../models/workout_model.dart';
import '../../models/mission_completed_model.dart';
import 'widgets/xp_history_chart.dart';
import 'widgets/animated_skills_radar.dart';
import 'widgets/history_list_item.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<WorkoutModel> _completedWorkouts = [];
  List<MissionCompletedModel> _completedMissions = [];
  Map<String, dynamic> _xpHistory = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final workoutService = context.read<WorkoutService>();
      final dailyMissionService = context.read<DailyMissionService>();
      final xpService = context.read<XPService>();

      // Carrega treinos concluídos
      final user = await context.read<UserService>().getUser();
      if (user != null) {
        _completedWorkouts = await workoutService.getCompletedWorkouts(user.id);
        _completedMissions = await dailyMissionService.getMissionHistory(user.id);
        _xpHistory = await xpService.getXpHistory(user.id);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Progresso'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Visão Geral'),
            Tab(text: 'Treinos'),
            Tab(text: 'Missões'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildWorkoutsTab(),
                _buildMissionsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final xpService = context.watch<XPService>();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Evolução de XP',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: XpHistoryChart(xpHistory: _xpHistory),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Evolução de Habilidades',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: AnimatedSkillsRadar(skills: xpService.skills),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estatísticas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Treinos',
                        _completedWorkouts.length.toString(),
                        Icons.fitness_center,
                      ),
                      _buildStatItem(
                        'Missões',
                        _completedMissions.length.toString(),
                        Icons.task_alt,
                      ),
                      _buildStatItem(
                        'Nível',
                        xpService.level.toString(),
                        Icons.star,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsTab() {
    if (_completedWorkouts.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum treino concluído ainda.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _completedWorkouts.length,
      itemBuilder: (context, index) {
        final workout = _completedWorkouts[index];
        return HistoryListItem(
          title: workout.name,
          subtitle: 'Concluído em ${_formatDate(workout.completedAt!)}',
          trailing: '+${workout.xpReward} XP',
          icon: Icons.fitness_center,
          color: Colors.green,
        );
      },
    );
  }

  Widget _buildMissionsTab() {
    if (_completedMissions.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma missão concluída ainda.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _completedMissions.length,
      itemBuilder: (context, index) {
        final mission = _completedMissions[index];
        return HistoryListItem(
          title: mission.title,
          subtitle: 'Concluída em ${_formatDate(mission.completedAt)}',
          trailing: '+${mission.xp} XP',
          icon: Icons.task_alt,
          color: Colors.blue,
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}