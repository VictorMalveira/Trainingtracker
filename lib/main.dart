import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:developer' as developer;

import 'services/xp_service.dart';
import 'services/user_service.dart';
import 'services/skill_service.dart';
import 'services/daily_mission_service.dart';
import 'services/workout_service.dart';
import 'services/app_initialization_service.dart';
import 'features/home/home_screen.dart';
import 'features/auth/registration_screen.dart';
import 'features/missions/daily_missions_screen.dart';
import 'features/workouts/workout_details_screen.dart';
import 'features/workouts/workouts_list_screen.dart';
import 'features/workouts/my_workouts_screen.dart';
import 'features/workouts/create_workout_screen.dart';
import 'features/profile/advanced_settings_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/progress/progress_screen.dart';
import 'screens/workout_validation_screen.dart';
import 'services/notification_service.dart';
import 'services/workout_validation_service.dart';
import 'services/xp_service.dart' as xp_service_import;

void main() async {
  try {
    // Garante que os widgets estejam inicializados
    WidgetsFlutterBinding.ensureInitialized();

    developer.log('Iniciando aplicativo...');
    
    // Inicializa os serviços do aplicativo
    final appInitService = AppInitializationService();
    await appInitService.initialize();
    
    // Configura o handler de notificações para validação de treinos
    final notificationService = NotificationService();
    await notificationService.initialize();
    
    // Configura o callback para quando uma notificação é tocada
    notificationService.setNotificationTapCallback((String? payload) {
      if (payload != null && payload.startsWith('workout_validation_')) {
        // Extrai o ID do treino do payload
        final workoutId = payload.replaceFirst('workout_validation_', '');
        // Aqui você pode navegar para a tela de validação
        // Isso será tratado pela navegação global quando implementada
        developer.log('Notificação de validação tocada para treino: $workoutId');
      }
    });

    // Inicializa o banco de dados
    developer.log('Abrindo banco de dados...');
    final database = await openDatabase(
      join(await getDatabasesPath(), 'jiu_tracker.db'),
      version: 1,
      onCreate: (db, version) async {
        developer.log('Criando banco de dados...');
        try {
          // Cria a tabela de usuários
          await db.execute(
            'CREATE TABLE IF NOT EXISTS users(id TEXT PRIMARY KEY, name TEXT, birthDate TEXT, weight REAL, beltLevel TEXT, beltDegree INTEGER, xpPoints INTEGER, currentStreak INTEGER, longestStreak INTEGER, lastWorkoutDate TEXT, trainingStartDate TEXT, lastPromotionDate TEXT)',
          );

          // Cria a tabela de habilidades
          await SkillService.createTable(db);

          // Cria a tabela de missões diárias
          await DailyMissionService.createTable(db);

          // Cria a tabela de treinos
          await WorkoutService.createTable(db);

          developer.log('Banco de dados criado com sucesso');
        } catch (e) {
          developer.log('Erro ao criar banco de dados: $e');
          rethrow;
        }
      },
    );

    // Inicializa os serviços
    developer.log('Inicializando serviços...');
    final userService = UserService();
    userService.db = database;

    final skillService = SkillService(database);
    final dailyMissionService = DailyMissionService(database);
    final workoutService = WorkoutService(database);
    final xpService = XPService(skillService, userService, dailyMissionService);

    try {
      // Verifica se já existe um usuário cadastrado
      developer.log('Verificando se usuário existe...');
      final userExists = await userService.userExists();
      developer.log('Usuário existe: $userExists');

      // Garante que as tabelas existem
      try {
        await SkillService.createTable(database);
        developer.log('Tabela skills verificada/criada');
      } catch (e) {
        developer.log('Erro ao criar tabela skills: $e');
      }

      try {
        await DailyMissionService.createTable(database);
        developer.log('Tabela daily_missions verificada/criada');
      } catch (e) {
        developer.log('Erro ao criar tabela daily_missions: $e');
      }

      try {
        await WorkoutService.createTable(database);
        developer.log('Tabela workouts verificada/criada');
      } catch (e) {
        developer.log('Erro ao criar tabela workouts: $e');
      }

      // Força a criação da tabela workouts
      try {
        developer.log('Forçando criação da tabela workouts...');
        await WorkoutService.createTable(database);
        developer.log('Tabela workouts criada/verificada com sucesso');
      } catch (e) {
        developer.log('Erro ao criar tabela workouts: $e');
      }

             runApp(
         JiuTrackerApp(
           userService: userService,
           skillService: skillService,
           dailyMissionService: dailyMissionService,
           workoutService: workoutService,
           xpService: xpService,
           initialRoute: userExists ? '/home' : '/register',
         ),
       );
    } catch (e) {
      developer.log('Erro ao verificar usuário: $e');
             // Em caso de erro, redireciona para a tela de cadastro
       runApp(
         JiuTrackerApp(
           userService: userService,
           skillService: skillService,
           dailyMissionService: dailyMissionService,
           workoutService: workoutService,
           xpService: xpService,
           initialRoute: '/register',
         ),
       );
    }
  } catch (e) {
    // Em caso de erro crítico, exibe uma tela de erro
    developer.log('Erro crítico: $e');
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Ocorreu um erro ao iniciar o aplicativo.\nPor favor, feche e abra novamente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}

class JiuTrackerApp extends StatelessWidget {
  final UserService userService;
  final SkillService skillService;
  final DailyMissionService dailyMissionService;
  final WorkoutService workoutService;
  final XPService xpService;
  final String initialRoute;

  const JiuTrackerApp({
    super.key,
    required this.userService,
    required this.skillService,
    required this.dailyMissionService,
    required this.workoutService,
    required this.xpService,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
         return MultiProvider(
       providers: [
         ChangeNotifierProvider<XPService>.value(value: xpService),
         Provider<UserService>.value(value: userService),
         Provider<SkillService>.value(value: skillService),
         Provider<DailyMissionService>.value(value: dailyMissionService),
         Provider<WorkoutService>.value(value: workoutService),
       ],
      child: MaterialApp(
        title: 'JiuTracker',
        theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR')],
        initialRoute: initialRoute,
        routes: {
          '/home': (context) => const HomeScreen(),
          '/register': (context) => const RegistrationScreen(),
          '/daily-missions': (context) => const DailyMissionsScreen(),
          '/create-workout': (context) => const CreateWorkoutScreen(),
          '/my-workouts': (context) => const MyWorkoutsScreen(),
          '/workouts-list': (context) => const WorkoutsListScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/progress': (context) => const ProgressScreen(),
          '/advanced-settings': (context) => const AdvancedSettingsScreen(),
          '/workout-details': (context) {
            final workoutId = ModalRoute.of(context)!.settings.arguments as String?;
            if (workoutId == null) {
              return const Scaffold(
                body: Center(child: Text('ID do treino não fornecido')),
              );
            }
            return WorkoutDetailsScreen(workoutId: workoutId);
          },
          '/workout-validation': (context) {
            final workoutId = ModalRoute.of(context)!.settings.arguments as String?;
            return WorkoutValidationScreen(workoutId: workoutId);
          },
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
