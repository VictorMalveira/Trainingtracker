import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PenaltySettingsScreen extends StatefulWidget {
  const PenaltySettingsScreen({super.key});

  @override
  State<PenaltySettingsScreen> createState() => _PenaltySettingsScreenState();
}

class _PenaltySettingsScreenState extends State<PenaltySettingsScreen> {
  bool _penaltiesEnabled = true;
  double _penaltyMultiplier = 0.5;
  int _checkIntervalMinutes = 1;
  bool _notificationsEnabled = true;
  bool _autoCleanLogs = true;
  int _logRetentionDays = 30;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _penaltiesEnabled = prefs.getBool('penalties_enabled') ?? true;
      _penaltyMultiplier = prefs.getDouble('penalty_multiplier') ?? 0.5;
      _checkIntervalMinutes = prefs.getInt('check_interval_minutes') ?? 1;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _autoCleanLogs = prefs.getBool('auto_clean_logs') ?? true;
      _logRetentionDays = prefs.getInt('log_retention_days') ?? 30;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('penalties_enabled', _penaltiesEnabled);
    await prefs.setDouble('penalty_multiplier', _penaltyMultiplier);
    await prefs.setInt('check_interval_minutes', _checkIntervalMinutes);
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('auto_clean_logs', _autoCleanLogs);
    await prefs.setInt('log_retention_days', _logRetentionDays);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurações salvas com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Penalidades'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Salvar configurações',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sistema de Penalidades',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Ativar penalidades'),
                    subtitle: const Text('Aplicar penalidades por missões expiradas'),
                    value: _penaltiesEnabled,
                    onChanged: (value) {
                      setState(() {
                        _penaltiesEnabled = value;
                      });
                    },
                  ),
                  if (_penaltiesEnabled) ...[
                    const Divider(),
                    Text(
                      'Multiplicador de Penalidade: ${(_penaltyMultiplier * 100).toInt()}%',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      value: _penaltyMultiplier,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      label: '${(_penaltyMultiplier * 100).toInt()}%',
                      onChanged: (value) {
                        setState(() {
                          _penaltyMultiplier = value;
                        });
                      },
                    ),
                    const Text(
                      'Porcentagem do XP da missão que será perdida como penalidade',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verificação Automática',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Intervalo de Verificação: $_checkIntervalMinutes minuto(s)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: _checkIntervalMinutes.toDouble(),
                    min: 1,
                    max: 60,
                    divisions: 59,
                    label: '$_checkIntervalMinutes min',
                    onChanged: (value) {
                      setState(() {
                        _checkIntervalMinutes = value.toInt();
                      });
                    },
                  ),
                  const Text(
                    'Frequência com que o sistema verifica missões expiradas',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notificações e Logs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Notificações'),
                    subtitle: const Text('Receber notificações sobre penalidades'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Limpeza automática de logs'),
                    subtitle: const Text('Remover logs antigos automaticamente'),
                    value: _autoCleanLogs,
                    onChanged: (value) {
                      setState(() {
                        _autoCleanLogs = value;
                      });
                    },
                  ),
                  if (_autoCleanLogs) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Retenção de Logs: $_logRetentionDays dias',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      value: _logRetentionDays.toDouble(),
                      min: 7,
                      max: 365,
                      divisions: 51,
                      label: '$_logRetentionDays dias',
                      onChanged: (value) {
                        setState(() {
                          _logRetentionDays = value.toInt();
                        });
                      },
                    ),
                    const Text(
                      'Logs mais antigos que este período serão removidos',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Informações Importantes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• As penalidades são aplicadas automaticamente quando missões expiram\n'
                    '• Missões com maior prioridade têm penalidades mais severas\n'
                    '• O XP perdido é calculado baseado na prioridade e valor da missão\n'
                    '• As configurações são aplicadas imediatamente após salvar',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}