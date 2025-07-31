import 'package:flutter/material.dart';
import '../../../services/app_initialization_service.dart';

/// Tela que exibe estatísticas e histórico de penalidades
class PenaltyStatsScreen extends StatefulWidget {
  const PenaltyStatsScreen({super.key});

  @override
  State<PenaltyStatsScreen> createState() => _PenaltyStatsScreenState();
}

class _PenaltyStatsScreenState extends State<PenaltyStatsScreen> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  final AppInitializationService _appService = AppInitializationService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final stats = await _appService.getPenaltyStats();
      final history = await _appService.getPenaltyHistory(limit: 100);
      
      setState(() {
        _stats = stats;
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cleanOldLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Logs Antigos'),
        content: const Text(
          'Deseja remover logs de penalidades com mais de 30 dias? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _appService.cleanOldPenaltyLogs();
        _loadData(); // Recarrega os dados
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logs antigos removidos com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao limpar logs: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penalidades'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clean') {
                _cleanOldLogs();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clean',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Limpar Logs Antigos'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCard(),
                    const SizedBox(height: 20),
                    _buildHistorySection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Estatísticas de Penalidades',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_stats.isEmpty)
              const Text(
                'Nenhuma penalidade aplicada ainda! 🎉',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Total de Penalidades',
                          '${_stats['totalPenalties'] ?? 0}',
                          Icons.gavel,
                          Colors.red,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'XP Perdido',
                          '${_stats['totalXpLost'] ?? 0}',
                          Icons.trending_down,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Esta Semana',
                          '${_stats['thisWeek'] ?? 0}',
                          Icons.calendar_view_week,
                          Colors.purple,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Este Mês',
                          '${_stats['thisMonth'] ?? 0}',
                          Icons.calendar_month,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Histórico de Penalidades',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_history.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.sentiment_very_satisfied,
                      size: 48,
                      color: Colors.green.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhuma penalidade no histórico!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Continue assim e mantenha suas missões em dia!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ..._history.map((penalty) => _buildPenaltyCard(penalty)),
      ],
    );
  }

  Widget _buildPenaltyCard(Map<String, dynamic> penalty) {
    final appliedAt = DateTime.parse(penalty['appliedAt']);
    final missionTitle = penalty['missionTitle'] ?? 'Missão Desconhecida';
    final xpLost = penalty['xpLost'] ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.withOpacity(0.1),
          child: const Icon(Icons.warning, color: Colors.red),
        ),
        title: Text(
          missionTitle,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'Penalidade aplicada em ${_formatDate(appliedAt)}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '-$xpLost XP',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoje às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ontem às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
      return '${weekdays[date.weekday % 7]} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}