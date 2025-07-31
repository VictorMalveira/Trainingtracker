import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/workout_model.dart';
import '../../services/workout_service.dart';
import '../../services/user_service.dart';
import '../../services/xp_service.dart';

class WorkoutDetailsScreen extends StatelessWidget {
  final String workoutId;

  const WorkoutDetailsScreen({
    super.key,
    required this.workoutId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Treino'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navegar para tela de edição
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => EditWorkoutScreen(workoutId: workoutId),
              //   ),
              // );
            },
          ),
        ],
      ),
      body: FutureBuilder<WorkoutModel?>(
        future: _loadWorkout(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final workout = snapshot.data;
          if (workout == null) {
            return const Center(child: Text('Treino não encontrado'));
          }

          return _buildWorkoutDetails(workout, context);
        },
      ),
    );
  }

  Future<WorkoutModel?> _loadWorkout(BuildContext context) async {
    final workoutService = context.read<WorkoutService>();
    return await workoutService.getWorkout(workoutId);
  }

  Widget _buildWorkoutDetails(WorkoutModel workout, BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final duration = '${workout.estimatedDuration} min';
    final xpReward = '${workout.xpReward} XP';
    final status = _getStatusText(workout.status);
    final statusColor = _getStatusColor(workout.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Card(
            elevation: 6,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Color(workout.typeColor).withOpacity(0.1),
                    Color(workout.typeColor).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(workout.typeColor).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            workout.typeIcon,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workout.name,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(workout.typeColor),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  workout.type.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                workout.status == WorkoutStatus.completed
                                    ? Icons.check_circle
                                    : workout.status == WorkoutStatus.inProgress
                                        ? Icons.play_circle
                                        : Icons.schedule,
                                color: statusColor,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        _buildInfoChip(Icons.timer_outlined, duration, Colors.blue),
                        const SizedBox(width: 8),
                        _buildInfoChip(Icons.star_outline, xpReward, Colors.amber),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Detalhes
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Detalhes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      context,
                      'Tipo',
                      workout.type,
                      Icons.fitness_center,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      context,
                      'Data e Hora',
                      dateFormat.format(workout.scheduledDate),
                      Icons.calendar_today,
                    ),
                    if (workout.startedAt != null) ...[
                      const Divider(),
                      _buildDetailRow(
                        context,
                        'Iniciado em',
                        dateFormat.format(workout.startedAt!),
                        Icons.play_arrow,
                      ),
                    ],
                    if (workout.completedAt != null) ...[
                      const Divider(),
                      _buildDetailRow(
                        context,
                        'Concluído em',
                        dateFormat.format(workout.completedAt!),
                        Icons.check_circle,
                      ),
                    ],
                    if (workout.relatedSkills.isNotEmpty) ...[
                      const Divider(),
                      _buildSkillsRow(workout.relatedSkills),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Notas
          if (workout.notes?.isNotEmpty ?? false) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.amber.shade50,
                      Colors.orange.shade50,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            color: Colors.orange.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Notas',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.shade200,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          workout.notes!,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Ações
          const SizedBox(height: 24),
          _buildActionButtons(workout, context),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsRow(List<String> skills) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.psychology_outlined, size: 20, color: Colors.orange),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Habilidades',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills
                    .map((skill) => Chip(
                          label: Text(skill),
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          labelStyle: const TextStyle(color: Colors.orange),
                        ))
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(WorkoutModel workout, BuildContext context) {
    final workoutService = context.read<WorkoutService>();
    final userService = context.read<UserService>();
    final xpService = context.read<XPService>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          if (workout.status == WorkoutStatus.scheduled) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final success = await workoutService.startWorkout(workout.id);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Treino iniciado!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context, true);
                  }
                },
                icon: const Icon(Icons.play_arrow, size: 24),
                label: const Text(
                  'Iniciar Treino',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else if (workout.status == WorkoutStatus.inProgress) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final success = await workoutService.completeWorkout(workout.id);
                  if (success && context.mounted) {
                    final user = await userService.getUser();
                    if (user != null) {
                      await xpService.initialize(user.id);
                      await xpService.addXP(workout.xpReward);
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Treino concluído! +${workout.xpReward} XP'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context, true);
                    }
                  }
                },
                icon: const Icon(Icons.check_circle, size: 24),
                label: const Text(
                  'Concluir Treino',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_circle, size: 24),
                label: const Text(
                  'Treino Concluído',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidade em desenvolvimento'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              icon: Icon(Icons.edit, color: Colors.grey.shade700),
              label: Text(
                'Editar Treino',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(WorkoutStatus status) {
    switch (status) {
      case WorkoutStatus.scheduled:
        return 'Agendado';
      case WorkoutStatus.inProgress:
        return 'Em andamento';
      case WorkoutStatus.completed:
        return 'Concluído';
      case WorkoutStatus.cancelled:
        return 'Cancelado';
      case WorkoutStatus.toValidate:
        return 'Aguardando validação';
    }
  }

  Color _getStatusColor(WorkoutStatus status) {
    switch (status) {
      case WorkoutStatus.scheduled:
        return Colors.blue;
      case WorkoutStatus.inProgress:
        return Colors.orange;
      case WorkoutStatus.completed:
        return Colors.green;
      case WorkoutStatus.cancelled:
        return Colors.red;
      case WorkoutStatus.toValidate:
        return const Color(0xFFFF5722);
    }
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
