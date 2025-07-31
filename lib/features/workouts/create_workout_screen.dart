import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workout_model.dart';
import '../../services/workout_service.dart';
import '../../services/user_service.dart';
import '../../services/workout_validation_service.dart';

class CreateWorkoutScreen extends StatefulWidget {
  const CreateWorkoutScreen({super.key});

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'musculação';
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  int _selectedDuration = 60;
  int _selectedXp = 40;
  List<String> _selectedSkills = ['Força'];

  bool _isLoading = false;
  late List<Map<String, dynamic>> _availableTypes;

  @override
  void initState() {
    super.initState();
    _availableTypes = [
      {
        'name': 'Musculação',
        'type': 'musculação',
        'icon': '💪',
        'color': 0xFFE57373,
        'defaultDuration': 60,
        'defaultXp': 40,
        'relatedSkills': ['Força'],
        'description': 'Treino focado em força e hipertrofia',
      },
      {
        'name': 'Funcional',
        'type': 'funcional',
        'icon': '🔥',
        'color': 0xFFFFB74D,
        'defaultDuration': 45,
        'defaultXp': 35,
        'relatedSkills': ['Força', 'Resistência'],
        'description': 'Treino de alta intensidade e funcionalidade',
      },
      {
        'name': 'Técnica',
        'type': 'técnica',
        'icon': '🥋',
        'color': 0xFF81C784,
        'defaultDuration': 90,
        'defaultXp': 50,
        'relatedSkills': ['Técnica', 'Mental'],
        'description': 'Treino focado em técnicas de Jiu-Jitsu',
      },
      {
        'name': 'Cardio',
        'type': 'cardio',
        'icon': '🏃',
        'color': 0xFF64B5F6,
        'defaultDuration': 30,
        'defaultXp': 25,
        'relatedSkills': ['Resistência'],
        'description': 'Treino cardiovascular e aeróbico',
      },
      {
        'name': 'Flexibilidade',
        'type': 'flexibilidade',
        'icon': '🧘',
        'color': 0xFFBA68C8,
        'defaultDuration': 30,
        'defaultXp': 20,
        'relatedSkills': ['Flexibilidade'],
        'description': 'Treino de alongamento e mobilidade',
      },
      {
        'name': 'Sparring',
        'type': 'sparring',
        'icon': '🥊',
        'color': 0xFFFF7043,
        'defaultDuration': 60,
        'defaultXp': 60,
        'relatedSkills': ['Técnica', 'Mental', 'Resistência'],
        'description': 'Treino de combate e aplicação prática',
      },
      {
        'name': 'Competição',
        'type': 'competição',
        'icon': '🏆',
        'color': 0xFFFFD54F,
        'defaultDuration': 180,
        'defaultXp': 100,
        'relatedSkills': ['Técnica', 'Mental', 'Força', 'Resistência'],
        'description': 'Participação em campeonatos e torneios',
      },
      {
        'name': 'Drilling',
        'type': 'drilling',
        'icon': '🔄',
        'color': 0xFF9C27B0,
        'defaultDuration': 45,
        'defaultXp': 30,
        'relatedSkills': ['Técnica', 'Mental'],
        'description': 'Repetição de movimentos e técnicas',
      },
      {
        'name': 'Aquecimento',
        'type': 'aquecimento',
        'icon': '🔥',
        'color': 0xFFFF9800,
        'defaultDuration': 15,
        'defaultXp': 10,
        'relatedSkills': ['Flexibilidade', 'Resistência'],
        'description': 'Preparação corporal para treinos',
      },
      {
        'name': 'Recuperação',
        'type': 'recuperação',
        'icon': '🛌',
        'color': 0xFF4FC3F7,
        'defaultDuration': 30,
        'defaultXp': 15,
        'relatedSkills': ['Mental', 'Flexibilidade'],
        'description': 'Treino de recuperação ativa e relaxamento',
      },
    ];
    _updateDefaultValues();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateDefaultValues() {
    final selectedTypeData = _availableTypes.firstWhere(
      (type) => type['type'] == _selectedType,
      orElse: () => _availableTypes.first,
    );

    setState(() {
      _selectedDuration = selectedTypeData['defaultDuration'];
      _selectedXp = selectedTypeData['defaultXp'];
      _selectedSkills = List<String>.from(selectedTypeData['relatedSkills']);
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _createWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userService = context.read<UserService>();
      final validationService = WorkoutValidationService();

      final user = await userService.getUser();
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Usuário não encontrado')));
        return;
      }

      // Usa o novo serviço de validação para agendar o treino
      await validationService.scheduleWorkoutWithValidation(
        userId: user.id,
        name: _nameController.text.trim(),
        type: _selectedType,
        startTime: _selectedDate,
        duration: _selectedDuration,
        relatedSkills: _selectedSkills,
        xpReward: _selectedXp,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Treino agendado com validação automática!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao criar treino: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Treino'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome do treino
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Treino',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Digite um nome para o treino';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tipo de treino
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Treino',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items:
                    _availableTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['type'] as String,
                        child: Row(
                          children: [
                            Text(type['icon'] as String),
                            const SizedBox(width: 8),
                            Text(type['name'] as String),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                    _updateDefaultValues();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Data e hora
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Data'),
                      subtitle: Text(
                        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _selectDate,
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Hora'),
                      subtitle: Text(
                        '${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: _selectTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Duração
              DropdownButtonFormField<int>(
                value: _selectedDuration,
                decoration: const InputDecoration(
                  labelText: 'Duração Estimada',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                ),
                items:
                    [15, 30, 45, 60, 75, 90, 105, 120].map((duration) {
                      return DropdownMenuItem(
                        value: duration,
                        child: Text(
                          duration < 60
                              ? '${duration}min'
                              : '${duration ~/ 60}h ${duration % 60 > 0 ? '${duration % 60}min' : ''}',
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDuration = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // XP
              DropdownButtonFormField<int>(
                value: _selectedXp,
                decoration: const InputDecoration(
                  labelText: 'XP de Recompensa',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star),
                ),
                items:
                    [10, 15, 20, 25, 30, 35, 40, 45, 50, 60, 75, 100].map((xp) {
                      return DropdownMenuItem(value: xp, child: Text('$xp XP'));
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedXp = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Habilidades relacionadas
              const Text(
                'Habilidades Impactadas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    [
                      'Força',
                      'Agilidade',
                      'Técnica',
                      'Resistência',
                      'Flexibilidade',
                      'Mental',
                    ].map((skill) {
                      final isSelected = _selectedSkills.contains(skill);
                      return FilterChip(
                        label: Text(skill),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSkills.add(skill);
                            } else {
                              _selectedSkills.remove(skill);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              // Observações
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Botão criar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Agendar Treino',
                            style: TextStyle(fontSize: 16),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
