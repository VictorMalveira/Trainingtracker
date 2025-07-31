import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/workout_model.dart';
import '../../services/workout_service.dart';
import 'workout_details_screen.dart';
import 'create_workout_screen.dart';

class WorkoutsListScreen extends StatefulWidget {
  const WorkoutsListScreen({super.key});

  @override
  State<WorkoutsListScreen> createState() => _WorkoutsListScreenState();
}

class _WorkoutsListScreenState extends State<WorkoutsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'todos';
  String _selectedType = 'todos';
  bool _isLoading = true;
  List<WorkoutModel> _workouts = [];
  List<WorkoutModel> _filteredWorkouts = [];

  final List<String> _filterOptions = [
    'todos',
    'agendados',
    'em_andamento',
    'concluidos',
    'cancelados',
  ];

  final List<String> _typeOptions = [
    'todos',
    'musculação',
    'funcional',
    'técnica',
    'cardio',
    'flexibilidade',
    'sparring',
    'competição',
    'drilling',
    'aquecimento',
    'recuperação',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWorkouts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkouts() async {
    setState(() => _isLoading = true);
    try {
      final workoutService = context.read<WorkoutService>();
      final workouts = await workoutService.getAllWorkouts();
      setState(() {
        _workouts = workouts;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar treinos: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    List<WorkoutModel> filtered = List.from(_workouts);

    // Filtro por status
    if (_selectedFilter != 'todos') {
      WorkoutStatus? status;
      switch (_selectedFilter) {
        case 'agendados':
          status = WorkoutStatus.scheduled;
          break;
        case 'em_andamento':
          status = WorkoutStatus.inProgress;
          break;
        case 'concluidos':
          status = WorkoutStatus.completed;
          break;
        case 'cancelados':
          status = WorkoutStatus.cancelled;
          break;
      }
      if (status != null) {
        filtered = filtered.where((w) => w.status == status).toList();
      }
    }

    // Filtro por tipo
    if (_selectedType != 'todos') {
      filtered = filtered.where((w) => w.type == _selectedType).toList();
    }

    // Ordenar por data
    filtered.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

    setState(() {
      _filteredWorkouts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Treinos'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Todos', icon: Icon(Icons.list)),
            Tab(text: 'Hoje', icon: Icon(Icons.today)),
            Tab(text: 'Próximos', icon: Icon(Icons.schedule)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWorkoutsList(_filteredWorkouts),
                _buildWorkoutsList(_getTodayWorkouts()),
                _buildWorkoutsList(_getUpcomingWorkouts()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateWorkoutScreen(),
            ),
          ).then((_) => _loadWorkouts());
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<WorkoutModel> _getTodayWorkouts() {
    final today = DateTime.now();
    return _filteredWorkouts.where((workout) {
      final workoutDate = workout.scheduledDate;
      return workoutDate.year == today.year &&
          workoutDate.month == today.month &&
          workoutDate.day == today.day;
    }).toList();
  }

  List<WorkoutModel> _getUpcomingWorkouts() {
    final now = DateTime.now();
    return _filteredWorkouts.where((workout) {
      return workout.scheduledDate.isAfter(now) &&
          workout.status == WorkoutStatus.scheduled;
    }).toList();
  }

  Widget _buildWorkoutsList(List<WorkoutModel> workouts) {
    if (workouts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum treino encontrado',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWorkouts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          final workout = workouts[index];
          return _buildWorkoutCard(workout);
        },
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutModel workout) {
    final dateFormat = DateFormat('dd/MM HH:mm');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutDetailsScreen(workoutId: workout.id),
            ),
          ).then((_) => _loadWorkouts());
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(workout.typeColor).withOpacity(0.3),
              width: 1,
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(workout.typeColor).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        workout.typeIcon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workout.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            workout.type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(workout.typeColor),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Color(workout.status.color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        workout.status.displayName,
                        style: TextStyle(
                          color: Color(workout.status.color),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(workout.scheduledDate),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      workout.durationFormatted,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${workout.xpReward} XP',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtros',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _filterOptions.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return FilterChip(
                    label: Text(_getFilterDisplayName(filter)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                        _applyFilters();
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tipo de Treino',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _typeOptions.map((type) {
                  final isSelected = _selectedType == type;
                  return FilterChip(
                    label: Text(_getTypeDisplayName(type)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = type;
                        _applyFilters();
                      });
                    },
                  );
                }).toList(),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilter = 'todos';
                          _selectedType = 'todos';
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Limpar Filtros'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Aplicar'),
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

  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'todos':
        return 'Todos';
      case 'agendados':
        return 'Agendados';
      case 'em_andamento':
        return 'Em Andamento';
      case 'concluidos':
        return 'Concluídos';
      case 'cancelados':
        return 'Cancelados';
      default:
        return filter;
    }
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'todos':
        return 'Todos';
      case 'musculação':
        return 'Musculação';
      case 'funcional':
        return 'Funcional';
      case 'técnica':
        return 'Técnica';
      case 'cardio':
        return 'Cardio';
      case 'flexibilidade':
        return 'Flexibilidade';
      case 'sparring':
        return 'Sparring';
      case 'competição':
        return 'Competição';
      case 'drilling':
        return 'Drilling';
      case 'aquecimento':
        return 'Aquecimento';
      case 'recuperação':
        return 'Recuperação';
      default:
        return type;
    }
  }
}