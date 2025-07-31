import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

/// Serviço responsável pelas notificações locais
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  Function(String)? _notificationTapCallback;

  /// Inicializa o serviço de notificações
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Configurações para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configurações para iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configurações gerais
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsIOS,
    );

    // Inicializa o plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Solicita permissões no Android 13+
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }

    _isInitialized = true;
    debugPrint('NotificationService inicializado com sucesso');
  }

  /// Solicita permissões no Android
  Future<void> _requestAndroidPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  /// Callback quando uma notificação é tocada
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    debugPrint('Notificação tocada com payload: $payload');
    
    if (payload != null) {
      // Aqui você pode navegar para a tela específica baseada no payload
      // Por exemplo, abrir a tela de validação do treino
      _handleWorkoutValidationNotification(payload);
    }
  }

  /// Define o callback para quando uma notificação é tocada
  void setNotificationTapCallback(Function(String) callback) {
    _notificationTapCallback = callback;
  }

  /// Manipula notificações de validação de treino
  void _handleWorkoutValidationNotification(String payload) {
    // Parse do payload para extrair o ID do treino
    if (payload.startsWith('workout_validation_')) {
      final workoutId = payload.replaceFirst('workout_validation_', '');
      debugPrint('Abrindo validação para treino: $workoutId');
      
      // Chama o callback se estiver definido
      if (_notificationTapCallback != null) {
        _notificationTapCallback!(payload);
      }
    }
  }

  /// Agenda uma notificação para validação de treino
  Future<void> scheduleWorkoutValidationNotification({
    required String workoutId,
    required String workoutName,
    required DateTime scheduledTime,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'workout_validation',
      'Validação de Treinos',
      channelDescription: 'Notificações para validar treinos concluídos',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
      macOS: iOSPlatformChannelSpecifics,
    );

    final int notificationId = workoutId.hashCode;

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
    
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      '🏋️ Validar Treino',
      'Você concluiu o treino "$workoutName"? Toque para confirmar e ganhar XP!',
      tzScheduledTime,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'workout_validation_$workoutId',
    );

    debugPrint('Notificação agendada para $scheduledTime - Treino: $workoutName');
  }

  /// Cancela uma notificação específica
  Future<void> cancelNotification(String workoutId) async {
    final int notificationId = workoutId.hashCode;
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
    debugPrint('Notificação cancelada para treino: $workoutId');
  }

  /// Cancela todas as notificações
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('Todas as notificações foram canceladas');
  }

  /// Mostra uma notificação imediata
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'immediate',
      'Notificações Imediatas',
      channelDescription: 'Notificações mostradas imediatamente',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
      macOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// Verifica se as notificações estão habilitadas
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        return await androidImplementation.areNotificationsEnabled() ?? false;
      }
    }
    return true; // Assume que estão habilitadas em outras plataformas
  }

  /// Lista todas as notificações pendentes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }
}