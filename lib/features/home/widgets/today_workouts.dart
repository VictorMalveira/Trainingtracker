import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/workout_model.dart';
import '../../../services/workout_service.dart';
import '../../../services/user_service.dart';
import '../../../services/xp_service.dart';

class TodayWorkouts extends StatefulWidget {
  const TodayWorkouts({super.key});

  @override
  State<TodayWorkouts> createState() => _TodayWorkoutsState();
}

class _TodayWorkoutsState extends State<TodayWorkouts> {
  List<WorkoutModel> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    try {
      final userService = context.read<UserService>();
      final workoutService = context.read<WorkoutService>();

      final user = await userService.getUser();
      if (user == null) return;

      _workouts = await workoutService.getTodayWorkouts(user.id);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildWorkoutsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final scheduledWorkouts =
        _workouts.where((w) => w.status == WorkoutStatus.scheduled).length;
    final inProgressWorkouts =
        _workouts.where((w) => w.status == WorkoutStatus.inProgress).length;
    final totalXp = _workouts
        .where(
          (w) =>
              w.status == WorkoutStatus.scheduled ||
              w.status == WorkoutStatus.inProgress,
        )
        .fold<int>(0, (sum, w) => sum + w.xpReward);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Treinos de Hoje',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${scheduledWorkouts + inProgressWorkouts} treinos • $totalXp XP disponível',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () async {
            await Navigator.pushNamed(context, '/create-workout');
            _loadWorkouts();
          },
          tooltip: 'Agendar Treino',
        ),
      ],
    );
  }

  Widget _buildWorkoutsList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final activeWorkouts =
        _workouts
            .where(
              (w) =>
                  w.status == WorkoutStatus.scheduled ||
                  w.status == WorkoutStatus.inProgress,
            )
            .toList();

    if (activeWorkouts.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children:
          activeWorkouts
              .take(3)
              .map(
                (workout) => _WorkoutTile(
                  workout: workout,
                  onStart: () => _startWorkout(workout),
                  onComplete: () => _completeWorkout(workout),
                ),
              )
              .toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Nenhum treino para hoje',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await Navigator.pushNamed(context, '/create-workout');
              _loadWorkouts();
            },
            child: const Text('Agendar Treino'),
          ),
        ],
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  final WorkoutModel workout;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  const _WorkoutTile({
    required this.workout,
    required this.onStart,
    required this.onComplete,
  });

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
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      workout.scheduledDate.hour.toString().padLeft(2, '0') +
                          ':' +
                          workout.scheduledDate.minute.toString().padLeft(
                            2,
                            '0',
                          ),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.timer, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      workout.durationFormatted,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.star, size: 12, color: Colors.amber[600]),
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
              ],
            ),
          ),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    switch (workout.status) {
      case WorkoutStatus.scheduled:
        return ElevatedButton(
          onPressed: workout.canStart ? onStart : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 32),
          ),
          child: const Text('Iniciar'),
        );
      case WorkoutStatus.inProgress:
        return ElevatedButton(
          onPressed: workout.canComplete ? onComplete : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 32),
          ),
          child: const Text('Concluir'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
