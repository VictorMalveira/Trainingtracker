import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/skill_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _birthDate;
  String _selectedBeltLevel = 'Branca';
  int _selectedBeltDegree = 0;
  DateTime? _trainingStartDate;
  bool _isLoading = false;

  final List<String> _beltLevels = ['Branca', 'Azul', 'Roxa', 'Marrom', 'Preta'];

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isBirthDate ? DateTime.now().subtract(const Duration(days: 6570)) : DateTime.now(),
      firstDate: isBirthDate ? DateTime(1900) : DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isBirthDate) {
          _birthDate = picked;
        } else {
          _trainingStartDate = picked;
        }
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null || _trainingStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todas as datas')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userService = context.read<UserService>();
      final skillService = context.read<SkillService>();

      // Cria o usuário
      final user = UserModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        birthDate: _birthDate!,
        weight: double.parse(_weightController.text),
        beltLevel: _selectedBeltLevel,
        beltDegree: _selectedBeltDegree,
        lastWorkoutDate: DateTime.now(),
        trainingStartDate: _trainingStartDate!,
      );

      await userService.createUser(user);

      // Inicializa as habilidades do usuário
      await skillService.getUserSkills(user.id);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar usuário: $e')),
        );
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
        title: const Text('Cadastro'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bem-vindo ao JiuTracker!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Complete seu cadastro para começar',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira seu nome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Peso (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu peso';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight <= 0) {
                    return 'Por favor, insira um peso válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Data de Nascimento'),
                subtitle: Text(
                  _birthDate != null
                      ? '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}'
                      : 'Selecione a data',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, true),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedBeltLevel,
                      decoration: const InputDecoration(
                        labelText: 'Faixa',
                        border: OutlineInputBorder(),
                      ),
                      items: _beltLevels.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Text(level),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBeltLevel = value!;
                          // Ajusta o grau máximo baseado na faixa
                          if (value == 'Preta') {
                            _selectedBeltDegree = _selectedBeltDegree.clamp(0, 6);
                          } else {
                            _selectedBeltDegree = _selectedBeltDegree.clamp(0, 4);
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedBeltDegree,
                      decoration: const InputDecoration(
                        labelText: 'Grau',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(
                        _selectedBeltLevel == 'Preta' ? 7 : 5,
                        (index) => DropdownMenuItem(
                          value: index,
                          child: Text(index.toString()),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _selectedBeltDegree = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Data de Início do Treino'),
                subtitle: Text(
                  _trainingStartDate != null
                      ? '${_trainingStartDate!.day.toString().padLeft(2, '0')}/${_trainingStartDate!.month.toString().padLeft(2, '0')}/${_trainingStartDate!.year}'
                      : 'Selecione a data',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, false),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Criar Conta',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
