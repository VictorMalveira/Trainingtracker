import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/daily_mission_model.dart';
import '../../services/daily_mission_service.dart';
import '../../services/user_service.dart';
import '../../services/xp_service.dart';

class DailyMissionsScreen extends StatefulWidget {
  const DailyMissionsScreen({super.key});

  @override
  State<DailyMissionsScreen> createState() => _DailyMissionsScreenState();
}

class _DailyMissionsScreenState extends State<DailyMissionsScreen> {
  List<DailyMissionModel> _missions = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  Map<String, dynamic>? _loginBonus;
  Map<String, dynamic>? _inactivityPenalty;

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    setState(() => _isLoading = true);

    try {
      final userService = context.read<UserService>();
      final dailyMissionService = context.read<DailyMissionService>();
      final xpService = context.read<XPService>();

      final user = await userService.getUser();
      if (user == null) return;

      // Gera missões se não existirem
      _missions = await dailyMissionService.generateDailyMissions(
        user.id,
        DateTime.now(),
        user: user,
      );

      // Carrega estatísticas
      _stats = await dailyMissionService.getTodayStats(user.id);

      // Verifica bônus de login e inatividade
      final loginBonus = await dailyMissionService.checkDailyLoginBonus(user.id);
      if (!loginBonus['alreadyReceived']) {
        _loginBonus = loginBonus;
      }

      final inactivity = await dailyMissionService.checkInactivity(user.id, user);
      if (inactivity['hasPenalty']) {
        _inactivityPenalty = inactivity;
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar missões: $e')),
      );
    }
  }

  Future<void> _completeMission(DailyMissionModel mission) async {
    try {
      final xpService = context.read<XPService>();

      final result = await xpService.completeMission(mission.id);
      if (!result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        return;
      }

      // Mostra feedback
      String message = '🎉 ${mission.title} concluída! +${result['xpGained']} XP';
      if (result['skillPointsGained'] > 0) {
        message += ' • +${result['skillPointsGained']} ponto${result['skillPointsGained'] > 1 ? 's' : ''} de habilidade!';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Recarrega as missões
      await _loadMissions();

      // Verifica se completou todas as missões
      final completionRate = _stats['completionRate'] as double;
      if (completionRate >= 100) {
        _showCompletionDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao concluir missão: $e')),
      );
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Missão Cumprida!'),
        content: const Text(
          'Parabéns! Você completou todas as missões do dia!\n\n'
          'Continue assim e veja suas habilidades crescerem!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missões Diárias'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMissions,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bônus de Login
                    if (_loginBonus != null) _buildLoginBonusCard(),
                    
                    // Penalidade de Inatividade
                    if (_inactivityPenalty != null) _buildInactivityCard(),
                    
                    // Estatísticas
                    _buildStatsCard(),
                    
                    // Painel de Pontos
                    _buildPointsPanel(),
                    
                    const SizedBox(height: 20),
                    
                    // Lista de Missões
                    _buildMissionsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoginBonusCard() {
    final bonus = _loginBonus!;
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bônus de Login!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  Text(
                    '+${bonus['xpBonus']} XP • Streak: ${bonus['streakCount']} dias',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (bonus['skillPointBonus'] > 0)
                    Text(
                      '+${bonus['skillPointBonus']} ponto de habilidade!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInactivityCard() {
    final penalty = _inactivityPenalty!;
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inatividade Detectada',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  Text(
                    '${penalty['daysInactive']} dias sem treino • -${penalty['penaltyAmount']} XP',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Faça um treino para evitar mais penalidades!',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progresso de Hoje',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatItem('Missões', '${_stats['completedMissions']}/${_stats['totalMissions']}', Icons.check_circle)),
                Expanded(child: _buildStatItem('XP Ganho', '${_stats['earnedXp']}', Icons.star)),
                Expanded(child: _buildStatItem('Progresso', '${_stats['completionRate'].toStringAsFixed(0)}%', Icons.trending_up)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (_stats['completionRate'] as double) / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                _stats['completionRate'] >= 100 ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getMotivationalMessage(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsPanel() {
    return Consumer<XPService>(
      builder: (context, xpService, child) {
        return Card(
          color: Colors.indigo.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.psychology, color: Colors.indigo, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Pontos Disponíveis: ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${xpService.availableSkillPoints}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const Spacer(),
                if (xpService.availableSkillPoints > 0)
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/home'),
                    icon: const Icon(Icons.radar, size: 16),
                    label: const Text('Distribuir'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.indigo,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.indigo, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildMissionsList() {
    if (_missions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Missões do Dia',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._missions.map((mission) => _MissionCard(
          mission: mission,
          onComplete: () => _completeMission(mission),
        )),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma missão disponível',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'As missões são geradas automaticamente todos os dias',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getMotivationalMessage() {
    final completionRate = _stats['completionRate'] as double;
    final dailyMissionService = context.read<DailyMissionService>();
    return dailyMissionService.getMotivationalMessage(completionRate);
  }
}

class _MissionCard extends StatelessWidget {
  final DailyMissionModel mission;
  final VoidCallback onComplete;

  const _MissionCard({
    required this.mission,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  mission.skillIcon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        mission.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${mission.xp} XP',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      mission.estimatedTimeFormatted,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(
                     color: Color(mission.status.color).withOpacity(0.1),
                     borderRadius: BorderRadius.circular(12),
                   ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(mission.status.icon),
                      const SizedBox(width: 4),
                      Text(
                        mission.status.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Color(mission.status.color),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (mission.status == MissionStatus.pending)
                  ElevatedButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Concluir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 