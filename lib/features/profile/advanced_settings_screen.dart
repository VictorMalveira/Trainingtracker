import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/user_service.dart';
import '../../services/xp_service.dart';
import '../../services/skill_service.dart';
import '../../services/daily_mission_service.dart';
import '../../services/workout_service.dart';
import '../../utils/persistence_test.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  bool _isRunningTest = false;
  Map<String, dynamic>? _lastTestResults;
  String _testOutput = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _runPersistenceTest() async {
    setState(() {
      _isRunningTest = true;
      _testOutput = 'Iniciando teste de persistência...\n';
      _lastTestResults = null;
    });

    try {
      final persistenceTest = PersistenceTest(
        context.read<UserService>(),
        context.read<XPService>(),
        context.read<SkillService>(),
        context.read<DailyMissionService>(),
        context.read<WorkoutService>(),
      );

      final results = await persistenceTest.runFullPersistenceTest();
      
      setState(() {
        _lastTestResults = results;
        _testOutput += '\n✅ Teste concluído!\n';
        _testOutput += 'Status: ${results['success'] ? 'PASSOU' : 'FALHOU'}\n';
        _testOutput += 'Duração: ${results['duration']}ms\n';
        _testOutput += 'Etapas: ${results['steps'].length}\n';
        if (results['errors'].isNotEmpty) {
          _testOutput += 'Erros: ${results['errors'].length}\n';
        }
      });

      // Auto-scroll para o final
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

    } catch (e) {
      setState(() {
        _testOutput += '\n❌ Erro durante o teste: $e\n';
      });
    } finally {
      setState(() {
        _isRunningTest = false;
      });
    }
  }

  Future<void> _runQuickValidation() async {
    setState(() {
      _testOutput += '\n⚡ Executando validação rápida...\n';
    });

    try {
      final persistenceTest = PersistenceTest(
        context.read<UserService>(),
        context.read<XPService>(),
        context.read<SkillService>(),
        context.read<DailyMissionService>(),
        context.read<WorkoutService>(),
      );

      final isValid = await persistenceTest.runQuickValidation();
      
      setState(() {
        _testOutput += isValid 
          ? '✅ Validação rápida: OK\n'
          : '❌ Validação rápida: FALHOU\n';
      });

    } catch (e) {
      setState(() {
        _testOutput += '❌ Erro na validação: $e\n';
      });
    }
  }

  Future<void> _createDataSnapshot() async {
    setState(() {
      _testOutput += '\n📸 Criando snapshot dos dados...\n';
    });

    try {
      final persistenceTest = PersistenceTest(
        context.read<UserService>(),
        context.read<XPService>(),
        context.read<SkillService>(),
        context.read<DailyMissionService>(),
        context.read<WorkoutService>(),
      );

      final snapshot = await persistenceTest.createDataSnapshot();
      
      setState(() {
        _testOutput += '✅ Snapshot criado:\n';
        _testOutput += '  - Usuário: ${snapshot['user']['name']}\n';
        _testOutput += '  - XP: ${snapshot['xpService']['xp']}\n';
        _testOutput += '  - Level: ${snapshot['xpService']['level']}\n';
        _testOutput += '  - Habilidades: ${snapshot['skills'].length}\n';
        _testOutput += '  - Treinos: ${snapshot['workouts'].length}\n';
      });

    } catch (e) {
      setState(() {
        _testOutput += '❌ Erro ao criar snapshot: $e\n';
      });
    }
  }

  void _clearOutput() {
    setState(() {
      _testOutput = '';
      _lastTestResults = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações Avançadas'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Testes de Persistência',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Execute testes para validar se todos os dados estão sendo salvos corretamente no banco de dados.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // Botões de ação
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunningTest ? null : _runPersistenceTest,
                  icon: _isRunningTest 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                  label: Text(_isRunningTest ? 'Executando...' : 'Teste Completo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isRunningTest ? null : _runQuickValidation,
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Validação Rápida'),
                ),
                OutlinedButton.icon(
                  onPressed: _isRunningTest ? null : _createDataSnapshot,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Snapshot'),
                ),
                TextButton.icon(
                  onPressed: _clearOutput,
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpar'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Resultados do último teste
            if (_lastTestResults != null) ...[
              Card(
                color: _lastTestResults!['success'] 
                  ? Colors.green[50] 
                  : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _lastTestResults!['success'] 
                              ? Icons.check_circle 
                              : Icons.error,
                            color: _lastTestResults!['success'] 
                              ? Colors.green 
                              : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _lastTestResults!['success'] 
                              ? 'Teste Passou' 
                              : 'Teste Falhou',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _lastTestResults!['success'] 
                                ? Colors.green[700] 
                                : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Duração: ${_lastTestResults!['duration']}ms'),
                      Text('Etapas: ${_lastTestResults!['steps'].length}'),
                      if (_lastTestResults!['errors'].isNotEmpty)
                        Text(
                          'Erros: ${_lastTestResults!['errors'].length}',
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Console de output
            const Text(
              'Console de Saída',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _testOutput.isEmpty
                  ? const Text(
                      'Nenhum teste executado ainda.\nClique em "Teste Completo" para começar.',
                      style: TextStyle(color: Colors.grey),
                    )
                  : SingleChildScrollView(
                      controller: _scrollController,
                      child: Text(
                        _testOutput,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}