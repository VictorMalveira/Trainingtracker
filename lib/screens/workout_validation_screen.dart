import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/workout_model.dart';
import '../services/workout_validation_service.dart';
import '../services/user_service.dart';
import '../services/xp_service.dart';

class WorkoutValidationScreen extends StatefulWidget {
  final String? workoutId;
  
  const WorkoutValidationScreen({super.key, this.workoutId});

  @override
  State<WorkoutValidationScreen> createState() => _WorkoutValidationScreenState();
}

class _WorkoutValidationScreenState extends State<WorkoutValidationScreen> {
  final WorkoutValidationService _validationService = WorkoutValidationService();
  List<WorkoutModel> _pendingWorkouts = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userService = context.read<UserService>();
      final user = await userService.getUser();
      
      if (user != null) {
        _userId = user.id;
        await _loadPendingWorkouts();
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPendingWorkouts() async {
    if (_userId == null) return;
    
    try {
      final workouts = await _validationService.getWorkoutsAwaitingValidation(_userId!);
      setState(() {
        _pendingWorkouts = workouts;
      });
    } catch (e) {
      debugPrint('Erro ao carregar treinos pendentes: $e');
    }
  }

  Future<void> _confirmWorkout(WorkoutModel workout) async {
    try {
      final xpService = context.read<XPService>();
      final success = await _validationService.confirmWorkout(workout.id, xpService);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Treino "${workout.name}" confirmado! XP concedido.'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadPendingWorkouts();
        
        // Se foi chamado para um treino específico, volta para a tela anterior
        if (widget.workoutId != null) {
          Navigator.pop(context);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao confirmar treino ou XP expirado.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao confirmar treino: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _denyWorkout(WorkoutModel workout) async {
    try {
      final success = await _validationService.denyWorkout(workout.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Treino "${workout.name}" negado.'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadPendingWorkouts();
        
        // Se foi chamado para um treino específico, volta para a tela anterior
        if (widget.workoutId != null) {
          Navigator.pop(context);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao negar treino.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao negar treino: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showConfirmationDialog(WorkoutModel workout, bool isConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isConfirm ? 'Confirmar Treino' : 'Negar Treino'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Treino: ${workout.name}'),
            Text('Tipo: ${workout.type}'),
            if (workout.plannedDuration != null)
              Text('Duração planejada: ${workout.plannedDuration} min'),
            if (workout.xpReward > 0)
              Text('XP: ${workout.xpReward}'),
            const SizedBox(height: 16),
            Text(
              isConfirm 
                  ? 'Você realmente realizou este treino? O XP será concedido baseado na duração planejada.'
                  : 'Tem certeza que não realizou este treino? Nenhum XP será concedido.',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (isConfirm) {
                _confirmWorkout(workout);
              } else {
                _denyWorkout(workout);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isConfirm ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(isConfirm ? 'Confirmar' : 'Negar'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutModel workout) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final now = DateTime.now();
    final isExpiringSoon = workout.xpExpiresAt != null && 
        workout.xpExpiresAt!.difference(now).inHours < 6;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpiringSoon ? Colors.red : Colors.orange,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          workout.type.toUpperCase(),
                          style: TextStyle(
                            color: Color(workout.typeColor),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '⏰ VALIDAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Informações do treino
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Planejado: ${dateFormat.format(workout.scheduledDate)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              if (workout.endPlanned != null) ...[
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Fim: ${dateFormat.format(workout.endPlanned!)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              
              Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Duração: ${workout.plannedDuration ?? workout.estimatedDuration} min',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '+${workout.xpReward} XP',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              if (workout.xpExpiresAt != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isExpiringSoon ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isExpiringSoon ? Colors.red : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isExpiringSoon ? Icons.warning : Icons.info,
                        size: 16,
                        color: isExpiringSoon ? Colors.red : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isExpiringSoon 
                              ? 'XP expira em ${workout.xpExpiresAt!.difference(now).inHours}h!'
                              : 'XP expira em: ${dateFormat.format(workout.xpExpiresAt!)}',
                          style: TextStyle(
                            color: isExpiringSoon ? Colors.red : Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showConfirmationDialog(workout, false),
                      icon: const Icon(Icons.close),
                      label: const Text('Não Fiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showConfirmationDialog(workout, true),
                      icon: const Icon(Icons.check),
                      label: const Text('Confirmei!'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validar Treinos'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingWorkouts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingWorkouts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum treino aguardando validação',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Todos os seus treinos estão em dia!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingWorkouts.length,
                  itemBuilder: (context, index) {
                    return _buildWorkoutCard(_pendingWorkouts[index]);
                  },
                ),
    );
  }
}