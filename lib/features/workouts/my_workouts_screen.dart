import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workout_model.dart';
import '../../services/workout_service.dart';
import '../../services/user_service.dart';
import '../../services/xp_service.dart';

class MyWorkoutsScreen extends StatefulWidget {
  const MyWorkoutsScreen({super.key});

  @override
  State<MyWorkoutsScreen> createState() => _MyWorkoutsScreenState();
}

class _MyWorkoutsScreenState extends State<MyWorkoutsScreen> {
  List<WorkoutModel> _workouts = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, scheduled, completed, cancelled

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() => _isLoading = true);

    try {
      final userService = context.read<UserService>();
      final workoutService = context.read<WorkoutService>();

      final user = await userService.getUser();
      if (user == null) return;

      _workouts = await workoutService.getUserWorkouts(user.id);
      _stats = await workoutService.getWorkoutStats(user.id);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar treinos: $e')));
    }
  }

  Future<void> _startWorkout(WorkoutModel workout) async {
    try {
      final workoutService = context.read<WorkoutService>();

      final success = await workoutService.startWorkout(workout.id);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível iniciar o treino')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Treino iniciado!'),
          backgroundColor: Colors.blue,
        ),
      );

      await _loadWorkouts();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao iniciar treino: $e')));
    }
  }

  Future<void> _completeWorkout(WorkoutModel workout) async {
    try {
      final workoutService = context.read<WorkoutService>();
      final xpService = context.read<XPService>();

      final success = await workoutService.completeWorkout(workout.id);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível concluir o treino')),
        );
        return;
      }

      // Adiciona XP
      final newPoints = await xpService.addXP(workout.xpReward);

      // Mostra feedback
      String message = '🎉 ${workout.name} concluído! +${workout.xpReward} XP';
      if (newPoints > 0) {
        message +=
            ' • +$newPoints ponto${newPoints > 1 ? 's' : ''} de habilidade!';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      await _loadWorkouts();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao concluir treino: $e')));
    }
  }

  Future<void> _cancelWorkout(WorkoutModel workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancelar Treino'),
            content: Text('Tem certeza que deseja cancelar "${workout.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Não'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sim'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      final workoutService = context.read<WorkoutService>();

      final success = await workoutService.cancelWorkout(workout.id);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível cancelar o treino')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Treino cancelado'),
          backgroundColor: Colors.orange,
        ),
      );

      await _loadWorkouts();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao cancelar treino: $e')));
    }
  }

  List<WorkoutModel> get _filteredWorkouts {
    switch (_selectedFilter) {
      case 'scheduled':
        return _workouts
            .where((w) => w.status == WorkoutStatus.scheduled)
            .toList();
      case 'completed':
        return _workouts
            .where((w) => w.status == WorkoutStatus.completed)
            .toList();
      case 'cancelled':
        return _workouts
            .where((w) => w.status == WorkoutStatus.cancelled)
            .toList();
      default:
        return _workouts;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Treinos'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.pushNamed(context, '/create-workout');
              _loadWorkouts();
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildStatsCard(),
                  _buildFilterChips(),
                  Expanded(child: _buildWorkoutsList()),
                ],
              ),
    );
  }

  Widget _buildStatsCard() {
    final completionRate = _stats['completionRate'] ?? 0.0;
    final completedWorkouts = _stats['completedWorkouts'] ?? 0;
    final totalWorkouts = _stats['totalWorkouts'] ?? 0;
    final totalXpEarned = _stats['totalXpEarned'] ?? 0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progresso Geral',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(completionRate * 100).toInt()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: completionRate,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Concluídos',
                  '$completedWorkouts/$totalWorkouts',
                  Icons.check_circle,
                ),
                _buildStatItem('XP Total', '$totalXpEarned', Icons.star),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Todos'),
            selected: _selectedFilter == 'all',
            onSelected: (selected) {
              setState(() => _selectedFilter = 'all');
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Agendados'),
            selected: _selectedFilter == 'scheduled',
            onSelected: (selected) {
              setState(() => _selectedFilter = 'scheduled');
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Concluídos'),
            selected: _selectedFilter == 'completed',
            onSelected: (selected) {
              setState(() => _selectedFilter = 'completed');
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Cancelados'),
            selected: _selectedFilter == 'cancelled',
            onSelected: (selected) {
              setState(() => _selectedFilter = 'cancelled');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsList() {
    if (_filteredWorkouts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredWorkouts.length,
      itemBuilder: (context, index) {
        final workout = _filteredWorkouts[index];
        return _WorkoutCard(
          workout: workout,
          onStart: () => _startWorkout(workout),
          onComplete: () => _completeWorkout(workout),
          onCancel: () => _cancelWorkout(workout),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_selectedFilter) {
      case 'scheduled':
        message = 'Nenhum treino agendado';
        icon = Icons.schedule;
        break;
      case 'completed':
        message = 'Nenhum treino concluído';
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        message = 'Nenhum treino cancelado';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'Nenhum treino encontrado';
        icon = Icons.fitness_center_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          if (_selectedFilter == 'all')
            Text(
              'Comece agendando seu primeiro treino!',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final WorkoutModel workout;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const _WorkoutCard({
    required this.workout,
    required this.onStart,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/workout-details',
            arguments: workout.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(workout.typeIcon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          workout.type,
                          style: TextStyle(
                            color: Color(workout.typeColor),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    workout.scheduledDateFormatted,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    workout.durationFormatted,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.star, size: 16, color: Colors.amber[600]),
                  const SizedBox(width: 4),
                  Text(
                    '+${workout.xpReward} XP',
                    style: TextStyle(
                      color: Colors.amber[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (workout.relatedSkills.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: workout.relatedSkills.map((skill) {
                    return Chip(
                      label: Text(
                        skill,
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.blue[50],
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
              if (workout.notes != null) ...[
                const SizedBox(height: 8),
                Text(
                  workout.notes!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Evitar que o clique nos botões disparem o onTap do InkWell
              GestureDetector(
                onTap: () {},
                child: _buildActionButtons(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(workout.status.color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(workout.status.color)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(workout.status.icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            workout.status.displayName,
            style: TextStyle(
              color: Color(workout.status.color),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    switch (workout.status) {
      case WorkoutStatus.scheduled:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: workout.canStart ? onStart : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Iniciar'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                child: const Text('Cancelar'),
              ),
            ),
          ],
        );
      case WorkoutStatus.inProgress:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: workout.canComplete ? onComplete : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Concluir Treino'),
          ),
        );
      case WorkoutStatus.completed:
        return const SizedBox.shrink();
      case WorkoutStatus.cancelled:
        return const SizedBox.shrink();
      case WorkoutStatus.toValidate:
        return const SizedBox.shrink();
    }
  }
}
