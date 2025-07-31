import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/xp_service.dart';
import '../progress/widgets/animated_skills_radar.dart';
import 'edit_profile_modal.dart';
import 'skill_point_distributor.dart';
import '../progress/progress_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userService = context.read<UserService>();
      final user = await userService.getUser();
      setState(() {
        _user = user;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  void _showEditProfileModal() {
    if (_user == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileModal(user: _user!),
    ).then((_) => _loadUserData());
  }
  
  void _showSkillPointDistributor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
                    'Distribuidor de Pontos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Expanded(
                child: SingleChildScrollView(
                  child: SkillPointDistributor(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final xpService = context.watch<XPService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsModal,
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: _isLoading || _user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(xpService),
                  const SizedBox(height: 24),
                  _buildSkillsSection(xpService),
                  const SizedBox(height: 24),
                  _buildStatsSection(xpService),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(XPService xpService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Hero(
                  tag: 'profile-avatar',
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    child: Text(
                      _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user!.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildBeltBadge(_user!.beltLevel, _user!.beltDegree),
                          const SizedBox(width: 8),
                          Text(
                            'Nível ${xpService.level}',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('XP Total', '${xpService.xp}', Icons.star),
                _buildStatItem(
                  'Sequência',
                  '${xpService.currentStreak} dias',
                  Icons.local_fire_department,
                ),
                _buildStatItem(
                  'Peso',
                  '${_user!.weight} kg',
                  Icons.fitness_center,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (xpService.availableSkillPoints > 0)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Você tem ${xpService.availableSkillPoints} ponto${xpService.availableSkillPoints > 1 ? 's' : ''} de habilidade para distribuir!',
                        style: TextStyle(
                          color: Colors.green[700],
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
      ),
    );
  }

  Widget _buildBeltBadge(String beltLevel, int degree) {
    Color beltColor;
    switch (beltLevel.toLowerCase()) {
      case 'branca':
        beltColor = Colors.white;
        break;
      case 'azul':
        beltColor = Colors.blue;
        break;
      case 'roxa':
        beltColor = Colors.purple;
        break;
      case 'marrom':
        beltColor = Colors.brown;
        break;
      case 'preta':
        beltColor = Colors.black;
        break;
      default:
        beltColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: beltColor,
        borderRadius: BorderRadius.circular(4),
        border: beltColor == Colors.white
            ? Border.all(color: Colors.grey[300]!)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            beltLevel,
            style: TextStyle(
              color: beltColor == Colors.white || beltColor == Colors.yellow
                  ? Colors.black
                  : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          if (degree > 0) ...[  
            const SizedBox(width: 4),
            Text(
              '• $degree',
              style: TextStyle(
                color: beltColor == Colors.white || beltColor == Colors.yellow
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection(XPService xpService) {
    return FadeTransition(
      opacity: _animation,
      child: AnimatedSkillsRadar(skills: xpService.skills),
    );
  }

  Widget _buildStatsSection(XPService xpService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estatísticas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Nível Atual',
                    '${xpService.level}',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'XP para Próximo',
                    '${xpService.xpToNextLevel}',
                    Icons.star_border,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Melhor Sequência',
                    '${xpService.bestStreak} dias',
                    Icons.local_fire_department,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Pontos Disponíveis',
                    '${xpService.availableSkillPoints}',
                    Icons.star,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final xpService = context.watch<XPService>();
    final hasAvailablePoints = xpService.availableSkillPoints > 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasAvailablePoints)
          ElevatedButton.icon(
            onPressed: _showSkillPointDistributor,
            icon: const Icon(Icons.star),
            label: Text('Distribuir ${xpService.availableSkillPoints} Ponto${xpService.availableSkillPoints > 1 ? 's' : ''}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        if (hasAvailablePoints)
          const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _showEditProfileModal,
          icon: const Icon(Icons.edit),
          label: const Text('Editar Perfil'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProgressScreen(),
              ),
            );
          },
          icon: const Icon(Icons.history),
          label: const Text('Ver Histórico'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            _showSettingsModal();
          },
          icon: const Icon(Icons.settings),
          label: const Text('Configurações'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        if (!hasAvailablePoints)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              onPressed: _showSkillPointDistributor,
              icon: const Icon(Icons.star_border),
              label: const Text('Ver Distribuidor de Pontos'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
      ],
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
                    'Configurações',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Notificações'),
                      subtitle: const Text('Gerenciar lembretes de treino'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Implementar configurações de notificação
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Em desenvolvimento')),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.backup),
                      title: const Text('Backup de Dados'),
                      subtitle: const Text('Exportar/importar dados'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Implementar backup
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Em desenvolvimento')),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.developer_mode),
                      title: const Text('Configurações Avançadas'),
                      subtitle: const Text('Testes de persistência e diagnósticos'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/advanced-settings');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.palette),
                      title: const Text('Tema'),
                      subtitle: const Text('Personalizar aparência'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Implementar seleção de tema
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Em desenvolvimento')),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('Sobre o App'),
                      subtitle: const Text('Versão e informações'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'JiuTracker',
                          applicationVersion: '1.0.0',
                          applicationIcon: const Icon(Icons.sports_martial_arts),
                          children: [
                            const Text('App para acompanhamento de treinos de Jiu-Jitsu'),
                          ],
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Excluir Perfil', style: TextStyle(color: Colors.red)),
                      subtitle: const Text('Remover todos os dados permanentemente'),
                      onTap: () => _showDeleteProfileConfirmation(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteProfileConfirmation() {
    Navigator.pop(context); // Fecha o modal de configurações
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Excluir Perfil'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Esta ação é IRREVERSÍVEL!',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              SizedBox(height: 8),
              Text('Todos os seus dados serão perdidos:'),
              SizedBox(height: 8),
              Text('• Perfil e informações pessoais'),
              Text('• Pontos de XP e nível atual'),
              Text('• Distribuição de habilidades'),
              Text('• Histórico de treinos'),
              Text('• Missões completadas'),
              SizedBox(height: 16),
              Text(
                'Tem certeza que deseja continuar?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => _confirmDeleteProfile(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Excluir Definitivamente'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteProfile() {
    Navigator.pop(context); // Fecha o dialog de confirmação
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmação Final'),
          content: const Text(
            'Digite "EXCLUIR" para confirmar a exclusão do perfil:',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showDeleteConfirmationInput();
              },
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationInput() {
    final TextEditingController confirmController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Digite EXCLUIR'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Para confirmar, digite exatamente: EXCLUIR'),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  hintText: 'Digite EXCLUIR aqui',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                confirmController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (confirmController.text.trim() == 'EXCLUIR') {
                  confirmController.dispose();
                  Navigator.pop(context);
                  _executeDeleteProfile();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Texto incorreto. Digite exatamente "EXCLUIR"'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar Exclusão'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeDeleteProfile() async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Excluindo perfil...'),
            ],
          ),
        );
      },
    );

    try {
      final userService = context.read<UserService>();
      
      print('🗑️ Iniciando exclusão do perfil...');
      
      // Executar exclusão
      await userService.deleteUserProfile();
      
      print('✅ Perfil excluído com sucesso');
      
      // Validar limpeza
      final validationResult = await userService.validateCleanDatabase();
      final isClean = validationResult['isClean'] as bool;
      if (isClean) {
        print('✅ Banco de dados limpo validado');
      } else {
        print('⚠️ Aviso: Alguns dados podem não ter sido removidos');
      }
      
      // Fechar loading
      if (mounted) {
        Navigator.pop(context);
      }
      
      // Mostrar sucesso e navegar para registro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil excluído com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navegar para tela de registro
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/register',
          (route) => false,
        );
      }
      
    } catch (e) {
      print('❌ Erro ao excluir perfil: $e');
      
      // Fechar loading
      if (mounted) {
        Navigator.pop(context);
      }
      
      // Mostrar erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}