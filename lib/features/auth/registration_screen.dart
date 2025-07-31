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

  /// Valida todos os campos obrigatórios
  String? _validateRequiredFields() {
    if (_nameController.text.trim().isEmpty) {
      return 'Nome é obrigatório';
    }
    if (_nameController.text.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }
    if (_birthDate == null) {
      return 'Data de nascimento é obrigatória';
    }
    if (_trainingStartDate == null) {
      return 'Data de início do treino é obrigatória';
    }
    if (_weightController.text.trim().isEmpty) {
      return 'Peso é obrigatório';
    }
    return null;
  }

  /// Valida lógica de datas e idade
  String? _validateDatesAndAge() {
    final now = DateTime.now();
    final age = now.difference(_birthDate!).inDays / 365.25;
    
    if (age < 4) {
      return 'Idade mínima para cadastro é 4 anos';
    }
    if (age > 120) {
      return 'Idade máxima para cadastro é 120 anos';
    }
    if (_trainingStartDate!.isAfter(now)) {
      return 'Data de início de treino não pode ser no futuro';
    }
    if (_birthDate!.isAfter(_trainingStartDate!)) {
      return 'Data de nascimento deve ser antes da data de início de treino';
    }
    
    // Validar se começou a treinar muito novo
    final trainingAge = _trainingStartDate!.difference(_birthDate!).inDays / 365.25;
    if (trainingAge < 3) {
      return 'Idade mínima para começar a treinar é 3 anos';
    }
    
    return null;
  }

  /// Valida peso
  String? _validateWeight() {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null) {
      return 'Peso deve ser um número válido';
    }
    if (weight <= 0) {
      return 'Peso deve ser maior que zero';
    }
    if (weight < 10) {
      return 'Peso mínimo é 10kg';
    }
    if (weight > 300) {
      return 'Peso máximo é 300kg';
    }
    return null;
  }

  /// Valida faixa e grau
  String? _validateBeltAndDegree() {
    final maxDegree = _selectedBeltLevel == 'Preta' ? 6 : 4;
    if (_selectedBeltDegree > maxDegree) {
      return 'Grau máximo para faixa $_selectedBeltLevel é $maxDegree';
    }
    return null;
  }

  Future<void> _register() async {
    print('🚀 INICIANDO CADASTRO...');
    
    // Validação do formulário
    if (!_formKey.currentState!.validate()) {
      print('❌ Formulário inválido');
      return;
    }

    // Validações customizadas
    String? error = _validateRequiredFields() ?? 
                   _validateDatesAndAge() ?? 
                   _validateWeight() ?? 
                   _validateBeltAndDegree();
    
    if (error != null) {
      print('❌ Erro de validação: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    setState(() => _isLoading = true);
    print('⏳ Iniciando processo de criação do usuário...');

    try {
      final userService = context.read<UserService>();
      final skillService = context.read<SkillService>();

      // Verificar se já existe usuário (segurança extra)
      final existingUser = await userService.getUser();
      if (existingUser != null) {
        throw Exception('Já existe um usuário cadastrado. Exclua o perfil atual primeiro.');
      }

      final weight = double.parse(_weightController.text.trim());
      final userId = const Uuid().v4();
      
      print('📝 Criando usuário com ID: $userId');
      print('   Nome: ${_nameController.text.trim()}');
      print('   Peso: ${weight}kg');
      print('   Faixa: $_selectedBeltLevel Grau $_selectedBeltDegree');
      print('   Nascimento: ${_birthDate!.toIso8601String()}');
      print('   Início treino: ${_trainingStartDate!.toIso8601String()}');

      // Cria o usuário
      final user = UserModel(
        id: userId,
        name: _nameController.text.trim(),
        birthDate: _birthDate!,
        weight: weight,
        beltLevel: _selectedBeltLevel,
        beltDegree: _selectedBeltDegree,
        xpPoints: 0,
        currentStreak: 0,
        longestStreak: 0,
        lastWorkoutDate: DateTime.now(),
        trainingStartDate: _trainingStartDate!,
      );

      await userService.createUser(user);
      print('✅ Usuário criado no banco de dados');

      // Inicializa as habilidades do usuário
      print('🎯 Inicializando habilidades do usuário...');
      final skills = await skillService.getUserSkills(user.id);
      print('✅ ${skills.length} habilidades inicializadas');

      // Log de sucesso
      print('🎉 CADASTRO CONCLUÍDO COM SUCESSO!');
      print('   Usuário: ${user.name}');
      print('   ID: ${user.id}');
      print('   Habilidades: ${skills.length}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado com sucesso! Bem-vindo ao JiuTracker!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Pequeno delay para mostrar a mensagem de sucesso
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pushReplacementNamed(context, '/home');
      }
      
    } catch (e) {
      print('❌ ERRO no cadastro: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar usuário: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
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
