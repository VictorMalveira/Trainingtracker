import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/daily_mission_model.dart';
import '../../../services/daily_mission_service.dart';
import '../../../services/user_service.dart';

class DailyMissions extends StatefulWidget {
  const DailyMissions({super.key});

  @override
  State<DailyMissions> createState() => _DailyMissionsState();
}

class _DailyMissionsState extends State<DailyMissions> {
  List<DailyMissionModel> _missions = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    try {
      final userService = context.read<UserService>();
      final dailyMissionService = context.read<DailyMissionService>();

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

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _missions.isEmpty
                    ? _buildEmptyState()
                    : _buildMissionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.assignment, color: Colors.indigo),
        const SizedBox(width: 8),
        Text(
          'Missões Diárias',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (!_isLoading && _missions.isNotEmpty)
          Text(
            '${_stats['completedMissions']}/${_stats['totalMissions']}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/daily-missions'),
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildMissionsList() {
    return Column(
      children: [
        // Barra de progresso
        LinearProgressIndicator(
          value: (_stats['completionRate'] as double) / 100,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            _stats['completionRate'] >= 100 ? Colors.green : Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        
        // Primeiras 3 missões
        ..._missions.take(3).map((mission) => _MissionTile(mission: mission)),
        
        // Mostra mais missões se houver
        if (_missions.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+${_missions.length - 3} mais missões',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Nenhuma missão hoje',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque para ver as missões',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  final DailyMissionModel mission;

  const _MissionTile({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Ícone da habilidade
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(mission.skillColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                mission.skillIcon,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Informações da missão
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '+${mission.xp} XP • ${mission.estimatedTimeFormatted}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: mission.status == MissionStatus.completed
                  ? Colors.green.withOpacity(0.1)
                  : mission.status == MissionStatus.expired
                      ? Colors.red.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              mission.status.icon,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
